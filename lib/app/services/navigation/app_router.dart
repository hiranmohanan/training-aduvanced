import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app_constants/app_routes.dart';
import '../../app_constants/app_text.dart';
import '../../bootstrap/app_bootstrap.dart';
import '../../feature/auth/bloc/auth_bloc.dart';
import '../../feature/auth/view/auth_view.dart';
import '../../feature/home/view/home_view.dart';
import '../../feature/tasks/view/tasks_view.dart';
import '../../feature/task_detail/view/task_detail_view.dart';
import '../../feature/task_form/view/task_form_view.dart';
import '../../feature/work_update/view/work_update_view.dart';
import '../../feature/profile/view/profile_view.dart';
import '../../feature/reports/view/reports_view.dart';
import '../../feature/employees/view/employees_view.dart';
import '../../feature/company/view/company_view.dart';
import '../../feature/settings/view/settings_view.dart';
import '../../shared/errors/app_failure.dart';
import '../../shared/widgets/ui.dart';
import '../deep_link/deep_link_service.dart';
import 'router_refresh_notifier.dart';

class AppRouter {
  AppRouter(this.auth, this.services, this.links, {String? initialLocation}) {
    refresh = RouterRefreshNotifier(auth.stream);
    router = GoRouter(
      initialLocation: initialLocation,
      refreshListenable: refresh,
      redirect: (context, state) async {
        final normalized = links.normalize(state.uri);
        if (normalized == null) {
          return state.uri.path == '/not-found' ? null : '/not-found';
        }
        final path = Uri.parse(normalized).path, user = auth.state.user;
        final public = path == AppRoutes.login || path == AppRoutes.verify;
        if (user == null) {
          if (path == '/not-found') return null;
          if (!public) links.remember(normalized);
          return auth.state.challenge != null
              ? (path == AppRoutes.verify ? null : AppRoutes.verify)
              : (path == AppRoutes.login ? null : AppRoutes.login);
        }
        if (public) return links.take() ?? AppRoutes.home;
        if (normalized != state.uri.toString()) return normalized;
        if ((path == AppRoutes.users && !user.isSuper) ||
            ((path == AppRoutes.assign || path == AppRoutes.employees) &&
                user.isEmployee)) {
          links.clear();
          return AppRoutes.forbidden;
        }
        final segments = state.uri.pathSegments;
        try {
          if (segments.length >= 2 &&
              segments.first == 'tasks' &&
              segments[1] != 'new') {
            final task = await services.tasks.read(segments[1]);
            if (segments.last == 'update' &&
                (!user.isEmployee || task.assigneeId != user.id)) {
              return AppRoutes.forbidden;
            }
          }
          if (segments.length == 2 && segments.first == 'employees') {
            await services.employees.read(segments[1]);
          }
        } on AppFailure catch (error) {
          if (error.code == 'forbidden') {
            links.clear();
            return AppRoutes.forbidden;
          }
          if (error.code == 'not_found') {
            links.clear();
            return '/not-found';
          }
          // Transport errors are rendered by the feature's loading state.
        }
        if (auth.state.user?.id != user.id) return AppRoutes.login;
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, _) =>
              auth.state.user == null ? AppRoutes.login : AppRoutes.home,
        ),
        GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginView()),
        GoRoute(path: AppRoutes.verify, builder: (_, _) => const VerifyView()),
        GoRoute(
          path: '/not-found',
          builder: (_, _) => const RouteMessage(AppText.notFound),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              AppShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeView()),
            GoRoute(
              path: AppRoutes.tasks,
              builder: (_, _) => const TasksView(),
            ),
            GoRoute(
              path: AppRoutes.assign,
              builder: (_, _) => const TaskFormView(),
            ),
            GoRoute(
              path: '/tasks/:id',
              builder: (_, s) => TaskDetailView(s.pathParameters['id']!),
              routes: [
                GoRoute(
                  path: 'update',
                  builder: (_, s) => WorkUpdateView(s.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: AppRoutes.employees,
              builder: (_, s) =>
                  EmployeesView(teamId: s.uri.queryParameters['team']),
            ),
            GoRoute(
              path: '/employees/:id',
              builder: (_, s) =>
                  ProfileView(employeeId: s.pathParameters['id']),
            ),
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileView(),
            ),
            GoRoute(
              path: AppRoutes.reports,
              builder: (_, _) => const ReportsView(),
            ),
            GoRoute(
              path: AppRoutes.users,
              builder: (_, _) => const EmployeesView(users: true),
            ),
            GoRoute(
              path: AppRoutes.company,
              builder: (_, _) => const CompanyView(),
            ),
            GoRoute(
              path: AppRoutes.settings,
              builder: (_, _) => const SettingsView(),
            ),
            GoRoute(
              path: AppRoutes.forbidden,
              builder: (_, _) => const RouteMessage(AppText.accessDenied),
            ),
          ],
        ),
      ],
      errorBuilder: (_, _) => const RouteMessage(AppText.notFound),
    );
  }
  final AuthBloc auth;
  final AppBootstrap services;
  final DeepLinkService links;
  late final RouterRefreshNotifier refresh;
  late final GoRouter router;
  void dispose() {
    router.dispose();
    refresh.dispose();
  }
}

class RouteMessage extends StatelessWidget {
  const RouteMessage(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: PageColumn(
      children: [
        MessageCard(message, error: true),
        const Gap(20),
        FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text(AppText.home),
        ),
      ],
    ),
  );
}

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final index = location.startsWith(AppRoutes.tasks)
        ? 1
        : location == AppRoutes.reports
        ? 2
        : location == AppRoutes.profile || location == AppRoutes.settings
        ? 3
        : 0;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(
          [
            AppRoutes.home,
            AppRoutes.tasks,
            AppRoutes.reports,
            AppRoutes.profile,
          ][i],
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: AppText.home,
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: AppText.tasks,
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: AppText.reports,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: AppText.profile,
          ),
        ],
      ),
    );
  }
}
