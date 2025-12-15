import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../dashboard/presentation/dashboard_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = [
      _ProfileEntry('Name', 'Muhamad Nizam Azmi'),
      _ProfileEntry('ID card Number', '537827638298748'),
      _ProfileEntry('Gender', 'Laki-laki'),
      _ProfileEntry('Age', '22'),
      _ProfileEntry('Phone Number', '087325239467372'),
      _ProfileEntry('E-Mail', 'ajem@gmail.com'),
      _ProfileEntry('Citizenship', 'Indonesia'),
      _ProfileEntry('Log Out', '', isDestructive: true),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'My Profile',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            _Avatar(),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: entries.length,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE7EBF3)),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isDelete = entry.isDestructive;
                  return InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.title,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight:
                                  isDelete ? FontWeight.w700 : FontWeight.w500,
                              color: isDelete
                                  ? Colors.redAccent
                                  : Colors.grey.shade800,
                            ),
                          ),
                          Row(
                            children: [
                              if (entry.value.isNotEmpty)
                                Text(
                                  entry.value,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded,
                                  size: 18,
                                  color: isDelete
                                      ? Colors.redAccent
                                      : const Color(0xFFBAC2D0)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            const _BottomNavProfile(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
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
        radius: 44,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            'https://api.dicebear.com/7.x/adventurer/png?seed=ajem&backgroundColor=b6e3f4',
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _ProfileEntry {
  _ProfileEntry(this.title, this.value, {this.isDestructive = false});

  final String title;
  final String value;
  final bool isDestructive;
}

class _BottomNavProfile extends StatelessWidget {
  const _BottomNavProfile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.history_rounded, color: Colors.grey.shade400),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                _slideRoute(const DashboardScreen(),
                    direction: AxisDirection.right),
              );
            },
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.electric_moped_rounded,
                  color: Colors.grey.shade500, size: 22),
            ),
          ),
          Container(
            height: 50,
            width: 50,
            decoration: const BoxDecoration(
              color: Color(0xFF2C7BFE),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.person_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}

PageRouteBuilder _slideRoute(Widget page,
    {AxisDirection direction = AxisDirection.left}) {
  Offset begin;
  switch (direction) {
    case AxisDirection.right:
      begin = const Offset(-1, 0);
      break;
    case AxisDirection.up:
      begin = const Offset(0, 1);
      break;
    case AxisDirection.down:
      begin = const Offset(0, -1);
      break;
    case AxisDirection.left:
    default:
      begin = const Offset(1, 0);
  }
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slideTween = Tween(begin: begin, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      final fadeTween = Tween<double>(begin: 0.7, end: 1)
          .chain(CurveTween(curve: Curves.easeOut));
      final scaleTween = Tween<double>(begin: 0.96, end: 1)
          .chain(CurveTween(curve: Curves.easeOut));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        ),
      );
    },
  );
}
