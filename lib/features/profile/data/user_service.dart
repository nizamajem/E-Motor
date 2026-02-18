import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';

class UserService {
  UserService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>?> fetchUserById(String userId) async {
    if (userId.isEmpty) return null;
    final res = await _client.getJson(
      '${ApiConfig.userByIdPath}/$userId',
      auth: true,
    );
    final data = res['data'] ?? res;
    if (data is Map<String, dynamic>) return data;
    return null;
  }
}
