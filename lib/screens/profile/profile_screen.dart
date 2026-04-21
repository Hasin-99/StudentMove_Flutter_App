import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/saved_routes_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_motion.dart';
import '../../widgets/motion_specs.dart';
import '../../widgets/feedback_sheet.dart';
import '../booking/booking_screen.dart';
import '../chat/chat_screen.dart';
import '../driver/driver_companion_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _localAuth = LocalAuthentication();
  bool _biometricOn = false;
  bool _bioLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBioPref();
  }

  Future<void> _loadBioPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _bioLoading = false;
      _biometricOn = prefs.getBool('biometric_on') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocaleProvider>();
    final s = AppStrings(loc.locale);
    final auth = context.watch<AuthProvider>();
    final routes = context.watch<SavedRoutesProvider>();
    final hPad = AppLayout.pageHPadFor(context);
    final topPad = AppLayout.pageTopPadFor(context);
    final bottomPad = AppLayout.pageBottomPadFor(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final sectionGap = viewportWidth >= 1200
        ? AppLayout.sectionGapFor(context) + 6
        : AppLayout.sectionGapFor(context);
    final maxWidth = viewportWidth >= 1200
        ? 1080.0
        : viewportWidth >= 900
            ? 940.0
            : AppLayout.contentMaxWidthFor(context);
    final profileNameSize = viewportWidth >= 1200
        ? 24.0
        : viewportWidth >= 900
            ? 22.0
            : 20.0;
    final profileEmailSize = viewportWidth >= 1200 ? 14.0 : 13.0;
    final ctaHeight = viewportWidth >= 1200
        ? 54.0
        : viewportWidth >= 900
            ? 52.0
            : 50.0;
    final leadingIconSize = viewportWidth >= 1200 ? 24.0 : 22.0;
    final trailingIconSize = viewportWidth >= 1200 ? 22.0 : 20.0;

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              hPad,
              topPad,
              hPad,
              bottomPad + 8,
            ),
            children: [
          AnimatedSection(
            order: 0,
            child: Container(
            padding: EdgeInsets.all(viewportWidth >= 900 ? 24 : 22),
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1F3B82F6),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final infoBlock = Column(
                  children: [
                    CircleAvatar(
                      radius: viewportWidth >= 1200 ? 40 : 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      backgroundImage: !kIsWeb &&
                              (auth.profileImagePath?.isNotEmpty ?? false) &&
                              File(auth.profileImagePath!).existsSync()
                          ? FileImage(File(auth.profileImagePath!))
                          : null,
                      child: (!kIsWeb &&
                              (auth.profileImagePath?.isNotEmpty ?? false) &&
                              File(auth.profileImagePath!).existsSync())
                          ? null
                          : Text(
                              (auth.userName?.isNotEmpty ?? false) ? auth.userName![0].toUpperCase() : 'U',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: viewportWidth >= 1200 ? 30 : 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      auth.userName ?? '—',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: profileNameSize,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.userEmail ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: profileEmailSize,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                );
                final editButton = ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => EditProfileScreen(
                          initialName: auth.userName ?? '',
                          initialEmail: auth.userEmail ?? '',
                          initialPhone: auth.userPhone ?? '',
                          initialInstitutionType: auth.institutionType ?? 'university',
                          initialInstitutionName: auth.institutionName ?? '',
                          initialDepartment: auth.department ?? '',
                          initialDateOfBirth: auth.dateOfBirth ?? '',
                          initialAddress: auth.address ?? '',
                          initialPhotoPath: auth.profileImagePath ?? '',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.brandDark,
                    minimumSize: Size(0, ctaHeight),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(s.isBangla ? 'প্রোফাইল এডিট' : 'Edit Profile'),
                );
                if (!isWide) {
                  return Column(
                    children: [
                      infoBlock,
                      const SizedBox(height: 12),
                      editButton,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: infoBlock),
                    const SizedBox(width: 16),
                    editButton,
                  ],
                );
              },
            ),
            ),
          ),
          SizedBox(height: sectionGap),
          AnimatedSection(
            order: 1,
            child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 768;
              final languageCard = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(s.language),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: SwitchListTile(
                      title: Text(s.isBangla ? 'বাংলা' : 'Bangla'),
                      subtitle: Text(s.isBangla ? 'বাংলা ইন্টারফেস' : 'Bangla interface'),
                      value: loc.isBangla,
                      onChanged: (_) => loc.toggleBangla(),
                      activeColor: AppColors.brand,
                    ),
                  ),
                ],
              );
              final bioCard = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section(s.biometric),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: _bioLoading
                        ? const ListTile(leading: CircularProgressIndicator(strokeWidth: 2), title: Text('…'))
                        : SwitchListTile(
                            title: Text(s.biometric),
                            subtitle: Text(
                              s.isBangla
                                  ? 'ফেস আইডি / ফিঙ্গারপ্রিন্ট (ডিভাইস সাপোর্ট লাগবে)'
                                  : 'Face ID / fingerprint when device supports local_auth',
                            ),
                            value: _biometricOn,
                            onChanged: (v) => _onBiometricToggle(context, s, v),
                            activeColor: AppColors.brand,
                          ),
                  ),
                ],
              );
              if (!isWide) {
                return Column(
                  children: [
                    languageCard,
                    SizedBox(height: sectionGap),
                    bioCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: languageCard),
                  const SizedBox(width: 12),
                  Expanded(child: bioCard),
                ],
              );
            },
            ),
          ),
          SizedBox(height: sectionGap),
          AnimatedSection(
            order: 2,
            child: Column(
              children: [
                _section(s.savedRoutes),
                Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (routes.items.isEmpty)
                  ListTile(
                    leading: Icon(Icons.route_rounded, color: AppColors.muted, size: leadingIconSize),
                    title: Text(
                      s.isBangla ? 'কোনো রুট সংরক্ষিত নেই' : 'No saved routes',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.muted),
                    ),
                  )
                else
                  ...routes.items.map(
                    (r) => ListTile(
                      title: Text(r),
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded, size: leadingIconSize),
                        onPressed: () => routes.remove(r),
                      ),
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.add_rounded, color: AppColors.brand, size: leadingIconSize),
                  title: Text(s.isBangla ? 'রুট যোগ করুন' : 'Add route'),
                  onTap: () => _promptAddRoute(context, routes, s),
                ),
              ],
            ),
                ),
              ],
            ),
          ),
          SizedBox(height: sectionGap),
          AnimatedSection(
            order: 3,
            child: Column(
              children: [
                _section(s.isBangla ? 'সেবা' : 'Services'),
                LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth >= 1200;
              final spacing = 10.0;
              final tileWidth = twoCols
                  ? (constraints.maxWidth - spacing) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: spacing,
                runSpacing: 0,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _tile(
                      Icons.chat_bubble_outline_rounded,
                      s.supportChat,
                      () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChatScreen())),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _tile(Icons.feedback_outlined, s.feedback, () => showFeedbackSheet(context, s)),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _tile(
                      Icons.directions_bus_filled_outlined,
                      s.driverConsole,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const DriverCompanionScreen()),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _tile(
                      Icons.event_seat_outlined,
                      s.bookSeat,
                      () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const BookingScreen())),
                    ),
                  ),
                ],
              );
            },
                ),
              ],
            ),
          ),
          SizedBox(height: sectionGap),
          SizedBox(
            height: ctaHeight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                final saved = context.read<SavedRoutesProvider>();
                final nav = Navigator.of(context);
                await auth.signOut();
                await saved.load();
                if (!mounted) return;
                nav.pushNamedAndRemoveUntil('/signin', (r) => false);
              },
              icon: Icon(Icons.logout_rounded, size: leadingIconSize),
              label: Text(s.signOut),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFECACA)),
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onBiometricToggle(BuildContext context, AppStrings s, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    if (enable) {
      try {
        final can = await _localAuth.canCheckBiometrics;
        if (!can) {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                s.isBangla ? 'এই ডিভাইসে বায়োমেট্রিক নেই' : 'Biometrics not available on this device',
              ),
            ),
          );
          return;
        }
        final ok = await _localAuth.authenticate(
          localizedReason: s.isBangla ? 'StudentMove আনলক করতে' : 'Unlock StudentMove',
        );
        if (!ok) return;
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text('$e')));
        return;
      }
    }
    if (!mounted) return;
    setState(() => _biometricOn = enable);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_on', enable);
  }

  Future<void> _promptAddRoute(
    BuildContext context,
    SavedRoutesProvider routes,
    AppStrings s,
  ) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.savedRoutes),
        content: TextField(
          controller: c,
          decoration: InputDecoration(hintText: s.routeSearchHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: Text(s.submit)),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await routes.add(name);
    }
    c.dispose();
  }

  static Widget _section(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        t.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.05,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final leadingIconSize = viewportWidth >= 1200 ? 24.0 : 22.0;
    final trailingIconSize = viewportWidth >= 1200 ? 22.0 : 20.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HoverPressCard(
        onTap: onTap,
        borderRadius: 18,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        splashColor: AppColors.brandLight.withValues(alpha: 0.14),
        highlightColor: AppColors.brandLight.withValues(alpha: 0.1),
        child: ListTile(
          leading: Icon(icon, color: AppColors.brand, size: leadingIconSize),
          title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          trailing: Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: trailingIconSize),
        ),
      ),
    );
  }
}
