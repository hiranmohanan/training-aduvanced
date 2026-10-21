import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_text.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../repository/dashboard/dashboard_metrics.dart';
import '../../../services/clock/clock_service.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../bloc/reports_bloc.dart';
import '../widgets/charts.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});
  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  int _week = 0;
  String? _team;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.reports,
    createBloc: (c) => ReportsBloc(c.read<WorkspaceRepository>()),
    builder: (context, data) {
      final clock = context.read<ClockService>(),
          start = context.read<ClockService>().weekStart.add(
            Duration(days: _week * 7),
          );
      final tasks = data.tasks.where((t) => _team == null || t.teamId == _team);
      final entries = data.entries.where(
        (e) => _team == null || data.person(e.employeeId)?.teamId == _team,
      );
      final metrics = DashboardMetrics(
        tasks: tasks,
        entries: entries,
        now: clock.now,
        weekStart: start,
      );
      return PageColumn(
        children: [
          if (data.user.isSuper) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _team,
              decoration: const InputDecoration(labelText: AppText.ourTeams),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(AppText.allTeams),
                ),
                for (final t in data.teams)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (value) => setState(() => _team = value),
            ),
            const Gap(14),
          ],
          Row(
            children: [
              IconButton(
                tooltip: AppText.previousWeek,
                onPressed: () => setState(() => _week--),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${ClockService.shortDate(start)} – ${ClockService.shortDate(start.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted),
                ),
              ),
              IconButton(
                tooltip: AppText.nextWeek,
                onPressed: _week >= 0 ? null : () => setState(() => _week++),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Gap(14),
          StatGrid(
            children: [
              StatCard(
                AppText.completion,
                metrics.tasks.isEmpty
                    ? '—'
                    : AppText.percent(metrics.completion),
                caption: AppText.taskCount(metrics.tasks.length),
                color: AppColors.green,
              ),
              StatCard(
                AppText.loggedHours,
                ClockService.hours(metrics.hours),
                caption: AppText.closedEntries,
              ),
            ],
          ),
          const Gap(20),
          StatusChart(metrics),
          const Gap(20),
          HoursChart(
            metrics.dailyHours,
            subtitle:
                '${ClockService.shortDate(start)} – ${ClockService.shortDate(start.add(const Duration(days: 6)))}',
          ),
          const Gap(10),
          Text(
            AppText.workNotAttendance,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      );
    },
  );
}
