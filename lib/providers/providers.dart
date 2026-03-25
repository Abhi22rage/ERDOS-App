import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/user_model.dart';
import '../models/breakdown_model.dart';
import '../services/api_service.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/signup_screen.dart';
import '../screens/home_screen.dart';
import '../screens/raise_issue_screen.dart';
import '../screens/incident_detail_screen.dart';
import '../screens/my_tasks_screen.dart';
import '../screens/approval_dashboard_screen.dart';
import '../screens/schemes_screen.dart';
import '../screens/contractors_screen.dart';
import '../screens/assets_screen.dart';
import '../screens/asset_details_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/certificate_report_screen.dart';
import '../screens/main_scaffold.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

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

// Auth state notifier
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return ref.read(apiServiceProvider).getCurrentUser();
  }

  Future<void> login(String mobile, String password) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(apiServiceProvider).login(mobile, password);
      state = AsyncValue.data(result['user'] as UserModel?);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signup(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(apiServiceProvider).signup(userData);
      state = AsyncValue.data(result['user'] as UserModel?);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(apiServiceProvider).logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = state.value;
    if (user != null) {
      await ref.read(apiServiceProvider).updateUserProfile(user.id, data);
      state = AsyncValue.data(await ref.read(apiServiceProvider).getCurrentUser());
    }
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(
  AuthNotifier.new,
);

// ─── Router Provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.watch(authProvider);
      final bool loggingIn =
          state.uri.path == '/login' || state.uri.path == '/signup';

      debugPrint('Router Redirect: path=${state.uri.path}, auth=$authState');

      return authState.when(
        data: (user) {
          if (user == null && !loggingIn) return '/login';
          if (user != null && loggingIn) return '/home';
          return null;
        },
        loading: () => null,
        error: (err, _) {
          debugPrint('Auth Error: $err');
          return '/login';
        },
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/schemes',
            builder: (context, state) => SchemesScreen(
              initialCenter: state.uri.queryParameters['center'],
              initialAsset: state.uri.queryParameters['asset'],
            ),
          ),
          GoRoute(
            path: '/contractors',
            builder: (context, state) => const ContractorsScreen(),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => AssetsScreen(
              type: state.uri.queryParameters['type'],
            ),
          ),
          GoRoute(
            path: '/assets/:id',
            builder: (context, state) =>
                AssetDetailsScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/my-tasks',
            builder: (context, state) => const MyTasksScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/raise-issue',
        builder: (context, state) => const RaiseIssueScreen(),
      ),
      GoRoute(
        path: '/incident/:id',
        builder: (context, state) =>
            IncidentDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/approvals',
        builder: (context, state) => const ApprovalDashboardScreen(),
      ),
      GoRoute(
        path: '/certificate-report',
        builder: (context, state) => const CertificateReportScreen(),
      ),
    ],
  );
});

// ─── Summary / Report ─────────────────────────────────────────────────────────
final summaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.read(apiServiceProvider).getSummary();
});

// ─── Breakdowns ───────────────────────────────────────────────────────────────
final myBreakdownsProvider =
    FutureProvider.autoDispose<List<BreakdownModel>>((ref) async {
  return ref.read(apiServiceProvider).getMyBreakdowns();
});

final allBreakdownsProvider =
    FutureProvider.autoDispose<List<BreakdownModel>>((ref) async {
  return ref.read(apiServiceProvider).getBreakdowns();
});

final breakdownDetailProvider =
    FutureProvider.family.autoDispose<BreakdownModel, String>((ref, id) async {
  return ref.read(apiServiceProvider).getBreakdownById(id);
});

// ─── Tasks ────────────────────────────────────────────────────────────────────
final tasksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(apiServiceProvider).getTasks();
});

// ─── Notifications ────────────────────────────────────────────────────────────
final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(apiServiceProvider).getNotifications();
});

// ─── Pending Approvals ────────────────────────────────────────────────────────
final pendingApprovalsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getPendingApprovals();
});

// ─── Schemes ──────────────────────────────────────────────────────────────────
final schemesProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getSchemes();
});

// ─── Assets ───────────────────────────────────────────────────────────────────
final assetsProvider =
    FutureProvider.family.autoDispose((ref, String? type) async {
  return ref.read(apiServiceProvider).getAssets(type: type);
});

// ─── Contractors ──────────────────────────────────────────────────────────────
final contractorsProvider = FutureProvider.autoDispose((ref) async {
  return ref.read(apiServiceProvider).getContractors();
});
