import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gps_tracker_app/services/bluetooth_manager.dart';
import 'package:gps_tracker_app/services/tracker_model.dart';

/// Example usage of BluetoothManager in an app component.
class BluetoothExample extends StatefulWidget {
  const BluetoothExample({super.key});

  @override
  State<BluetoothExample> createState() => _BluetoothExampleState();
}

class _BluetoothExampleState extends State<BluetoothExample> {
  final BluetoothManager _mgr = BluetoothManager();
  StreamSubscription<TrackerDiscovery>? _sub;
  final List<TrackerDiscovery> _found = [];

  @override
  void initState() {
    super.initState();
    _sub = _mgr.discoveries.listen((d) async {
      // Basic UI handling: add to list
      setState(() {
        _found.removeWhere((e) => e.shortId == d.shortId);
        _found.add(d);
      });

      // Optionally validate on demand or automatically (careful with concurrency)
      final device = d.device;
      final ok = await _mgr.validateDevice(device);
      if (ok) {
        debugPrint('Validated device: ${d.shortId}');
        // Update UI state if needed
      }
    });

    // Start a short scan for demo
    _mgr.startScan(timeout: const Duration(seconds: 8));
  }

  @override
  void dispose() {
    _sub?.cancel();
    _mgr.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: _found.map((d) => ListTile(
            title: Text(d.shortId),
            subtitle: Text('rssi: ${d.rssi}'),
            trailing: const Icon(Icons.chevron_right),
          )).toList(),
    );
  }
}
