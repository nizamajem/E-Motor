import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'package:flutter/foundation.dart';

class Emotor {
  Emotor({
    required this.id,
    required this.plate,
    required this.userId,
    this.status,
    this.createTime,
  });

  factory Emotor.fromJson(Map<String, dynamic> json) {
    return Emotor(
      id: json['id']?.toString() ?? '',
      plate: json['vehicle_number']?.toString() ??
          json['plate']?.toString() ??
          json['license_plate']?.toString() ??
          '-',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      status: json['rental_status']?.toString() ??
          json['status']?.toString() ??
          json['bike_status']?.toString(),
      createTime: DateTime.tryParse(json['create_time']?.toString() ?? ''),
    );
  }

  final String id;
  final String plate;
  final String userId;
  final String? status;
  final DateTime? createTime;

  bool get isInUse => false;
}

class EmotorService {
  EmotorService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Emotor>> fetchEmotors({
    String? merchantId,
    String? tenantId,
    String? status,
  }) async {
    final query = <String, String>{};
    if (merchantId != null && merchantId.isNotEmpty) query['merchantId'] = merchantId;
    if (tenantId != null && tenantId.isNotEmpty) query['tenantId'] = tenantId;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final res = await _client.getJson(
      ApiConfig.emotorListPath,
      auth: true,
      query: query.isEmpty ? null : query,
    );
    debugPrint('emotor list response: $res');
    final data = (res['data'] ?? res) as List<dynamic>;
    return data.map((e) => Emotor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Emotor?> fetchAssignedToUser(String userId) async {
    final emotors = await fetchEmotors();
    try {
      return emotors.firstWhere((e) => e.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<Emotor?> fetchById(String id) async {
    final res = await _client.getJson(
      '${ApiConfig.emotorByIdPath}/$id',
      auth: true,
    );
    final data = res['data'] ?? res;
    return Emotor.fromJson(data as Map<String, dynamic>);
  }

  Future<DashboardRefreshData?> fetchDashboardRefresh(String customerId) async {
    if (customerId.isEmpty) return null;
    final res = await _client.getJson(
      '${ApiConfig.refreshDashboardPath}/$customerId',
      auth: true,
    );
    final data = res['data'] ?? res;
    if (data is! Map<String, dynamic>) return null;
    return DashboardRefreshData.fromJson(data);
  }

  Future<AdditionalInfo?> fetchAdditionalInfo(String customerId) async {
    if (customerId.isEmpty) return null;
    final res = await _client.getJson(
      '${ApiConfig.additionalInfoPath}/$customerId',
      auth: true,
    );
    final data = res['data'] ?? res;
    if (data is! Map<String, dynamic>) return null;
    return AdditionalInfo.fromJson(data);
  }
}

class DashboardRefreshData {
  DashboardRefreshData({
    required this.emotorNumber,
    required this.packageName,
    required this.remainingSeconds,
    required this.validUntil,
    required this.emissionReduction,
    required this.rideRange,
  });

  factory DashboardRefreshData.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) =>
        value == null ? '' : value.toString().trim();
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    final emotorNumber = text(json['emotorNumber'] ?? json['emotor_number']);
    final packageName = text(json['packageName'] ?? json['package_name']);
    final remaining =
        toInt(json['membershipDurationRemaining'] ?? json['durationRemaining']);
    DateTime? parseServerDate(String raw) {
      if (raw.isEmpty) return null;
      final hasTz = raw.endsWith('Z') ||
          raw.contains('+') ||
          RegExp(r'-\d{2}:?\d{2}$').hasMatch(raw);
      final normalized = hasTz ? raw : '${raw}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed == null) return null;
      // Backend time is already local; prevent +8 shift in app.
      return parsed.subtract(const Duration(hours: 8));
    }

    final validUntil = parseServerDate(
      text(json['membershipValidUntil'] ?? json['membership_valid_until']),
    );
    final emission = toDouble(
      json['emissionReduction'] ?? json['emission_reduction'],
    );
    final rideRange = toInt(json['rideRange'] ?? json['ride_range']);

    return DashboardRefreshData(
      emotorNumber: emotorNumber,
      packageName: packageName,
      remainingSeconds: remaining,
      validUntil: validUntil,
      emissionReduction: emission,
      rideRange: rideRange,
    );
  }

  final String emotorNumber;
  final String packageName;
  final int remainingSeconds;
  final DateTime? validUntil;
  final double emissionReduction;
  final int rideRange;
}

class AdditionalInfo {
  AdditionalInfo({
    required this.additionalPayment,
    required this.overtimeSeconds,
    required this.overtimeBlockMinutes,
    required this.overtimeBlocks,
  });

  factory AdditionalInfo.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString()) ?? 0;
    }

    return AdditionalInfo(
      additionalPayment: toDouble(
        json['additionalPayment'] ?? json['additional_payment'],
      ),
      overtimeSeconds: toInt(json['overtimeSeconds'] ?? json['overtime_seconds']),
      overtimeBlockMinutes:
          toInt(json['overtimeBlockMinutes'] ?? json['overtime_block_minutes']),
      overtimeBlocks:
          toInt(json['overtimeBlocks'] ?? json['overtime_blocks']),
    );
  }

  final double additionalPayment;
  final int overtimeSeconds;
  final int overtimeBlockMinutes;
  final int overtimeBlocks;
}
