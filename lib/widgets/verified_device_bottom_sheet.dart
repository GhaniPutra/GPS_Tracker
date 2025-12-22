import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gps_tracker_app/screens/bluetooth_scan_screen.dart';
import 'package:gps_tracker_app/services/bluetooth_manager.dart';
import 'package:gps_tracker_app/services/tracker_model.dart';

class VerifiedDeviceBottomSheet extends StatefulWidget {
  const VerifiedDeviceBottomSheet({super.key});

  @override
  State<VerifiedDeviceBottomSheet> createState() => _VerifiedDeviceBottomSheetState();
}

class _VerifiedDeviceBottomSheetState extends State<VerifiedDeviceBottomSheet> {
  final BluetoothManager _mgr = BluetoothManager();
  StreamSubscription<TrackerDiscovery>? _confirmedSub;
  final List<TrackerDiscovery> _confirmed = [];

  // Per-device validation state
  final Map<String, bool> _inProgress = {};
  final Map<String, bool?> _lastResult = {};
  final Map<String, DateTime?> _lastChecked = {};

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

  void _refreshScan() async {
    await _mgr.startScan(timeout: const Duration(seconds: 8));
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
                'Perangkat Terverifikasi',
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
                                    // manager will emit confirmed discovery
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
                child: Builder(builder: (context) {
                  if (_confirmed.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tidak ada perangkat terverifikasi.'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _refreshScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: controller,
                    itemCount: _confirmed.length,
                    itemBuilder: (context, index) {
                      final d = _confirmed[index];
                      final display = d.shortId;

                      return Card(
                        elevation: 0,
                        color: theme.cardColor,
                        child: ListTile(
                          leading: const Icon(Icons.gps_fixed, size: 30),
                          title: Text(display),
                          subtitle: Text(
                            'RSSI: ${d.rssi} dBm • Seen: ${d.seenAt}\n'
                            '${_lastChecked[d.shortId] != null ? 'Last check: ${_lastChecked[d.shortId]} • ${_lastResult[d.shortId] == true ? 'OK' : _lastResult[d.shortId] == false ? 'FAIL' : ''}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: _inProgress[d.shortId] == true ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.replay),
                                onPressed: () => _revalidate(d),
                                tooltip: 'Re-validate',
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                          onTap: () {
                            // navigate to detail or center map on device GPS when available
                          },
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _revalidate(TrackerDiscovery d) async {
    final id = d.shortId;
    if (_inProgress[id] == true) return; // already running

    setState(() {
      _inProgress[id] = true;
    });

    final ok = await _mgr.validateDiscovery(d);

    if (!mounted) return;

    setState(() {
      _inProgress[id] = false;
      _lastResult[id] = ok;
      _lastChecked[id] = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Validasi berhasil untuk $id' : 'Validasi gagal untuk $id')),
    );

  }
}
