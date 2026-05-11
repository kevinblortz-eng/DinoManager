import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/role_theme.dart';

class RoleThemeProvider extends ChangeNotifier {
  static const String _prefsKey = 'role_themes';

  // role → thème personnalisé (null = utilise le défaut)
  Map<String, RoleTheme> _customThemes = {};

  // roles supprimés des défauts par l'utilisateur
  Set<String> _deletedDefaults = {};

  RoleThemeProvider() {
    _load();
  }

  // Retourne le thème actif pour un rôle
  // (perso > défaut, sauf si supprimé)
  RoleTheme themeForRole(String role) {
    if (_customThemes.containsKey(role)) return _customThemes[role]!;
    if (_deletedDefaults.contains(role)) {
      // Retourne un thème neutre si le défaut a été supprimé
      return RoleTheme(
        role: role,
        background: const Color(0xFF111827),
        border: const Color(0xFF2D3748),
        text: const Color(0xFF6B7A8D),
      );
    }
    return RoleThemeDefaults.forRole(role);
  }

  // Tous les rôles visibles (défauts non supprimés + perso)
  List<String> get allRoles {
    final roles = <String>{};
    // Ajoute les défauts non supprimés
    for (final role in RoleThemeDefaults.defaults.keys) {
      if (!_deletedDefaults.contains(role)) roles.add(role);
    }
    // Ajoute les perso
    roles.addAll(_customThemes.keys);
    return roles.toList()..sort();
  }

  bool hasCustomTheme(String role) => _customThemes.containsKey(role);
  bool isDefaultDeleted(String role) => _deletedDefaults.contains(role);

  // Sauvegarde un thème perso
  Future<void> setTheme(String role, RoleTheme theme) async {
    _customThemes[role] = theme;
    _deletedDefaults.remove(role); // restaure si était supprimé
    notifyListeners();
    await _save();
  }

  // Supprime la personnalisation (retour au défaut)
  Future<void> resetToDefault(String role) async {
    _customThemes.remove(role);
    _deletedDefaults.remove(role);
    notifyListeners();
    await _save();
  }

  // Supprime complètement un thème (même le défaut)
  Future<void> deleteTheme(String role) async {
    _customThemes.remove(role);
    if (RoleThemeDefaults.defaults.containsKey(role)) {
      _deletedDefaults.add(role);
    }
    notifyListeners();
    await _save();
  }

  // Reset tout
  Future<void> resetAll() async {
    _customThemes = {};
    _deletedDefaults = {};
    notifyListeners();
    await _save();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final themes = decoded['themes'] as Map<String, dynamic>? ?? {};
        final deleted = decoded['deleted'] as List<dynamic>? ?? [];
        _customThemes = themes.map(
          (k, v) => MapEntry(k, RoleTheme.fromMap(v as Map<String, dynamic>)),
        );
        _deletedDefaults = Set<String>.from(deleted.cast<String>());
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'themes': _customThemes.map((k, v) => MapEntry(k, v.toMap())),
      'deleted': _deletedDefaults.toList(),
    };
    await prefs.setString(_prefsKey, jsonEncode(data));
  }
}
