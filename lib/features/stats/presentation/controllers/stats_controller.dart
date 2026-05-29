import 'package:flutter/foundation.dart';

import '../../data/stats_repository.dart';

class StatsController extends ChangeNotifier {
  StatsController(this._repository);

  final StatsRepository _repository;

  StatsData? _data;
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  StatsData? get data => _data;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.load();
    } catch (_) {
      _errorMessage = 'Não foi possível carregar as estatísticas.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save(List<StatsInput> inputs) async {
    final session = _data?.session;
    if (session == null) {
      return;
    }

    _saving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _data = await _repository.saveSessionStats(
        weeklySessionId: session.id,
        inputs: inputs,
      );
      _successMessage = 'Stats salvas no aparelho e enfileiradas para sync.';
    } catch (_) {
      _errorMessage = 'Não foi possível salvar as stats.';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
