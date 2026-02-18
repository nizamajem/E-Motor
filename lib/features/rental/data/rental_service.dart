import 'dart:async';
import 'dart:convert';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';
import '../../history/data/history_service.dart';
import '../../history/data/history_models.dart';
import 'emotor_service.dart';
import 'package:flutter/foundation.dart';

class RideStatus {
  RideStatus({
    required this.motorOn,
    required this.rangeKm,
    required this.pingQuality,
    required this.rentalMinutes,
    required this.carbonReduction,
    required this.rideSeconds,
    required this.carbonEmissions,
    required this.calories,
    required this.hasMotorState,
    required this.isEnded,
    this.startedAt,
    this.endedAt,
    this.plate,
    this.batteryPercent,
  });

  factory RideStatus.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map<String, dynamic> ? value : null;
    final bike = asMap(json['bike']);
    final emotor = asMap(json['eMotor']) ?? asMap(json['emotor']);
    final merged = <String, dynamic>{
      ...json,
      if (bike != null) ...bike,
      if (emotor != null) ...emotor,
    };
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final statusStr = (merged['status'] ?? merged['bike_status'] ?? '')
        .toString();
    final hasStatusText = statusStr.isNotEmpty;
    final hasMotorState =
        merged.containsKey('motor_on') ||
        merged.containsKey('motorOn') ||
        merged.containsKey('is_active') ||
        hasStatusText;
    final isAccOn = statusStr.toUpperCase().contains('ON');
    final rawRideSeconds = merged['ride_time_seconds'] ?? merged['ride_time'];
    var rideSeconds = toDouble(rawRideSeconds);
    // Some backends send milliseconds; normalize to seconds if value is huge.
    if (rawRideSeconds != null && rideSeconds > 100000) {
      rideSeconds = rideSeconds / 1000;
    }
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      if (text.isEmpty) return null;
      return DateTime.tryParse(text);
    }

    final startAt = parseDate(
      merged['start_position_time'] ??
          merged['start_date_time'] ??
          merged['start_time'],
    );
    final endAt = parseDate(
      merged['end_position_time'] ??
          merged['end_date_time'] ??
          merged['end_time'],
    );
    final isEnded =
        merged['is_end'] == true ||
        merged['isEnded'] == true ||
        merged['ended'] == true ||
        merged['ride_ended'] == true ||
        merged['finish'] == true;

    final carbon = toDouble(
      merged['carbon_emissions'] ??
          merged['carbon_reduction'] ??
          merged['carbonReduction'] ??
          merged['carbon_reduction_grams'] ??
          merged['co2_saved'] ??
          merged['co2'] ??
          merged['carbon'],
    );
    final calories = toDouble(merged['calories']);
    final distanceMeters = toDouble(
      merged['total_distance_meters'] ??
          merged['distance_m'] ??
          merged['distance'],
    );
    final power =
        merged['power'] ??
        merged['battery'] ??
        merged['battery_percent'] ??
        merged['batteryPercent'];
    final signal =
        merged['signalDbm'] ??
        merged['signal_dbm'] ??
        merged['signal'] ??
        merged['signal_strength'];
    final plate =
        merged['vehicle_number'] ?? merged['plate'] ?? merged['license_plate'];
    final signalDbm = signal is num
        ? signal.toDouble()
        : double.tryParse(signal?.toString() ?? '');
    return RideStatus(
      motorOn:
          merged['motor_on'] == true ||
          merged['motorOn'] == true ||
          merged['is_active'] == true ||
          isAccOn,
      rangeKm: toDouble(
        merged['range_km'] ?? merged['range'] ?? distanceMeters / 1000,
      ),
      pingQuality: signalDbm == null
          ? (merged['ping']?.toString() ?? 'Unknown')
          : '${signalDbm.toStringAsFixed(0)} dBm',
      rentalMinutes: rideSeconds == 0 ? 0 : (rideSeconds / 60).round(),
      carbonReduction: carbon,
      rideSeconds: rideSeconds.round(),
      carbonEmissions: carbon,
      calories: calories,
      hasMotorState: hasMotorState,
      isEnded: isEnded,
      startedAt: startAt,
      endedAt: endAt,
      plate: plate?.toString(),
      batteryPercent: power == null ? null : toDouble(power),
    );
  }

  final bool motorOn;
  final double rangeKm;
  final String pingQuality;
  final int rentalMinutes;
  final double carbonReduction;
  final int rideSeconds;
  final double carbonEmissions;
  final double calories;
  final bool hasMotorState;
  final bool isEnded;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? plate;
  final double? batteryPercent;
}

