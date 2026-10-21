import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../services/api/api_provider_service.dart';
import '../../app_constants/api_endpoints.dart';

abstract class EmployeeRepository {
  Future<AppUser> read(String id);
  Future<void> changeAccess(
    String id,
    UserRole role,
    bool active,
    String? teamId,
  );
}

class EmployeeRepositoryImpl implements EmployeeRepository {
  EmployeeRepositoryImpl(this.api);
  final ApiProviderService api;
  @override
  Future<AppUser> read(String id) async => AppUser.fromJson(
    (await api.request('GET', ApiEndpoints.employee(id)))['data'] as Json,
  );
  @override
  Future<void> changeAccess(
    String id,
    UserRole role,
    bool active,
    String? teamId,
  ) async {
    await api.request(
      'PATCH',
      ApiEndpoints.access(id),
      body: {'role': role.name, 'isActive': active, 'managedTeamId': teamId},
    );
  }
}
