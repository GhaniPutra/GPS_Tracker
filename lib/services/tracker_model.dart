import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Represents a discovered tracker candidate (parsed and normalized)
class TrackerDiscovery {
  final BluetoothDevice device;
  final int rssi;
  final Map<int, List<int>> manufacturerData;
  final DateTime seenAt;
  final String shortId; // parsed short id hex string (if present)
  final int deviceType;

  TrackerDiscovery({
    required this.device,
    required this.rssi,
    required this.manufacturerData,
    required this.seenAt,
    required this.shortId,
    required this.deviceType,
  });
}
