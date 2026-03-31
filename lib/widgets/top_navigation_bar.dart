
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'responsive_widget.dart';

class TopNavigationBar extends StatelessWidget {
  final String currentRoute;

  const TopNavigationBar({Key? key, required this.currentRoute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: ResponsiveWidget.isMobile(context)
          ? _buildMobileNav(context)
          : _buildDesktopNav(context),
    );
  }


  Widget _buildDesktopNav(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive breakpoints
    bool isMobile = screenWidth < 600;
    bool showMenuInsteadOfNav = screenWidth < 750;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // LEFT: Logo + Title
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                context.push('/settings');
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Color(0xFF3A4554),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFFFFFFFF),
                  size: 24,
                ),
              ),
            ),
            SizedBox(width: 10,),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SecureClub',
                    style: AppTextStyles.heading3Light.copyWith(fontSize: 18)),
                Text(
                  'ADMIN TERMINAL',
                  style: AppTextStyles.bodyMuted.copyWith(
                      fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        // CENTER: Navigation / Menu
        if (!showMenuInsteadOfNav)
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF242C38),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(context, 'Entry Scan', Icons.crop_free, '/entry_scan'),
                  _buildNavItem(context, 'Dashboard', Icons.dashboard, '/dashboard'),
                  _buildNavItem(context, 'Ban Request', Icons.block, '/ban_warning'),
                  _buildNavItem(context, 'Inspection Log', Icons.security, '/inspection_log'),
                  // _buildNavItem(context, 'Settings', Icons.settings, '/settings'),
                ],
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            color: AppColors.cardBackground,
            onSelected: (route) {
              if (currentRoute != route) context.go(route);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/entry_scan', child: Text('Entry Scan')),
              PopupMenuItem(value: '/dashboard', child: Text('Dashboard')),
              PopupMenuItem(value: '/ban_warning', child: Text('Ban Request')),
              PopupMenuItem(value: '/inspection_log', child: Text('Inspection Log')),
              PopupMenuItem(value: '/settings', child: Text('Settings')),
            ],
          ),

        // RIGHT: Profile
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF384457).withOpacity(0.5),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Marcus Thorne',
                    style: AppTextStyles.bodyLight.copyWith(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                Text('GUARD',
                    style: AppTextStyles.bodyMuted.copyWith(
                        fontSize: 10, letterSpacing: 0.5)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ================= MOBILE =================
  Widget _buildMobileNav(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo + Title
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('SecureClub',
                    style: AppTextStyles.heading3Light.copyWith(fontSize: 16)),
                Text('ADMIN',
                    style: AppTextStyles.bodyMuted.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),

        // Hamburger Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          color: AppColors.cardBackground,
          onSelected: (route) {
            if (currentRoute != route) context.go(route);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: '/entry_scan', child: Text('Entry Scan')),
            PopupMenuItem(value: '/dashboard', child: Text('Dashboard')),
            PopupMenuItem(value: '/ban_warning', child: Text('Ban Request')),
            PopupMenuItem(value: '/inspection_log', child: Text('Inspection Log')),
            PopupMenuItem(value: '/settings', child: Text('Settings')),
          ],
        ),
      ],
    );
  }

  // ================= NAV ITEM =================
  Widget _buildNavItem(
      BuildContext context, String title, IconData icon, String route) {
    bool isSelected = currentRoute == route;

    return GestureDetector(
      onTap: () {
        if (!isSelected) context.go(route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : const Color(0xFF2C3545),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF9E9E9E)),
            const SizedBox(width: 6),
            Text(
              title,
              style: isSelected
                  ? AppTextStyles.bodyLight.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white)
                  : AppTextStyles.bodyMuted.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: const Color(0xFFCBCBCB)),
            ),
          ],
        ),
      ),
    );
  }
}