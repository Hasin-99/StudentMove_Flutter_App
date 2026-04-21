/// Timetable row: route + weekday + time + bus + origin.
/// Loaded from Firestore when available; else local [all].
class ScheduleSlot {
  const ScheduleSlot({
    required this.routeName,
    required this.dayIndex,
    required this.timeLabel,
    required this.dateLabel,
    required this.origin,
    required this.busCode,
    this.whiteboardNote = '',
    this.universityTags = const [],
  });

  final String routeName;
  /// 0 = Sat … 5 = Thu (matches UI tabs).
  final int dayIndex;
  final String timeLabel;
  final String dateLabel;
  final String origin;
  final String busCode;
  final String whiteboardNote;
  final List<String> universityTags;

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) {
    var tags = <String>[];
    final raw = json['university_tags'] ?? json['universityTags'];
    if (raw is List) {
      tags = raw.map((e) => e.toString()).toList();
    }
    final di = json['day_index'] ?? json['dayIndex'] ?? json['weekday'];
    final dayIndex = di is int ? di : (di is num ? di.toInt() : 0);
    return ScheduleSlot(
      routeName: '${json['route_name'] ?? json['routeName'] ?? ''}',
      dayIndex: dayIndex,
      timeLabel: '${json['time_label'] ?? json['timeLabel'] ?? ''}',
      dateLabel: '${json['date_label'] ?? json['dateLabel'] ?? ''}',
      origin: '${json['origin'] ?? ''}',
      busCode: '${json['bus_code'] ?? json['busCode'] ?? ''}',
      whiteboardNote: '${json['whiteboard_note'] ?? json['whiteboardNote'] ?? ''}',
      universityTags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'route_name': routeName,
        'day_index': dayIndex,
        'time_label': timeLabel,
        'date_label': dateLabel,
        'origin': origin,
        'bus_code': busCode,
        'whiteboard_note': whiteboardNote,
        'university_tags': universityTags,
      };

  static const dayShortLabels = ['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU'];

  static const routes = [
    'Uttara — DSC',
    'Uttara — DU',
    'Dhanmondi — BUET',
  ];

  static const List<ScheduleSlot> all = [
    // Uttara — DSC
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 0,
      timeLabel: '7.00 AM',
      dateLabel: '12 May',
      origin: 'Rajhlokkhi',
      busCode: 'SM-101',
      whiteboardNote: '7.00 AM: Monie(7), Surjomokhi(1)',
      universityTags: ['DSC', 'Dhaka', 'Uttara'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 0,
      timeLabel: '8.30 AM',
      dateLabel: '12 May',
      origin: 'Rajhlokkhi',
      busCode: 'SM-104',
      universityTags: ['DSC', 'Dhaka'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 1,
      timeLabel: '7.15 AM',
      dateLabel: '13 May',
      origin: 'Uttara Sector 7',
      busCode: 'SM-102',
      universityTags: ['DSC'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 1,
      timeLabel: '9.00 AM',
      dateLabel: '13 May',
      origin: 'Uttara Sector 7',
      busCode: 'SM-105',
      universityTags: ['DSC', 'North'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 2,
      timeLabel: '6.45 AM',
      dateLabel: '14 May',
      origin: 'Rajhlokkhi',
      busCode: 'SM-101',
      universityTags: ['DSC'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 2,
      timeLabel: '10.30 AM',
      dateLabel: '14 May',
      origin: 'Abdullahpur',
      busCode: 'SM-108',
      universityTags: ['DSC', 'DU'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 3,
      timeLabel: '7.00 AM',
      dateLabel: '15 May',
      origin: 'Rajhlokkhi',
      busCode: 'SM-103',
      universityTags: ['DSC'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 4,
      timeLabel: '8.00 AM',
      dateLabel: '16 May',
      origin: 'Uttara Sector 10',
      busCode: 'SM-106',
      universityTags: ['DSC'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DSC',
      dayIndex: 5,
      timeLabel: '7.30 AM',
      dateLabel: '17 May',
      origin: 'Rajhlokkhi',
      busCode: 'SM-107',
      universityTags: ['DSC'],
    ),
    // Uttara — DU
    ScheduleSlot(
      routeName: 'Uttara — DU',
      dayIndex: 0,
      timeLabel: '6.30 AM',
      dateLabel: '12 May',
      origin: 'Uttara North',
      busCode: 'SM-201',
      universityTags: ['DU', 'Dhaka University', 'TSC'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DU',
      dayIndex: 0,
      timeLabel: '9.15 AM',
      dateLabel: '12 May',
      origin: 'Uttara North',
      busCode: 'SM-203',
      universityTags: ['DU'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DU',
      dayIndex: 2,
      timeLabel: '7.45 AM',
      dateLabel: '14 May',
      origin: 'Abdullahpur',
      busCode: 'SM-202',
      universityTags: ['DU', 'Shahbagh'],
    ),
    ScheduleSlot(
      routeName: 'Uttara — DU',
      dayIndex: 3,
      timeLabel: '5.45 PM',
      dateLabel: '15 May',
      origin: 'DU Campus',
      busCode: 'SM-205',
      universityTags: ['DU', 'Return'],
    ),
    // Dhanmondi — BUET
    ScheduleSlot(
      routeName: 'Dhanmondi — BUET',
      dayIndex: 0,
      timeLabel: '7.20 AM',
      dateLabel: '12 May',
      origin: 'Dhanmondi 27',
      busCode: 'SM-301',
      universityTags: ['BUET', 'Palashi'],
    ),
    ScheduleSlot(
      routeName: 'Dhanmondi — BUET',
      dayIndex: 1,
      timeLabel: '8.00 AM',
      dateLabel: '13 May',
      origin: 'Kalabagan',
      busCode: 'SM-302',
      universityTags: ['BUET'],
    ),
    ScheduleSlot(
      routeName: 'Dhanmondi — BUET',
      dayIndex: 4,
      timeLabel: '6.15 PM',
      dateLabel: '16 May',
      origin: 'BUET Gate',
      busCode: 'SM-303',
      universityTags: ['BUET', 'Evening'],
    ),
  ];

  static List<ScheduleSlot> filtered({
    required Iterable<ScheduleSlot> source,
    required String routeName,
    required int dayIndex,
    required String universityQuery,
  }) {
    final q = universityQuery.trim().toLowerCase();
    return source.where((s) {
      if (s.routeName != routeName) return false;
      if (s.dayIndex != dayIndex) return false;
      if (q.isEmpty) return true;
      if (routeName.toLowerCase().contains(q)) return true;
      for (final t in s.universityTags) {
        if (t.toLowerCase().contains(q)) return true;
      }
      if (s.origin.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}
