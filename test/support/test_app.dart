import 'dart:convert';
import 'dart:io';
import 'package:teamflow/app/bootstrap/app_bootstrap.dart';
import 'package:teamflow/app/services/clock/clock_service.dart';
import 'package:teamflow/app/services/api/api_provider_service.dart';

class TestClock extends ClockService {
  TestClock() : super(frozen: true);
  DateTime current = DateTime.utc(2026, 9, 16, 9);
  @override
  DateTime get now => current;
  void advance(Duration duration) => current = current.add(duration);
  @override
  void reset() {
    current = DateTime.utc(2026, 9, 16, 9);
  }
}

AppBootstrap testApp({TestClock? clock}) => AppBootstrap.fromSeed(
  jsonDecode(File('assets/data/mock_seed.json').readAsStringSync()) as Json,
  clock: clock ?? TestClock(),
  latency: Duration.zero,
);
Future<void> signIn(AppBootstrap app, String phone) async {
  final challenge = await app.auth.requestCode(phone);
  await app.auth.verify(challenge, '123456');
}
