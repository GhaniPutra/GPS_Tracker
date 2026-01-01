import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

class KeyManager {
  KeyManager._internal();
  static final KeyManager _i = KeyManager._internal();
  factory KeyManager() => _i;

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'gps_tracker_hmac_hex';

  /// Returns HMAC key as bytes if present, otherwise null.
  Future<List<int>?> getKeyBytes() async {
    final hex = await _storage.read(key: _storageKey);
    if (hex == null || hex.isEmpty) return null;
    return _hexToBytes(hex);
  }

  Future<void> setKeyFromHex(String hex) async {
    await _storage.write(key: _storageKey, value: hex);
  }

  Future<void> clearKey() async {
    await _storage.delete(key: _storageKey);
  }

  /// Fetch key from remote config endpoint defined in AppConfig.hmacRemoteUrl
  /// Expected JSON: { "hmacKeyHex": "aabbcc..." }
  Future<List<int>?> fetchFromRemote() async {
    const url = AppConfig.hmacRemoteUrl;
    if (url.isEmpty) return null;

    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return null;

    try {
      final Map<String, dynamic> j = jsonDecode(resp.body);
      final hex = (j['hmacKeyHex'] as String?)?.trim() ?? '';
      if (hex.isEmpty) return null;
      await setKeyFromHex(hex);
      return _hexToBytes(hex);
    } catch (_) {
      return null;
    }
  }

  static List<int> _hexToBytes(String hex) {
    final clean = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    final bytes = <int>[];
    for (var i = 0; i < clean.length; i += 2) {
      final byte = clean.substring(i, i + 2);
      bytes.add(int.parse(byte, radix: 16));
    }
    return bytes;
  }
}
