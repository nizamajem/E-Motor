import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'detail_history_screen.dart';
import '../../payment/presentation/payment_screen.dart';
import '../../../components/bottom_nav.dart';
import '../../../components/list_ui.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';
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
  late Future<List<MembershipHistoryEntry>> _membershipFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = HistoryService().fetchHistory();
    final customerId = SessionManager.instance.customerId ?? '';
    _membershipFuture =
        HistoryService().fetchMembershipHistoryByCustomer(customerId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
                Text(
                  l10n.membershipHistoryTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Column(
                children: [
                  FutureBuilder<List<HistoryEntry>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      final stats = _buildStats(snapshot.data ?? [], l10n);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _StatsRow(items: stats),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder<List<MembershipHistoryEntry>>(
                      future: _membershipFuture,
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 6,
                          ),
                          itemBuilder: (context, index) {
                            final entry = _sortMemberships(items)[index];
                            return _MembershipHistoryCard(
                              item: entry,
                              onTap: () {
                                Navigator.of(context).push(
                                  appRoute(
                                    MembershipHistoryDetailScreen(entry: entry),
                                  ),
                                );
                              },
                              onPay:
                                  entry.status.toUpperCase().contains('PENDING')
                                      ? () {
                                          final token = SessionManager.instance
                                                  .getPendingSnapToken(entry.id) ??
                                              '';
                                          if (token.isEmpty) {
                                            return;
                                          }
                                          Navigator.of(context).push(
                                            appRoute(
                                              PaymentScreen(
                                                amount: entry.price.round(),
                                                walletBalance:
                                                    SessionManager.instance
                                                            .walletBalance ??
                                                        0,
                                                flow: PaymentFlow.membership,
                                                membershipId: entry.membershipId,
                                                snapToken: token,
                                                membershipHistoryId: entry.id,
                                                lockMidtrans: true,
                                              ),
                                            ),
                                          );
                                        }
                                      : null,
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemCount: items.length,
                        );
                },
              ),
            ),
                ],
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  List<MembershipHistoryEntry> _sortMemberships(
    List<MembershipHistoryEntry> items,
  ) {
    final list = List<MembershipHistoryEntry>.from(items);
    int rank(MembershipHistoryEntry entry) {
      final status = entry.status.toUpperCase();
      if (status.contains('ACTIVE')) return 0;
      if (status.contains('PENDING') || status.contains('QUEUE')) return 1;
      if (entry.expiredAt == null) return 1;
      return 2;
    }

    list.sort((a, b) {
      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  List<_StatItem> _buildStats(
    List<HistoryEntry> entries,
    AppLocalizations l10n,
  ) {
    double totalKm = 0;
    double totalEmission = 0;
    final days = <String>{};
    for (final entry in entries) {
      totalKm += entry.distanceKmValue;
      totalEmission += entry.carbonEmissionsValue;
      final dt = entry.startDate;
      if (dt != null) {
        days.add('${dt.year}-${dt.month}-${dt.day}');
      } else if (entry.date.isNotEmpty) {
        days.add(entry.date);
      }
    }
    return [
      _StatItem(
        label: l10n.statsMileage,
        value: '${totalKm.toStringAsFixed(2)} km',
        icon: Icons.route_rounded,
      ),
      _StatItem(
        label: l10n.statsActiveDays,
        value: '${days.length} ${l10n.days}',
        icon: Icons.local_fire_department_rounded,
      ),
      _StatItem(
        label: l10n.statsReducedEmission,
        value: _formatEmission(totalEmission),
        icon: Icons.eco_rounded,
      ),
    ];
  }

  String _formatEmission(double value) {
    if (value >= 1000) {
      final kg = value / 1000;
      return '${kg.toStringAsFixed(2)} kg';
    }
    return '${value.toStringAsFixed(2)} g';
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return ListCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: const Color(0xFF2C7BFE),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A2C7BFE),
          blurRadius: 12,
          offset: Offset(0, 8),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Expanded(
                  child: SummaryStat(
                    label: items[i].label,
                    value: items[i].value,
                    icon: items[i].icon,
                    alignCenter: true,
                  ),
                ),
                if (i != items.length - 1)
                  Container(
                    width: 1,
                    height: 36,
                    color: const Color(0xFFE6E9F2),
                  ),
              ],
            ],
          ),
        ],
      ),
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
    required this.id,
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

  final String id;
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
    final l10n = AppLocalizations.of(context);
    return ListCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 16,
                color: Color(0xFF8B93A4),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.date,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.totalCost,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C7BFE),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MetaItem(
                icon: Icons.access_time_rounded,
                label: l10n.durationLabel,
                value: item.rentalDuration,
              ),
              const SizedBox(width: 10),
              _MetaItem(
                icon: Icons.route_rounded,
                label: l10n.distanceLabel,
                value: item.distanceKm,
              ),
              const SizedBox(width: 10),
              _MetaItem(
                icon: Icons.eco_rounded,
                label: l10n.emissionLabel,
                value: item.emission,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/dashboard.png',
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.plate,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B93A4),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFB4BAC6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MembershipHistoryDetailScreen extends StatefulWidget {
  const MembershipHistoryDetailScreen({super.key, required this.entry});

  final MembershipHistoryEntry entry;

  @override
  State<MembershipHistoryDetailScreen> createState() =>
      _MembershipHistoryDetailScreenState();
}

