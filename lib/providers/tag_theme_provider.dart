import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TagThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'tag_colors';

  // tag → couleur hex string (ex: 'Boss' → '#FF4444')
  Map<String, String> _tagColors = {};

  Map<String, String> get tagColors => Map.unmodifiable(_tagColors);

  TagThemeProvider() {
    _load();
  }

  /// Retourne la couleur d'un tag, ou null si non définie
  Color? colorForTag(String tag) {
    final hex = _tagColors[tag];
    if (hex == null) return null;
    return _hexToColor(hex);
  }

  /// Retourne la couleur hex d'un tag, ou null si non définie
  String? hexForTag(String tag) => _tagColors[tag];

  /// Définit la couleur d'un tag et sauvegarde
  Future<void> setTagColor(String tag, String hex) async {
    _tagColors[tag] = hex;
    notifyListeners();
    await _save();
  }

  /// Supprime la couleur personnalisée d'un tag (retour au défaut)
  Future<void> removeTagColor(String tag) async {
    _tagColors.remove(tag);
    notifyListeners();
    await _save();
  }

  /// Réinitialise tous les tags
  Future<void> resetAll() async {
    _tagColors = {};
    notifyListeners();
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _tagColors = decoded.map((k, v) => MapEntry(k, v as String));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_tagColors));
  }

  static Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}
