import 'package:flutter_test/flutter_test.dart';
import 'package:gps_tracker_app/services/bluetooth_manager.dart';
import 'package:crypto/crypto.dart';

void main() {
  group('BluetoothManager parsing', () {
    final manager = BluetoothManager();

    test('parse valid manufacturer data', () {
      // Construct manufacturer data bytes for vendor id 0x1234
      // Layout: [deviceType, fwMajor, flags, shortId(6), crc]
      final bytes = <int>[0x02, 0x01, 0x00, 0xAA, 0xBB, 0xCC, 0xDD, 0xEE, 0xFF, 0x11];
      final md = {BluetoothManager().trackerManufacturerId: bytes};

      final info = manager.parseManufacturerData(md);
      expect(info, isNotNull);
      expect(info!.deviceType, 0x02);
      expect(info.shortId, 'aabbccddeeff');
    });

    test('parse missing manufacturer id returns null', () {
      final md = <int, List<int>>{};
      final info = manager.parseManufacturerData(md);
      expect(info, isNull);
    });

    test('validation payload length rule', () {
      // shorter than 10 -> false
      expect(manager.verifyValidationPayload(List<int>.filled(9, 0)), isFalse);
      // 10 or more -> true (no key configured)
      expect(manager.verifyValidationPayload(List<int>.filled(10, 0)), isTrue);
    });

    test('HMAC validation works when key configured', () {
      // Compose message: 6 bytes shortId + 4 bytes ts
      final shortId = [0xAA,0xBB,0xCC,0xDD,0xEE,0xFF];
      final ts = [0x00,0x00,0x00,0x01];
      final message = [...shortId, ...ts];

      // key
      final key = List<int>.generate(16, (i) => i + 1);
      manager.setHmacKey(key);

      // compute hmac sha256
      final hmac = Hmac(sha256, key);
      final mac = hmac.convert(message).bytes;
      final sig = mac.sublist(0, manager.signatureLength);

      final payload = [...message, ...sig];
      expect(manager.verifyValidationPayload(payload), isTrue);

      // tampered signature
      final bad = List<int>.from(payload);
      bad[10] = (bad[10] + 1) & 0xFF;
      expect(manager.verifyValidationPayload(bad), isFalse);
    });
  });
}
