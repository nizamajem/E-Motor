import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../history/presentation/history_screen.dart';
import '../../history/data/history_service.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../rental/data/rental_service.dart';
import '../../history/presentation/detail_history_screen.dart';
import '../../../components/bottom_nav.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialRental});

  final RentalSession? initialRental;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isActive = false;
  bool _isToggling = false;
  bool _isEnding = false;
  bool _isStartingRide = false;
  bool _hasRental = false;
  bool _requireStart = false;
  int _elapsedSeconds = 0;
  RideStatus? _status;
  RentalSession? _rental;
  final RentalService _rentalService = RentalService();
  StreamSubscription<RideStatus>? _statusSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _rental = widget.initialRental ?? SessionManager.instance.rental;
    _isActive = _rental?.motorOn ?? false;
    _hasRental = (_rental?.rideHistoryId ?? '').isNotEmpty;
    _requireStart = !_hasRental;
    _elapsedSeconds = _hasRental ? 0 : 0;
    _ensureTimer();
    if (_hasRental) {
      _startStatusListener();
    }
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startStatusListener() {
    if (SessionManager.instance.token == null) return;
    _statusSub = _rentalService.statusStream().listen(
      (data) {
        if (!mounted) return;
        setState(() {
          _status = data;
          if (data.hasMotorState) {
            _isActive = data.motorOn;
          }
          _hasRental = true;
          if (data.rideSeconds > 0) {
            _elapsedSeconds = data.rideSeconds;
          }
        });
        if (_hasRental) {
          _ensureTimer();
        }
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
    final l10n = AppLocalizations.of(context);
    final emotorFromProfile = SessionManager.instance.emotorProfile;
    final emotorFromUser = SessionManager.instance.userProfile?['emotor'];
    final emotorPlate = emotorFromProfile?['vehicle_number']?.toString().trim() ??
        emotorFromProfile?['vehicleNumber']?.toString().trim() ??
        (emotorFromUser is Map<String, dynamic>
            ? (emotorFromUser['vehicle_number']?.toString().trim() ??
                emotorFromUser['vehicleNumber']?.toString().trim())
            : null);
    final emotorName = emotorFromProfile?['modelBikeId_model']?.toString().trim() ??
        (emotorFromUser is Map<String, dynamic>
            ? emotorFromUser['modelBikeId_model']?.toString().trim()
            : null);
    final emotorBattery = emotorFromProfile?['power']?.toString().trim() ??
        (emotorFromUser is Map<String, dynamic>
            ? emotorFromUser['power']?.toString().trim()
            : null);
    final emotorFallback = (emotorPlate != null && emotorPlate.isNotEmpty)
        ? emotorPlate
        : (emotorName != null && emotorName.isNotEmpty)
            ? emotorName
            : 'N/A';
    final batteryFallback = double.tryParse(emotorBattery ?? '');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: AbsorbPointer(
                    absorbing: _requireStart,
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
                            TextSpan(text: l10n.welcome),
                            TextSpan(
                              text: riderName,
                                      style: const TextStyle(color: Color(0xFF2C7BFE)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                              l10n.tagline,
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
                                  plate: status?.plate ??
                                      rental?.plate ??
                                      emotorFallback,
                                  battery: status?.batteryPercent ??
                                      rental?.batteryPercent ??
                                      batteryFallback,
                                ),
                                const SizedBox(height: 10),
                                _GridCards(
                                  status: status,
                                  rental: rental,
                                  isActive: _isActive,
                                  dimmed: dimmed,
                                  isBusy: _isToggling,
                                  isEnding: _isEnding,
                                  elapsedSeconds: _elapsedSeconds,
                                  hasRental: _hasRental,
                                  onToggle: _handleToggle,
                                  onEnd: _handleEndRental,
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
          if (_requireStart)
            Positioned.fill(
              bottom: 92,
              child: _StartRideOverlay(
                isLoading: _isStartingRide,
                onStart: _handleStartRide,
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
      final ok = await _rentalService.toggleMotor(value);
      if (!mounted) return;
      setState(() {
        if (ok) {
          _isActive = value;
          final current = _status;
          if (current != null) {
            _status = RideStatus(
              motorOn: value,
              rangeKm: current.rangeKm,
              pingQuality: current.pingQuality,
              rentalMinutes: current.rentalMinutes,
              carbonReduction: current.carbonReduction,
              rideSeconds: current.rideSeconds,
              carbonEmissions: current.carbonEmissions,
              calories: current.calories,
              hasMotorState: true,
              plate: current.plate,
              batteryPercent: current.batteryPercent,
            );
          }
        }
      });
      if (!ok) {
        _showSnack(AppLocalizations.of(context).accFailed);
      }
    } catch (e) {
      _showSnack('${AppLocalizations.of(context).sendFailed}$e');
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

  void _ensureTimer() {
    if (_timer != null || !_hasRental) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleStartRide() async {
    if (_isStartingRide) return;
    setState(() => _isStartingRide = true);
    try {
      final rental = await _rentalService.startRental();
      if (!mounted) return;
      setState(() {
        _rental = rental;
        _hasRental = (rental.rideHistoryId ?? '').isNotEmpty || rental.id.isNotEmpty;
        _elapsedSeconds = 0;
        _requireStart = false;
      });
      _ensureTimer();
      _startStatusListener();
    } catch (e) {
      _showSnack('${AppLocalizations.of(context).startRideFailed}$e');
    } finally {
      if (mounted) {
        setState(() => _isStartingRide = false);
      }
    }
  }

  Future<void> _handleEndRental() async {
    if (_isEnding) return;
    if (_isActive) {
      _showSnack(AppLocalizations.of(context).turnOffBeforeEnd);
      return;
    }
    setState(() => _isEnding = true);
    try {
      final endedRideId = await _rentalService.endRental();
      _statusSub?.cancel();
      _timer?.cancel();
      final history = await HistoryService().fetchHistoryById(endedRideId);
      if (!mounted) return;
      if (history.isEmpty) {
        _showSnack('Detail history tidak ditemukan.');
        return;
      }
      final entry = history.first;
      final item = HistoryItem(
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
      );
      setState(() {
        _rental = null;
        _status = null;
        _hasRental = false;
        _requireStart = true;
        _elapsedSeconds = 0;
      });
      Navigator.of(context).push(
        appRoute(DetailHistoryScreen(item: item, returnToDashboard: true)),
      );
    } catch (e) {
      _showSnack('${AppLocalizations.of(context).endRentalFailed}$e');
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
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

class _StartRideOverlay extends StatelessWidget {
  const _StartRideOverlay({
    required this.isLoading,
    required this.onStart,
  });

  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
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
            border: Border.all(color: const Color(0xFFE7EBF3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).startRideTitle,
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).startRideBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          AppLocalizations.of(context).startRideButton,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
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
    final l10n = AppLocalizations.of(context);
    final batteryText =
        battery != null ? '${l10n.battery} ${(battery!).toStringAsFixed(0)}%' : l10n.locked;
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
              isActive ? l10n.statusOn : l10n.statusOff,
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
    required this.isEnding,
    required this.elapsedSeconds,
    required this.hasRental,
    required this.onEnd,
    this.status,
    this.rental,
  });

  final bool isActive;
  final bool dimmed;
  final bool isBusy;
  final bool isEnding;
  final int elapsedSeconds;
  final bool hasRental;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEnd;
  final RideStatus? status;
  final RentalSession? rental;

  @override
  Widget build(BuildContext context) {
    final carbon = status?.carbonEmissions ?? 0;
    final rentalTime = status?.rentalMinutes ?? 0;
    final ping = status?.pingQuality ?? '---';
    final l10n = AppLocalizations.of(context);
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
                  label: l10n.carbonEmission,
                  value: carbon == 0 ? '--' : carbon.toStringAsFixed(2),
                  icon: Icons.eco_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  dimmed: dimmed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EndRentalTile(
                  isEnding: isEnding,
                  disabled: isBusy,
                  onPressed: onEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _RentalTimeTile(
                  label: l10n.rentalTime,
                  value: hasRental
                      ? _formatDuration(elapsedSeconds)
                      : (rentalTime == 0
                          ? '--'
                          : '$rentalTime ${l10n.durationMinute}'),
                  icon: Icons.timer_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  active: hasRental,
                  dimmed: dimmed,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                  label: l10n.ping,
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
                child: _ActionTile(
                  label: l10n.on,
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
                  label: l10n.off,
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

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

class _RentalTimeTile extends StatelessWidget {
  const _RentalTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.labelStyle,
    required this.valueStyle,
    required this.active,
    required this.dimmed,
  });

  final String label;
  final String value;
  final IconData icon;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final bool active;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFF2C7BFE);
    final fg = active ? Colors.white : baseColor;
    final bg = active
        ? const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFF1E6DFF),
              Color(0xFF3F8CFF),
            ],
          )
        : const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xFFE5ECF7),
              Color(0xFFF4F7FB),
            ],
          );
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(12),
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
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: labelStyle.copyWith(color: fg)),
                if (value.isNotEmpty)
                  Text(value, style: valueStyle.copyWith(color: fg)),
              ],
            ),
            const Spacer(),
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  AppLocalizations.of(context).live,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            if (!active)
              Icon(Icons.timer_outlined, color: baseColor, size: 18),
          ],
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

class _EndRentalTile extends StatelessWidget {
  const _EndRentalTile({
    required this.isEnding,
    required this.disabled,
    required this.onPressed,
  });

  final bool isEnding;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFFFA45B);
    final isDisabled = disabled || isEnding;
    return Opacity(
      opacity: isDisabled ? 0.7 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDisabled ? null : onPressed,
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1AFFA45B),
                blurRadius: 10,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.stop_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isEnding
                      ? AppLocalizations.of(context).ending
                      : AppLocalizations.of(context).endRental,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (isEnding)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
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
  void initState() {
    super.initState();
    _position = widget.isActive ? 1.0 : -1.0;
  }

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
                      widget.isActive
                          ? AppLocalizations.of(context).slideToLock
                          : AppLocalizations.of(context).slideToUnlock,
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
