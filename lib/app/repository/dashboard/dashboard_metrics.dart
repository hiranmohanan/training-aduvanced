import '../../models/enums.dart';
import '../../models/task.dart';
import '../../models/work_entry.dart';

class DashboardMetrics {
  DashboardMetrics({
    required Iterable<Task> tasks,
    required Iterable<WorkEntry> entries,
    required DateTime now,
    required DateTime weekStart,
  }) : tasks = List.unmodifiable(tasks),
       counts = {
         for (final s in TaskStatus.values)
           s: tasks.where((t) => t.status == s).length,
       },
       overdue = tasks.where((t) => t.isOverdue(now)).length,
       dailyHours = List.generate(7, (day) {
         final start = weekStart.add(Duration(days: day)),
             end = weekStart.add(Duration(days: day + 1));
         return entries.where((e) => e.endedAt != null).fold<double>(0, (
           sum,
           e,
         ) {
           final a = e.startedAt.isAfter(start) ? e.startedAt : start;
           final b = e.endedAt!.isBefore(end) ? e.endedAt! : end;
           return sum + (b.isAfter(a) ? b.difference(a).inSeconds / 3600 : 0);
         });
       });
  final List<Task> tasks;
  final Map<TaskStatus, int> counts;
  final int overdue;
  final List<double> dailyHours;
  int get done => counts[TaskStatus.done]!;
  int get active => tasks.length - done;
  double get hours => dailyHours.fold(0, (a, b) => a + b);
  int get completion => tasks.isEmpty ? 0 : (done / tasks.length * 100).round();
}
