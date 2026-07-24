import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/app_error.dart';
import 'core/firebase_bootstrap.dart';
import 'core/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_inbox_provider.dart';
import 'providers/notification_prefs_provider.dart';
import 'providers/saved_routes_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/schedule_repository.dart';
import 'services/announcement_repository.dart';
import 'services/live_bus_repository.dart';
import 'services/chat_repository.dart';
import 'services/booking_repository.dart';
import 'services/feedback_repository.dart';
import 'services/offer_repository.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = true;
    installGlobalErrorHandlers(messengerKey: appMessengerKey);

    try {
      await FirebaseBootstrap.initialize();
    } catch (e, st) {
      final mapped = ErrorMapper.from(e, st);
      debugPrint('Firebase bootstrap failed: $mapped');
      // Still launch UI so users see a recoverable error instead of a blank crash.
    }

    try {
      await NotificationService.initialize(
        navigatorKey: appNavigatorKey,
        messengerKey: appMessengerKey,
      );
    } catch (e, st) {
      debugPrint('Notification init failed: ${ErrorMapper.from(e, st)}');
    }

    runApp(const StudentMoveApp());
  }, (error, stack) {
    final mapped = ErrorMapper.from(error, stack);
    debugPrint('Zone error: $mapped');
    appMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(mapped.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  });
}

class StudentMoveApp extends StatelessWidget {
  const StudentMoveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => NotificationInboxProvider()),
        ChangeNotifierProvider(create: (_) => NotificationPrefsProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, sub) {
            sub ??= SubscriptionProvider();
            sub.bindUser(auth.userId);
            return sub;
          },
        ),
        ChangeNotifierProvider(create: (_) => SavedRoutesProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleRepository()),
        ChangeNotifierProvider(create: (_) => AnnouncementRepository()),
        ChangeNotifierProvider(create: (_) => LiveBusRepository()),
        ChangeNotifierProvider(create: (_) => ChatRepository()),
        ChangeNotifierProxyProvider<AuthProvider, BookingRepository>(
          create: (_) => BookingRepository(),
          update: (_, auth, repo) {
            repo ??= BookingRepository();
            repo.bindUser(auth.userId);
            return repo;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FeedbackRepository>(
          create: (_) => FeedbackRepository(),
          update: (_, auth, repo) {
            repo ??= FeedbackRepository();
            repo.bindUser(auth.userId);
            return repo;
          },
        ),
        ChangeNotifierProvider(create: (_) => OfferRepository()),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) {
          final base = AppTheme.light();
          final textTheme = locale.isBangla
              ? GoogleFonts.hindSiliguriTextTheme(base.textTheme).apply(
                    bodyColor: AppColors.ink,
                    displayColor: AppColors.ink,
                  )
              : base.textTheme;

          return MaterialApp(
            navigatorKey: appNavigatorKey,
            scaffoldMessengerKey: appMessengerKey,
            title: 'StudentMove',
            debugShowCheckedModeBanner: false,
            theme: base.copyWith(textTheme: textTheme),
            locale: locale.locale,
            supportedLocales: const [
              Locale('en'),
              Locale('bn'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              ErrorWidget.builder = (details) {
                return Material(
                  color: AppColors.surface,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
                          const SizedBox(height: 12),
                          Text(
                            'This screen hit a glitch.',
                            style: GoogleFonts.syne(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            kDebugMode
                                ? details.exceptionAsString()
                                : 'Please go back and try again.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.ibmPlexSans(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              };
              return child ?? const SizedBox.shrink();
            },
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/signin': (context) => const SignInScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/forgot-password': (context) => const ForgotPasswordScreen(),
              '/home': (context) => const HomeScreen(),
            },
          );
        },
      ),
    );
  }
}
