import 'package:flutter_riverpod/legacy.dart';

import 'theme_mode_controller.dart';

final themeModeControllerProvider = ChangeNotifierProvider<ThemeModeController>(
  (ref) => ThemeModeController(),
);
