import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_prefs_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/motion_specs.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppStrings(context.watch<LocaleProvider>().locale);
    final prefs = context.watch<NotificationPrefsProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(s.isBangla ? 'নোটিফিকেশন সেটিংস' : 'Notification settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AnimatedSection(
            order: 0,
            child: Text(
              s.isBangla
                  ? 'কোন অ্যালার্ট পেতে চান তা বেছে নিন'
                  : 'Choose which StudentMove alerts reach you',
              style: GoogleFonts.ibmPlexSans(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSection(
            order: 1,
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.timelapse_rounded, color: AppColors.accent),
                    title: Text(
                      s.isBangla ? 'বাস ডিলে' : 'Bus delay alerts',
                      style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      s.isBangla
                          ? 'লাইভ GPS ডিলে হলে জানান'
                          : 'Get notified when live GPS reports a delay',
                    ),
                    value: prefs.busDelay,
                    activeColor: AppColors.brand,
                    onChanged: prefs.loaded ? (v) => prefs.setBusDelay(v) : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.alt_route_rounded, color: AppColors.brand),
                    title: Text(
                      s.isBangla ? 'রুট পরিবর্তন' : 'Route change alerts',
                      style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      s.isBangla
                          ? 'সেভ করা রুটে পরিবর্তন'
                          : 'Updates when your saved routes change',
                    ),
                    value: prefs.routeChange,
                    activeColor: AppColors.brand,
                    onChanged: prefs.loaded ? (v) => prefs.setRouteChange(v) : null,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.local_offer_rounded, color: AppColors.accentHot),
                    title: Text(
                      s.isBangla ? 'প্রমোশনাল অফার' : 'Promotional offers',
                      style: GoogleFonts.ibmPlexSans(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      s.isBangla
                          ? 'স্টুডেন্ট পাস ও অফার'
                          : 'Student pass deals and campus offers',
                    ),
                    value: prefs.promotional,
                    activeColor: AppColors.brand,
                    onChanged: prefs.loaded ? (v) => prefs.setPromotional(v) : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
