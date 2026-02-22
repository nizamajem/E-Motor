import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/localization/app_localizations.dart';

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
  static const Duration _timeout = Duration(seconds: 20);

  Future<TopupSnapResponse?> createSnap({
    required String customerId,
    required String customerWalletId,
    required int amount,
    bool isSandbox = true,
  }) async {
    if ((customerId.isEmpty && customerWalletId.isEmpty) || amount <= 0) {
      return null;
    }
    try {
      final body = <String, dynamic>{
        'amount': amount,
        'isSandbox': isSandbox,
        'env': isSandbox ? 'sandbox' : 'production',
        if (customerId.isNotEmpty) 'customerId': customerId,
        if (customerId.isNotEmpty) 'customer_id': customerId,
        if (customerWalletId.isNotEmpty) 'customerWalletId': customerWalletId,
        if (customerWalletId.isNotEmpty) 'customer_wallet_id': customerWalletId,
        if (customerWalletId.isNotEmpty) 'walletId': customerWalletId,
        if (customerWalletId.isNotEmpty) 'wallet_id': customerWalletId,
      };
      if (kDebugMode) {
        debugPrint('topup createSnap path=${ApiConfig.topupSnapPath}');
        debugPrint('topup createSnap body=$body');
      }
      final res = await _client.postJson(
        ApiConfig.topupSnapPath,
        auth: true,
        body: body,
      );
      final data = res['data'] ?? res;
      if (data is! Map<String, dynamic>) return null;
      return TopupSnapResponse.fromJson(data);
    } on ApiException catch (e) {
      final message = e.message.isNotEmpty
          ? e.message
          : AppLocalizations.current.topupFailed;
      throw Exception(message);
    } catch (_) {
      throw Exception(AppLocalizations.current.topupFailed);
    }
  }

  Future<String> checkTopupStatus({required String orderId}) async {
    if (orderId.isEmpty) return '';
    try {
      final json = await _client
          .getJson('${ApiConfig.topupCheckStatusPath}/$orderId', auth: true)
          .timeout(_timeout);
      final data = json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : json;
      final status = _readString(data, [
        'status',
        'transaction_status',
        'payment_status',
      ]);
      if (status == null || status.isEmpty) return '';
      return status.trim().toLowerCase();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return '';
      rethrow;
    }
  }

  String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }
}
