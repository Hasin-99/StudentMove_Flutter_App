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

/// Driver GPS companion — dark phone-first UI matching StudentMove web driver panel.
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
  String _tripStatus = 'on_time';

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
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _status = 'Location permission is denied.');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _status = 'Location permission setup error: $e');
      return false;
    }
  }

  Future<void> _publish({
    required double lat,
    required double lng,
    required double heading,
    required double speedKmph,
    required String source,
  }) async {
    await FirebaseFirestore.instance.collection('liveBuses').doc(_docId).set({
      'busCode': _busCode(),
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speedKmph': speedKmph,
      'source': source,
      'status': _tripStatus,
      'delayMinutes': _tripStatus == 'delayed' ? 5 : 0,
      'routeName': 'Campus shuttle',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _setTripStatus(String status) async {
    setState(() => _tripStatus = status);
    final pos = _lastPosition;
    if (pos != null) {
      try {
        await _publish(
          lat: pos.latitude,
          lng: pos.longitude,
          heading: pos.heading.isNaN ? 0.0 : pos.heading,
          speedKmph: (pos.speed * 3.6).clamp(0, 180),
          source: 'gps',
        );
      } catch (_) {}
    } else {
      try {
        await FirebaseFirestore.instance.collection('liveBuses').doc(_docId).set({
          'status': status,
          'delayMinutes': status == 'delayed' ? 5 : 0,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
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
        await _publish(
          lat: pos.latitude,
          lng: pos.longitude,
          heading: pos.heading.isNaN ? 0.0 : pos.heading,
          speedKmph: (pos.speed * 3.6).clamp(0, 180),
          source: 'gps',
        );
        if (mounted) {
          setState(() => _status = 'Live · sending to students');
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
      _status = 'Live · sending to students';
    });
  }

  Future<void> _stopBroadcast() async {
    await _positionSub?.cancel();
    _positionSub = null;
    if (!mounted) return;
    setState(() {
      _broadcasting = false;
      _status = 'Shift ended';
    });
  }

  Future<void> _sendManualLocation() async {
    final p = _manualPoints[_manualPointKey];
    if (p == null) return;
    try {
      await _publish(
        lat: p.lat,
        lng: p.lng,
        heading: 0,
        speedKmph: 0,
        source: 'manual',
      );
      if (!mounted) return;
      setState(() => _status = 'Manual location sent: ${p.label}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manual location sent: ${p.label}')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Manual location failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);
    final gpsState = _requesting
        ? 'Requesting GPS…'
        : _broadcasting
            ? 'GPS live'
            : (_lastPosition == null ? 'GPS idle' : 'GPS paused');

    return Scaffold(
      backgroundColor: AppColors.graphite,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        title: Text(
          s.driverTitle,
          style: GoogleFonts.syne(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF262F3A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _busCode(),
                  style: GoogleFonts.syne(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Campus shuttle · $gpsState',
                  style: GoogleFonts.ibmPlexSans(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusBtn(
                      label: s.isBangla ? 'অন টাইম' : 'On time',
                      selected: _tripStatus == 'on_time',
                      color: AppColors.brandLight,
                      onTap: () => _setTripStatus('on_time'),
                    ),
                    _StatusBtn(
                      label: s.isBangla ? 'ডিলে' : 'Report delay',
                      selected: _tripStatus == 'delayed',
                      color: AppColors.accent,
                      onTap: () => _setTripStatus('delayed'),
                    ),
                    _StatusBtn(
                      label: s.isBangla ? 'স্টপড' : 'Bus stopped',
                      selected: _tripStatus == 'stopped',
                      color: AppColors.danger,
                      onTap: () => _setTripStatus('stopped'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (_status != null)
                  Text(
                    _status!,
                    style: GoogleFonts.ibmPlexSans(
                      color: AppColors.accentHot,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (_lastPosition != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Lat ${_lastPosition!.latitude.toStringAsFixed(5)}  ·  '
                    'Lng ${_lastPosition!.longitude.toStringAsFixed(5)}\n'
                    'Accuracy ±${_lastPosition!.accuracy.toStringAsFixed(0)} m  ·  '
                    '${(_lastPosition!.speed * 3.6).clamp(0, 180).toStringAsFixed(0)} km/h',
                    style: GoogleFonts.ibmPlexSans(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
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
            label: Text(
              _requesting
                  ? 'Starting…'
                  : (_broadcasting
                      ? (s.isBangla ? 'শিফট শেষ' : 'End shift')
                      : (s.isBangla ? 'শিফট শুরু' : 'Start shift')),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor:
                  _broadcasting ? AppColors.danger : AppColors.accent,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            s.isBangla ? 'ম্যানুয়াল / ডেমো GPS' : 'Manual / demo GPS',
            style: GoogleFonts.ibmPlexSans(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _manualPointKey,
            dropdownColor: const Color(0xFF262F3A),
            style: GoogleFonts.ibmPlexSans(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF262F3A),
              labelText: s.isBangla ? 'লোকেশন পয়েন্ট' : 'Location point',
              labelStyle: const TextStyle(color: Colors.white70),
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
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white24),
            ),
            icon: const Icon(Icons.place_rounded),
            label: Text(
              s.isBangla ? 'ম্যানুয়াল লোকেশন পাঠান' : 'Send manual location',
            ),
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

class _StatusBtn extends StatelessWidget {
  const _StatusBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: GoogleFonts.ibmPlexSans(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
