import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../notifications/notifications_screen.dart';
import '../subscribe/subscribe_screen.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.isBangla ? 'অফারস' : 'Offers'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.pageHPad,
          AppLayout.pageTopPad,
          AppLayout.pageHPad,
          AppLayout.pageBottomPad,
        ),
        children: [
          _TopOfferCard(strings: strings),
          const SizedBox(height: 12),
          _ReferralCard(strings: strings),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => NotificationsScreen(strings: strings),
                ),
              );
            },
            icon: const Icon(Icons.notifications_rounded),
            label: Text(strings.isBangla ? 'নোটিফিকেশন দেখুন' : 'View Notifications'),
          ),
        ],
      ),
    );
  }
}

class _TopOfferCard extends StatelessWidget {
  const _TopOfferCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppLayout.cardRadius + 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isBangla ? '১০-১৫% ছাড়' : '10-15% OFF',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  strings.isBangla ? 'সকল সার্ভিসে' : 'Now in Package\nAll Services',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const SubscribeScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      strings.isBangla ? 'এখনই বুক করুন' : 'Book Now',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 78,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 34),
          ),
        ],
      ),
    );
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppLayout.cardRadius + 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              strings.isBangla ? 'বন্ধুকে রেফার করুন\n১০% ছাড় পান' : 'Refer a friend\nGet 10% OFF',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
              color: Colors.white.withValues(alpha: 0.14),
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}
