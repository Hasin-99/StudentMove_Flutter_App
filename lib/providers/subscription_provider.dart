import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Local subscription state persisted on device.
class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider() {
    _load();
  }

  static const _planKey = 'sub_plan';
  static const _untilKey = 'sub_until_ms';
  static const _invoiceKey = 'sub_invoices_json';

  String? _planName;
  DateTime? _validUntil;
  List<SubscriptionInvoice> _invoices = const [];

  String? get planName => _planName;
  DateTime? get validUntil => _validUntil;
  List<SubscriptionInvoice> get invoices => List.unmodifiable(_invoices);

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

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _planName = prefs.getString(_planKey);
    final ms = prefs.getInt(_untilKey);
    if (ms != null) {
      _validUntil = DateTime.fromMillisecondsSinceEpoch(ms);
    }
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

  /// Call when user completes plan selection (stub until payment API exists).
  Future<void> activatePlan(
    String plan,
    Duration duration, {
    double? amount,
    String? paymentMethod,
  }) async {
    final prevPlan = _planName;
    final prevValidUntil = _validUntil;
    final prevInvoices = List<SubscriptionInvoice>.from(_invoices);
    try {
      _planName = plan;
      _validUntil = DateTime.now().add(duration);
      final invoice = SubscriptionInvoice(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        planName: plan,
        paidAt: DateTime.now(),
        validUntil: _validUntil!,
        amount: amount ?? 0,
        paymentMethod: paymentMethod ?? 'Unknown',
      );
      _invoices = [invoice, ..._invoices];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, plan);
      await prefs.setInt(_untilKey, _validUntil!.millisecondsSinceEpoch);
      await prefs.setString(
        _invoiceKey,
        jsonEncode(_invoices.map((e) => e.toJson()).toList()),
      );
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('activatePlan failed: $e');
      }
      // Roll back in-memory state when persistence fails.
      _planName = prevPlan;
      _validUntil = prevValidUntil;
      _invoices = prevInvoices;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> clear() async {
    final prevPlan = _planName;
    final prevValidUntil = _validUntil;
    final prevInvoices = List<SubscriptionInvoice>.from(_invoices);
    try {
      _planName = null;
      _validUntil = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_planKey);
      await prefs.remove(_untilKey);
      await prefs.remove(_invoiceKey);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('clear subscription failed: $e');
      }
      _planName = prevPlan;
      _validUntil = prevValidUntil;
      _invoices = prevInvoices;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> cancelActivePlan() async {
    final prevPlan = _planName;
    final prevValidUntil = _validUntil;
    final prevInvoices = List<SubscriptionInvoice>.from(_invoices);
    try {
      _planName = null;
      _validUntil = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_planKey);
      await prefs.remove(_untilKey);
      // Keep invoices for payment history.
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('cancelActivePlan failed: $e');
      }
      _planName = prevPlan;
      _validUntil = prevValidUntil;
      _invoices = prevInvoices;
      notifyListeners();
      rethrow;
    }
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'plan_name': planName,
        'paid_at': paidAt.toIso8601String(),
        'valid_until': validUntil.toIso8601String(),
        'amount': amount,
        'payment_method': paymentMethod,
      };
}