class RentalService {
  RentalService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  String? _findStringByKey(Map<String, dynamic> map, List<String> keys) {
    for (final entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (keys.any((k) => key.contains(k))) {
        if (value is String && value.isNotEmpty) return value;
        if (value != null && value.toString().isNotEmpty)
          return value.toString();
      }
      if (value is Map<String, dynamic>) {
        final nested = _findStringByKey(value, keys);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findMapByKey(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    for (final entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      if (keys.any((k) => key.contains(k)) && value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map<String, dynamic>) {
        final nested = _findMapByKey(value, keys);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final body = <String, dynamic>{'username': username, 'password': password};
    final res = await _client.postJson(ApiConfig.loginPath, body: body);
    debugPrint('login response: $res');

    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : null;
    final tokenForLog =
        _findStringByKey(
          {...res, if (data != null) ...data},
          ['access_token', 'token', 'access'],
        ) ??
        '';
    if (tokenForLog.isNotEmpty) {
      _logTokenTimes('login', tokenForLog);
    }
    final rootUser = res['user'] is Map<String, dynamic>
        ? res['user'] as Map<String, dynamic>
        : null;
    final dataUser = data != null && data['user'] is Map<String, dynamic>
        ? data['user'] as Map<String, dynamic>
        : null;
    final user = rootUser ?? dataUser;
    final token =
        _findStringByKey(
          {...res, if (data != null) ...data},
          ['access_token', 'token', 'access'],
        ) ??
        '';
    final refreshToken =
        _findStringByKey(
          {...res, if (data != null) ...data},
          ['refresh_token', 'refreshToken'],
        ) ??
        '';
    final name =
        _findStringByKey({...res, if (data != null) ...data}, ['name']) ??
        username;
    final email =
        _findStringByKey({...res, if (data != null) ...data}, ['email']) ??
        username;
    final userId =
        user?['id_user']?.toString().trim() ??
        user?['user_id']?.toString().trim() ??
        user?['id']?.toString().trim() ??
        _findStringByKey(
          {...res, if (data != null) ...data},
          ['userid', 'user_id', 'id'],
        );

    debugPrint('===== LOGIN SUCCESS =====');
    debugPrint('Access token length: ${token.length}');
    debugPrint('Refresh token length: ${refreshToken.length}');
    debugPrint('==============================');
    debugPrint('✅ LOGIN SUCCESS');
    debugPrint('Access Token: $token');
    debugPrint('Refresh Token: $refreshToken');
    _logTokenTimes('login-access', token);

    _logTokenTimes('login-access', token);

    if (refreshToken.isNotEmpty) {
      _logTokenTimes('login-refresh', refreshToken);
    }

    final emotorFromUser = user?['emotor'] ?? user?['eMotor'];
    final emotorFromData = data?['emotor'] ?? data?['eMotor'];
    final emotorMap = (emotorFromUser is Map<String, dynamic>)
        ? emotorFromUser
        : (emotorFromData is Map<String, dynamic>)
        ? emotorFromData
        : _findMapByKey({...res, if (data != null) ...data}, ['emotor']);
    final emotorId =
        emotorMap?['id']?.toString().trim() ??
        emotorMap?['emotorId']?.toString().trim() ??
        emotorMap?['emotor_id']?.toString().trim() ??
        _findStringByKey(
          {...res, if (data != null) ...data},
          ['emotorid', 'emotor_id'],
        );
    final emotorImei =
        emotorMap?['IMEI']?.toString().trim() ??
        emotorMap?['imei']?.toString().trim() ??
        _findStringByKey({...res, if (data != null) ...data}, ['imei']);
    final walletFromUser = user?['customerWallet'] ?? user?['customer_wallet'];
    final walletFromData = data?['customerWallet'] ?? data?['customer_wallet'];
    final walletMap = (walletFromUser is Map<String, dynamic>)
        ? walletFromUser
        : (walletFromData is Map<String, dynamic>)
        ? walletFromData
        : _findMapByKey(
            {...res, if (data != null) ...data},
            ['customerwallet', 'customer_wallet', 'wallet'],
          );
    debugPrint(
      'login parsed userId=$userId emotorId=$emotorId emotorImei=$emotorImei',
    );
    if (token.isEmpty) {
      throw ApiException(
        'Token kosong dari server, pastikan endpoint login-emotor benar.',
      );
    }

    final session = UserSession(
      token: token,
      name: name,
      email: email,
      userId: userId,
    );
    final previousUserId =
        SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim();
    if (previousUserId != null &&
        previousUserId.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty &&
        previousUserId != userId) {
      SessionManager.instance.clearRental();
    }
    await SessionManager.instance.saveUser(session);
    await SessionManager.instance.saveToken(token);
    if (refreshToken.isNotEmpty) {
      await SessionManager.instance.saveRefreshToken(refreshToken);
    }
    if (user != null) {
      await SessionManager.instance.saveUserProfile(user);
    }
    if (emotorMap != null) {
      await SessionManager.instance.saveEmotorProfile(emotorMap);
    }
    if (walletMap != null) {
      await SessionManager.instance.saveWalletProfile(walletMap);
    }
    if (emotorId != null && emotorId.isNotEmpty) {
      await SessionManager.instance.saveEmotorId(emotorId);
    }
    if (emotorImei != null && emotorImei.isNotEmpty) {
      await SessionManager.instance.saveEmotorImei(emotorImei);
    }
    return session;
  }

  void _logTokenTimes(String label, String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;
      var payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (decoded is! Map<String, dynamic>) return;
      final iat = decoded['iat'];
      final exp = decoded['exp'];
      debugPrint('token($label) iat=$iat exp=$exp');
    } catch (_) {}
  }

  Future<RentalSession> startRental() async {
    final userId =
        SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim() ??
        '';
    if (userId.isEmpty) {
      throw ApiException('UserId tidak ditemukan. Silakan login ulang.');
    }
    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']
        ?.toString()
        .trim();
    final emotorIdFromUser =
        (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor']
                  as Map<String, dynamic>)['id']
              ?.toString()
              .trim()
        : null;
    final emotorId = (SessionManager.instance.emotorId ?? '').isNotEmpty
        ? SessionManager.instance.emotorId!
        : (emotorIdFromProfile != null && emotorIdFromProfile.isNotEmpty)
        ? emotorIdFromProfile
        : (emotorIdFromUser != null && emotorIdFromUser.isNotEmpty)
        ? emotorIdFromUser
        : ApiConfig.emotorId.isNotEmpty
        ? ApiConfig.emotorId
        : SessionManager.instance.rental?.emotorId ?? '';
    debugPrint(
      'startRental emotorId=$emotorId sessionEmotorId=${SessionManager.instance.emotorId}',
    );
    if (emotorId.isEmpty) {
      throw ApiException(
        'EMOTOR_ID belum diset. Jalankan dengan --dart-define=EMOTOR_ID=xxx atau simpan di session.',
      );
    }
    if ((SessionManager.instance.emotorId ?? '').isEmpty) {
      await SessionManager.instance.saveEmotorId(emotorId);
    }

    final res = await _client.postJson(
      ApiConfig.startRentalPath,
      auth: true,
      body: {'userId': userId, 'emotorId': emotorId},
    );
    final rentalPayload = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    var rental = RentalSession.fromJson(rentalPayload);
    final localStart = DateTime.now();
    if (rental.emotorId.isEmpty && emotorId.isNotEmpty) {
      rental = RentalSession(
        id: rental.id,
        emotorId: emotorId,
        plate: rental.plate,
        rangeKm: rental.rangeKm,
        batteryPercent: rental.batteryPercent,
        motorOn: rental.motorOn,
        rideHistoryId: rental.rideHistoryId,
      );
    }
    SessionManager.instance.saveRental(rental);
    SessionManager.instance.setRentalStartedAt(localStart);
    return rental;
  }

  Future<bool> toggleMotor(bool enable) async {
    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']
        ?.toString()
        .trim();
    final emotorIdFromUser =
        (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor']
                  as Map<String, dynamic>)['id']
              ?.toString()
              .trim()
        : null;
    final emotorId =
        SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        (emotorIdFromProfile != null && emotorIdFromProfile.isNotEmpty
            ? emotorIdFromProfile
            : null) ??
        (emotorIdFromUser != null && emotorIdFromUser.isNotEmpty
            ? emotorIdFromUser
            : null) ??
        ApiConfig.emotorId;
    if (emotorId.isEmpty) {
      throw ApiException('Tidak ada emotorId untuk kirim perintah ACC.');
    }
    final res = await _client.postJson(
      ApiConfig.accCommandPath,
      auth: true,
      body: {
        'ids': [emotorId],
        'enable': enable,
      },
    );
    if (res['ok'] == true) return true;
    final matched = res['matched'];
    if (matched is num && matched > 0) return true;
    return false;
  }

  Future<bool> findEmotor() async {
    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']
        ?.toString()
        .trim();
    final emotorIdFromUser =
        (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor']
                  as Map<String, dynamic>)['id']
              ?.toString()
              .trim()
        : null;
    final emotorId =
        SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        (emotorIdFromProfile != null && emotorIdFromProfile.isNotEmpty
            ? emotorIdFromProfile
            : null) ??
        (emotorIdFromUser != null && emotorIdFromUser.isNotEmpty
            ? emotorIdFromUser
            : null) ??
        ApiConfig.emotorId;
    if (emotorId.isEmpty) {
      throw ApiException('Tidak ada emotorId untuk perintah find.');
    }
    final res = await _client.postJson(
      ApiConfig.findCommandPath,
      auth: true,
      body: {
        'ids': [emotorId],
      },
    );
    if (res['ok'] == true) return true;
    final matched = res['matched'];
    if (matched is num && matched > 0) return true;
    return false;
  }

  Future<RideStatus> fetchStatus() async {
    final rental = SessionManager.instance.rental;

    String? clean(String? v) {
      if (v == null) return null;
      final t = v.trim();
      return t.isEmpty ? null : t;
    }

    final rideId = clean(rental?.rideHistoryId);
    final emotorId =
        clean(rental?.emotorId) ?? clean(SessionManager.instance.emotorId);

    final imei = clean(SessionManager.instance.emotorImei);

    // 🔥 PRIORITY 1 → rideId
    if (rideId != null) {
      return fetchStatusById(rideId);
    }

    // 🔥 PRIORITY 2 → emotorId
    if (emotorId != null) {
      debugPrint('fetchStatus → using emotorId=$emotorId');

      final res = await _client.getJson(
        '${ApiConfig.emotorByIdPath}/$emotorId',
        auth: true,
      );

      final payload = res['data'] is Map<String, dynamic> ? res['data'] : res;

      return RideStatus.fromJson(payload);
    }

    // 🔥 PRIORITY 3 → IMEI
    if (imei != null) {
      debugPrint('fetchStatus → using IMEI=$imei');

      final res = await _client.getJson(
        '${ApiConfig.emotorByIdPath}/imei/$imei',
        auth: true,
      );

      final payload = res['data'] is Map<String, dynamic> ? res['data'] : res;

      return RideStatus.fromJson(payload);
    }

    debugPrint('⛔ fetchStatus aborted → no identifier ready');
    throw ApiException('No emotor identifier available');
  }

  Future<RideStatus> fetchStatusById(String rideId) async {
    final res = await _client.getJson(
      '${ApiConfig.historyByIdPath}/$rideId',
      auth: true,
    );
    final payload = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    return RideStatus.fromJson(payload);
  }

  Stream<RideStatus> statusStream({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      await Future.delayed(interval);

      final rental = SessionManager.instance.rental;
      if (rental == null || (rental.rideHistoryId ?? '').trim().isEmpty) {
        debugPrint('⛔ statusStream stopped → no active ride');
        break;
      }

      try {
        yield await fetchStatus();
      } catch (e) {
        debugPrint('⚠️ statusStream error ignored: $e');
      }
    }
  }

  Future<String> endRental() async {
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    final userId = SessionManager.instance.user?.userId ?? '';
    if (userId.isEmpty) {
      throw ApiException('UserId tidak ditemukan. Silakan login ulang.');
    }
    final emotorId =
        SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        ApiConfig.emotorId;
    final emotorImei = SessionManager.instance.emotorImei ?? '';
    if ((rideId == null || rideId.isEmpty) &&
        emotorId.isEmpty &&
        emotorImei.isEmpty) {
      throw ApiException(
        'Tidak ada rideId, emotorId, atau IMEI untuk diakhiri.',
      );
    }
    debugPrint('==============================');
    debugPrint('🔥 END RENTAL API CALL');
    debugPrint('userId = $userId');
    debugPrint('rideId = $rideId');
    debugPrint('emotorId = $emotorId');
    debugPrint('imei = $emotorImei');

    final body = {
      'userId': userId,
      if (emotorImei.isNotEmpty)
        'imei': emotorImei
      else if (emotorId.isNotEmpty)
        'emotorId': emotorId,
    };

    debugPrint('📤 END RENTAL REQUEST BODY: $body');

    final res = await _client.postJson(
      ApiConfig.endRentalPath,
      auth: true,
      body: body,
    );

    debugPrint('📥 END RENTAL RESPONSE: $res');

    final ride = res['ride'] is Map<String, dynamic>
        ? res['ride'] as Map<String, dynamic>
        : null;
    final endedId = ride?['id']?.toString();
    final fallbackId = (rideId != null && rideId.isNotEmpty)
        ? rideId
        : (emotorImei.isNotEmpty ? emotorImei : emotorId);
    return (endedId != null && endedId.isNotEmpty) ? endedId : fallbackId;
  }

  Future<void> logout() async {
    try {
      await _client.postJson(ApiConfig.logoutPath, auth: true);
    } finally {
      SessionManager.instance.clear();
    }
  }

  Future<void> runFullFlow({
    required String username,
    required String password,
    Duration stepDelay = const Duration(milliseconds: 600),
  }) async {
    Future<void> waitStep() async {
      if (stepDelay > Duration.zero) {
        await Future<void>.delayed(stepDelay);
      }
    }

    await login(username: username, password: password);
    await waitStep();
    await startRental();
    await waitStep();
    await fetchStatus();
    await waitStep();
    await toggleMotor(true);
    await waitStep();
    await toggleMotor(false);
    await waitStep();
    final endedId = await endRental();
    await waitStep();
    await fetchStatusById(endedId);
    await waitStep();
    await logout();
  }

  Future<RentalSession?> restoreActiveRental() async {
    final token = SessionManager.instance.token;
    if (token == null || token.isEmpty) return null;
    final existing = SessionManager.instance.rental;

    final entries = await HistoryService().fetchHistory();
    final activeEntries = entries.where((entry) => entry.isActive).toList();

    String normalizePlate(String? value) {
      if (value == null) return '';
      return value.replaceAll(RegExp(r'\\s+'), '').toUpperCase();
    }

    final emotorProfile = SessionManager.instance.emotorProfile;
    final emotorFromUser = SessionManager.instance.userProfile?['emotor'];
    var preferredPlate = normalizePlate(
      emotorProfile?['vehicle_number']?.toString() ??
          emotorProfile?['plate']?.toString() ??
          emotorProfile?['license_plate']?.toString() ??
          (emotorFromUser is Map<String, dynamic>
              ? (emotorFromUser['vehicle_number']?.toString() ??
                    emotorFromUser['plate']?.toString() ??
                    emotorFromUser['license_plate']?.toString())
              : null),
    );
    String? preferredEmotorId = emotorProfile?['id']?.toString().trim();
    final userId =
        SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim();
    Emotor? assigned;
    if (userId != null && userId.isNotEmpty) {
      assigned = await EmotorService().fetchAssignedToUser(userId);
      if (assigned != null) {
        preferredPlate = normalizePlate(assigned.plate);
        preferredEmotorId = assigned.id;
      }
    }
    debugPrint(
      'restoreActiveRental: existingPlate=${existing?.plate} existingEmotorId=${existing?.emotorId} '
      'assignedPlate=${assigned?.plate} assignedEmotorId=${assigned?.id} assignedStatus=${assigned?.status} '
      'preferredPlate=$preferredPlate activeEntries=${activeEntries.length} totalHistory=${entries.length}',
    );
    if (existing != null) {
      if (assigned != null) {
        final normalizedExistingPlate = normalizePlate(existing.plate);
        if (normalizedExistingPlate != preferredPlate ||
            (preferredEmotorId != null &&
                preferredEmotorId.isNotEmpty &&
                existing.emotorId != preferredEmotorId)) {
          final updated = RentalSession(
            id: existing.id,
            emotorId: preferredEmotorId ?? existing.emotorId,
            plate: assigned.plate,
            rangeKm: existing.rangeKm,
            batteryPercent: existing.batteryPercent,
            motorOn: existing.motorOn,
            rideHistoryId: existing.rideHistoryId,
          );
          SessionManager.instance.saveRental(updated);
          return updated;
        }
      }
      return existing;
    }

    HistoryEntry? active;
    if (activeEntries.isNotEmpty) {
      if (preferredPlate.isNotEmpty) {
        active = activeEntries.firstWhere(
          (entry) => normalizePlate(entry.plate) == preferredPlate,
          orElse: () => activeEntries.first,
        );
      } else {
        active = activeEntries.first;
      }
    }
    final emotorInUse = assigned?.isInUse == true;
    if (active == null && !emotorInUse) return null;

    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']
        ?.toString()
        .trim();
    final emotorIdFromUser =
        (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor']
                  as Map<String, dynamic>)['id']
              ?.toString()
              .trim()
        : null;
    final emotorId = (preferredEmotorId != null && preferredEmotorId.isNotEmpty)
        ? preferredEmotorId
        : SessionManager.instance.emotorId ??
              (emotorIdFromProfile != null && emotorIdFromProfile.isNotEmpty
                  ? emotorIdFromProfile
                  : null) ??
              (emotorIdFromUser != null && emotorIdFromUser.isNotEmpty
                  ? emotorIdFromUser
                  : null) ??
              ApiConfig.emotorId;
    if (emotorId.isEmpty) return null;

    debugPrint(
      'restoreActiveRental: selectedPlate=${active?.plate} selectedRideId=${active?.id} '
      'resolvedEmotorId=$emotorId activeStart=${active?.startDate} activeEnd=${active?.endDate}',
    );

    debugPrint('RESTORE → final emotorId=$emotorId');

    final rental = RentalSession(
      id: emotorId,
      emotorId: emotorId,
      plate: active?.plate ?? (assigned?.plate ?? '-'),
      rangeKm: 0,
      batteryPercent: 0,
      motorOn: false,
      rideHistoryId: active?.id,
    );
    SessionManager.instance.saveRental(rental);
    if (SessionManager.instance.rentalStartedAt == null &&
        active?.startDate != null) {
      SessionManager.instance.setRentalStartedAt(active!.startDate);
    }

    return rental;
  }

  Future<String?> forceEndRental({
    String? rideId,
    String? reason,
    String? forcedBy,
  }) async {
    final emotorId =
        SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        ApiConfig.emotorId;
    final emotorImei = SessionManager.instance.emotorImei ?? '';
    final body = <String, dynamic>{
      if (rideId != null && rideId.isNotEmpty) 'rideId': rideId,
      if ((rideId == null || rideId.isEmpty) && emotorId.isNotEmpty)
        'emotorId': emotorId,
      if ((rideId == null || rideId.isEmpty) &&
          emotorId.isEmpty &&
          emotorImei.isNotEmpty)
        'imei': emotorImei,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (forcedBy != null && forcedBy.isNotEmpty) 'forcedBy': forcedBy,
    };
    if (!body.containsKey('rideId') &&
        !body.containsKey('emotorId') &&
        !body.containsKey('imei')) {
      return null;
    }
    final res = await _client.postJson(
      ApiConfig.forceEndRentalPath,
      auth: true,
      body: body,
    );
    final ride = res['ride'] is Map<String, dynamic>
        ? res['ride'] as Map<String, dynamic>
        : null;
    return ride?['id']?.toString() ?? rideId ?? emotorId;
  }

  Future<DashboardRefresh> refreshDashboard() async {
    final userId =
        SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim();

    if (userId == null || userId.isEmpty) {
      throw ApiException('UserId not found');
    }

    final res = await _client.getJson(
      ApiConfig.refreshDashboard(userId),
      auth: true,
    );

    final payload = res['data'] is Map<String, dynamic> ? res['data'] : res;

    return DashboardRefresh.fromJson(payload);
  }
}

class DashboardRefresh {
  DashboardRefresh({
    required this.emotorNumber,
    required this.packageName,
    required this.membershipDurationRemaining,
    required this.membershipValidUntil,
    required this.emissionReduction,
    required this.rideRange,
  });

  factory DashboardRefresh.fromJson(Map<String, dynamic> json) {
    return DashboardRefresh(
      emotorNumber: json['emotorNumber']?.toString() ?? '-',
      packageName: json['packageName']?.toString() ?? '',
      membershipDurationRemaining:
          (json['membershipDurationRemaining'] ?? 0) as int,
      membershipValidUntil: DateTime.tryParse(
        json['membershipValidUntil'] ?? '',
      ),
      emissionReduction: (json['emissionReduction'] ?? 0).toDouble(),
      rideRange: (json['rideRange'] ?? 0).toDouble(),
    );
  }

  final String emotorNumber;
  final String packageName;
  final int membershipDurationRemaining;
  final DateTime? membershipValidUntil;
  final double emissionReduction;
  final double rideRange;
}
