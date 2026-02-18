import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_config.dart';
import '../../../core/session/session_manager.dart';

class MembershipCheckService {
  MembershipCheckService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<bool?> checkMembership({required String customerId}) async {
    if (customerId.isEmpty) return null;
    final res = await _client.postJson(
      '${ApiConfig.checkMembershipPath}/$customerId',
      auth: true,
      body: const {},
    );
    // Debug log
    debugPrint('check-membership response=$res');
    final data = res['data'] is Map<String, dynamic>
        ? res['data'] as Map<String, dynamic>
        : res;
    final status = _extractCertificationStatus(data);
    if (status != null) {
      final normalized = _normalizeStatus(status);
      final current = SessionManager.instance.customerVerificationStatus;
      if (normalized == 'verified' || current != 'verified') {
        await SessionManager.instance.setCustomerVerificationStatus(status);
      }
    }
    final expiresAt = _extractMembershipExpiresAt(data);
    await SessionManager.instance.setMembershipExpiresAt(expiresAt);
    final membershipName = _extractMembershipName(data);
    await SessionManager.instance.setMembershipName(membershipName);
    final raw = data['isHaveMembership'] ?? data['is_have_membership'];
    if (raw is bool) {
      if (!raw) {
        await SessionManager.instance.clearMembershipState();
      }
      return raw;
    }
    if (raw is num) return raw != 0;
    if (raw is String) {
      final text = raw.toLowerCase().trim();
      if (text == 'true' || text == 'yes' || text == '1') return true;
      if (text == 'false' || text == 'no' || text == '0') {
        await SessionManager.instance.clearMembershipState();
        return false;
      }
    }
    return null;
  }

  String _normalizeStatus(String raw) {
    final text = raw.trim().toLowerCase();
    if (text.contains('real_name') ||
        text.contains('verified') ||
        text.contains('approved')) {
      return 'verified';
    }
    if (text.contains('under_review') ||
        text.contains('under review') ||
        text.contains('pending') ||
        text.contains('review')) {
      return 'under_review';
    }
    if (text.contains('audit_failed') ||
        text.contains('rejected') ||
        text.contains('not_certified') ||
        text.contains('unverified')) {
      return 'not_verified';
    }
    return 'not_verified';
  }

  String? _extractCertificationStatus(Map<String, dynamic> data) {
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final direct = read(data['certification_status']) ??
        read(data['certificationStatus']);
    if (direct != null) return direct;
    final history = data['membershipHistory'] ?? data['membership_history'];
    if (history is Map<String, dynamic>) {
      final customer = history['customer'] ?? history['Customer'];
      if (customer is Map<String, dynamic>) {
        final status = read(customer['certification_status']) ??
            read(customer['certificationStatus']);
        if (status != null) return status;
      }
    }
    final customer = data['customer'] ?? data['Customer'];
    if (customer is Map<String, dynamic>) {
      return read(customer['certification_status']) ??
          read(customer['certificationStatus']);
    }
    return null;
  }

  DateTime? _extractMembershipExpiresAt(Map<String, dynamic> data) {
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    DateTime? parseServerDate(String raw) {
      final text = raw.trim();
      if (text.isEmpty) return null;
      final hasTz = text.endsWith('Z') ||
          text.contains('+') ||
          RegExp(r'-\d{2}:?\d{2}$').hasMatch(text);
      final normalized = hasTz ? text : '${text}Z';
      final parsed = DateTime.tryParse(normalized);
      if (parsed == null) return null;
      // Backend time is already local; prevent +8 shift in app.
      return parsed.subtract(const Duration(hours: 8));
    }

    final history = data['membershipHistory'] ?? data['membership_history'];
    if (history is Map<String, dynamic>) {
      final expires = read(history['expired_at'] ?? history['expiredAt']);
      if (expires != null) return parseServerDate(expires);
    }
    return null;
  }

  String? _extractMembershipName(Map<String, dynamic> data) {
    String? read(dynamic value) {
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    final history = data['membershipHistory'] ?? data['membership_history'];
    if (history is Map<String, dynamic>) {
      final membership = history['membership'];
      if (membership is Map<String, dynamic>) {
        final name = read(membership['name']);
        if (name != null) return name;
      }
    }
    return null;
  }
}
