import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'package:flutter/foundation.dart';

class Emotor {
  Emotor({
    required this.id,
    required this.plate,
    required this.userId,
    this.status,
  });

  factory Emotor.fromJson(Map<String, dynamic> json) {
    return Emotor(
      id: json['id']?.toString() ?? '',
      plate: json['vehicle_number']?.toString() ??
          json['plate']?.toString() ??
          json['license_plate']?.toString() ??
          '-',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      status: json['status']?.toString() ??
          json['bike_status']?.toString() ??
          json['rental_status']?.toString(),
    );
  }

  final String id;
  final String plate;
  final String userId;
  final String? status;

  bool get isInUse {
    final value = status?.toLowerCase().trim();
    if (value == null || value.isEmpty) return false;
    return value.contains('in_use') ||
        value.contains('in-use') ||
        value.contains('using') ||
        value.contains('running') ||
        value.contains('active') ||
        value.contains('on_ride');
  }
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
}
