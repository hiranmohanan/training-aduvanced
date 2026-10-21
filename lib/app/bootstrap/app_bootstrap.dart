import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../app_constants/app_config.dart';
import '../app_constants/app_metadata.dart';
import '../app_constants/app_text.dart';
import '../mock/mock_database.dart';
import '../models/enums.dart';
import '../repository/auth/auth_repository.dart';
import '../repository/auth/auth_repository_impl.dart';
import '../repository/task/task_repository.dart';
import '../repository/work_log/work_log_repository.dart';
import '../repository/workspace/workspace_repository.dart';
import '../repository/employee/employee_repository.dart';
import '../repository/demo/demo_repository.dart';
import '../services/api/api_provider_service.dart';
import '../services/api/mock_api_provider.dart';
import '../services/clock/clock_service.dart';
import '../services/timer/work_timer_service.dart';

class AppBootstrap {
  AppBootstrap.fromSeed(
    Json seed, {
    ClockService? clock,
    Duration latency = const Duration(milliseconds: 180),
    AppMetadata? metadata,
  }) : clock = clock ?? ClockService(),
       metadata =
           metadata ??
           const AppMetadata(
             version: '1.0.0 (1)',
             terms: AppText.demo,
             privacy: AppText.demo,
           ) {
    final mock = MockApiProvider(
      MockDatabase(seed),
      this.clock,
      latency: latency,
    );
    api = mock;
    demo = DemoRepositoryImpl(mock);
    auth = AuthRepositoryImpl(
      api,
      List.unmodifiable(
        mock.demoAccounts.map(
          (a) => DemoAccount(
            a['name'] as String,
            a['phoneE164'] as String,
            UserRole.values.byName(a['role'] as String),
          ),
        ),
      ),
    );
    workspace = WorkspaceRepositoryImpl(api);
    tasks = TaskRepositoryImpl(api);
    work = WorkLogRepositoryImpl(api);
    employees = EmployeeRepositoryImpl(api);
    timer = WorkTimerService(this.clock);
  }
  final ClockService clock;
  final AppMetadata metadata;
  late final ApiProviderService api;
  late final AuthRepository auth;
  late final WorkspaceRepository workspace;
  late final TaskRepository tasks;
  late final WorkLogRepository work;
  late final EmployeeRepository employees;
  late final DemoRepository demo;
  late final WorkTimerService timer;
  static Future<AppBootstrap> load() async {
    if (!AppConfig.useMock) throw StateError(AppText.comingBackend);
    final seed =
        jsonDecode(await rootBundle.loadString(AppConfig.seedAsset)) as Json;
    String version = AppConfig.versionFallback;
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } on MissingPluginException {
      /* Metadata fallback for unsupported test runners. */
    }
    return AppBootstrap.fromSeed(
      seed,
      metadata: AppMetadata(
        version: version,
        terms: await rootBundle.loadString('assets/legal/demo_terms.md'),
        privacy: await rootBundle.loadString('assets/legal/demo_privacy.md'),
      ),
    );
  }

  Future<void> dispose() => api.dispose();
}
