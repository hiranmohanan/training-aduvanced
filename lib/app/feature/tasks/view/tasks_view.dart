import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../bloc/tasks_bloc.dart';

class TasksView extends StatefulWidget {
  const TasksView({super.key});
  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  String _query = '';
  TaskStatus? _status;
  TaskPriority? _priority;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.tasks,
    createBloc: (c) => TasksBloc(c.read<WorkspaceRepository>()),
    builder: (context, data) {
      final nav = context.read<NavigationService>();
      final tasks = data.tasks
          .where(
            (t) =>
                (_status == null || t.status == _status) &&
                (_priority == null || t.priority == _priority) &&
                (t.title.toLowerCase().contains(_query.toLowerCase()) ||
                    t.id.toLowerCase().contains(_query.toLowerCase())),
          )
          .toList();
      return PageColumn(
        children: [
          TextField(
            decoration: const InputDecoration(
              hintText: AppText.searchTasks,
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
          const Gap(16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text(AppText.all),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                ),
                for (final status in TaskStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(status.label),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
          DropdownButtonFormField<TaskPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: AppText.priority),
            items: [
              const DropdownMenuItem(value: null, child: Text(AppText.all)),
              for (final p in TaskPriority.values)
                DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) => setState(() => _priority = v),
          ),
          const Gap(18),
          Text(AppText.taskCount(tasks.length)),
          const Gap(12),
          if (tasks.isEmpty) const MessageCard(AppText.emptyTasks),
          for (final task in tasks) ...[
            TaskCard(
              task,
              onTap: () => nav.openTask(task.id),
              assignee: data.user.isEmployee
                  ? null
                  : data.personName(task.assigneeId),
            ),
            const Gap(14),
          ],
          if (!data.user.isEmployee)
            FilledButton.icon(
              onPressed: nav.openAssignment,
              icon: const Icon(Icons.add),
              label: const Text(AppText.assignTask),
            ),
        ],
      );
    },
  );
}
