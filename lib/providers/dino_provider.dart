import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/dino.dart';

class DinoProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Dino> _dinos = [];
  List<Dino> _filteredDinos = [];
  bool _isLoading = false;
  String? _error;

  // Tags personnalisés (chargés depuis SharedPreferences)
  List<String> _customTags = [];

  // Filtres actifs
  String _searchQuery = '';
  String _filterEspece = '';
  String _filterSexe = '';
  String _filterRole = '';
  String _filterTag = '';

  // Getters
  List<Dino> get dinos => _filteredDinos;
  List<Dino> get allDinos => _dinos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get filterEspece => _filterEspece;
  String get filterSexe => _filterSexe;
  String get filterRole => _filterRole;
  String get filterTag => _filterTag;
  int get dinoCount => _dinos.length;

  // Tous les tags disponibles = défaut + personnalisés
  List<String> get allTags => [
        ...Dino.tagsParDefaut,
        ..._customTags.where((t) => !Dino.tagsParDefaut.contains(t)),
      ];

  bool get hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _filterEspece.isNotEmpty ||
      _filterSexe.isNotEmpty ||
      _filterRole.isNotEmpty ||
      _filterTag.isNotEmpty;

  Future<void> loadDinos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadCustomTags();
      _dinos = await _db.getAllDinos();
      _applyFilters();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> replaceAllData({
    required List<Dino> dinos,
    required List<String> customTags,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Nettoyer les tags custom :
      // - trim
      // - supprimer vides
      // - retirer ceux déjà présents dans tagsParDefaut
      // - unicité
      final cleanCustomTags = customTags
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !Dino.tagsParDefaut.contains(e))
          .toSet()
          .toList()
        ..sort();

      // Sauvegarde des tags custom
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('custom_tags', cleanCustomTags);

      // Remplacement complet en base
      await _db.replaceAllDinos(dinos);

      // Rechargement depuis les sources réelles
      _customTags = cleanCustomTags;
      _dinos = await _db.getAllDinos();

      _applyFilters();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCustomTags() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customTags = prefs.getStringList('custom_tags') ?? [];
    } catch (_) {}
  }

  Future<void> addCustomTag(String tag) async {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    if (allTags.contains(trimmed)) return;

    _customTags.add(trimmed);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('custom_tags', _customTags);
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> addDino(Dino dino) async {
    try {
      final id = await _db.insertDino(dino);
      final newDino = dino.copyWith(id: id);
      _dinos.insert(0, newDino);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDino(Dino dino) async {
    try {
      await _db.updateDino(dino);
      final index = _dinos.indexWhere((d) => d.id == dino.id);
      if (index != -1) {
        _dinos[index] = dino;
        _applyFilters();
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteDino(int id) async {
    try {
      await _db.deleteDino(id);
      _dinos.removeWhere((d) => d.id == id);
      _applyFilters();
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setFilterEspece(String espece) {
    _filterEspece = espece;
    _applyFilters();
    notifyListeners();
  }

  void setFilterSexe(String sexe) {
    _filterSexe = sexe;
    _applyFilters();
    notifyListeners();
  }

  void setFilterRole(String role) {
    _filterRole = role;
    _applyFilters();
    notifyListeners();
  }

  void setFilterTag(String tag) {
    _filterTag = tag;
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _filterEspece = '';
    _filterSexe = '';
    _filterRole = '';
    _filterTag = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredDinos = _dinos.where((dino) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!dino.nom.toLowerCase().contains(q) &&
            !dino.espece.toLowerCase().contains(q)) {
          return false;
        }
      }

      if (_filterEspece.isNotEmpty && dino.espece != _filterEspece) {
        return false;
      }

      if (_filterSexe.isNotEmpty && dino.sexe != _filterSexe) {
        return false;
      }

      if (_filterRole.isNotEmpty && dino.role != _filterRole) {
        return false;
      }

      if (_filterTag.isNotEmpty && !dino.tags.contains(_filterTag)) {
        return false;
      }

      return true;
    }).toList();
  }

  // Stats globales
  Map<String, int> getRoleStats() {
    final stats = <String, int>{};
    for (final dino in _dinos) {
      stats[dino.role] = (stats[dino.role] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> getEspeceStats() {
    final stats = <String, int>{};
    for (final dino in _dinos) {
      stats[dino.espece] = (stats[dino.espece] ?? 0) + 1;
    }
    return stats;
  }
}
