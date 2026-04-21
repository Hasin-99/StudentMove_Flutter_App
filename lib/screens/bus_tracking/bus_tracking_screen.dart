import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/live_bus_data.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../services/live_bus_repository.dart';
import '../../theme/app_theme.dart';

/// Live map with route polyline, ETA chips, stops — build reference §4.2.
class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LiveBusRepository? _liveRepo;
  bool _repoBound = false;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(23.8103, 90.4125),
    zoom: 13.2,
  );

  static const _routePoints = [
    LatLng(23.875, 90.382),
    LatLng(23.850, 90.395),
    LatLng(23.820, 90.405),
    LatLng(23.8103, 90.4125),
  ];

  static final _stops = [
    _Stop('Uttara', const LatLng(23.875, 90.382), '≈ 8 min'),
    _Stop('Airport Rd', const LatLng(23.850, 90.395), '≈ 15 min'),
    _Stop('DSC', const LatLng(23.8103, 90.4125), '≈ 28 min'),
  ];

  Future<void> _openLatestInGoogleMaps() async {
    final buses = _liveRepo?.buses ?? const <LiveBus>[];
    final lat = buses.isNotEmpty ? buses.first.lat : _initialPosition.target.latitude;
    final lng = buses.isNotEmpty ? buses.first.lng : _initialPosition.target.longitude;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();
    _buildMapData(const []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repoBound) return;
    _liveRepo = context.read<LiveBusRepository>();
    _liveRepo!.addListener(_handleLiveUpdate);
    _liveRepo!.startPolling();
    _repoBound = true;
  }

  void _handleLiveUpdate() {
    if (!mounted) return;
    _buildMapData(_liveRepo?.buses ?? const []);
  }

  void _buildMapData(List<LiveBus> buses) {
    final busIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final stopIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

    setState(() {
      _markers..clear();
      if (buses.isEmpty) {
        _markers.add(
          Marker(
            markerId: const MarkerId('bus_sample'),
            position: const LatLng(23.835, 90.398),
            infoWindow: const InfoWindow(title: 'Shuttle (sample)'),
            icon: busIcon,
          ),
        );
      } else {
        for (final b in buses) {
          _markers.add(
            Marker(
              markerId: MarkerId('bus_${b.id}'),
              position: LatLng(b.lat, b.lng),
              infoWindow: InfoWindow(
                title: b.busCode,
                snippet: '${b.speedKmph.toStringAsFixed(0)} km/h',
              ),
              icon: busIcon,
              rotation: b.heading,
            ),
          );
        }
      }
      for (var i = 0; i < _stops.length; i++) {
        final st = _stops[i];
        _markers.add(
          Marker(
            markerId: MarkerId('stop_$i'),
            position: st.position,
            infoWindow: InfoWindow(title: st.name),
            icon: stopIcon,
          ),
        );
      }
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: AppColors.brand,
            width: 5,
            points: _routePoints,
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final liveRepo = context.watch<LiveBusRepository>();
    final s = AppStrings(loc.locale);

    final map = Stack(
      fit: StackFit.expand,
      children: [
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS)
          Container(
            color: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Map preview is not supported on macOS yet.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Live location is still tracked from driver updates. Open in Google Maps for full map view.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _openLatestInGoogleMaps,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open in Google Maps'),
                ),
              ],
            ),
          )
        else
          GoogleMap(
            initialCameraPosition: _initialPosition,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (c) => _mapController = c,
          ),
        Positioned(
          top: 86,
          right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x2206B6D4), blurRadius: 12, offset: Offset(0, 6)),
              ],
            ),
            child: Text(
              s.isBangla ? 'রিয়েল-টাইম বাস ট্র্যাকিং' : 'Real-time bus Tracking',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        Positioned(
          top: 88,
          left: 0,
          right: 0,
          height: 44,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: _stops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final st = _stops[i];
              return Chip(
                avatar: const Icon(Icons.schedule_rounded, size: 18),
                label: Text(
                  '${st.name} · ${st.eta}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.border),
              );
            },
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.22,
          minChildSize: 0.14,
          maxChildSize: 0.55,
          builder: (_, scroll) {
            return Material(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              color: AppColors.card,
              elevation: 12,
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    s.isBangla ? 'বাস ট্র্যাকিং' : 'Bus Tracking',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 36 * 0.62),
                  ),
                  const SizedBox(height: 10),
                  Divider(color: AppColors.border),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFE2E8F0),
                      child: Icon(Icons.person_rounded, color: AppColors.ink),
                    ),
                    title: Text(
                      'Cameron Williamson',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 18 * 0.9),
                    ),
                    subtitle: Text(
                      s.isBangla ? 'বাস ড্রাইভার' : 'Bus Driver',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                    ),
                    trailing: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFF3B82F6),
                      child: Icon(Icons.call_rounded, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  ..._stops.map(
                    (st) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.brandLight.withValues(alpha: 0.13),
                        child: Icon(
                          st.name == 'DSC' ? Icons.access_time_rounded : Icons.place_rounded,
                          color: AppColors.brand,
                        ),
                      ),
                      title: Text(
                        st.name == 'DSC'
                            ? (s.isBangla ? 'আনুমানিক পৌঁছানোর সময়' : 'Estimated Arrival')
                            : (s.isBangla ? 'ঠিকানা' : 'Address'),
                        style: GoogleFonts.plusJakartaSans(color: AppColors.muted, fontSize: 13),
                      ),
                      trailing: Text(
                        st.name == 'DSC'
                            ? (s.isBangla ? '03:00 PM (সর্বোচ্চ ২০ মিনিট)' : '03:00 PM (Max 20 min)')
                            : (s.isBangla ? 'DIU, স্মার্ট সিটি, আশুলিয়া' : 'DIU, Smart City, Ashulia'),
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (liveRepo.lastError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Live status: ${liveRepo.lastError}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.red.shade400,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );

    if (!widget.showAppBar) {
      return map;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.trackTitle),
      ),
      body: map,
    );
  }

  @override
  void dispose() {
    _liveRepo?.removeListener(_handleLiveUpdate);
    _liveRepo?.stopPolling();
    _mapController?.dispose();
    super.dispose();
  }
}

class _Stop {
  const _Stop(this.name, this.position, this.eta);
  final String name;
  final LatLng position;
  final String eta;
}
