import 'package:equatable/equatable.dart';

class WorkEntry extends Equatable {
  const WorkEntry({
    required this.id,
    required this.taskId,
    required this.employeeId,
    required this.startedAt,
    required this.note,
    this.endedAt,
  });
  factory WorkEntry.fromJson(Map<String, dynamic> j) => WorkEntry(
    id: j['id'] as String,
    taskId: j['taskId'] as String,
    employeeId: j['employeeId'] as String,
    startedAt: DateTime.parse(j['startedAt'] as String),
    note: j['note'] as String? ?? '',
    endedAt: j['endedAt'] == null
        ? null
        : DateTime.parse(j['endedAt'] as String),
  );
  final String id, taskId, employeeId, note;
  final DateTime startedAt;
  final DateTime? endedAt;
  bool get isRunning => endedAt == null;
  Duration get closedDuration =>
      endedAt?.difference(startedAt) ?? Duration.zero;
  @override
  List<Object?> get props => [id, taskId, employeeId, startedAt, endedAt, note];
}
