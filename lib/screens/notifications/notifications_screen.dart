import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_inbox_provider.dart';
import '../../providers/saved_routes_provider.dart';
import '../../services/announcement_repository.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_motion.dart';
import '../../widgets/motion_specs.dart';

/// Push inbox — build reference §4.4 (list from GET /notifications when live).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.strings});

  final AppStrings strings;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final savedRoutes = context.read<SavedRoutesProvider>();
    try {
      await context.read<AnnouncementRepository>().refresh(
            email: auth.userEmail,
            department: auth.department,
            routes: savedRoutes.items,
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Notifications refresh failed: $e');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not refresh notifications. Please try again.')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AnnouncementRepository>();
    final inbox = context.watch<NotificationInboxProvider>();
    final items = repo.items;
    final inboxItems = inbox.items;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.strings.isBangla ? 'নোটিফিকেশন' : 'Notifications'),
        actions: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.pageHPad,
            AppLayout.pageTopPad,
            AppLayout.pageHPad,
            AppLayout.pageBottomPad,
          ),
          children: [
            if (inboxItems.isNotEmpty) ...[
              AnimatedSection(
                order: 0,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.strings.isBangla ? 'লাইভ ইনবক্স' : 'Live Inbox',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: inbox.clearAll,
                      child: Text(widget.strings.isBangla ? 'মুছুন' : 'Clear'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...inboxItems.map(
                (n) => AnimatedSection(
                  order: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(23),
                          ),
                          child: const Icon(Icons.notifications_active_rounded, color: AppColors.brand),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.body,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('HH:mm').format(n.receivedAt),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.muted.withValues(alpha: 0.85),
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
              const SizedBox(height: 8),
            ],
            if (repo.loading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Column(
                children: const [
                  _StaticNotificationTile(
                    title: 'General Notifications',
                    body: 'High fived your workout',
                    time: '0 min',
                    icon: Icons.notifications_active_rounded,
                    tint: Color(0xFF93C5FD),
                  ),
                  SizedBox(height: 12),
                  _StaticNotificationTile(
                    title: 'Bus Arrivals/Delays',
                    body: 'High fived your workout',
                    time: '6 min',
                    icon: Icons.directions_bus_rounded,
                    tint: Color(0xFF86EFAC),
                  ),
                  SizedBox(height: 12),
                  _StaticNotificationTile(
                    title: 'Service Alerts',
                    body: 'High fived your workout',
                    time: '15 min',
                    icon: Icons.lightbulb_outline_rounded,
                    tint: Color(0xFFFDE68A),
                  ),
                ],
              )
            else
              ...items.map((a) {
                return AnimatedSection(
                  order: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppLayout.cardRadius),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.brandLight.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_rounded, color: AppColors.brand),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                a.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                a.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('m min').format(a.publishAt.toLocal()),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.muted.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, color: Color(0xFF3B82F6), size: 8),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
      floatingActionButton: MotionFabSmall(
        onPressed: _refresh,
        child: const Icon(Icons.refresh_rounded),
      ),
    );
  }
}

class _StaticNotificationTile extends StatelessWidget {
  const _StaticNotificationTile({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.tint,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppLayout.cardRadius),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: tint.withValues(alpha: 0.3),
            child: Icon(icon, color: const Color(0xFF334155)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.circle, color: Color(0xFF3B82F6), size: 8),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
