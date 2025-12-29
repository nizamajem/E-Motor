import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class FeedbackService {
  FeedbackService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> createFeedback({
    String? userId,
    String? tenantId,
    String? userCyclingHistoryId,
    String? tenantCyclingHistoryId,
    required int rating,
    required String feedback,
  }) {
    final body = <String, dynamic>{
      'rating': rating,
      'feedback': feedback,
    };
    if (userId != null && userId.isNotEmpty) body['userId'] = userId;
    if (tenantId != null && tenantId.isNotEmpty) body['tenantId'] = tenantId;
    if (userCyclingHistoryId != null && userCyclingHistoryId.isNotEmpty) {
      body['userCyclingHistoryId'] = userCyclingHistoryId;
    }
    if (tenantCyclingHistoryId != null && tenantCyclingHistoryId.isNotEmpty) {
      body['tenantCyclingHistoryId'] = tenantCyclingHistoryId;
    }
    return _client.postJson(ApiConfig.feedbacksPath, body: body, auth: true);
  }
}
