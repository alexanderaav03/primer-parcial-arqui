import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

const _prefsKey = 'selected_theme';

extension _AppThemeOptionStorage on AppThemeOption {
  String get _storageValue => switch (this) {
        AppThemeOption.energetic => 'energetic',
        AppThemeOption.premium => 'premium',
      };

  static AppThemeOption _fromStorage(String? value) => switch (value) {
        'premium' => AppThemeOption.premium,
        _ => AppThemeOption.energetic,
      };
}

class ThemeOptionNotifier extends Notifier<AppThemeOption> {
  @override
  AppThemeOption build() => AppThemeOption.energetic;

  /// Se llama una vez al arrancar la app (antes de runApp) para aplicar el
  /// tema guardado desde el primer frame, sin flash del tema default.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = _AppThemeOptionStorage._fromStorage(prefs.getString(_prefsKey));
  }

  Future<void> select(AppThemeOption option) async {
    state = option;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, option._storageValue);
  }
}

final themeOptionProvider = NotifierProvider<ThemeOptionNotifier, AppThemeOption>(ThemeOptionNotifier.new);
