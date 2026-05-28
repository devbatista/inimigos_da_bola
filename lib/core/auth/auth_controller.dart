import 'package:flutter/foundation.dart';

import '../api/api_exception.dart';
import 'auth_repository.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository, {AuthStatus status = AuthStatus.checking})
    : _status = status;

  final AuthRepository _repository;

  AuthStatus _status;
  bool _submitting = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _status = await _repository.hasStoredSession()
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível entrar. Tente novamente.';
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
