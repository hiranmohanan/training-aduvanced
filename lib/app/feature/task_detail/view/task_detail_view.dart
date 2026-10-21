import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_routes.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../models/task.dart';
import '../../../models/workspace_data.dart';
import '../../../repository/task/task_repository.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../services/clock/clock_service.dart';
import '../../../shared/bloc/action_bloc.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../../theme/app_theme.dart';
import '../bloc/task_detail_bloc.dart';

class TaskDetailView extends StatelessWidget {
  const TaskDetailView(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.taskDetails,
    createBloc: (c) => TaskDetailBloc(
      c.read<WorkspaceRepository>(),
      checkAccess: () async {
        await c.read<TaskRepository>().read(id);
      },
    ),
    builder: (context, data) {
      final task = data.tasks.where((t) => t.id == id).firstOrNull;
      if (task == null) {
        return const PageColumn(children: [MessageCard(AppText.notFound)]);
      }
      final nav = context.read<NavigationService>(),
          person = data.person(task.assigneeId);
      final activity = data.activity.where((a) => a.taskId == id).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return PageColumn(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              StatusChip(task.status),
              Chip(label: Text(task.priority.label)),
              if (task.isOverdue(context.read<ClockService>().now))
                const Chip(label: Text(AppText.overdue)),
            ],
          ),
          const Gap(20),
          Text(
            task.title,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700),
          ),
          const Gap(20),
          if (person != null)
            PersonTile(
              person,
              subtitle: AppText.by(data.personName(task.createdById)),
              onTap: () => nav.openEmployee(person.id),
            ),
          const Gap(18),
          AppCard(
            child: Column(
              children: [
                DetailRow(AppText.taskProgress, AppText.percent(task.progress)),
                const Gap(8),
                LinearProgressIndicator(
                  value: task.progress / 100,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
                const Gap(10),
                DetailRow(
                  AppText.dueDate,
                  '${ClockService.date(task.dueAt)} · ${ClockService.time(task.dueAt)}',
                ),
              ],
            ),
          ),
          const Gap(24),
          const SectionTitle(AppText.description),
          const Gap(10),
          Text(
            task.description,
            style: const TextStyle(color: AppColors.muted, height: 1.6),
          ),
          const Gap(26),
          if (data.user.isEmployee &&
              task.status != TaskStatus.done &&
              task.status != TaskStatus.inReview)
            FilledButton(
              onPressed: () => nav.push(AppRoutes.update(id)),
              child: const Text(AppText.updateWork),
            ),
          if (!data.user.isEmployee && !task.isDone) ...[
            if (task.status == TaskStatus.inReview) _ReviewForm(id),
            const Gap(12),
            _Reassignment(task, data),
          ],
          const Gap(24),
          const SectionTitle(AppText.recentActivity),
          const Gap(12),
          if (activity.isEmpty) const MessageCard(AppText.emptyActivity),
          for (final entry in activity) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.summary, style: const TextStyle(height: 1.5)),
                  const Gap(8),
                  Text(
                    '${ClockService.shortDate(entry.createdAt)} · ${ClockService.time(entry.createdAt)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),
          ],
        ],
      );
    },
  );
}

class _ReviewForm extends StatefulWidget {
  const _ReviewForm(this.id);
  final String id;
  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _note = TextEditingController();
  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ActionBloc, ActionState>(
    builder: (context, state) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _note,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(labelText: AppText.reviewComment),
        ),
        const Gap(12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              onPressed: state.busy
                  ? null
                  : () => context.read<ActionBloc>().add(
                      ReviewTask(widget.id, false, _note.text),
                    ),
              child: const Text(AppText.requestChanges),
            ),
            FilledButton(
              key: const Key('approve_task'),
              onPressed: state.busy
                  ? null
                  : () => context.read<ActionBloc>().add(
                      ReviewTask(widget.id, true, _note.text),
                    ),
              child: const Text(AppText.approve),
            ),
          ],
        ),
      ],
    ),
  );
}

class _Reassignment extends StatelessWidget {
  const _Reassignment(this.task, this.data);
  final Task task;
  final WorkspaceData data;
  @override
  Widget build(BuildContext context) => BlocBuilder<ActionBloc, ActionState>(
    builder: (context, state) => OutlinedButton(
      onPressed: state.busy
          ? null
          : () async {
              final selected = await showDialog<String>(
                context: context,
                builder: (dialog) => SimpleDialog(
                  title: const Text(AppText.reassign),
                  children: [
                    for (final user in data.people.where(
                      (p) =>
                          p.isEmployee &&
                          p.isActive &&
                          p.teamId == task.teamId &&
                          p.id != task.assigneeId,
                    ))
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(dialog, user.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(user.name),
                        ),
                      ),
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text(AppText.cancel),
                    ),
                  ],
                ),
              );
              if (selected != null && context.mounted) {
                context.read<ActionBloc>().add(ReassignTask(task.id, selected));
              }
            },
      child: const Text(AppText.reassign),
    ),
  );
}
