import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:gps_tracker_app/providers/bluetooth_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
        _startScan();
      } else {
        if (Platform.isAndroid) {
          FlutterBluePlus.turnOn();
        }
      }
    });
  }

  @override
  void dispose() {
    _adapterStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _connectionStateSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
    void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    if (await _checkPermissions()) {
      if (!mounted) return;
      setState(() {
        _isScanning = true;
        _scanResults.clear();
      });

      try {
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      } catch (e) {
        _showErrorSnackbar('Gagal memulai pemindaian: ${e.toString()}');
      } finally {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      }
    }
  }

  Future<bool> _checkPermissions() async {
    if (Platform.isAndroid) {
      var bluetoothScanStatus = await Permission.bluetoothScan.request();
      var bluetoothConnectStatus = await Permission.bluetoothConnect.request();
      var locationStatus = await Permission.location.request();

      if (bluetoothScanStatus.isGranted &&
          bluetoothConnectStatus.isGranted &&
          locationStatus.isGranted) {
        return true;
      }
    } else if (Platform.isIOS) {
      return true;
    }

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text(
              'Izin Bluetooth dan Lokasi diperlukan untuk memindai perangkat.')),
    );
    return false;
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    final bluetoothProvider = Provider.of<BluetoothProvider>(context, listen: false);

    await FlutterBluePlus.stopScan();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Menyambung ke ${device.platformName.isNotEmpty ? device.platformName : device.remoteId}...')
      ),
    );

    try {
      await device.connect();

      _connectionStateSubscription = device.connectionState.listen((state) async {
        if (state == BluetoothConnectionState.connected) {
          await bluetoothProvider.addDevice(device);
          _showSuccessSnackbar('Berhasil terhubung ke ${device.platformName}');

          // Try to discover simple 'lat,lon' ASCII payloads on readable characteristics
          try {
            final services = await device.discoverServices();
            for (final s in services) {
              for (final c in s.characteristics) {
                try {
                  final val = await c.read();
                  if (val.isEmpty) continue;
                  final str = String.fromCharCodes(val);
                  // Expected simple format: "lat,lon" e.g. "-7.7,110.36"
                  final parts = str.split(',');
                  if (parts.length >= 2) {
                    final lat = double.tryParse(parts[0].trim());
                    final lon = double.tryParse(parts[1].trim());
                    if (lat != null && lon != null) {
                      // update provider (this will also persist)
                      await bluetoothProvider.updateDevicePosition(device, LatLng(lat, lon));
                      // stop once parsed
                      break;
                    }
                  }
                } catch (_) {
                  // ignore parse/read errors for non-GPS chars or non-readable chars
                }
              }
            }
          } catch (e) {
            // ignore discovery errors here
          }
        } else if (state == BluetoothConnectionState.disconnected) {
          await bluetoothProvider.removeDevice(device);
          if (!mounted) return;
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Terputus dari ${device.platformName}')),
          );
        }
      });


    } catch (e) {
      _showErrorSnackbar('Gagal terhubung: ${e.toString()}');
    }
  }

  Widget _buildScanResultList() {
    if (_isScanning && _scanResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memindai perangkat di sekitar...'),
          ],
        ),
      );
    }

    if (!_isScanning && _scanResults.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada perangkat ditemukan.\nTekan tombol refresh untuk memindai ulang.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _scanResults.length,
      itemBuilder: (context, index) {
        final result = _scanResults[index];
        final deviceName = result.device.platformName;
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(deviceName.isNotEmpty ? deviceName : 'Perangkat Tidak Dikenal'),
          subtitle: Text(result.device.remoteId.toString()),
          trailing: Text('${result.rssi} dBm'),
          onTap: () => _connectToDevice(result.device),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Perangkat Bluetooth'),
      ),
      body: _buildScanResultList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        backgroundColor: _isScanning ? Colors.grey : Theme.of(context).primaryColor,
        child: _isScanning
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.refresh),
      ),
    );
  }
}
