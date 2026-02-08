import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../components/find_no_connection_dialog.dart';
import '../../../components/loading_dialog.dart';
import '../../../components/no_internet_dialog.dart';
import '../../../core/network/network_utils.dart';
import '../../history/presentation/history_screen.dart';
import '../../history/data/history_service.dart';
import '../../history/data/history_models.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../rental/data/emotor_service.dart';
import '../../rental/data/rental_service.dart';
import '../../history/presentation/detail_history_screen.dart';
import '../../../components/bottom_nav.dart';
import '../../../components/end_rental_notice.dart';
import '../../../core/navigation/app_route.dart';
import '../../../core/network/api_client.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.initialRental});

  final RentalSession? initialRental;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  bool _isActive = false;
  bool _isToggling = false;
  bool _isEnding = false;
  bool _isStartingRide = false;
  bool _isFinding = false;
  bool _hasRental = false;
  bool _requireStart = false;
  int _elapsedSeconds = 0;
  RideStatus? _status;
  RentalSession? _rental;
  final RentalService _rentalService = RentalService();
  StreamSubscription<RideStatus>? _statusSub;
  Timer? _timer;
  static const Duration kIoTCommandTimeout = Duration(seconds: 12);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _rentalTimeSyncTimer;

  bool _noInternetDialogShown = false;
  bool _resumeInProgress = false;
  bool _authExpiredHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenInternetConnection();

    _rental = widget.initialRental ?? SessionManager.instance.rental;
    _isActive = _rental?.motorOn ?? false;
    _hasRental = _rental != null;
    _requireStart = !_hasRental;
    _elapsedSeconds = 0;
    final startedAt = SessionManager.instance.rentalStartedAt;
    if (_hasRental && startedAt != null) {
      final diff = DateTime.now().difference(startedAt);
      if (!diff.isNegative) {
        _elapsedSeconds = diff.inSeconds;
      }
    }
    _ensureTimer();
    _bootstrapRental();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();

    _statusSub?.cancel();
    _timer?.cancel();
    _rentalTimeSyncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleResume();
    }
  }

  Future<void> _handleResume() async {
    if (_resumeInProgress) return;
    _resumeInProgress = true;
    try {
      await SessionManager.instance.loadFromStorage();
      if (!mounted) return;

      final storedRental = SessionManager.instance.rental;
      if (storedRental != null) {
        setState(() {
          _rental ??= storedRental;
          _isActive = _rental?.motorOn ?? _isActive;
          _hasRental = true;
          _requireStart = false;
          final startedAt = SessionManager.instance.rentalStartedAt;
          if (startedAt != null) {
            final diff = DateTime.now().difference(startedAt);
            if (!diff.isNegative) {
              _elapsedSeconds = diff.inSeconds;
            }
          }
        });
        _ensureTimer();
        _statusSub?.cancel();
        await _bootstrapRental();
      }
    } finally {
      _resumeInProgress = false;
    }
  }

  Future<void> _bootstrapRental() async {
    if (_hasRental) {
      await _verifyRentalActive();
      if (!mounted) return;
      if (_hasRental) {
        if ((_rental?.rideHistoryId ?? '').isNotEmpty) {
          _refreshStatusOnce();
          _startStatusListener();
        }
        _syncStartRentalTime();
        return;
      }
    }
    await _restoreActiveRentalIfNeeded();
  }

  void _syncStartRentalTime() {
    _rentalTimeSyncTimer?.cancel();
    _fetchAssignedAndSyncStartTime();
    _rentalTimeSyncTimer = Timer(const Duration(seconds: 3), () {
      _fetchAssignedAndSyncStartTime();
    });
  }

  Future<void> _fetchAssignedAndSyncStartTime() async {
    final userId = SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim();
    if (userId == null || userId.isEmpty) return;
    try {
      final assigned = await EmotorService().fetchAssignedToUser(userId);
      if (!mounted || assigned?.createTime == null) return;
      SessionManager.instance.setRentalStartedAt(assigned!.createTime);
      if (mounted) {
        setState(() {
          _elapsedSeconds = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _verifyRentalActive() async {
    final rideId = _rental?.rideHistoryId;
    if (rideId == null || rideId.isEmpty) {
      await _verifyAssignedEmotorStatus();
      return;
    }
    try {
      final history = await HistoryService().fetchHistoryById(rideId);
      if (!mounted) return;
      final entry = history.isNotEmpty ? history.first : null;
      final isActive = entry is HistoryEntry && entry.isActive;
      if (!isActive) {
        _statusSub?.cancel();
        _timer?.cancel();
        setState(() {
          _status = null;
          _rental = null;
          _hasRental = false;
          _requireStart = true;
          _isActive = false;
          _elapsedSeconds = 0;
        });
        SessionManager.instance.clearRental();
        SessionManager.instance.setRentalStartedAt(null);
      }
    } catch (_) {}
  }

  Future<void> _verifyAssignedEmotorStatus() async {
    try {
      final userId = SessionManager.instance.user?.userId ??
          SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
          SessionManager.instance.userProfile?['id']?.toString().trim();
      if (userId == null || userId.isEmpty) return;
      final assigned = await EmotorService().fetchAssignedToUser(userId);
      if (!mounted) return;
      if (assigned == null) return;
      if (!assigned.isInUse) {
        if ((_rental?.rideHistoryId ?? '').isEmpty &&
            SessionManager.instance.rentalStartedAt != null) {
          return;
        }
        _statusSub?.cancel();
        _timer?.cancel();
        setState(() {
          _status = null;
          _rental = null;
          _hasRental = false;
          _requireStart = true;
          _isActive = false;
          _elapsedSeconds = 0;
        });
        SessionManager.instance.clearRental();
        SessionManager.instance.setRentalStartedAt(null);
      }
    } catch (_) {}
  }

  Future<void> _restoreActiveRentalIfNeeded() async {
    if (!mounted || _hasRental) return;
    if (SessionManager.instance.token == null) return;
    final restored = await _rentalService.restoreActiveRental();
    if (!mounted || restored == null) return;
    setState(() {
      _rental = restored;
      _hasRental = true;
      _requireStart = false;
      final startedAt = SessionManager.instance.rentalStartedAt;
      if (startedAt != null) {
        final diff = DateTime.now().difference(startedAt);
        if (!diff.isNegative) {
          _elapsedSeconds = diff.inSeconds;
        }
      }
    });
    _ensureTimer();
    if ((_rental?.rideHistoryId ?? '').isNotEmpty) {
      _refreshStatusOnce();
      _startStatusListener();
    }
    _syncStartRentalTime();
  }

  void _listenInternetConnection() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      if (!mounted) return;

      final hasInternet =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      if (!hasInternet) {
        if (_noInternetDialogShown) return;

        _noInternetDialogShown = true;
        await showNoInternetDialog(context);
        _noInternetDialogShown = false;
      }
    });
  }

  void _startStatusListener() {
    if (SessionManager.instance.token == null) return;
    _statusSub = _rentalService.statusStream().listen((data) {
      if (!mounted) return;
      if (data.isEnded && _shouldAcceptRemoteEnd(data)) {
        _handleRemoteEnd();
        return;
      }
      setState(() {
        _status = data;
        if (data.hasMotorState) {
          _isActive = data.motorOn;
        }
        _hasRental = true;
        if (data.rideSeconds > 0 && _shouldSyncElapsed(data.rideSeconds)) {
          _elapsedSeconds = data.rideSeconds;
        }
      });
      if (_hasRental) {
        _ensureTimer();
      }
    }, onError: (error) {
      if (!mounted) return;
      if (error is ApiException &&
          (error.statusCode == 404 || error.statusCode == 410)) {
        _handleRemoteEnd();
      } else if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        _handleAuthExpired();
      }
    });
  }

  Future<void> _refreshStatusOnce() async {
    if (SessionManager.instance.token == null) return;
    try {
      final data = await _rentalService.fetchStatus();
      if (!mounted) return;
      if (data.isEnded && _shouldAcceptRemoteEnd(data)) {
        _handleRemoteEnd();
        return;
      }
      setState(() {
        _status = data;
        if (data.hasMotorState) {
          _isActive = data.motorOn;
          final currentRental = _rental;
          if (currentRental != null) {
            final updatedRental = RentalSession(
              id: currentRental.id,
              emotorId: currentRental.emotorId,
              plate: currentRental.plate,
              rangeKm: currentRental.rangeKm,
              batteryPercent: currentRental.batteryPercent,
              motorOn: data.motorOn,
              rideHistoryId: currentRental.rideHistoryId,
            );
            _rental = updatedRental;
            SessionManager.instance.saveRental(updatedRental);
          }
        }
        _hasRental = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 404 || e.statusCode == 410) {
        _handleRemoteEnd();
      } else if (e.statusCode == 401 || e.statusCode == 403) {
        _handleAuthExpired();
      }
    } catch (_) {}
  }

  void _handleRemoteEnd() {
    if (!_hasRental) return;
    _statusSub?.cancel();
    _timer?.cancel();
    setState(() {
      _status = null;
      _rental = null;
      _hasRental = false;
      _requireStart = true;
      _isActive = false;
      _elapsedSeconds = 0;
    });
    SessionManager.instance.clearRental();
    SessionManager.instance.setRentalStartedAt(null);
    _showSnack(AppLocalizations.of(context).rentalEndedRemote);
  }

  bool _shouldAcceptRemoteEnd(RideStatus data) {
    final localStart = SessionManager.instance.rentalStartedAt;
    final remoteStart = data.startedAt;
    if (localStart == null || remoteStart == null) return true;
    final deltaMinutes = localStart.difference(remoteStart).inMinutes.abs();
    return deltaMinutes <= 10;
  }

  Future<void> _handleAuthExpired() async {
    if (!mounted || _authExpiredHandled) return;
    _authExpiredHandled = true;
    _statusSub?.cancel();
    _timer?.cancel();
    if (mounted) {
      setState(() {
        _isToggling = false;
        _isEnding = false;
        _isStartingRide = false;
        _isFinding = false;
      });
    }
    SessionManager.instance.clearAuth();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2C7BFE),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x332C7BFE),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_clock_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dialogL10n.errorSessionExpired,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      backgroundColor: const Color(0xFF2C7BFE),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      dialogL10n.signIn,
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
          ),
        );
      },
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      appRoute(const LoginScreen(), direction: AxisDirection.right),
      (route) => false,
    );
  }

  bool _shouldSyncElapsed(int serverSeconds) {
    if (serverSeconds <= 0) return false;
    final startedAt = SessionManager.instance.rentalStartedAt;
    if (startedAt != null) {
      final expected = DateTime.now().difference(startedAt).inSeconds;
      if (expected.isNegative) return false;
      final delta = (serverSeconds - expected).abs();
      return delta <= 30;
    }
    if (_elapsedSeconds == 0) return true;
    if (serverSeconds < _elapsedSeconds) return false;
    return (serverSeconds - _elapsedSeconds) <= 60;
  }

  @override
  Widget build(BuildContext context) {
    String firstNonEmpty(List<String?> values, String fallback) {
      for (final value in values) {
        final text = value?.toString().trim();
        if (text == null || text.isEmpty) continue;
        final lowered = text.toLowerCase();
        if (text == '-' || text == 'N/A' || lowered == 'null') continue;
        return text;
      }
      return fallback;
    }

    final dimmed = !_isActive;
    final rental = _rental;
    final status = _status;
    final riderName = SessionManager.instance.user?.name ?? 'Rider';
    final l10n = AppLocalizations.of(context);
    final emotorFromProfile = SessionManager.instance.emotorProfile;
    final emotorFromUser = SessionManager.instance.userProfile?['emotor'];
    final emotorPlate =
        emotorFromProfile?['vehicle_number']?.toString().trim() ??
        emotorFromProfile?['vehicleNumber']?.toString().trim() ??
        emotorFromProfile?['plate']?.toString().trim() ??
        emotorFromProfile?['license_plate']?.toString().trim() ??
        (emotorFromUser is Map<String, dynamic>
            ? (emotorFromUser['vehicle_number']?.toString().trim() ??
                  emotorFromUser['vehicleNumber']?.toString().trim() ??
                  emotorFromUser['plate']?.toString().trim() ??
                  emotorFromUser['license_plate']?.toString().trim())
            : null);
    final emotorName =
        emotorFromProfile?['modelBikeId_model']?.toString().trim() ??
        emotorFromProfile?['model_name']?.toString().trim() ??
        emotorFromProfile?['model']?.toString().trim() ??
        emotorFromProfile?['name']?.toString().trim() ??
        (emotorFromUser is Map<String, dynamic>
            ? (emotorFromUser['modelBikeId_model']?.toString().trim() ??
                  emotorFromUser['model_name']?.toString().trim() ??
                  emotorFromUser['model']?.toString().trim() ??
                  emotorFromUser['name']?.toString().trim())
            : null);
    final emotorFallback = (emotorPlate != null && emotorPlate.isNotEmpty)
        ? emotorPlate
        : (emotorName != null && emotorName.isNotEmpty)
        ? emotorName
        : 'E-Motor';
    final plateText = firstNonEmpty([
      status?.plate,
      rental?.plate,
      emotorPlate,
      emotorName,
    ], emotorFallback);
    final rentalStartedAt = SessionManager.instance.rentalStartedAt;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: _requireStart,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
                                          style: const TextStyle(
                                            color: Color(0xFF2C7BFE),
                                          ),
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
                                      plate: plateText,
                                    ),
                                    const SizedBox(height: 10),
                                    _GridCards(
                                      status: status,
                                      rental: rental,
                                      isActive: _isActive,
                                      dimmed: dimmed,
                                      isBusy: _isToggling,
                                      isEnding: _isEnding,
                                      isFinding: _isFinding,
                                      elapsedSeconds: _elapsedSeconds,
                                      rentalStartedAt: rentalStartedAt,
                                      hasRental: _hasRental,
                                      onEnd: _handleEndRental,
                                      onFind: _handleFind,
                                    ),
                                    const SizedBox(height: 10),
                                    _PowerButtons(
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
                      if (_requireStart)
                        Positioned.fill(
                          child: _StartRideOverlay(
                            isLoading: _isStartingRide,
                            onStart: _handleStartRide,
                          ),
                        ),
                    ],
                  ),
                ),
                AppBottomNav(
                  activeTab: BottomNavTab.dashboard,
                  onHistoryTap: () {
                    Navigator.of(context).push(
                      appRoute(
                        const HistoryScreen(),
                        direction: AxisDirection.left,
                      ),
                    );
                  },
                  onDashboardTap: () {},
                  onProfileTap: () {
                    Navigator.of(context).push(
                      appRoute(
                        const ProfileScreen(),
                        direction: AxisDirection.left,
                      ),
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
    final l10n = AppLocalizations.of(context);
    if (_isToggling) return;

    if (!value) {
      final confirmed = await showTurnOffConfirmDialog(context);
      if (!mounted) return;
      if (confirmed != true) return;
    }

    // 1️⃣ CEK INTERNET DULU
    final hasInternet = await hasInternetConnection();
    if (!mounted) return;
    if (!hasInternet) {
      _showSnack(l10n.errorNoInternet);
      return;
    }

    setState(() => _isToggling = true);

    showLoadingDialog(
      context,
      message: value
          ? l10n.loadingConnectingVehicle
          : l10n.loadingSendingCommand,
    );

    try {
      // 2️⃣ KIRIM COMMAND + TIMEOUT
      final ok = await _rentalService
          .toggleMotor(value)
          .timeout(kIoTCommandTimeout);

      if (!mounted) return;

      hideLoadingDialog(context);

      if (ok) {
        setState(() {
          _isActive = value;

          final currentRental = _rental;
          if (currentRental != null) {
            final updatedRental = RentalSession(
              id: currentRental.id,
              emotorId: currentRental.emotorId,
              plate: currentRental.plate,
              rangeKm: currentRental.rangeKm,
              batteryPercent: currentRental.batteryPercent,
              motorOn: value,
              rideHistoryId: currentRental.rideHistoryId,
            );
            _rental = updatedRental;
            SessionManager.instance.saveRental(updatedRental);
          }
        });
      } else {
        _showSnack(l10n.errorSendCommandFailed);
      }
    }
    // 3️⃣ AUTH EXPIRED
    on ApiException catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      if (e.statusCode == 401 || e.statusCode == 403) {
        _handleAuthExpired();
      } else {
        _showSnack(l10n.errorNetworkGeneric);
      }
    }
    // 4️⃣ TIMEOUT (SINYAL JELEK / IOT TIDAK RESPON)
    on TimeoutException {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack(l10n.errorVehicleNotResponding);
    }
    // 5️⃣ ERROR LAIN (API / IOT)
    catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack(l10n.errorNetworkGeneric);
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleFind() async {
    final l10n = AppLocalizations.of(context);
    if (_isFinding) return;

    // 1️⃣ CEK INTERNET AWAL
    final hasInternet = await hasInternetConnection();
    if (!mounted) return;
    if (!hasInternet) {
      await showFindNoConnectionDialog(context);
      return;
    }

    setState(() => _isFinding = true);

    // 2️⃣ TAMPILKAN LOADING (SAMA KAYAK ON/OFF)
    showLoadingDialog(context, message: l10n.loadingFindingVehicle);

    try {
      // 3️⃣ PANGGIL API FIND
      final ok = await _rentalService.findEmotor().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted) return;

      // 4️⃣ TUTUP LOADING
      hideLoadingDialog(context);

      // 5️⃣ JIKA BERHASIL → TAMPILKAN POPUP FIND YANG SEKARANG
      if (ok) {
        showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final dialogL10n = AppLocalizations.of(dialogContext);
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2C7BFE),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x332C7BFE),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dialogL10n.findEmotorTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dialogL10n.findEmotorBody,
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
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          backgroundColor: const Color(0xFF2C7BFE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          dialogL10n.findEmotorCta,
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
              ),
            );
          },
        );
      } else {
        _showSnack(l10n.findEmotorFailed);
      }
    }
    // 6️⃣ TIMEOUT / SINYAL JELEK
    on TimeoutException {
      if (!mounted) return;
      hideLoadingDialog(context);
      await showFindNoConnectionDialog(context);
    }
    // 7️⃣ ERROR LAIN
    on ApiException catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      if (e.statusCode == 401 || e.statusCode == 403) {
        _handleAuthExpired();
      } else {
        _showSnack(l10n.findEmotorFailed);
      }
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack(l10n.findEmotorFailed);
    } finally {
      if (mounted) {
        setState(() => _isFinding = false);
      }
    }
  }

  void _ensureTimer() {
    if (_timer != null || !_hasRental) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        final startedAt = SessionManager.instance.rentalStartedAt;
        if (startedAt != null) {
          final diff = DateTime.now().difference(startedAt);
          if (!diff.isNegative) {
            _elapsedSeconds = diff.inSeconds;
            return;
          }
        }
        _elapsedSeconds += 1;
      });
    });
  }

  Future<void> _handleStartRide() async {
    final l10n = AppLocalizations.of(context);
    if (_isStartingRide) return;
    setState(() => _isStartingRide = true);
    try {
      final rental = await _rentalService.startRental();
      if (!mounted) return;
      setState(() {
        _rental = rental;
        _hasRental = true;
        _elapsedSeconds = 0;
        _requireStart = false;
      });
      SessionManager.instance.setRentalStartedAt(DateTime.now());
      _ensureTimer();
      _startStatusListener();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401 || e.statusCode == 403) {
        _handleAuthExpired();
      } else {
        _showSnack('${l10n.startRideFailed}$e');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('${l10n.startRideFailed}$e');
    } finally {
      if (mounted) {
        setState(() => _isStartingRide = false);
      }
    }
  }

  Future<bool?> showEndRentalConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFA45B),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FFA45B),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.stop_circle_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.endRentalConfirmTitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.endRentalConfirmBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: Text(l10n.endRentalConfirmNo),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA45B),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: Text(l10n.endRentalConfirmYes),
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

  Future<void> _handleEndRental() async {
    final l10n = AppLocalizations.of(context);
    if (_isEnding) return;

    final status = _status;
    if (_isActive || (status?.hasMotorState == true && status!.motorOn)) {
      await EndRentalNoticeDialog.show(
        context,
        type: EndRentalNoticeType.turnOffRequired,
      );
      if (!mounted) return;
      return;
    }

    // 1️⃣ KONFIRMASI DULU
    final confirmed = await showEndRentalConfirmDialog(context);
    if (!mounted) return;
    if (confirmed != true) return;

    setState(() => _isEnding = true);

    // 2️⃣ TAMPILKAN LOADING
    showLoadingDialog(context, message: l10n.loadingEndingRental);

    try {
      // 3️⃣ END RENTAL
      final endedRideId = await _endRentalWithRetry();

      if (!mounted) return;
      if (endedRideId == null) {
        hideLoadingDialog(context);
        _showSnack(l10n.endRentalFailed);
        return;
      }

      hideLoadingDialog(context);

      _statusSub?.cancel();
      _timer?.cancel();

      final history = await HistoryService().fetchHistoryById(endedRideId);

      if (!mounted) return;

      if (history.isEmpty) {
        _statusSub?.cancel();
        _timer?.cancel();
        setState(() {
          _rental = null;
          _status = null;
          _hasRental = false;
          _requireStart = true;
          _elapsedSeconds = 0;
          _isActive = false;
        });
        SessionManager.instance.clearRental();
        SessionManager.instance.setRentalStartedAt(null);
        _showSnack(l10n.errorHistoryNotFound);
        return;
      }

      final entry = history.first;

      final item = HistoryItem(
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
      );

      setState(() {
        _rental = null;
        _status = null;
        _hasRental = false;
        _requireStart = true;
        _elapsedSeconds = 0;
      });

      SessionManager.instance.clearRental();
      SessionManager.instance.setRentalStartedAt(null);

      Navigator.of(context).push(
        appRoute(DetailHistoryScreen(item: item, returnToDashboard: true)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      if (e.statusCode == 401 || e.statusCode == 403) {
        _handleAuthExpired();
      } else if (e.statusCode == 404 || e.statusCode == 410) {
        _handleRemoteEnd();
      } else {
        _showSnack('${l10n.endRentalFailed}$e');
      }
    } catch (e) {
      if (!mounted) return;
      hideLoadingDialog(context);
      _showSnack('${l10n.endRentalFailed}$e');
    } finally {
      if (mounted) {
        setState(() => _isEnding = false);
      }
    }
  }

  Future<String?> _endRentalWithRetry() async {
    const maxAttempts = 3;
    var attempt = 0;
    while (mounted && attempt < maxAttempts) {
      try {
        return await _rentalService.endRental();
      } on ApiException catch (e) {
        attempt += 1;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

  Future<bool?> showTurnOffConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final l10n = AppLocalizations.of(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFA45B),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FFA45B),
                        blurRadius: 14,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.power_settings_new_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.turnOffConfirmTitle, // atau hardcode
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.turnOffConfirmBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          side: const BorderSide(color: Color(0xFFE0E6F1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA45B),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          l10n.turnOff,
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
  const _StartRideOverlay({required this.isLoading, required this.onStart});

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
                    color: const Color(
                      0xFF2C7BFE,
                    ).withValues(alpha: isActive ? 0.16 : 0.08),
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
  const _PlateBadge({required this.isActive, required this.plate});

  final bool isActive;
  final String plate;

  @override
  Widget build(BuildContext context) {
    final muted = !isActive;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        plate,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
    );
  }
}

class _GridCards extends StatelessWidget {
  const _GridCards({
    required this.isActive,
    required this.dimmed,
    required this.isBusy,
    required this.isEnding,
    required this.isFinding,
    required this.elapsedSeconds,
    required this.rentalStartedAt,
    required this.hasRental,
    required this.onEnd,
    required this.onFind,
    this.status,
    this.rental,
  });

  final bool isActive;
  final bool dimmed;
  final bool isBusy;
  final bool isEnding;
  final bool isFinding;
  final int elapsedSeconds;
  final DateTime? rentalStartedAt;
  final bool hasRental;
  final VoidCallback onEnd;
  final VoidCallback onFind;
  final RideStatus? status;
  final RentalSession? rental;

  @override
  Widget build(BuildContext context) {
    final carbon = status?.carbonEmissions ?? 0;
    final rentalTime = status?.rentalMinutes ?? 0;
    final ping = status?.pingQuality ?? '---';
    final l10n = AppLocalizations.of(context);
    final label = GoogleFonts.poppins(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final value = GoogleFonts.poppins(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    String formatDate(DateTime? dt) {
      if (dt == null) return '--';
      final local = dt;
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
      final day = local.day.toString().padLeft(2, '0');
      final month = months[local.month - 1];
      return '$day $month ${local.year}';
    }

    String formatTime(DateTime? dt) {
      if (dt == null) return '--';
      final local = dt;
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    String rentalValue() {
      if (!hasRental) return '--';
      if (rentalStartedAt != null) {
        return formatDate(rentalStartedAt);
      }
      return '--';
    }

    List<String> splitValue(String value) {
      final parts = value.split('|');
      if (parts.length >= 2) {
        return [parts[0], parts.sublist(1).join('|')];
      }
      return [value, ''];
    }

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
                  label: '${l10n.start} ${l10n.rentalTime}',
                  value: hasRental
                      ? (rentalStartedAt != null
                            ? '${rentalValue()}|${formatTime(rentalStartedAt)}'
                            : rentalValue())
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
                  label: l10n.findEmotor,
                  value: ping,
                  icon: Icons.campaign_rounded,
                  labelStyle: label,
                  valueStyle: value,
                  rightIcon: true,
                  outlined: true,
                  dimmed: false, // Ping stays vivid
                  onTap: isFinding ? null : onFind,
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
                Text(label, style: labelStyle.copyWith(color: fgColor)),
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
            colors: [Color(0xFF1E6DFF), Color(0xFF3F8CFF)],
          )
        : const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFFE5ECF7), Color(0xFFF4F7FB)],
          );
    final parts = value.split('|');
    final line1 = parts.isNotEmpty ? parts.first : '';
    final line2 = parts.length > 1 ? parts.sublist(1).join('|') : '';
    return Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Container(
        height: 74,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle.copyWith(color: fg),
                  ),
                  if (line1.isNotEmpty)
                    Text(
                      line1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle.copyWith(color: fg, fontSize: 11.5),
                    ),
                  if (line2.isNotEmpty)
                    Text(
                      line2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: valueStyle.copyWith(color: fg, fontSize: 11),
                    ),
                ],
              ),
            ),
            if (!active)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(Icons.timer_outlined, color: baseColor, size: 18),
              ),
          ],
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
              const Icon(
                Icons.stop_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
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

class _PowerButtons extends StatelessWidget {
  const _PowerButtons({
    required this.isActive,
    required this.onToggle,
    this.disabled = false,
  });

  final bool isActive;
  final bool disabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    const onColor = Color(0xFF2C7BFE);
    const offColor = Color(0xFFFFA45B);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _PowerButton(
              label: l10n.on,
              icon: Icons.flash_on_rounded,
              color: onColor,
              active: isActive,
              disabled: disabled,
              onTap: () => onToggle(true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _PowerButton(
              label: l10n.off,
              icon: Icons.power_settings_new_rounded,
              color: offColor,
              active: !isActive,
              disabled: disabled,
              onTap: () => onToggle(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = disabled;
    final bg = active ? color : Colors.white;
    final fg = active ? Colors.white : color;
    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: active
                ? null
                : Border.all(color: color.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: active ? 0.28 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
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
