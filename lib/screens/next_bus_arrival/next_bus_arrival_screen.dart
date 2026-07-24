import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../data/schedule_data.dart';
import '../../data/live_bus_data.dart';
import '../../providers/auth_provider.dart';
import '../../services/schedule_repository.dart';
import '../../services/live_bus_repository.dart';
import '../../theme/app_theme.dart';

/// Day tabs, route, university search, per-slot bus/time/origin + mini route + PDF.
class NextBusArrivalScreen extends StatefulWidget {
  const NextBusArrivalScreen({super.key});

  @override
  State<NextBusArrivalScreen> createState() => _NextBusArrivalScreenState();
}

class _NextBusArrivalScreenState extends State<NextBusArrivalScreen> {
  static const _accentBlue = AppColors.brand;
  static const _pageBg = Color(0xFFEDF2F1);

  final _searchController = TextEditingController();

  String _route = ScheduleSlot.routes.first;
  int _dayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ScheduleRepository>().refresh();
      context.read<LiveBusRepository>().startPolling();
      if (!mounted) return;
      final routes = context.read<ScheduleRepository>().routeNames;
      if (routes.isNotEmpty && !routes.contains(_route)) {
        setState(() => _route = routes.first);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Keep live polling for other screens; do not stop globally.
    super.dispose();
  }

  List<ScheduleSlot> _visible(ScheduleRepository repo) {
    final routes = repo.routeNames;
    final active = routes.contains(_route) ? _route : routes.first;
    return ScheduleSlot.filtered(
      source: repo.slots,
      routeName: active,
      dayIndex: _dayIndex,
      universityQuery: _searchController.text,
    );
  }

  String _pdfSafe(String value) {
    return value
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('•', '-')
        .replaceAll('·', '-');
  }

