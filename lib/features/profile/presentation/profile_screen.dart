import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../membership/presentation/membership_screen.dart';
import '../../recharge/presentation/recharge_screen.dart';
import '../../profile/presentation/document_screen.dart';
import '../../../core/navigation/app_route.dart';
import '../../../components/bottom_nav.dart';
import '../../../components/active_rental_logout_dialog.dart';
import '../../../components/logout_dialog.dart';
import '../../../components/app_motion.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    String? readText(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    String? formatDate(dynamic value) {
      final raw = readText(value);
      if (raw == null) return null;
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) return raw;
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = parsed.day.toString().padLeft(2, '0');
      final month = months[parsed.month - 1];
      return '$day $month ${parsed.year}';
    }

    final profile = SessionManager.instance.userProfile ?? {};
    final l10n = AppLocalizations.of(context);
    final walletBalance = SessionManager.instance.walletBalance ?? 0;
    final verificationStatus =
        SessionManager.instance.customerVerificationStatus;
    final username = readText(profile['username']);
    final fullName = readText(profile['full_name']);
    final email = readText(profile['email']);
    final phone = readText(profile['phone_number']);
    final gender = readText(profile['gender']);
    final idCard = readText(profile['id_number']);
    final birthday = formatDate(profile['birthday']);
    final height = readText(profile['height']);
    final weight = readText(profile['weight']);

    final displayName =
        username ?? SessionManager.instance.user?.name ?? 'User';

    final entries = <_ProfileEntry>[
      _ProfileEntry(
        l10n.verifyDocuments,
        _verificationLabel(l10n, verificationStatus),
        Icons.verified_user_outlined,
        showChevron: true,
        isVerifyDocs: true,
      ),
      if (displayName.isNotEmpty)
        _ProfileEntry(l10n.displayName, displayName, Icons.person_rounded),
      if (fullName != null)
        _ProfileEntry(l10n.name, fullName, Icons.badge_outlined),
      if (email != null) _ProfileEntry(l10n.email, email, Icons.email_outlined),
      if (phone != null)
        _ProfileEntry(l10n.phone, phone, Icons.phone_rounded),
      if (gender != null) _ProfileEntry(l10n.gender, gender, Icons.male_rounded),
      if (birthday != null)
        _ProfileEntry(l10n.birthday, birthday, Icons.cake_outlined),
      if (idCard != null)
        _ProfileEntry(l10n.idCard, idCard, Icons.credit_card),
      if (height != null)
        _ProfileEntry(l10n.height, '$height cm', Icons.height_rounded),
      if (weight != null)
        _ProfileEntry(l10n.weight, '$weight kg', Icons.monitor_weight_rounded),
      _ProfileEntry(
        l10n.logout,
        '',
        Icons.logout_rounded,
        isDestructive: true,
        isLogout: true,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            const _ProfileBackground(),
            Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  l10n.myProfile,
                  style: GoogleFonts.poppins(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProfileHeaderCard(
                    name: displayName,
                    email: email ?? '-',
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _WalletCard(
                    balance: walletBalance,
                    balanceLabel: l10n.balance,
                    topUpLabel: l10n.topUp,
                    packageLabel: l10n.packageLabel,
                    onTopUp: () {
                      Navigator.of(context).push(
                        appRoute(
                          const RechargeScreen(),
                          direction: AxisDirection.left,
                        ),
                      );
                    },
                    onPackage: () {
                      Navigator.of(context).push(
                        appRoute(
                          const MembershipScreen(),
                          direction: AxisDirection.left,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 14,
                          offset: Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE8EDF4)),
                    ),
                    child: ListView.separated(
                      itemCount: entries.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return _ProfileRow(
                          entry: entry,
                          onTap: () => _handleTap(context, entry),
                        );
                      },
                      separatorBuilder: (context, index) {
                        return const Divider(
                          height: 1,
                          color: Color(0xFFE7EBF3),
                        );
                      },
                    ),
                  ),
                ),
                AppBottomNav(
                  activeTab: BottomNavTab.profile,
                  onHistoryTap: () {
                    Navigator.of(context).pushReplacement(
                      appRoute(const HistoryScreen(),
                          direction: AxisDirection.right),
                    );
                  },
                  onDashboardTap: () {
                    Navigator.of(context).pushReplacement(
                      appRoute(const DashboardScreen(),
                          direction: AxisDirection.right),
                    );
                  },
                  onProfileTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _verificationLabel(AppLocalizations l10n, String status) {
    switch (status) {
      case 'verified':
        return l10n.verified;
      case 'under_review':
        return l10n.underReview;
      default:
        return l10n.notVerified;
    }
  }

}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.balance,
    required this.balanceLabel,
    required this.topUpLabel,
    required this.packageLabel,
    required this.onTopUp,
    required this.onPackage,
  });

  final int balance;
  final String balanceLabel;
  final String topUpLabel;
  final String packageLabel;
  final VoidCallback onTopUp;
  final VoidCallback onPackage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C7BFE),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE3EAF5)),
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C7BFE), Color(0xFF6CD2FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332C7BFE),
                  blurRadius: 10,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  balanceLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8B93A4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatRupiah(balance),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          _WalletAction(
            icon: Icons.account_balance_wallet_outlined,
            label: topUpLabel,
            onTap: onTopUp,
          ),
          const SizedBox(width: 6),
          _WalletAction(
            icon: Icons.local_offer_outlined,
            label: packageLabel,
            onTap: onPackage,
          ),
        ],
      ),
    );
  }

  String _formatRupiah(int value) {
    final digits = value.toString();
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
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF1FF), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCE6F4)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 16,
                color: const Color(0xFF2C7BFE),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C7BFE),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF4FF), Colors.white],
            stops: [0.0, 0.5],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        children: [
          const _Avatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.mail_rounded,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF2C7BFE), Color(0xFF6CD2FF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C7BFE),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 29,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            'https://api.dicebear.com/7.x/adventurer/png?seed=ajem&backgroundColor=b6e3f4',
            height: 52,
            width: 52,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ProfileEntry {
  _ProfileEntry(
    this.title,
    this.value,
    this.icon, {
    this.isDestructive = false,
    this.isLogout = false,
    this.showChevron = false,
    this.isVerifyDocs = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool isDestructive;
  final bool isLogout;
  final bool showChevron;
  final bool isVerifyDocs;
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.entry, required this.onTap});

  final _ProfileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const isEditable = false;
    final isDelete = entry.isDestructive;
    final accent = isDelete ? Colors.redAccent : const Color(0xFF2C7BFE);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        child: Row(
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: isDelete ? const Color(0x1AF44336) : const Color(0x1A2C7BFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, color: accent, size: 15),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isDelete ? FontWeight.w700 : FontWeight.w600,
                      color: isDelete ? Colors.redAccent : Colors.grey.shade800,
                    ),
                  ),
                  if (entry.value.isNotEmpty)
                    Text(
                      entry.value,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            if (isEditable || isDelete || entry.showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: isDelete
                    ? Colors.redAccent
                    : const Color(0xFF2C7BFE),
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showLogoutDialog(BuildContext context) {
  return showAppDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => LogoutDialog(
      onConfirm: () {
        SessionManager.instance.clear();
        Navigator.of(context)
          ..pop()
          ..pushAndRemoveUntil(
            appRoute(const LoginScreen(), direction: AxisDirection.right),
            (route) => false,
          );
      },
    ),
  );
}

Future<void> _showActiveRentalLogoutDialog(BuildContext context) {
  return showAppDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => const ActiveRentalLogoutDialog(),
  );
}

void _handleTap(BuildContext context, _ProfileEntry entry) {
  if (entry.isLogout) {
    if (SessionManager.instance.rental != null) {
      _showActiveRentalLogoutDialog(context);
    } else {
      _showLogoutDialog(context);
    }
  } else if (entry.isVerifyDocs) {
    Navigator.of(context).push(
      appRoute(
        const DocumentScreen(),
        direction: AxisDirection.left,
      ),
    );
  } else {
    // Non-editable fields are shown only; editable ones use header pencil.
  }
}

