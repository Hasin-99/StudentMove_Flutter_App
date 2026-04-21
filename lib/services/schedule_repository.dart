import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/schedule_data.dart';

/// Fetches schedules from Firestore; on any failure uses bundled [ScheduleSlot.all].
class ScheduleRepository extends ChangeNotifier {
  ScheduleRepository() : _slots = List<ScheduleSlot>.from(ScheduleSlot.all);

  List<ScheduleSlot> _slots;
  bool _loading = false;
  String? _lastError;
  bool _fromApi = false;

  List<ScheduleSlot> get slots => _slots;
  bool get loading => _loading;
  String? get lastError => _lastError;
  bool get fromApi => _fromApi;

  /// Distinct route names for the dropdown (falls back to static list if empty).
  List<String> get routeNames {
    final names = _slots.map((s) => s.routeName).toSet().toList()..sort();
    if (names.isNotEmpty) return names;
    return List<String>.from(ScheduleSlot.routes);
  }

  Future<void> refresh() async {
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Admin writes `weekday` (0–5); legacy/docs may use `dayIndex`. Query must match real fields.
      final snap = await FirebaseFirestore.instance
          .collection('schedules')
          .orderBy('routeName')
          .orderBy('weekday')
          .get();
      if (snap.docs.isEmpty) {
        _lastError = 'No schedules found in Firestore';
        _slots = List<ScheduleSlot>.from(ScheduleSlot.all);
        _fromApi = false;
      } else {
        _slots = snap.docs.map((doc) {
          final d = doc.data();
          final dayRaw = d['dayIndex'] ?? d['weekday'];
          return ScheduleSlot.fromJson({
            'route_name': d['routeName'],
            'day_index': dayRaw,
            'time_label': d['timeLabel'],
            'date_label': d['dateLabel'],
            'origin': d['origin'],
            'bus_code': d['busCode'],
            'whiteboard_note': d['whiteboardNote'],
            'university_tags': d['universityTags'],
          });
        }).toList();
        _fromApi = true;
        _lastError = null;
      }
    } catch (e) {
      _lastError = e.toString();
      _slots = List<ScheduleSlot>.from(ScheduleSlot.all);
      _fromApi = false;
    }

    _loading = false;
    notifyListeners();
  }
}
