import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class RechargeOptionDto {
  RechargeOptionDto({
    required this.id,
    required this.amount,
    required this.giftType,
    required this.giftNumber,
  });

  factory RechargeOptionDto.fromJson(Map<String, dynamic> json) {
    String readAny(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }
      return '';
    }
    return RechargeOptionDto(
      id: readAny(['id']),
      amount: readAny(['amount']),
      giftType: readAny(['gift_type', 'giftType']),
      giftNumber: readAny(['gift_number', 'giftNumber']),
    );
  }

  final String id;
  final String amount;
  final String giftType;
  final String giftNumber;
}

class RechargeService {
  RechargeService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<RechargeOptionDto>> fetchRechargeOptions({
    String? tenantId,
    String? merchantId,
  }) async {
    final query = <String, String>{};
    if (tenantId != null && tenantId.trim().isNotEmpty) {
      query['tenantId'] = tenantId.trim();
    }
    if (merchantId != null && merchantId.trim().isNotEmpty) {
      query['merchantId'] = merchantId.trim();
    }
    final res = await _client.getJson(
      ApiConfig.rechargesPath,
      auth: true,
      query: query.isEmpty ? null : query,
    );
    final data = res['data'] ?? res;
    final items = _extractItems(data);
    return items
        .whereType<Map<String, dynamic>>()
        .map(RechargeOptionDto.fromJson)
        .toList();
  }

  List<dynamic> _extractItems(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['data'] ?? data['recharges'];
      if (items is List) return items;
    }
    return const [];
  }
}
