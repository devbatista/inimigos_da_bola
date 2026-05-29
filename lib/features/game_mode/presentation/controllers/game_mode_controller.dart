import 'dart:async';

import 'package:flutter/foundation.dart';

enum GameTimerMode { countUp, countDown }

@immutable
class GameModeState {
  const GameModeState({
    this.teamAName = 'Time A',
    this.teamBName = 'Time B',
    this.teamAScore = 0,
    this.teamBScore = 0,
    this.timerMode = GameTimerMode.countDown,
    this.targetDuration = const Duration(minutes: 8),
    this.baseElapsed = Duration.zero,
    this.startedAt,
  });

  final String teamAName;
  final String teamBName;
  final int teamAScore;
  final int teamBScore;
  final GameTimerMode timerMode;
  final Duration targetDuration;
  final Duration baseElapsed;
  final DateTime? startedAt;

  bool get isRunning => startedAt != null;

  GameModeState copyWith({
    String? teamAName,
    String? teamBName,
    int? teamAScore,
    int? teamBScore,
    GameTimerMode? timerMode,
    Duration? targetDuration,
    Duration? baseElapsed,
    DateTime? startedAt,
    bool clearStartedAt = false,
  }) {
    return GameModeState(
      teamAName: teamAName ?? this.teamAName,
      teamBName: teamBName ?? this.teamBName,
      teamAScore: teamAScore ?? this.teamAScore,
      teamBScore: teamBScore ?? this.teamBScore,
      timerMode: timerMode ?? this.timerMode,
      targetDuration: targetDuration ?? this.targetDuration,
      baseElapsed: baseElapsed ?? this.baseElapsed,
      startedAt: clearStartedAt ? null : startedAt ?? this.startedAt,
    );
  }
}

class GameModeSnapshot {
  const GameModeSnapshot({
    required this.state,
    required this.elapsed,
    required this.displayDuration,
    required this.finishedByTime,
    required this.finishedByScore,
  });

  final GameModeState state;
  final Duration elapsed;
  final Duration displayDuration;
  final bool finishedByTime;
  final bool finishedByScore;

  bool get isFinished => finishedByTime || finishedByScore;
}

class GameModeController extends ChangeNotifier {
  GameModeController({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  GameModeState _state = const GameModeState();
  Timer? _ticker;

  GameModeState get state => _state;

  GameModeSnapshot get snapshot => snapshotAt(_now());

  GameModeSnapshot snapshotAt(DateTime now) {
    final elapsed = _elapsedAt(now);
    final displayDuration = switch (_state.timerMode) {
      GameTimerMode.countUp => elapsed,
      GameTimerMode.countDown => _remainingFrom(elapsed),
    };

    return GameModeSnapshot(
      state: _state,
      elapsed: elapsed,
      displayDuration: displayDuration,
      finishedByTime: elapsed >= _state.targetDuration,
      finishedByScore: _state.teamAScore >= 2 || _state.teamBScore >= 2,
    );
  }

  void setTimerMode(GameTimerMode mode) {
    if (_state.timerMode == mode) {
      return;
    }

    _state = _state.copyWith(
      timerMode: mode,
      baseElapsed: Duration.zero,
      clearStartedAt: true,
    );
    _stopTicker();
    notifyListeners();
  }

  void start() {
    if (_state.isRunning) {
      return;
    }

    _state = _state.copyWith(startedAt: _now());
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!_state.isRunning) {
      return;
    }

    _state = _state.copyWith(
      baseElapsed: _elapsedAt(_now()),
      clearStartedAt: true,
    );
    _stopTicker();
    notifyListeners();
  }

  void reset() {
    _state = _state.copyWith(
      teamAScore: 0,
      teamBScore: 0,
      baseElapsed: Duration.zero,
      clearStartedAt: true,
    );
    _stopTicker();
    notifyListeners();
  }

  void renameTeamA(String name) => _renameTeam(isTeamA: true, name: name);

  void renameTeamB(String name) => _renameTeam(isTeamA: false, name: name);

  void incrementTeamA() => _setTeamAScore(_state.teamAScore + 1);

  void decrementTeamA() => _setTeamAScore(_state.teamAScore - 1);

  void incrementTeamB() => _setTeamBScore(_state.teamBScore + 1);

  void decrementTeamB() => _setTeamBScore(_state.teamBScore - 1);

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  Duration _elapsedAt(DateTime now) {
    final startedAt = _state.startedAt;
    if (startedAt == null) {
      return _state.baseElapsed;
    }

    final runningElapsed = now.difference(startedAt);
    if (runningElapsed.isNegative) {
      return _state.baseElapsed;
    }

    return _state.baseElapsed + runningElapsed;
  }

  Duration _remainingFrom(Duration elapsed) {
    final remaining = _state.targetDuration - elapsed;
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining;
  }

  void _renameTeam({required bool isTeamA, required String name}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _state = isTeamA
        ? _state.copyWith(teamAName: trimmed)
        : _state.copyWith(teamBName: trimmed);
    notifyListeners();
  }

  void _setTeamAScore(int score) {
    _state = _state.copyWith(teamAScore: score.clamp(0, 99));
    notifyListeners();
  }

  void _setTeamBScore(int score) {
    _state = _state.copyWith(teamBScore: score.clamp(0, 99));
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}
