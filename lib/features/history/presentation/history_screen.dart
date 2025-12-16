import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'detail_history_screen.dart';
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
      HistoryItem(
        date: '6 June 2025',
        durationAndCost: '30 Days - Rp 100.000',
        distanceKm: '100 km',
        plate: 'DR 1234 PW',
        calories: '79.64 kcal',
        emission: '0.23 g',
        startTime: '16:05 PM',
        endTime: '16:15 PM',
        startPlace:
            'C37V+Q4P, Jl. Unram, Gomong, Kec. Selaparang, Kota Mataram, Nusa Tenggara Barat, Indonesia',
        endPlace:
            'C37V+Q4P, Jl. Unram, Gomong, Kec. Selaparang, Kota Mataram, Nusa Tenggara Barat, Indonesia',
        rideCost: 'Rp 4.600,00',
        idleCost: 'Rp 2.000,00',
        totalCost: 'Rp 6.600,00',
      ),
      HistoryItem(
        date: '6 April 2025',
        durationAndCost: '12 Days - Rp 50.000',
        distanceKm: '221 km',
        plate: 'DR 1211 XY',
        calories: '60.20 kcal',
        emission: '0.18 g',
        startTime: '15:05 PM',
        endTime: '15:20 PM',
        startPlace:
            'Jl. Catur Warga, Mataram, Nusa Tenggara Barat, Indonesia',
        endPlace:
            'Jl. Pelita, Mataram, Nusa Tenggara Barat, Indonesia',
        rideCost: 'Rp 3.800,00',
        idleCost: 'Rp 1.500,00',
        totalCost: 'Rp 5.300,00',
      ),
      HistoryItem(
        date: '20 January 2025',
        durationAndCost: '12 Days - Rp 50.000',
        distanceKm: '100 km',
        plate: 'DR 3211 AB',
        calories: '45.10 kcal',
        emission: '0.12 g',
        startTime: '10:15 AM',
        endTime: '10:28 AM',
        startPlace: 'Jl. Pejanggik, Mataram, Nusa Tenggara Barat',
        endPlace: 'Jl. Langko, Mataram, Nusa Tenggara Barat',
        rideCost: 'Rp 3.200,00',
        idleCost: 'Rp 1.200,00',
        totalCost: 'Rp 4.400,00',
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
                itemBuilder: (context, index) => _HistoryCard(
                  item: history[index],
                  onTap: () {
                    Navigator.of(context).push(
                      appRoute(DetailHistoryScreen(item: history[index])),
                    );
                  },
                ),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: history.length,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AppBottomNav(
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
            ),
            const SizedBox(height: 14),
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

class HistoryItem {
  const HistoryItem({
    required this.date,
    required this.durationAndCost,
    required this.distanceKm,
    required this.plate,
    required this.calories,
    required this.emission,
    required this.startTime,
    required this.endTime,
    required this.startPlace,
    required this.endPlace,
    required this.rideCost,
    required this.idleCost,
    required this.totalCost,
  });

  final String date;
  final String durationAndCost;
  final String distanceKm;
  final String plate;
  final String calories;
  final String emission;
  final String startTime;
  final String endTime;
  final String startPlace;
  final String endPlace;
  final String rideCost;
  final String idleCost;
  final String totalCost;
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, this.onTap});

  final HistoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2C7BFE);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
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
