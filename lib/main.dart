import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/firebase_bootstrap.dart';
import 'core/notification_service.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/notification_inbox_provider.dart';
import 'providers/saved_routes_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/schedule_repository.dart';
import 'services/announcement_repository.dart';
import 'services/live_bus_repository.dart';
import 'services/chat_repository.dart';
import 'screens/auth/signin_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep runtime fetching enabled so missing bundled font files don't crash UI.
  GoogleFonts.config.allowRuntimeFetching = true;
  await FirebaseBootstrap.initialize();
  await NotificationService.initialize(
    navigatorKey: appNavigatorKey,
    messengerKey: appMessengerKey,
  );
  runApp(const StudentMoveApp());
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
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => SavedRoutesProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleRepository()),
        ChangeNotifierProvider(create: (_) => AnnouncementRepository()),
        ChangeNotifierProvider(create: (_) => LiveBusRepository()),
        ChangeNotifierProvider(create: (_) => ChatRepository()),
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
