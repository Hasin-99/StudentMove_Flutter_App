import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/quick_actions_dock.dart';

/// Plans, payment launchers, invoice area — build reference §4.3.
class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  String _vehicle = 'bus';
  final GlobalKey _invoiceHeaderKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const _plans = [
    _PlanDef('Basic', 1200, '/month', Duration(days: 30), rides: '20 rides per month'),
    _PlanDef('Standard', 1800, '/month', Duration(days: 30), rides: '40 rides per month'),
    _PlanDef('Yearly', 12000, '/year', Duration(days: 365), rides: 'Unlimited bus rides'),
  ];

  Future<void> _jumpToInvoiceHistory() async {
    final contextForHeader = _invoiceHeaderKey.currentContext;
    if (contextForHeader == null) return;
    await Scrollable.ensureVisible(
      contextForHeader,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);
    final sub = context.watch<SubscriptionProvider>();
    final maxWidth = AppLayout.contentMaxWidthFor(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.isBangla ? 'সাবস্ক্রিপশন প্ল্যান' : 'Subscription Plans'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pageHPad,
              AppLayout.pageTopPad,
              AppLayout.pageHPad,
              32,
            ),
            children: [
          Container(
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
          const SizedBox(height: 16),
          if (sub.hasActiveSubscription)
            Card(
              color: AppColors.brandLight.withValues(alpha: 0.15),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: AppColors.success),
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
                          await subProvider.cancelActivePlan();
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
                        icon: const Icon(Icons.cancel_outlined),
                        label: Text(
                          s.isBangla ? 'সাবস্ক্রিপশন বাতিল করুন' : 'Cancel subscription',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (sub.hasActiveSubscription) const SizedBox(height: 16),
          Text(
            s.isBangla ? 'সাবস্ক্রিপশন প্ল্যান' : 'Subscription Plans',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            s.isBangla
                ? 'আপনার দৈনন্দিন যাত্রার জন্য সেরা প্ল্যান বেছে নিন'
                : 'Choose the best plan for your daily commute',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 860;
              final cardWidth = isWide
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
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
                            await subProvider.activatePlan(
                              p.name,
                              p.duration,
                              amount: p.price.toDouble(),
                              paymentMethod: details.paymentMethod,
                            );
                            if (!context.mounted) return;
                            final invoices = subProvider.invoices;
                            final invoice = invoices.isEmpty ? null : invoices.first;
                            if (invoice != null) {
                              await showDialog<void>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(s.isBangla ? 'ইনভয়েস' : 'Invoice'),
                                  content: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 460, maxHeight: 280),
                                    child: SingleChildScrollView(
                                      child: Text(
                                        '${invoice.planName}\n'
                                        '${s.isBangla ? 'পরিমাণ' : 'Amount'}: ৳${NumberFormat('#,##0').format(invoice.amount)}\n'
                                        '${s.isBangla ? 'পেমেন্ট' : 'Payment'}: ${invoice.paymentMethod}\n'
                                        '${s.isBangla ? 'পেমেন্ট তারিখ' : 'Paid'}: ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.paidAt)}\n'
                                        '${s.isBangla ? 'ভ্যালিড আনটিল' : 'Valid until'}: ${DateFormat('dd MMM yyyy').format(invoice.validUntil)}',
                                      ),
                                    ),
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
          const SizedBox(height: 28),
          Text(
            key: _invoiceHeaderKey,
            s.isBangla ? 'ইনভয়েস হিস্ট্রি' : 'Invoice history',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (sub.invoices.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined, color: AppColors.muted, size: 32),
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
                  leading: const Icon(Icons.receipt_long_rounded, color: AppColors.brand),
                  title: Text(
                    inv.planName,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Amount: ৳${NumberFormat('#,##0').format(inv.amount)} · ${inv.paymentMethod}\n'
                    'Paid: ${DateFormat('dd MMM yyyy, hh:mm a').format(inv.paidAt)}\n'
                    'Valid until: ${DateFormat('dd MMM yyyy').format(inv.validUntil)}',
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: s.isBangla ? 'ডাউনলোড PDF' : 'Download PDF',
                        onPressed: () => _downloadInvoicePdf(context, inv, s),
                        icon: const Icon(Icons.download_rounded, color: AppColors.brand),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                    ],
                  ),
                  onTap: () => _showInvoiceActions(context, inv, s),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
      floatingActionButton: QuickActionsDock(
        actions: [
          QuickActionItem(
            heroTag: 'subscription_jump_invoice',
            tooltip: 'Jump to invoice history',
            icon: Icons.receipt_long_rounded,
            onPressed: _jumpToInvoiceHistory,
          ),
        ],
      ),
    );
  }
}

Future<void> _showInvoiceActions(
  BuildContext context,
  SubscriptionInvoice invoice,
  AppStrings strings,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(
          strings.isBangla ? 'ইনভয়েস ডিটেইলস' : 'Invoice Details',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 320),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plan: ${invoice.planName}'),
                Text('Invoice ID: ${invoice.id}'),
                Text('Amount: ৳${NumberFormat('#,##0').format(invoice.amount)}'),
                Text('Payment Method: ${invoice.paymentMethod}'),
                Text('Paid: ${DateFormat('dd MMM yyyy, hh:mm a').format(invoice.paidAt)}'),
                Text('Valid until: ${DateFormat('dd MMM yyyy').format(invoice.validUntil)}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.isBangla ? 'বন্ধ করুন' : 'Close'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _downloadInvoicePdf(context, invoice, strings);
            },
            icon: const Icon(Icons.download_rounded),
            label: Text(strings.isBangla ? 'ডাউনলোড PDF' : 'Download PDF'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _printInvoice(invoice);
            },
            icon: const Icon(Icons.print_rounded),
            label: Text(strings.isBangla ? 'প্রিন্ট' : 'Print'),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadInvoicePdf(
  BuildContext context,
  SubscriptionInvoice invoice,
  AppStrings strings,
) async {
  final path = await _printInvoice(invoice);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        path != null
            ? 'Invoice PDF saved: $path'
            : (strings.isBangla ? 'PDF শেয়ার অপশন চালু হয়েছে' : 'PDF share opened'),
      ),
    ),
  );
}

Future<String?> _printInvoice(SubscriptionInvoice invoice) async {
  final regularFont = await PdfGoogleFonts.notoSansRegular();
  final boldFont = await PdfGoogleFonts.notoSansBold();
  final doc = pw.Document(
    theme: pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    ),
  );
  final paidAt = DateFormat('EEEE, dd MMM yyyy, hh:mm a').format(invoice.paidAt);
  final validUntil = DateFormat('EEEE, dd MMM yyyy').format(invoice.validUntil);
  final issuedOn = DateFormat('EEEE, dd MMM yyyy').format(invoice.paidAt);
  final subtotal = invoice.amount;
  const vat = 0.0;
  final total = subtotal + vat;
  final invoiceCode = invoice.id.length > 8 ? invoice.id.substring(0, 8).toUpperCase() : invoice.id.toUpperCase();
  final referenceNo = 'SM-INV-$invoiceCode';
  String money(double amount) => 'BDT ${amount.toStringAsFixed(2)}';

  doc.addPage(
    pw.Page(
      pageTheme: pw.PageTheme(
        margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 24),
        buildBackground: (context) => _pdfWatermark('STUDENTMOVE'),
      ),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#142A6B'),
                borderRadius: pw.BorderRadius.circular(12),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'StudentMove',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Official Billing Document',
                        style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
                      ),
                    ],
                  ),
                  pw.Text(
                    'INVOICE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F6F8FC'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      'Invoice ID: #$invoiceCode',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Text(
                    'Issued: $issuedOn',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Subscriber Information',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#1F2937'),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Reference No: $referenceNo', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Plan: ${invoice.planName}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment Method: ${invoice.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment Status: Paid', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment Date: $paidAt', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Valid Until: $validUntil', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text('Payment Terms: Immediate', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'),
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Verification',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1F2937'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Scan QR to verify reference', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(referenceNo, style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: 'StudentMove|Invoice|$referenceNo|$paidAt|${money(total)}',
                    width: 58,
                    height: 58,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColor.fromHex('#E5E7EB'), width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(1.1),
                2: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColor.fromHex('#EEF2FF')),
                  children: [
                    _tableHeaderCell('Description'),
                    _tableHeaderCell('Qty', alignRight: true),
                    _tableHeaderCell('Amount', alignRight: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableBodyCell('${invoice.planName} subscription access'),
                    _tableBodyCell('1', alignRight: true),
                    _tableBodyCell(money(subtotal), alignRight: true),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableBodyCell('VAT'),
                    _tableBodyCell('-', alignRight: true),
                    _tableBodyCell(money(vat), alignRight: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 14),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 230,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#142A6B'),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    _summaryRow('Subtotal', money(subtotal)),
                    _summaryRow('VAT', money(vat)),
                    pw.Divider(color: PdfColors.white, thickness: 0.4),
                    _summaryRow('Total', money(total), bold: true),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F9FAFB'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Issuer',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#374151'),
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text('StudentMove Transit Services, Dhaka', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('support@studentmove.app', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('Currency: BDT', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Divider(color: PdfColor.fromHex('#D1D5DB')),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Thank you for choosing StudentMove.',
                  style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#6B7280')),
                ),
                pw.Text(
                  'Generated digitally - no signature required',
                  style: pw.TextStyle(fontSize: 8, color: PdfColor.fromHex('#9CA3AF')),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  final bytes = await doc.save();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    final fileName = 'studentmove_invoice_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final docsDir = await getApplicationDocumentsDirectory();
    final downloadsDir = await getDownloadsDirectory();
    final home = Platform.environment['HOME'];
    final candidateDirs = <Directory>[
      if (home != null && home.isNotEmpty) Directory('$home/Downloads'),
      if (downloadsDir != null) downloadsDir,
      docsDir,
    ];
    for (final dir in candidateDirs) {
      final file = File('${dir.path}/$fileName');
      try {
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        await file.writeAsBytes(bytes, flush: true);
        debugPrint('Invoice saved: ${file.path}');
        return file.path;
      } catch (e) {
        debugPrint('Invoice save failed at ${dir.path}: $e');
      }
    }
    debugPrint('Invoice save failed: no writable target directory found');
    return null;
  }
  await Printing.sharePdf(
    bytes: bytes,
    filename: 'studentmove_invoice_${invoice.id}.pdf',
  );
  return null;
}

pw.Widget _tableHeaderCell(String text, {bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
        color: PdfColor.fromHex('#1F2937'),
      ),
    ),
  );
}

pw.Widget _tableBodyCell(String text, {bool alignRight = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      style: const pw.TextStyle(fontSize: 10),
    ),
  );
}

pw.Widget _summaryRow(String label, String value, {bool bold = false}) {
  final style = pw.TextStyle(
    color: PdfColors.white,
    fontSize: bold ? 11 : 10,
    fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
  );
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    ),
  );
}

pw.Widget _pdfWatermark(String text) {
  return pw.FullPage(
    ignoreMargins: true,
    child: pw.Center(
      child: pw.Transform.rotate(
        angle: -0.45,
        child: pw.Opacity(
          opacity: 0.05,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 72,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1E3A8A'),
            ),
          ),
        ),
      ),
    ),
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
    return Container(
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(color: AppColors.muted)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 22 * 0.62),
              ),
            ],
          ),
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
