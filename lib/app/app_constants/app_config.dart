abstract final class AppConfig {
  static const name = 'TeamFlow';
  static const company = 'Northstar Studio';
  static const versionFallback = '1.0.0';
  static const termsVersion = 'demo-1';
  static const seedAsset = 'assets/data/mock_seed.json';
  static const useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const otp = '123456';
  static const networkTimeout = Duration(seconds: 15);
  static const otpLifetime = Duration(minutes: 5);
  static const resendDelay = Duration(seconds: 30);
  static const pagePadding = 20.0;
}
