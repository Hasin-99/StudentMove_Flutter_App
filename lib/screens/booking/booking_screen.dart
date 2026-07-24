import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/saved_routes_provider.dart';
import '../../l10n/app_strings.dart';
import '../../services/booking_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/motion_specs.dart';

/// Routes tab: suggest & save routes + book seats (StudentMove parity).
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().userId;
      context.read<BookingRepository>().bindUser(uid);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);
    final maxWidth = AppLayout.contentMaxWidthFor(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.isBangla ? 'রুট ও বুকিং' : 'Routes & Booking',
                              style: GoogleFonts.syne(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            Text(
                              s.isBangla
                                  ? 'পরিকল্পনা করুন, সেভ করুন, সিট বুক করুন'
                                  : 'Plan, save favorites, and book seats',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabs,
                  labelColor: AppColors.brand,
                  unselectedLabelColor: AppColors.muted,
                  indicatorColor: AppColors.accent,
                  labelStyle: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                  tabs: [
                    Tab(text: s.isBangla ? 'প্ল্যান' : 'Plan'),
                    Tab(text: s.isBangla ? 'বুক' : 'Book'),
                    Tab(text: s.isBangla ? 'আমার' : 'My rides'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _PlanTab(strings: s),
                      _BookTab(strings: s),
                      _MyBookingsTab(strings: s),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlanTab extends StatefulWidget {
  const _PlanTab({required this.strings});
  final AppStrings strings;

  @override
  State<_PlanTab> createState() => _PlanTabState();
}

class _PlanTabState extends State<_PlanTab> {
  String _from = 'Uttara';
  String _to = 'DSC';
  String _pref = 'fastest';

  static const _places = [
    'Uttara',
    'Mirpur',
    'Farmgate',
    'Dhanmondi',
    'DSC',
    'DIU',
    'BUET',
    'NSU',
  ];

  List<_Suggestion> get _suggestions {
    final base = <_Suggestion>[
      _Suggestion(
        title: 'Fastest · $_from → $_to',
        duration: '28 min',
        cost: '৳30',
        transfers: 0,
        comfort: 'Good',
        rating: 4.6,
        buses: const ['SM-101'],
        description: 'Direct campus shuttle with live GPS.',
        preference: 'fastest',
      ),
      _Suggestion(
        title: 'Cheapest · $_from → $_to',
        duration: '42 min',
        cost: '৳25',
        transfers: 1,
        comfort: 'Fair',
        rating: 4.1,
        buses: const ['SM-204', 'Local'],
        description: 'Lower fare with one transfer at Farmgate.',
        preference: 'cheapest',
      ),
      _Suggestion(
        title: 'Direct · $_from → $_to',
        duration: '35 min',
        cost: '৳35',
        transfers: 0,
        comfort: 'High',
        rating: 4.8,
        buses: const ['SM-118'],
        description: 'AC coach, fewer stops, reserved seats.',
        preference: 'direct',
      ),
    ];
    base.sort((a, b) {
      if (_pref == 'cheapest') return a.cost.compareTo(b.cost);
      if (_pref == 'direct') return a.transfers.compareTo(b.transfers);
      return a.duration.compareTo(b.duration);
    });
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final saved = context.watch<SavedRoutesProvider>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        AnimatedSection(
          order: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppTheme.pageAtmosphere,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _from,
                  decoration: InputDecoration(
                    labelText: s.isBangla ? 'বর্তমান অবস্থান' : 'From',
                  ),
                  items: _places
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _from = v ?? _from),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _to,
                  decoration: InputDecoration(
                    labelText: s.isBangla ? 'গন্তব্য' : 'Destination',
                  ),
                  items: _places
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _to = v ?? _to),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in const ['fastest', 'cheapest', 'direct', 'comfortable'])
                      ChoiceChip(
                        label: Text(p),
                        selected: _pref == p,
                        onSelected: (_) => setState(() => _pref = p),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          s.isBangla ? 'সাজেশন' : 'Ranked suggestions',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ..._suggestions.map((sug) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppTheme.elev1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sug.title,
                        style: GoogleFonts.ibmPlexSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        sug.description,
                        style: GoogleFonts.ibmPlexSans(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _MetaChip(icon: Icons.schedule, label: sug.duration),
                          _MetaChip(icon: Icons.payments_outlined, label: sug.cost),
                          _MetaChip(
                            icon: Icons.swap_horiz,
                            label: '${sug.transfers} transfers',
                          ),
                          _MetaChip(
                            icon: Icons.star_rounded,
                            label: sug.rating.toStringAsFixed(1),
                          ),
                          ...sug.buses.map(
                            (b) => Chip(
                              label: Text(b),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await saved.add('$_from → $_to · ${sug.duration}');
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      s.isBangla
                                          ? 'রুট সেভ হয়েছে'
                                          : 'Route saved to favorites',
                                    ),
                                  ),
                                );
                              },
                              child: Text(s.isBangla ? 'সেভ' : 'Save route'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final state =
                                    context.findAncestorStateOfType<_BookingScreenState>();
                                state?._tabs.animateTo(1);
                              },
                              child: Text(s.isBangla ? 'বুক করুন' : 'Book this'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (saved.items.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            s.isBangla ? 'সেভ করা রুট' : 'Saved favorites',
            style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...saved.items.map(
            (r) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bookmark_rounded, color: AppColors.brand),
              title: Text(r),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => saved.remove(r),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BookTab extends StatefulWidget {
  const _BookTab({required this.strings});
  final AppStrings strings;

  @override
  State<_BookTab> createState() => _BookTabState();
}

class _BookTabState extends State<_BookTab> {
  AvailableTrip? _selected;
  DateTime _date = DateTime.now().add(const Duration(days: 0));
  int _seats = 1;
  String _pref = 'any';
  final _notes = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final trip = _selected;
    if (trip == null) return;
    setState(() => _submitting = true);
    final repo = context.read<BookingRepository>();
    final booking = await repo.createBooking(
      trip: trip,
      travelDate: _date,
      seats: _seats,
      seatPreference: _pref,
      notes: _notes.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(repo.lastError ?? 'Booking failed')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.strings.isBangla ? 'বুকিং নিশ্চিত' : 'Booking confirmed'),
        content: Text(
          widget.strings.isBangla
              ? 'কোড: ${booking.code}\n${booking.route}\nসিট: ${booking.seats} · ৳${booking.fare.toStringAsFixed(0)}'
              : 'Code: ${booking.code}\n${booking.route}\nSeats: ${booking.seats} · ৳${booking.fare.toStringAsFixed(0)}',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    final state = context.findAncestorStateOfType<_BookingScreenState>();
    state?._tabs.animateTo(2);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final trips = BookingRepository.demoTrips;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          s.isBangla ? 'উপলব্ধ ট্রিপ' : 'Available trips',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        ...trips.map((t) {
          final selected = _selected?.id == t.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: selected
                  ? AppColors.brandLight.withValues(alpha: 0.12)
                  : AppColors.card,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: t.isFull ? null : () => setState(() => _selected = t),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? AppColors.brand : AppColors.border,
                      width: selected ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.directions_bus_filled_rounded,
                        color: t.isFull ? AppColors.muted : AppColors.brand,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.route,
                              style: GoogleFonts.ibmPlexSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${t.busNumber} · ${t.departureTime} · ৳${t.farePerSeat.toStringAsFixed(0)}/seat',
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 13,
                                color: AppColors.muted,
                              ),
                            ),
                            Text(
                              t.isFull
                                  ? (s.isBangla ? 'পূর্ণ' : 'Full')
                                  : (s.isBangla
                                      ? '${t.seatsLeft} সিট বাকি'
                                      : '${t.seatsLeft} seats left'),
                              style: GoogleFonts.ibmPlexSans(
                                fontSize: 12,
                                color: t.seatsLeft <= 5
                                    ? AppColors.danger
                                    : AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle, color: AppColors.brand),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_selected != null) ...[
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.isBangla ? 'ভ্রমণের তারিখ' : 'Travel date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                  initialDate: _date,
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ),
          Text(s.isBangla ? 'সিট সংখ্যা (সর্বোচ্চ ৪)' : 'Seats (max 4)'),
          Slider(
            value: _seats.toDouble(),
            min: 1,
            max: 4,
            divisions: 3,
            label: '$_seats',
            onChanged: (v) => setState(() => _seats = v.round()),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final p in const ['any', 'window', 'aisle'])
                ChoiceChip(
                  label: Text(p),
                  selected: _pref == p,
                  onSelected: (_) => setState(() => _pref = p),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.isBangla ? 'নোট (ঐচ্ছিক)' : 'Notes (optional)',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.isBangla
                ? 'আনুমানিক ভাড়া: ৳${(_selected!.farePerSeat * _seats).toStringAsFixed(0)}'
                : 'Estimated fare: ৳${(_selected!.farePerSeat * _seats).toStringAsFixed(0)}',
            style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _confirm,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(s.isBangla ? 'বুকিং নিশ্চিত করুন' : 'Confirm booking'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MyBookingsTab extends StatelessWidget {
  const _MyBookingsTab({required this.strings});
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final s = strings;
    final repo = context.watch<BookingRepository>();

    if (repo.loading && repo.bookings.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (repo.bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_seat_outlined,
        title: s.isBangla ? 'কোনো বুকিং নেই' : 'No bookings yet',
        subtitle: s.isBangla
            ? 'বুক ট্যাব থেকে সিট সংরক্ষণ করুন'
            : 'Reserve seats from the Book tab',
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<BookingRepository>().refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: repo.bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final b = repo.bookings[i];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.code,
                        style: GoogleFonts.syne(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: AppColors.brand,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(b.status),
                      backgroundColor: b.status == 'cancelled'
                          ? AppColors.danger.withValues(alpha: 0.12)
                          : AppColors.brandLight.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                Text(b.route, style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700)),
                Text(
                  '${DateFormat.yMMMd().format(b.travelDate)} · ${b.departureTime}',
                  style: GoogleFonts.ibmPlexSans(color: AppColors.muted, fontSize: 13),
                ),
                Text(
                  '${b.seats} seats · ${b.seatPreference} · ৳${b.fare.toStringAsFixed(0)}',
                  style: GoogleFonts.ibmPlexSans(fontSize: 13),
                ),
                if (b.isCancellable)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text(s.isBangla ? 'বাতিল?' : 'Cancel booking?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(s.isBangla ? 'না' : 'No'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(s.isBangla ? 'হ্যাঁ' : 'Yes'),
                              ),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await context.read<BookingRepository>().cancelBooking(b.id);
                        }
                      },
                      child: Text(s.isBangla ? 'বাতিল' : 'Cancel'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.ibmPlexSans(fontSize: 12)),
        ],
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.title,
    required this.duration,
    required this.cost,
    required this.transfers,
    required this.comfort,
    required this.rating,
    required this.buses,
    required this.description,
    required this.preference,
  });

  final String title;
  final String duration;
  final String cost;
  final int transfers;
  final String comfort;
  final double rating;
  final List<String> buses;
  final String description;
  final String preference;
}
