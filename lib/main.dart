import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'viewmodels/auth_provider.dart';
import 'viewmodels/dashboard_view_model.dart';
import 'viewmodels/ban_warning_view_model.dart';
import 'viewmodels/entry_scan_view_model.dart';
import 'viewmodels/inspection_log_view_model.dart';
import 'viewmodels/settings_view_model.dart';
import 'views/inspection_log/entry_logs_provider.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => BanWarningViewModel()),
        ChangeNotifierProvider(create: (_) => EntryScanViewModel()),
        ChangeNotifierProvider(create: (_) => InspectionLogViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => EntryLogsProvider()),
      ],
      child: const SecureClubApp(),
    ),
  );
}

class SecureClubApp extends StatelessWidget {
  const SecureClubApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SecureClub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
    );
  }
}
