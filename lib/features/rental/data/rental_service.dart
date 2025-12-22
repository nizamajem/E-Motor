import 'dart:async';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import 'package:flutter/foundation.dart';

class RideStatus {
  RideStatus({
    required this.motorOn,
    required this.rangeKm,
    required this.pingQuality,
    required this.rentalMinutes,
    required this.carbonReduction,
    this.batteryPercent,
  });

  factory RideStatus.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? json['bike_status'] ?? '').toString();
    final isAccOn = statusStr.toUpperCase().contains('ON');
    final rideSeconds = (json['ride_time_seconds'] ?? json['ride_time'] ?? 0).toDouble();
    final carbon = (json['carbon_emissions'] ?? json['carbon_reduction'] ?? 0).toDouble();
    final distanceMeters = (json['total_distance_meters'] ?? json['distance_m'] ?? 0).toDouble();
    final power = (json['power'] ?? json['battery'] ?? json['battery_percent'])?.toDouble();
    return RideStatus(
      motorOn: json['motor_on'] == true ||
          json['motorOn'] == true ||
          json['is_active'] == true ||
          isAccOn,
      rangeKm: (json['range_km'] ?? json['range'] ?? distanceMeters / 1000).toDouble(),
      pingQuality: json['ping']?.toString() ?? 'Unknown',
      rentalMinutes: rideSeconds == 0 ? 0 : (rideSeconds / 60).round(),
      carbonReduction: carbon,
      batteryPercent: power,
    );
  }

  final bool motorOn;
  final double rangeKm;
  final String pingQuality;
  final int rentalMinutes;
  final double carbonReduction;
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

  Future<UserSession> login({
    required String username,
    required String password,
  }) async {
    final res = await _client.postJson(
      ApiConfig.loginPath,
      body: {
        'username': username,
        'email': username,
        'password': password,
      },
    );
    debugPrint('login response: $res');

    final data = res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : null;
    final user = res['user'] is Map<String, dynamic> ? res['user'] as Map<String, dynamic> : null;
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
    final userId = user?['id_user']?.toString() ??
        user?['user_id']?.toString() ??
        user?['id']?.toString() ??
        _findStringByKey(
          {
            ...res,
            if (data != null) ...data,
          },
          ['userid', 'user_id', 'id'],
        );
    final emotor = user?['emotor'];
    final emotorMap = emotor is Map<String, dynamic> ? emotor : null;
    final emotorId = emotorMap?['id']?.toString();
    final emotorImei = emotorMap?['IMEI']?.toString() ?? emotorMap?['imei']?.toString();
    debugPrint('login parsed userId=$userId emotorId=$emotorId emotorImei=$emotorImei');
    if (token.isEmpty) {
      throw ApiException('Token kosong dari server, pastikan endpoint login-emotor benar.');
    }

    final session = UserSession(token: token, name: name, email: email, userId: userId);
    SessionManager.instance.saveUser(session);
    if (emotorId != null && emotorId.isNotEmpty) {
      SessionManager.instance.saveEmotorId(emotorId);
    }
    if (emotorImei != null && emotorImei.isNotEmpty) {
      SessionManager.instance.saveEmotorImei(emotorImei);
    }
    return session;
  }

  Future<RentalSession> startRental() async {
    final sessionEmotorImei = SessionManager.instance.emotorImei ?? '';
    final emotorId = (SessionManager.instance.emotorId ?? '').isNotEmpty
        ? SessionManager.instance.emotorId!
        : ApiConfig.emotorId.isNotEmpty
            ? ApiConfig.emotorId
            : SessionManager.instance.rental?.emotorId ?? '';
    debugPrint(
        'startRental emotorId=$emotorId emotorImei=$sessionEmotorImei sessionEmotorId=${SessionManager.instance.emotorId}');
    if (emotorId.isEmpty) {
      throw ApiException(
          'EMOTOR_ID belum diset. Jalankan dengan --dart-define=EMOTOR_ID=xxx atau simpan di session.');
    }

    final res = await _client.postJson(
      ApiConfig.startRentalPath,
      auth: true,
      body: sessionEmotorImei.isNotEmpty ? {'imei': sessionEmotorImei} : {'emotorId': emotorId},
    );
    final rental = RentalSession.fromJson(res);
    SessionManager.instance.saveRental(rental);
    return rental;
  }

  Future<RideStatus> toggleMotor(bool enable) async {
    final emotorId = SessionManager.instance.rental?.emotorId ?? ApiConfig.emotorId;
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
    return RideStatus.fromJson(res);
  }

  Future<RideStatus> fetchStatus() async {
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    if (rideId == null || rideId.isEmpty) {
      throw ApiException('Belum ada rideHistoryId. Mulai rental dulu.');
    }
    final res = await _client.getJson(
      '${ApiConfig.historyByIdPath}/$rideId',
      auth: true,
    );
    return RideStatus.fromJson(res);
  }

  Stream<RideStatus> statusStream({Duration interval = const Duration(seconds: 4)}) {
    return Stream.periodic(interval).asyncMap((_) => fetchStatus());
  }

  Future<void> endRental() async {
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    if (rideId == null || rideId.isEmpty) {
      throw ApiException('Tidak ada rideHistoryId untuk diakhiri.');
    }
    await _client.postJson(
      ApiConfig.endRentalPath,
      auth: true,
      body: {'rideId': rideId},
    );
  }
}
