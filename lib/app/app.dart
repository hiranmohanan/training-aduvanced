import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_constants/app_config.dart';
import 'app_constants/app_metadata.dart';
import 'bootstrap/app_bootstrap.dart';
import 'feature/auth/bloc/auth_bloc.dart';
import 'repository/auth/auth_repository.dart';
import 'repository/workspace/workspace_repository.dart';
import 'repository/task/task_repository.dart';
import 'repository/work_log/work_log_repository.dart';
import 'repository/employee/employee_repository.dart';
import 'repository/demo/demo_repository.dart';
import 'services/clock/clock_service.dart';
import 'services/timer/work_timer_service.dart';
import 'services/deep_link/deep_link_service.dart';
import 'services/navigation/navigation_service.dart';
import 'services/navigation/app_router.dart';
import 'theme/app_theme.dart';

class TeamFlowApp extends StatefulWidget {
  const TeamFlowApp({super.key, required this.services, this.initialLocation});
  final AppBootstrap services;
  final String? initialLocation;
  @override
  State<TeamFlowApp> createState() => _TeamFlowAppState();
}

class _TeamFlowAppState extends State<TeamFlowApp> {
  late final AuthBloc _auth;
  late final AppRouter _router;
  final DeepLinkService _links = DeepLinkService();
  @override
  void initState() {
    super.initState();
    _auth = AuthBloc(widget.services.auth);
    _router = AppRouter(
      _auth,
      widget.services,
      _links,
      initialLocation: widget.initialLocation,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.close();
    widget.services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: services.auth),
        RepositoryProvider<WorkspaceRepository>.value(
          value: services.workspace,
        ),
        RepositoryProvider<TaskRepository>.value(value: services.tasks),
        RepositoryProvider<WorkLogRepository>.value(value: services.work),
        RepositoryProvider<EmployeeRepository>.value(value: services.employees),
        RepositoryProvider<DemoRepository>.value(value: services.demo),
        RepositoryProvider<ClockService>.value(value: services.clock),
        RepositoryProvider<WorkTimerService>.value(value: services.timer),
        RepositoryProvider<AppMetadata>.value(value: services.metadata),
        RepositoryProvider<DeepLinkService>.value(value: _links),
        RepositoryProvider<NavigationService>.value(
          value: NavigationService(_router.router),
        ),
      ],
      child: BlocProvider.value(
        value: _auth,
        child: MaterialApp.router(
          title: AppConfig.name,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: _router.router,
        ),
      ),
    );
  }
}
