import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/find_no_connection_dialog.dart';
import '../../../components/loading_dialog.dart';
import '../../../components/no_internet_dialog.dart';
import '../../../components/app_motion.dart';
import '../../../core/network/network_utils.dart';
import '../../history/presentation/history_screen.dart';
import '../../history/data/history_service.dart';
import '../../history/data/history_models.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../rental/data/emotor_service.dart';
import '../../rental/data/rental_service.dart';
import '../../membership/presentation/membership_screen.dart';
import '../../membership/data/membership_check_service.dart';
import '../../../components/bottom_nav.dart';
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
  bool _isFinding = false;
  bool _hasRental = false;
  bool _requireStart = false;
  int _elapsedSeconds = 0;
  double _additionalPayment = 0;
  int _overtimeSeconds = 0;
  DateTime? _lastAdditionalFetch;
  bool _fetchingAdditional = false;
  RideStatus? _status;
  RentalSession? _rental;
  final RentalService _rentalService = RentalService();
  final MembershipCheckService _membershipCheckService =
      MembershipCheckService();
  final EmotorService _emotorService = EmotorService();
  StreamSubscription<RideStatus>? _statusSub;
  Timer? _timer;
  static const Duration kIoTCommandTimeout = Duration(seconds: 12);
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _rentalTimeSyncTimer;

  bool _noInternetDialogShown = false;
  bool _resumeInProgress = false;
  bool _authExpiredHandled = false;
  bool _computeHasActivePackage() {
    final expiresAt = SessionManager.instance.membershipExpiresAt;
    if (expiresAt != null && expiresAt.isAfter(DateTime.now())) {
      return true;
    }
    final remaining = SessionManager.instance.getRemainingSecondsNow();
    if (remaining > 0) {
      return true;
    }
    return SessionManager.instance.hasActivePackage;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenInternetConnection();

    _rental = widget.initialRental ?? SessionManager.instance.rental;
    _isActive = _rental?.motorOn ?? false;
    _hasRental = _rental != null;
    _requireStart = !_hasRental && !_computeHasActivePackage();
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
    _checkMembershipStatus();
    _refreshDashboard();
    _updateAdditionalPayIfNeeded();
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
      } else {
        setState(() {
          _requireStart = !_computeHasActivePackage();
        });
      }
      _checkMembershipStatus();
      _refreshDashboard();
      _updateAdditionalPayIfNeeded();
    } finally {
      _resumeInProgress = false;
    }
  }

  Future<void> _checkMembershipStatus() async {
    final customerId = SessionManager.instance.customerId ?? '';
    if (customerId.isEmpty || SessionManager.instance.token == null) return;
    try {
      final hasMembership =
          await _membershipCheckService.checkMembership(customerId: customerId);
      if (!mounted || hasMembership == null) return;
      final active = hasMembership || _computeHasActivePackage();
      SessionManager.instance.setHasActivePackage(active);
      if (mounted) {
        setState(() {
          _requireStart = !_hasRental && !active;
        });
        _ensureTimer();
      }
    } catch (_) {}
  }

  Future<void> _refreshDashboard() async {
    final customerId = SessionManager.instance.customerId ?? '';
    if (customerId.isEmpty || SessionManager.instance.token == null) return;
    try {
      final data = await _emotorService.fetchDashboardRefresh(customerId);
      if (data == null) return;
      await SessionManager.instance.setDashboardData(
        emotorNumber: data.emotorNumber,
        packageName: data.packageName,
        remainingSeconds: data.remainingSeconds,
        validUntil: data.validUntil,
        emissionReduction: data.emissionReduction,
        rideRange: data.rideRange,
      );
      final activeFromDashboard =
          (data.remainingSeconds != null && data.remainingSeconds! > 0) ||
              (data.validUntil != null &&
                  data.validUntil!.isAfter(DateTime.now()));
      if (!activeFromDashboard) {
        await SessionManager.instance.clearMembershipState();
      } else {
        SessionManager.instance.setHasActivePackage(activeFromDashboard);
      }
      if (mounted) {
        setState(() {});
        setState(() {
          _requireStart = !_hasRental && !activeFromDashboard;
        });
        _ensureTimer();
        _updateAdditionalPayIfNeeded();
      }
    } catch (_) {}
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
          _requireStart = !_computeHasActivePackage();
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
          _requireStart = !_computeHasActivePackage();
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
      _updateAdditionalPayIfNeeded();
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
      _updateAdditionalPayIfNeeded();
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
      _requireStart = !_computeHasActivePackage();
      _isActive = false;
      _elapsedSeconds = 0;
      _additionalPayment = 0;
      _overtimeSeconds = 0;
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
        _isFinding = false;
      });
    }
    SessionManager.instance.clearAuth();
    if (!mounted) return;
    await showAppDialog<void>(
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

    final rental = _rental;
    final status = _status;
    final riderName = SessionManager.instance.user?.name ?? 'Rider';
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
    final dashboardNumber = SessionManager.instance.dashboardEmotorNumber;
    final emotorFallback = (dashboardNumber != null && dashboardNumber.isNotEmpty)
        ? dashboardNumber
        : (emotorPlate != null && emotorPlate.isNotEmpty)
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
    final showStartOverlay = !_hasRental && !_computeHasActivePackage();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _Background(),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: showStartOverlay,
                        child: _NewDashboardContent(
                          riderName: riderName,
                          plateText: plateText,
                          isActive: _isActive,
                          isFinding: _isFinding,
                          isToggling: _isToggling,
                          elapsedSeconds: _elapsedSeconds,
                          rentalStartedAt: rentalStartedAt,
                          status: status,
                          rental: rental,
                          additionalPayment: _additionalPayment,
                          onFind: _handleFind,
                          onToggle: _handleToggle,
                          onViewPackage: _handleGetPackages,
                          onChangeMotor: _showChangeMotorDialog,
                        ),
                      ),
                    ),
                    const SizedBox(height: 72),
                  ],
                ),
                if (showStartOverlay)
                  Positioned.fill(
                    child: _StartRideOverlay(
                      isLoading: false,
                      onStart: _handleGetPackages,
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AppBottomNavBar(
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
                ),
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
        _updateAdditionalPayIfNeeded(force: true);
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
    catch (_) {
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
    showAppSnackBar(context, message);
  }

  bool _isMembershipExpired() {
    final expiresAt = SessionManager.instance.membershipExpiresAt;
    if (expiresAt == null) return false;
    return expiresAt.isBefore(DateTime.now());
  }

  Future<void> _updateAdditionalPayIfNeeded({bool force = false}) async {
    if (!mounted) return;
    final customerId = SessionManager.instance.customerId ?? '';
    if (customerId.isEmpty || SessionManager.instance.token == null) return;

    final expired = _isMembershipExpired();
    final motorOn = _isActive;
    if (!expired || !motorOn) {
      if (_additionalPayment != 0 || _overtimeSeconds != 0) {
        setState(() {
          _additionalPayment = 0;
          _overtimeSeconds = 0;
        });
      }
      return;
    }

    if (_fetchingAdditional) return;
    if (!force && _lastAdditionalFetch != null) {
      final diff = DateTime.now().difference(_lastAdditionalFetch!);
      if (diff.inSeconds < 10) return;
    }

    _fetchingAdditional = true;
    _lastAdditionalFetch = DateTime.now();
    try {
      final info = await _emotorService.fetchAdditionalInfo(customerId);
      if (!mounted || info == null) return;
      setState(() {
        _additionalPayment = info.additionalPayment;
        _overtimeSeconds = info.overtimeSeconds;
      });
    } catch (_) {} finally {
      _fetchingAdditional = false;
    }
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
        showAppDialog<void>(
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
    } catch (_) {
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
    final hasCountdown = _hasRental ||
        SessionManager.instance.membershipExpiresAt != null ||
        SessionManager.instance.getRemainingSecondsNow() > 0;
    if (_timer != null || !hasCountdown) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (!_hasRental &&
          SessionManager.instance.membershipExpiresAt == null &&
          SessionManager.instance.getRemainingSecondsNow() == 0) {
        _timer?.cancel();
        _timer = null;
        return;
      }
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

  void _handleGetPackages() {
    Navigator.of(context).push(
      appRoute(
        const MembershipScreen(),
        direction: AxisDirection.left,
      ),
    );
  }

  void _showChangeMotorDialog() {
    showAppDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ChangeMotorDialog(
          onClose: () => Navigator.of(dialogContext).pop(),
          onContact: () {
            Navigator.of(dialogContext).pop();
            _showContactOperatorDialog(context);
          },
        );
      },
    );
  }

  Future<void> _showContactOperatorDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    const phoneNumber = '+62 821-4454-0304';
    const waNumber = '6282144540304';
    final message = Uri.encodeComponent(
      'Halo Operator, saya butuh bantuan untuk penggantian motor.',
    );
    final url = Uri.parse('https://wa.me/$waNumber?text=$message');
    await showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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
                        l10n.contactOperator,
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
                  l10n.contactOperatorBody,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B8190),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF5FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD6E4FF)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.chat_bubble_rounded,
                          color: Color(0xFF25D366), size: 18),
                      const SizedBox(width: 6),
                      Text(
                        phoneNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C7BFE),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.contactAdminButton,
                      style: GoogleFonts.poppins(
                        fontSize: 12.8,
                        fontWeight: FontWeight.w600,
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
  }

  Future<bool?> showEndRentalConfirmDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return showAppDialog<bool>(
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



  Future<bool?> showTurnOffConfirmDialog(BuildContext context) {
    return showAppDialog<bool>(
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
                    color: const Color(0xFFE34A43),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33E34A43),
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
                          backgroundColor: const Color(0xFFE34A43),
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
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, 12),
              ),
            ],
            border: Border.all(color: const Color(0xFFF0F2F6)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      AppLocalizations.of(context).startRideTitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1B1F2A),
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
                        onPressed: null,
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        color: const Color(0xFF222222),
                        disabledColor: const Color(0xFF222222),
                        splashRadius: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).startRideBody,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 132,
                    width: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFEFF4FF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2C7BFE)
                              .withValues(alpha: 0.14),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/buy.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C7BFE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                            fontSize: 13.8,
                            fontWeight: FontWeight.w600,
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

