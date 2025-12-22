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
    return HistoryEntry(
      id: json['id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      durationAndCost: json['duration_and_cost']?.toString() ??
          json['durationAndCost']?.toString() ??
          '',
      distanceKm: json['distance_km']?.toString() ??
          json['distance']?.toString() ??
          '${json['distance'] ?? '-'} km',
      plate: json['plate']?.toString() ?? '-',
      calories: json['calories']?.toString() ?? '-',
      emission: json['emission']?.toString() ?? '-',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      startPlace: json['start_place']?.toString() ?? '',
      endPlace: json['end_place']?.toString() ?? '',
      rideCost: json['ride_cost']?.toString() ?? '',
      idleCost: json['idle_cost']?.toString() ?? '',
      totalCost: json['total_cost']?.toString() ?? '',
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
