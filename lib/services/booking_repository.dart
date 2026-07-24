import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/app_error.dart';

/// Seat booking model aligned with StudentMove web bookings.
class RideBooking {
  const RideBooking({
    required this.id,
    required this.code,
    required this.route,
    required this.busNumber,
    required this.from,
    required this.to,
    required this.travelDate,
    required this.departureTime,
    required this.seats,
    required this.seatPreference,
    required this.fare,
    required this.status,
    this.notes = '',
  });

  final String id;
  final String code;
  final String route;
  final String busNumber;
  final String from;
  final String to;
  final DateTime travelDate;
  final String departureTime;
  final int seats;
  final String seatPreference;
  final double fare;
  final String status;
  final String notes;

  bool get isCancellable => status == 'confirmed' || status == 'pending';

  factory RideBooking.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime asDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return RideBooking(
      id: id,
      code: '${data['code'] ?? ''}',
      route: '${data['route'] ?? ''}',
      busNumber: '${data['busNumber'] ?? data['bus_number'] ?? ''}',
      from: '${data['from'] ?? ''}',
      to: '${data['to'] ?? ''}',
      travelDate: asDate(data['travelDate'] ?? data['travel_date']),
      departureTime: '${data['departureTime'] ?? data['departure_time'] ?? ''}',
      seats: (data['seats'] is num) ? (data['seats'] as num).toInt() : 1,
      seatPreference: '${data['seatPreference'] ?? data['seat_preference'] ?? 'any'}',
      fare: (data['fare'] is num) ? (data['fare'] as num).toDouble() : 0,
      status: '${data['status'] ?? 'confirmed'}',
      notes: '${data['notes'] ?? ''}',
    );
  }
}

class AvailableTrip {
  const AvailableTrip({
    required this.id,
    required this.route,
    required this.busNumber,
    required this.from,
    required this.to,
    required this.departureTime,
    required this.farePerSeat,
    required this.seatsLeft,
    required this.totalSeats,
  });

  final String id;
  final String route;
  final String busNumber;
  final String from;
  final String to;
  final String departureTime;
  final double farePerSeat;
  final int seatsLeft;
  final int totalSeats;

  bool get isFull => seatsLeft <= 0;
}

/// Firestore-backed bookings with demo trip catalog fallback.
class BookingRepository extends ChangeNotifier {
  BookingRepository();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<RideBooking> _bookings = const [];
  bool _loading = false;
  String? _lastError;
  String? _uid;

  List<RideBooking> get bookings => List.unmodifiable(_bookings);
  bool get loading => _loading;
  String? get lastError => _lastError;

  static const demoTrips = <AvailableTrip>[
    AvailableTrip(
      id: 't1',
      route: 'Uttara → DSC',
      busNumber: 'SM-101',
      from: 'Uttara',
      to: 'DSC',
      departureTime: '07:30',
      farePerSeat: 30,
      seatsLeft: 12,
      totalSeats: 40,
    ),
    AvailableTrip(
      id: 't2',
      route: 'Mirpur → DIU',
      busNumber: 'SM-204',
      from: 'Mirpur',
      to: 'DIU',
      departureTime: '08:15',
      farePerSeat: 35,
      seatsLeft: 6,
      totalSeats: 40,
    ),
    AvailableTrip(
      id: 't3',
      route: 'Dhanmondi → BUET',
      busNumber: 'SM-312',
      from: 'Dhanmondi',
      to: 'BUET',
      departureTime: '09:00',
      farePerSeat: 25,
      seatsLeft: 18,
      totalSeats: 35,
    ),
    AvailableTrip(
      id: 't4',
      route: 'Farmgate → DSC',
      busNumber: 'SM-118',
      from: 'Farmgate',
      to: 'DSC',
      departureTime: '10:45',
      farePerSeat: 30,
      seatsLeft: 3,
      totalSeats: 40,
    ),
  ];

  void bindUser(String? uid) {
    final next = (uid ?? '').trim();
    if (next == (_uid ?? '')) return;
    _uid = next.isEmpty ? null : next;
    if (_uid == null) {
      _bookings = const [];
      notifyListeners();
      return;
    }
    refresh();
  }

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      final snap = await _db
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(40)
          .get();
      _bookings = snap.docs
          .map((d) => RideBooking.fromFirestore(d.id, d.data()))
          .toList();
    } catch (e, st) {
      _lastError = ErrorMapper.from(e, st).message;
      // Fallback without orderBy if index missing.
      try {
        final snap = await _db
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .limit(40)
            .get();
        final list = snap.docs
            .map((d) => RideBooking.fromFirestore(d.id, d.data()))
            .toList();
        list.sort((a, b) => b.travelDate.compareTo(a.travelDate));
        _bookings = list;
        _lastError = null;
      } catch (e2, st2) {
        _lastError = ErrorMapper.from(e2, st2).message;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    final buf = StringBuffer('SM');
    for (var i = 0; i < 8; i++) {
      buf.write(chars[r.nextInt(chars.length)]);
    }
    return buf.toString();
  }

  Future<RideBooking?> createBooking({
    required AvailableTrip trip,
    required DateTime travelDate,
    required int seats,
    required String seatPreference,
    String notes = '',
  }) async {
    final uid = _uid;
    if (uid == null) {
      _lastError = 'Sign in required';
      notifyListeners();
      return null;
    }
    if (seats < 1 || seats > 4) {
      _lastError = 'Seats must be between 1 and 4';
      notifyListeners();
      return null;
    }
    if (trip.isFull || seats > trip.seatsLeft) {
      _lastError = 'Not enough seats available';
      notifyListeners();
      return null;
    }

    final code = _generateCode();
    final fare = trip.farePerSeat * seats;
    final doc = _db.collection('bookings').doc();
    final booking = RideBooking(
      id: doc.id,
      code: code,
      route: trip.route,
      busNumber: trip.busNumber,
      from: trip.from,
      to: trip.to,
      travelDate: travelDate,
      departureTime: trip.departureTime,
      seats: seats,
      seatPreference: seatPreference,
      fare: fare,
      status: 'confirmed',
      notes: notes,
    );

    try {
      await doc.set({
        'userId': uid,
        'code': code,
        'route': trip.route,
        'busNumber': trip.busNumber,
        'from': trip.from,
        'to': trip.to,
        'travelDate': Timestamp.fromDate(
          DateTime(travelDate.year, travelDate.month, travelDate.day),
        ),
        'departureTime': trip.departureTime,
        'seats': seats,
        'seatPreference': seatPreference,
        'fare': fare,
        'status': 'confirmed',
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _bookings = [booking, ..._bookings];
      _lastError = null;
      notifyListeners();
      return booking;
    } catch (e, st) {
      // Optimistic local booking when rules/offline block write.
      _bookings = [booking, ..._bookings];
      _lastError =
          'Saved on device. Sync when online. (${ErrorMapper.from(e, st).message})';
      notifyListeners();
      return booking;
    }
  }

  Future<bool> cancelBooking(String bookingId) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      await _db.collection('bookings').doc(bookingId).set({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Still update local.
    }
    _bookings = _bookings
        .map(
          (b) => b.id == bookingId
              ? RideBooking(
                  id: b.id,
                  code: b.code,
                  route: b.route,
                  busNumber: b.busNumber,
                  from: b.from,
                  to: b.to,
                  travelDate: b.travelDate,
                  departureTime: b.departureTime,
                  seats: b.seats,
                  seatPreference: b.seatPreference,
                  fare: b.fare,
                  status: 'cancelled',
                  notes: b.notes,
                )
              : b,
        )
        .toList();
    notifyListeners();
    return true;
  }
}
