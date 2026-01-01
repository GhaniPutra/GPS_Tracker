import 'dart:async';
import 'dart:collection';
import 'package:crypto/crypto.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'tracker_model.dart';

/// A lightweight Bluetooth manager focused on discovering and validating
/// tracker devices (not general-purpose BLE scanner).
///
/// Features:
/// - OS-level filtering by service UUID
/// - Manufacturer data parsing
/// - RSSI threshold and deduplication
/// - Short-lived connect-and-validate flow with concurrency limit
class BluetoothManager {
  BluetoothManager._internal();
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;

  // Defaults - replace GUIDs / ids with project-specific values
  final Guid trackerService = Guid('0000FEED-0000-1000-8000-00805F9B34FB');
  final Guid validationChar = Guid('0000BEEF-0000-1000-8000-00805F9B34FB');
  final int trackerManufacturerId = 0x1234; // example vendor id

  // Public stream of confirmed discoveries (after basic filtering)
  final _discoverController = StreamController<TrackerDiscovery>.broadcast();
  Stream<TrackerDiscovery> get discoveries => _discoverController.stream;

  // Confirmed/validated trackers stream
  final _confirmedController = StreamController<TrackerDiscovery>.broadcast();
  Stream<TrackerDiscovery> get confirmedDiscoveries => _confirmedController.stream;

  // Auto-validate discovered devices when HMAC key configured
  bool autoValidateOnDiscover = true;

  // track recent validation attempts per shortId to avoid repeated connects
  final Map<String, DateTime> _lastValidationAttempt = {};

  // keep set of confirmed shortIds to avoid duplicate emits
  final Set<String> _confirmedIds = {};
  // Scan subscription
  StreamSubscription<List<ScanResult>>? _scanResultsSub;

  // Dedup map: deviceId -> last seen rssi/time
  final Map<String, DateTime> _lastSeen = {};
  final Map<String, int> _lastRssi = {};

  // concurrent connect limit
  final int _maxConcurrentConnects = 2;
  int _activeConnects = 0;
  final Queue<BluetoothDevice> _connectQueue = Queue<BluetoothDevice>();

  // Tunables
  Duration dedupeDuration = const Duration(seconds: 60);
  int rssiThreshold = -90; // ignore below this
  int rssiChangeThreshold = 8; // dB to force re-emit

  // HMAC verification config
  List<int>? _hmacKey;
  int signatureLength = 8; // default truncated signature length in bytes

