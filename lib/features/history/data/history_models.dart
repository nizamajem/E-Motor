import '../../../core/localization/app_localizations.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.date,
    required this.durationAndCost,
    required this.distanceKm,
    required this.plate,
    required this.rentalDuration,
    required this.emission,
    required this.distanceKmValue,
    required this.carbonEmissionsValue,
    required this.startDate,
    required this.endDate,
    required this.startTime,
    required this.endTime,
    required this.startPlace,
    required this.endPlace,
    required this.rideCost,
    required this.idleCost,
    required this.totalCost,
    required this.statusRaw,
    required this.isEnded,
    required this.rideSecondsValue,
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
      const monthsEn = [
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
      const monthsId = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final months =
          AppLocalizations.current.locale.languageCode == 'id'
              ? monthsId
              : monthsEn;
      final day = dt.day.toString().padLeft(2, '0');
      final month = months[dt.month - 1];
      return '$day $month ${dt.year}';
    }

    String formatTime(DateTime? dt) {
      if (dt == null) return '-';
      final shifted = dt.add(const Duration(hours: 8));
      final hour = shifted.hour.toString().padLeft(2, '0');
      final minute = shifted.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    String formatDuration(DateTime? start, DateTime? end) {
      if (start == null || end == null) return '-';
      final diff = end.difference(start);
      if (diff.isNegative) return '-';
      final totalSeconds = diff.inSeconds;
      final hours = totalSeconds ~/ 3600;
      final minutes = (totalSeconds % 3600) ~/ 60;
      final l10n = AppLocalizations.current;
      if (hours > 0) {
        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')} ${l10n.durationHour}';
      }
      return '${minutes.toString().padLeft(2, '0')} ${l10n.durationMinute}';
    }

    double normalizeDurationSeconds(double seconds) {
      if (seconds <= 0) return 0;
      if (seconds > 1000000000) {
        return seconds / 1000000; // microseconds
      }
      if (seconds > 10000000) {
        return seconds / 1000; // milliseconds
      }
      return seconds;
    }

    final bike = asMap(json['bike']);
    final emotor = asMap(json['eMotor']) ?? asMap(json['emotor']);
    final startAt = DateTime.tryParse(
        toText(json['start_position_time']) ?? toText(json['start_date_time']) ?? '');
    final endAt = DateTime.tryParse(
        toText(json['end_position_time']) ?? toText(json['end_date_time']) ?? '');
    final rideSeconds = normalizeDurationSeconds(
      toDouble(
        json['ride_time_seconds'] ??
            json['usage_time_seconds'] ??
            json['ride_time'],
      ),
    );
    final statusRaw = toText(
      json['status'] ??
          json['ride_status'] ??
          json['bike_status'] ??
          json['rental_status'] ??
          bike?['status'] ??
          emotor?['status'],
    );
    final isEnded = json['is_end'] == true ||
        json['isEnded'] == true ||
        json['ended'] == true ||
        json['finish'] == true ||
        json['ride_ended'] == true;
    final amountPaid = json['amount_paid'];
    final pauseAmount = json['pause_amount'];
    final startLat = json['start_position_latitude'];
    final startLng = json['start_position_longitude'];
    final endLat = json['end_position_latitude'];
    final endLng = json['end_position_longitude'];
    final distanceMeters =
        toDouble(json['total_distance_meters'] ?? json['distance_m']);
    final carbonEmissions = toDouble(
      json['carbon_emissions'] ??
          json['carbon_reduction'] ??
          json['carbonReduction'] ??
          json['carbon_reduction_grams'] ??
          json['co2_saved'] ??
          json['co2'] ??
          json['carbon'],
    );
    final plate = toText(bike?['vehicle_number'] ?? emotor?['vehicle_number']) ??
        toText(json['plate']) ??
        '-';
    String durationText = '-';
    if (startAt != null && endAt != null) {
      final diff = endAt.difference(startAt);
      if (!diff.isNegative && diff.inSeconds <= 7 * 24 * 3600) {
        final minutes = (diff.inSeconds / 60).round();
        durationText = '$minutes min';
      }
    }
    if (durationText == '-' && rideSeconds > 0) {
      durationText = '${(rideSeconds / 60).round()} min';
    }
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
      distanceKm: formatDistance(distanceMeters),
      plate: plate,
      rentalDuration: formatDuration(startAt, endAt),
      emission: formatNumber(
        json['carbon_emissions'] ??
            json['carbon_reduction'] ??
            json['carbonReduction'] ??
            json['carbon_reduction_grams'] ??
            json['co2_saved'] ??
            json['co2'] ??
            json['carbon'],
        ' g',
      ),
      distanceKmValue: distanceMeters == 0 ? 0 : distanceMeters / 1000,
      carbonEmissionsValue: carbonEmissions,
      startDate: startAt,
      endDate: endAt,
      startTime: formatTime(startAt),
      endTime: formatTime(endAt),
      startPlace: startPlace,
      endPlace: endPlace,
      rideCost: formatCurrency(amountPaid),
      idleCost: pauseAmount == null ? '-' : formatCurrency(pauseAmount),
      totalCost: formatCurrency(amountPaid),
      statusRaw: statusRaw,
      isEnded: isEnded,
      rideSecondsValue: rideSeconds,
    );
  }

  final String id;
  final String date;
  final String durationAndCost;
  final String distanceKm;
  final String plate;
  final String rentalDuration;
  final String emission;
  final double distanceKmValue;
  final double carbonEmissionsValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String startTime;
  final String endTime;
  final String startPlace;
  final String endPlace;
  final String rideCost;
  final String idleCost;
  final String totalCost;
  final String? statusRaw;
  final bool isEnded;
  final double rideSecondsValue;

  bool get isActive {
    if (isEnded) return false;
    final status = statusRaw?.toLowerCase().trim();
    if (status != null && status.isNotEmpty) {
      if (status.contains('running') ||
          status.contains('in_use') ||
          status.contains('in-use') ||
          status.contains('using') ||
          status.contains('active') ||
          status.contains('on_ride')) {
        return true;
      }
    }
    if (startDate != null && endDate == null) return true;
    return false;
  }
}

class MembershipHistoryEntry {
  MembershipHistoryEntry({
    required this.id,
    required this.membershipId,
    required this.status,
    required this.createdAt,
    required this.expiredAt,
    required this.name,
    required this.price,
  });

  factory MembershipHistoryEntry.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? asMap(dynamic value) =>
        value is Map<String, dynamic> ? value : null;
    String text(dynamic value) =>
        value == null ? '' : value.toString().trim();
    num toNum(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value;
      return num.tryParse(value.toString()) ?? 0;
    }

    final membership = asMap(json['membership']) ?? const {};
    final id = text(json['id']);
    final membershipId = text(json['membership_id']).isNotEmpty
        ? text(json['membership_id'])
        : text(membership['id']);
    final status = text(json['status']);
    final createdAt = DateTime.tryParse(text(json['createdAt'])) ??
        DateTime.tryParse(text(json['created_at']));
    final expiredAt = DateTime.tryParse(text(json['expired_at']));
    final name = text(membership['name']);
    final price = toNum(membership['price']);

    return MembershipHistoryEntry(
      id: id,
      membershipId: membershipId,
      status: status,
      createdAt: createdAt,
      expiredAt: expiredAt,
      name: name.isEmpty ? '-' : name,
      price: price.toDouble(),
    );
  }

  final String id;
  final String membershipId;
  final String status;
  final DateTime? createdAt;
  final DateTime? expiredAt;
  final String name;
  final double price;

  bool get isActive => status.toLowerCase().contains('active');
}
