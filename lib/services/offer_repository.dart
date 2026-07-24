import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/app_error.dart';

class OfferItem {
  const OfferItem({
    required this.id,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.validUntil,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final int discountPercent;
  final DateTime validUntil;
  final bool isActive;

  factory OfferItem.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now().add(const Duration(days: 14));
      return DateTime.now().add(const Duration(days: 14));
    }

    return OfferItem(
      id: id,
      title: '${data['title'] ?? ''}',
      description: '${data['description'] ?? ''}',
      discountPercent: (data['discountPercent'] is num)
          ? (data['discountPercent'] as num).toInt()
          : (data['discount_percentage'] is num)
              ? (data['discount_percentage'] as num).toInt()
              : 0,
      validUntil: asDate(data['validUntil'] ?? data['valid_until']),
      isActive: data['isActive'] != false && data['is_active'] != false,
    );
  }
}

class OfferRepository extends ChangeNotifier {
  OfferRepository() {
    refresh();
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<OfferItem> _offers = const [];
  bool _loading = false;
  String? _lastError;

  List<OfferItem> get offers => List.unmodifiable(_offers);
  bool get loading => _loading;
  String? get lastError => _lastError;

  static final demoOffers = <OfferItem>[
    OfferItem(
      id: 'demo-weekly',
      title: 'Student Weekly Pass',
      description: 'Unlimited rides for 7 days — best for exam week.',
      discountPercent: 15,
      validUntil: DateTime.now().add(const Duration(days: 21)),
    ),
    OfferItem(
      id: 'demo-referral',
      title: 'Refer a classmate',
      description: 'Share StudentMove and unlock a free single ride.',
      discountPercent: 100,
      validUntil: DateTime.now().add(const Duration(days: 60)),
    ),
    OfferItem(
      id: 'demo-monthly',
      title: 'Monthly Pass Boost',
      description: 'Save on the Monthly Pass this semester.',
      discountPercent: 10,
      validUntil: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      final snap = await _db
          .collection('offers')
          .where('isActive', isEqualTo: true)
          .limit(20)
          .get();
      final now = DateTime.now();
      final list = snap.docs
          .map((d) => OfferItem.fromFirestore(d.id, d.data()))
          .where((o) => o.isActive && o.validUntil.isAfter(now))
          .toList();
      list.sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
      _offers = list.isEmpty ? demoOffers : list;
      _lastError = null;
    } catch (e, st) {
      _offers = demoOffers;
      _lastError = ErrorMapper.from(e, st).message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
