// Minimal pseudocode for tracker firmware (C-like pseudo)
// - Advertises Tracker Service UUID
// - Puts short ID + flags into manufacturer data
// - Exposes a read-only validation characteristic that returns [deviceId, timestamp, signature]

#include <stdint.h>
#include <stdbool.h>

// PSEUDOCODE: replace with actual BLE stack APIs (e.g., NimBLE, Zephyr, ESP-IDF)

// Config
const uint8_t SERVICE_UUID[16] = {0x00,0x00,0xFE,0xED, 0x00,0x00,0x10,0x00, 0x80,0x00,0x00,0x80,0x5F,0x9B,0x34,0xFB};
const uint16_t MANUFACTURER_ID = 0x1234;
uint8_t SHORT_ID[6]; // assigned/per-device

void advertise_start() {
  // manufact data: [deviceType(1), fwMajor(1), flags(1), shortId(6), crc(4)]
  uint8_t manuf[12];
  manuf[0] = 0x01; // device type tracker
  manuf[1] = 0x01; // fw major
  manuf[2] = 0x00; // flags
  memcpy(&manuf[3], SHORT_ID, 6);
  uint32_t crc = crc32(manuf, 9);
  memcpy(&manuf[9], &crc, 4);

  ble_advertise_with_service_and_manufacturer(SERVICE_UUID, MANUFACTURER_ID, manuf, sizeof(manuf));
}

// Validation char read handler
// Return: [shortId(6) | unix_ts(4) | signature(8)]
int on_read_validation_char(uint8_t *outBuf, int maxLen) {
  uint32_t ts = get_unix_time();
  uint8_t payload[18];
  memcpy(payload, SHORT_ID, 6);
  memcpy(&payload[6], &ts, 4);
  // signature = HMAC(secret, SHORT_ID || ts) truncated to 8 bytes
  uint8_t sig[8];
  hmac_sha256_truncate(secret_key, secret_len, payload, 10, sig, 8);
  memcpy(&payload[10], sig, 8);

  int len = 18;
  if (maxLen < len) return 0;
  memcpy(outBuf, payload, len);
  return len;
}

void main_loop() {
  ble_init();
  advertise_start();
  while (1) {
    // sleep or low power loop
    power_manage();
  }
}
