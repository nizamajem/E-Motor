import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../history/presentation/history_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../rental/data/rental_service.dart';
import '../../../components/bottom_nav.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialRental});

  final RentalSession? initialRental;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isActive = false;
  bool _isToggling = false;
  RideStatus? _status;
  RentalSession? _rental;
  final RentalService _rentalService = RentalService();
  StreamSubscription<RideStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _rental = widget.initialRental ?? SessionManager.instance.rental;
    _isActive = _rental?.motorOn ?? false;
    _startStatusListener();
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    super.dispose();
  }

  void _startStatusListener() {
    if (SessionManager.instance.token == null) return;
    _statusSub = _rentalService.statusStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _status = data;
          _isActive = data.motorOn;
        });
      },
      onError: (_) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final dimmed = !_isActive;
    final rental = _rental;
    final status = _status;
    final riderName = SessionManager.instance.user?.name ?? 'Rider';
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                          children: [
                            const TextSpan(text: 'Welcome '),
                            TextSpan(
                              text: riderName,
                              style: const TextStyle(color: Color(0xFF2C7BFE)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A seamless electric mobility powered by real-time technology',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _ScooterHero(isActive: _isActive),
                        const SizedBox(height: 8),
                        _PlateBadge(
                          isActive: _isActive,
                          plate: rental?.plate ?? 'N/A',
                          battery: status?.batteryPercent ?? rental?.batteryPercent,
                        ),
                        const SizedBox(height: 10),
                        _GridCards(
                          status: status,
                          rental: rental,
                          isActive: _isActive,
                          dimmed: dimmed,
                          isBusy: _isToggling,
                          onToggle: _handleToggle,
                        ),
                        const SizedBox(height: 10),
                        _LockSlider(
                          isActive: _isActive,
                          disabled: _isToggling,
                          onToggle: _handleToggle,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                AppBottomNav(
                  activeTab: BottomNavTab.dashboard,
                  onHistoryTap: () {
                    Navigator.of(context).push(
                      appRoute(const HistoryScreen(),
                          direction: AxisDirection.left),
                    );
                  },
                  onDashboardTap: () {},
                  onProfileTap: () {
                    Navigator.of(context).push(
                      appRoute(const ProfileScreen(),
                          direction: AxisDirection.left),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleToggle(bool value) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    try {
      final status = await _rentalService.toggleMotor(value);
      if (!mounted) return;
      setState(() {
        _status = status;
        _isActive = status.motorOn;
      });
    } catch (e) {
      _showSnack('Gagal mengirim perintah: $e');
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEFF4FF), Colors.white],
            stops: [0.0, 0.35],
          ),
        ),
      ),
    );
  }
}

