import 'package:equatable/equatable.dart';
import 'enums.dart';

class Task extends Equatable {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.teamId,
    required this.assigneeId,
    required this.createdById,
    required this.status,
    required this.priority,
    required this.progress,
    required this.dueAt,
    required this.updatedAt,
    this.completedAt,
  });
  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id: j['id'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    teamId: j['teamId'] as String,
    assigneeId: j['assigneeId'] as String,
    createdById: j['createdById'] as String,
    status: TaskStatus.values.byName(j['status'] as String),
    priority: TaskPriority.values.byName(j['priority'] as String),
    progress: j['progress'] as int,
    dueAt: DateTime.parse(j['dueAt'] as String),
    updatedAt: DateTime.parse(j['updatedAt'] as String),
    completedAt: j['completedAt'] == null
        ? null
        : DateTime.parse(j['completedAt'] as String),
  );
  final String id, title, description, teamId, assigneeId, createdById;
  final TaskStatus status;
  final TaskPriority priority;
  final int progress;
  final DateTime dueAt, updatedAt;
  final DateTime? completedAt;
  bool get isDone => status == TaskStatus.done;
  bool isOverdue(DateTime now) => !isDone && dueAt.isBefore(now);
  @override
  List<Object?> get props => [
    id,
    title,
    description,
    teamId,
    assigneeId,
    createdById,
    status,
    priority,
    progress,
    dueAt,
    updatedAt,
    completedAt,
  ];
}

class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.priority,
    required this.dueAt,
  });
  final String title, description, assigneeId;
  final TaskPriority priority;
  final DateTime dueAt;
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'assigneeId': assigneeId,
    'priority': priority.name,
    'dueAt': dueAt.toUtc().toIso8601String(),
  };
}
