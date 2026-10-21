import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_routes.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../repository/dashboard/dashboard_metrics.dart';
import '../../../services/clock/clock_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../reports/widgets/charts.dart';
import '../bloc/home_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthBloc>().state.user;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final nav = context.read<NavigationService>();
    return FeaturePage(
      title: user.isEmployee
          ? AppText.greeting(user.firstName)
          : user.isSuper
          ? AppText.companyOverview
          : AppText.teamOverview,
      createBloc: (c) => HomeBloc(c.read<WorkspaceRepository>()),
      actions: [
        IconButton(
          tooltip: AppText.company,
          onPressed: () => nav.push(AppRoutes.company),
          icon: const Icon(Icons.apartment_outlined),
        ),
        IconButton(
          tooltip: AppText.settings,
          onPressed: () => nav.push(AppRoutes.settings),
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
      builder: (context, data) {
        final clock = context.read<ClockService>();
        final metrics = DashboardMetrics(
          tasks: data.tasks,
          entries: data.entries,
          now: clock.now,
          weekStart: clock.weekStart,
        );
        final current = data.tasks.where((t) => !t.isDone).toList()
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));
        return PageColumn(
          children: [
            Text(
              '${user.name} · ${user.role.label} · ${data.teamName(user.teamId)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const Gap(20),
            if (user.isEmployee || user.isSuper) ...[
              AppCard(
                color: AppColors.navy,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ClockService.date(clock.now),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const Gap(16),
                    Text(
                      user.isEmployee
                          ? AppText.activeCount(metrics.active)
                          : AppText.taskCount(data.tasks.length),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      user.isEmployee
                          ? AppText.currentWeek
                          : AppText.activeCount(metrics.active),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Gap(18),
            ],
            StatGrid(
              children: [
                StatCard(
                  AppText.assigned,
                  '${data.tasks.length}',
                  caption: '${metrics.done} ${AppText.completed.toLowerCase()}',
                ),
                StatCard(
                  AppText.weeklyHours,
                  ClockService.hours(metrics.hours),
                  caption: AppText.loggedHours,
                ),
                if (!user.isEmployee) ...[
                  StatCard(AppText.activeTasks, '${metrics.active}'),
                  StatCard(
                    AppText.overdue,
                    '${metrics.overdue}',
                    color: AppColors.amber,
                  ),
                ],
              ],
            ),
            const Gap(20),
            if (user.isSuper) ...[
              const SectionTitle(AppText.yourTeams),
              const Gap(12),
              for (final team in data.teams) ...[
                AppCard(
                  onTap: () =>
                      nav.push('${AppRoutes.employees}?team=${team.id}'),
                  child: Row(
                    children: [
                      PersonAvatar(team.name),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              team.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              data.personName(team.managerId),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        AppText.taskCount(
                          data.tasks.where((t) => t.teamId == team.id).length,
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(12),
              ],
              FilledButton(
                onPressed: () => nav.push(AppRoutes.users),
                child: const Text(AppText.manageUsers),
              ),
              const Gap(20),
            ] else ...[
              HoursChart(
                metrics.dailyHours,
                title: user.isEmployee ? AppText.yourWeek : AppText.teamHours,
              ),
              const Gap(20),
            ],
            SectionTitle(
              user.isEmployee ? AppText.currentTasks : AppText.reviewQueue,
              action: user.isEmployee ? AppText.viewAll : AppText.employees,
              onTap: () => nav.go(
                user.isEmployee ? AppRoutes.tasks : AppRoutes.employees,
              ),
            ),
            const Gap(12),
            if (user.isEmployee && current.isEmpty)
              const MessageCard(AppText.emptyTasks),
            if (!user.isEmployee &&
                !data.tasks.any((t) => t.status == TaskStatus.inReview))
              const MessageCard(AppText.emptyReview),
            for (final task
                in (user.isEmployee
                        ? current
                        : data.tasks.where(
                            (t) => t.status == TaskStatus.inReview,
                          ))
                    .take(3)) ...[
              TaskCard(
                task,
                onTap: () => nav.openTask(task.id),
                assignee: user.isEmployee
                    ? null
                    : data.personName(task.assigneeId),
              ),
              const Gap(12),
            ],
            if (!user.isEmployee) ...[
              const Gap(8),
              FilledButton.icon(
                onPressed: nav.openAssignment,
                icon: const Icon(Icons.add),
                label: const Text(AppText.assignTask),
              ),
            ],
          ],
        );
      },
    );
  }
}
