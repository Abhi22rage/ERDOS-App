# Dark Mode Removal TODO

## Steps:

- [x] 1. Delete lib/providers/theme_provider.dart
- [x] 2. Edit lib/theme/app_theme.dart: Remove dark colors and darkTheme method
- [x] 3. Edit lib/main.dart: Remove themeProvider import/watch and darkTheme/themeMode
- [x] 4. Edit lib/screens/home_screen.dart: Remove themeProvider import/watch/isDark and theme toggle button
- [x] 5. Run `flutter pub get`
- [x] 6. Run `flutter analyze` (clean, no errors)
- [ ] 7. Test app with `flutter run` (confirm only light theme, no toggle)

Updated on each completion.
