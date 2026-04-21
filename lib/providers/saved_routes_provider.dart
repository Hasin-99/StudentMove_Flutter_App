import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedRoutesProvider extends ChangeNotifier {
  SavedRoutesProvider() {
    load();
  }

  List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _items = prefs.getStringList('saved_routes') ?? [];
    await _syncFromServer();
    notifyListeners();
  }

  Future<void> add(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_items.contains(trimmed)) return;
    _items = [..._items, trimmed];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_routes', _items);
    await _syncWithServer();
    notifyListeners();
  }

  Future<void> remove(String name) async {
    _items = _items.where((e) => e != name).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_routes', _items);
    await _syncWithServer();
    notifyListeners();
  }

  Future<void> _syncWithServer() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('userPreferences').doc(user.uid).set({
        'savedRoutes': _items,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await prefs.setStringList('saved_routes', _items);
    } catch (_) {
      // Silent fail: local UX should not break on network issue.
    }
  }

  Future<void> _syncFromServer() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('userPreferences')
          .doc(user.uid)
          .get();
      final raw = doc.data()?['savedRoutes'];
      if (raw is! List) return;
      final remote = raw.map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
      if (remote.isEmpty) return;
      _items = remote;
      await prefs.setStringList('saved_routes', _items);
    } catch (_) {
      // Silent fail keeps local routes.
    }
  }
}
