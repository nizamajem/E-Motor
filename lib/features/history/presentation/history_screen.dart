import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'detail_history_screen.dart';
import '../../../components/bottom_nav.dart';
import '../../../core/navigation/app_route.dart';
import '../data/history_service.dart';
import '../data/history_models.dart';
import '../../../core/localization/app_localizations.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryEntry>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService().fetchHistory();
  }

  List<HistoryItem> _mapItems(List<HistoryEntry> entries) {
    return entries
        .map(
          (entry) => HistoryItem(
            date: entry.date,
            durationAndCost: entry.durationAndCost,
            distanceKm: entry.distanceKm,
            plate: entry.plate,
            rentalDuration: entry.rentalDuration,
            emission: entry.emission,
            startTime: entry.startTime,
            endTime: entry.endTime,
            startPlace: entry.startPlace,
            endPlace: entry.endPlace,
            rideCost: entry.rideCost,
            idleCost: entry.idleCost,
            totalCost: entry.totalCost,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = [
      _StatItem(
        label: l10n.statsMileage,
        value: '40,22 km',
        icon: Icons.route_rounded,
      ),
      _StatItem(
        label: l10n.statsActiveDays,
        value: '20 ${l10n.days}',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatItem(
        label: l10n.statsReducedEmission,
        value: '5,19',
        icon: Icons.eco_rounded,
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
                  l10n.myHistory,
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
              child: FutureBuilder<List<HistoryEntry>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        l10n.historyLoadFailed,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  final items = _mapItems(snapshot.data ?? []);
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.historyEmpty,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    itemBuilder: (context, index) => _HistoryCard(
                      item: items[index],
                      onTap: () {
                        Navigator.of(context).push(
                          appRoute(DetailHistoryScreen(item: items[index])),
                        );
                      },
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: items.length,
                  );
                },
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
    required this.rentalDuration,
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
  final String rentalDuration;
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
