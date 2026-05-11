// lib/providers/language_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_locale';

  // Langues supportées : code → label + drapeau
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'fr', 'label': 'Français',  'flag': '🇫🇷'},
    {'code': 'en', 'label': 'English',   'flag': '🇬🇧'},
    {'code': 'de', 'label': 'Deutsch',   'flag': '🇩🇪'},
  ];

  static const List<String> supportedCodes =
      ['fr', 'en', 'de'];

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get currentCode => _locale.languageCode;

  Map<String, String> get currentLanguageInfo {
    return supportedLanguages.firstWhere(
      (l) => l['code'] == currentCode,
      orElse: () => supportedLanguages[1], // English par défaut
    );
  }

  /// Initialise la locale : charge la préférence sauvegardée,
  /// ou détecte la langue du device au premier lancement.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved != null && supportedCodes.contains(saved)) {
      _locale = Locale(saved);
    } else {
      // Premier lancement : tenter la détection de la langue du device
      final detected = _detectDeviceLocale();
      _locale = Locale(detected);
      // Sauvegarder pour les prochains lancements
      await prefs.setString(_prefKey, detected);
    }
    notifyListeners();
  }

  /// Détecte la langue du device et retourne son code si elle est supportée,
  /// sinon retourne 'en' (anglais par défaut).
  String _detectDeviceLocale() {
    try {
      // Platform.localeName retourne p.ex. "fr_FR", "en_US", "de_DE"
      final raw = Platform.localeName; // ex: "fr_FR"
      if (raw.length >= 2) {
        final code = raw.substring(0, 2).toLowerCase();
        if (supportedCodes.contains(code)) {
          return code;
        }
      }
    } catch (_) {
      // Web ou erreur → anglais par défaut
    }
    return 'en';
  }

  /// Change la langue et sauvegarde la préférence.
  Future<void> setLocale(String languageCode) async {
    if (!supportedCodes.contains(languageCode)) return;
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, languageCode);
  }

  /// Retourne true si le code de langue est celui actuellement sélectionné.
  bool isActive(String code) => _locale.languageCode == code;
}
