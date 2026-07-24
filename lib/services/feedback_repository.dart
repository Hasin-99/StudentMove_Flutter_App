import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/app_error.dart';

class FeedbackItem {
  const FeedbackItem({
    required this.id,
    required this.subject,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.reply,
    this.status = 'open',
  });

  final String id;
  final String subject;
  final String message;
  final int rating;
  final DateTime createdAt;
  final String? reply;
  final String status;

  factory FeedbackItem.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return FeedbackItem(
      id: id,
      subject: '${data['subject'] ?? ''}',
      message: '${data['message'] ?? data['review'] ?? ''}',
      rating: (data['rating'] is num) ? (data['rating'] as num).toInt() : 5,
      createdAt: asDate(data['createdAt'] ?? data['created_at']),
      reply: data['reply'] == null ? null : '${data['reply']}',
      status: '${data['status'] ?? 'open'}',
    );
  }
}

class FeedbackRepository extends ChangeNotifier {
  FeedbackRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<FeedbackItem> _items = const [];
  bool _loading = false;
  String? _lastError;
  String? _uid;

  List<FeedbackItem> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get lastError => _lastError;

  void bindUser(String? uid) {
    final next = (uid ?? '').trim();
    if (next == (_uid ?? '')) return;
    _uid = next.isEmpty ? null : next;
    if (_uid == null) {
      _items = const [];
      notifyListeners();
      return;
    }
    refresh();
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('feedback')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      _items = snap.docs
          .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
          .toList();
      _lastError = null;
    } catch (e, st) {
      try {
        final snap = await _db
            .collection('feedback')
            .where('userId', isEqualTo: uid)
            .limit(30)
            .get();
        final list = snap.docs
            .map((d) => FeedbackItem.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _items = list;
        _lastError = null;
      } catch (e2, st2) {
        _lastError = ErrorMapper.from(e2, st2).message;
        debugPrint('feedback refresh fallback: ${ErrorMapper.from(e, st)}');
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required String subject,
    required String message,
    required int rating,
    String category = 'general',
  }) async {
    final uid = _uid;
    if (uid == null) {
      _lastError = 'Sign in required';
      notifyListeners();
      return false;
    }
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      _lastError = 'Please describe your feedback';
      notifyListeners();
      return false;
    }
    final doc = _db.collection('feedback').doc();
    final item = FeedbackItem(
      id: doc.id,
      subject: subject.trim().isEmpty ? category : subject.trim(),
      message: trimmed,
      rating: rating.clamp(1, 5),
      createdAt: DateTime.now(),
      status: 'open',
    );
    try {
      await doc.set({
        'userId': uid,
        'subject': item.subject,
        'message': item.message,
        'rating': item.rating,
        'category': category,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _items = [item, ..._items];
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e, st) {
      _items = [item, ..._items];
      _lastError =
          'Saved on device. ${ErrorMapper.from(e, st).message}';
      notifyListeners();
      return true;
    }
  }
}
