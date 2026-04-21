import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/prefs_keys.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _load();
  }

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isBangla => _locale.languageCode == 'bn';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(PrefsKeys.locale);
    if (code == 'bn') {
      _locale = const Locale('bn');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'bn') return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefsKeys.locale, locale.languageCode);
  }

  Future<void> toggleBangla() async {
    await setLocale(isBangla ? const Locale('en') : const Locale('bn'));
  }
}