class _NewDashboardContent extends StatelessWidget {
  const _NewDashboardContent({
    required this.riderName,
    required this.plateText,
    required this.isActive,
    required this.isFinding,
    required this.isToggling,
    required this.elapsedSeconds,
    required this.rentalStartedAt,
    required this.status,
    required this.rental,
    required this.additionalPayment,
    required this.onFind,
    required this.onToggle,
    required this.onViewPackage,
    required this.onChangeMotor,
  });

  final String riderName;
  final String plateText;
  final bool isActive;
  final bool isFinding;
  final bool isToggling;
  final int elapsedSeconds;
  final DateTime? rentalStartedAt;
  final RideStatus? status;
  final RentalSession? rental;
  final double additionalPayment;
  final VoidCallback onFind;
  final ValueChanged<bool> onToggle;
  final VoidCallback onViewPackage;
  final VoidCallback onChangeMotor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final carbonReduction = SessionManager.instance.dashboardEmission ?? 0;
    final rangeKm = SessionManager.instance.dashboardRideRange ?? 0;
    final rideSeconds = elapsedSeconds;
    final needToPayAmount = additionalPayment > 0
        ? additionalPayment
        : (status?.amountPaid ?? 0);
    final expiresAt = SessionManager.instance.membershipExpiresAt;
    final membershipName =
        SessionManager.instance.membershipName ?? l10n.packageDefault;
    final remainingFromExpiry = _remainingSecondsFromExpiry(expiresAt);
    final remainingFromSession = SessionManager.instance.getRemainingSecondsNow();
    final remainingSeconds =
        remainingFromExpiry > 0 ? remainingFromExpiry : remainingFromSession;
    String formatCountdown(int seconds) {
      if (seconds < 0) seconds = 0;
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      child: Column(
        children: [
          _DashboardHeaderCard(
            plateText: plateText,
            isActive: isActive,
            expiresAt: expiresAt,
            remainingSeconds: remainingSeconds,
            needToPayAmount: needToPayAmount,
            onViewPackage: onViewPackage,
            rideHeader: l10n.rideHeader,
            packageLabel: membershipName,
            viewPackageLabel: l10n.viewPackage,
            expiresLabel: l10n.packageExpires,
            remainingLabel: l10n.additionalPay,
          ),
          const SizedBox(height: 16),
          _StatGrid(
            carbonReduction: carbonReduction,
            rangeKm: rangeKm,
            rideSeconds: rideSeconds,
            isFinding: isFinding,
            onFind: onFind,
            carbonLabel: l10n.emissionReduction,
            findLabel: l10n.findEmotor,
            findingLabel: l10n.finding,
            rangeLabel: l10n.rangeLabel,
            rideTimeLabel: l10n.timeLeft,
            rideTimeValue: formatCountdown(remainingSeconds),
          ),
          const SizedBox(height: 12),
          _ActionRow(
            isActive: isActive,
            isToggling: isToggling,
            onToggle: onToggle,
            onLabel: l10n.on,
            offLabel: l10n.off,
          ),
          const SizedBox(height: 10),
          _OutlineButton(
            label: l10n.changeMotor,
            icon: Icons.cached_rounded,
            onTap: onChangeMotor,
          ),
        ],
      ),
    );
  }

  int _remainingSecondsFromExpiry(DateTime? expiresAt) {
    if (expiresAt == null) return 0;
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inSeconds;
  }

}

