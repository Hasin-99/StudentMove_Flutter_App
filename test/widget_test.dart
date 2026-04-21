import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:studentmove/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App shows splash asset then sign-in', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentMoveApp());

    expect(
      find.byWidgetPredicate((w) {
        if (w is! Image) return false;
        final img = w.image;
        return img is AssetImage && img.assetName.contains('splash_brand.png');
      }),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
