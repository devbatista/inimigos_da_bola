import 'package:flutter/foundation.dart';

import '../../../../core/api/api_exception.dart';
import '../../data/guest_attendance_repository.dart';

class GuestAttendanceController extends ChangeNotifier {
  GuestAttendanceController(this._repository);

  final GuestAttendanceRepository _repository;

  GuestAttendanceData? _data;
  bool _loading = false;
  bool _submitting = false;
  String? _errorMessage;

  GuestAttendanceData? get data => _data;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _repository.load();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar as presenças avulsas.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> create(String guestName) async {
    final current = _data;
    if (current == null) {
      return;
    }

    await _submit(
      () => _repository.create(current: current, guestName: guestName),
    );
  }

  Future<void> delete(String attendanceId) async {
    final current = _data;
    if (current == null) {
      return;
    }

    await _submit(
      () => _repository.delete(current: current, attendanceId: attendanceId),
    );
  }

  Future<void> _submit(Future<GuestAttendanceData> Function() action) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await action();
    } on ApiException catch (exception) {
      _errorMessage = exception.message;
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar a presença avulsa.';
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
