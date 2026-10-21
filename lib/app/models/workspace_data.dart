import 'app_user.dart';
import 'task.dart';
import 'work_entry.dart';

class Team {
  const Team(this.id, this.name, this.managerId, [this.managerName = '']);
  factory Team.fromJson(Map<String, dynamic> j) => Team(
    j['id'] as String,
    j['name'] as String,
    j['managerId'] as String,
    j['managerName'] as String? ?? '',
  );
  final String id, name, managerId, managerName;
}

class Announcement {
  const Announcement(this.id, this.title, this.body);
  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    j['id'] as String,
    j['title'] as String,
    j['body'] as String,
  );
  final String id, title, body;
}

class ActivityEntry {
  const ActivityEntry(this.id, this.taskId, this.summary, this.createdAt);
  factory ActivityEntry.fromJson(Map<String, dynamic> j) => ActivityEntry(
    j['id'] as String,
    j['entityId'] as String,
    j['summary'] as String,
    DateTime.parse(j['createdAt'] as String),
  );
  final String id, taskId, summary;
  final DateTime createdAt;
}

class WorkspaceData {
  WorkspaceData({
    required this.user,
    required Iterable<AppUser> people,
    required Iterable<Task> tasks,
    required Iterable<WorkEntry> entries,
    required Iterable<Team> teams,
    required Iterable<Announcement> announcements,
    required Iterable<ActivityEntry> activity,
  }) : people = List.unmodifiable(people),
       tasks = List.unmodifiable(tasks),
       entries = List.unmodifiable(entries),
       teams = List.unmodifiable(teams),
       announcements = List.unmodifiable(announcements),
       activity = List.unmodifiable(activity);
  factory WorkspaceData.fromJson(Map<String, dynamic> j) => WorkspaceData(
    user: AppUser.fromJson(j['user'] as Map<String, dynamic>),
    people: (j['people'] as List).map(
      (x) => AppUser.fromJson(x as Map<String, dynamic>),
    ),
    tasks: (j['tasks'] as List).map(
      (x) => Task.fromJson(x as Map<String, dynamic>),
    ),
    entries: (j['workEntries'] as List).map(
      (x) => WorkEntry.fromJson(x as Map<String, dynamic>),
    ),
    teams: (j['teams'] as List).map(
      (x) => Team.fromJson(x as Map<String, dynamic>),
    ),
    announcements: (j['announcements'] as List).map(
      (x) => Announcement.fromJson(x as Map<String, dynamic>),
    ),
    activity: (j['activity'] as List).map(
      (x) => ActivityEntry.fromJson(x as Map<String, dynamic>),
    ),
  );
  final AppUser user;
  final List<AppUser> people;
  final List<Task> tasks;
  final List<WorkEntry> entries;
  final List<Team> teams;
  final List<Announcement> announcements;
  final List<ActivityEntry> activity;
  AppUser? person(String id) {
    if (user.id == id) return user;
    for (final p in people) {
      if (p.id == id) return p;
    }
    return null;
  }

  String personName(String id) =>
      person(id)?.name ??
      teams.where((t) => t.managerId == id).firstOrNull?.managerName ??
      id;
  String teamName(String? id) {
    for (final t in teams) {
      if (t.id == id) return t.name;
    }
    return '';
  }
}