class _DashboardHeaderCard extends StatelessWidget {
  const _DashboardHeaderCard({
    required this.plateText,
    required this.isActive,
    required this.expiresAt,
    required this.remainingSeconds,
    required this.needToPayAmount,
    required this.onViewPackage,
    required this.rideHeader,
    required this.packageLabel,
    required this.viewPackageLabel,
    required this.expiresLabel,
    required this.remainingLabel,
  });

  final String plateText;
  final bool isActive;
  final DateTime? expiresAt;
  final int remainingSeconds;
  final double needToPayAmount;
  final VoidCallback onViewPackage;
  final String rideHeader;
  final String packageLabel;
  final String viewPackageLabel;
  final String expiresLabel;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF78C9F4), Color(0xFF4A8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2C7BFE),
            blurRadius: 14,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            rideHeader,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          _VehicleHero(
            plateText: plateText,
            isActive: isActive,
          ),
          const SizedBox(height: 12),
          _PackageSummaryCard(
            expiresAt: expiresAt,
            remainingSeconds: remainingSeconds,
            needToPayAmount: needToPayAmount,
            onViewPackage: onViewPackage,
            packageLabel: packageLabel,
            viewPackageLabel: viewPackageLabel,
            expiresLabel: expiresLabel,
            remainingLabel: remainingLabel,
          ),
        ],
      ),
    );
  }

}

