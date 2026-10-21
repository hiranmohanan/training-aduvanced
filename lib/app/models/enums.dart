import '../app_constants/app_text.dart';

enum UserRole {
  employee(AppText.employee),
  admin(AppText.admin),
  superAdmin(AppText.superAdmin);

  const UserRole(this.label);
  final String label;
}

enum TaskStatus {
  todo(AppText.todo),
  inProgress(AppText.inProgress),
  blocked(AppText.blocked),
  inReview(AppText.inReview),
  done(AppText.done);

  const TaskStatus(this.label);
  final String label;
}

enum TaskPriority {
  low(AppText.low),
  medium(AppText.medium),
  high(AppText.high);

  const TaskPriority(this.label);
  final String label;
}
