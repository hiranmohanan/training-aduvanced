import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/app_user.dart';
import '../../../repository/auth/auth_repository.dart';
import '../../../shared/errors/app_failure.dart';

sealed class AuthEvent {}

class PhoneSubmitted extends AuthEvent {
  PhoneSubmitted(this.phone);
  final String phone;
}

class CodeSubmitted extends AuthEvent {
  CodeSubmitted(this.code);
  final String code;
}

class LogoutRequested extends AuthEvent {}

class PhoneChangeRequested extends AuthEvent {}

class SessionReset extends AuthEvent {}

class AuthState extends Equatable {
  const AuthState({this.user, this.challenge, this.busy = false, this.error});
  final AppUser? user;
  final OtpChallenge? challenge;
  final bool busy;
  final String? error;
  @override
  List<Object?> get props => [user, challenge, busy, error];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.repository) : super(const AuthState()) {
    on<AuthEvent>((event, emit) async {
      if (state.busy) return;
      final previous = state;
      if (event is PhoneChangeRequested || event is SessionReset) {
        emit(const AuthState());
        return;
      }
      emit(AuthState(user: state.user, challenge: state.challenge, busy: true));
      try {
        switch (event) {
          case PhoneSubmitted():
            emit(
              AuthState(challenge: await repository.requestCode(event.phone)),
            );
          case CodeSubmitted():
            if (previous.challenge == null) {
              emit(const AuthState());
              return;
            }
            emit(
              AuthState(
                user: await repository.verify(previous.challenge!, event.code),
              ),
            );
          case LogoutRequested():
            await repository.logout();
            emit(const AuthState());
          default:
            break;
        }
      } catch (error) {
        emit(
          AuthState(
            user: previous.user,
            challenge: previous.challenge,
            error: AppFailure.from(error).message,
          ),
        );
      }
    });
  }
  final AuthRepository repository;
}
