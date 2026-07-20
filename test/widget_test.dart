import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studentmove/providers/auth_provider.dart';
import 'package:studentmove/screens/auth/signin_screen.dart';
import 'package:studentmove/screens/splash_screen.dart';

/// Auth stub for widget tests — avoids requiring Firebase initialization.
class _TestAuthProvider extends ChangeNotifier implements AuthProvider {
  _TestAuthProvider({this.authenticated = false});

  bool authenticated;
  bool checkAuthCalled = false;

  @override
  bool get isAuthenticated => authenticated;

  @override
  Future<void> checkAuthStatus() async {
    checkAuthCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash shows branding then navigates to sign-in', (WidgetTester tester) async {
    final auth = _TestAuthProvider(authenticated: false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: MaterialApp(
          home: const SplashScreen(),
          routes: {
            '/signin': (_) => const SignInScreen(),
            '/home': (_) => const Scaffold(body: Text('home')),
          },
        ),
      ),
    );

    expect(find.text('StudentMove'), findsOneWidget);
    expect(find.text('Your journey starts here'), findsOneWidget);
    expect(find.byIcon(Icons.directions_car_outlined), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2200));
    await tester.pumpAndSettle();

    expect(auth.checkAuthCalled, isTrue);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Login to continue your journey'), findsOneWidget);
  });
}
