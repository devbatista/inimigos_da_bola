import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/skill_ratings_repository.dart';

class SkillRatingsController extends ChangeNotifier {
  SkillRatingsController(this._repository);

  final SkillRatingsRepository _repository;

  SkillRatingsData? _data;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;
  String? _submitErrorMessage;

  SkillRatingsData? get data => _data;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  String? get submitErrorMessage => _submitErrorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.load();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os jogadores.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearSubmitError() {
    if (_submitErrorMessage == null) {
      return;
    }

    _submitErrorMessage = null;
    notifyListeners();
  }

  Future<bool> submit({
    required String evaluatedUserId,
    required int score,
  }) async {
    final current = _data;
    if (current == null) {
      return false;
    }

    _submitting = true;
    _submitErrorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.submit(
        currentUserId: current.currentUserId,
        currentUserEmail: current.currentUserEmail,
        evaluatedUserId: evaluatedUserId,
        score: score,
      );
      return true;
    } on ApiException catch (exception) {
      _submitErrorMessage = exception.message;
      return false;
    } catch (_) {
      _submitErrorMessage = 'Não foi possível enviar a nota.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
