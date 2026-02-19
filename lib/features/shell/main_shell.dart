import 'package:flutter/material.dart';

import '../../components/bottom_nav.dart';
import '../dashboard/presentation/dashboard_screen.dart';
import '../history/presentation/history_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../../core/session/session_manager.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    this.initialTab = BottomNavTab.dashboard,
    this.initialRental,
  });

  final BottomNavTab initialTab;
  final RentalSession? initialRental;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _indexForTab(widget.initialTab);
  }

  int _indexForTab(BottomNavTab tab) {
    switch (tab) {
      case BottomNavTab.history:
        return 0;
      case BottomNavTab.dashboard:
        return 1;
      case BottomNavTab.profile:
        return 2;
    }
  }

  BottomNavTab _tabForIndex(int index) {
    switch (index) {
      case 0:
        return BottomNavTab.history;
      case 1:
        return BottomNavTab.dashboard;
      case 2:
      default:
        return BottomNavTab.profile;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const HistoryScreen(),
      DashboardScreen(initialRental: widget.initialRental),
      const ProfileScreen(),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: tabs,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppBottomNavBar(
              activeTab: _tabForIndex(_index),
              onHistoryTap: () => setState(() => _index = 0),
              onDashboardTap: () => setState(() => _index = 1),
              onProfileTap: () => setState(() => _index = 2),
            ),
          ),
        ],
      ),
    );
  }
}
