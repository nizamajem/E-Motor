import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../navigation/app_navigator.dart';
import '../session/session_manager.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static Future<bool>? _refreshInFlight;
  static const int _maxRefreshAttempts = 3;

  Future<bool> refreshAccessToken() async => _refreshToken();

  Uri _buildUri(String path, [Map<String, String>? query]) {
    if (path.startsWith('http')) return Uri.parse(path);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SessionManager.instance.token;
    if (withAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (withAuth && kDebugMode) {
      debugPrint('auth header missing: tokenLength=${token?.length ?? 0}');
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    Future<http.Response> request() => _client.get(
          _buildUri(path, query),
          headers: _headers(withAuth: auth),
        );
    return _sendWithRefresh(request, authRequested: auth);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    Future<http.Response> request() => _client.post(
          _buildUri(path),
          headers: _headers(withAuth: auth),
          body: jsonEncode(body ?? {}),
        );
    return _sendWithRefresh(request, authRequested: auth);
  }

  Future<Map<String, dynamic>> _sendWithRefresh(
    Future<http.Response> Function() request,
    {required bool authRequested}
  ) async {
    var response = await request();
    if (kDebugMode && (response.statusCode == 401 || response.statusCode == 403)) {
      debugPrint('${response.statusCode} received: url=${response.request?.url}');
      debugPrint('${response.statusCode} body=${_safeBody(response.body)}');
    }
    if (authRequested && _shouldRetryWithRefresh(response)) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        response = await request();
      }
    }
    return _decode(response);
  }

  bool _shouldRetryWithRefresh(http.Response response) {
    final status = response.statusCode;
    return status == 401;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = SessionManager.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    _refreshInFlight ??= _performRefreshWithRetry(refreshToken);
    final result = await _refreshInFlight!;
    _refreshInFlight = null;
    return result;
  }

  Future<bool> _performRefreshWithRetry(String refreshToken) async {
    for (var attempt = 1; attempt <= _maxRefreshAttempts; attempt++) {
      final success = await _performRefreshOnce(refreshToken);
      if (success) return true;
      if (attempt < _maxRefreshAttempts) {
        await Future<void>.delayed(const Duration(seconds: 6));
      }
    }
    if (kDebugMode) {
      debugPrint('refresh failed after $_maxRefreshAttempts attempts');
    }
    SessionManager.instance.clearAuth();
    await AppNavigator.showRefreshDialog(
      'Refresh token gagal. Silakan login ulang.',
    );
    return false;
  }

  Future<bool> _performRefreshOnce(String refreshToken) async {
    try {
      var response = await _client.post(
        _buildUri(ApiConfig.refreshMobilePath),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'refresh_token': refreshToken}),
      );
      debugPrint(
        'refresh-mobile response: status=${response.statusCode} body=${_safeBody(response.body)}',
      );
      if (response.statusCode == 401) {
        return false;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final newToken = _extractTokenFromRefresh(response);
      if (newToken.isEmpty) return false;
      _logTokenTimes('refresh', newToken);
      await SessionManager.instance.saveToken(newToken);
      if (kDebugMode) {
        debugPrint('refresh success accessTokenLen=${newToken.length}');
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _extractTokenFromRefresh(http.Response response) {
    if (response.body.isEmpty) return '';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final token = decoded['access_token']?.toString() ??
            decoded['token']?.toString() ??
            decoded['accessToken']?.toString() ??
            '';
        if (token.isNotEmpty) return token;
      }
    } catch (_) {
      return '';
    }
    return '';
  }


  String _safeBody(String body) {
    if (body.length <= 240) return body;
    return body.substring(0, 240);
  }

  void _logTokenTimes(String label, String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return;
      var payload = parts[1];
      payload = base64Url.normalize(payload);
      final decoded = jsonDecode(utf8.decode(base64Url.decode(payload)));
      if (decoded is! Map<String, dynamic>) return;
      final iat = decoded['iat'];
      final exp = decoded['exp'];
      debugPrint('token($label) iat=$iat exp=$exp');
    } catch (_) {}
  }

  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    final raw = response.body.isEmpty ? '{}' : response.body;
    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      if (status >= 200 && status < 300) {
        throw ApiException('Invalid server response.', statusCode: status);
      }
      throw ApiException(
        raw.length > 160 ? raw.substring(0, 160) : raw,
        statusCode: status,
      );
    }
    final data = decoded is Map<String, dynamic> ? decoded : {'data': decoded};

    if (status >= 200 && status < 300) return data;

    final message = data['message'] ?? data['error'] ?? 'Unexpected error';
    throw ApiException(message.toString(), statusCode: status);
  }

  void close() => _client.close();
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
