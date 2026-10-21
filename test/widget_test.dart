import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:teamflow/app/app.dart';
import 'package:teamflow/app/app_constants/app_text.dart';
import 'package:teamflow/app/feature/home/view/home_view.dart';
import 'package:teamflow/app/models/enums.dart';
import 'support/test_app.dart';

Future<void> login(WidgetTester tester, String phone) async {
  await tester.enterText(find.byKey(const Key('auth_phone')), phone);
  await tester.ensureVisible(find.byKey(const Key('auth_send')));
  await tester.tap(find.byKey(const Key('auth_send')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('auth_code')), '123456');
  await tester.tap(find.byKey(const Key('auth_verify')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('all nine demo accounts render the correct role dashboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fixture = testApp();
    final accounts = fixture.auth.demoAccounts;
    await fixture.dispose();
    for (final account in accounts) {
      await tester.pumpWidget(
        TeamFlowApp(
          key: UniqueKey(),
          services: testApp(),
          initialLocation: '/login',
        ),
      );
      await tester.pumpAndSettle();
      await login(tester, account.phone);
      expect(find.byType(HomeView), findsOneWidget);
      final title = switch (account.role) {
        UserRole.employee => AppText.greeting(account.name.split(' ').first),
        UserRole.admin => AppText.teamOverview,
        UserRole.superAdmin => AppText.companyOverview,
      };
      expect(find.text(title), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'cold protected link resumes after login and forbidden task is hidden',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        TeamFlowApp(services: testApp(), initialLocation: '/tasks/T001'),
      );
      await tester.pumpAndSettle();
      await login(tester, '+12025550101');
      expect(find.text('Redesign client dashboard'), findsOneWidget);
      final router = GoRouter.of(
        tester.element(find.text('Redesign client dashboard')),
      );
      router.go('/tasks/T004');
      await tester.pumpAndSettle();
      expect(find.text(AppText.accessDenied), findsOneWidget);
      expect(find.text('Build task list filters'), findsNothing);
      router.go('/admin/users');
      await tester.pumpAndSettle();
      expect(find.text(AppText.accessDenied), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
  testWidgets('admin assignment form creates a task and opens its detail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      TeamFlowApp(services: testApp(), initialLocation: '/login'),
    );
    await tester.pumpAndSettle();
    await login(tester, '+12025550111');
    final router = GoRouter.of(tester.element(find.byType(HomeView)));
    router.go('/tasks/new');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task_title')),
      'Workshop release checklist',
    );
    await tester.enterText(
      find.byKey(const Key('task_description')),
      'Prepare the release checklist.',
    );
    await tester.ensureVisible(find.byKey(const Key('task_assignee')));
    await tester.tap(find.byKey(const Key('task_assignee')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rahul Dev').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('task_assign_submit')));
    await tester.tap(find.byKey(const Key('task_assign_submit')));
    await tester.pumpAndSettle();
    expect(find.text('Workshop release checklist'), findsOneWidget);
    expect(find.text('Rahul Dev'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
  testWidgets(
    '360px layouts and reports support enlarged text without overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        TeamFlowApp(services: testApp(), initialLocation: '/'),
      );
      await tester.pumpAndSettle();
      await login(tester, '+12025550199');
      expect(tester.takeException(), isNull, reason: 'login and dashboard');
      final router = GoRouter.of(tester.element(find.byType(HomeView)));
      for (final route in [
        '/reports',
        '/profile',
        '/employees',
        '/admin/users',
        '/company',
        '/settings',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    },
  );
}
