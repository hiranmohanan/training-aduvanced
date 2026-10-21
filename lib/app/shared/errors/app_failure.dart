import '../../app_constants/app_text.dart';

class AppFailure implements Exception {
  const AppFailure(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => message;
  static AppFailure from(Object error) => error is AppFailure
      ? error
      : const AppFailure('unexpected', AppText.unexpectedFailure);
}
