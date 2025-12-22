/// App-level config for BLE keys and other environment values.
/// IMPORTANT: For production, store keys in secure storage or fetch from server.
class AppConfig {
  // Hex-encoded HMAC key used for validation. Prefer to use secure storage or remote fetch.
  static const String hmacKeyHex = ''; // e.g. 'aabbcc...'

  // Remote config endpoint to fetch HMAC key if not present in secure storage
  // Example response: { "hmacKeyHex": "aabbcc..." }
  static const String hmacRemoteUrl = ''; // e.g. 'https://example.com/config'
}
