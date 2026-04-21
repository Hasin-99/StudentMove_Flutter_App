import 'package:flutter/material.dart';

/// Bangla / English copy aligned with StudentMove build reference (localization §12).
class AppStrings {
  AppStrings(this.locale);

  final Locale locale;

  bool get isBangla => locale.languageCode == 'bn';

  String _e(String en, String bn) => isBangla ? bn : en;

  // Tabs
  String get tabHome => _e('Home', 'হোম');
  String get tabTrack => _e('Track', 'ট্র্যাক');
  String get tabSubscribe => _e('Subscribe', 'সাবস্ক্রাইব');
  String get tabNotifications => _e('Notifications', 'নোটিফিকেশন');
  String get tabProfile => _e('Profile', 'প্রোফাইল');

  // Home
  String get homeGreeting => _e('Hello', 'হ্যালো');
  String get homeSubtitle =>
      _e('Where are you heading today?', 'আজ আপনি কোথায় যাবেন?');
  String get subscriptionActive => _e('Active subscription', 'সক্রিয় সাবস্ক্রিপশন');
  String get noSubscription =>
      _e('No active plan', 'কোনো সক্রিয় প্ল্যান নেই');
  String get daysLeft => _e('days left', 'দিন বাকি');
  String get nextBus => _e('Next bus', 'পরবর্তী বাস');
  String get nextBusHint => _e(
        'ETAs refresh from the server when online.',
        'অনলাইনে থাকলে সার্ভার থেকে সময় আপডেট হবে।',
      );
  String get routeSearch => _e('Quick route search', 'দ্রুত রুট খুঁজুন');
  String get routeSearchHint =>
      _e('Search route or stop name', 'রুট বা স্টপের নাম লিখুন');
  String get bookSeat => _e('Book a seat', 'আসন বুক করুন');
  String get offlineMessage => _e(
        'You are offline. Cached routes load from storage; live tracking and payments need internet.',
        'আপনি অফলাইন। ক্যাশ করা রুট দেখাবে; লাইভ ট্র্যাকিং ও পেমেন্টের জন্য ইন্টারনেট লাগবে।',
      );

  // Track
  String get trackTitle => _e('Live tracking', 'লাইভ ট্র্যাকিং');
  String get etaChips => _e('ETA at stops', 'স্টপে আগমনের সময়');
  String get stopsAlong => _e('Stops along route', 'রুটের স্টপসমূহ');

  // Subscribe
  String get subscribeTitle => _e('Plans & payment', 'প্ল্যান ও পেমেন্ট');
  String get payBkash => _e('bKash', 'বিকাশ');
  String get payNagad => _e('Nagad', 'নগদ');
  String get payCard => _e('Card', 'কার্ড');
  String get invoices => _e('Invoice history', 'ইনভয়েস ইতিহাস');
  String get noInvoices => _e(
        'No invoices yet. After payment, PDFs appear here.',
        'এখনো ইনভয়েস নেই। পেমেন্টের পর পিডিএফ এখানে দেখাবে।',
      );

  // Notifications
  String get notificationsTitle => _e('Inbox', 'ইনবক্স');
  String get noNotifications => _e(
        'No notifications. Delays and offers will appear here.',
        'কোনো নোটিফিকেশন নেই। দেরি ও অফার এখানে আসবে।',
      );

  // Profile
  String get profileTitle => _e('Profile', 'প্রোফাইল');
  String get language => _e('Language', 'ভাষা');
  String get biometric => _e('Biometric login', 'বায়োমেট্রিক লগইন');
  String get savedRoutes => _e('Saved routes', 'সংরক্ষিত রুট');
  String get feedback => _e('Feedback', 'মতামত');
  String get supportChat => _e('Support chat', 'সাপোর্ট চ্যাট');
  String get driverConsole => _e('Driver console', 'ড্রাইভার কনসোল');
  String get signOut => _e('Sign out', 'সাইন আউট');

  // Feedback modal
  String get feedbackTitle => _e('Send feedback', 'মতামত পাঠান');
  String get category => _e('Category', 'ধরন');
  String get bug => _e('Bug', 'বাগ');
  String get suggestion => _e('Suggestion', 'পরামর্শ');
  String get complaint => _e('Complaint', 'অভিযোগ');
  String get describe => _e('Describe', 'বিবরণ');
  String get addPhoto => _e('Add photo', 'ছবি যোগ করুন');
  String get submit => _e('Submit', 'জমা দিন');

  // Driver
  String get driverTitle => _e('Driver companion', 'ড্রাইভার মোড');
  String get startTrip => _e('Start trip', 'ট্রিপ শুরু');
  String get stopTrip => _e('Stop trip', 'ট্রিপ বন্ধ');
  String get tripStatus => _e('Trip status', 'ট্রিপ স্ট্যাটাস');
}
