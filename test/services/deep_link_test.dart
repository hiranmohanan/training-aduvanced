import 'package:flutter_test/flutter_test.dart';
import 'package:teamflow/app/services/deep_link/deep_link_service.dart';

void main() {
  test(
    'custom links normalize, external redirects and malformed IDs are rejected',
    () {
      final service = DeepLinkService();
      expect(
        service.normalize(Uri.parse('teamflow://app/tasks/T001')),
        '/tasks/T001',
      );
      expect(
        service.normalize(Uri.parse('teamflow://app/employees/E001')),
        '/employees/E001',
      );
      expect(
        service.normalize(Uri.parse('https://untrusted.example/tasks/T001')),
        isNull,
      );
      expect(
        service.normalize(Uri.parse('//untrusted.example/tasks/T001')),
        isNull,
      );
      expect(service.normalize(Uri.parse('/tasks/a/b')), isNull);
      service.remember('/tasks/T001?token=secret');
      expect(service.take(), '/tasks/T001');
      expect(service.take(), isNull);
      service.remember('/tasks/T002');
      service.clear();
      expect(service.take(), isNull);
    },
  );
}
