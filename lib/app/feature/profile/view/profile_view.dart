import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_routes.dart';
import '../../../app_constants/app_text.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../repository/employee/employee_repository.dart';
import '../../../repository/dashboard/dashboard_metrics.dart';
import '../../../services/clock/clock_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../../reports/widgets/charts.dart';
import '../bloc/profile_bloc.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, this.employeeId});
  final String? employeeId;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: employeeId == null ? AppText.myProfile : AppText.employeeProfile,
    createBloc: (c) => ProfileBloc(
      c.read<WorkspaceRepository>(),
      checkAccess: employeeId == null
          ? null
          : () async {
              await c.read<EmployeeRepository>().read(employeeId!);
            },
    ),
    actions: employeeId == null
        ? [
            IconButton(
              tooltip: AppText.settings,
              onPressed: () =>
                  context.read<NavigationService>().push(AppRoutes.settings),
              icon: const Icon(Icons.settings_outlined),
            ),
          ]
        : null,
    builder: (context, data) {
      final person = data.person(employeeId ?? data.user.id);
      if (person == null) {
        return const PageColumn(children: [MessageCard(AppText.notFound)]);
      }
      final clock = context.read<ClockService>();
      final entries =
          data.entries.where((e) => e.employeeId == person.id).toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final metrics = DashboardMetrics(
        tasks: data.tasks.where((t) => t.assigneeId == person.id),
        entries: entries,
        now: clock.now,
        weekStart: clock.weekStart,
      );
      return PageColumn(
        children: [
          const Gap(12),
          Center(child: PersonAvatar(person.name, radius: 40)),
          const Gap(18),
          Text(
            person.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
          ),
          const Gap(8),
          Text(
            '${person.designation} · ${data.teamName(person.teamId)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const Gap(24),
          if (person.isEmployee) ...[
            StatGrid(
              children: [
                StatCard(AppText.assigned, '${metrics.tasks.length}'),
                StatCard(
                  AppText.completed,
                  '${metrics.done}',
                  color: AppColors.green,
                ),
              ],
            ),
            const Gap(20),
            HoursChart(
              metrics.dailyHours,
              title:
                  '${AppText.hours(ClockService.hours(metrics.hours))} · ${AppText.currentWeek}',
            ),
            const Gap(20),
          ],
          AppCard(
            child: Column(
              children: [
                DetailRow(AppText.role, person.role.label),
                DetailRow(
                  AppText.reportingTo,
                  person.managerId == null
                      ? AppText.noManager
                      : data.personName(person.managerId!),
                ),
                DetailRow(AppText.phone, person.phone),
                DetailRow(AppText.joined, ClockService.date(person.joinedAt)),
              ],
            ),
          ),
          if (person.isEmployee) ...[
            const Gap(24),
            const SectionTitle(AppText.workHistory),
            const Gap(12),
            if (entries.isEmpty) const MessageCard(AppText.noWork),
            for (final entry in entries.take(7)) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DetailRow(
                      entry.taskId,
                      entry.isRunning
                          ? AppText.running
                          : AppText.hours(
                              ClockService.hours(
                                entry.closedDuration.inSeconds / 3600,
                              ),
                            ),
                    ),
                    Text(
                      '${ClockService.shortDate(entry.startedAt)} · ${ClockService.time(entry.startedAt)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const Gap(8),
                      Text(entry.note),
                    ],
                  ],
                ),
              ),
              const Gap(10),
            ],
          ],
        ],
      );
    },
  );
}
