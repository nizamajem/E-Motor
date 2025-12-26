class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.date,
    required this.durationAndCost,
    required this.distanceKm,
    required this.plate,
    required this.calories,
    required this.emission,
    required this.startTime,
    required this.endTime,
    required this.startPlace,
    required this.endPlace,
    required this.rideCost,
    required this.idleCost,
    required this.totalCost,
  });

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map<String, dynamic> ? value : null;
    double toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0;
    }

    String? toText(dynamic value) {
      if (value == null) return null;
      final text = value.toString();
      return text.isEmpty ? null : text;
    }

    String formatCurrency(dynamic value) {
      if (value == null) return '-';
      final text = value.toString();
      if (text.isEmpty) return '-';
      return text.startsWith('Rp') ? text : 'Rp $text';
    }

    String formatNumber(dynamic value, String suffix, {int digits = 2}) {
      if (value == null) return '-';
      final parsed = value is num ? value.toDouble() : double.tryParse(value.toString());
      if (parsed == null) return value.toString();
      return '${parsed.toStringAsFixed(digits)}$suffix';
    }

    String formatDistance(dynamic value) {
      if (value == null) return '-';
      final meters = toDouble(value);
      final km = meters == 0 ? 0 : meters / 1000;
      return '${km.toStringAsFixed(1)} km';
    }

    String formatDate(DateTime? dt) {
      if (dt == null) return '-';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      return '$day $month ${dt.year}';
    }

    String formatTime(DateTime? dt) {
      if (dt == null) return '-';
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    final bike = asMap(json['bike']);
    final emotor = asMap(json['eMotor']) ?? asMap(json['emotor']);
    final startAt = DateTime.tryParse(
        toText(json['start_position_time']) ?? toText(json['start_date_time']) ?? '');
    final endAt = DateTime.tryParse(
        toText(json['end_position_time']) ?? toText(json['end_date_time']) ?? '');
    final rideSeconds = toDouble(
      json['ride_time_seconds'] ?? json['usage_time_seconds'] ?? json['ride_time'],
    );
    final amountPaid = json['amount_paid'];
    final pauseAmount = json['pause_amount'];
    final startLat = json['start_position_latitude'];
    final startLng = json['start_position_longitude'];
    final endLat = json['end_position_latitude'];
    final endLng = json['end_position_longitude'];
    final plate = toText(bike?['vehicle_number'] ?? emotor?['vehicle_number']) ??
        toText(json['plate']) ??
        '-';
    final durationText =
        rideSeconds == 0 ? '-' : '${(rideSeconds / 60).round()} min';
    final durationAndCost = amountPaid == null
        ? durationText
        : '$durationText - ${formatCurrency(amountPaid)}';
    final startPlace = (startLat != null && startLng != null)
        ? '${toDouble(startLat).toStringAsFixed(5)}, ${toDouble(startLng).toStringAsFixed(5)}'
        : '-';
    final endPlace = (endLat != null && endLng != null)
        ? '${toDouble(endLat).toStringAsFixed(5)}, ${toDouble(endLng).toStringAsFixed(5)}'
        : '-';
    return HistoryEntry(
      id: json['id']?.toString() ?? '',
      date: formatDate(startAt),
      durationAndCost: durationAndCost,
      distanceKm: formatDistance(json['total_distance_meters'] ?? json['distance_m']),
      plate: plate,
      calories: formatNumber(json['calories'], ' kcal'),
      emission: formatNumber(json['carbon_emissions'], ' g'),
      startTime: formatTime(startAt),
      endTime: formatTime(endAt),
      startPlace: startPlace,
      endPlace: endPlace,
      rideCost: formatCurrency(amountPaid),
      idleCost: pauseAmount == null ? '-' : formatCurrency(pauseAmount),
      totalCost: formatCurrency(amountPaid),
    );
  }

  final String id;
  final String date;
  final String durationAndCost;
  final String distanceKm;
  final String plate;
  final String calories;
  final String emission;
  final String startTime;
  final String endTime;
  final String startPlace;
  final String endPlace;
  final String rideCost;
  final String idleCost;
  final String totalCost;
}
