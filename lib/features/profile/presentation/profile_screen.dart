import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';
import '../../history/presentation/history_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../../core/navigation/app_route.dart';
import '../../../components/bottom_nav.dart';
import '../../../components/logout_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'Ajem';
  String _fullName = 'Muhamad Nizam Azmi';
  String _email = 'ajem@gmail.com';

  @override
  Widget build(BuildContext context) {
    final entries = [
      _ProfileEntry('Display Name', _displayName, Icons.person_rounded),
      _ProfileEntry('Name', _fullName, Icons.badge_outlined),
      _ProfileEntry('E-Mail', _email, Icons.email_outlined),
      _ProfileEntry('ID card Number', '537827638298748', Icons.credit_card),
      _ProfileEntry('Gender', 'Laki-laki', Icons.male_rounded),
      _ProfileEntry('Age', '22', Icons.cake_outlined),
      _ProfileEntry('Phone Number', '087325239467372', Icons.phone_rounded),
      _ProfileEntry('Citizenship', 'Indonesia', Icons.flag_circle_rounded),
      _ProfileEntry('Log Out', '', Icons.logout_rounded, isDestructive: true),
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
                  'My Profile',
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
                    name: _displayName,
                    email: _email,
                    onEdit: () => _openEditSheet(context),
                  ),
                ),
                const SizedBox(height: 8),
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
                    child: Column(
                      children: [
                        for (int i = 0; i < entries.length; i++) ...[
                          _ProfileRow(
                            entry: entries[i],
                            onTap: () => _handleTap(context, entries[i]),
                          ),
                          if (i != entries.length - 1)
                            const Divider(
                                height: 1, color: Color(0xFFE7EBF3)),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: AppBottomNav(
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
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _applyEdits({
    required String display,
    required String full,
    required String email,
  }) {
    setState(() {
      _displayName = display;
      _fullName = full;
      _email = email;
    });
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final displayController = TextEditingController(text: _displayName);
    final fullController = TextEditingController(text: _fullName);
    final emailController = TextEditingController(text: _email);
    const accent = Color(0xFF2C7BFE);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            left: 12,
            right: 12,
            top: 0,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Edit Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _EditField(
                  label: 'Display Name',
                  controller: displayController,
                  icon: Icons.person_rounded,
                  accent: accent,
                ),
                const SizedBox(height: 10),
                _EditField(
                  label: 'Full Name',
                  controller: fullController,
                  icon: Icons.badge_outlined,
                  accent: accent,
                ),
                const SizedBox(height: 10),
                _EditField(
                  label: 'E-Mail',
                  controller: emailController,
                  icon: Icons.email_outlined,
                  accent: accent,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fields like ID, gender, age, phone only editable by admin.',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: Color(0xFFE2E7F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final display = displayController.text.trim();
                          final full = fullController.text.trim();
                          final email = emailController.text.trim();
                          if (display.isEmpty ||
                              full.isEmpty ||
                              email.isEmpty) {
                            Navigator.of(ctx).pop();
                            return;
                          }
                          _applyEdits(
                            display: display,
                            full: full,
                            email: email,
                          );
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
  const _ProfileHeaderCard(
      {required this.name, required this.email, required this.onEdit});

  final String name;
  final String email;
  final VoidCallback onEdit;

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
          GestureDetector(
            onTap: onEdit,
            child: Icon(Icons.edit_outlined,
                size: 16, color: Colors.grey.shade500),
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
  _ProfileEntry(this.title, this.value, this.icon, {this.isDestructive = false});

  final String title;
  final String value;
  final IconData icon;
  final bool isDestructive;

  bool get isLogout => isDestructive && title.toLowerCase().contains('log out');
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.entry, required this.onTap});

  final _ProfileEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEditable = entry.title == 'Display Name' ||
        entry.title == 'Name' ||
        entry.title == 'E-Mail';
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
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDelete
                  ? Colors.redAccent
                  : isEditable
                      ? const Color(0xFF2C7BFE)
                      : const Color(0xFFBAC2D0),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showLogoutDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => LogoutDialog(
      onConfirm: () {
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

void _handleTap(BuildContext context, _ProfileEntry entry) {
  if (entry.isLogout) {
    _showLogoutDialog(context);
  } else {
    // Non-editable fields are shown only; editable ones use header pencil.
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.accent,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color accent;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5EAF2)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: label,
                    border: InputBorder.none,
                    isDense: true,
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
