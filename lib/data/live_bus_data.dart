enum GpsFreshness { live, stale, waiting, offline }

class LiveBus {
  const LiveBus({
    required this.id,
    required this.busCode,
    required this.lat,
    required this.lng,
    required this.heading,
    required this.speedKmph,
    required this.updatedAt,
    this.source = 'gps',
    this.routeName = '',
    this.status = 'on_time',
    this.delayMinutes = 0,
  });

  final String id;
  final String busCode;
  final double lat;
  final double lng;
  final double heading;
  final double speedKmph;
  final DateTime updatedAt;
  final String source;
  final String routeName;
  final String status;
  final int delayMinutes;

  /// Fresh if pinged within 45s (matches StudentMove web).
  bool get isGpsFresh =>
      DateTime.now().difference(updatedAt).inSeconds <= 45;

  /// Stale after 45s, offline after 120s without updates.
  GpsFreshness get gpsFreshness {
    final age = DateTime.now().difference(updatedAt).inSeconds;
    if (lat == 0 && lng == 0) return GpsFreshness.waiting;
    if (age <= 45) return GpsFreshness.live;
    if (age <= 120) return GpsFreshness.stale;
    return GpsFreshness.offline;
  }

  String get gpsLabel {
    return switch (gpsFreshness) {
      GpsFreshness.live => 'GPS live',
      GpsFreshness.stale => 'GPS stale',
      GpsFreshness.waiting => 'Waiting for GPS',
      GpsFreshness.offline => 'GPS offline',
    };
  }

  String get etaText {
    if (delayMinutes >= 3) return 'Delayed · +$delayMinutes min';
    if (speedKmph <= 0.5) return 'Arriving soon';
    final mins = (5 / (speedKmph / 60)).clamp(3, 45).round();
    return 'ETA ~$mins min';
  }

  factory LiveBus.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => (v is num) ? v.toDouble() : 0;

    return LiveBus(
      id: '${json['id'] ?? ''}',
      busCode: '${json['bus_code'] ?? json['busCode'] ?? ''}',
      lat: toDouble(json['lat']),
      lng: toDouble(json['lng']),
      heading: toDouble(json['heading']),
      speedKmph: toDouble(json['speed_kmph'] ?? json['speedKmph']),
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? json['updatedAt'] ?? ''}') ??
              DateTime.now(),
      source: '${json['source'] ?? 'gps'}',
      routeName: '${json['route_name'] ?? json['routeName'] ?? ''}',
      status: '${json['status'] ?? 'on_time'}',
      delayMinutes: (json['delay_minutes'] is num)
          ? (json['delay_minutes'] as num).toInt()
          : (json['delayMinutes'] is num)
              ? (json['delayMinutes'] as num).toInt()
              : 0,
    );
  }
}
