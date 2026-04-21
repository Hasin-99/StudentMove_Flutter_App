import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_motion.dart';
import '../../widgets/motion_specs.dart';

/// Plans, payment launchers, invoice area — build reference §4.3.
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  String _vehicle = 'bus';

  Future<Directory?> _preferredDownloadsDirectory() async {
    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir != null) return downloadsDir;
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    return Directory('$home/Downloads');
  }

  static const _plans = [
    _PlanDef('Basic', 1200, '/month', Duration(days: 30), rides: '20 rides per month'),
    _PlanDef('Standard', 1800, '/month', Duration(days: 30), rides: '40 rides per month'),
    _PlanDef('Yearly', 12000, '/year', Duration(days: 365), rides: 'Unlimited bus rides'),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);
    final sub = context.watch<SubscriptionProvider>();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = viewportWidth >= 1200
        ? 1180.0
        : viewportWidth >= 900
            ? 980.0
            : AppLayout.contentMaxWidthFor(context);
    final hPad = viewportWidth >= 1200
        ? 26.0
        : viewportWidth >= 900
            ? 22.0
            : AppLayout.pageHPad;
    final topPad = viewportWidth >= 1200
        ? AppLayout.pageTopPad + 6
        : AppLayout.pageTopPad;
    final titleSize = viewportWidth >= 1200
        ? 26.0
        : viewportWidth >= 900
            ? 24.0
            : 22.0;
    final subtitleSize = viewportWidth >= 1200 ? 15.0 : 14.0;
    final sectionGap = viewportWidth >= 900 ? 24.0 : 20.0;
    final ctaHeight = viewportWidth >= 1200
        ? 52.0
        : viewportWidth >= 900
            ? 50.0
            : 48.0;
    final listIconSize = viewportWidth >= 1200 ? 24.0 : 22.0;
    final listTrailingIconSize = viewportWidth >= 1200 ? 22.0 : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isBangla ? 'সাবস্ক্রিপশন প্ল্যান' : 'Subscription Plans'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              hPad,
              topPad,
              hPad,
              32,
            ),
            children: [
          AnimatedSection(
            order: 0,
            child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _VehicleTab(
                    label: s.isBangla ? 'বাস' : 'Bus',
                    selected: _vehicle == 'bus',
                    icon: Icons.directions_bus_rounded,
                    onTap: () => setState(() => _vehicle = 'bus'),
                  ),
                ),
                Expanded(
                  child: _VehicleTab(
                    label: s.isBangla ? 'কার' : 'Car',
                    selected: _vehicle == 'car',
                    icon: Icons.directions_car_filled_rounded,
                    onTap: () => setState(() => _vehicle = 'car'),
                  ),
                ),
              ],
            ),
            ),
          ),
          SizedBox(height: sectionGap - 4),
          if (sub.hasActiveSubscription)
            AnimatedSection(
              order: 1,
              child: Card(
              color: AppColors.brandLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_rounded, color: AppColors.success, size: listIconSize),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${sub.planName} · ${sub.daysRemaining} ${s.daysLeft}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                s.isBangla
                                    ? 'সাবস্ক্রিপশন সক্রিয়'
                                    : 'Subscription active',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final subProvider = context.read<SubscriptionProvider>();
                          final messenger = ScaffoldMessenger.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(
                                s.isBangla ? 'সাবস্ক্রিপশন বাতিল' : 'Cancel subscription',
                              ),
                              content: Text(
                                s.isBangla
                                    ? 'আপনি কি বর্তমান সাবস্ক্রিপশন বাতিল করতে চান?'
                                    : 'Do you want to cancel your active subscription?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(s.isBangla ? 'না' : 'No'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(s.isBangla ? 'হ্যাঁ, বাতিল' : 'Yes, cancel'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return;
                          try {
                            await subProvider.cancelActivePlan();
                          } catch (_) {
                            if (!mounted) return;
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Could not cancel subscription right now.'),
                              ),
                            );
                            return;
                          }
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                s.isBangla
                                    ? 'সাবস্ক্রিপশন বাতিল করা হয়েছে।'
                                    : 'Subscription cancelled.',
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.cancel_outlined, size: listTrailingIconSize),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, ctaHeight),
                        ),
                        label: Text(
                          s.isBangla ? 'সাবস্ক্রিপশন বাতিল করুন' : 'Cancel subscription',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
            ),
          if (sub.hasActiveSubscription) SizedBox(height: sectionGap - 4),
          AnimatedSection(
            order: 2,
            child: Text(
            s.isBangla ? 'সাবস্ক্রিপশন প্ল্যান' : 'Subscription Plans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            ),
          ),
          ),
          const SizedBox(height: 10),
          AnimatedSection(
            order: 3,
            child: Text(
            s.isBangla
                ? 'আপনার দৈনন্দিন যাত্রার জন্য সেরা প্ল্যান বেছে নিন'
                : 'Choose the best plan for your daily commute',
            style: GoogleFonts.plusJakartaSans(
              fontSize: subtitleSize,
              height: 1.45,
              color: AppColors.muted,
            ),
            ),
          ),
          SizedBox(height: sectionGap),
          AnimatedSection(
            order: 4,
            child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final columns = width >= 1200
                  ? 3
                  : width >= 768
                      ? 2
                      : 1;
              final spacing = 12.0;
              final cardWidth = (width - (spacing * (columns - 1))) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _plans
                    .map(
                      (p) => SizedBox(
                        width: cardWidth,
                        child: _PlanTile(
                          plan: p,
                          strings: s,
                          highlight: _vehicle == 'bus' && p.name == 'Basic',
                          onSelect: () async {
                            final subProvider = context.read<SubscriptionProvider>();
                            final details = await Navigator.push<_SubscriptionSelection>(
                              context,
                              MaterialPageRoute<_SubscriptionSelection>(
                                builder: (_) => _SubscriptionDetailsScreen(plan: p, strings: s),
                              ),
                            );
                            if (details == null) return;
                            try {
                              await subProvider.activatePlan(
                                p.name,
                                p.duration,
                                amount: p.price.toDouble(),
                                paymentMethod: details.paymentMethod,
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Could not save subscription. Please try again.'),
                                ),
                              );
                              return;
                            }
                            if (!context.mounted) return;
                            final invoices = subProvider.invoices;
                            final invoice = invoices.isEmpty ? null : invoices.first;
                            if (invoice != null) {
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(s.isBangla ? 'ইনভয়েস' : 'Invoice'),
                                  content: Text(
                                    '${invoice.planName}\n'
                                    '${s.isBangla ? 'পরিমাণ' : 'Amount'}: ৳${NumberFormat('#,##0').format(invoice.amount)}\n'
                                    '${s.isBangla ? 'পেমেন্ট' : 'Payment'}: ${invoice.paymentMethod}\n'
                                    '${s.isBangla ? 'পেমেন্ট তারিখ' : 'Paid'}: ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.paidAt)}\n'
                                    '${s.isBangla ? 'ভ্যালিড আনটিল' : 'Valid until'}: ${DateFormat('dd MMM yyyy').format(invoice.validUntil)}',
                                  ),
                                  actions: [
                                    FilledButton(
                                      onPressed: () => Navigator.pop(dialogContext),
                                      child: Text(s.isBangla ? 'ঠিক আছে' : 'Done'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            ),
          ),
          const SizedBox(height: 28),
          AnimatedSection(
            order: 5,
            child: Text(
            s.isBangla ? 'ইনভয়েস হিস্ট্রি' : 'Invoice history',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          ),
          const SizedBox(height: 12),
          if (sub.invoices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: AppColors.muted, size: viewportWidth >= 1200 ? 34 : 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        s.noInvoices,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...sub.invoices.map(
              (inv) => Card(
                child: ListTile(
                  leading: Icon(Icons.receipt_long_rounded, color: AppColors.brand, size: listIconSize),
                  title: Text(
                    inv.planName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Amount: ৳${NumberFormat('#,##0').format(inv.amount)} · ${inv.paymentMethod}\n'
                    'Paid: ${DateFormat('dd MMM yyyy, hh:mm a').format(inv.paidAt)}\n'
                    'Valid until: ${DateFormat('dd MMM yyyy').format(inv.validUntil)}',
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: listTrailingIconSize,
                  ),
                  onTap: () => _showInvoiceActions(context, inv, s),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showInvoiceActions(
  BuildContext context,
  SubscriptionInvoice invoice,
  AppStrings strings,
) async {
  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text(
                strings.isBangla ? 'ইনভয়েস ডিটেইলস' : 'Invoice Details',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text('Plan: ${invoice.planName}'),
              Text('Invoice ID: ${invoice.id}'),
              Text('Amount: ৳${NumberFormat('#,##0').format(invoice.amount)}'),
              Text('Payment Method: ${invoice.paymentMethod}'),
              Text('Paid: ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.paidAt)}'),
              Text('Valid until: ${DateFormat('dd MMM yyyy').format(invoice.validUntil)}'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.visibility_outlined),
                      label: Text(strings.isBangla ? 'বন্ধ করুন' : 'Close'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _printInvoice(invoice);
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: Text(strings.isBangla ? 'প্রিন্ট' : 'Print'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _printInvoice(SubscriptionInvoice invoice) async {
  final doc = pw.Document();
  final paidAt = DateFormat('dd MMM yyyy, hh:mm a').format(invoice.paidAt);
  final validUntil = DateFormat('dd MMM yyyy').format(invoice.validUntil);
  final subtotal = invoice.amount;
  const vat = 0.0;
  final total = subtotal + vat;

  doc.addPage(
    pw.Page(
      build: (context) {
        return pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'StudentMove Invoice',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Invoice ID: ${invoice.id}'),
              pw.Text('Plan: ${invoice.planName}'),
              pw.Text('Payment Method: ${invoice.paymentMethod}'),
              pw.Text('Paid: $paidAt'),
              pw.Text('Valid until: $validUntil'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('Subtotal'), pw.Text('৳${subtotal.toStringAsFixed(0)}')],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [pw.Text('VAT'), pw.Text('৳${vat.toStringAsFixed(0)}')],
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('৳${total.toStringAsFixed(0)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Thank you for choosing StudentMove.'),
            ],
          ),
        );
      },
    ),
  );

  final bytes = await doc.save();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    final fileName = 'studentmove_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final downloadsDir = await _preferredDownloadsDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    File file = File('${(downloadsDir ?? docsDir).path}/$fileName');
    try {
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('Invoice saved: ${file.path}');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Invoice save to Downloads failed: $e');
      }
      file = File('${docsDir.path}/$fileName');
      try {
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('Invoice saved (fallback): ${file.path}');
      } catch (fallbackError) {
        debugPrint('Invoice save failed: $fallbackError');
      }
    }
    return;
  }
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'studentmove_invoice_${invoice.id}.pdf',
  );
}

class _PlanDef {
  const _PlanDef(this.name, this.price, this.period, this.duration, {required this.rides});
  final String name;
  final int price;
  final String period;
  final Duration duration;
  final String rides;
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.strings,
    required this.highlight,
    required this.onSelect,
  });

  final _PlanDef plan;
  final AppStrings strings;
  final bool highlight;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return MotionScaleTap(
      pressedScale: MotionSpecs.pressScaleCard,
      child: Container(
        decoration: BoxDecoration(
          gradient: highlight
              ? const LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: highlight ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: highlight ? Colors.transparent : AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x140F172A), blurRadius: 14, offset: Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              plan.name,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: highlight ? Colors.white : AppColors.brand,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '৳${NumberFormat('#,##0').format(plan.price)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: highlight ? Colors.white : AppColors.ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  plan.period,
                  style: GoogleFonts.plusJakartaSans(
                    color: highlight ? Colors.white70 : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _feature(plan.rides, highlight),
            _feature(strings.isBangla ? 'স্ট্যান্ডার্ড বাস' : 'Standard buses', highlight),
            _feature(strings.isBangla ? 'অফ-পিক আওয়ার্স' : 'Off-peak hours', highlight),
            _feature(strings.isBangla ? 'বেসিক সাপোর্ট' : 'Basic support', highlight),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSelect,
                child: Text(strings.isBangla ? 'প্ল্যান সিলেক্ট করুন' : 'Select plan'),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(String text, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: highlight ? Colors.white : AppColors.brandLight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                color: highlight ? Colors.white : AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionDetailsScreen extends StatefulWidget {
  const _SubscriptionDetailsScreen({required this.plan, required this.strings});

  final _PlanDef plan;
  final AppStrings strings;

  @override
  State<_SubscriptionDetailsScreen> createState() => _SubscriptionDetailsScreenState();
}

class _SubscriptionDetailsScreenState extends State<_SubscriptionDetailsScreen> {
  String _payment = 'mobile';

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final s = widget.strings;
    final now = DateTime.now();
    final next = now.add(p.duration);

    return Scaffold(
      appBar: AppBar(title: Text(s.isBangla ? 'সাবস্ক্রিপশন ডিটেইলস' : 'Subscription Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppLayout.pageHPad, AppLayout.pageTopPad, AppLayout.pageHPad, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brand, AppColors.brandDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.name} Subscription',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 31 * 0.62,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '৳${NumberFormat('#,##0').format(p.price)} ${p.period}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                _detailTick('Save 33% with annual plan'),
                _detailTick('Unlimited bus rides'),
                _detailTick('Priority customer support'),
                _detailTick('Cancel anytime'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            s.isBangla ? 'Billing Period' : 'Billing Period',
            style: GoogleFonts.plusJakartaSans(fontSize: 29 * 0.62, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _billingRow('Start Date', DateFormat('MMM dd, yyyy').format(now)),
                  const Divider(),
                  _billingRow('Next Billing', DateFormat('MMM dd, yyyy').format(next)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            s.isBangla ? 'Payment Method' : 'Payment Method',
            style: GoogleFonts.plusJakartaSans(fontSize: 29 * 0.62, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _payOption('mobile', 'Mobile Banking', 'bKash, Nagad, Rocket'),
          const SizedBox(height: 10),
          _payOption('card', 'Card', 'Visa, MasterCard'),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                _SubscriptionSelection(
                  paymentMethod: _payment == 'mobile' ? 'Mobile Banking' : 'Card',
                ),
              ),
              child: Text(s.isBangla ? 'সাবস্ক্রিপশন কনফার্ম করুন' : 'Confirm Subscription'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTick(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFFBFDBFE), size: 20),
          const SizedBox(width: 8),
          Text(t, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _billingRow(String label, String value) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 20,
          backgroundColor: Color(0xFFE5E7EB),
          child: Icon(Icons.calendar_month_rounded, color: AppColors.brand),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
            Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 22 * 0.62)),
          ],
        ),
      ],
    );
  }

  Widget _payOption(String id, String title, String subtitle) {
    final selected = _payment == id;
    return Material(
      color: selected ? AppColors.brandLight.withValues(alpha: 0.14) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.brand : AppColors.border, width: 1.5),
      ),
      child: InkWell(
        onTap: () => setState(() => _payment = id),
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.brandLight.withValues(alpha: 0.16),
        highlightColor: AppColors.brandLight.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: selected ? AppColors.brand : const Color(0xFFE2E8F0),
                child: Icon(
                  id == 'mobile' ? Icons.phone_android_rounded : Icons.credit_card_rounded,
                  color: selected ? Colors.white : AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 26 * 0.62)),
                    Text(subtitle, style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? AppColors.brand : AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionSelection {
  const _SubscriptionSelection({required this.paymentMethod});
  final String paymentMethod;
}

class _VehicleTab extends StatelessWidget {
  const _VehicleTab({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.brandLight.withValues(alpha: 0.14),
        highlightColor: AppColors.brandLight.withValues(alpha: 0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: AppColors.brand.withValues(alpha: 0.32))
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.brand : AppColors.muted),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
