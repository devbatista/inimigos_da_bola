import 'package:flutter_riverpod/legacy.dart';

import 'game_mode_controller.dart';

// AutoDispose: cronômetro e placar são ferramentas de quadra e não persistem.
final gameModeControllerProvider =
    ChangeNotifierProvider.autoDispose<GameModeController>((ref) {
      return GameModeController();
    });
