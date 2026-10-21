import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_config.dart';
import '../../../app_constants/app_text.dart';
import '../../../repository/auth/auth_repository.dart';
import '../../../services/clock/clock_service.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _phone = TextEditingController();
  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) => PageColumn(
          children: [
            const Gap(36),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.blue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.checklist, color: Colors.white),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    AppConfig.name,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const Gap(32),
            const Text(
              AppConfig.company,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(22),
            const Text(
              AppText.signInTitle,
              style: TextStyle(
                fontSize: 34,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(18),
            const Text(
              AppText.signInSubtitle,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const Gap(38),
            TextField(
              key: const Key('auth_phone'),
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: AppText.phone,
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              onSubmitted: (_) {
                if (!state.busy) {
                  context.read<AuthBloc>().add(PhoneSubmitted(_phone.text));
                }
              },
            ),
            const Gap(16),
            if (state.error != null) ...[
              Text(state.error!, style: const TextStyle(color: AppColors.red)),
              const Gap(12),
            ],
            FilledButton(
              key: const Key('auth_send'),
              onPressed: state.busy
                  ? null
                  : () => context.read<AuthBloc>().add(
                      PhoneSubmitted(_phone.text),
                    ),
              child: state.busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppText.sendCode),
            ),
            const Gap(28),
            const SectionTitle(AppText.demoAccounts),
            const Gap(10),
            for (final account
                in context.read<AuthRepository>().demoAccounts) ...[
              AppCard(
                onTap: () => setState(() => _phone.text = account.phone),
                child: Row(
                  children: [
                    PersonAvatar(account.name),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${account.role.label} · ${account.phone}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 15,
                      color: AppColors.muted,
                    ),
                  ],
                ),
              ),
              const Gap(10),
            ],
            const Gap(12),
            const Text(
              AppText.noSms,
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class VerifyView extends StatefulWidget {
  const VerifyView({super.key});
  @override
  State<VerifyView> createState() => _VerifyViewState();
}

class _VerifyViewState extends State<VerifyView> {
  final _code = TextEditingController();
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    builder: (context, state) {
      final challenge = state.challenge;
      final seconds = challenge == null
          ? 0
          : AppConfig.resendDelay.inSeconds -
                context
                    .read<ClockService>()
                    .now
                    .difference(challenge.issuedAt)
                    .inSeconds;
      return Scaffold(
        appBar: AppBar(title: const Text(AppText.verifyTitle)),
        body: SafeArea(
          child: PageColumn(
            children: [
              const Gap(28),
              AppCard(
                color: AppColors.pale,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_outlined, color: AppColors.blue),
                    const Gap(12),
                    Text(AppText.codeFor(challenge?.phone ?? '')),
                  ],
                ),
              ),
              const Gap(38),
              TextField(
                key: const Key('auth_code'),
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 14),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(labelText: AppText.otpLabel),
                onSubmitted: (_) {
                  if (!state.busy) {
                    context.read<AuthBloc>().add(CodeSubmitted(_code.text));
                  }
                },
              ),
              const Gap(18),
              if (state.error != null) ...[
                Text(
                  state.error!,
                  style: const TextStyle(color: AppColors.red),
                ),
                const Gap(14),
              ],
              FilledButton(
                key: const Key('auth_verify'),
                onPressed: state.busy
                    ? null
                    : () => context.read<AuthBloc>().add(
                        CodeSubmitted(_code.text),
                      ),
                child: state.busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(AppText.verify),
              ),
              const Gap(16),
              TextButton(
                onPressed: seconds > 0 || state.busy || challenge == null
                    ? null
                    : () => context.read<AuthBloc>().add(
                        PhoneSubmitted(challenge.phone),
                      ),
                child: Text(
                  seconds > 0 ? AppText.resendIn(seconds) : AppText.resend,
                ),
              ),
              TextButton(
                onPressed: state.busy
                    ? null
                    : () =>
                          context.read<AuthBloc>().add(PhoneChangeRequested()),
                child: const Text(AppText.changePhone),
              ),
              const Gap(30),
              const AppCard(
                child: Text(AppText.demoOtp, style: TextStyle(height: 1.7)),
              ),
            ],
          ),
        ),
      );
    },
  );
}
