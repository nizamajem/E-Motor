import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession({
    required this.token,
    required this.name,
    required this.email,
    this.userId,
  });

  final String token;
  final String name;
  final String email;
  final String? userId;
}

class RentalSession {
  RentalSession({
    required this.id,
    required this.emotorId,
    required this.plate,
    required this.rangeKm,
    required this.batteryPercent,
    required this.motorOn,
    this.rideHistoryId,
  });

  factory RentalSession.fromJson(Map<String, dynamic> json) {
    final rideId = json['rideHistoryId']?.toString() ??
        json['ride_history_id']?.toString() ??
        json['ride_id']?.toString() ??
        json['rideId']?.toString() ??
        json['id']?.toString() ??
        '';
    return RentalSession(
      id: json['id']?.toString() ?? rideId,
      emotorId: json['emotorId']?.toString() ??
          json['eMotorId']?.toString() ??
          json['bikeId']?.toString() ??
          json['emotor_id']?.toString() ??
          '',
      plate: json['plate']?.toString() ?? json['vehicle_number']?.toString() ?? '-',
      rangeKm: (json['range_km'] ?? json['range'] ?? 0).toDouble(),
      batteryPercent: (json['battery'] ?? json['battery_percent'] ?? 0).toDouble(),
      motorOn: json['motor_on'] == true || json['motorOn'] == true,
      rideHistoryId: rideId.isEmpty ? null : rideId,
    );
  }

