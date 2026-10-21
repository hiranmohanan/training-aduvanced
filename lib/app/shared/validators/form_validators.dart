import '../../app_constants/app_text.dart';

abstract final class FormValidators {
  static String? required(String? value) =>
      value == null || value.trim().isEmpty ? AppText.required : null;
  static String? title(String? value) =>
      (value?.trim().length ?? 0) < 3 || value!.trim().length > 100
      ? AppText.invalidTitle
      : null;
  static String? note(String? value) =>
      (value?.trim().length ?? 0) < 5 || value!.trim().length > 500
      ? AppText.invalidNote
      : null;
  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return '+${digits.length == 10 ? '1$digits' : digits}';
  }
}
