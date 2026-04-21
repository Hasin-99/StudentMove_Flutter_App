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
import '../../providers/auth_provider.dart';
import '../../services/schedule_repository.dart';
import '../../theme/app_theme.dart';

/// Day tabs, route, university search, per-slot bus/time/origin + mini route + PDF.
class NextBusArrivalScreen extends StatefulWidget {
  const NextBusArrivalScreen({super.key});

  @override
  State<NextBusArrivalScreen> createState() => _NextBusArrivalScreenState();
}

class _NextBusArrivalScreenState extends State<NextBusArrivalScreen> {
  static const _accentBlue = Color(0xFF1A23D1);
  static const _pageBg = Color(0xFFF2F3F8);

  final _searchController = TextEditingController();

  String _route = ScheduleSlot.routes.first;
  int _dayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<ScheduleRepository>().refresh();
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
    final routes = repo.routeNames;
    final activeRoute = routes.contains(_route) ? _route : routes.first;
    final slots = _visible(repo);
    final name = auth.userName ?? 'U';

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
                  style: GoogleFonts.plusJakartaSans(
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
                        hintStyle: GoogleFonts.plusJakartaSans(
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
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'U',
                      style: GoogleFonts.plusJakartaSans(
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
                          style: GoogleFonts.plusJakartaSans(
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
                initialValue: activeRoute,
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
                              style: GoogleFonts.plusJakartaSans(
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
                                  style: GoogleFonts.plusJakartaSans(
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
                    style: GoogleFonts.plusJakartaSans(
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
  const _ScheduleCard({required this.slot, required this.accent});

  final ScheduleSlot slot;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${slot.timeLabel}, ${slot.dateLabel}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bus: ${slot.busCode}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'from: ${slot.origin}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            if (slot.whiteboardNote.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                slot.whiteboardNote,
                style: GoogleFonts.plusJakartaSans(
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
    final bg = Paint()..color = const Color(0xFFE8EAF6);
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(4),
    );
    canvas.drawRRect(r, bg);

    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 0.15,
        size.width * 0.88,
        size.height * 0.48,
      );

    final line = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, line);

    final dot = Paint()..color = accent;
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.55), 5, dot);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.48), 5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
