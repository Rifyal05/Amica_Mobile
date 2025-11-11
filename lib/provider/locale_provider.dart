import 'package:flutter/material.dart';

class L10n {
  static final all = [
    const Locale('en'),
    const Locale('id'),
  ];
}

class LocaleProvider with ChangeNotifier {
  Locale _locale = const Locale('id');

  Locale get locale => _locale;

  void setLocale(Locale newLocale) {
    if (!L10n.all.contains(newLocale)) return;

    _locale = newLocale;
    notifyListeners();
  }
}