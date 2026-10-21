import '../models/enums.dart';

abstract final class TaskTransitionPolicy {
  static bool employeeCanMove(TaskStatus from, TaskStatus to) => from == to
      ? from != TaskStatus.done && from != TaskStatus.inReview
      : switch ((from, to)) {
          (TaskStatus.todo, TaskStatus.inProgress) => true,
          (TaskStatus.inProgress, TaskStatus.blocked) => true,
          (TaskStatus.blocked, TaskStatus.inProgress) => true,
          (TaskStatus.inProgress, TaskStatus.inReview) => true,
          _ => false,
        };
}
