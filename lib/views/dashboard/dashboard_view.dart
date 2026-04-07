
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../../viewmodels/auth_provider.dart';
import '../../widgets/top_navigation_bar.dart';
import '../../widgets/responsive_widget.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        context.read<DashboardViewModel>().fetchDashboardStats(token);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveWidget.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const TopNavigationBar(currentRoute: '/dashboard'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 48),
                    _buildCardsSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isMobile = ResponsiveWidget.isMobile(context);

    final locationInfo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow(Icons.location_on_outlined, vm.clubName ?? 'Elite club Melbourne'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.calendar_today_outlined, 'Today'),
        const SizedBox(height: 8),
        _buildInfoRow(Icons.access_time, vm.formattedTime),
      ],
    );

    final titleInfo = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Dashboard',
          style: AppTextStyles.heading1.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text( 
          'Real-time monitoring of all facility access attempts and verifications.',
          style: AppTextStyles.bodyLight.copyWith(
              fontSize: 14, color: const Color(0xFFE2E8F0)),
        ),
      ],
    );

    final countInfo = Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          'Entry/Exit Count',
          style: AppTextStyles.bodyLight.copyWith(fontSize: 14, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCountButton(
              icon: Icons.remove,
              onTap: () => context.read<DashboardViewModel>().decrementEntry(),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                vm.formattedEntryCount,
                style: AppTextStyles.bodyLight.copyWith(letterSpacing: 2),
              ),
            ),
            const SizedBox(width: 8),
            _buildCountButton(
              icon: Icons.add,
              onTap: () => context.read<DashboardViewModel>().incrementEntry(),
            ),
          ],
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleInfo,
          const SizedBox(height: 32),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [locationInfo, countInfo],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [locationInfo, titleInfo, countInfo],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMain),
        const SizedBox(width: 8),
        Text(text, style: AppTextStyles.bodyLight.copyWith(fontSize: 12)),
      ],
    );
  }

  Widget _buildCountButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ================= CARDS SECTION =================
  Widget _buildCardsSection(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isMobile = ResponsiveWidget.isMobile(context);
    final isTablet = ResponsiveWidget.isTablet(context);

    int crossAxisCount = isMobile ? 1 : 3; // Mobile 1, Tablet/Web 3

    final spacing = 24.0;

    // Combine all cards into one list for easier grid layout
    final cards = <Widget>[
      _buildStatCard(
        iconBackground: const Color(0xFF2C1E26),
        icon: Icons.person_off_outlined,
        iconColor: AppColors.errorRed,
        title: 'Active Bans',
        value: vm.activeBans.toString(),
      ),
      _buildStatCard(
        iconBackground: const Color(0xFF2A231C),
        icon: Icons.login,
        iconColor: AppColors.warningOrange,
        title: 'Today Entries',
        value: vm.todayEntries.toString(),
      ),
      _buildStatCard(
        iconBackground: const Color(0xFF1B2333),
        icon: Icons.assignment_late_outlined,
        iconColor: const Color(0xFF8C9BB3),
        title: 'Pending Ban Req',
        value: vm.pendingBanReq.toString(),
      ),
      _buildActionCard(
        context,
        iconBackground: const Color(0xFF132724),
        icon: Icons.qr_code_scanner,
        iconColor: AppColors.primaryGreen,
        title: 'Start Scanning',
        subtitle: 'Scan patron QR codes',
        route: '/entry_scan',
      ),
      _buildActionCard(
        context,
        iconBackground: const Color(0xFF2C1E26),
        icon: Icons.do_not_disturb_alt,
        iconColor: AppColors.errorRed,
        title: 'Raise Ban & Warning request',
        subtitle: 'Ban & Warn a Person',
        route: '/ban_warning',
      ),
      _buildActionCard(
        context,
        iconBackground: const Color(0xFF16203B),
        icon: Icons.security,
        iconColor: AppColors.actionBlue,
        title: 'Inspection Log',
        subtitle: 'Inspection entry Details',
        route: '/inspection_log',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard({
    required Color iconBackground,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return _buildBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 24),
          Text(title, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.heading1.copyWith(fontSize: 32)),
        ],
      ),
    );
  }

  // ================= ACTION CARD =================
  Widget _buildActionCard(
      BuildContext context, {
        required Color iconBackground,
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required String route,
      }) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: _buildBaseCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3Light.copyWith(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodyMuted.copyWith(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BASE CARD =================
  Widget _buildBaseCard({required Widget child}) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2633),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF384457).withOpacity(0.5)),
      ),
      child: child,
    );
  }
}