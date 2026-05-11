// lib/providers/gemini_provider.dart
//
// Gère la clé API Gemini et le mode OCR actif (Gemini ou local).
// La clé est persistée dans SharedPreferences.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/gemini_ocr_service.dart';

class GeminiProvider extends ChangeNotifier {
  static const String _keyApiKey  = 'gemini_api_key';
  static const String _keyEnabled = 'gemini_ocr_enabled';

  String _apiKey  = '';
  bool   _enabled = false;
  bool   _validating = false;
  String? _validationError;

  String  get apiKey          => _apiKey;
  bool    get isEnabled       => _enabled && _apiKey.isNotEmpty;
  bool    get hasKey          => _apiKey.isNotEmpty;
  bool    get isValidating    => _validating;
  String? get validationError => _validationError;

  // Masquer la clé dans l'UI (affiche AIza...xxxx)
  String get maskedKey {
    if (_apiKey.length <= 8) return '•' * _apiKey.length;
    return '${_apiKey.substring(0, 4)}...${_apiKey.substring(_apiKey.length - 4)}';
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey  = prefs.getString(_keyApiKey)  ?? '';
    _enabled = prefs.getBool(_keyEnabled)   ?? false;
    notifyListeners();
  }

  // ── Sauvegarder et valider la clé ─────────────────────────────────────────
  Future<bool> setApiKey(String key) async {
    final trimmed = key.trim();
    _validating = true;
    _validationError = null;
    notifyListeners();

    // Validation basique du format
    if (trimmed.isNotEmpty && !trimmed.startsWith('AIza')) {
      _validating = false;
      _validationError = 'Format invalide. La clé doit commencer par "AIza"';
      notifyListeners();
      return false;
    }

    // Test de connectivité si clé non vide
    if (trimmed.isNotEmpty) {
      final isValid = await GeminiOcrService.validateApiKey(trimmed);
      if (!isValid) {
        _validating = false;
        _validationError = 'Clé invalide ou sans accès à l\'API Gemini';
        notifyListeners();
        return false;
      }
    }

    _apiKey  = trimmed;
    _enabled = trimmed.isNotEmpty; // Active auto si clé valide
    _validating = false;
    _validationError = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiKey,  _apiKey);
    await prefs.setBool(_keyEnabled,   _enabled);
    notifyListeners();
    return true;
  }

  Future<void> setEnabled(bool value) async {
    if (!hasKey && value) return; // Pas de clé → impossible d'activer
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, _enabled);
    notifyListeners();
  }

  Future<void> clearApiKey() async {
    _apiKey  = '';
    _enabled = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyApiKey);
    await prefs.setBool(_keyEnabled, false);
    notifyListeners();
  }

  /// Retourne une instance GeminiOcrService si activée, null sinon
  GeminiOcrService? get service {
    if (!isEnabled) return null;
    return GeminiOcrService(_apiKey);
  }
}
