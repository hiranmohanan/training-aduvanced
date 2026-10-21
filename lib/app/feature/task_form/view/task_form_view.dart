import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_routes.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../models/task.dart';
import '../../../models/workspace_data.dart';
import '../../../services/clock/clock_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../shared/bloc/action_bloc.dart';
import '../../../shared/validators/form_validators.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';

class TaskFormView extends StatelessWidget {
  const TaskFormView({super.key});
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.assignTask,
    onSuccess: (context, state) {
      if (state.createdId != null) {
        context.read<NavigationService>().go(AppRoutes.task(state.createdId!));
      }
    },
    builder: (context, data) => _TaskForm(data),
  );
}

class _TaskForm extends StatefulWidget {
  const _TaskForm(this.data);
  final WorkspaceData data;
  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  final _form = GlobalKey<FormState>(),
      _title = TextEditingController(),
      _description = TextEditingController();
  String? _employee;
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _due;
  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final local = ClockService.companyTime(context.read<ClockService>().now);
    final due = _due ?? DateTime(local.year, local.month, local.day + 2, 18);
    final people = widget.data.people
        .where((p) => p.isEmployee && p.isActive)
        .toList();
    return BlocBuilder<ActionBloc, ActionState>(
      builder: (context, state) => PageColumn(
        children: [
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('task_title'),
                  controller: _title,
                  validator: FormValidators.title,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: AppText.taskTitle,
                  ),
                ),
                const Gap(16),
                TextFormField(
                  key: const Key('task_description'),
                  controller: _description,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: AppText.description,
                  ),
                ),
                const Gap(16),
                DropdownButtonFormField<String>(
                  key: const Key('task_assignee'),
                  initialValue: _employee,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppText.assignTo,
                  ),
                  validator: FormValidators.required,
                  items: [
                    for (final p in people)
                      DropdownMenuItem(value: p.id, child: Text(p.name)),
                  ],
                  onChanged: (v) => setState(() => _employee = v),
                ),
                const Gap(22),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(
                    labelText: AppText.priority,
                  ),
                  items: [
                    for (final p in TaskPriority.values)
                      DropdownMenuItem(value: p, child: Text(p.label)),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                const Gap(22),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: due,
                      firstDate: DateTime(local.year, local.month, local.day),
                      lastDate: DateTime(local.year + 3),
                    );
                    if (picked != null) {
                      setState(
                        () => _due = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          18,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${AppText.dueDate}: ${ClockService.date(ClockService.fromCompany(due))} · 6:00 PM',
                  ),
                ),
                const Gap(30),
                FilledButton(
                  key: const Key('task_assign_submit'),
                  onPressed: state.busy
                      ? null
                      : () {
                          if (_form.currentState!.validate()) {
                            context.read<ActionBloc>().add(
                              AssignTask(
                                TaskDraft(
                                  title: _title.text,
                                  description: _description.text,
                                  assigneeId: _employee!,
                                  priority: _priority,
                                  dueAt: ClockService.fromCompany(due),
                                ),
                              ),
                            );
                          }
                        },
                  child: const Text(AppText.assignTask),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
