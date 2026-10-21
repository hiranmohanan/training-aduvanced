import '../../models/workspace_data.dart';
import '../../app_constants/api_endpoints.dart';
import '../../services/api/api_provider_service.dart';

abstract class WorkspaceRepository {
  Stream<void> get changes;
  Future<WorkspaceData> read();
}

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  WorkspaceRepositoryImpl(this.api);
  final ApiProviderService api;
  @override
  Stream<void> get changes => api.changes;
  @override
  Future<WorkspaceData> read() async => WorkspaceData.fromJson(
    (await api.request('GET', ApiEndpoints.dashboard))['data'] as Json,
  );
}