class _MembershipHistoryDetailScreenState
    extends State<MembershipHistoryDetailScreen> {
  late Future<List<HistoryEntry>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _ridesFuture = HistoryService()
        .fetchCyclingByMembership(widget.entry.membershipId);
  }

  List<HistoryItem> _mapItems(List<HistoryEntry> entries) {
    return entries
        .map(
          (entry) => HistoryItem(
            id: entry.id,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF111827),
                  ),
                  Expanded(
                    child: Text(
                      l10n.membershipHistoryDetail,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _MembershipHistoryCard(
                item: widget.entry,
                dense: true,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<HistoryEntry>>(
                future: _ridesFuture,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    itemBuilder: (context, index) => _HistoryCard(
                      item: items[index],
                      onTap: () {
                        Navigator.of(context).push(
                          appRoute(DetailHistoryScreen(item: items[index])),
                        );
                      },
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemCount: items.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF8B93A4)),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8B93A4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipHistoryCard extends StatelessWidget {
  const _MembershipHistoryCard({
    required this.item,
    this.onTap,
    this.dense = false,
    this.onPay,
  });

  final MembershipHistoryEntry item;
  final VoidCallback? onTap;
  final bool dense;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = item.status.toUpperCase();
    final isActive = status.contains('ACTIVE');
    final isPending = status.contains('PENDING') ||
        status.contains('QUEUE') ||
        item.expiredAt == null;
    final statusLabel = isActive
        ? l10n.membershipStatusActive
        : isPending
            ? l10n.membershipStatusPending
            : l10n.membershipStatusExpired;
    final statusColor = isActive
        ? const Color(0xFF16A34A)
        : isPending
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    String formatDate(DateTime? date) {
      if (date == null) return '-';
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    }

    String formatRemaining(DateTime? createdAt) {
      if (createdAt == null) return '--';
      final expires = createdAt.add(const Duration(hours: 20));
      final diff = expires.difference(DateTime.now());
      if (diff.isNegative) return '00:00';
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    String formatRupiah(double value) {
      final intValue = value.round();
      final digits = intValue.toString();
      final buffer = StringBuffer();
      for (var i = 0; i < digits.length; i++) {
        final idx = digits.length - i;
        buffer.write(digits[i]);
        if (idx > 1 && idx % 3 == 1) {
          buffer.write('.');
        }
      }
      return 'Rp ${buffer.toString()}';
    }

    final padding = dense
        ? const EdgeInsets.fromLTRB(14, 12, 14, 12)
        : const EdgeInsets.fromLTRB(16, 14, 16, 14);

    return ListCard(
      onTap: onTap,
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    fontSize: dense ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MembershipMeta(
                label: l10n.membershipValidUntil,
                value: formatDate(item.expiredAt),
              ),
              const SizedBox(width: 10),
              _MembershipMeta(
                label: isPending ? l10n.payBefore : l10n.membershipPurchased,
                value: isPending
                    ? formatRemaining(item.createdAt)
                    : formatDate(item.createdAt),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  formatRupiah(item.price),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2C7BFE),
                  ),
                ),
              ),
              const Spacer(),
              if (onPay != null && isPending)
                SizedBox(
                  height: 34,
                  child: ElevatedButton(
                    onPressed: onPay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C7BFE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      l10n.payMembership,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (onPay != null && isPending) const SizedBox(width: 8),
              if (onTap != null)
                Text(
                  l10n.viewRides,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C7BFE),
                  ),
                ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFFB4BAC6),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MembershipMeta extends StatelessWidget {
  const _MembershipMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF8B93A4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
