import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import 'history_models.dart';

class HistoryService {
  HistoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<HistoryEntry>> fetchHistory() async {
    if (SessionManager.instance.token == null) return [];
    final userId = SessionManager.instance.user?.userId ??
        SessionManager.instance.userProfile?['id_user']?.toString().trim() ??
        SessionManager.instance.userProfile?['id']?.toString().trim();
    if (userId == null || userId.isEmpty) return [];
    return fetchHistoryByUser(userId);
  }

  Future<List<HistoryEntry>> fetchHistoryById(String rideId) async {
    if (SessionManager.instance.token == null) return [];
    if (rideId.isEmpty) return [];
    Map<String, dynamic> res;
    try {
      res = await _client.getJson(
        '${ApiConfig.historyByIdPath}/$rideId',
        auth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } on FormatException {
      return [];
    }
    // API returns single history object; wrap into list for UI.
    final data = res['data'] ?? res;
    if (data is List) {
      return data
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [HistoryEntry.fromJson(data as Map<String, dynamic>)];
  }

  Future<List<HistoryEntry>> fetchHistoryByUser(String userId) async {
    if (SessionManager.instance.token == null) return [];
    if (userId.isEmpty) return [];
    Map<String, dynamic> res;
    try {
      res = await _client.getJson(
        '${ApiConfig.historyByUserPath}/$userId',
        auth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } on FormatException {
      return [];
    }
    final data = res['data'] ?? res;
    if (data is List) {
      return data
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      return [HistoryEntry.fromJson(data)];
    }
    return [];
  }

  Future<List<MembershipHistoryEntry>> fetchMembershipHistoryByCustomer(
    String customerId,
  ) async {
    if (SessionManager.instance.token == null) return [];
    if (customerId.isEmpty) return [];
    Map<String, dynamic> res;
    try {
      res = await _client.getJson(
        '${ApiConfig.membershipHistoryByCustomerPath}/$customerId',
        auth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } on FormatException {
      return [];
    }
    final data = res['data'] ?? res;
    if (data is List) {
      return data
          .map((e) => MembershipHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      return [MembershipHistoryEntry.fromJson(data)];
    }
    return [];
  }

  Future<List<HistoryEntry>> fetchCyclingByMembership(String membershipId) async {
    if (SessionManager.instance.token == null) return [];
    if (membershipId.isEmpty) return [];
    Map<String, dynamic> res;
    try {
      res = await _client.getJson(
        '${ApiConfig.historyByMembershipPath}/$membershipId',
        auth: true,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    } on FormatException {
      return [];
    }
    final data = res['data'] ?? res;
    if (data is List) {
      return data
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is Map<String, dynamic>) {
      return [HistoryEntry.fromJson(data)];
    }
    return [];
  }

  Stream<List<HistoryEntry>> streamHistory(
      {Duration interval = const Duration(seconds: 6)}) {
    return Stream.periodic(interval).asyncMap((_) => fetchHistory());
  }
}
