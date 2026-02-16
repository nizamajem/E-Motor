import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'package:flutter/foundation.dart';

class PaymentResult {
  PaymentResult({
    required this.isSuccess,
    this.message,
    this.redirectUrl,
    this.snapToken,
    this.membershipHistoryId,
  });

  final bool isSuccess;
  final String? message;
  final String? redirectUrl;
  final String? snapToken;
  final String? membershipHistoryId;
}

class PaymentService {
  PaymentService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  static const Duration _timeout = Duration(seconds: 20);

  Future<PaymentResult> payRideWallet({required String rideId}) async {
    final res = await _client
        .postJson(
          ApiConfig.payRideWalletPath,
          auth: true,
          body: {'rideId': rideId, 'method': 'WALLET'},
        )
        .timeout(_timeout);
    final data = _unwrap(res);
    return PaymentResult(
      isSuccess: true,
      message: _extractString(data, ['message']),
    );
  }

  Future<PaymentResult> payRideMidtrans({required String rideId}) async {
    final res = await _client
        .postJson(
          ApiConfig.payRideMidtransPath,
          auth: true,
          body: {'rideId': rideId},
        )
        .timeout(_timeout);
    if (kDebugMode) {
      debugPrint('payRideMidtrans response=$res');
    }
    final data = _unwrap(res);
    return PaymentResult(
      isSuccess: true,
      message: _extractString(data, ['message']),
      redirectUrl: _extractString(data, ['redirectUrl', 'redirect_url']),
      snapToken: _extractString(data, ['snapToken', 'snap_token']),
    );
  }

  Future<PaymentResult> buyMembershipWallet({
    required String userId,
    required String membershipId,
  }) async {
    final res = await _client
        .postJson(
          ApiConfig.buyMembershipPath,
          auth: true,
          body: {
            'userId': userId,
            'membershipId': membershipId,
            'paymentMethod': 'WALLET',
          },
        )
        .timeout(_timeout);
    final data = _unwrap(res);
    return PaymentResult(
      isSuccess: true,
      message: _extractString(data, ['message']),
    );
  }

  Future<PaymentResult> buyMembershipMidtrans({
    required String userId,
    required String membershipId,
  }) async {
    final res = await _client
        .postJson(
          ApiConfig.buyMembershipPath,
          auth: true,
          body: {
            'userId': userId,
            'membershipId': membershipId,
            'paymentMethod': 'MIDTRANS',
          },
        )
        .timeout(_timeout);
    if (kDebugMode) {
      debugPrint('buyMembershipMidtrans response=$res');
    }
    final data = _unwrap(res);
    final paymentMap = _extractMap(data, ['payment']) ?? data;
    final historyMap = _extractMap(data, ['membershipHistory', 'membership_history']);
    return PaymentResult(
      isSuccess: true,
      message: _extractString(data, ['message']),
      redirectUrl: _extractString(paymentMap, ['redirectUrl', 'redirect_url']),
      snapToken: _extractString(paymentMap, ['snapToken', 'snap_token']),
      membershipHistoryId: _extractString(
        historyMap ?? data,
        ['id', 'membershipHistoryId', 'membership_history_id'],
      ),
    );
  }

  Future<bool> refreshMembershipStatus() async {
    final res = await _client.getJson(
      ApiConfig.membershipsForEmotorPath,
      auth: true,
    );
    final data = res['data'];
    if (data is List) {
      return data.isNotEmpty;
    }
    return false;
  }

  String? _extractString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractMap(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = data[key];
      if (value is Map<String, dynamic>) return value;
    }
    return null;
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> data) {
    final inner = data['data'];
    if (inner is Map<String, dynamic>) return inner;
    return data;
  }
}
