import 'dart:convert';

import 'package:http/http.dart' as http;

import '../session/session_manager.dart';
import 'api_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? query]) {
    if (path.startsWith('http')) return Uri.parse(path);
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
  }

  Map<String, String> _headers({bool withAuth = false}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SessionManager.instance.token;
    if (withAuth && token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
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
    return _sendWithRefresh(request);
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
    return _sendWithRefresh(request);
  }

  Future<Map<String, dynamic>> _sendWithRefresh(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (_shouldRetryWithRefresh(response)) {
      final refreshToken = _extractRefreshToken(response);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await SessionManager.instance.saveToken(refreshToken);
        response = await request();
      }
    }
    return _decode(response);
  }

  bool _shouldRetryWithRefresh(http.Response response) {
    final status = response.statusCode;
    if (status != 401 && status != 403) return false;
    return _extractRefreshToken(response)?.isNotEmpty == true;
  }

  String? _extractRefreshToken(http.Response response) {
    return response.headers['x-refresh-token'] ??
        response.headers['x-refresh_token'];
  }

  Map<String, dynamic> _decode(http.Response response) {
    final refreshToken = _extractRefreshToken(response);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      SessionManager.instance.saveToken(refreshToken);
    }
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