class _VehicleHero extends StatefulWidget {
  const _VehicleHero({
    required this.plateText,
    required this.isActive,
  });

  final String plateText;
  final bool isActive;

  @override
  State<_VehicleHero> createState() => _VehicleHeroState();
}

class _VehicleHeroState extends State<_VehicleHero>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  late final Animation<double> _sweep;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _sweep = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _startSweepLoop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _visible = state == AppLifecycleState.resumed;
    if (!_visible) {
      _controller.stop();
    } else {
      _startSweepLoop();
    }
  }

  Future<void> _startSweepLoop() async {
    if (!_visible || _controller.isAnimating) return;
    while (mounted && _visible) {
      await _controller.forward(from: 0);
      if (!mounted || !_visible) break;
      await Future<void>.delayed(const Duration(milliseconds: 1800));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 150,
          width: 210,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(90),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(90),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/dashboard.png',
                  height: 132,
                  fit: BoxFit.contain,
                ),
                AnimatedBuilder(
                  animation: _sweep,
                  builder: (context, child) {
                    final dx = (-0.6 + (_sweep.value * 1.2));
                    return Transform.translate(
                      offset: Offset(210 * dx, 0),
                      child: child,
                    );
                  },
                  child: Transform.rotate(
                    angle: -0.25,
                    child: Container(
                      width: 90,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.12),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.plateText,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            _StatusBadge(isActive: widget.isActive),
          ],
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? const Color(0xFF22C55E) : const Color(0xFFE34A43);
    final l10n = AppLocalizations.of(context);
    final text = isActive ? l10n.statusOn : l10n.statusOff;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PackageSummaryCard extends StatelessWidget {
  const _PackageSummaryCard({
    required this.expiresAt,
    required this.remainingSeconds,
    required this.needToPayAmount,
    required this.onViewPackage,
    required this.packageLabel,
    required this.viewPackageLabel,
    required this.expiresLabel,
    required this.remainingLabel,
  });

  final DateTime? expiresAt;
  final int remainingSeconds;
  final double needToPayAmount;
  final VoidCallback onViewPackage;
  final String packageLabel;
  final String viewPackageLabel;
  final String expiresLabel;
  final String remainingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F2FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  packageLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C7BFE),
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onViewPackage,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  viewPackageLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9AA0AA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Divider(color: const Color(0xFFE6E9F2), height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expiresLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C7BFE),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(expiresAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C7BFE),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    remainingLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C7BFE),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatRupiah(needToPayAmount),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C7BFE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '--';
    dt = dt.toLocal();
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
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month ${dt.year} $hour:$minute';
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({
    required this.carbonReduction,
    required this.rangeKm,
    required this.rideSeconds,
    required this.isFinding,
    required this.onFind,
    required this.carbonLabel,
    required this.findLabel,
    required this.findingLabel,
    required this.rangeLabel,
    required this.rideTimeLabel,
    required this.rideTimeValue,
  });

  final double carbonReduction;
  final int rangeKm;
  final int rideSeconds;
  final bool isFinding;
  final VoidCallback onFind;
  final String carbonLabel;
  final String findLabel;
  final String findingLabel;
  final String rangeLabel;
  final String rideTimeLabel;
  final String rideTimeValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: carbonLabel,
                value: _formatCarbon(carbonReduction),
                icon: Icons.eco_rounded,
                filled: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                title: isFinding ? findingLabel : findLabel,
                value: '',
                icon: Icons.campaign_rounded,
                filled: false,
                onTap: isFinding ? null : onFind,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                title: rangeLabel,
                value: '$rangeKm km',
                icon: Icons.place_rounded,
                filled: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                title: rideTimeLabel,
                value: rideTimeValue,
                icon: Icons.timer_rounded,
                filled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCarbon(double value) {
    if (value >= 1000) {
      final kg = value / 1000;
      return '${kg.toStringAsFixed(2)} kg';
    }
    return '${value.toStringAsFixed(2)} g';
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.isActive,
    required this.isToggling,
    required this.onToggle,
    required this.onLabel,
    required this.offLabel,
  });

  final bool isActive;
  final bool isToggling;
  final ValueChanged<bool> onToggle;
  final String onLabel;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            label: onLabel,
            color: const Color(0xFF2C7BFE),
            icon: Icons.power_settings_new_rounded,
            onTap: (!isToggling && !isActive) ? () => onToggle(true) : null,
            isActive: isActive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionTile(
            label: offLabel,
            color: const Color(0xFFE34A43),
            icon: Icons.power_settings_new_rounded,
            onTap: (!isToggling && isActive) ? () => onToggle(false) : null,
            isActive: !isActive,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.filled,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final baseColor = const Color(0xFF2C7BFE);
    final bg = filled ? baseColor : Colors.white;
    final border =
        filled ? null : Border.all(color: const Color(0xFFE6E9F2), width: 1);
    final textColor = filled ? Colors.white : const Color(0xFF111827);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 78,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: onTap != null
                ? Border.all(color: baseColor, width: 1.2)
                : border,
            boxShadow: filled
                ? const [
                    BoxShadow(
                      color: Color(0x1A2C7BFE),
                      blurRadius: 10,
                      offset: Offset(0, 6),
                    ),
                  ]
                : null,
          ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              icon,
              color: filled ? Colors.white : const Color(0xFF2C7BFE),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
    required this.isActive,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final isRed = color == const Color(0xFFE34A43);
    final background = isRed ? null : null;
    return Opacity(
      opacity: onTap == null ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: color,
            gradient: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C7BFE), width: 1.2),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF2C7BFE), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
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

