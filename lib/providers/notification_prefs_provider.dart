import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notification preference toggles aligned with StudentMove web settings.
class NotificationPrefsProvider extends ChangeNotifier {
  NotificationPrefsProvider() {
    _load();
  }

  static const _delayKey = 'pref_bus_delay';
  static const _routeKey = 'pref_route_change';
  static const _promoKey = 'pref_promotional';

  bool _busDelay = true;
  bool _routeChange = true;
  bool _promotional = true;
  bool _loaded = false;

  bool get busDelay => _busDelay;
  bool get routeChange => _routeChange;
  bool get promotional => _promotional;
  bool get loaded => _loaded;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _busDelay = prefs.getBool(_delayKey) ?? true;
    _routeChange = prefs.getBool(_routeKey) ?? true;
    _promotional = prefs.getBool(_promoKey) ?? true;
    _loaded = true;
    notifyListeners();
    await _hydrateFromServer();
  }

  Future<void> _hydrateFromServer() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data == null) return;
      final notif = data['notifications'];
      if (notif is! Map) return;
      _busDelay = notif['busDelay'] != false;
      _routeChange = notif['routeChange'] != false;
      _promotional = notif['promotional'] != false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_delayKey, _busDelay);
      await prefs.setBool(_routeKey, _routeChange);
      await prefs.setBool(_promoKey, _promotional);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setBusDelay(bool v) => _set(delay: v);
  Future<void> setRouteChange(bool v) => _set(route: v);
  Future<void> setPromotional(bool v) => _set(promo: v);

  Future<void> _set({bool? delay, bool? route, bool? promo}) async {
    if (delay != null) _busDelay = delay;
    if (route != null) _routeChange = route;
    if (promo != null) _promotional = promo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_delayKey, _busDelay);
    await prefs.setBool(_routeKey, _routeChange);
    await prefs.setBool(_promoKey, _promotional);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('userPreferences').doc(user.uid).set({
        'notifications': {
          'busDelay': _busDelay,
          'routeChange': _routeChange,
          'promotional': _promotional,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
