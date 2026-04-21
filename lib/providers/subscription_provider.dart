import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription state synced to Firestore + cached locally.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider() {
    _load();
  }

  static const _planKey = 'sub_plan';
  static const _untilKey = 'sub_until_ms';
  static const _invoiceKey = 'sub_invoices_json';
  static const _statusKey = 'sub_status';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subDocSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _invoicesSub;
  String? _uid;

  String? _planName;
  DateTime? _validUntil;
  List<SubscriptionInvoice> _invoices = const [];
  String? _status;

  String? get planName => _planName;
  DateTime? get validUntil => _validUntil;
  List<SubscriptionInvoice> get invoices => List.unmodifiable(_invoices);
  String? get status => _status;

  bool get hasActiveSubscription =>
      _planName != null &&
      _planName!.isNotEmpty &&
      _validUntil != null &&
      _validUntil!.isAfter(DateTime.now());

  int? get daysRemaining {
    if (_validUntil == null) return null;
    final d = _validUntil!.difference(DateTime.now()).inDays;
    return d < 0 ? 0 : d;
  }

  /// Called by app-level auth binding (ProxyProvider) to start/stop Firestore sync.
  void bindUser(String? uid) {
    final normalized = (uid ?? '').trim();
    final next = normalized.isEmpty ? null : normalized;
    if (next == _uid) return;
    _uid = next;

    _subDocSub?.cancel();
    _subDocSub = null;
    _invoicesSub?.cancel();
    _invoicesSub = null;

    if (_uid == null) {
      // Keep cached values until cleared; prevent showing previous user's cache after logout.
      _planName = null;
      _validUntil = null;
      _status = null;
      _invoices = const [];
      notifyListeners();
      return;
    }

    _listenToFirestore(_uid!);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _planName = prefs.getString(_planKey);
    final ms = prefs.getInt(_untilKey);
    if (ms != null) {
      _validUntil = DateTime.fromMillisecondsSinceEpoch(ms);
    }
    _status = prefs.getString(_statusKey);
    final invoicesRaw = prefs.getString(_invoiceKey);
    if (invoicesRaw != null && invoicesRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(invoicesRaw);
        if (decoded is List) {
          _invoices = decoded
              .whereType<Map>()
              .map((e) => SubscriptionInvoice.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {
        _invoices = const [];
      }
    }
    notifyListeners();
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (_planName == null || _planName!.trim().isEmpty) {
      await prefs.remove(_planKey);
    } else {
      await prefs.setString(_planKey, _planName!);
    }
    if (_validUntil == null) {
      await prefs.remove(_untilKey);
    } else {
      await prefs.setInt(_untilKey, _validUntil!.millisecondsSinceEpoch);
    }
    if (_status == null || _status!.trim().isEmpty) {
      await prefs.remove(_statusKey);
    } else {
      await prefs.setString(_statusKey, _status!);
    }
    await prefs.setString(
      _invoiceKey,
      jsonEncode(_invoices.map((e) => e.toJson()).toList()),
    );
  }

  void _listenToFirestore(String uid) {
    final subDoc = _db.collection('subscriptions').doc(uid);
    _subDocSub = subDoc.snapshots().listen((snap) async {
      final data = snap.data();
      if (data == null) return;
      final plan = '${data['planName'] ?? ''}'.trim();
      final status = '${data['status'] ?? ''}'.trim();
      final vu = data['validUntil'];
      DateTime? validUntil;
      if (vu is Timestamp) validUntil = vu.toDate();
      if (vu is String) validUntil = DateTime.tryParse(vu);

      _planName = plan.isEmpty ? null : plan;
      _status = status.isEmpty ? null : status;
      _validUntil = validUntil;
      await _persistLocal();
      notifyListeners();
    }, onError: (_) {});

    _invoicesSub = subDoc
        .collection('invoices')
        .orderBy('paidAt', descending: true)
        .snapshots()
        .listen((snap) async {
      _invoices = snap.docs.map((d) {
        final data = d.data();
        return SubscriptionInvoice.fromFirestore(id: d.id, data: data);
      }).toList();
      await _persistLocal();
      notifyListeners();
    }, onError: (_) {});
  }

  /// Call when user completes plan selection (stub until payment API exists).
  Future<void> activatePlan(
    String plan,
    Duration duration, {
    double? amount,
    String? paymentMethod,
  }) async {
    _planName = plan;
    _validUntil = DateTime.now().add(duration);
    _status = 'active';
    final invoice = SubscriptionInvoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      planName: plan,
      paidAt: DateTime.now(),
      validUntil: _validUntil!,
      amount: amount ?? 0,
      paymentMethod: paymentMethod ?? 'Unknown',
    );
    _invoices = [invoice, ..._invoices];
    await _persistLocal();
    notifyListeners();

    final uid = _uid;
    if (uid == null) return;
    final subDoc = _db.collection('subscriptions').doc(uid);
    final invoiceDoc = subDoc.collection('invoices').doc(invoice.id);
    try {
      await _db.runTransaction((tx) async {
        tx.set(subDoc, {
          'planName': plan.trim(),
          'status': 'active',
          'validUntil': Timestamp.fromDate(_validUntil!),
          'activePlanSince': FieldValue.serverTimestamp(),
          'lastInvoiceAt': Timestamp.fromDate(invoice.paidAt),
          'lastInvoiceId': invoice.id,
          'lastPaymentMethod': invoice.paymentMethod,
          'lastInvoiceAmount': invoice.amount,
          'totalPaid': FieldValue.increment(invoice.amount),
          'currency': 'BDT',
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        tx.set(invoiceDoc, {
          'planName': invoice.planName,
          'amount': invoice.amount,
          'paymentMethod': invoice.paymentMethod,
          'paidAt': Timestamp.fromDate(invoice.paidAt),
          'validUntil': Timestamp.fromDate(invoice.validUntil),
          'referenceNo': 'SM-INV-${invoice.id}',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      // Keep local state; Firestore sync will catch up when online/rules allow.
    }
  }

  Future<void> clear() async {
    _planName = null;
    _validUntil = null;
    _status = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
    await prefs.remove(_untilKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_invoiceKey);
    notifyListeners();
  }

  Future<void> cancelActivePlan() async {
    _planName = null;
    _validUntil = null;
    _status = 'cancelled';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planKey);
    await prefs.remove(_untilKey);
    // Keep invoices for payment history.
    notifyListeners();

    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('subscriptions').doc(uid).set({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void dispose() {
    _subDocSub?.cancel();
    _invoicesSub?.cancel();
    super.dispose();
  }
}

class SubscriptionInvoice {
  const SubscriptionInvoice({
    required this.id,
    required this.planName,
    required this.paidAt,
    required this.validUntil,
    required this.amount,
    required this.paymentMethod,
  });

  final String id;
  final String planName;
  final DateTime paidAt;
  final DateTime validUntil;
  final double amount;
  final String paymentMethod;

  factory SubscriptionInvoice.fromJson(Map<String, dynamic> json) {
    return SubscriptionInvoice(
      id: '${json['id'] ?? ''}',
      planName: '${json['plan_name'] ?? ''}',
      paidAt: DateTime.tryParse('${json['paid_at'] ?? ''}') ?? DateTime.now(),
      validUntil: DateTime.tryParse('${json['valid_until'] ?? ''}') ?? DateTime.now(),
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0,
      paymentMethod: '${json['payment_method'] ?? 'Unknown'}',
    );
  }

  factory SubscriptionInvoice.fromFirestore({
    required String id,
    required Map<String, dynamic> data,
  }) {
    DateTime _asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return SubscriptionInvoice(
      id: id,
      planName: '${data['planName'] ?? data['plan_name'] ?? ''}',
      paidAt: _asDate(data['paidAt'] ?? data['paid_at']),
      validUntil: _asDate(data['validUntil'] ?? data['valid_until']),
      amount: (data['amount'] is num) ? (data['amount'] as num).toDouble() : 0,
      paymentMethod: '${data['paymentMethod'] ?? data['payment_method'] ?? 'Unknown'}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_name': planName,
        'paid_at': paidAt.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'amount': amount,
        'payment_method': paymentMethod,
      };
}
