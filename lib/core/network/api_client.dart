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
  static const bool _debugAuth = true;

  Future<bool> refreshAccessToken() async => _refreshToken();

  Uri _buildUri(String path, [Map<String, String>? query]) {
    if (path.startsWith('http')) return Uri.parse(path);
    return Uri.parse(
      '${ApiConfig.baseUrl}$path',
    ).replace(queryParameters: query);
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};

    final token = SessionManager.instance.token;

    if (withAuth && token != null && token.isNotEmpty) {
      if (_debugAuth) {
        debugPrint('🧠 Current Access Token before request:');
        _logTokenTimes('request', token);
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    bool auth = false,
  }) async {
    Future<http.Response> request() =>
        _client.get(_buildUri(path, query), headers: _headers(withAuth: auth));
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
    Future<http.Response> Function() request, {
    required bool authRequested,
  }) async {
    if (_debugAuth) {
      debugPrint('==============================');
      debugPrint('➡️ API REQUEST START');
    }

    var response = await request();

    if (_debugAuth) {
      debugPrint('⬅️ RESPONSE STATUS: ${response.statusCode}');
      debugPrint('⬅️ RESPONSE BODY: ${_safeBody(response.body)}');
    }

    if (authRequested && _shouldRetryWithRefresh(response)) {
      if (_debugAuth) {
        debugPrint('⚠️ 401 detected → Access token might be expired');
      }

      final refreshed = await _refreshToken();

      if (refreshed) {
        if (_debugAuth) {
          debugPrint('🔁 Retrying original request after refresh...');
        }
        response = await request();

        if (_debugAuth) {
          debugPrint('⬅️ RETRY STATUS: ${response.statusCode}');
        }
      } else {
        if (_debugAuth) {
          debugPrint('❌ Refresh failed → user will be logged out');
        }
        throw ApiException(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      }
    }

    return _decode(response);
  }

  bool _shouldRetryWithRefresh(http.Response response) {
    final status = response.statusCode;
    if (status != 401) return false;
    if (SessionManager.instance.refreshToken?.isNotEmpty != true) return false;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code']?.toString().toUpperCase();
        if (code == null || code.isEmpty) {
          return true;
        }
        return code == 'TOKEN_EXPIRED' ||
            code == 'ACCESS_TOKEN_EXPIRED' ||
            code == 'SESSION_EXPIRED' ||
            code == 'TOKEN_INVALID' ||
            code == 'INVALID_TOKEN' ||
            code == 'JWT_EXPIRED';
      }
    } catch (_) {}
    return true;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = SessionManager.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;
    _refreshInFlight ??= _performRefresh(refreshToken);
    final result = await _refreshInFlight!;
    _refreshInFlight = null;
    return result;
  }

  Future<bool> _performRefresh(String refreshToken) async {
    try {
      if (_debugAuth) {
        debugPrint('==============================');
        debugPrint('🔄 REFRESH TOKEN START');
        debugPrint('Refresh Endpoint: ${ApiConfig.refreshMobilePath}');
        debugPrint('Refresh Token: $refreshToken');
        _logTokenTimes('refresh-before', refreshToken);
      }

      final response = await _client.post(
        _buildUri(ApiConfig.refreshMobilePath),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (_debugAuth) {
        debugPrint('⬅️ REFRESH STATUS: ${response.statusCode}');
        debugPrint('⬅️ REFRESH BODY: ${_safeBody(response.body)}');
      }

      if (response.statusCode == 401) {
        if (_debugAuth) {
          debugPrint('❌ REFRESH TOKEN EXPIRED');
        }

        SessionManager.instance.clear();
        await AppNavigator.showRefreshDialog(
          'Session expired. Please login again.',
        );
        await AppNavigator.navigateToLogin();
        return false;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (_debugAuth) {
          debugPrint('❌ REFRESH FAILED (non-2xx)');
        }
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      final payload = decoded['data'] is Map<String, dynamic>
          ? decoded['data']
          : decoded;
      final newAccessToken =
          payload['access_token']?.toString() ??
          payload['token']?.toString() ??
          payload['accessToken']?.toString() ??
          '';

      final newRefreshToken = payload['refresh_token']?.toString() ?? '';
      if (newAccessToken.isEmpty) {
        if (_debugAuth) {
          debugPrint('❌ REFRESH FAILED (no access token in response)');
        }
        return false;
      }

      if (newRefreshToken.isNotEmpty) {
        await SessionManager.instance.saveRefreshToken(newRefreshToken);
      }

      if (_debugAuth) {
        debugPrint('✅ REFRESH SUCCESS');
        _logTokenTimes('refresh-after', newAccessToken);
      }

      await SessionManager.instance.saveToken(newAccessToken);

      return true;
    } catch (e) {
      if (_debugAuth) {
        debugPrint('❌ REFRESH ERROR: $e');
      }
      return false;
    }
  }

  Future<void> _forceLogout() async {
    try {
      if (_debugAuth) {
        debugPrint('🚨 FORCE LOGOUT START');
      }

      final token = SessionManager.instance.token;

      if (token != null && token.isNotEmpty) {
        await _client.post(
          _buildUri(ApiConfig.logoutPath),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (_) {
      // ignore error, we are logging out anyway
    } finally {
      SessionManager.instance.clear();
      await AppNavigator.navigateToLogin();
    }
  }

  String _extractTokenFromRefresh(http.Response response) {
    if (response.body.isEmpty) return '';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final token =
            decoded['access_token']?.toString() ??
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
