import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/localization/app_localizations.dart';
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

    final statusStr =
        (merged['status'] ?? merged['bike_status'] ?? '').toString();
    final hasStatusText = statusStr.isNotEmpty;
    final hasMotorState =
        merged.containsKey('motor_on') ||
        merged.containsKey('motorOn') ||
        merged.containsKey('is_active') ||
        hasStatusText;
    final isAccOn = statusStr.toUpperCase().contains('ON');
    final rideSeconds =
        toDouble(merged['ride_time_seconds'] ?? merged['ride_time']);
    final carbon =
        toDouble(merged['carbon_emissions'] ?? merged['carbon_reduction']);
    final calories = toDouble(merged['calories']);
    final distanceMeters = toDouble(merged['total_distance_meters'] ??
        merged['distance_m'] ??
        merged['distance']);
    final power = merged['power'] ??
        merged['battery'] ??
        merged['battery_percent'] ??
        merged['batteryPercent'];
    final signal = merged['signalDbm'] ??
        merged['signal_dbm'] ??
        merged['signal'] ??
        merged['signal_strength'];
    final plate = merged['vehicle_number'] ??
        merged['plate'] ??
        merged['license_plate'];
    final signalDbm =
        signal is num ? signal.toDouble() : double.tryParse(signal?.toString() ?? '');
    return RideStatus(
      motorOn: merged['motor_on'] == true ||
          merged['motorOn'] == true ||
          merged['is_active'] == true ||
          isAccOn,
      rangeKm:
          toDouble(merged['range_km'] ?? merged['range'] ?? distanceMeters / 1000),
      pingQuality: signalDbm == null ? (merged['ping']?.toString() ?? 'Unknown') : '${signalDbm.toStringAsFixed(0)} dBm',
      rentalMinutes: rideSeconds == 0 ? 0 : (rideSeconds / 60).round(),
      carbonReduction: carbon,
      rideSeconds: rideSeconds.round(),
      carbonEmissions: carbon,
      calories: calories,
      hasMotorState: hasMotorState,
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
        if (value != null && value.toString().isNotEmpty) return value.toString();
      }
      if (value is Map<String, dynamic>) {
        final nested = _findStringByKey(value, keys);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  Map<String, dynamic>? _findMapByKey(Map<String, dynamic> map, List<String> keys) {
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
    final res = await _client.postJson(
      ApiConfig.loginPath,
      body: {
        'username': username,
        'password': password,
        'detik': ApiConfig.loginSessionSeconds,
      },
    );
    debugPrint('login response: $res');

    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : null;
    final rootUser = res['user'] is Map<String, dynamic> ? res['user'] as Map<String, dynamic> : null;
    final dataUser =
        data != null && data['user'] is Map<String, dynamic> ? data['user'] as Map<String, dynamic> : null;
    final user = rootUser ?? dataUser;
    final token = _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['token', 'access'],
        ) ??
        '';
    final name = _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['name'],
        ) ??
        username;
    final email = _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['email'],
        ) ??
        username;
    final userId = user?['id_user']?.toString().trim() ??
        user?['user_id']?.toString().trim() ??
        user?['id']?.toString().trim() ??
        _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['userid', 'user_id', 'id'],
        );
    final emotorFromUser = user?['emotor'] ?? user?['eMotor'];
    final emotorFromData = data?['emotor'] ?? data?['eMotor'];
    final emotorMap = (emotorFromUser is Map<String, dynamic>)
        ? emotorFromUser
        : (emotorFromData is Map<String, dynamic>)
            ? emotorFromData
            : _findMapByKey(
                {
                  ...res,
                  if (data != null) ...data,
                },
                ['emotor'],
              );
    final emotorId = emotorMap?['id']?.toString().trim() ??
        emotorMap?['emotorId']?.toString().trim() ??
        emotorMap?['emotor_id']?.toString().trim() ??
        _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['emotorid', 'emotor_id'],
        );
    final emotorImei = emotorMap?['IMEI']?.toString().trim() ??
        emotorMap?['imei']?.toString().trim() ??
        _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['imei'],
        );
    final walletFromUser = user?['customerWallet'] ?? user?['customer_wallet'];
    final walletFromData = data?['customerWallet'] ?? data?['customer_wallet'];
    final walletMap = (walletFromUser is Map<String, dynamic>)
        ? walletFromUser
        : (walletFromData is Map<String, dynamic>)
            ? walletFromData
            : _findMapByKey(
                {
                  ...res,
                  if (data != null) ...data,
                },
                ['customerwallet', 'customer_wallet', 'wallet'],
              );
    debugPrint('login parsed userId=$userId emotorId=$emotorId emotorImei=$emotorImei');
    if (token.isEmpty) {
      throw ApiException('Token kosong dari server, pastikan endpoint login-emotor benar.');
    }

    final session = UserSession(token: token, name: name, email: email, userId: userId);
    SessionManager.instance.clearRental();
    await SessionManager.instance.saveUser(session);
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

  Future<RentalSession> startRental() async {
    final userId = SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim() ??
        '';
    if (userId.isEmpty) {
      throw ApiException('UserId tidak ditemukan. Silakan login ulang.');
    }
    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']?.toString().trim();
    final emotorIdFromUser = (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor'] as Map<String, dynamic>)['id']?.toString().trim()
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
        'startRental emotorId=$emotorId sessionEmotorId=${SessionManager.instance.emotorId}');
    if (emotorId.isEmpty) {
      throw ApiException(
          'EMOTOR_ID belum diset. Jalankan dengan --dart-define=EMOTOR_ID=xxx atau simpan di session.');
    }
    if ((SessionManager.instance.emotorId ?? '').isEmpty) {
      await SessionManager.instance.saveEmotorId(emotorId);
    }

    final res = await _client.postJson(
      ApiConfig.startRentalPath,
      auth: true,
      body: {'userId': userId, 'emotorId': emotorId},
    );
    final rentalPayload =
        res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
    var rental = RentalSession.fromJson(rentalPayload);
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
    return rental;
  }

  Future<bool> toggleMotor(bool enable) async {
    final emotorIdFromProfile = SessionManager.instance.emotorProfile?['id']?.toString().trim();
    final emotorIdFromUser = (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
        ? (SessionManager.instance.userProfile?['emotor'] as Map<String, dynamic>)['id']?.toString().trim()
        : null;
    final emotorId = SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        (emotorIdFromProfile != null && emotorIdFromProfile.isNotEmpty ? emotorIdFromProfile : null) ??
        (emotorIdFromUser != null && emotorIdFromUser.isNotEmpty ? emotorIdFromUser : null) ??
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
    final emotorIdFromProfile =
        SessionManager.instance.emotorProfile?['id']?.toString().trim();
    final emotorIdFromUser =
        (SessionManager.instance.userProfile?['emotor'] is Map<String, dynamic>)
            ? (SessionManager.instance.userProfile?['emotor']
                as Map<String, dynamic>)['id']
                ?.toString()
                .trim()
            : null;
    final emotorId = SessionManager.instance.rental?.emotorId ??
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
      body: {'ids': [emotorId]},
    );
    if (res['ok'] == true) return true;
    final matched = res['matched'];
    if (matched is num && matched > 0) return true;
    return false;
  }

  Future<RideStatus> fetchStatus() async {
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    if (rideId == null || rideId.isEmpty) {
      throw ApiException(AppLocalizations.current.noRideId);
    }
    return fetchStatusById(rideId);
  }

  Future<RideStatus> fetchStatusById(String rideId) async {
    final res = await _client.getJson(
      '${ApiConfig.historyByIdPath}/$rideId',
      auth: true,
    );
    final payload =
        res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : res;
    return RideStatus.fromJson(payload);
  }

  Stream<RideStatus> statusStream({Duration interval = const Duration(seconds: 4)}) {
    return Stream.periodic(interval).asyncMap((_) => fetchStatus());
  }

  Future<String> endRental() async {
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    final userId = SessionManager.instance.user?.userId ?? '';
    if (userId.isEmpty) {
      throw ApiException('UserId tidak ditemukan. Silakan login ulang.');
    }
    final emotorId = SessionManager.instance.rental?.emotorId ??
        SessionManager.instance.emotorId ??
        ApiConfig.emotorId;
    final emotorImei = SessionManager.instance.emotorImei ?? '';
    if ((rideId == null || rideId.isEmpty) && emotorId.isEmpty && emotorImei.isEmpty) {
      throw ApiException('Tidak ada rideId, emotorId, atau IMEI untuk diakhiri.');
    }
    final res = await _client.postJson(
      ApiConfig.endRentalPath,
      auth: true,
      body: {
        'userId': userId,
        if (rideId != null && rideId.isNotEmpty)
          'rideId': rideId
        else if (emotorImei.isNotEmpty)
          'imei': emotorImei
        else
          'emotorId': emotorId,
      },
    );
    final ride = res['ride'] is Map<String, dynamic> ? res['ride'] as Map<String, dynamic> : null;
    final endedId = ride?['id']?.toString();
    final fallbackId =
        (rideId != null && rideId.isNotEmpty) ? rideId : (emotorImei.isNotEmpty ? emotorImei : emotorId);
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
}
