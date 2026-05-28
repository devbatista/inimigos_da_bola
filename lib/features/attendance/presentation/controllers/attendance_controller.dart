import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/attendance_repository.dart';

class AttendanceController extends ChangeNotifier {
  AttendanceController(this._repository);

  AttendanceController.fake(AttendanceHomeData data)
    : _repository = null,
      _data = data;

  final AttendanceRepository? _repository;

  AttendanceHomeData? _data;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  AttendanceHomeData? get data => _data;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await repository.load();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar o racha.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> confirm() async {
    final current = _data;
    final repository = _repository;
    if (current == null || repository == null) {
      return;
    }

    await _submit(() => repository.confirm(current));
  }

  Future<void> decline() async {
    final current = _data;
    final repository = _repository;
    if (current == null || repository == null) {
      return;
    }

    await _submit(() => repository.decline(current));
  }

  Future<void> _submit(Future<AttendanceHomeData> Function() action) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await action();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar sua presença.';
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
