import 'package:flutter/material.dart';

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
    final neutral = Colors.grey.shade500;

    Widget buildItem({
      required IconData icon,
      required bool isActive,
      required VoidCallback? onTap,
    }) {
      final bgColor = isActive ? accent : const Color(0xFFF0F4FA);
      final iconColor = isActive ? Colors.white : neutral;
      return GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x1A2C7BFE),
                      blurRadius: 12,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          buildItem(
            icon: Icons.history_rounded,
            isActive: activeTab == BottomNavTab.history,
            onTap: onHistoryTap,
          ),
          buildItem(
            icon: Icons.electric_moped_rounded,
            isActive: activeTab == BottomNavTab.dashboard,
            onTap: onDashboardTap,
          ),
          buildItem(
            icon: Icons.person_outline_rounded,
            isActive: activeTab == BottomNavTab.profile,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}
