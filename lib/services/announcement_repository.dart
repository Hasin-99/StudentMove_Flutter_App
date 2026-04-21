import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/announcement_data.dart';

class AnnouncementRepository extends ChangeNotifier {
  List<AnnouncementItem> _items = const [];
  bool _loading = false;
  String? _lastError;

  List<AnnouncementItem> get items => _items;
  bool get loading => _loading;
  String? get lastError => _lastError;

  Future<void> refresh({String? email, String? department, List<String>? routes}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('publishAt', descending: true)
          .get();

      final dep = department?.trim().toLowerCase() ?? '';
      final routeSet = (routes ?? const <String>[])
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet();

      final now = DateTime.now();
      _items = snap.docs.where((doc) {
        final d = doc.data();
        // Admin panel uses isActive + targetDepartments/targetRoutes; older data may use isVisible/departments/routes.
        final inactive = d['isActive'] == false || d['isVisible'] == false;
        if (inactive) return false;
        final expiresAt = d['expiresAt'];
        if (expiresAt is Timestamp && expiresAt.toDate().isBefore(now)) {
          return false;
        }
        List<dynamic> depList = (d['departments'] as List<dynamic>?) ?? const [];
        if (depList.isEmpty) {
          depList = (d['targetDepartments'] as List<dynamic>?) ?? const [];
        }
        List<dynamic> routeList = (d['routes'] as List<dynamic>?) ?? const [];
        if (routeList.isEmpty) {
          routeList = (d['targetRoutes'] as List<dynamic>?) ?? const [];
        }
        final targetDeps = depList
            .map((e) => '$e'.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();
        final targetRoutes = routeList
            .map((e) => '$e'.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();
        final depMatch = targetDeps.isEmpty || (dep.isNotEmpty && targetDeps.contains(dep));
        final routeMatch =
            targetRoutes.isEmpty || routeSet.any((route) => targetRoutes.contains(route));
        return depMatch && routeMatch;
      }).map((doc) {
        final d = doc.data();
        final publishAt = d['publishAt'];
        return AnnouncementItem.fromJson({
          'id': doc.id,
          'title': d['title'],
          'body': d['body'],
          'is_pinned': d['isPinned'],
          'publish_at': publishAt is Timestamp
              ? publishAt.toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        });
      }).toList();
      _lastError = null;
    } catch (e) {
      _items = const [];
      _lastError = '$e';
    }

    _loading = false;
    notifyListeners();
  }
}