class _ChangeMotorDialog extends StatelessWidget {
  const _ChangeMotorDialog({
    required this.onClose,
    required this.onContact,
  });

  final VoidCallback onClose;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE7F2FF),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A2C7BFE),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: Color(0xFF2C7BFE),
                      size: 30,
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
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                      iconSize: 18,
                      color: const Color(0xFF111827),
                      splashRadius: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.changeMotorTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.changeMotorBody,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B8190),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F3F6),
                        foregroundColor: const Color(0xFF111827),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.cancel,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
                      onPressed: onContact,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C7BFE),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        l10n.contactOperator,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
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
  }
}

class _ScooterHero extends StatefulWidget {
  const _ScooterHero({
    required this.isActive,
    required this.hasActivePackage,
  });

  final bool isActive;
  final bool hasActivePackage;

  @override
  State<_ScooterHero> createState() => _ScooterHeroState();
}

class _ScooterHeroState extends State<_ScooterHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulse = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
    if (widget.hasActivePackage) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ScooterHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActivePackage && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.hasActivePackage && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowBase = widget.isActive ? 0.16 : 0.08;
    final glowBoost = widget.hasActivePackage ? 0.10 : 0.0;
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final scale = widget.hasActivePackage ? _pulse.value : 1.0;
          final glow = glowBase + (widget.hasActivePackage ? 0.06 : 0.0);
          return Transform.scale(
            scale: scale,
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
                          color: const Color(0xFF2C7BFE).withValues(
                            alpha: (glow + glowBoost).clamp(0.08, 0.28),
                          ),
                          blurRadius: 28,
                          spreadRadius: 6,
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
        },
      ),
    );
  }
}





