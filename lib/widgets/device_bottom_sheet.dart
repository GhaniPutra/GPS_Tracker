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
              // Main scroll area: use the provided `controller` for vertical scrolling only
              Expanded(
                child: Consumer<BluetoothProvider>(
                  builder: (context, bt, child) {
                    final connected = bt.connectedDevices;
                    final known = bt.knownDevices;

                    return ListView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        // Connected devices list or empty placeholder
                        if (connected.isEmpty)
                          Container(
                            height: 120,
                            alignment: Alignment.center,
                            child: Text('Tidak ada perangkat terhubung.', style: theme.textTheme.bodyMedium),
                          )
                        else ...connected.map((conn) {
                          final device = conn.device;
                          final deviceName = conn.name;
                          final hasPos = conn.lastPosition != null;
                          return Card(
                            elevation: 0,
                            color: theme.cardColor,
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: ListTile(
                              leading: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(Icons.bluetooth_connected, size: 30),
                                  if (hasPos)
                                    const Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Icon(Icons.location_on, size: 12, color: Colors.red),
                                    ),
                                ],
                              ),
                              title: Text(deviceName),
                              subtitle: Text(device.remoteId.toString()),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  final provider = Provider.of<BluetoothProvider>(context, listen: false);
                                  if (value == 'disconnect') {
                                    await provider.disconnectDevice(device);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Terputus dari ${deviceName}')),
                                    );
                                  } else if (value == 'forget') {
                                    await provider.forgetDeviceById(device.remoteId.toString());
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${deviceName} dihapus dari daftar')), 
                                    );
                                  }
                                },
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(value: 'disconnect', child: Text('Disconnect')),
                                  const PopupMenuItem(value: 'forget', child: Text('Lupakan Perangkat')),
                                ],
                              ),
                              onTap: () {
                                final provider = Provider.of<BluetoothProvider>(context, listen: false);
                                provider.selectDevice(device);
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 6),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Stored devices header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'Perangkat Tersimpan',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (known.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text('Tidak ada perangkat tersimpan.', style: theme.textTheme.bodyMedium),
                          )
                        else
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              itemCount: known.length,
                              itemBuilder: (context, i) {
                                final d = known[i];
                                final hasPos = d.lastLat != null && d.lastLon != null;
                                return SizedBox(
                                  width: 220,
                                  child: Card(
                                    color: theme.cardColor,
                                    margin: const EdgeInsets.only(right: 12.0, bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(d.name, style: theme.textTheme.bodyMedium),
                                          if (hasPos)
                                            Text('Pos: ${d.lastLat}, ${d.lastLon}', style: theme.textTheme.bodySmall),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    final provider = Provider.of<BluetoothProvider>(context, listen: false);
                                                    final activeIndex = provider.connectedDevices.indexWhere((c) => c.id == d.id);
                                                    if (activeIndex != -1) {
                                                      provider.selectDevice(provider.connectedDevices[activeIndex].device);
                                                      Navigator.pop(context);
                                                    } else if (hasPos) {
                                                      // Move map to stored last-known position
                                                      provider.selectStoredDevicePosition(d);
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text('Lihat / Hubungkan'),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline),
                                                onPressed: () async {
                                                  final provider = Provider.of<BluetoothProvider>(context, listen: false);
                                                  await provider.forgetDeviceById(d.id);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('${d.name} dihapus dari daftar')), 
                                                  );
                                                },
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
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
