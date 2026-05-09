import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';

// ─── IMPORTANT: Replace with your Supabase credentials ─────────────────────
// Get these from: Project Settings → API in your Supabase dashboard
const String supabaseUrl = 'https://ezzimhxbxspkogazgpcp.supabase.co';
const String supabaseAnonKey = 'sb_publishable_rWjGI8t2DX2NcFW8HHlmow_l8PZ0uNq';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(
    const ProviderScope(
      child: PHEApp(),
    ),
  );
}

class PHEApp extends ConsumerWidget {
  const PHEApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'PHE Emergency App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
