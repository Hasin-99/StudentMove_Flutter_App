import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studentmove/core/app_error.dart';
import 'package:studentmove/data/live_bus_data.dart';
import 'package:studentmove/services/ai_assistant_service.dart';
import 'package:studentmove/services/booking_repository.dart';
import 'package:studentmove/services/offer_repository.dart';
import 'package:studentmove/theme/app_theme.dart';
import 'package:studentmove/widgets/brand_logo_3d.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ErrorMapper', () {
    test('maps FirebaseAuth wrong-password', () {
      final mapped = ErrorMapper.from(
        FirebaseAuthException(code: 'wrong-password'),
      );
      expect(mapped.message.toLowerCase().contains('password'), isTrue);
      expect(mapped.code, 'wrong-password');
    });

    test('maps network-ish strings', () {
      final mapped = ErrorMapper.from(
        Exception('SocketException: Failed host lookup'),
      );
      expect(mapped.code, 'network');
    });

    test('maps timeout', () {
      final mapped = ErrorMapper.from(TimeoutException('slow'));
      expect(mapped.code, 'timeout');
    });

    test('passes through AppException', () {
      const original = AppException('hi', code: 'x');
      expect(ErrorMapper.from(original).message, 'hi');
    });
  });

  group('StudentMove design tokens', () {
    test('brand matches web route teal', () {
      expect(AppColors.brand.toARGB32(), 0xFF0B6E6A);
      expect(AppColors.accent.toARGB32(), 0xFFE0952C);
      expect(AppColors.paper.toARGB32(), 0xFFEDF2F1);
      expect(AppColors.graphite.toARGB32(), 0xFF1E2630);
    });
  });

  group('3D brand logo', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: BrandLogo3D(size: 96, float: false)),
          ),
        ),
      );
      expect(find.byType(BrandLogo3D), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('atmosphere backdrop paints', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Atmosphere3DBackdrop(
            child: SizedBox.expand(),
          ),
        ),
      );
      expect(find.byType(Atmosphere3DBackdrop), findsOneWidget);
    });
  });

  group('LiveBus GPS freshness', () {
    test('marks live within 45 seconds', () {
      final bus = LiveBus(
        id: '1',
        busCode: 'SM-101',
        lat: 23.87,
        lng: 90.40,
        heading: 90,
        speedKmph: 28,
        updatedAt: DateTime.now(),
      );
      expect(bus.gpsFreshness, GpsFreshness.live);
      expect(bus.gpsLabel, 'GPS live');
    });

    test('marks stale between 45 and 120 seconds', () {
      final bus = LiveBus(
        id: '1',
        busCode: 'SM-101',
        lat: 23.87,
        lng: 90.40,
        heading: 90,
        speedKmph: 10,
        updatedAt: DateTime.now().subtract(const Duration(seconds: 70)),
      );
      expect(bus.gpsFreshness, GpsFreshness.stale);
    });

    test('marks offline after 120 seconds', () {
      final bus = LiveBus(
        id: '1',
        busCode: 'SM-101',
        lat: 23.87,
        lng: 90.40,
        heading: 90,
        speedKmph: 0,
        updatedAt: DateTime.now().subtract(const Duration(seconds: 130)),
      );
      expect(bus.gpsFreshness, GpsFreshness.offline);
    });

    test('delay eta text', () {
      final bus = LiveBus(
        id: '1',
        busCode: 'SM-101',
        lat: 23.87,
        lng: 90.40,
        heading: 90,
        speedKmph: 20,
        updatedAt: DateTime.now(),
        delayMinutes: 5,
      );
      expect(bus.etaText.contains('Delayed'), isTrue);
    });
  });

  group('AI assistant', () {
    setUp(AiAssistantService.clear);

    test('answers monthly pass fare', () {
      final reply = AiAssistantService.reply('How much is the monthly pass?');
      expect(reply.toLowerCase().contains('1200'), isTrue);
    });

    test('answers booking help', () {
      final reply = AiAssistantService.reply('How do I book a seat?');
      expect(reply.toLowerCase().contains('seat'), isTrue);
    });

    test('answers delay/gps help', () {
      final reply =
          AiAssistantService.reply('Is the bus delayed on live track?');
      expect(
        reply.toLowerCase().contains('gps') ||
            reply.toLowerCase().contains('live'),
        isTrue,
      );
    });
  });

  group('Booking catalog', () {
    test('demo trips match StudentMove routes', () {
      expect(BookingRepository.demoTrips, isNotEmpty);
      expect(
        BookingRepository.demoTrips.any((t) => t.route.contains('Uttara')),
        isTrue,
      );
      expect(
        BookingRepository.demoTrips.every((t) => t.farePerSeat >= 25),
        isTrue,
      );
    });
  });

  group('Offers catalog', () {
    test('demo offers have discount and future expiry', () {
      expect(OfferRepository.demoOffers, isNotEmpty);
      expect(
        OfferRepository.demoOffers.every((o) => o.discountPercent > 0),
        isTrue,
      );
      expect(
        OfferRepository.demoOffers
            .every((o) => o.validUntil.isAfter(DateTime.now())),
        isTrue,
      );
    });
  });
}
