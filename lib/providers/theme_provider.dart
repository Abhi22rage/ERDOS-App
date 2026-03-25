import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Theme Provider ───────────────────────────────────────────────────────────
class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() => false; // false = light mode, true = dark mode

  void toggle() {
    state = !state;
  }

  void setDarkMode(bool isDark) {
    state = isDark;
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, bool>(() {
  return ThemeNotifier();
});
