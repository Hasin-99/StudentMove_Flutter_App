import 'package:flutter/material.dart';
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
            onPressed: () {
              setState(() => _broadcasting = !_broadcasting);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _broadcasting
                        ? (s.isBangla
                            ? 'ট্রিপ শুরু (স্টাব)। ক্লাউড ফাংশন দিয়ে লাইভ লোকেশন যুক্ত করুন'
                            : 'Trip started (stub). Wire live location cloud function.')
                        : (s.isBangla
                            ? 'ট্রিপ বন্ধ'
                            : 'Trip stopped'),
                  ),
                ),
              );
            },
            icon: Icon(_broadcasting ? Icons.stop_rounded : Icons.play_arrow_rounded),
            label: Text(_broadcasting ? s.stopTrip : s.startTrip),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: _broadcasting ? const Color(0xFFDC2626) : AppColors.brand,
            ),
          ),
        ],
      ),
    );
  }
}
