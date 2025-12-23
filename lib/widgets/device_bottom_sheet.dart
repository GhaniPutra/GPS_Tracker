import 'package:flutter/material.dart';
import 'package:gps_tracker_app/providers/bluetooth_provider.dart';
import 'package:gps_tracker_app/screens/bluetooth_scan_screen.dart';
import 'package:provider/provider.dart';

class DeviceBottomSheet extends StatelessWidget {
  const DeviceBottomSheet({super.key});

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
                                onTap: () {
                                  Navigator.pop(ctx); // Tutup bottom sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const BluetoothScanScreen()),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.wifi),
                                title: const Text('Tambah via Wi-Fi'),
                                onTap: () {
                                  // ignore: avoid_print
                                  print('Navigasi ke halaman pencarian Wi-Fi...');
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
              // Daftar Device (Fitur 1)
              Expanded(
                child: Consumer<BluetoothProvider>(
                  builder: (context, bluetoothProvider, child) {
                    if (bluetoothProvider.connectedDevices.isEmpty) {
                      return Center(
                        child: Text(
                          'Tidak ada perangkat terhubung.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: bluetoothProvider.connectedDevices.length,
                      itemBuilder: (context, index) {
                        final device = bluetoothProvider.connectedDevices[index];
                        final deviceName = device.platformName;
                        return Card(
                          elevation: 0,
                          color: theme.cardColor,
                          child: ListTile(
                            leading: const Icon(Icons.bluetooth_connected, size: 30),
                            title: Text(deviceName.isNotEmpty ? deviceName : 'Perangkat Tidak Dikenal'),
                            subtitle: Text(device.remoteId.toString()),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              // Logika untuk fokus ke perangkat
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
