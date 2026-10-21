import '../models/app_user.dart';
import '../models/enums.dart';
import '../models/task.dart';

abstract final class AccessPolicy {
  static bool canReadTask(AppUser user, Task task) =>
      user.isSuper ||
      (user.isEmployee
          ? task.assigneeId == user.id
          : task.teamId == user.managedTeamId);
  static bool canManageTask(AppUser user, Task task) =>
      !user.isEmployee && canReadTask(user, task);
  static bool canReadPerson(AppUser user, AppUser person) =>
      user.id == person.id ||
      user.isSuper ||
      (user.role == UserRole.admin &&
          person.role == UserRole.employee &&
          person.teamId == user.managedTeamId);
}
