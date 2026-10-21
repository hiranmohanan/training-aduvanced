import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_config.dart';
import '../../../app_constants/app_metadata.dart';
import '../../../app_constants/app_routes.dart';
import '../../../app_constants/app_text.dart';
import '../../../repository/demo/demo_repository.dart';
import '../../../services/deep_link/deep_link_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/settings_bloc.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (c) => SettingsBloc(c.read<DemoRepository>()),
    child: BlocConsumer<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state.reset) {
          context.read<DeepLinkService>().clear();
          context.read<AuthBloc>().add(SessionReset());
        }
      },
      builder: (context, state) {
        final user = context.read<AuthBloc>().state.user,
            metadata = context.read<AppMetadata>();
        return Scaffold(
          appBar: AppBar(title: const Text(AppText.settings)),
          body: SafeArea(
            child: PageColumn(
              children: [
                if (user != null) PersonTile(user, subtitle: user.role.label),
                const Gap(20),
                AppCard(
                  child: Column(
                    children: [
                      DetailRow(AppText.appVersion, metadata.version),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppText.company),
                        subtitle: const Text(AppConfig.company),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.read<NavigationService>().push(
                          AppRoutes.company,
                        ),
                      ),
                      const DetailRow(AppText.mode, AppText.demo),
                      const Text(
                        AppText.resetHint,
                        style: TextStyle(fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppText.terms),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _legal(context, AppText.terms, metadata.terms),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(AppText.privacy),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            _legal(context, AppText.privacy, metadata.privacy),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                AppCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(AppText.offlineScenario),
                    subtitle: const Text(AppText.offlineHint),
                    value: state.offline,
                    onChanged: (value) =>
                        context.read<SettingsBloc>().add(OfflineChanged(value)),
                  ),
                ),
                const Gap(18),
                const AppCard(
                  color: AppColors.pale,
                  child: Text(
                    AppText.sampleHint,
                    style: TextStyle(height: 1.6),
                  ),
                ),
                const Gap(24),
                OutlinedButton(
                  key: const Key('logout'),
                  onPressed: () {
                    context.read<DeepLinkService>().clear();
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                  child: const Text(AppText.logout),
                ),
                const Gap(10),
                TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialog) => AlertDialog(
                        title: const Text(AppText.resetTitle),
                        content: const Text(AppText.resetBody),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialog, false),
                            child: const Text(AppText.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialog, true),
                            child: const Text(AppText.reset),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      context.read<SettingsBloc>().add(DemoResetRequested());
                    }
                  },
                  child: const Text(AppText.reset),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
  void _legal(BuildContext context, String title, String content) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (context) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: .75,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SectionTitle(title),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Text(content, style: const TextStyle(height: 1.6)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
