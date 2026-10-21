import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app_constants/app_text.dart';
import '../../../models/enums.dart';
import '../../../models/task.dart';
import '../../../models/workspace_data.dart';
import '../../../repository/task/task_repository.dart';
import '../../../repository/workspace/workspace_repository.dart';
import '../../../services/clock/clock_service.dart';
import '../../../services/navigation/navigation_service.dart';
import '../../../services/timer/work_timer_service.dart';
import '../../../shared/bloc/action_bloc.dart';
import '../../../shared/validators/form_validators.dart';
import '../../../shared/widgets/feature_page.dart';
import '../../../shared/widgets/ui.dart';
import '../../task_detail/bloc/task_detail_bloc.dart';

class WorkUpdateView extends StatelessWidget {
  const WorkUpdateView(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) => FeaturePage(
    title: AppText.updateWork,
    createBloc: (c) => TaskDetailBloc(
      c.read<WorkspaceRepository>(),
      checkAccess: () async {
        await c.read<TaskRepository>().read(id);
      },
    ),
    onSuccess: (context, state) {
      if (state.completedAction is UpdateWork) {
        context.read<NavigationService>().back();
      }
    },
    builder: (context, data) {
      final task = data.tasks.where((t) => t.id == id).firstOrNull;
      if (task == null) {
        return const PageColumn(children: [MessageCard(AppText.notFound)]);
      }
      if (task.isDone || task.status == TaskStatus.inReview) {
        return const PageColumn(children: [MessageCard(AppText.readOnly)]);
      }
      return _WorkForm(task, data);
    },
  );
}

class _WorkForm extends StatefulWidget {
  const _WorkForm(this.task, this.data);
  final Task task;
  final WorkspaceData data;
  @override
  State<_WorkForm> createState() => _WorkFormState();
}

class _WorkFormState extends State<_WorkForm> {
  final _form = GlobalKey<FormState>(),
      _note = TextEditingController(),
      _blocker = TextEditingController();
  late int _progress;
  late TaskStatus _status;
  @override
  void initState() {
    super.initState();
    _progress = widget.task.progress;
    _status = widget.task.status;
  }

