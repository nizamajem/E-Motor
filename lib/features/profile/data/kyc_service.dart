import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_config.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/session/session_manager.dart';

class KycService {
  Future<void> uploadDocument({
    required String type,
    required File file,
  }) async {
    final l10n = AppLocalizations.current;
    final token = SessionManager.instance.token;
    if (token == null || token.isEmpty) {
      throw Exception(l10n.tokenMissing);
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/kyc/$type');
    debugPrint('KYC upload url=$uri type=$type');
    debugPrint('KYC token length=${token.length}');
    final contentType = _contentTypeFor(file.path);
    if (contentType == null) {
      throw Exception(l10n.uploadFileTypeError);
    }
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: contentType,
        ),
      );
    final response = await request.send();
    final body = await response.stream.bytesToString();
    debugPrint('KYC upload status=${response.statusCode} body=$body');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        body.isNotEmpty
            ? body
            : l10n.uploadFailed(response.statusCode.toString()),
      );
    }
  }

  MediaType? _contentTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    return null;
  }
}
