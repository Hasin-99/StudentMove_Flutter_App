import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/offline_banner.dart';
import '../booking/booking_screen.dart';
import '../bus_tracking/bus_tracking_screen.dart';
import '../chat/chat_screen.dart';
import '../next_bus_arrival/next_bus_arrival_screen.dart';
import '../notifications/notifications_screen.dart';
import '../offers/offers_screen.dart';
import '../profile/profile_screen.dart';
import '../subscribe/subscribe_screen.dart';

/// Bottom tabs match home reference: Home, Messages, Routes, Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final net = context.watch<ConnectivityProvider>();
    final s = AppStrings(loc.locale);

    final tabs = <Widget>[
      _HomeTabContent(strings: s),
      ChatScreen(onBack: () => setState(() => _index = 0)),
      const BookingScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (!net.isOnline) OfflineBanner(strings: s),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: KeyedSubtree(
                key: ValueKey<int>(_index),
                child: tabs[_index],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: s.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: s.isBangla ? 'মেসেজ' : 'Messages',
          ),
          NavigationDestination(
            icon: const Icon(Icons.route_outlined),
            selectedIcon: const Icon(Icons.route_rounded),
            label: s.isBangla ? 'রুটস' : 'Routes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: s.tabProfile,
          ),
        ],
      ),
    );
  }
}

class _HomeTabContent extends StatefulWidget {
  const _HomeTabContent({required this.strings});

  final AppStrings strings;

  @override
  State<_HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<_HomeTabContent> {
  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final hPad = AppLayout.pageHPadFor(context);
    final topPad = AppLayout.pageTopPadFor(context);
    final maxWidth = AppLayout.contentMaxWidthFor(context);
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final name = auth.userName ?? 'Traveler';
    final savedRoutes = <String>[
      'Uttara to DSC',
      'Uttara to DU',
    ];

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            hPad,
            topPad,
            hPad,
            110,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (sheetContext) {
                            return SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _QuickActionTile(
                                      icon: Icons.map_rounded,
                                      title: s.isBangla ? 'লাইভ ট্র্যাক' : 'Live Track',
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => const BusTrackingScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionTile(
                                      icon: Icons.card_membership_rounded,
                                      title: s.isBangla ? 'সাবস্ক্রিপশন' : 'Subscription',
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => const SubscribeScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionTile(
                                      icon: Icons.notifications_rounded,
                                      title: s.isBangla ? 'নোটিফিকেশন' : 'Notifications',
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => NotificationsScreen(strings: s),
                                          ),
                                        );
                                      },
                                    ),
                                    _QuickActionTile(
                                      icon: Icons.schedule_rounded,
                                      title: s.isBangla ? 'নেক্সট বাস' : 'Next Bus Arrival',
                                      onTap: () {
                                        Navigator.pop(sheetContext);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) => const NextBusArrivalScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.menu_rounded),
                      color: const Color(0xFF1F2937),
                    ),
                    const Spacer(),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  s.isBangla ? 'ফিরে আসায় স্বাগতম!' : 'Welcome back!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: narrow ? 20 : 22 * 1.1,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.isBangla
                      ? 'আজকের যাত্রা পরিকল্পনা করি'
                      : 'Ready to plan your journey?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: narrow ? 15 : 18 * 0.95,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  s.isBangla ? 'ড্যাশবোর্ড' : 'Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36 * 0.55,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.isBangla ? 'আজ কী করতে চান?' : 'What would you like to do?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 520;
                    if (stacked) {
                      return Column(
                        children: [
                          _HomeActionCard(
                            title: 'Next Bus Arrival',
                            subtitle: 'View upcoming buses',
                            tint: const Color(0xFFDBEAFE),
                            textColor: const Color(0xFF1E3A8A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const NextBusArrivalScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          _HomeActionCard(
                            title: 'Personalized Routes',
                            subtitle: 'Get recommendations',
                            tint: const Color(0xFFECFDF5),
                            textColor: const Color(0xFF047857),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const BookingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _HomeActionCard(
                            title: 'Next Bus Arrival',
                            subtitle: 'View upcoming buses',
                            tint: const Color(0xFFDBEAFE),
                            textColor: const Color(0xFF1E3A8A),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const NextBusArrivalScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _HomeActionCard(
                            title: 'Personalized Routes',
                            subtitle: 'Get recommendations',
                            tint: const Color(0xFFECFDF5),
                            textColor: const Color(0xFF047857),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const BookingScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                Material(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => OffersScreen(strings: s),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.isBangla ? 'বিশেষ অফার চলছে' : 'Special Offer Available',
                              style: TextStyle(
                                color: Color(0xFF92400E),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: Color(0xFFF59E0B)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  s.isBangla ? 'সাম্প্রতিক কার্যকলাপ' : 'Recent Activity',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 36 * 0.55,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 560;
                    final leftCard = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Past Routes',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16 * 0.95,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...savedRoutes.map(
                              (r) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 7,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        r,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          color: const Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    final rightCard = Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Feedback\nSubmitted',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16 * 0.95,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sub.hasActiveSubscription
                                  ? 'Thanks! plan active now.'
                                  : 'Thank you for sharing',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      );
                    if (stacked) {
                      return Column(
                        children: [
                          leftCard,
                          const SizedBox(height: 12),
                          rightCard,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: leftCard),
                        const SizedBox(width: 12),
                        Expanded(child: rightCard),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Icon(icon, color: const Color(0xFF2563EB)),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.textColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color tint;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SizedBox(
            height: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16 * 0.95,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(Icons.arrow_forward_rounded, color: textColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