  Future<Directory?> _preferredDownloadsDirectory() async {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) return downloadsDir;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    return Directory('$home/Downloads');
  }

  Future<void> _downloadPdf(ScheduleRepository repo) async {
    final slots = _visible(repo);
    final routes = repo.routeNames;
    final activeRoute = routes.contains(_route) ? _route : routes.first;
    final day = ScheduleSlot.dayShortLabels[_dayIndex];
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => [
          pw.Text(
            _pdfSafe('StudentMove - Bus schedule'),
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(_pdfSafe('Route: $activeRoute')),
          pw.Text('Day: $day'),
          if (_searchController.text.trim().isNotEmpty)
            pw.Text(_pdfSafe('University filter: ${_searchController.text.trim()}')),
          pw.SizedBox(height: 16),
          if (slots.isEmpty)
            pw.Text('No trips match.')
          else
            ...slots.map(
              (s) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  _pdfSafe(
                    '${s.busCode} - ${s.timeLabel}, ${s.dateLabel} - from ${s.origin}'
                    '${s.whiteboardNote.trim().isEmpty ? '' : ' - ${s.whiteboardNote}'}',
                  ),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
    final bytes = await doc.save();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final fileName = 'studentmove_schedule_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final downloadsDir = await _preferredDownloadsDirectory();
      final docsDir = await getApplicationDocumentsDirectory();
      File file = File('${(downloadsDir ?? docsDir).path}/$fileName');
      try {
        await file.writeAsBytes(bytes, flush: true);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Schedule PDF save to Downloads failed: $e');
        }
        file = File('${docsDir.path}/$fileName');
        try {
          await file.writeAsBytes(bytes, flush: true);
        } catch (fallbackError) {
          if (kDebugMode) {
            debugPrint('Schedule PDF fallback save failed: $fallbackError');
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save PDF locally: $fallbackError')),
          );
          return;
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloads blocked ($e). Saved to app Documents instead.')),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved: ${file.path}')),
      );
      return;
    }
    await Printing.sharePdf(bytes: bytes, filename: 'studentmove_schedule.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final repo = context.watch<ScheduleRepository>();
    final liveBuses = context.watch<LiveBusRepository>().buses;
    final routes = repo.routeNames;
    final activeRoute = routes.contains(_route) ? _route : routes.first;
    final slots = _visible(repo);
    final name = auth.userName ?? 'U';
    final hasProfilePhoto = !kIsWeb &&
        (auth.profileImagePath?.isNotEmpty ?? false) &&
        File(auth.profileImagePath!).existsSync();

    LiveBus? matchLive(ScheduleSlot slot) {
      final code = slot.busCode.trim().toLowerCase();
      for (final b in liveBuses) {
        if (b.busCode.trim().toLowerCase() == code) return b;
      }
      return null;
    }
    return Scaffold(
      backgroundColor: _pageBg,
      floatingActionButton: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: AppColors.brand,
        child: InkWell(
          onTap: slots.isEmpty
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No schedule rows to export.')),
                  );
                }
              : () => _downloadPdf(repo),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Download PDF',
                  style: GoogleFonts.ibmPlexSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.ink,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter your University name',
                        hintStyle: GoogleFonts.ibmPlexSans(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.brand,
                    backgroundImage: hasProfilePhoto
                        ? FileImage(File(auth.profileImagePath!))
                        : null,
                    child: hasProfilePhoto
                        ? null
                        : Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: GoogleFonts.ibmPlexSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (repo.loading)
                    const LinearProgressIndicator(minHeight: 2),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        repo.fromApi ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        size: 18,
                        color: repo.fromApi ? AppColors.success : AppColors.muted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repo.fromApi
                              ? 'Schedules from server'
                              : 'Sample schedules (publish schedules collection in Firestore)',
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>('${activeRoute}_${routes.join('|')}'),
                value: activeRoute,
                decoration: InputDecoration(
                  labelText: 'Route',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: routes
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _route = v);
                },
              ),
            ),
            _DayTabBar(
              selectedIndex: _dayIndex,
              accent: _accentBlue,
              onSelect: (i) => setState(() => _dayIndex = i),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<ScheduleRepository>().refresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 520;
                    return CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              slots.length == 1
                                  ? 'One schedule available'
                                  : '${slots.length} schedules available',
                              style: GoogleFonts.ibmPlexSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        if (slots.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No buses for ${ScheduleSlot.dayShortLabels[_dayIndex]} on this route.\nTry another day or clear the university search.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.ibmPlexSans(
                                    color: AppColors.muted,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: twoCol ? 2 : 1,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: twoCol ? 0.72 : 1.15,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => _ScheduleCard(
                                  slot: slots[i],
                                  accent: _accentBlue,
                                  liveBus: matchLive(slots[i]),
                                ),
                                childCount: slots.length,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTabBar extends StatelessWidget {
  const _DayTabBar({
    required this.selectedIndex,
    required this.accent,
    required this.onSelect,
  });

  final int selectedIndex;
  final Color accent;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ScheduleSlot.dayShortLabels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (context, i) {
          final sel = i == selectedIndex;
          return InkWell(
            onTap: () => onSelect(i),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ScheduleSlot.dayShortLabels[i],
                    style: GoogleFonts.ibmPlexSans(
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                      color: sel ? accent : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    width: sel ? 28 : 0,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.slot,
    required this.accent,
    this.liveBus,
  });

  final ScheduleSlot slot;
  final Color accent;
  final LiveBus? liveBus;

  @override
  Widget build(BuildContext context) {
    final gps = liveBus?.gpsFreshness;
    final gpsColor = switch (gps) {
      GpsFreshness.live => AppColors.brand,
      GpsFreshness.stale => AppColors.accent,
      GpsFreshness.waiting => AppColors.muted,
      GpsFreshness.offline => AppColors.danger,
      null => AppColors.muted,
    };
    final gpsText = liveBus?.gpsLabel ?? 'Waiting for GPS';
    final eta = liveBus?.etaText;
    final delayed = (liveBus?.delayMinutes ?? 0) >= 3;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        boxShadow: AppTheme.elev1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${slot.timeLabel}, ${slot.dateLabel}',
                    style: GoogleFonts.syne(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: gpsColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: gpsColor),
                      const SizedBox(width: 4),
                      Text(
                        gpsText,
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: gpsColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Bus: ${slot.busCode}',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            if (liveBus != null && liveBus!.speedKmph > 0) ...[
              const SizedBox(height: 4),
              Text(
                '${liveBus!.heading.toStringAsFixed(0)}° · ${liveBus!.speedKmph.toStringAsFixed(0)} km/h'
                '${eta != null ? ' · $eta' : ''}',
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: delayed ? AppColors.danger : AppColors.muted,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'from: ${slot.origin}',
              style: GoogleFonts.ibmPlexSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            if (slot.whiteboardNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                slot.whiteboardNote,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ],
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 96,
                width: double.infinity,
                child: CustomPaint(
                  painter: _MiniRoutePainter(accent: accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  _MiniRoutePainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.paper,
          AppColors.brandLight.withValues(alpha: 0.18),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(r, bg);

    // Soft 3D road shadow.
    final shadow = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.58)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.18,
        size.width * 0.88,
        size.height * 0.50,
      );
    canvas.drawPath(path, shadow);

    final line = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, line);

    final bus = Paint()..color = accent;
    final busRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.52, size.height * 0.34),
        width: 22,
        height: 12,
      ),
      const Radius.circular(3),
    );
    canvas.drawRRect(busRect, bus);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.58), 5, bus);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.50), 5, bus);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
