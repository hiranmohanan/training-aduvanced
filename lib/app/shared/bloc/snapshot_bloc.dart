import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/workspace_data.dart';
import '../../repository/workspace/workspace_repository.dart';
import '../errors/app_failure.dart';

class SnapshotRequested {}

class SnapshotState {
  const SnapshotState({this.data, this.error, this.loading = false});
  final WorkspaceData? data;
  final AppFailure? error;
  final bool loading;
}

/// Shared read lifecycle; each route owns a distinct feature instance.
class SnapshotBloc extends Bloc<SnapshotRequested, SnapshotState> {
  SnapshotBloc(this.repository, {this.checkAccess})
    : super(const SnapshotState(loading: true)) {
    on<SnapshotRequested>((event, emit) async {
      final generation = ++_generation;
      emit(SnapshotState(data: state.data, loading: true));
      try {
        await checkAccess?.call();
        final data = await repository.read();
        if (generation == _generation && !isClosed) {
          emit(SnapshotState(data: data));
        }
      } catch (error) {
        if (generation == _generation && !isClosed) {
          emit(SnapshotState(error: AppFailure.from(error)));
        }
      }
    });
    _subscription = repository.changes.listen((_) {
      if (!isClosed) add(SnapshotRequested());
    });
    add(SnapshotRequested());
  }
  final WorkspaceRepository repository;
  final Future<void> Function()? checkAccess;
  late final StreamSubscription<void> _subscription;
  int _generation = 0;
  @override
  Future<void> close() async {
    ++_generation;
    await _subscription.cancel();
    await super.close();
  }
}
