import '../../models/task.dart';
import '../../models/enums.dart';
import '../../services/api/api_provider_service.dart';
import '../../app_constants/api_endpoints.dart';

abstract class TaskRepository {
  Future<Task> read(String id);
  Future<Task> create(TaskDraft draft);
  Future<void> update(
    String id, {
    required int progress,
    required String note,
    required TaskStatus status,
    String blocker = '',
  });
  Future<void> review(String id, {required bool approve, required String note});
  Future<void> reassign(String id, String employeeId);
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl(this.api);
  final ApiProviderService api;
  @override
  Future<Task> read(String id) async => Task.fromJson(
    (await api.request('GET', ApiEndpoints.task(id)))['data'] as Json,
  );
  @override
  Future<Task> create(TaskDraft draft) async => Task.fromJson(
    (await api.request(
          'POST',
          ApiEndpoints.tasks,
          body: draft.toJson(),
        ))['data']
        as Json,
  );
  @override
  Future<void> update(
    String id, {
    required int progress,
    required String note,
    required TaskStatus status,
    String blocker = '',
  }) async {
    await api.request(
      'POST',
      ApiEndpoints.updates(id),
      body: {
        'progress': progress,
        'note': note,
        'requestedStatus': status.name,
        'blocker': blocker,
      },
    );
  }

  @override
  Future<void> review(
    String id, {
    required bool approve,
    required String note,
  }) async {
    await api.request(
      'POST',
      ApiEndpoints.review(id),
      body: {'decision': approve ? 'approve' : 'requestChanges', 'note': note},
    );
  }

  @override
  Future<void> reassign(String id, String employeeId) async {
    await api.request(
      'POST',
      ApiEndpoints.assignment(id),
      body: {'assigneeId': employeeId},
    );
  }
}
