import 'package:equatable/equatable.dart';
import 'enums.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.designation,
    required this.joinedAt,
    required this.isActive,
    this.teamId,
    this.managedTeamId,
    this.managerId,
  });
  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id: j['id'] as String,
    name: j['name'] as String,
    phone: j['phoneE164'] as String,
    role: UserRole.values.byName(j['role'] as String),
    designation: j['designation'] as String,
    joinedAt: DateTime.parse(j['joinedAt'] as String),
    isActive: j['isActive'] as bool,
    teamId: j['teamId'] as String?,
    managedTeamId: j['managedTeamId'] as String?,
    managerId: j['managerId'] as String?,
  );
  final String id, name, phone, designation;
  final UserRole role;
  final DateTime joinedAt;
  final bool isActive;
  final String? teamId, managedTeamId, managerId;
  bool get isEmployee => role == UserRole.employee;
  bool get isSuper => role == UserRole.superAdmin;
  String get firstName => name.split(' ').first;
  String get initials => name.split(' ').take(2).map((p) => p[0]).join();
  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    role,
    designation,
    joinedAt,
    isActive,
    teamId,
    managedTeamId,
    managerId,
  ];
}
