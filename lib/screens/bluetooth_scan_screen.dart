import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();

    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startScan();
      }
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _scanResults = results;
      });
    }, onError: (e) {
      _showErrorSnackbar(e.toString());
    });

    // Start scanning immediately if Bluetooth is already on
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on) {
        _startScan();
      } else {
        // Show a message or prompt to turn on Bluetooth
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
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _startScan() async {
    if (_isScanning) return;

    if (await _checkPermissions()) {
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
      // iOS handles permissions differently, often at the time of use.
      // FlutterBluePlus handles the Bluetooth permission prompt.
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Izin Bluetooth dan Lokasi diperlukan untuk memindai perangkat.')),
      );
    }
    return false;
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
          onTap: () {
            FlutterBluePlus.stopScan();
            // TODO: Implement connection logic
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Menyambung ke ${deviceName.isNotEmpty ? deviceName : result.device.remoteId}...')),
            );
          },
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