class _ScooterHero extends StatelessWidget {
  const _ScooterHero({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 38,
            child: Container(
              width: 174,
              height: 174,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE7F1FF),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C7BFE)
                        .withValues(alpha: isActive ? 0.16 : 0.08),
                    blurRadius: 26,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Image.asset(
              'assets/images/dashboard.png',
              height: 135,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlateBadge extends StatelessWidget {
  const _PlateBadge(
      {required this.isActive, required this.plate, this.battery});

  final bool isActive;
  final String plate;
  final double? battery;

  @override
  Widget build(BuildContext context) {
    final muted = !isActive;
    final batteryText =
        battery != null ? 'Battery ${(battery!).toStringAsFixed(0)}%' : 'Locked';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: muted ? 0.04 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              Icons.eco_rounded,
              color: muted ? Colors.grey.shade500 : const Color(0xFF2C7BFE),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plate,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                batteryText,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: muted ? Colors.grey.shade200 : const Color(0x1A2C7BFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isActive ? 'Active' : 'Locked',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: muted ? Colors.grey.shade600 : const Color(0xFF2C7BFE),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridCards extends StatelessWidget {
  const _GridCards({
    required this.isActive,
    required this.dimmed,
    required this.onToggle,
    required this.isBusy,
    this.status,
    this.rental,
  });

  final bool isActive;
  final bool dimmed;
  final bool isBusy;
  final ValueChanged<bool> onToggle;
  final RideStatus? status;
  final RentalSession? rental;

  @override
  Widget build(BuildContext context) {
    final carbon = status?.carbonReduction ?? 0;
    final range = status?.rangeKm ?? rental?.rangeKm ?? 0;
    final rentalTime = status?.rentalMinutes ?? 0;
    final ping = status?.pingQuality ?? '---';
    final label = GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final value = GoogleFonts.poppins(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Carbon Reduction',
                  value: carbon == 0 ? '--' : carbon.toStringAsFixed(2),
                  icon: Icons.eco_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  dimmed: dimmed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: 'Ping',
                  value: ping,
                  icon: Icons.wifi_tethering_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  rightIcon: true,
                  outlined: true,
                  dimmed: false, // Ping stays vivid
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Range',
                  value: range == 0 ? '--' : '${range.toStringAsFixed(0)} km',
                  icon: Icons.location_on_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  dimmed: dimmed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: 'Rental Time',
                  value: rentalTime == 0 ? '--' : '$rentalTime min',
                  icon: Icons.timer_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  dimmed: dimmed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  label: 'On',
                  icon: Icons.flash_on_rounded,
                  color: const Color(0xFF2C7BFE),
                  active: isActive,
                  dimmed: dimmed,
                  onTap: isBusy ? null : () => onToggle(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionTile(
                  label: 'Off',
                  icon: Icons.power_settings_new_rounded,
                  color: const Color(0xFF2C7BFE),
                  active: !isActive,
                  dimmed: dimmed,
                  onTap: isBusy ? null : () => onToggle(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.labelStyle,
    required this.valueStyle,
    this.rightIcon = false,
    this.outlined = false,
    this.dimmed = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool rightIcon;
  final bool outlined;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF2C7BFE);
    final bg = outlined ? Colors.white : baseColor;
    final border = outlined ? Border.all(color: baseColor, width: 1.3) : null;
    final fgColor = outlined ? baseColor : Colors.white;
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 68,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: const [
              BoxShadow(
                color: Color(0x142C7BFE),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: rightIcon
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              Icon(icon, color: fgColor, size: 20),
              const SizedBox(width: 8),
              if (!rightIcon)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: labelStyle.copyWith(color: fgColor)),
                    if (value.isNotEmpty)
                      Text(value, style: valueStyle.copyWith(color: fgColor)),
                  ],
                ),
              if (rightIcon)
                Text(
                  label,
                  style: labelStyle.copyWith(color: fgColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.dimmed,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? color : Colors.white;
    final fg =
        active ? Colors.white : color.withValues(alpha: dimmed ? 0.45 : 0.8);
    final border =
        active ? null : Border.all(color: color.withValues(alpha: 0.25));
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: border,
            boxShadow: const [
              BoxShadow(
                color: Color(0x142C7BFE),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: fg, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ],
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 220),
                opacity: active ? 1 : 0.25,
                child: Icon(
                  active ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockSlider extends StatefulWidget {
  const _LockSlider({
    required this.isActive,
    required this.onToggle,
    this.disabled = false,
  });

  final bool isActive;
  final bool disabled;
  final ValueChanged<bool> onToggle;

  @override
  State<_LockSlider> createState() => _LockSliderState();
}

class _LockSliderState extends State<_LockSlider> {
  double _position = -1.0; // -1 to 1

  @override
  void didUpdateWidget(covariant _LockSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _position = widget.isActive ? 1.0 : -1.0;
  }

  @override
  Widget build(BuildContext context) {
    // Lively palette: blue when unlocked, orange when locked.
    const unlockColor = Color(0xFF2C7BFE);
    const lockColor = Color(0xFFFFA45B);
    final t = ((_position + 1) / 2).clamp(0.0, 1.0);
    final startColor = Color.lerp(lockColor, unlockColor, t)!;
    final endColor =
        Color.lerp(lockColor, unlockColor, (t + 0.25).clamp(0.0, 1.0))!;
    final knobColor = Color.lerp(lockColor, Colors.black, t * 0.22)!;
    final textColor = Color.lerp(
      Colors.grey.shade700,
      Colors.white,
      (t * 1.2).clamp(0.0, 1.0),
    )!;
    final isLocked = !widget.isActive;
    final statusIcon = isLocked ? Icons.lock_rounded : Icons.lock_open_rounded;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onHorizontalDragUpdate: widget.disabled
            ? null
            : (details) {
                setState(() {
                  _position =
                      (_position + details.delta.dx / 120).clamp(-1.0, 1.0);
                });
              },
        onHorizontalDragEnd: widget.disabled
            ? null
            : (_) {
                final shouldActivate = _position > 0;
                widget.onToggle(shouldActivate);
                setState(() {
                  _position = shouldActivate ? 1.0 : -1.0;
                });
                HapticFeedback.lightImpact();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [startColor, endColor],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A2C7BFE),
                blurRadius: 12,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 18, color: textColor),
                    const SizedBox(width: 6),
                    Text(
                      widget.isActive ? 'Slide to Lock' : 'Slide to Unlock',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: Alignment((_position).clamp(-1, 1), 0),
                child: Transform.rotate(
                  angle: widget.isActive ? math.pi : 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [knobColor, Colors.black],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 10,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.vpn_key_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
