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

  UserSession? _user;
  RentalSession? _rental;
  String? _emotorId; // e-motor bound to this user
  String? _emotorImei; // IMEI bound to this user

  String? get token => _user?.token;
  UserSession? get user => _user;
  RentalSession? get rental => _rental;
  String? get emotorId => _emotorId;
  String? get emotorImei => _emotorImei;

  void saveUser(UserSession session) {
    _user = session;
  }

  void saveRental(RentalSession session) {
    _rental = session;
    _emotorId ??= session.emotorId;
  }

  void saveEmotorId(String id) {
    _emotorId = id;
  }

  void saveEmotorImei(String imei) {
    _emotorImei = imei;
  }

  void clear() {
    _user = null;
    _rental = null;
    _emotorId = null;
    _emotorImei = null;
  }
}
