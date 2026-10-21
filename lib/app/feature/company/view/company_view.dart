import 'package:flutter/material.dart';
import '../../../app_constants/app_config.dart';
import '../../../app_constants/app_text.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';

class CompanyView extends StatelessWidget {
  const CompanyView({super.key});
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.company,
    builder: (context, data) => PageColumn(
      children: [
        const AppCard(
          color: AppColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConfig.company,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Gap(14),
              Text(
                AppText.companyTimezone,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const Gap(24),
        const SectionTitle(AppText.announcements),
        const Gap(12),
        for (final notice in data.announcements) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(12),
                Text(
                  notice.body,
                  style: const TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
          const Gap(14),
        ],
        const Gap(20),
        const SectionTitle(AppText.ourTeams),
        const Gap(12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final team in data.teams) Chip(label: Text(team.name)),
          ],
        ),
        const Gap(22),
        const Text(
          AppText.workNotAttendance,
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    ),
  );
}
