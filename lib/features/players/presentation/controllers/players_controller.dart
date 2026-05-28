import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/db/app_database.dart';
import '../../data/players_repository.dart';

class PlayersController extends ChangeNotifier {
  PlayersController(this._repository);

  final PlayersRepository _repository;

  List<User> _players = const [];
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  List<User> get players => _players;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _players = await _repository.load();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar os jogadores.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> invite({required String email, required String name}) async {
    await _submit(() => _repository.invite(email: email, name: name));
  }

  Future<void> update(User user, PlayerUpdate update) async {
    await _submit(() => _repository.update(user, update));
  }

  Future<void> softDelete(User user) async {
    await _submit(() => _repository.softDelete(user));
  }

  Future<void> _submit(Future<List<User>> Function() action) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _players = await action();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar o jogador.';
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