  // Start scanning with filters set to tracker service UUID to reduce noise
  Future<void> startScan({Duration? timeout}) async {
    await stopScan();
    // start OS-level scan with service filter (best for background)
    try {
      await FlutterBluePlus.startScan(timeout: timeout ?? const Duration(seconds: 10), withServices: [trackerService]);
    } catch (e) {
      debugPrint('startScan error: $e');
    }

    _scanResultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        _onScanResult(r);
      }
    }, onError: (e) {
      debugPrint('scanResults error: $e');
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    await _scanResultsSub?.cancel();
    _scanResultsSub = null;
  }

  void _onScanResult(ScanResult r) {
    // Basic RSSI filtering
    if (r.rssi < rssiThreshold) return;

    // Manufacturer data parsing
    final md = r.advertisementData.manufacturerData;

    // If manufacturer id present and matches tracker vendor OR service uuid matched earlier
    final manufacturerPresents = md.containsKey(trackerManufacturerId);

    // Parse shortId & deviceType if available
    final parsed = parseManufacturerData(md);

    // Construct shortId to dedupe (use device id remoteId as fallback)
    final shortId = parsed?.shortId ?? r.device.remoteId.toString();
    final deviceType = parsed?.deviceType ?? 0;

    // Dedup: check last seen timestamp and rssi
    final now = DateTime.now();
    final last = _lastSeen[shortId];
    final lastRssi = _lastRssi[shortId];

    final shouldEmit = (last == null) || (now.difference(last) > dedupeDuration) || (lastRssi == null) || (r.rssi - lastRssi).abs() >= rssiChangeThreshold;

    // Use service uuid match (scan filter) + manufacturer data OR manufacturer data presence
    if (shouldEmit && (manufacturerPresents || r.advertisementData.serviceUuids.contains(trackerService))) {
      _lastSeen[shortId] = now;
      _lastRssi[shortId] = r.rssi;

      final discovery = TrackerDiscovery(
        device: r.device,
        rssi: r.rssi,
        manufacturerData: md,
        seenAt: now,
        shortId: parsed?.shortId ?? r.device.remoteId.toString(),
        deviceType: deviceType,
      );

      _discoverController.add(discovery);

      // Optionally auto-validate if HMAC key is configured
      final shortIdKey = discovery.shortId;
      final lastAttempt = _lastValidationAttempt[shortIdKey];
      const maxAttemptInterval = Duration(minutes: 2);

      if (autoValidateOnDiscover && (_hmacKey != null && _hmacKey!.isNotEmpty)) {
        if (lastAttempt == null || now.difference(lastAttempt) > maxAttemptInterval) {
          _lastValidationAttempt[shortIdKey] = now;
          // Fire-and-forget validate, add to confirmed stream on success
          validateDevice(discovery.device).then((ok) {
            if (ok) {
              // Avoid double-confirming
              if (!_confirmedIds.contains(shortIdKey)) {
                _confirmedIds.add(shortIdKey);
                _confirmedController.add(discovery);
              }
            }
          });
        }
      }
    }
  }

  // Simple structure returned by parser
  /// Public wrapper for parsing manufacturer data (useful for tests)
  ManufacturerInfo? parseManufacturerData(Map<int, List<int>> md) {
    if (!md.containsKey(trackerManufacturerId)) return null;

    final bytes = md[trackerManufacturerId]!;
    if (bytes.isEmpty) return null;

    // Expecting layout: [deviceType(1), fwMajor(1), flags(1), shortId(6), ...]
    if (bytes.length < 9) return null; // minimal

    final deviceType = bytes[0];
    // fwMajor = bytes[1];
    // flags = bytes[2];
    final shortIdBytes = bytes.sublist(3, 9);
    final shortIdHex = shortIdBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return ManufacturerInfo(deviceType: deviceType, shortId: shortIdHex);
  }

  // Enqueue a validation connect attempt (reads validationChar)
  Future<bool> validateDevice(BluetoothDevice device, {Duration timeout = const Duration(seconds: 8)}) async {
    // If no key configured, return false immediately
    if (_hmacKey == null || _hmacKey!.isEmpty) return false;
    // If limit reached, enqueue
    if (_activeConnects >= _maxConcurrentConnects) {
      _connectQueue.add(device);
      return false;
    }

    _activeConnects++;
    bool success = false;

    try {
      await device.connect(timeout: timeout);

      final services = await device.discoverServices();
      final valChar = _findCharacteristic(services, validationChar);
      if (valChar != null) {
        final val = await valChar.read();
        success = _verifyValidationPayload(val);
      }
    } catch (e) {
      debugPrint('validateDevice error: $e');
    } finally {
      try {
        await device.disconnect();
      } catch (_) {}
      _activeConnects--;
      // start next queued connection if exists
      if (_connectQueue.isNotEmpty) {
        final next = _connectQueue.removeFirst();
        // fire and forget
        validateDevice(next);
      }
    }

    return success;
  }

  // Find validation characteristic in discovered services
  BluetoothCharacteristic? _findCharacteristic(List<BluetoothService> services, Guid charGuid) {
    for (final s in services) {
      for (final c in s.characteristics) {
        if (c.uuid == charGuid) return c;
      }
    }
    return null;
  }

  // HMAC verification: val layout: [shortId(6) | ts(4) | signature(sigLen)]
  bool _verifyValidationPayload(List<int> val) {
    // minimal message without signature is 6+4 bytes
    if (val.length < 6 + 4) return false; // minimal

    // If no HMAC key configured, fallback to simple length check
    if (_hmacKey == null || _hmacKey!.isEmpty) {
      return val.length >= 10;
    }

    final sigLen = signatureLength;
    if (val.length < 6 + 4 + sigLen) return false;

    final message = val.sublist(0, 10); // shortId(6) + ts(4)
    final signature = val.sublist(10, 10 + sigLen);

    // Compute HMAC-SHA256 and compare first sigLen bytes
    final hmac = Hmac(sha256, _hmacKey!);
    final mac = hmac.convert(message).bytes;
    final expected = mac.sublist(0, sigLen);

    // Constant-time comparison
    if (expected.length != signature.length) return false;
    var mismatch = 0;
    for (int i = 0; i < sigLen; i++) {
      mismatch |= (expected[i] ^ signature[i]);
    }
    return mismatch == 0;
  }

  /// Public helper to verify validation payloads (for tests)
  bool verifyValidationPayload(List<int> val) => _verifyValidationPayload(val);

  /// Configure HMAC key used for validation (raw bytes). Accepts hex string via helper.
  void setHmacKey(List<int> key) {
    _hmacKey = List<int>.from(key);
  }

  /// Set hmac key from hex string like 'aabbcc...'
  void setHmacKeyFromHex(String hex) {
    final clean = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final bytes = <int>[];
    for (var i = 0; i < clean.length; i += 2) {
      final hexByte = clean.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    setHmacKey(bytes);
  }

  /// Validate a discovery object (reads characteristic and verifies HMAC)
  Future<bool> validateDiscovery(TrackerDiscovery d, {Duration timeout = const Duration(seconds: 8)}) async {
    final ok = await validateDevice(d.device, timeout: timeout);
    if (ok) {
      if (!_confirmedIds.contains(d.shortId)) {
        _confirmedIds.add(d.shortId);
        _confirmedController.add(d);
      }
    }
    return ok;
  }

  void dispose() {
    _discoverController.close();
    _confirmedController.close();
    _scanResultsSub?.cancel();
  }
}

class ManufacturerInfo {
  final int deviceType;
  final String shortId;
  ManufacturerInfo({required this.deviceType, required this.shortId});
}
