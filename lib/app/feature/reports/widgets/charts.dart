import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../repository/dashboard/dashboard_metrics.dart';
import '../../../services/clock/clock_service.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';

class HoursChart extends StatelessWidget {
  const HoursChart(
    this.values, {
    super.key,
    this.title = AppText.dailyHours,
    this.subtitle = AppText.currentWeek,
  });
  final List<double> values;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Gap(5),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const Gap(24),
        SizedBox(
          height: 135,
          child: BarChart(
            BarChartData(
              maxY: values.fold<double>(1, (a, b) => a > b ? a : b) * 1.25,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, index, rod, rodIndex) =>
                      BarTooltipItem(
                        AppText.hours(ClockService.hours(rod.toY)),
                        const TextStyle(color: Colors.white),
                      ),
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 27,
                    getTitlesWidget: (value, meta) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        const ['M', 'T', 'W', 'T', 'F', 'S', 'S'][value
                            .toInt()
                            .clamp(0, 6)],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              barGroups: List.generate(
                7,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: 20,
                      color: i == 2 ? AppColors.blue : const Color(0xFFB8C8FF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const Gap(10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: List.generate(
            7,
            (i) => Text(
              '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i]} ${ClockService.hours(values[i])}h',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ),
        ),
      ],
    ),
  );
}

class StatusChart extends StatelessWidget {
  const StatusChart(this.metrics, {super.key});
  final DashboardMetrics metrics;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppText.taskStatus,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const Gap(20),
        if (metrics.tasks.isEmpty)
          const Text(AppText.emptyTasks)
        else
          Wrap(
            spacing: 20,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 140,
                height: 150,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 47,
                        sectionsSpace: 0,
                        sections: [
                          for (final status in TaskStatus.values)
                            if (metrics.counts[status]! > 0)
                              PieChartSectionData(
                                value: metrics.counts[status]!.toDouble(),
                                color: statusColor(status),
                                radius: 17,
                                showTitle: false,
                              ),
                        ],
                      ),
                    ),
                    Text(
                      '${metrics.tasks.length}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                child: Column(
                  children: [
                    for (final status in TaskStatus.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: statusColor(status),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status.label,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            Text(
                              '${metrics.counts[status]}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
      ],
    ),
  );
}
