import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';
import 'history_models.dart';

class HistoryService {
  HistoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<HistoryEntry>> fetchHistory() async {
    if (SessionManager.instance.token == null) return [];
    final rideId = SessionManager.instance.rental?.rideHistoryId;
    if (rideId == null || rideId.isEmpty) return [];
    return fetchHistoryById(rideId);
  }

  Future<List<HistoryEntry>> fetchHistoryById(String rideId) async {
    if (SessionManager.instance.token == null) return [];
    if (rideId.isEmpty) return [];
    final res = await _client.getJson(
      '${ApiConfig.historyByIdPath}/$rideId',
      auth: true,
    );
    // API returns single history object; wrap into list for UI.
    final data = res['data'] ?? res;
    if (data is List) {
      return data
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [HistoryEntry.fromJson(data as Map<String, dynamic>)];
  }

  Stream<List<HistoryEntry>> streamHistory(
      {Duration interval = const Duration(seconds: 6)}) {
    return Stream.periodic(interval).asyncMap((_) => fetchHistory());
  }
}
