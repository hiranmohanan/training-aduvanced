import 'package:flutter_test/flutter_test.dart';
import 'package:teamflow/app/bootstrap/app_bootstrap.dart';
import 'package:teamflow/app/app_constants/api_endpoints.dart';
import 'package:teamflow/app/models/enums.dart';
import 'package:teamflow/app/models/task.dart';
import 'package:teamflow/app/models/work_entry.dart';
import 'package:teamflow/app/repository/dashboard/dashboard_metrics.dart';
import 'package:teamflow/app/shared/errors/app_failure.dart';
import '../support/test_app.dart';

Matcher failure(String code) =>
    throwsA(isA<AppFailure>().having((e) => e.code, 'code', code));
void main() {
  late AppBootstrap app;
  late TestClock clock;
  setUp(() {
    clock = TestClock();
    app = testApp(clock: clock);
  });
  tearDown(() async {
    await app.dispose();
  });
  test(
    'nine unique phones resolve five employees, three admins and a super admin',
    () async {
      final roles = <UserRole, int>{};
      for (final account in app.auth.demoAccounts) {
        await signIn(app, account.phone);
        final data = await app.workspace.read();
        expect(data.user.name, account.name);
        roles.update(data.user.role, (n) => n + 1, ifAbsent: () => 1);
        await app.auth.logout();
      }
      expect(roles, {
        UserRole.employee: 5,
        UserRole.admin: 3,
        UserRole.superAdmin: 1,
      });
    },
  );
  test('unknown phone, wrong code, resend cooldown and expiry fail', () async {
    await expectLater(app.auth.requestCode('999'), failure('validation'));
    final challenge = await app.auth.requestCode('+12025550101');
    await expectLater(
      app.auth.verify(challenge, '000000'),
      failure('validation'),
    );
    await expectLater(
      app.auth.requestCode('+12025550101'),
      failure('cooldown'),
    );
    clock.advance(const Duration(minutes: 6));
    await expectLater(app.auth.verify(challenge, '123456'), failure('expired'));
    final fresh = await app.auth.requestCode('+12025550101');
    expect((await app.auth.verify(fresh, '123456')).id, 'E001');
  });
  test('company and team summaries reconcile with seed records', () async {
    await signIn(app, '+12025550199');
    var data = await app.workspace.read();
    var m = DashboardMetrics(
      tasks: data.tasks,
      entries: data.entries,
      now: clock.now,
      weekStart: clock.weekStart,
    );
    expect([m.tasks.length, m.active, m.done, m.overdue], [15, 11, 4, 2]);
    expect(m.hours, 54);
    expect(m.dailyHours, [20.5, 21, 12.5, 0, 0, 0, 0]);
    await app.auth.logout();
    await signIn(app, '+12025550111');
    data = await app.workspace.read();
    m = DashboardMetrics(
      tasks: data.tasks,
      entries: data.entries,
      now: clock.now,
      weekStart: clock.weekStart,
    );
    expect(m.tasks.length, 6);
    expect(m.hours, 21.5);
    expect(data.people.where((p) => p.isEmployee).length, 2);
  });
  test(
    'employee read/write scope and admin team scope are enforced by API',
    () async {
      await signIn(app, '+12025550101');
      expect((await app.tasks.read('T001')).assigneeId, 'E001');
      await expectLater(app.tasks.read('T004'), failure('forbidden'));
      await expectLater(app.employees.read('E002'), failure('forbidden'));
      await expectLater(
        app.api.request('GET', ApiEndpoints.users),
        failure('forbidden'),
      );
      await expectLater(
        app.tasks.review('T001', approve: true, note: ''),
        failure('forbidden'),
      );
      await app.auth.logout();
      await signIn(app, '+12025550111');
      await expectLater(app.tasks.read('T007'), failure('forbidden'));
      await expectLater(
        app.tasks.reassign('T001', 'E003'),
        failure('validation'),
      );
    },
  );
  test(
    'assignment -> employee time -> review -> approval persists across logins',
    () async {
      await signIn(app, '+12025550111');
      final task = await app.tasks.create(
        TaskDraft(
          title: 'Workshop handoff',
          description: 'Prepare release notes',
          assigneeId: 'E002',
          priority: TaskPriority.medium,
          dueAt: clock.now.add(const Duration(days: 1)),
        ),
      );
      await app.auth.logout();
      await signIn(app, '+12025550102');
      expect((await app.tasks.read(task.id)).status, TaskStatus.todo);
      await app.work.start(task.id);
      clock.advance(const Duration(minutes: 45));
      final open = (await app.workspace.read()).entries.singleWhere(
        (e) => e.isRunning,
      );
      await app.work.stop(open.id);
      await app.tasks.update(
        task.id,
        progress: 100,
        note: 'Handoff is complete and ready for review',
        status: TaskStatus.inReview,
      );
      await app.auth.logout();
      await signIn(app, '+12025550111');
      await app.tasks.review(task.id, approve: true, note: 'Reviewed');
      final done = await app.tasks.read(task.id);
      expect(done.status, TaskStatus.done);
      expect(done.completedAt, isNotNull);
      final data = await app.workspace.read();
      final metrics = DashboardMetrics(
        tasks: data.tasks,
        entries: data.entries,
        now: clock.now,
        weekStart: clock.weekStart,
      );
      expect(metrics.hours, 22.25);
      expect(metrics.done, 3);
      expect(data.activity.any((a) => a.taskId == task.id), isTrue);
    },
  );
  test(
    'invalid transitions, missing blocker and early review are rejected',
    () async {
      await signIn(app, '+12025550101');
      await expectLater(
        app.tasks.update(
          'T001',
          progress: 65,
          note: 'Ready for review',
          status: TaskStatus.inReview,
        ),
        failure('validation'),
      );
      await expectLater(
        app.tasks.update(
          'T001',
          progress: 65,
          note: 'Waiting on details',
          status: TaskStatus.blocked,
        ),
        failure('validation'),
      );
      await expectLater(
        app.tasks.update(
          'T001',
          progress: 65,
          note: 'Return to backlog',
          status: TaskStatus.todo,
        ),
        failure('validation'),
      );
      expect((await app.tasks.read('T001')).progress, 65);
      await app.tasks.update(
        'T001',
        progress: 70,
        note: 'Waiting for the approved brand kit',
        status: TaskStatus.blocked,
        blocker: 'Brand kit missing',
      );
      await app.tasks.update(
        'T001',
        progress: 75,
        note: 'Brand kit received and applied',
        status: TaskStatus.inProgress,
      );
      expect((await app.tasks.read('T001')).progress, 75);
    },
  );
  test(
    'running timer uniqueness, overlap and future intervals fail without mutation',
    () async {
      await signIn(app, '+12025550101');
      await app.work.start('T001');
      await expectLater(app.work.start('T002'), failure('validation'));
      await expectLater(
        app.work.add(
          'T001',
          DateTime.utc(2026, 9, 16, 4),
          DateTime.utc(2026, 9, 16, 5),
          'Duplicate work interval',
        ),
        failure('validation'),
      );
      await expectLater(
        app.work.add(
          'T001',
          clock.now,
          clock.now.add(const Duration(hours: 1)),
          'Future work interval',
        ),
        failure('validation'),
      );
      expect(
        (await app.workspace.read()).entries.where((e) => e.isRunning).length,
        1,
      );
      clock.advance(const Duration(minutes: 10));
      await app.auth.logout();
      await signIn(app, '+12025550101');
      expect(
        (await app.workspace.read()).entries.any((e) => e.isRunning),
        isFalse,
      );
    },
  );
  test(
    'manual time adds to profile, while a cross-midnight record splits by day',
    () async {
      await signIn(app, '+12025550101');
      await app.work.add(
        'T001',
        DateTime.utc(2026, 9, 16, 7, 30),
        DateTime.utc(2026, 9, 16, 8, 30),
        'Final accessibility review',
      );
      final data = await app.workspace.read();
      final metrics = DashboardMetrics(
        tasks: data.tasks,
        entries: data.entries,
        now: clock.now,
        weekStart: clock.weekStart,
      );
      expect(metrics.hours, 11.5);
      final split = DashboardMetrics(
        tasks: [],
        entries: [
          WorkEntry(
            id: 'X',
            taskId: 'T001',
            employeeId: 'E001',
            startedAt: DateTime.utc(2026, 9, 14, 17, 30),
            endedAt: DateTime.utc(2026, 9, 14, 19, 30),
            note: 'Cross-day work',
          ),
        ],
        now: clock.now,
        weekStart: clock.weekStart,
      );
      expect(split.dailyHours, [1, 1, 0, 0, 0, 0, 0]);
    },
  );
  test('admin request changes returns submitted task to in progress', () async {
    await signIn(app, '+12025550111');
    await expectLater(
      app.tasks.review('T005', approve: false, note: ''),
      failure('validation'),
    );
    await app.tasks.review(
      'T005',
      approve: false,
      note: 'Please add accessibility labels',
    );
    expect((await app.tasks.read('T005')).status, TaskStatus.inProgress);
  });
  test(
    'access changes protect super admin, managers and employees with active work',
    () async {
      await signIn(app, '+12025550199');
      await expectLater(
        app.employees.changeAccess('S001', UserRole.employee, false, null),
        failure('validation'),
      );
      await expectLater(
        app.employees.changeAccess('A001', UserRole.employee, false, null),
        failure('validation'),
      );
      await expectLater(
        app.employees.changeAccess('E001', UserRole.admin, true, 'TEAM-P'),
        failure('validation'),
      );
      await app.tasks.reassign('T001', 'E002');
      await app.tasks.reassign('T002', 'E002');
      await app.employees.changeAccess('E001', UserRole.admin, true, 'TEAM-P');
      await app.auth.logout();
      await signIn(app, '+12025550101');
      expect((await app.workspace.read()).user.role, UserRole.admin);
    },
  );
  test(
    'demo error scenario can recover, and reset invalidates session',
    () async {
      await signIn(app, '+12025550101');
      app.demo.setOffline(true);
      await expectLater(app.workspace.read(), failure('offline'));
      app.demo.setOffline(false);
      expect((await app.workspace.read()).tasks.length, 3);
      app.demo.reset();
      await expectLater(app.workspace.read(), failure('unauthorized'));
      await signIn(app, '+12025550199');
      expect((await app.workspace.read()).tasks.length, 15);
    },
  );
}
