import 'dart:async';
import 'dart:convert';
import '../../app_constants/api_endpoints.dart';
import '../../app_constants/app_config.dart';
import '../../app_constants/app_text.dart';
import '../../mock/mock_database.dart';
import '../../models/app_user.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../policies/access_policy.dart';
import '../../policies/task_transition_policy.dart';
import '../../shared/errors/app_failure.dart';
import '../../shared/validators/form_validators.dart';
import '../clock/clock_service.dart';
import 'api_provider_service.dart';

class MockApiProvider implements ApiProviderService {
  MockApiProvider(
    this.database,
    this.clock, {
    this.latency = const Duration(milliseconds: 180),
  });
  final MockDatabase database;
  final ClockService clock;
  final Duration latency;
  final _changes = StreamController<void>.broadcast();
  String? _userId, _challengePhone, _challengeId;
  DateTime? _challengeAt;
  bool offline = false;
  List<Json> get demoAccounts => List.unmodifiable(
    database
        .records('users')
        .map(
          (u) => <String, dynamic>{
            'id': u['id'],
            'name': u['name'],
            'phoneE164': u['phoneE164'],
            'role': u['role'],
          },
        ),
  );
  @override
  Stream<void> get changes => _changes.stream;
  void _notify() => _changes.add(null);
  void setOffline(bool value) {
    offline = value;
    _notify();
  }

  void reset() {
    _userId = null;
    _challengePhone = null;
    _challengeId = null;
    _challengeAt = null;
    offline = false;
    database.reset();
    clock.reset();
    _notify();
  }

  AppFailure _fail(String code, String message) => AppFailure(code, message);
  Never _deny() => throw _fail('forbidden', AppText.accessDenied);
  Json _find(String table, String id) => database
      .records(table)
      .firstWhere(
        (x) => x['id'] == id,
        orElse: () => throw _fail('not_found', AppText.notFound),
      );
  AppUser get _user {
    if (_userId == null) throw _fail('unauthorized', AppText.authRequired);
    final user = AppUser.fromJson(_find('users', _userId!));
    if (!user.isActive) throw _fail('unauthorized', AppText.authRequired);
    return user;
  }

  bool _visible(Json j) => AccessPolicy.canReadTask(_user, Task.fromJson(j));
  Json _task(String id) {
    final task = _find('tasks', id);
    if (!_visible(task)) _deny();
    return task;
  }

  void _writable(Json task) {
    if (task['status'] == 'done') throw _fail('readonly', AppText.readOnly);
  }

  void _owner(Json task) {
    if (!_user.isEmployee || task['assigneeId'] != _user.id) _deny();
  }

  String get _now => clock.now.toIso8601String();
  Json _result(Object? data) => jsonDecode(jsonEncode({'data': data})) as Json;
  void _activity(Json task, String summary) {
    database.records('activity').add({
      'id': database.newId('ACT'),
      'actorId': _user.id,
      'entityId': task['id'],
      'summary': summary,
      'action': 'updated',
      'createdAt': _now,
    });
    task['updatedAt'] = _now;
  }

  Json _assignee(String id, {String? teamId}) {
    final j = _find('users', id);
    final p = AppUser.fromJson(j);
    if (!p.isActive ||
        !p.isEmployee ||
        p.teamId == null ||
        (!_user.isSuper && p.teamId != _user.managedTeamId) ||
        (teamId != null && p.teamId != teamId)) {
      throw _fail('validation', AppText.invalidAssignee);
    }
    return j;
  }

  void _note(String note) {
    if (FormValidators.note(note) != null) {
      throw _fail('validation', AppText.invalidNote);
    }
  }

  List<Json> _openEntries(String employeeId) => database
      .records('workEntries')
      .where((w) => w['employeeId'] == employeeId && w['endedAt'] == null)
      .toList();
  void _closeOwnEntries({String? taskId, String note = ''}) {
    for (final e in _openEntries(
      _user.id,
    ).where((e) => taskId == null || e['taskId'] == taskId)) {
      e['endedAt'] = _now;
      if (note.isNotEmpty) e['note'] = note;
    }
  }

