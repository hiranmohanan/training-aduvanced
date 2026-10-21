import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repository/demo/demo_repository.dart';

sealed class SettingsEvent {}

class OfflineChanged extends SettingsEvent {
  OfflineChanged(this.value);
  final bool value;
}

class DemoResetRequested extends SettingsEvent {}

class SettingsState {
  const SettingsState(this.offline, {this.reset = false});
  final bool offline, reset;
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc(this.repository) : super(SettingsState(repository.offline)) {
    on<SettingsEvent>((event, emit) {
      if (event is OfflineChanged) {
        repository.setOffline(event.value);
        emit(SettingsState(event.value));
      }
      if (event is DemoResetRequested) {
        repository.reset();
        emit(const SettingsState(false, reset: true));
      }
    });
  }
  final DemoRepository repository;
}
