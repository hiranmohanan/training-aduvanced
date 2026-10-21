import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/app_user.dart';
import '../../../models/enums.dart';
import '../../../models/workspace_data.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/bloc/action_bloc.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';

class EmployeesView extends StatefulWidget {
  const EmployeesView({super.key, this.users = false, this.teamId});
  final bool users;
  final String? teamId;
  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  String _query = '';
  UserRole? _role;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: widget.users ? AppText.userManagement : AppText.employees,
    builder: (context, data) {
      final people = data.people
          .where(
            (p) =>
                (widget.users || p.isEmployee) &&
                (widget.teamId == null || p.teamId == widget.teamId) &&
                (_role == null || p.role == _role) &&
                p.name.toLowerCase().contains(_query.toLowerCase()),
          )
          .toList();
      return PageColumn(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: AppText.searchPeople,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const Gap(16),
          if (widget.users) ...[
            DropdownButtonFormField<UserRole>(
              isExpanded: true,
              initialValue: _role,
              decoration: const InputDecoration(labelText: AppText.role),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(AppText.allRoles),
                ),
                for (final r in UserRole.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) => setState(() => _role = v),
            ),
            const Gap(16),
          ],
          Text(
            widget.users
                ? AppText.accountCount(people.length)
                : AppText.employeeCount(people.length),
          ),
          const Gap(14),
          if (people.isEmpty) const MessageCard(AppText.emptyPeople),
          for (final person in people) ...[
            PersonTile(
              person,
              subtitle:
                  '${person.role.label} · ${data.teamName(person.teamId)}${person.isActive ? '' : ' · ${AppText.inactive}'}',
              trailing: widget.users && person.isSuper
                  ? const Icon(Icons.lock_outline)
                  : null,
              onTap: widget.users
                  ? (person.isSuper
                        ? null
                        : () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => BlocProvider.value(
                              value: context.read<ActionBloc>(),
                              child: _AccessForm(person, data),
                            ),
                          ))
                  : () => context.read<NavigationService>().openEmployee(
                      person.id,
                    ),
            ),
            const Gap(12),
          ],
        ],
      );
    },
  );
}

class _AccessForm extends StatefulWidget {
  const _AccessForm(this.person, this.data);
  final AppUser person;
  final WorkspaceData data;
  @override
  State<_AccessForm> createState() => _AccessFormState();
}

class _AccessFormState extends State<_AccessForm> {
  late UserRole _role;
  late bool _active;
  String? _team;
  @override
  void initState() {
    super.initState();
    _role = widget.person.role;
    _active = widget.person.isActive;
    _team = widget.person.managedTeamId ?? widget.person.teamId;
  }

  @override
  Widget build(BuildContext context) => BlocListener<ActionBloc, ActionState>(
    listener: (c, s) {
      if (s.completedAction is ChangeAccess) Navigator.pop(c);
    },
    child: SafeArea(
      child: BlocBuilder<ActionBloc, ActionState>(
        builder: (context, state) => Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionTitle(AppText.editAccess),
                const Gap(18),
                Text(
                  widget.person.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(24),
                DropdownButtonFormField<UserRole>(
                  isExpanded: true,
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: AppText.role),
                  items: [
                    for (final r in [UserRole.employee, UserRole.admin])
                      DropdownMenuItem(value: r, child: Text(r.label)),
                  ],
                  onChanged: (v) => setState(() => _role = v!),
                ),
                const Gap(20),
                if (_role == UserRole.admin) ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _team,
                    decoration: const InputDecoration(
                      labelText: AppText.managedTeam,
                    ),
                    items: [
                      for (final t in widget.data.teams)
                        DropdownMenuItem(value: t.id, child: Text(t.name)),
                    ],
                    onChanged: (v) => setState(() => _team = v),
                  ),
                  const Gap(18),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(AppText.accountActive),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),
                const Gap(16),
                const Text(AppText.accessHint),
                const Gap(18),
                if (state.error != null) ...[Text(state.error!), const Gap(12)],
                FilledButton(
                  onPressed: state.busy
                      ? null
                      : () => context.read<ActionBloc>().add(
                          ChangeAccess(widget.person.id, _role, _active, _team),
                        ),
                  child: const Text(AppText.saveAccess),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