  Json _snapshot() {
    final user = _user;
    final tasks = database.records('tasks').where(_visible).toList();
    final ids = tasks.map((t) => t['id']).toSet();
    final people = database
        .records('users')
        .where((j) => AccessPolicy.canReadPerson(user, AppUser.fromJson(j)))
        .toList();
    final teams = database
        .records('teams')
        .map(
          (t) => <String, dynamic>{
            ...t,
            'managerName': _find('users', t['managerId'] as String)['name'],
          },
        )
        .toList();
    final entries = database
        .records('workEntries')
        .where(
          (e) =>
              user.isSuper ||
              (user.isEmployee
                  ? e['employeeId'] == user.id
                  : people.any((p) => p['id'] == e['employeeId'])),
        )
        .toList();
    return {
      'user': _find('users', user.id),
      'tasks': tasks,
      'people': people,
      'teams': teams,
      'workEntries': entries,
      'announcements': database.records('announcements'),
      'activity': database
          .records('activity')
          .where((a) => ids.contains(a['entityId']))
          .toList(),
    };
  }

  @override
  Future<Json> request(
    String method,
    String path, {
    Json body = const {},
    Json query = const {},
  }) async {
    final requestUser = _userId;
    await Future<void>.delayed(latency);
    final isAuth =
        path == ApiEndpoints.otpRequest || path == ApiEndpoints.otpVerify;
    if (!isAuth && requestUser != _userId) {
      throw _fail('unauthorized', AppText.authRequired);
    }
    if (offline && method == 'GET') throw _fail('offline', AppText.offline);
    if (path == ApiEndpoints.otpRequest && method == 'POST') {
      final phone = FormValidators.normalizePhone(
        body['phoneE164'] as String? ?? '',
      );
      if (!database
          .records('users')
          .any((u) => u['phoneE164'] == phone && u['isActive'] == true)) {
        throw _fail('validation', AppText.invalidPhone);
      }
      if (phone == _challengePhone &&
          _challengeAt != null &&
          clock.now.difference(_challengeAt!) < AppConfig.resendDelay) {
        throw _fail('cooldown', AppText.cooldown);
      }
      _challengePhone = phone;
      _challengeId = database.newId('OTP');
      _challengeAt = clock.now;
      return _result({
        'challengeId': _challengeId,
        'phone': phone,
        'issuedAt': _challengeAt!.toIso8601String(),
      });
    }
    if (path == ApiEndpoints.otpVerify && method == 'POST') {
      if (_challengeId == null || body['challengeId'] != _challengeId) {
        throw _fail('validation', AppText.invalidOtp);
      }
      if (clock.now.difference(_challengeAt!) > AppConfig.otpLifetime) {
        throw _fail('expired', AppText.expiredOtp);
      }
      if (body['code'] != AppConfig.otp) {
        throw _fail('validation', AppText.invalidOtp);
      }
      final account = database
          .records('users')
          .firstWhere((u) => u['phoneE164'] == _challengePhone);
      if (account['isActive'] != true) {
        throw _fail('unauthorized', AppText.authRequired);
      }
      _userId = account['id'] as String;
      _challengeId = null;
      return _result({'user': account, 'token': 'mock-session'});
    }
    final user = _user;
    if (path == ApiEndpoints.logout && method == 'POST') {
      _closeOwnEntries();
      _userId = null;
      _challengeAt = null;
      _challengePhone = null;
      _challengeId = null;
      _notify();
      return _result(true);
    }
    if (path == ApiEndpoints.dashboard && method == 'GET') {
      return _result(_snapshot());
    }
    if (path == ApiEndpoints.me && method == 'GET') {
      return _result(_find('users', user.id));
    }
    if (path == ApiEndpoints.company && method == 'GET') {
      return _result(database.data['company']);
    }
    if (path == ApiEndpoints.announcements && method == 'GET') {
      return _result(database.records('announcements'));
    }
    if (path == ApiEndpoints.teams && method == 'GET') {
      return _result(
        (_snapshot()['teams'] as List)
            .where(
              (t) =>
                  user.isSuper ||
                  t['id'] ==
                      (user.isEmployee ? user.teamId : user.managedTeamId),
            )
            .toList(),
      );
    }
    if (path == ApiEndpoints.users && method == 'GET') {
      if (!user.isSuper) _deny();
      return _result(database.records('users'));
    }
    if (path == ApiEndpoints.employees && method == 'GET') {
      if (user.isEmployee) _deny();
      return _result(
        (_snapshot()['people'] as List)
            .where((p) => p['role'] == 'employee')
            .toList(),
      );
    }
    if (path.startsWith('${ApiEndpoints.employees}/') && method == 'GET') {
      final person = _find('users', path.split('/').last);
      if (!AccessPolicy.canReadPerson(user, AppUser.fromJson(person))) _deny();
      return _result(person);
    }
    if (path == ApiEndpoints.tasks && method == 'GET') {
      final list = database
          .records('tasks')
          .where(_visible)
          .where(
            (t) =>
                (query['status'] == null || query['status'] == t['status']) &&
                (query['priority'] == null ||
                    query['priority'] == t['priority']) &&
                (query['query'] == null ||
                    (t['title'] as String).toLowerCase().contains(
                      (query['query'] as String).toLowerCase(),
                    )),
          )
          .toList();
      final page = (query['page'] as int? ?? 1).clamp(1, 10000),
          size = (query['pageSize'] as int? ?? 50).clamp(1, 100);
      return {
        ..._result(list.skip((page - 1) * size).take(size).toList()),
        'meta': {'page': page, 'pageSize': size, 'total': list.length},
      };
    }
    if (path == ApiEndpoints.tasks && method == 'POST') {
      if (user.isEmployee) _deny();
      final title = (body['title'] as String? ?? '').trim(),
          description = (body['description'] as String? ?? '').trim();
      if (FormValidators.title(title) != null) {
        throw _fail('validation', AppText.invalidTitle);
      }
      if (description.length > 1000) {
        throw _fail('validation', AppText.invalidDescription);
      }
      final assignee = _assignee(body['assigneeId'] as String? ?? '');
      final due = DateTime.tryParse(body['dueAt'] as String? ?? '');
      final localNow = ClockService.companyTime(clock.now);
      final today = ClockService.fromCompany(
        DateTime(localNow.year, localNow.month, localNow.day),
      );
      if (due == null || due.isBefore(today)) {
        throw _fail('validation', AppText.invalidDue);
      }
      if (!TaskPriority.values.any((p) => p.name == body['priority'])) {
        throw _fail('validation', AppText.required);
      }
      final task = <String, dynamic>{
        'id': database.newId('T'),
        'title': title,
        'description': description,
        'teamId': assignee['teamId'],
        'assigneeId': assignee['id'],
        'createdById': user.id,
        'status': 'todo',
        'priority': body['priority'],
        'progress': 0,
        'dueAt': due.toUtc().toIso8601String(),
        'createdAt': _now,
        'updatedAt': _now,
        'completedAt': null,
      };
      database.records('tasks').add(task);
      _activity(task, AppText.assignedActivity(assignee['name'] as String));
      _notify();
      return _result(task);
    }
    final parts = path.split('/');
    if (parts.length >= 4 && parts[2] == 'tasks') {
      final task = _task(parts[3]);
      final action = parts.length > 4 ? parts[4] : '';
      if (method == 'GET' && action.isEmpty) return _result(task);
      if (method == 'GET' && action == 'activity') {
        return _result(
          database
              .records('activity')
              .where((a) => a['entityId'] == task['id'])
              .toList(),
        );
      }
      _writable(task);
      if (method == 'POST' && action == 'assignment') {
        if (user.isEmployee) _deny();
        final assignee = _assignee(
          body['assigneeId'] as String? ?? '',
          teamId: task['teamId'] as String,
        );
        if (database
            .records('workEntries')
            .any((e) => e['taskId'] == task['id'] && e['endedAt'] == null)) {
          throw _fail('validation', AppText.timerExists);
        }
        task['assigneeId'] = assignee['id'];
        _activity(task, AppText.assignedActivity(assignee['name'] as String));
        _notify();
        return _result(task);
      }
      if (method == 'PATCH' && action.isEmpty) {
        if (user.isEmployee) _deny();
        final title = (body['title'] as String? ?? task['title'] as String)
            .trim();
        final description =
            (body['description'] as String? ?? task['description'] as String)
                .trim();
        if (FormValidators.title(title) != null) {
          throw _fail('validation', AppText.invalidTitle);
        }
        if (description.length > 1000) {
          throw _fail('validation', AppText.invalidDescription);
        }
        final due = DateTime.tryParse(
          body['dueAt'] as String? ?? task['dueAt'] as String,
        );
        if (due == null) throw _fail('validation', AppText.invalidDue);
        final priority = body['priority'] ?? task['priority'];
        if (!TaskPriority.values.any((p) => p.name == priority)) {
          throw _fail('validation', AppText.required);
        }
        task.addAll({
          'title': title,
          'description': description,
          'dueAt': due.toIso8601String(),
          'priority': priority,
        });
        _activity(task, AppText.saved);
        _notify();
        return _result(task);
      }
      if (method == 'POST' && action == 'updates') {
        _owner(task);
        final note = (body['note'] as String? ?? '').trim();
        _note(note);
        final value = body['progress'];
        if (value is! int || value < 0 || value > 100) {
          throw _fail('validation', AppText.invalidProgress);
        }
        final from = TaskStatus.values.byName(task['status'] as String);
        if (body['requestedStatus'] != null &&
            !TaskStatus.values.any((s) => s.name == body['requestedStatus'])) {
          throw _fail('validation', AppText.invalidTransition);
        }
        final target =
            TaskStatus.values
                .where((s) => s.name == body['requestedStatus'])
                .firstOrNull ??
            from;
        if (!TaskTransitionPolicy.employeeCanMove(from, target)) {
          throw _fail('validation', AppText.invalidTransition);
        }
        if (target == TaskStatus.inReview && value != 100) {
          throw _fail('validation', AppText.reviewNeedsProgress);
        }
        if (target == TaskStatus.todo && value != 0) {
          throw _fail('validation', AppText.invalidTransition);
        }
        final blocker = (body['blocker'] as String? ?? '').trim();
        if (target == TaskStatus.blocked && blocker.isEmpty) {
          throw _fail('validation', AppText.blockerRequired);
        }
        if (target == TaskStatus.blocked || target == TaskStatus.inReview) {
          _closeOwnEntries(taskId: task['id'] as String, note: note);
        }
        task['status'] = target.name;
        task['progress'] = value;
        database.records('taskUpdates').add({
          'id': database.newId('U'),
          'taskId': task['id'],
          'actorId': user.id,
          'note': note,
          'blocker': blocker,
          'progress': value,
          'createdAt': _now,
        });
        _activity(
          task,
          '${AppText.progressActivity(user.firstName, value)} $note',
        );
        _notify();
        return _result(task);
      }
      if (method == 'POST' && action == 'review') {
        if (user.isEmployee) _deny();
        if (task['status'] != 'inReview') {
          throw _fail('validation', AppText.invalidTransition);
        }
        final decision = body['decision'],
            note = (body['note'] as String? ?? '').trim();
        if (decision != 'approve' && decision != 'requestChanges') {
          throw _fail('validation', AppText.invalidTransition);
        }
        if (decision == 'requestChanges') _note(note);
        task['status'] = decision == 'approve' ? 'done' : 'inProgress';
        task['completedAt'] = decision == 'approve' ? _now : null;
        _activity(
          task,
          '${AppText.statusActivity(TaskStatus.values.byName(task['status'] as String).label)} $note',
        );
        _notify();
        return _result(task);
      }
    }
    if (path == ApiEndpoints.workEntries && method == 'GET') {
      return _result(_snapshot()['workEntries']);
    }
    if ((path == ApiEndpoints.workEntries || path == ApiEndpoints.startWork) &&
        method == 'POST') {
      final task = _task(body['taskId'] as String? ?? '');
      _owner(task);
      _writable(task);
      if (task['status'] != 'todo' && task['status'] != 'inProgress') {
        throw _fail('validation', AppText.inactiveTask);
      }
      final isTimer = path == ApiEndpoints.startWork;
      if (isTimer && _openEntries(user.id).isNotEmpty) {
        throw _fail('validation', AppText.timerExists);
      }
      final start = isTimer
          ? clock.now
          : DateTime.tryParse(body['startedAt'] as String? ?? '');
      final end = isTimer
          ? null
          : DateTime.tryParse(body['endedAt'] as String? ?? '');
      final note = (body['note'] as String? ?? '').trim();
      if (!isTimer) {
        _note(note);
        if (start == null ||
            end == null ||
            !start.isBefore(end) ||
            end.isAfter(clock.now) ||
            end.difference(start) > const Duration(hours: 12)) {
          throw _fail('validation', AppText.invalidTime);
        }
        for (final e
            in database
                .records('workEntries')
                .where((e) => e['employeeId'] == user.id)) {
          final a = DateTime.parse(e['startedAt'] as String),
              b = e['endedAt'] == null
                  ? clock.now
                  : DateTime.parse(e['endedAt'] as String);
          if (start.isBefore(b) && end.isAfter(a)) {
            throw _fail('validation', AppText.overlappingTime);
          }
        }
      }
      final entry = <String, dynamic>{
        'id': database.newId('W'),
        'taskId': task['id'],
        'employeeId': user.id,
        'startedAt': start!.toUtc().toIso8601String(),
        'endedAt': end?.toUtc().toIso8601String(),
        'note': note,
        'source': isTimer ? 'timer' : 'manual',
      };
      database.records('workEntries').add(entry);
      if (task['status'] == 'todo') task['status'] = 'inProgress';
      _activity(task, isTimer ? AppText.running : AppText.timeSaved);
      _notify();
      return _result(entry);
    }
    if (parts.length == 5 &&
        parts[2] == 'work-entries' &&
        parts[4] == 'stop' &&
        method == 'POST') {
      final entry = _find('workEntries', parts[3]);
      if (entry['employeeId'] != user.id) _deny();
      if (entry['endedAt'] != null) {
        throw _fail('validation', AppText.noOpenTimer);
      }
      entry['endedAt'] = _now;
      entry['note'] = body['note'] ?? entry['note'];
      _activity(_task(entry['taskId'] as String), AppText.timerStopped);
      _notify();
      return _result(entry);
    }
    if (parts.length == 5 &&
        parts[2] == 'users' &&
        parts[4] == 'access' &&
        method == 'PATCH') {
      if (!user.isSuper) _deny();
      final target = _find('users', parts[3]);
      final role = body['role'] as String? ?? target['role'] as String;
      final active = body['isActive'] as bool? ?? target['isActive'] as bool;
      if (!['employee', 'admin'].contains(role) ||
          target['role'] == 'superAdmin' ||
          ((role != 'admin' || !active) &&
              database
                  .records('teams')
                  .any((t) => t['managerId'] == target['id']))) {
        throw _fail('validation', AppText.protectedAdmin);
      }
      if ((role != target['role'] || !active) &&
          (database
                  .records('tasks')
                  .any(
                    (t) =>
                        t['assigneeId'] == target['id'] &&
                        t['status'] != 'done',
                  ) ||
              _openEntries(target['id'] as String).isNotEmpty)) {
        throw _fail('validation', AppText.activeAssignments);
      }
      final team =
          body['managedTeamId'] as String? ??
          target['managedTeamId'] as String?;
      if (role == 'admin' &&
          !database.records('teams').any((t) => t['id'] == team)) {
        throw _fail('validation', AppText.teamRequired);
      }
      target.addAll({
        'role': role,
        'isActive': active,
        'managedTeamId': role == 'admin' ? team : null,
      });
      _notify();
      return _result(target);
    }
    if (path == ApiEndpoints.statusReport && method == 'GET') {
      final tasks = database.records('tasks').where(_visible);
      return _result({
        for (final s in TaskStatus.values)
          s.name: tasks.where((t) => t['status'] == s.name).length,
      });
    }
    if (path == ApiEndpoints.hoursReport && method == 'GET') {
      return _result(_snapshot()['workEntries']);
    }
    throw _fail('not_found', AppText.notFound);
  }

  @override
  Future<void> dispose() => _changes.close();
}
