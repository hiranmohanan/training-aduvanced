import '../clock/clock_service.dart';

class WorkTimerService {
  WorkTimerService(this.clock);
  final ClockService clock;
  Stream<Duration> elapsedSince(DateTime start) async* {
    yield clock.now.difference(start);
    yield* Stream.periodic(
      const Duration(seconds: 1),
      (_) => clock.now.difference(start),
    );
  }
}
