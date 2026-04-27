import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/main_scaffold.dart';
import '../screens/incidents/raise_issue_screen.dart';
import '../screens/incidents/incident_detail_screen.dart';
import '../screens/incidents/apply_certificate_screen.dart';
import '../screens/tasks/my_tasks_screen.dart';
import '../screens/tasks/approval_dashboard_screen.dart';
import '../screens/schemes/schemes_screen.dart';
import '../screens/contractors/contractors_screen.dart';
import '../screens/contractors/contractor_profile_screen.dart';
import '../screens/assets/assets_screen.dart';
import '../screens/assets/asset_details_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/alerts/alerts_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/reports/certificate_report_screen.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

// ─── Router Provider ──────────────────────────────────────────────────────────
final routerProvider = Provider<GoRouter>((ref) {
  // Notify GoRouter when auth state changes without recreating the entire router
  final refreshNotifier = ValueNotifier<AsyncValue<UserModel?>>(const AsyncLoading());
  
  ref.listen(authProvider, (previous, next) {
    refreshNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
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
            path: '/contractor-profile',
            builder: (context, state) => ContractorProfileScreen(contractor: state.extra as Map<String, dynamic>),
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
      GoRoute(
        path: '/certificate-report/:id',
        builder: (context, state) => CertificateReportScreen(
          incidentId: state.pathParameters['id'],
          budget: state.uri.queryParameters['budget'],
        ),
      ),
      GoRoute(
        path: '/apply-certificate/:id',
        builder: (context, state) => ApplyCertificateScreen(
          incidentId: state.pathParameters['id']!,
        ),
      ),
    ],
  );
});