  final String id;
  final String emotorId;
  final String plate;
  final double rangeKm;
  final double batteryPercent;
  final bool motorOn;
  final String? rideHistoryId;
}

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const _keyToken = 'session_token';
  static const _keyName = 'session_name';
  static const _keyEmail = 'session_email';
  static const _keyUserId = 'session_user_id';
  static const _keyEmotorId = 'session_emotor_id';
  static const _keyEmotorImei = 'session_emotor_imei';
  static const _keyUserJson = 'session_user_json';
  static const _keyEmotorJson = 'session_emotor_json';
  static const _keyWalletJson = 'session_wallet_json';
  static const _keyUserVerified = 'session_user_verified';
  static const _keyWalletBalance = 'session_wallet_balance';
  static const _keyOnboardingSeen = 'session_onboarding_seen';
  static const _keyCustomerId = 'session_customer_id';
  static const _keyCustomerEligible = 'session_customer_eligible';
  static const _keyCustomerVerificationStatus =
      'session_customer_verification_status';
  static const _keyMembershipExpiresAt = 'session_membership_expires_at';
  static const _keyMembershipName = 'session_membership_name';
  static const _keyDashboardEmotorNumber = 'session_dashboard_emotor_number';
  static const _keyDashboardRemainingSeconds =
      'session_dashboard_remaining_seconds';
  static const _keyDashboardEmission = 'session_dashboard_emission';
  static const _keyDashboardRideRange = 'session_dashboard_ride_range';
  static const _keyPendingSnapTokens = 'session_pending_snap_tokens';
  static const _keyPendingRedirectUrls = 'session_pending_redirect_urls';
  static const _keyRentalJson = 'session_rental_json';
  static const _keyRentalStartedAt = 'session_rental_started_at';
  static const _keyHasActivePackage = 'session_has_active_package';
  static const _secureKeyAccessToken = 'secure_access_token';
  static const _secureKeyRefreshToken = 'secure_refresh_token';
  static const _secureKeyUserId = 'secure_user_id';
  static const _secureKeyCustomerId = 'secure_customer_id';

  UserSession? _user;
  RentalSession? _rental;
  DateTime? _rentalStartedAt;
  String? _emotorId; // e-motor bound to this user
  String? _emotorImei; // IMEI bound to this user
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _emotorProfile;
  Map<String, dynamic>? _walletProfile;
  bool _isVerified = false;
  int? _walletBalance;
  String? _customerId;
  bool _customerEligible = false;
  String _customerVerificationStatus = 'not_verified';
  DateTime? _membershipExpiresAt;
  String? _membershipName;
  String? _dashboardEmotorNumber;
  int? _dashboardRemainingSeconds;
  double? _dashboardEmission;
  int? _dashboardRideRange;
  Map<String, String> _pendingSnapTokens = {};
  Map<String, String> _pendingRedirectUrls = {};
  bool _hasActivePackage = false;
  bool _onboardingSeen = false;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _refreshToken;

  String? get token => _user?.token;
  String? get refreshToken => _refreshToken;
  UserSession? get user => _user;
  RentalSession? get rental => _rental;
  DateTime? get rentalStartedAt => _rentalStartedAt;
  String? get emotorId => _emotorId;
  String? get emotorImei => _emotorImei;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get emotorProfile => _emotorProfile;
  Map<String, dynamic>? get walletProfile => _walletProfile;
  bool get isVerified => _isVerified;
  int? get walletBalance => _walletBalance;
  String? get customerId => _customerId;
  bool get customerEligible => _customerEligible;
  String get customerVerificationStatus => _customerVerificationStatus;
  DateTime? get membershipExpiresAt => _membershipExpiresAt;
  String? get membershipName => _membershipName;
  String? get dashboardEmotorNumber => _dashboardEmotorNumber;
  int? get dashboardRemainingSeconds => _dashboardRemainingSeconds;
  double? get dashboardEmission => _dashboardEmission;
  int? get dashboardRideRange => _dashboardRideRange;
  String? getPendingSnapToken(String membershipHistoryId) =>
      _pendingSnapTokens[membershipHistoryId];
  String? getPendingRedirectUrl(String membershipHistoryId) =>
      _pendingRedirectUrls[membershipHistoryId];
  bool get hasActivePackage => _hasActivePackage;
  bool get onboardingSeen => _onboardingSeen;

  Future<String> resolveUserId() async {
    final direct = _user?.userId?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    final profileId = _userProfile?['id_user']?.toString().trim() ??
        _userProfile?['user_id']?.toString().trim() ??
        _userProfile?['id']?.toString().trim();
    if (profileId != null && profileId.isNotEmpty) return profileId;
    final secureUserId = await _secureStorage.read(key: _secureKeyUserId);
    if (secureUserId != null && secureUserId.isNotEmpty) {
      return secureUserId;
    }
    return '';
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = await _secureStorage.read(key: _secureKeyAccessToken);
    _refreshToken = await _secureStorage.read(key: _secureKeyRefreshToken);
    final secureUserId = await _secureStorage.read(key: _secureKeyUserId);
    final secureCustomerId =
        await _secureStorage.read(key: _secureKeyCustomerId);
    await prefs.remove(_keyToken);
    if (accessToken != null && accessToken.isNotEmpty) {
      _user = UserSession(
        token: accessToken,
        name: prefs.getString(_keyName) ?? '',
        email: prefs.getString(_keyEmail) ?? '',
        userId: secureUserId,
      );
    } else if (secureUserId != null && secureUserId.isNotEmpty) {
      _user = UserSession(
        token: '',
        name: prefs.getString(_keyName) ?? '',
        email: prefs.getString(_keyEmail) ?? '',
        userId: secureUserId,
      );
    } else {
      _user = null;
    }
    _emotorId = prefs.getString(_keyEmotorId);
    _emotorImei = prefs.getString(_keyEmotorImei);
    _userProfile = _decodeMap(prefs.getString(_keyUserJson));
    _emotorProfile = _decodeMap(prefs.getString(_keyEmotorJson));
    _walletProfile = _decodeMap(prefs.getString(_keyWalletJson));
    _isVerified = prefs.getBool(_keyUserVerified) ??
        _parseVerified(_userProfile) ??
        _parseVerified(_walletProfile) ??
        false;
    _walletBalance = prefs.getInt(_keyWalletBalance) ??
        _parseWalletBalance(_walletProfile) ??
        _parseWalletBalance(_userProfile);
    _customerId = prefs.getString(_keyCustomerId) ??
        secureCustomerId ??
        _parseCustomerId(_userProfile) ??
        _parseCustomerId(_walletProfile);
    _customerVerificationStatus =
        prefs.getString(_keyCustomerVerificationStatus) ??
            _parseCustomerVerificationStatus(_userProfile) ??
            _parseCustomerVerificationStatus(_walletProfile) ??
            'not_verified';
    _customerEligible = _customerVerificationStatus == 'verified';
    if (!_customerEligible) {
      _customerEligible = prefs.getBool(_keyCustomerEligible) ??
          _parseCustomerEligibility(_userProfile) ??
          false;
    }
    _onboardingSeen = prefs.getBool(_keyOnboardingSeen) ?? false;
    final expiresRaw = prefs.getString(_keyMembershipExpiresAt);
    _membershipExpiresAt =
        expiresRaw == null ? null : DateTime.tryParse(expiresRaw);
    _membershipName = prefs.getString(_keyMembershipName);
    _dashboardEmotorNumber = prefs.getString(_keyDashboardEmotorNumber);
    _dashboardRemainingSeconds = prefs.getInt(_keyDashboardRemainingSeconds);
    _dashboardEmission = prefs.getDouble(_keyDashboardEmission);
    _dashboardRideRange = prefs.getInt(_keyDashboardRideRange);
    final pendingRaw = prefs.getString(_keyPendingSnapTokens);
    if (pendingRaw != null && pendingRaw.isNotEmpty) {
      final decoded = _decodeMap(pendingRaw);
      if (decoded != null) {
        _pendingSnapTokens = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
    }
    final pendingRedirectRaw = prefs.getString(_keyPendingRedirectUrls);
    if (pendingRedirectRaw != null && pendingRedirectRaw.isNotEmpty) {
      final decoded = _decodeMap(pendingRedirectRaw);
      if (decoded != null) {
        _pendingRedirectUrls = decoded.map(
          (key, value) => MapEntry(key, value.toString()),
        );
      }
    }
    // Do not persist membership state locally; infer from latest profile only.
    _hasActivePackage =
        _parseHasActivePackage(_userProfile) ??
        _parseHasActivePackage(_walletProfile) ??
        false;
    await prefs.remove(_keyHasActivePackage);
    final rentalJson = _decodeMap(prefs.getString(_keyRentalJson));
    if (rentalJson != null) {
      _rental = RentalSession.fromJson(rentalJson);
    }
    final startedAtMs = prefs.getInt(_keyRentalStartedAt);
    if (startedAtMs != null && startedAtMs > 0) {
      _rentalStartedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
    } else if (rentalJson != null) {
      final fallbackMs = rentalJson['started_at'];
      if (fallbackMs is num && fallbackMs.toInt() > 0) {
        _rentalStartedAt = DateTime.fromMillisecondsSinceEpoch(
          fallbackMs.toInt(),
        );
      }
    }
    if ((_emotorId == null || _emotorId!.isEmpty) && _emotorProfile != null) {
      final id = _emotorProfile?['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        _emotorId = id;
      }
    }
    if ((_emotorImei == null || _emotorImei!.isEmpty) && _emotorProfile != null) {
      final imei = _emotorProfile?['IMEI']?.toString().trim() ??
          _emotorProfile?['imei']?.toString().trim();
      if (imei != null && imei.isNotEmpty) {
        _emotorImei = imei;
      }
    }
    if ((_emotorId == null || _emotorId!.isEmpty) && _userProfile != null) {
      final emotor = _userProfile?['emotor'];
      if (emotor is Map<String, dynamic>) {
        final id = emotor['id']?.toString().trim();
        if (id != null && id.isNotEmpty) {
          _emotorId = id;
        }
      }
    }
    if ((_emotorImei == null || _emotorImei!.isEmpty) && _userProfile != null) {
      final emotor = _userProfile?['emotor'];
      if (emotor is Map<String, dynamic>) {
        final imei =
            emotor['IMEI']?.toString().trim() ?? emotor['imei']?.toString().trim();
        if (imei != null && imei.isNotEmpty) {
          _emotorImei = imei;
        }
      }
    }
  }

  Future<void> saveUser(UserSession session) async {
    _user = session;
    final prefs = await SharedPreferences.getInstance();
    // Do not persist access_token per backend policy.
    await prefs.remove(_keyToken);
    await prefs.setString(_keyName, session.name);
    await prefs.setString(_keyEmail, session.email);
    if (session.userId != null && session.userId!.isNotEmpty) {
      await prefs.setString(_keyUserId, session.userId!);
      await _secureStorage.write(
        key: _secureKeyUserId,
        value: session.userId!,
      );
    } else {
      await prefs.remove(_keyUserId);
    }
  }

  Future<void> setOnboardingSeen(bool value) async {
    _onboardingSeen = value;
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_keyOnboardingSeen, true);
    } else {
      await prefs.remove(_keyOnboardingSeen);
    }
  }

  Future<void> saveToken(String token) async {
    if (token.isEmpty) return;
    final current = _user;
    _user = UserSession(
      token: token,
      name: current?.name ?? '',
      email: current?.email ?? '',
      userId: current?.userId,
    );
    await _secureStorage.write(key: _secureKeyAccessToken, value: token);
  }

  void saveRental(RentalSession session) {
    _rental = session;
    _emotorId ??= session.emotorId;
    unawaited(_saveRentalStorage(session));
  }

  void setRentalStartedAt(DateTime? startedAt) {
    _rentalStartedAt = startedAt;
    unawaited(_saveRentalStartedAt(startedAt));
    final current = _rental;
    if (current != null) {
      unawaited(_saveRentalStorage(current));
    }
  }

  void setHasActivePackage(bool value) {
    _hasActivePackage = value;
  }

  Future<void> setMembershipExpiresAt(DateTime? expiresAt) async {
    _membershipExpiresAt = expiresAt;
    final prefs = await SharedPreferences.getInstance();
    if (expiresAt == null) {
      await prefs.remove(_keyMembershipExpiresAt);
    } else {
      await prefs.setString(_keyMembershipExpiresAt, expiresAt.toIso8601String());
    }
  }

  Future<void> setMembershipName(String? name) async {
    final trimmed = name?.trim() ?? '';
    _membershipName = trimmed.isEmpty ? null : trimmed;
    final prefs = await SharedPreferences.getInstance();
    if (_membershipName == null) {
      await prefs.remove(_keyMembershipName);
    } else {
      await prefs.setString(_keyMembershipName, _membershipName!);
    }
  }

  Future<void> setDashboardData({
    String? emotorNumber,
    int? remainingSeconds,
    double? emissionReduction,
    int? rideRange,
    DateTime? validUntil,
    String? packageName,
  }) async {
    _dashboardEmotorNumber =
        (emotorNumber?.trim().isEmpty ?? true) ? null : emotorNumber!.trim();
    _dashboardRemainingSeconds = remainingSeconds;
    _dashboardEmission = emissionReduction;
    _dashboardRideRange = rideRange;
    if (validUntil != null) {
      _membershipExpiresAt = validUntil;
    }
    if (packageName != null && packageName.trim().isNotEmpty) {
      _membershipName = packageName.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    if (_dashboardEmotorNumber == null) {
      await prefs.remove(_keyDashboardEmotorNumber);
    } else {
      await prefs.setString(
        _keyDashboardEmotorNumber,
        _dashboardEmotorNumber!,
      );
    }
    if (_dashboardRemainingSeconds == null) {
      await prefs.remove(_keyDashboardRemainingSeconds);
    } else {
      await prefs.setInt(
        _keyDashboardRemainingSeconds,
        _dashboardRemainingSeconds!,
      );
    }
    if (_dashboardEmission == null) {
      await prefs.remove(_keyDashboardEmission);
    } else {
      await prefs.setDouble(_keyDashboardEmission, _dashboardEmission!);
    }
    if (_dashboardRideRange == null) {
      await prefs.remove(_keyDashboardRideRange);
    } else {
      await prefs.setInt(_keyDashboardRideRange, _dashboardRideRange!);
    }
    if (validUntil != null) {
      await prefs.setString(
        _keyMembershipExpiresAt,
        validUntil.toIso8601String(),
      );
    }
    if (packageName != null && packageName.trim().isNotEmpty) {
      await prefs.setString(
        _keyMembershipName,
        packageName.trim(),
      );
    }
  }

  Future<void> savePendingSnapToken({
    required String membershipHistoryId,
    required String snapToken,
  }) async {
    if (membershipHistoryId.isEmpty || snapToken.isEmpty) return;
    _pendingSnapTokens[membershipHistoryId] = snapToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPendingSnapTokens,
      jsonEncode(_pendingSnapTokens),
    );
  }

  Future<void> savePendingRedirectUrl({
    required String membershipHistoryId,
    required String redirectUrl,
  }) async {
    if (membershipHistoryId.isEmpty || redirectUrl.isEmpty) return;
    _pendingRedirectUrls[membershipHistoryId] = redirectUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyPendingRedirectUrls,
      jsonEncode(_pendingRedirectUrls),
    );
  }

  Future<void> clearPendingSnapToken(String membershipHistoryId) async {
    if (!_pendingSnapTokens.containsKey(membershipHistoryId)) return;
    _pendingSnapTokens.remove(membershipHistoryId);
    final prefs = await SharedPreferences.getInstance();
    if (_pendingSnapTokens.isEmpty) {
      await prefs.remove(_keyPendingSnapTokens);
    } else {
      await prefs.setString(
        _keyPendingSnapTokens,
        jsonEncode(_pendingSnapTokens),
      );
    }
  }

  Future<void> clearPendingRedirectUrl(String membershipHistoryId) async {
    if (!_pendingRedirectUrls.containsKey(membershipHistoryId)) return;
    _pendingRedirectUrls.remove(membershipHistoryId);
    final prefs = await SharedPreferences.getInstance();
    if (_pendingRedirectUrls.isEmpty) {
      await prefs.remove(_keyPendingRedirectUrls);
    } else {
      await prefs.setString(
        _keyPendingRedirectUrls,
        jsonEncode(_pendingRedirectUrls),
      );
    }
  }

  void clearRental() {
    _rental = null;
    _rentalStartedAt = null;
    unawaited(_clearRentalStorage());
  }

  Future<void> saveEmotorId(String id) async {
    _emotorId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id.isNotEmpty) {
      await prefs.setString(_keyEmotorId, id);
    } else {
      await prefs.remove(_keyEmotorId);
    }
  }

  Future<void> saveEmotorImei(String imei) async {
    _emotorImei = imei;
    final prefs = await SharedPreferences.getInstance();
    if (imei.isNotEmpty) {
      await prefs.setString(_keyEmotorImei, imei);
    } else {
      await prefs.remove(_keyEmotorImei);
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic>? profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyUserJson, profile);
    final verified = _parseVerified(profile);
    if (verified != null) {
      _isVerified = verified;
      await prefs.setBool(_keyUserVerified, verified);
    }
    final balance = _parseWalletBalance(profile);
    if (balance != null) {
      _walletBalance = balance;
      await prefs.setInt(_keyWalletBalance, balance);
    }
    final customerId = _parseCustomerId(profile);
    if (customerId != null && customerId.isNotEmpty) {
      _customerId = customerId;
      await prefs.setString(_keyCustomerId, customerId);
      await _secureStorage.write(
        key: _secureKeyCustomerId,
        value: customerId,
      );
    }
    final eligible = _parseCustomerEligibility(profile);
    final verificationStatus = _parseCustomerVerificationStatus(profile);
    if (verificationStatus != null) {
      _customerVerificationStatus = verificationStatus;
      _customerEligible = verificationStatus == 'verified';
      await prefs.setString(
        _keyCustomerVerificationStatus,
        verificationStatus,
      );
      await prefs.setBool(_keyCustomerEligible, _customerEligible);
    } else if (eligible != null) {
      _customerEligible = eligible;
      await prefs.setBool(_keyCustomerEligible, eligible);
    }
    final active = _parseHasActivePackage(profile);
    if (active != null) {
      _hasActivePackage = active;
    }
    final emotor = profile?['emotor'];
    if (emotor is Map<String, dynamic>) {
      final id = emotor['id']?.toString().trim();
      final imei = emotor['IMEI']?.toString().trim() ?? emotor['imei']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        await saveEmotorId(id);
      }
      if (imei != null && imei.isNotEmpty) {
        await saveEmotorImei(imei);
      }
    }
  }

  Future<void> saveEmotorProfile(Map<String, dynamic>? profile) async {
    _emotorProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyEmotorJson, profile);
    final id = profile?['id']?.toString().trim();
    final imei = profile?['IMEI']?.toString().trim() ?? profile?['imei']?.toString().trim();
    if (id != null && id.isNotEmpty) {
      await saveEmotorId(id);
    }
    if (imei != null && imei.isNotEmpty) {
      await saveEmotorImei(imei);
    }
  }

  Future<void> saveWalletProfile(Map<String, dynamic>? profile) async {
    _walletProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyWalletJson, profile);
    final verified = _parseVerified(profile);
    if (verified != null) {
      _isVerified = verified;
      await prefs.setBool(_keyUserVerified, verified);
    }
    final balance = _parseWalletBalance(profile);
    if (balance != null) {
      _walletBalance = balance;
      await prefs.setInt(_keyWalletBalance, balance);
    }
    final customerId = _parseCustomerId(profile);
    if (customerId != null && customerId.isNotEmpty) {
      _customerId = customerId;
      await prefs.setString(_keyCustomerId, customerId);
      await _secureStorage.write(
        key: _secureKeyCustomerId,
        value: customerId,
      );
    }
    final eligible = _parseCustomerEligibility(profile);
    final verificationStatus = _parseCustomerVerificationStatus(profile);
    if (verificationStatus != null) {
      _customerVerificationStatus = verificationStatus;
      _customerEligible = verificationStatus == 'verified';
      await prefs.setString(
        _keyCustomerVerificationStatus,
        verificationStatus,
      );
      await prefs.setBool(_keyCustomerEligible, _customerEligible);
    } else if (eligible != null) {
      _customerEligible = eligible;
      await prefs.setBool(_keyCustomerEligible, eligible);
    }
    final active = _parseHasActivePackage(profile);
    if (active != null) {
      _hasActivePackage = active;
    }
  }

  void clear() {
    _user = null;
    _rental = null;
    _rentalStartedAt = null;
    _emotorId = null;
    _emotorImei = null;
    _userProfile = null;
    _emotorProfile = null;
    _walletProfile = null;
    _isVerified = false;
    _walletBalance = null;
    _customerId = null;
    _customerEligible = false;
    _customerVerificationStatus = 'not_verified';
    _membershipExpiresAt = null;
    _membershipName = null;
    _dashboardEmotorNumber = null;
    _dashboardRemainingSeconds = null;
    _dashboardEmission = null;
    _dashboardRideRange = null;
    _pendingSnapTokens = {};
    _pendingRedirectUrls = {};
    _refreshToken = null;
    unawaited(_clearStorage());
  }

  void clearAuth() {
    _user = null;
    _userProfile = null;
    _walletProfile = null;
    _isVerified = false;
    _walletBalance = null;
    _customerId = null;
    _customerEligible = false;
    _customerVerificationStatus = 'not_verified';
    _membershipExpiresAt = null;
    _membershipName = null;
    _dashboardEmotorNumber = null;
    _dashboardRemainingSeconds = null;
    _dashboardEmission = null;
    _dashboardRideRange = null;
    _pendingSnapTokens = {};
    _pendingRedirectUrls = {};
    _refreshToken = null;
    unawaited(_clearAuthStorage());
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _secureKeyAccessToken);
    await _secureStorage.delete(key: _secureKeyRefreshToken);
    await _secureStorage.delete(key: _secureKeyUserId);
    await _secureStorage.delete(key: _secureKeyCustomerId);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmotorId);
    await prefs.remove(_keyEmotorImei);
    await prefs.remove(_keyUserJson);
    await prefs.remove(_keyEmotorJson);
    await prefs.remove(_keyWalletJson);
    await prefs.remove(_keyUserVerified);
    await prefs.remove(_keyWalletBalance);
    await prefs.remove(_keyOnboardingSeen);
    await prefs.remove(_keyCustomerId);
    await prefs.remove(_keyCustomerEligible);
    await prefs.remove(_keyCustomerVerificationStatus);
    await prefs.remove(_keyMembershipExpiresAt);
    await prefs.remove(_keyMembershipName);
    await prefs.remove(_keyDashboardEmotorNumber);
    await prefs.remove(_keyDashboardRemainingSeconds);
    await prefs.remove(_keyDashboardEmission);
    await prefs.remove(_keyDashboardRideRange);
    await prefs.remove(_keyPendingSnapTokens);
    await prefs.remove(_keyPendingRedirectUrls);
    await prefs.remove(_keyRentalJson);
    await prefs.remove(_keyRentalStartedAt);
  }

  Future<void> _clearAuthStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _secureKeyAccessToken);
    await _secureStorage.delete(key: _secureKeyRefreshToken);
    await _secureStorage.delete(key: _secureKeyCustomerId);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserJson);
    await prefs.remove(_keyWalletJson);
    await prefs.remove(_keyUserVerified);
    await prefs.remove(_keyWalletBalance);
    // Keep onboarding flag on auth clear.
    await prefs.remove(_keyCustomerId);
    await prefs.remove(_keyCustomerEligible);
    await prefs.remove(_keyCustomerVerificationStatus);
    await prefs.remove(_keyMembershipExpiresAt);
    await prefs.remove(_keyMembershipName);
    await prefs.remove(_keyDashboardEmotorNumber);
    await prefs.remove(_keyDashboardRemainingSeconds);
    await prefs.remove(_keyDashboardEmission);
    await prefs.remove(_keyDashboardRideRange);
    await prefs.remove(_keyPendingSnapTokens);
    await prefs.remove(_keyPendingRedirectUrls);
  }

  Future<void> saveRefreshToken(String token) async {
    if (token.isEmpty) return;
    _refreshToken = token;
    await _secureStorage.write(key: _secureKeyRefreshToken, value: token);
  }

  Future<void> setCustomerVerificationStatus(String? raw) async {
    final normalized = _normalizeVerificationStatus(raw);
    if (normalized == null) return;
    _customerVerificationStatus = normalized;
    _customerEligible = normalized == 'verified';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomerVerificationStatus, normalized);
    await prefs.setBool(_keyCustomerEligible, _customerEligible);
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> _saveMap(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic>? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(value));
  }

  Future<void> _saveRentalStorage(RentalSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyRentalJson,
      jsonEncode({
        'id': session.id,
        'emotorId': session.emotorId,
        'plate': session.plate,
        'range_km': session.rangeKm,
        'battery_percent': session.batteryPercent,
        'motor_on': session.motorOn,
        'rideHistoryId': session.rideHistoryId,
        if (_rentalStartedAt != null)
          'started_at': _rentalStartedAt!.millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> _saveRentalStartedAt(DateTime? startedAt) async {
    final prefs = await SharedPreferences.getInstance();
    if (startedAt == null) {
      await prefs.remove(_keyRentalStartedAt);
      return;
    }
    await prefs.setInt(_keyRentalStartedAt, startedAt.millisecondsSinceEpoch);
  }

  Future<void> _clearRentalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRentalJson);
    await prefs.remove(_keyRentalStartedAt);
  }

  bool? _parseVerified(Map<String, dynamic>? data) {
    if (data == null) return null;
    final keys = {
      'verified',
      'is_verified',
      'isverified',
      'verify_status',
      'document_verified',
      'documentverified',
      'kyc_verified',
      'kycverified',
      'verification_status',
      'status_verifikasi',
      'statusverifikasi',
    };
    bool? walk(dynamic value) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        for (final entry in value.entries) {
          final key = entry.key.toString().toLowerCase();
          if (keys.contains(key) || key.contains('verify_status')) {
            final parsed = _parseBool(entry.value);
            if (parsed != null) return parsed;
          }
          final nested = walk(entry.value);
          if (nested != null) return nested;
        }
      } else if (value is List) {
        for (final item in value) {
          final nested = walk(item);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return walk(data);
  }

  int? _parseWalletBalance(Map<String, dynamic>? data) {
    if (data == null) return null;
    final keys = [
      'balance',
      'saldo',
      'amount',
      'current_balance',
      'currentBalance',
      'balance_amount',
      'balanceAmount',
      'wallet_balance',
      'walletBalance',
      'total',
    ];
    for (final key in keys) {
      final value = data[key];
      final parsed = _parseInt(value);
      if (parsed != null) return parsed;
    }
    final wallet = data['wallet'];
    if (wallet is Map<String, dynamic>) {
      return _parseWalletBalance(wallet);
    }
    final customer = data['Customer'] ?? data['customer'];
    if (customer is Map<String, dynamic>) {
      final customerWallet =
          customer['CustomerWallet'] ?? customer['customerWallet'] ?? customer['customer_wallet'];
      if (customerWallet is Map<String, dynamic>) {
        return _parseWalletBalance(customerWallet);
      }
    }
    return null;
  }

  bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      if (text.isEmpty) return null;
      if (text == 'true' || text == 'yes' || text == 'y' || text == '1') {
        return true;
      }
      if (text == 'false' || text == 'no' || text == 'n' || text == '0') {
        return false;
      }
      if (text == 'verified' || text == 'active' || text == 'approved') {
        return true;
      }
      if (text == 'unverified' || text == 'inactive' || text == 'rejected') {
        return false;
      }
    }
    return null;
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isEmpty) return null;
      return int.tryParse(cleaned);
    }
    return null;
  }

  bool? _parseHasActivePackage(Map<String, dynamic>? data) {
    if (data == null) return null;
    final keys = [
      'has_active_package',
      'hasActivePackage',
      'active_package',
      'activePackage',
      'membership_active',
      'membershipActive',
      'is_membership_active',
      'isMembershipActive',
      'subscription_active',
      'subscriptionActive',
      'package_active',
      'packageActive',
      'membership',
      'subscription',
    ];
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) {
        final nested = _parseHasActivePackage(value);
        if (nested != null) return nested;
        continue;
      }
      final parsed = _parseBool(value);
      if (parsed != null) return parsed;
    }
    final status = data['membership_status'] ??
        data['membershipStatus'] ??
        data['status_membership'] ??
        data['subscription_status'] ??
        data['subscriptionStatus'];
    final statusParsed = _parseBool(status);
    if (statusParsed != null) return statusParsed;
    final expires = data['membership_expires_at'] ??
        data['membershipExpiresAt'] ??
        data['subscription_expires_at'] ??
        data['subscriptionExpiresAt'] ??
        data['expired_at'] ??
        data['expiredAt'] ??
        data['valid_until'] ??
        data['validUntil'];
    if (expires != null) {
      final parsedDate = DateTime.tryParse(expires.toString());
      if (parsedDate != null) {
        return parsedDate.isAfter(DateTime.now());
      }
    }
    return null;
  }

  String? _parseCustomerId(Map<String, dynamic>? data) {
    if (data == null) return null;
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final direct = read(data['customer_id']) ??
        read(data['customerId']) ??
        read(data['id_customer']);
    if (direct != null) return direct;
    final customer = data['Customer'] ?? data['customer'];
    if (customer is Map<String, dynamic>) {
      return read(customer['id']) ??
          read(customer['customer_id']) ??
          read(customer['id_customer']);
    }
    return null;
  }

  bool? _parseCustomerEligibility(Map<String, dynamic>? data) {
    if (data == null) return null;
    Map<String, dynamic>? customer;
    final raw = data['Customer'] ?? data['customer'];
    if (raw is Map<String, dynamic>) {
      customer = raw;
    }
    bool? parse(dynamic value) => _parseBool(value);
    final cert = customer?['certification_status'] ?? customer?['certificationStatus'];
    final status = customer?['status'];
    final certParsed = parse(cert);
    if (certParsed != null) return certParsed;
    final statusParsed = parse(status);
    if (statusParsed != null) return statusParsed;
    if (cert != null) {
      final text = cert.toString().toLowerCase();
      if (text.contains('verified') || text.contains('approved')) return true;
      if (text.contains('pending') || text.contains('reject')) return false;
    }
    if (status != null) {
      final text = status.toString().toLowerCase();
      if (text.contains('active') || text.contains('verified')) return true;
      if (text.contains('inactive') || text.contains('pending')) return false;
    }
    return null;
  }

  String? _parseCustomerVerificationStatus(Map<String, dynamic>? data) {
    if (data == null) return null;
    Map<String, dynamic>? customer;
    final raw = data['Customer'] ?? data['customer'];
    if (raw is Map<String, dynamic>) {
      customer = raw;
    }

    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final cert = read(customer?['certification_status'] ??
        customer?['certificationStatus'] ??
        data['certification_status'] ??
        data['certificationStatus']);
    final normalized = _normalizeVerificationStatus(cert);
    if (normalized != null) return normalized;
    final verify = data['verify_status'] ??
        data['verified'] ??
        data['is_verified'] ??
        customer?['verify_status'];

    if (verify is bool) {
      return verify ? 'verified' : 'not_verified';
    }
    if (verify != null) {
      final text = verify.toString().toLowerCase();
      if (text == 'true' || text == '1') return 'verified';
      if (text == 'false' || text == '0') return 'not_verified';
    }
    return null;
  }

  String? _normalizeVerificationStatus(String? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    if (text.contains('real_name') ||
        text.contains('verified') ||
        text.contains('approved')) {
      return 'verified';
    }
    if (text.contains('under_review') ||
        text.contains('under review') ||
        text.contains('pending') ||
        text.contains('review')) {
      return 'under_review';
    }
    if (text.contains('audit_failed') ||
        text.contains('rejected') ||
        text.contains('not_certified') ||
        text.contains('unverified')) {
      return 'not_verified';
    }
    return null;
  }
}
