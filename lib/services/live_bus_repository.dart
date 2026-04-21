import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../data/live_bus_data.dart';

class LiveBusRepository extends ChangeNotifier {
  List<LiveBus> _buses = const [];
  bool _loading = false;
  String? _lastError;
  Timer? _timer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  List<LiveBus> get buses => _buses;
  bool get loading => _loading;
  String? get lastError => _lastError;

  void startPolling() {
    _timer?.cancel();
    _sub?.cancel();
    refresh();
    _sub = FirebaseFirestore.instance.collection('liveBuses').snapshots().listen((snap) {
      _buses = snap.docs.map((doc) {
        final d = doc.data();
        final updatedAt = d['updatedAt'];
        return LiveBus.fromJson({
          'id': doc.id,
          'bus_code': d['busCode'],
          'lat': d['lat'],
          'lng': d['lng'],
          'heading': d['heading'],
          'speed_kmph': d['speedKmph'],
          'updated_at': updatedAt is Timestamp
              ? updatedAt.toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        });
      }).toList();
      _loading = false;
      _lastError = null;
      notifyListeners();
    }, onError: (e) {
      _lastError = '$e';
      notifyListeners();
    });
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
    _sub?.cancel();
    _sub = null;
  }

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await FirebaseFirestore.instance.collection('liveBuses').get();
      _buses = snap.docs.map((doc) {
        final d = doc.data();
        final updatedAt = d['updatedAt'];
        return LiveBus.fromJson({
          'id': doc.id,
          'bus_code': d['busCode'],
          'lat': d['lat'],
          'lng': d['lng'],
          'heading': d['heading'],
          'speed_kmph': d['speedKmph'],
          'updated_at': updatedAt is Timestamp
              ? updatedAt.toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
        });
      }).toList();
      _lastError = null;
    } catch (e) {
      _lastError = '$e';
    }
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
