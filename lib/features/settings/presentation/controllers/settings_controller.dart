import 'package:flutter/foundation.dart';

import '../../../../core/db/app_database.dart';
import '../../data/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;

  User? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  User? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.loadProfile();
    } catch (_) {
      _errorMessage = 'Não foi possível carregar seu perfil.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(SettingsProfileUpdate update) async {
    _saving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _profile = await _repository.updateProfile(update);
      _successMessage = 'Perfil atualizado.';
    } catch (_) {
      _errorMessage = 'Não foi possível salvar seu perfil.';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
