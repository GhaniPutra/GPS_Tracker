import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:latlong2/latlong.dart';
import '../services/device_db.dart';

/// Represents a connected device with optional last known position
class ConnectedDevice {
  final BluetoothDevice device;
  LatLng? lastPosition;

  ConnectedDevice({required this.device, this.lastPosition});

  String get id => device.remoteId.toString();
  String get name => device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString();
}

class BluetoothProvider with ChangeNotifier {
  final List<ConnectedDevice> _connectedDevices = [];
  final List<StoredDevice> _knownDevices = [];
  String? _selectedDeviceId;

  BluetoothProvider() {
    _loadKnownDevices();
  }

  List<ConnectedDevice> get connectedDevices => List.unmodifiable(_connectedDevices);
  List<StoredDevice> get knownDevices => List.unmodifiable(_knownDevices);

  ConnectedDevice? getSelectedDevice() {
    if (_selectedDeviceId == null) return null;
    try {
      return _connectedDevices.firstWhere((d) => d.id == _selectedDeviceId);
    } catch (_) {
      return null;
    }
  }

  String? get selectedDeviceId => _selectedDeviceId;
  LatLng? _selectedKnownPosition;
  LatLng? get selectedKnownPosition => _selectedKnownPosition;

  Future<void> _loadKnownDevices() async {
    try {
      final list = await DeviceDatabase.instance.getAllDevices();
      _knownDevices.clear();
      _knownDevices.addAll(list);
      notifyListeners();
    } catch (_) {}
  }

  /// Select a stored device position (last seen). HomeScreen should move map to this position and then the selection is cleared.
  void selectStoredDevicePosition(StoredDevice d) {
    if (d.lastLat != null && d.lastLon != null) {
      _selectedKnownPosition = LatLng(d.lastLat!, d.lastLon!);
      notifyListeners();
    }
  }

  void clearSelectedKnownPosition() {
    _selectedKnownPosition = null;
    notifyListeners();
  }
  Future<void> addDevice(BluetoothDevice device) async {
    if (_connectedDevices.indexWhere((d) => d.id == device.remoteId.toString()) == -1) {
      _connectedDevices.add(ConnectedDevice(device: device));
      // Save or update known device record
      final sv = StoredDevice(id: device.remoteId.toString(), name: device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(), lastLat: null, lastLon: null, lastSeen: DateTime.now().millisecondsSinceEpoch);
      await DeviceDatabase.instance.upsertDevice(sv);
      // refresh known devices
      await _loadKnownDevices();
      notifyListeners();
    }
  }

  Future<void> removeDevice(BluetoothDevice device) async {
    _connectedDevices.removeWhere((d) => d.id == device.remoteId.toString());
    if (_selectedDeviceId == device.remoteId.toString()) _selectedDeviceId = null;
    notifyListeners();
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (_) {}
    await removeDevice(device);
  }

  Future<void> forgetDeviceById(String deviceId) async {
    await DeviceDatabase.instance.deleteDeviceById(deviceId);
    _knownDevices.removeWhere((d) => d.id == deviceId);
    notifyListeners();
  }

  Future<void> updateDevicePosition(BluetoothDevice device, LatLng position) async {
    final idx = _connectedDevices.indexWhere((d) => d.id == device.remoteId.toString());
    if (idx != -1) {
      _connectedDevices[idx].lastPosition = position;
    }
    // persist to DB as well
    final sd = StoredDevice(
      id: device.remoteId.toString(),
      name: device.platformName.isNotEmpty ? device.platformName : device.remoteId.toString(),
      lastLat: position.latitude,
      lastLon: position.longitude,
      lastSeen: DateTime.now().millisecondsSinceEpoch,
    );
    await DeviceDatabase.instance.upsertDevice(sd);
    await _loadKnownDevices();
    notifyListeners();
  }

  void selectDevice(BluetoothDevice device) {
    _selectedDeviceId = device.remoteId.toString();
    notifyListeners();
  }

  void clearSelection() {
    _selectedDeviceId = null;
    notifyListeners();
  }
}
