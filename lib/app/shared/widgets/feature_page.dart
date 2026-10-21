import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/workspace_data.dart';
import '../../repository/workspace/workspace_repository.dart';
import '../../repository/task/task_repository.dart';
import '../../repository/work_log/work_log_repository.dart';
import '../../repository/employee/employee_repository.dart';
import '../bloc/snapshot_bloc.dart';
import '../bloc/action_bloc.dart';
import 'ui.dart';

class FeaturePage extends StatelessWidget {
  const FeaturePage({
    super.key,
    required this.title,
    required this.builder,
    this.createBloc,
    this.actions,
    this.onSuccess,
  });
  final String title;
  final Widget Function(BuildContext, WorkspaceData) builder;
  final SnapshotBloc Function(BuildContext)? createBloc;
  final List<Widget>? actions;
  final void Function(BuildContext, ActionState)? onSuccess;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider<SnapshotBloc>(
        create: (c) =>
            createBloc?.call(c) ?? SnapshotBloc(c.read<WorkspaceRepository>()),
      ),
      BlocProvider(
        create: (c) => ActionBloc(
          c.read<TaskRepository>(),
          c.read<WorkLogRepository>(),
          c.read<EmployeeRepository>(),
        ),
      ),
    ],
    child: Builder(
      builder: (context) => BlocListener<ActionBloc, ActionState>(
        listener: (context, state) {
          if (state.error != null || state.message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(state.error ?? state.message!)),
              );
          }
          if (state.completedAction != null) onSuccess?.call(context, state);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: actions,
          ),
          body: SafeArea(
            top: false,
            child: BlocBuilder<SnapshotBloc, SnapshotState>(
              builder: (context, state) {
                if (state.data != null) return builder(context, state.data!);
                if (state.error != null) {
                  return PageColumn(
                    children: [
                      MessageCard(
                        state.error!.message,
                        error: true,
                        onRetry: () => context.read<SnapshotBloc>().add(
                          SnapshotRequested(),
                        ),
                      ),
                    ],
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ),
      ),
    ),
  );
}
