import 'package:flutter_test/flutter_test.dart';
import 'package:inimigos_da_bola/features/game_mode/presentation/controllers/game_mode_controller.dart';

void main() {
  group('GameModeController', () {
    late DateTime currentTime;
    late GameModeController controller;

    setUp(() {
      currentTime = DateTime(2026, 1, 5, 20);
      controller = GameModeController(now: () => currentTime);
    });

    tearDown(() {
      controller.dispose();
    });

    test('uses countdown with 08:00 by default', () {
      expect(controller.snapshot.displayDuration, const Duration(minutes: 8));
      expect(controller.snapshot.state.timerMode, GameTimerMode.countDown);
    });

    test('keeps counting from absolute time while running', () {
      controller.start();

      currentTime = currentTime.add(const Duration(minutes: 3, seconds: 15));

      expect(
        controller.snapshot.displayDuration,
        const Duration(minutes: 4, seconds: 45),
      );
    });

    test('pauses with elapsed time accumulated', () {
      controller.start();
      currentTime = currentTime.add(const Duration(minutes: 2));

      controller.pause();
      currentTime = currentTime.add(const Duration(minutes: 1));

      expect(controller.snapshot.displayDuration, const Duration(minutes: 6));
    });

    test('supports count up mode', () {
      controller.setTimerMode(GameTimerMode.countUp);
      controller.start();

      currentTime = currentTime.add(const Duration(seconds: 42));

      expect(controller.snapshot.displayDuration, const Duration(seconds: 42));
    });

    test('marks match finished by time', () {
      controller.start();

      currentTime = currentTime.add(const Duration(minutes: 8));

      expect(controller.snapshot.finishedByTime, isTrue);
      expect(controller.snapshot.isFinished, isTrue);
      expect(controller.snapshot.displayDuration, Duration.zero);
    });

    test('marks match finished by score', () {
      controller.incrementTeamA();
      controller.incrementTeamA();

      expect(controller.snapshot.finishedByScore, isTrue);
      expect(controller.snapshot.isFinished, isTrue);
    });

    test('reset clears timer and score', () {
      controller.incrementTeamB();
      controller.start();
      currentTime = currentTime.add(const Duration(minutes: 1));

      controller.reset();

      expect(controller.snapshot.state.teamBScore, 0);
      expect(controller.snapshot.state.isRunning, isFalse);
      expect(controller.snapshot.displayDuration, const Duration(minutes: 8));
    });
  });
}
