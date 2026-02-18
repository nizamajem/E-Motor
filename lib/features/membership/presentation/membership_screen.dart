import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';
import '../../../components/app_motion.dart';
import '../data/membership_models.dart';
import '../data/membership_service.dart';
import '../../membership/data/membership_check_service.dart';
import '../../payment/presentation/payment_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<List<MembershipPackage>> _membershipsFuture;
  Timer? _ticker;
  bool _activeFromCheck = false;

  @override
  void initState() {
    super.initState();
    _membershipsFuture = MembershipService().fetchMembershipsForEmotor();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _loadActiveMembership();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadActiveMembership() async {
    final customerId = SessionManager.instance.customerId ?? '';
    if (customerId.isEmpty) return;
    try {
      final active = await MembershipCheckService()
          .checkMembership(customerId: customerId);
      if (!mounted || active == null) return;
      SessionManager.instance.setHasActivePackage(active);
      setState(() {
        _activeFromCheck = active;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final walletBalance = SessionManager.instance.walletBalance ?? 10000;
    final localeCode = Localizations.localeOf(context).languageCode;
    final activeName =
        SessionManager.instance.membershipName ?? l10n.packageDefault;
    final activeExpiresAt = SessionManager.instance.membershipExpiresAt;
    String? activeEmotor = SessionManager.instance.dashboardEmotorNumber;
    if (activeEmotor == null || activeEmotor.isEmpty) {
      final emotorMap = SessionManager.instance.userProfile?['emotor'];
      if (emotorMap is Map<String, dynamic>) {
        activeEmotor = emotorMap['vehicle_number']?.toString();
      }
    }
    final remainingSeconds = SessionManager.instance.getRemainingSecondsNow();
    final hasActive = (activeExpiresAt != null &&
            activeExpiresAt.isAfter(DateTime.now())) ||
        remainingSeconds > 0 ||
        _activeFromCheck ||
        SessionManager.instance.hasActivePackage;
    String durationHours(int hours) {
      if (hours >= 24) {
        final days = hours ~/ 24;
        final remaining = hours % 24;
        if (remaining == 0) {
          return '$days ${l10n.dayLabel}';
        }
        return '$days ${l10n.dayLabel} $remaining ${l10n.hours}';
      }
      return '$hours ${l10n.hours}';
    }

    String validForHours(int hours) {
      final label = durationHours(hours);
      return '${l10n.validFor} $label';
    }
    String minBalance(String amount) => '${l10n.minBalancePrefix} $amount';
    String formatCountdown(int seconds) {
      if (seconds <= 0) return '00:00:00';
      final h = seconds ~/ 3600;
      final m = (seconds % 3600) ~/ 60;
      final s = seconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    String formatDateTime(DateTime dt) {
      const monthsEn = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      const monthsId = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
      ];
      final months = localeCode == 'id' ? monthsId : monthsEn;
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month ${dt.year} $hour:$minute';
    }

    int computeRemainingSeconds() {
      if (remainingSeconds > 0) return remainingSeconds;
      if (activeExpiresAt == null) return 0;
      final diff = activeExpiresAt.difference(DateTime.now()).inSeconds;
      return diff > 0 ? diff : 0;
    }

    DateTime? resolveExpiresAt() {
      if (activeExpiresAt != null) return activeExpiresAt;
      if (remainingSeconds > 0) {
        return DateTime.now().add(Duration(seconds: remainingSeconds));
      }
      return null;
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                      l10n.membershipTitle,
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
            Expanded(
              child: FutureBuilder<List<MembershipPackage>>(
                future: _membershipsFuture,
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
                          color: const Color(0xFF8B93A4),
                        ),
                      ),
                    );
                  }
                  final memberships = snapshot.data ?? [];
                  if (memberships.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.historyEmpty,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B93A4),
                        ),
                      ),
                    );
                  }

                  final packages = memberships.map((m) {
                    final hours = m.durationHours;
                    return _Package(
                      id: m.id,
                      label: m.name.isNotEmpty ? m.name : l10n.packageDefault,
                      duration: durationHours(hours),
                      price: _formatRupiah(m.price),
                      validity: validForHours(hours),
                      minBalance: minBalance(_formatRupiah(m.minBalance)),
                    );
                  }).toList();
                  final resolvedExpiresAt = resolveExpiresAt();

                      return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (!hasActive) ...[
                          Text(
                            l10n.startRideTitle,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E88E5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n.membershipSubtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9AA0AA),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                        if (hasActive) ...[
                          _ActiveMembershipCard(
                            packageName: activeName,
                            validUntil: resolvedExpiresAt == null
                                ? '--'
                                : formatDateTime(resolvedExpiresAt),
                            countdown: formatCountdown(computeRemainingSeconds()),
                            code: activeEmotor?.toString().trim() ?? '',
                            note: l10n.overtimeNotice,
                          ),
                          const SizedBox(height: 16),
                        ],
                        ...packages.map((pkg) => _PackageCard(
                            package: pkg,
                            onBuy: () {
                              final minBalance =
                                  _parseRupiah(pkg.minBalance);
                              if (walletBalance < minBalance) {
                                _showInsufficientDialog(context);
                                return;
                              }
                              _showConfirmDialog(
                                context,
                                pkg,
                                walletBalance,
                              );
                            },
                          )),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRupiah(num value) {
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

  void _showConfirmDialog(
    BuildContext context,
    _Package package,
    int walletBalance,
  ) {
    final l10n = AppLocalizations.of(context);
    _showPremiumDialog(
      context: context,
      childBuilder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        l10n.confirmPackageTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          iconSize: 18,
                          color: const Color(0xFF111827),
                          splashRadius: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.confirmPackageBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B8190),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F3F6),
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.of(context).push(
                              appRoute(
                                PaymentScreen(
                                  amount: _parseRupiah(package.price),
                                  walletBalance: walletBalance,
                                  flow: PaymentFlow.membership,
                                  membershipId: package.id,
                                ),
                                direction: AxisDirection.left,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C7BFE),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.buy,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInsufficientDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _showPremiumDialog(
      context: context,
      childBuilder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        l10n.insufficientTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(
                        height: 28,
                        width: 28,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                          iconSize: 18,
                          color: const Color(0xFF111827),
                          splashRadius: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.insufficientBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B8190),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F3F6),
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C7BFE),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            l10n.topUp,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPremiumDialog({
    required BuildContext context,
    required WidgetBuilder childBuilder,
  }) {
    showAppDialog<void>(
      context: context,
      builder: childBuilder,
    );
  }

  int _parseRupiah(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.onBuy,
  });

  final _Package package;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context).packageLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C7BFE),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                package.validity,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: const Color(0xFFE9EEF5)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package.label,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      package.price,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E88E5),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '*${package.minBalance}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE53935),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: onBuy,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).buy,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Package {
  const _Package({
    required this.id,
    required this.label,
    required this.duration,
    required this.price,
    required this.validity,
    required this.minBalance,
  });

  final String id;
  final String label;
  final String duration;
  final String price;
  final String validity;
  final String minBalance;
}

class _ActiveMembershipCard extends StatelessWidget {
  const _ActiveMembershipCard({
    required this.packageName,
    required this.validUntil,
    required this.countdown,
    required this.code,
    required this.note,
  });

  final String packageName;
  final String validUntil;
  final String countdown;
  final String code;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF35A7E6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  packageName,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                validUntil,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppLocalizations.of(context).timeLeft}:',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            countdown,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          if (code.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  code,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          if (code.isNotEmpty) const SizedBox(height: 8),
          Text(
            note,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
