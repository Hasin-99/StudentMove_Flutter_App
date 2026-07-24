/// Local AI assistant for Dhaka student transport (offline-capable fallback).
class AiAssistantService {
  AiAssistantService._();

  static final List<({String role, String text})> _history = [];

  static List<({String role, String text})> get history =>
      List.unmodifiable(_history);

  static void clear() => _history.clear();

  static String reply(String userText) {
    final q = userText.trim();
    if (q.isEmpty) return 'Ask me about routes, fares, schedules, or passes.';

    _history.add((role: 'user', text: q));
    final lower = q.toLowerCase();
    late final String answer;

    if (_matches(lower, const ['hi', 'hello', 'hey', 'salam', 'assalam'])) {
      answer =
          'Hey! I am your StudentMove assistant for Dhaka. Ask about live buses, routes, bookings, or student passes.';
    } else if (_matches(lower, const ['fare', 'price', 'cost', 'টাকা', 'ভাড়া'])) {
      answer =
          'Single rides are about ৳25–৳35. Student passes: Weekly ৳350, Monthly ৳1200, Single Ride ৳30. Open Plans to subscribe.';
    } else if (_matches(lower, const ['schedule', 'time', 'timing', 'next bus', 'arrival'])) {
      answer =
          'Open Live map / Next Bus Arrival for day tabs (Sat–Thu), ETA, and GPS status. Pull to refresh for the latest schedule.';
    } else if (_matches(lower, const ['route', 'uttara', 'mirpur', 'dhanmondi', 'dsc', 'diu', 'buet'])) {
      answer =
          'Popular routes: Uttara→DSC, Mirpur→DIU, Dhanmondi→BUET, Farmgate→DSC. Use Routes to plan, save favorites, or book seats.';
    } else if (_matches(lower, const ['pass', 'subscription', 'plan', 'weekly', 'monthly'])) {
      answer =
          'Student passes: Weekly (7 days, ৳350), Monthly (30 days, ৳1200), Single Ride (৳30). Pay with bKash/Nagad/Rocket or card (demo checkout in-app).';
    } else if (_matches(lower, const ['book', 'seat', 'booking', 'cancel'])) {
      answer =
          'Go to Book / Routes, pick a trip, choose up to 4 seats and a preference (any/window/aisle). You get a code like SMXXXXXXXX. Cancel from My bookings while status is confirmed.';
    } else if (_matches(lower, const ['delay', 'late', 'gps', 'track', 'live'])) {
      answer =
          'Live Track shows bus markers with GPS freshness (live / stale / waiting). Drivers broadcast location from the Driver Console; delays notify booked riders.';
    } else if (_matches(lower, const ['help', 'support', 'feedback'])) {
      answer =
          'Switch to the Support tab to message the team, or submit Feedback from Profile. We reply in your notification inbox.';
    } else {
      answer =
          'I can help with Dhaka campus routes, next-bus ETAs, seat booking, and student passes. Try: “How much is the monthly pass?” or “Uttara to DSC schedule”.';
    }

    _history.add((role: 'assistant', text: answer));
    return answer;
  }

  static bool _matches(String lower, List<String> keys) {
    for (final k in keys) {
      if (lower.contains(k)) return true;
    }
    return false;
  }
}
