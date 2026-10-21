import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app_constants/app_text.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../../repository/task/task_repository.dart';
import '../../repository/work_log/work_log_repository.dart';
import '../../repository/employee/employee_repository.dart';
import '../errors/app_failure.dart';

sealed class AppAction {}

class AssignTask extends AppAction {
  AssignTask(this.draft);
  final TaskDraft draft;
}

class UpdateWork extends AppAction {
  UpdateWork(this.id, this.progress, this.note, this.status, this.blocker);
  final String id, note, blocker;
  final int progress;
  final TaskStatus status;
}

class ReviewTask extends AppAction {
  ReviewTask(this.id, this.approve, this.note);
  final String id, note;
  final bool approve;
}

class ReassignTask extends AppAction {
  ReassignTask(this.id, this.employee);
  final String id, employee;
}

class StartWork extends AppAction {
  StartWork(this.id);
  final String id;
}

class StopWork extends AppAction {
  StopWork(this.id);
  final String id;
}

class AddWork extends AppAction {
  AddWork(this.id, this.start, this.end, this.note);
  final String id, note;
  final DateTime start, end;
}

class ChangeAccess extends AppAction {
  ChangeAccess(this.id, this.role, this.active, this.teamId);
  final String id;
  final UserRole role;
  final bool active;
  final String? teamId;
}

class ActionState {
  const ActionState({
    this.busy = false,
    this.message,
    this.error,
    this.createdId,
    this.completedAction,
  });
  final bool busy;
  final String? message, error, createdId;
  final AppAction? completedAction;
}

/// Route-owned mutation BLoC. Commands are typed and UI never handles API payloads.
class ActionBloc extends Bloc<AppAction, ActionState> {
  ActionBloc(this.tasks, this.work, this.people) : super(const ActionState()) {
    on<AppAction>((event, emit) async {
      if (state.busy) return;
      emit(const ActionState(busy: true));
      try {
        String message = AppText.saved;
        String? id;
        switch (event) {
          case AssignTask():
            id = (await tasks.create(event.draft)).id;
            message = AppText.assignedSuccess;
          case UpdateWork():
            await tasks.update(
              event.id,
              progress: event.progress,
              note: event.note,
              status: event.status,
              blocker: event.blocker,
            );
          case ReviewTask():
            await tasks.review(
              event.id,
              approve: event.approve,
              note: event.note,
            );
          case ReassignTask():
            await tasks.reassign(event.id, event.employee);
          case StartWork():
            await work.start(event.id);
            message = AppText.running;
          case StopWork():
            await work.stop(event.id);
            message = AppText.timerStopped;
          case AddWork():
            await work.add(event.id, event.start, event.end, event.note);
            message = AppText.timeSaved;
          case ChangeAccess():
            await people.changeAccess(
              event.id,
              event.role,
              event.active,
              event.teamId,
            );
        }
        emit(
          ActionState(message: message, createdId: id, completedAction: event),
        );
      } catch (error) {
        emit(ActionState(error: AppFailure.from(error).message));
      }
    });
  }
  final TaskRepository tasks;
  final WorkLogRepository work;
  final EmployeeRepository people;
}
