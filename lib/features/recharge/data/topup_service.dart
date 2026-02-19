import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class TopupSnapResponse {
  TopupSnapResponse({
    required this.snapToken,
    required this.redirectUrl,
    required this.orderId,
  });

  factory TopupSnapResponse.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value == null ? '' : value.toString().trim();
    return TopupSnapResponse(
      snapToken: text(json['snapToken'] ?? json['snap_token']),
      redirectUrl: text(json['redirectUrl'] ?? json['redirect_url']),
      orderId: text(json['order_id'] ?? json['orderId']),
    );
  }

  final String snapToken;
  final String redirectUrl;
  final String orderId;
}

class TopupService {
  TopupService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<TopupSnapResponse?> createSnap({
    required String customerWalletId,
    required int amount,
    bool isSandbox = true,
  }) async {
    if (customerWalletId.isEmpty || amount <= 0) return null;
    try {
      final res = await _client.postJson(
        ApiConfig.topupSnapPath,
        auth: true,
        body: {
          'customerWalletId': customerWalletId,
          'amount': amount,
          'isSandbox': isSandbox,
        },
      );
      final data = res['data'] ?? res;
      if (data is! Map<String, dynamic>) return null;
      return TopupSnapResponse.fromJson(data);
    } on ApiException catch (e) {
      final message =
          e.message.isNotEmpty ? e.message : 'Top up failed';
      throw Exception(message);
    } catch (_) {
      throw Exception('Top up failed');
    }
  }
}
