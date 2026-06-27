import '../sms/sms_parser.dart';

/// Extension points for native/platform features deferred to later phases.
/// Each has a clean interface + a no-op implementation so the rest of the app
/// can depend on them today and the real implementation drops in without a
/// refactor. UI surfaces these via "coming soon" sheets.

enum IntegrationStatus { notImplemented, permissionRequired, ready }

abstract class SmsReader {
  /// Reads device inbox and returns parsed bank/UPI transactions (Android only).
  Future<List<ParsedSms>> readInbox();
  IntegrationStatus get status;
}

class StubSmsReader implements SmsReader {
  @override
  Future<List<ParsedSms>> readInbox() async => const [];
  @override
  IntegrationStatus get status => IntegrationStatus.notImplemented;
}

abstract class OcrService {
  /// Extracts a draft transaction from a receipt image/PDF.
  Future<ParsedSms?> scan(String path);
  IntegrationStatus get status;
}

class StubOcrService implements OcrService {
  @override
  Future<ParsedSms?> scan(String path) async => null;
  @override
  IntegrationStatus get status => IntegrationStatus.notImplemented;
}

abstract class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class StubBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate(String reason) async => true; // no-op passthrough
}

abstract class NotificationService {
  Future<void> scheduleDailySummary();
  IntegrationStatus get status;
}

class StubNotificationService implements NotificationService {
  @override
  Future<void> scheduleDailySummary() async {}
  @override
  IntegrationStatus get status => IntegrationStatus.notImplemented;
}

abstract class AdsService {
  bool get enabled;
  Future<void> maybeShowAppOpen();
}

class StubAdsService implements AdsService {
  @override
  bool get enabled => false;
  @override
  Future<void> maybeShowAppOpen() async {}
}
