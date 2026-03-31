

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_text_styles.dart' show AppTextStyles;
import '../../widgets/top_navigation_bar.dart';
import '../../viewmodels/auth_provider.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../dashboard/dashboard_view.dart';
import '../login/login_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool autoFlash = true;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double horizontalPadding = 20;
    if (screenWidth < 600) {
      horizontalPadding = 16;
    } else if (screenWidth < 1100) {
      horizontalPadding = 24;
    } else {
      horizontalPadding = 20;
    }

    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1E2D),
      body: SafeArea(
        child: Column(
          children: [

            // ── Top Nav Bar ──
            const TopNavigationBar(currentRoute: '/settings'),

            const SizedBox(height: 10),

            Text(
              "Settings",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 26 : 34,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Container(
                      padding: EdgeInsets.all(isMobile ? 20 : 30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // ── DEVICE INFORMATION header + LOGOUT button ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "DEVICE INFORMATION",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 12,
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await context.read<AuthProvider>().logout();
                                  if (context.mounted) {
                                    context.go('/');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Colors.black87, width: 1.5),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.logout,
                                    color: Colors.black87, size: 16),
                                label: const Text(
                                  "LOGOUT",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Device info card ──
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const _InfoRow(title: "Device ID", value: "TAB-001-2026"),
                                const Divider(),
                                _InfoRow(title: "Club", value: context.watch<DashboardViewModel>().clubName ?? "Mamao Club"),
                                const Divider(),
                                const _InfoRow(title: "App Version", value: "1.0.0"),
                                const Divider(),
                                const _StatusRow(title: "Status", value: "Connected"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── SCAN SETTINGS ──
                          const Text(
                            "SCAN SETTINGS",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F4F4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: _SwitchTile(
                              title: "Auto-flash in dim light",
                              subtitle: "Enable flash for face capture (NFR07)",
                              value: autoFlash,
                              onChanged: (val) =>
                                  setState(() => autoFlash = val),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── Back button — bottom right ──


                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/dashboard');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white, size: 18),
                              label: const Text(
                                "Back",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DEVICE INFO ROW
class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.black54)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// STATUS ROW WITH GREEN DOT
class _StatusRow extends StatelessWidget {
  final String title;
  final String value;

  const _StatusRow({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Status", style: TextStyle(color: Colors.black54)),
        Row(
          children: [
            const CircleAvatar(radius: 5, backgroundColor: Colors.green),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}

/// SWITCH TILE
class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style:
                  const TextStyle(color: Colors.black54, fontSize: 13)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: const Color(0xFF14C38E),
          onChanged: onChanged,
        ),
      ],
    );
  }
}