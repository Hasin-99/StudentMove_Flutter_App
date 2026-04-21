import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../theme/app_theme.dart';

/// GPS broadcast companion for driver-side live location workflow.
class DriverCompanionScreen extends StatefulWidget {
  const DriverCompanionScreen({super.key});

  @override
  State<DriverCompanionScreen> createState() => _DriverCompanionScreenState();
}

class _DriverCompanionScreenState extends State<DriverCompanionScreen> {
  bool _broadcasting = false;
  bool _requesting = false;
  String? _status;
  Position? _lastPosition;
  StreamSubscription<Position>? _positionSub;
  String _manualPointKey = 'dsc_gate';

  static const Map<String, ({String label, double lat, double lng})> _manualPoints = {
    'dsc_gate': (label: 'DIU/DSC Gate', lat: 23.8103, lng: 90.4125),
    'uttara': (label: 'Uttara Stop', lat: 23.8750, lng: 90.3820),
    'airport_road': (label: 'Airport Road Stop', lat: 23.8500, lng: 90.3950),
    'ashulia': (label: 'Ashulia Segment', lat: 23.8200, lng: 90.4050),
  };

  String get _docId {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) return uid;
    return 'driver_demo';
  }

  String _busCode() {
    final name = FirebaseAuth.instance.currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      final segments = name.split(' ').where((e) => e.isNotEmpty).toList();
      final first = segments.isEmpty ? 'DRV' : segments.first;
      return 'BUS-${first.toUpperCase()}';
    }
    return 'BUS-DEMO';
  }

  Future<bool> _ensureLocationReady() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() => _status = 'Location services are disabled.');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() => _status = 'Location permission is denied.');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _status = 'Location permission setup error: $e');
      return false;
    }
  }

  Future<void> _startBroadcast() async {
    if (_broadcasting || _requesting) return;
    setState(() => _requesting = true);

    final ready = await _ensureLocationReady();
    if (!ready) {
      if (!mounted) return;
      setState(() => _requesting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location service/permission.')),
      );
      return;
    }

    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) async {
      _lastPosition = pos;
      try {
        await FirebaseFirestore.instance.collection('liveBuses').doc(_docId).set({
          'busCode': _busCode(),
          'lat': pos.latitude,
          'lng': pos.longitude,
          'heading': pos.heading.isNaN ? 0.0 : pos.heading,
          'speedKmph': (pos.speed * 3.6).clamp(0, 180),
          'source': 'gps',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        if (mounted) {
          setState(() => _status = 'Broadcasting live location.');
        }
      } catch (e) {
        if (mounted) setState(() => _status = 'Failed to sync: $e');
      }
    }, onError: (e) {
      if (mounted) setState(() => _status = 'Location stream error: $e');
    });

    if (!mounted) return;
    setState(() {
      _broadcasting = true;
      _requesting = false;
      _status = 'Broadcasting live location.';
    });
  }

  Future<void> _stopBroadcast() async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (!mounted) return;
    setState(() {
      _broadcasting = false;
      _status = 'Broadcast stopped.';
    });
  }

  Future<void> _sendManualLocation() async {
    final p = _manualPoints[_manualPointKey];
    if (p == null) return;
    try {
      await FirebaseFirestore.instance.collection('liveBuses').doc(_docId).set({
        'busCode': _busCode(),
        'lat': p.lat,
        'lng': p.lng,
        'heading': 0.0,
        'speedKmph': 0.0,
        'source': 'manual',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _status = 'Manual location sent: ${p.label}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manual location sent: ${p.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Manual location failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manual location failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.driverTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tripStatus,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _broadcasting
                        ? (s.isBangla ? 'চলছে — লোকেশন প্রতি ১০ সেকেন্ডে পাঠানো হবে' : 'En route — location every 10s to backend')
                        : (s.isBangla ? 'অপেক্ষমান' : 'Idle'),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.muted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_status != null) ...[
                    Text(
                      _status!,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_lastPosition != null) ...[
                    Text(
                      'Lat: ${_lastPosition!.latitude.toStringAsFixed(6)} | '
                      'Lng: ${_lastPosition!.longitude.toStringAsFixed(6)}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        Icons.battery_charging_full_rounded,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s.isBangla ? 'ব্যাটারি: ডিভাইস রিপোর্ট' : 'Battery: from device',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.signal_cellular_alt_rounded, color: AppColors.brand),
                      const SizedBox(width: 8),
                      Text(
                        s.isBangla ? 'সংযোগ: নেটওয়ার্ক স্ট্যাটাস' : 'Connection: network status',
                        style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _requesting
                ? null
                : () async {
                    if (_broadcasting) {
                      await _stopBroadcast();
                    } else {
                      await _startBroadcast();
                    }
                  },
            icon: Icon(_broadcasting ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(_requesting ? 'Starting...' : (_broadcasting ? s.stopTrip : s.startTrip)),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _broadcasting ? const Color(0xFFDC2626) : AppColors.brand,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _manualPointKey,
            decoration: InputDecoration(
              labelText: s.isBangla ? 'ম্যানুয়াল লোকেশন' : 'Manual location point',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _manualPoints.entries
                .map(
                  (e) => DropdownMenuItem<String>(
                    value: e.key,
                    child: Text(e.value.label),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _manualPointKey = v);
            },
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _requesting ? null : _sendManualLocation,
            icon: const Icon(Icons.place_rounded),
            label: Text(s.isBangla ? 'ম্যানুয়াল লোকেশন পাঠান' : 'Send manual location'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
