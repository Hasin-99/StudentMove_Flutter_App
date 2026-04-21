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
  });

  final String id;
  final String busCode;
  final double lat;
  final double lng;
  final double heading;
  final double speedKmph;
  final DateTime updatedAt;
  final String source;

  factory LiveBus.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) => (v is num) ? v.toDouble() : 0;

    return LiveBus(
      id: '${json['id'] ?? ''}',
      busCode: '${json['bus_code'] ?? ''}',
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      heading: _toDouble(json['heading']),
      speedKmph: _toDouble(json['speed_kmph']),
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? ''}') ?? DateTime.now(),
      source: '${json['source'] ?? 'gps'}',
    );
  }
}
