import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teamflow/app/feature/auth/bloc/auth_bloc.dart';
import 'package:teamflow/app/bootstrap/app_bootstrap.dart';
import '../support/test_app.dart';

void main() {
  late AppBootstrap app;
  setUp(() => app = testApp());
  tearDown(() => app.dispose());
  blocTest<AuthBloc, AuthState>(
    'phone request emits busy then a challenge',
    build: () => AuthBloc(app.auth),
    act: (bloc) => bloc.add(PhoneSubmitted('+12025550101')),
    expect: () => [
      isA<AuthState>().having((s) => s.busy, 'busy', true),
      isA<AuthState>()
          .having((s) => s.challenge?.phone, 'phone', '+12025550101')
          .having((s) => s.busy, 'busy', false),
    ],
  );
}
