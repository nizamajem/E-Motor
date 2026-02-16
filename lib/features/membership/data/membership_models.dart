class MembershipPackage {
  const MembershipPackage({
    required this.id,
    required this.name,
    required this.durationHours,
    required this.price,
    required this.minBalance,
  });

  final String id;
  final String name;
  final int durationHours;
  final double price;
  final double minBalance;

  factory MembershipPackage.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
    }

    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      final raw = value.toString();
      final digits = RegExp(r'\d+').stringMatch(raw);
      return int.tryParse(digits ?? '') ?? 0;
    }

    final id = json['id']?.toString() ??
        json['membership_id']?.toString() ??
        json['uuid']?.toString() ??
        '';
    final name = json['name']?.toString() ??
        json['title']?.toString() ??
        json['package_name']?.toString() ??
        'Package';
    final durationHours = toInt(
      json['duration_hours'] ??
          json['durationHours'] ??
          json['valid_hours'] ??
          json['validHours'] ??
          json['hours'] ??
          json['valid_period'] ??
          json['validPeriod'] ??
          json['period'] ??
          json['duration'],
    );
    final price = toDouble(
      json['price'] ??
          json['amount'] ??
          json['price_amount'] ??
          json['priceAmount'],
    );
    final minBalance = toDouble(
      json['min_balance'] ??
          json['minimum_balance'] ??
          json['minimumBalance'] ??
          json['minBalance'],
    );

    return MembershipPackage(
      id: id,
      name: name,
      durationHours: durationHours,
      price: price,
      minBalance: minBalance,
    );
  }
}
