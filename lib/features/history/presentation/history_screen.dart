import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../../components/bottom_nav.dart';
import '../../../core/navigation/app_route.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const stats = [
      _StatItem(
        label: 'Mileage',
        value: '40,22 km',
        icon: Icons.route_rounded,
      ),
      _StatItem(
        label: 'Active Days',
        value: '20 Days',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatItem(
        label: 'Reduced Emission',
        value: '5,19',
        icon: Icons.eco_rounded,
      ),
    ];

    const history = [
      _HistoryItem(
        date: '6 June 2025',
        durationAndCost: '30 Days - Rp 100.000',
        distanceKm: '100 km',
        plate: 'DR 1234 PW',
      ),
      _HistoryItem(
        date: '6 April 2025',
        durationAndCost: '12 Days - Rp 50.000',
        distanceKm: '221 km',
        plate: 'DR 1211 XY',
      ),
      _HistoryItem(
        date: '20 January 2025',
        durationAndCost: '12 Days - Rp 50.000',
        distanceKm: '100 km',
        plate: 'DR 3211 AB',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Text(
              'My History',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _StatsRow(items: stats),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                itemBuilder: (context, index) =>
                    _HistoryCard(item: history[index]),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: history.length,
              ),
            ),
            const SizedBox(height: 6),
            AppBottomNav(
              activeTab: BottomNavTab.history,
              onDashboardTap: () {
                Navigator.of(context).pushReplacement(
                  appRoute(const DashboardScreen(),
                      direction: AxisDirection.right),
                );
              },
              onProfileTap: () {
                Navigator.of(context).pushReplacement(
                  appRoute(const ProfileScreen(),
                      direction: AxisDirection.left),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _StatTile(item: items[i])),
            if (i != items.length - 1)
              Container(
                width: 1,
                height: 42,
                color: const Color(0xFFE8ECF2),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.item});

  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, color: accent, size: 20),
        const SizedBox(height: 6),
        Text(
          item.value,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  const _StatItem(
      {required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;
}

class _HistoryItem {
  const _HistoryItem({
    required this.date,
    required this.durationAndCost,
    required this.distanceKm,
    required this.plate,
  });

  final String date;
  final String durationAndCost;
  final String distanceKm;
  final String plate;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final _HistoryItem item;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F4FA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_outlined,
                        color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      item.date,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        color: Colors.grey.shade500, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      item.durationAndCost,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _Chip(text: item.distanceKm, color: accent),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/dashboard.png',
                height: 88,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 10),
              Text(
                item.plate,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
