import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession({
    required this.token,
    required this.name,
    required this.email,
    this.userId,
  });

  final String token;
  final String name;
  final String email;
  final String? userId;
}

class RentalSession {
  RentalSession({
    required this.id,
    required this.emotorId,
    required this.plate,
    required this.rangeKm,
    required this.batteryPercent,
    required this.motorOn,
    this.rideHistoryId,
  });

  factory RentalSession.fromJson(Map<String, dynamic> json) {
    final rideId = json['rideHistoryId']?.toString() ??
        json['ride_history_id']?.toString() ??
        json['id']?.toString() ??
        '';
    return RentalSession(
      id: json['id']?.toString() ?? rideId,
      emotorId: json['emotorId']?.toString() ??
          json['eMotorId']?.toString() ??
          json['bikeId']?.toString() ??
          json['emotor_id']?.toString() ??
          '',
      plate: json['plate']?.toString() ?? json['vehicle_number']?.toString() ?? '-',
      rangeKm: (json['range_km'] ?? json['range'] ?? 0).toDouble(),
      batteryPercent: (json['battery'] ?? json['battery_percent'] ?? 0).toDouble(),
      motorOn: json['motor_on'] == true || json['motorOn'] == true,
      rideHistoryId: rideId.isEmpty ? null : rideId,
    );
  }

  final String id;
  final String emotorId;
  final String plate;
  final double rangeKm;
  final double batteryPercent;
  final bool motorOn;
  final String? rideHistoryId;
}

class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  static const _keyToken = 'session_token';
  static const _keyName = 'session_name';
  static const _keyEmail = 'session_email';
  static const _keyUserId = 'session_user_id';
  static const _keyEmotorId = 'session_emotor_id';
  static const _keyEmotorImei = 'session_emotor_imei';
  static const _keyUserJson = 'session_user_json';
  static const _keyEmotorJson = 'session_emotor_json';
  static const _keyWalletJson = 'session_wallet_json';

  UserSession? _user;
  RentalSession? _rental;
  String? _emotorId; // e-motor bound to this user
  String? _emotorImei; // IMEI bound to this user
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _emotorProfile;
  Map<String, dynamic>? _walletProfile;

  String? get token => _user?.token;
  UserSession? get user => _user;
  RentalSession? get rental => _rental;
  String? get emotorId => _emotorId;
  String? get emotorImei => _emotorImei;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get emotorProfile => _emotorProfile;
  Map<String, dynamic>? get walletProfile => _walletProfile;

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null || token.isEmpty) return;
    _user = UserSession(
      token: token,
      name: prefs.getString(_keyName) ?? '',
      email: prefs.getString(_keyEmail) ?? '',
      userId: prefs.getString(_keyUserId),
    );
    _emotorId = prefs.getString(_keyEmotorId);
    _emotorImei = prefs.getString(_keyEmotorImei);
    _userProfile = _decodeMap(prefs.getString(_keyUserJson));
    _emotorProfile = _decodeMap(prefs.getString(_keyEmotorJson));
    _walletProfile = _decodeMap(prefs.getString(_keyWalletJson));
    if ((_emotorId == null || _emotorId!.isEmpty) && _emotorProfile != null) {
      final id = _emotorProfile?['id']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        _emotorId = id;
      }
    }
    if ((_emotorImei == null || _emotorImei!.isEmpty) && _emotorProfile != null) {
      final imei = _emotorProfile?['IMEI']?.toString().trim() ??
          _emotorProfile?['imei']?.toString().trim();
      if (imei != null && imei.isNotEmpty) {
        _emotorImei = imei;
      }
    }
    if ((_emotorId == null || _emotorId!.isEmpty) && _userProfile != null) {
      final emotor = _userProfile?['emotor'];
      if (emotor is Map<String, dynamic>) {
        final id = emotor['id']?.toString().trim();
        if (id != null && id.isNotEmpty) {
          _emotorId = id;
        }
      }
    }
    if ((_emotorImei == null || _emotorImei!.isEmpty) && _userProfile != null) {
      final emotor = _userProfile?['emotor'];
      if (emotor is Map<String, dynamic>) {
        final imei =
            emotor['IMEI']?.toString().trim() ?? emotor['imei']?.toString().trim();
        if (imei != null && imei.isNotEmpty) {
          _emotorImei = imei;
        }
      }
    }
  }

  Future<void> saveUser(UserSession session) async {
    _user = session;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, session.token);
    await prefs.setString(_keyName, session.name);
    await prefs.setString(_keyEmail, session.email);
    if (session.userId != null && session.userId!.isNotEmpty) {
      await prefs.setString(_keyUserId, session.userId!);
    } else {
      await prefs.remove(_keyUserId);
    }
  }

  void saveRental(RentalSession session) {
    _rental = session;
    _emotorId ??= session.emotorId;
  }

  Future<void> saveEmotorId(String id) async {
    _emotorId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id.isNotEmpty) {
      await prefs.setString(_keyEmotorId, id);
    } else {
      await prefs.remove(_keyEmotorId);
    }
  }

  Future<void> saveEmotorImei(String imei) async {
    _emotorImei = imei;
    final prefs = await SharedPreferences.getInstance();
    if (imei.isNotEmpty) {
      await prefs.setString(_keyEmotorImei, imei);
    } else {
      await prefs.remove(_keyEmotorImei);
    }
  }

  Future<void> saveUserProfile(Map<String, dynamic>? profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyUserJson, profile);
    final emotor = profile?['emotor'];
    if (emotor is Map<String, dynamic>) {
      final id = emotor['id']?.toString().trim();
      final imei = emotor['IMEI']?.toString().trim() ?? emotor['imei']?.toString().trim();
      if (id != null && id.isNotEmpty) {
        await saveEmotorId(id);
      }
      if (imei != null && imei.isNotEmpty) {
        await saveEmotorImei(imei);
      }
    }
  }

  Future<void> saveEmotorProfile(Map<String, dynamic>? profile) async {
    _emotorProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyEmotorJson, profile);
    final id = profile?['id']?.toString().trim();
    final imei = profile?['IMEI']?.toString().trim() ?? profile?['imei']?.toString().trim();
    if (id != null && id.isNotEmpty) {
      await saveEmotorId(id);
    }
    if (imei != null && imei.isNotEmpty) {
      await saveEmotorImei(imei);
    }
  }

  Future<void> saveWalletProfile(Map<String, dynamic>? profile) async {
    _walletProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await _saveMap(prefs, _keyWalletJson, profile);
  }

  void clear() {
    _user = null;
    _rental = null;
    _emotorId = null;
    _emotorImei = null;
    _userProfile = null;
    _emotorProfile = null;
    _walletProfile = null;
    unawaited(_clearStorage());
  }

  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmotorId);
    await prefs.remove(_keyEmotorImei);
    await prefs.remove(_keyUserJson);
    await prefs.remove(_keyEmotorJson);
    await prefs.remove(_keyWalletJson);
  }

  Map<String, dynamic>? _decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  Future<void> _saveMap(
    SharedPreferences prefs,
    String key,
    Map<String, dynamic>? value,
  ) async {
    if (value == null) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(value));
  }
}
