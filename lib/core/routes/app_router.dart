import 'package:go_router/go_router.dart';
import '../../views/login/login_view.dart';
import '../../views/login/forgot_password_view.dart';
import '../../views/dashboard/dashboard_view.dart';
import '../../views/ban_warning/ban_warning_view.dart';
import '../../views/entry_scan/entry_scan_view.dart';
import '../../views/inspection_log/inspection_log_view.dart';
import '../../views/settings/settings_view.dart';
import '../../views/entry_scan/qr_scanner_view.dart';
import '../../views/ban_warning/raise_ban_request_page.dart';
import '../../views/ban_warning/raise_warning_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardView(),
      ),
      GoRoute(
        path: '/ban_warning',
        builder: (context, state) => const BanWarningView(),
      ),
      GoRoute(
        path: '/entry_scan',
        builder: (context, state) => const EntryScanView(),
      ),
      GoRoute(
        path: '/inspection_log',
        builder: (context, state) => const InspectionLogView(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsView(),
      ),
      GoRoute(
        path: '/qr_scanner',
        builder: (context, state) => const QrScannerView(),
      ),
      GoRoute(
        path: '/raise_ban_request',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RaiseBanRequestPage(
            name: extra['name'] as String? ?? '',
            id: extra['id'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/raise_warning',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RaiseWarningPage(
            name: extra['name'] as String? ?? '',
            id: extra['id'] as String? ?? '',
          );
        },
      ),
    ],
  );
}
