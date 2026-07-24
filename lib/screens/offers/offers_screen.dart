import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/offer_repository.dart';
import '../../theme/app_theme.dart';
import '../notifications/notifications_screen.dart';
import '../subscribe/subscribe_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfferRepository>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    final repo = context.watch<OfferRepository>();

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.isBangla ? 'অফারস' : 'Offers'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<OfferRepository>().refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.pageHPad,
            AppLayout.pageTopPad,
            AppLayout.pageHPad,
            AppLayout.pageBottomPad,
          ),
          children: [
            Text(
              strings.isBangla
                  ? 'সক্রিয় প্রমোশন'
                  : 'Active promotions',
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.isBangla
                  ? 'স্টুডেন্ট পাস ও রেফারেলে সঞ্চয় করুন'
                  : 'Save on student passes and referrals',
              style: GoogleFonts.ibmPlexSans(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (repo.loading && repo.offers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              ...repo.offers.map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.brandGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.elev1,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${o.discountPercent}% OFF',
                                style: GoogleFonts.ibmPlexSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Until ${DateFormat.MMMd().format(o.validUntil)}',
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          o.title,
                          style: GoogleFonts.syne(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          o.description,
                          style: GoogleFonts.ibmPlexSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const SubscribeScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              strings.isBangla ? 'প্ল্যান দেখুন' : 'View plans',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
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
              label: Text(
                strings.isBangla ? 'নোটিফিকেশন দেখুন' : 'View Notifications',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
