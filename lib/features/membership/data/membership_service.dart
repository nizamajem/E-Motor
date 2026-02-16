import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import 'membership_models.dart';

class MembershipService {
  Future<List<MembershipPackage>> fetchMembershipsForEmotor() async {
    final res = await ApiClient().getJson(
      ApiConfig.membershipsForEmotorPath,
      auth: true,
    );
    final items = _extractList(res);
    return items
        .whereType<Map<String, dynamic>>()
        .map(MembershipPackage.fromJson)
        .toList();
  }

  List<dynamic> _extractList(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['data'] ?? data['items'] ?? data['memberships'];
      if (nested is List) return nested;
    }
    final items = res['items'] ?? res['memberships'];
    if (items is List) return items;
    return const [];
  }
}
