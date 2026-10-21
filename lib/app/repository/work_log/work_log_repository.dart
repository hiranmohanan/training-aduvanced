import '../../services/api/api_provider_service.dart';
import '../../app_constants/api_endpoints.dart';

abstract class WorkLogRepository {
  Future<void> start(String taskId);
  Future<void> stop(String entryId);
  Future<void> add(String taskId, DateTime start, DateTime end, String note);
}

class WorkLogRepositoryImpl implements WorkLogRepository {
  WorkLogRepositoryImpl(this.api);
  final ApiProviderService api;
  @override
  Future<void> start(String taskId) async {
    await api.request('POST', ApiEndpoints.startWork, body: {'taskId': taskId});
  }

  @override
  Future<void> stop(String entryId) async {
    await api.request('POST', ApiEndpoints.stopWork(entryId));
  }

  @override
  Future<void> add(
    String taskId,
    DateTime start,
    DateTime end,
    String note,
  ) async {
    await api.request(
      'POST',
      ApiEndpoints.workEntries,
      body: {
        'taskId': taskId,
        'startedAt': start.toUtc().toIso8601String(),
        'endedAt': end.toUtc().toIso8601String(),
        'note': note,
      },
    );
  }
}
