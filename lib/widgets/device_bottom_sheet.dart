import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gps_tracker_app/screens/bluetooth_scan_screen.dart';
import 'package:gps_tracker_app/services/bluetooth_manager.dart';
import 'package:gps_tracker_app/services/tracker_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceBottomSheet extends StatefulWidget {
  const DeviceBottomSheet({super.key});

  @override
  State<DeviceBottomSheet> createState() => _DeviceBottomSheetState();
}

class _DeviceBottomSheetState extends State<DeviceBottomSheet> {
  final BluetoothManager _mgr = BluetoothManager();
  StreamSubscription<TrackerDiscovery>? _confirmedSub;
  final List<TrackerDiscovery> _confirmed = [];

  // Legacy stubs to remain compatible with older callers
  Future<List<BluetoothDevice>>? _connectedDevicesFuture;
  void _loadConnectedDevices() {}

  @override
  void initState() {
    super.initState();
    _confirmedSub = _mgr.confirmedDiscoveries.listen((d) {
      setState(() {
        _confirmed.removeWhere((e) => e.shortId == d.shortId);
        _confirmed.add(d);
      });
    });
  }

  @override
  void dispose() {
    _confirmedSub?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.6,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Perangkat Terhubung',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Tambah Perangkat'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pilih Metode Koneksi',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: const Icon(Icons.bluetooth),
                                title: const Text('Tambah via Bluetooth'),
                                onTap: () async {
                                  Navigator.pop(ctx);
                                  final result = await Navigator.push<bool?>(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
                                  );
                                  if (result == true) {
                                    _loadConnectedDevices();
                                  }
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.wifi),
                                title: const Text('Tambah via Wi-Fi'),
                                onTap: () {
                                  Navigator.pop(ctx);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurface,
                    side: BorderSide(color: theme.dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<BluetoothDevice>>(
                  future: _connectedDevicesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final devices = snapshot.data ?? [];
                    if (devices.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Tidak ada perangkat terhubung.'),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _loadConnectedDevices,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: controller,
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final displayName = (device.platformName.isNotEmpty)
                            ? device.platformName
                            : device.remoteId.toString();

                        return Card(
                          elevation: 0,
                          color: theme.cardColor,
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth_connected, size: 30),
                            title: Text(displayName),
                            subtitle: StreamBuilder<BluetoothConnectionState>(
                              stream: device.connectionState,
                              initialData: BluetoothConnectionState.disconnected,
                              builder: (context, stateSnap) {
                                final st = stateSnap.data ?? BluetoothConnectionState.disconnected;
                                return Text(st == BluetoothConnectionState.connected ? 'Terhubung' : st.name);
                              },
                            ),
                            trailing: FutureBuilder<int?>(
                              future: (() async {
                                try {
                                  return await device.readRssi();
                                } catch (_) {
                                  return null;
                                }
                              })(),
                              builder: (context, rssiSnap) {
                                if (rssiSnap.hasData && rssiSnap.data != null) {
                                  return Text('${rssiSnap.data} dBm');
                                }
                                return const Icon(Icons.chevron_right);
                              },
                            ),
                            onTap: () {
                              // Bisa implementasikan navigasi ke detail perangkat
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
