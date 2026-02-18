import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/localization/app_localizations.dart';

enum BottomNavTab { history, dashboard, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeTab,
    this.onHistoryTap,
    this.onDashboardTap,
    this.onProfileTap,
  });

  final BottomNavTab activeTab;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onDashboardTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    const neutral = Color(0xFF9AA0AA);
    const bgColor = Colors.white;
    const dividerColor = Color(0xFFE6E9F2);
    final l10n = AppLocalizations.of(context);

    int indexForTab(BottomNavTab tab) {
      switch (tab) {
        case BottomNavTab.history:
          return 0;
        case BottomNavTab.dashboard:
          return 1;
        case BottomNavTab.profile:
          return 2;
      }
    }

    Widget buildItem({
      required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback? onTap,
    }) {
      final iconColor = isActive ? accent : neutral;
      final textColor = isActive ? accent : neutral;
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 58,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  scale: isActive ? 1.08 : 1,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: isActive ? 1 : 0.8,
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeIndex = indexForTab(activeTab);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: dividerColor),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 3;
          final indicatorWidth = 36.0;
          final left =
              (itemWidth * activeIndex) + (itemWidth - indicatorWidth) / 2;
          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOutCubic,
                left: left,
                bottom: 2,
                child: Container(
                  height: 3,
                  width: indicatorWidth,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                children: [
                  buildItem(
                    icon: Icons.history_rounded,
                    label: l10n.navHistory,
                    isActive: activeTab == BottomNavTab.history,
                    onTap: onHistoryTap,
                  ),
                  buildItem(
                    icon: Icons.electric_moped_rounded,
                    label: l10n.navDashboard,
                    isActive: activeTab == BottomNavTab.dashboard,
                    onTap: onDashboardTap,
                  ),
                  buildItem(
                    icon: Icons.person_outline_rounded,
                    label: l10n.navProfile,
                    isActive: activeTab == BottomNavTab.profile,
                    onTap: onProfileTap,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.activeTab,
    this.onHistoryTap,
    this.onDashboardTap,
    this.onProfileTap,
  });

  final BottomNavTab activeTab;
  final VoidCallback? onHistoryTap;
  final VoidCallback? onDashboardTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AppBottomNav(
        activeTab: activeTab,
        onHistoryTap: onHistoryTap,
        onDashboardTap: onDashboardTap,
        onProfileTap: onProfileTap,
      ),
    );
  }
}
