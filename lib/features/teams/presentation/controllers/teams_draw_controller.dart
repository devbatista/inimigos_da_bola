import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/teams_draw_repository.dart';
import '../../domain/draw_algorithm.dart';
import '../../domain/team_plan.dart';

class TeamsDrawController extends ChangeNotifier {
  TeamsDrawController(this._repository);

  final TeamsDrawRepository _repository;
  final Random _random = Random();

  List<DrawParticipant> _loadedParticipants = const [];
  final List<DrawParticipant> _temporaryParticipants = [];
  final Set<String> _removedIds = <String>{};

  bool _loading = false;
  String? _errorMessage;

  DrawResult? _result;
  TeamPlanFailure? _planFailure;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  DrawResult? get result => _result;
  TeamPlanFailure? get planFailure => _planFailure;

  List<DrawParticipant> get participants {
    return [
      ..._loadedParticipants,
      ..._temporaryParticipants,
    ].where((participant) => !_removedIds.contains(participant.id)).toList();
  }

  int get participantCount => participants.length;
  int get goalkeeperCount =>
      participants.where((participant) => participant.goalkeeper).length;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loadedParticipants = await _repository.loadConfirmedParticipants();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os confirmados.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void addTemporaryParticipant({
    required String name,
    required bool goalkeeper,
  }) {
    final id = 'temp-${DateTime.now().microsecondsSinceEpoch}';
    _temporaryParticipants.add(
      DrawParticipant(
        id: id,
        name: name.trim(),
        kind: DrawParticipantKind.temporary,
        goalkeeper: goalkeeper,
      ),
    );
    _result = null;
    notifyListeners();
  }

  void removeParticipant(String id) {
    _temporaryParticipants.removeWhere((participant) => participant.id == id);
    _removedIds.add(id);
    _result = null;
    notifyListeners();
  }

  void draw() {
    _planFailure = null;

    final planResult = planTeams(
      participantCount: participantCount,
      goalkeeperCount: goalkeeperCount,
    );

    if (planResult is TeamPlanFailure) {
      _planFailure = planResult;
      _result = null;
      notifyListeners();
      return;
    }

    final plan = (planResult as TeamPlanSuccess).plan;
    _result = snakeDraft(
      participants: participants,
      plan: plan,
      seed: _random.nextInt(1 << 31),
    );
    notifyListeners();
  }

  void renameTeam(int index, String name) {
    final current = _result;
    if (current == null || index < 0 || index >= current.teams.length) {
      return;
    }

    final updated = [...current.teams];
    updated[index] = DrawTeam(
      name: name.trim(),
      players: current.teams[index].players,
    );
    _result = DrawResult(teams: updated, seed: current.seed);
    notifyListeners();
  }

  void clearResult() {
    _result = null;
    _planFailure = null;
    notifyListeners();
  }
}
