import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_motion.dart';
import '../../widgets/motion_specs.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  String _source = 'Current Location';
  String _selectedDestination = 'DIU';
  _RouteSuggestion? _recommendedRoute;
  bool _loadingLocation = false;
  String? _locationError;
  String _selectedVehicle = 'Bus';

  static const _campusLocations = <String, (double, double)>{
    'DIU': (23.7636, 90.4283),
    'DSC': (23.7636, 90.4283),
    'BUET': (23.7264, 90.3928),
  };

  static const _sourceOptions = <String>[
    'Current Location',
    'Uttara',
    'Farmgate',
    'Dhanmondi',
    'Mirpur',
  ];

  static const _routePool = <_RouteSuggestion>[
    _RouteSuggestion(
      routeName: 'Uttara -> DSC',
      from: (23.8746, 90.4005),
      to: (23.7636, 90.4283),
      averageSpeedKmph: 24,
    ),
    _RouteSuggestion(
      routeName: 'Farmgate -> DIU',
      from: (23.7588, 90.3894),
      to: (23.7636, 90.4283),
      averageSpeedKmph: 19,
    ),
    _RouteSuggestion(
      routeName: 'Dhanmondi -> BUET',
      from: (23.7461, 90.3742),
      to: (23.7264, 90.3928),
      averageSpeedKmph: 16,
    ),
    _RouteSuggestion(
      routeName: 'Mirpur -> DSC',
      from: (23.8223, 90.3654),
      to: (23.7636, 90.4283),
      averageSpeedKmph: 18,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final destinations = _campusLocations.keys.toList();
    final rec = _recommendedRoute;
    final busEta = rec?.etaMinutes ?? 15;
    final carEta = rec == null ? 8 : (rec.etaMinutes * 0.65).round().clamp(6, 60);
    final distanceText = '${(rec?.distanceKm ?? 0.95).toStringAsFixed(2)} km';
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = viewportWidth >= 1200
        ? 28.0
        : viewportWidth >= 900
            ? 22.0
            : AppLayout.pageHPad;
    final contentMaxWidth = viewportWidth >= 1200
        ? 980.0
        : viewportWidth >= 900
            ? 860.0
            : double.infinity;
    final topCardPadding = viewportWidth >= 1200
        ? 18.0
        : viewportWidth >= 900
            ? 17.0
            : 16.0;
    final panelTopPad = viewportWidth >= 900
        ? AppLayout.pageTopPad + 4
        : AppLayout.pageTopPad;
    final panelTitleSize = viewportWidth >= 1200
        ? 20.0
        : viewportWidth >= 900
            ? 19.0
            : 17.6;
    final ctaHeight = viewportWidth >= 1200
        ? 56.0
        : viewportWidth >= 900
            ? 55.0
            : 54.0;
    final backButtonSize = viewportWidth >= 1200 ? 46.0 : 44.0;
    final backIconSize = viewportWidth >= 1200 ? 19.0 : 18.0;
    final panelHandleWidth = viewportWidth >= 1200 ? 82.0 : 74.0;
    final panelHandleHeight = viewportWidth >= 1200 ? 5.0 : 4.0;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF4F6F8), Color(0xFFECEFF3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CustomPaint(
                painter: _GridMapPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                AnimatedSection(
                  order: 0,
                  child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppLayout.pageTopPad,
                    horizontalPadding,
                    0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(topCardPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () async {
                                final popped = await Navigator.maybePop(context);
                                if (!popped && mounted) {
                                  Navigator.of(context, rootNavigator: true)
                                      .pushNamedAndRemoveUntil('/home', (_) => false);
                                }
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: backButtonSize,
                                height: backButtonSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(Icons.arrow_back_ios_new_rounded, size: backIconSize),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                children: [
                                  _RoutePointRow(
                                    dotColor: const Color(0xFF9CA3AF),
                                    label: 'From',
                                    value: _source == 'Current Location' ? 'My Location' : _source,
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _source,
                                    decoration: InputDecoration(
                                      labelText: 'Source',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                    ),
                                    items: _sourceOptions
                                        .map(
                                          (v) => DropdownMenuItem<String>(
                                            value: v,
                                            child: Text(v),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null || v == _source) return;
                                      setState(() => _source = v);
                                      _refreshRecommendation();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  const Padding(
                                    padding: EdgeInsets.only(left: 7),
                                    child: SizedBox(
                                      height: 24,
                                      child: VerticalDivider(
                                        width: 2,
                                        thickness: 2,
                                        color: Color(0xFFD1D5DB),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final selected = await showModalBottomSheet<String>(
                                        context: context,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (sheetContext) {
                                          return ListView(
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.all(16),
                                            children: destinations
                                                .map(
                                                  (d) => ListTile(
                                                    title: Text(d),
                                                    trailing: d == _selectedDestination
                                                        ? const Icon(Icons.check_rounded)
                                                        : null,
                                                    onTap: () => Navigator.pop(sheetContext, d),
                                                  ),
                                                )
                                                .toList(),
                                          );
                                        },
                                      );
                                      if (selected == null) return;
                                      setState(() => _selectedDestination = selected);
                                      _refreshRecommendation();
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: _RoutePointRow(
                                      dotColor: const Color(0xFF3B82F6),
                                      label: 'To',
                                      value: _selectedDestination,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  fit: FlexFit.loose,
                  child: AnimatedSection(
                    order: 1,
                    child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentMaxWidth),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            panelTopPad,
                            horizontalPadding,
                            20,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x220F172A),
                                blurRadius: 18,
                                offset: Offset(0, -6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      Center(
                        child: Container(
                          width: panelHandleWidth,
                          height: panelHandleHeight,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Text(
                        'Choose Vehicle',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: panelTitleSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _VehicleTile(
                        icon: Icons.directions_car_filled_rounded,
                        label: 'Car',
                        details: '$carEta min · $distanceText',
                        selected: _selectedVehicle == 'Car',
                        onTap: () => setState(() => _selectedVehicle = 'Car'),
                      ),
                      const SizedBox(height: 12),
                      _VehicleTile(
                        icon: Icons.directions_bus_rounded,
                        label: 'Bus',
                        details: '$busEta min · $distanceText',
                        selected: _selectedVehicle == 'Bus',
                        onTap: () => setState(() => _selectedVehicle = 'Bus'),
                      ),
                      if (_loadingLocation)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                      if (_locationError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _locationError!,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: ctaHeight,
                        child: ElevatedButton(
                          onPressed: _recommendedRoute == null
                              ? null
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Route confirmed: $_selectedVehicle via ${_recommendedRoute!.routeName}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                  Navigator.pop(context);
                                },
                          child: const Text('Confirm Route'),
                        ),
                      ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshRecommendation();
  }

  Future<void> _refreshRecommendation() async {
    setState(() {
      _loadingLocation = _source == 'Current Location';
      _locationError = null;
    });

    final destination = _campusLocations[_selectedDestination]!;
    final sourcePoint = await _resolveSourcePoint();
    if (!mounted || sourcePoint == null) return;

    _RouteSuggestion? best;
    for (final route in _routePool.where(
      (r) => _distanceKm(r.to, destination) < 3.5,
    )) {
      final firstLeg = _distanceKm(sourcePoint, route.from);
      final routeLeg = _distanceKm(route.from, route.to);
      final eta = ((firstLeg / 22) * 60 + (routeLeg / route.averageSpeedKmph) * 60).round();
      final candidate = route.copyWith(
        etaMinutes: eta.clamp(8, 160),
        distanceKm: firstLeg + routeLeg,
      );
      if (best == null || candidate.etaMinutes < best.etaMinutes) {
        best = candidate;
      }
    }

    setState(() {
      _recommendedRoute = best;
      _loadingLocation = false;
      _locationError ??=
          best == null ? 'No close route found for this destination right now.' : null;
    });
  }

  Future<(double, double)?> _resolveSourcePoint() async {
    if (_source != 'Current Location') {
      return switch (_source) {
        'Uttara' => (23.8746, 90.4005),
        'Farmgate' => (23.7588, 90.3894),
        'Dhanmondi' => (23.7461, 90.3742),
        'Mirpur' => (23.8223, 90.3654),
        _ => (23.8103, 90.4125),
      };
    }

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        setState(() {
          _locationError = 'Location is off. Turn it on or choose a manual source.';
        });
        return (23.8103, 90.4125);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied. Using default city center.';
        });
        return (23.8103, 90.4125);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      return (pos.latitude, pos.longitude);
    } catch (_) {
      setState(() {
        _locationError = 'Could not read current location. Using default source.';
      });
      return (23.8103, 90.4125);
    }
  }

  double _distanceKm((double, double) a, (double, double) b) {
    return Geolocator.distanceBetween(a.$1, a.$2, b.$1, b.$2) / 1000;
  }
}

class _RoutePointRow extends StatelessWidget {
  const _RoutePointRow({
    required this.dotColor,
    required this.label,
    required this.value,
  });

  final Color dotColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 2),
            color: dotColor.withValues(alpha: 0.12),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 30 * 0.55,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.icon,
    required this.label,
    required this.details,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String details;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverPressCard(
      onTap: onTap,
      borderRadius: 14,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
          width: selected ? 1.6 : 1.2,
        ),
      ),
      splashColor: const Color(0x143B82F6),
      highlightColor: const Color(0x0F3B82F6),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? const Color(0xFF2563EB) : const Color(0xFFFB923C)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16 * 0.95,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? const Color(0xFF3B82F6) : const Color(0xFF9CA3AF),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _GridMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFD8DEE6)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final parkPaint = Paint()..color = const Color(0xFFC7EBCF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.42, 46, 60),
        const Radius.circular(8),
      ),
      parkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteSuggestion {
  const _RouteSuggestion({
    required this.routeName,
    required this.from,
    required this.to,
    required this.averageSpeedKmph,
    this.etaMinutes = 0,
    this.distanceKm = 0,
  });

  final String routeName;
  final (double, double) from;
  final (double, double) to;
  final double averageSpeedKmph;
  final int etaMinutes;
  final double distanceKm;

  _RouteSuggestion copyWith({int? etaMinutes, double? distanceKm}) {
    return _RouteSuggestion(
      routeName: routeName,
      from: from,
      to: to,
      averageSpeedKmph: averageSpeedKmph,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }
}
