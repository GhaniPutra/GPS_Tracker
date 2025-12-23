import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothProvider with ChangeNotifier {
  final List<BluetoothDevice> _connectedDevices = [];

  List<BluetoothDevice> get connectedDevices => _connectedDevices;

  void addDevice(BluetoothDevice device) {
    if (!_connectedDevices.contains(device)) {
      _connectedDevices.add(device);
      notifyListeners();
    }
  }

  void removeDevice(BluetoothDevice device) {
    _connectedDevices.remove(device);
    notifyListeners();
  }
}