  @override
  void didUpdateWidget(covariant _WorkForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.status != widget.task.status) {
      _status = widget.task.status;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _blocker.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, TaskStatus status) {
    if (_form.currentState!.validate()) {
      context.read<ActionBloc>().add(
        UpdateWork(
          widget.task.id,
          _progress,
          _note.text,
          status,
          _blocker.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final open = widget.data.entries
        .where((e) => e.employeeId == widget.data.user.id && e.isRunning)
        .firstOrNull;
    return BlocBuilder<ActionBloc, ActionState>(
      builder: (context, state) => PageColumn(
        children: [
          Text(
            widget.task.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const Gap(20),
          AppCard(
            child: Column(
              children: [
                DetailRow(AppText.taskProgress, AppText.percent(_progress)),
                Slider(
                  value: _progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: AppText.percent(_progress),
                  onChanged: state.busy
                      ? null
                      : (value) => setState(() => _progress = value.round()),
                ),
              ],
            ),
          ),
          const Gap(22),
          Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<TaskStatus>(
                  key: ValueKey(_status),
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: AppText.status),
                  items: [
                    for (final s in [
                      TaskStatus.todo,
                      TaskStatus.inProgress,
                      TaskStatus.blocked,
                    ])
                      DropdownMenuItem(value: s, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() => _status = v!),
                ),
                const Gap(22),
                TextFormField(
                  key: const Key('work_note'),
                  controller: _note,
                  maxLines: 4,
                  maxLength: 500,
                  validator: FormValidators.note,
                  decoration: const InputDecoration(
                    labelText: AppText.workUpdate,
                  ),
                ),
                if (_status == TaskStatus.blocked) ...[
                  const Gap(14),
                  TextFormField(
                    controller: _blocker,
                    validator: FormValidators.required,
                    decoration: const InputDecoration(
                      labelText: AppText.blocker,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Gap(22),
          const SectionTitle(AppText.timeTracking),
          const Gap(12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (open == null)
                  const Text(AppText.noTimer)
                else ...[
                  Text('${AppText.running} · ${open.taskId}'),
                  StreamBuilder<Duration>(
                    stream: context.read<WorkTimerService>().elapsedSince(
                      open.startedAt,
                    ),
                    builder: (context, s) => Text(
                      ClockService.elapsed(s.data ?? Duration.zero),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const Gap(14),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: state.busy
                          ? null
                          : () => context.read<ActionBloc>().add(
                              open == null
                                  ? StartWork(widget.task.id)
                                  : StopWork(open.id),
                            ),
                      icon: Icon(open == null ? Icons.play_arrow : Icons.stop),
                      label: Text(
                        open == null ? AppText.startTimer : AppText.stopTimer,
                      ),
                    ),
                    TextButton(
                      onPressed: state.busy
                          ? null
                          : () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => BlocProvider.value(
                                value: context.read<ActionBloc>(),
                                child: _ManualTime(
                                  widget.task.id,
                                  context.read<ClockService>(),
                                ),
                              ),
                            ),
                      child: const Text(AppText.manualTime),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap(28),
          FilledButton(
            key: const Key('work_save'),
            onPressed: state.busy ? null : () => _submit(context, _status),
            child: const Text(AppText.saveUpdate),
          ),
          const Gap(12),
          OutlinedButton(
            onPressed: state.busy
                ? null
                : () => _submit(context, TaskStatus.inReview),
            child: const Text(AppText.submitReview),
          ),
        ],
      ),
    );
  }
}

class _ManualTime extends StatefulWidget {
  const _ManualTime(this.taskId, this.clock);
  final String taskId;
  final ClockService clock;
  @override
  State<_ManualTime> createState() => _ManualTimeState();
}

class _ManualTimeState extends State<_ManualTime> {
  final _note = TextEditingController(), _form = GlobalKey<FormState>();
  late DateTime _start, _end;
  @override
  void initState() {
    super.initState();
    _end = ClockService.companyTime(widget.clock.now);
    _start = _end.subtract(const Duration(minutes: 30));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pick(bool start) async {
    final initial = start ? _start : _end;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: ClockService.companyTime(widget.clock.now),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time != null && mounted) {
      setState(() {
        final value = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ActionBloc, ActionState>(
    listener: (context, state) {
      if (state.completedAction is AddWork) Navigator.pop(context);
    },
    child: SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: BlocBuilder<ActionBloc, ActionState>(
          builder: (context, state) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionTitle(AppText.manualTime),
                    const Gap(18),
                    OutlinedButton(
                      onPressed: () => _pick(true),
                      child: Text(
                        '${AppText.startTime}: ${ClockService.shortDate(ClockService.fromCompany(_start))} ${ClockService.time(ClockService.fromCompany(_start))}',
                      ),
                    ),
                    const Gap(10),
                    OutlinedButton(
                      onPressed: () => _pick(false),
                      child: Text(
                        '${AppText.endTime}: ${ClockService.shortDate(ClockService.fromCompany(_end))} ${ClockService.time(ClockService.fromCompany(_end))}',
                      ),
                    ),
                    const Gap(18),
                    TextFormField(
                      controller: _note,
                      validator: FormValidators.note,
                      decoration: const InputDecoration(
                        labelText: AppText.workNote,
                      ),
                    ),
                    const Gap(18),
                    if (state.error != null) ...[
                      Text(state.error!),
                      const Gap(10),
                    ],
                    FilledButton(
                      onPressed: state.busy
                          ? null
                          : () {
                              if (_form.currentState!.validate()) {
                                context.read<ActionBloc>().add(
                                  AddWork(
                                    widget.taskId,
                                    ClockService.fromCompany(_start),
                                    ClockService.fromCompany(_end),
                                    _note.text,
                                  ),
                                );
                              }
                            },
                      child: const Text(AppText.save),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
