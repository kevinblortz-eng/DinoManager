// market_provider.dart — État + persistance du Market (shops & listings).
// Persistance SharedPreferences JSON (même pattern que OrderProvider) :
// les deadlines sont des dates stockées → décompte recalculé à chaque
// ouverture via la date de l'appareil, rien ne se "perd" app fermée.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/market.dart';
import '../models/dino.dart';

/// Projection minimale d'un dino de la bibliothèque pour le market.
class DinoLite {
  final String espece;
  final String nom;
  final ListingSexe sexe;
  DinoLite({required this.espece, required this.nom, required this.sexe});

  factory DinoLite.fromDino(Dino d) => DinoLite(
        espece: d.espece,
        nom: d.nom,
        sexe: d.sexe == 'Mâle'
            ? ListingSexe.male
            : d.sexe == 'Femelle'
                ? ListingSexe.femelle
                : ListingSexe.indefini,
      );
}

class MarketProvider extends ChangeNotifier {
  static const String _storageKey = 'market_data_v1';

  List<MarketShop> _shops = [];
  List<MarketListing> _listings = [];
  bool _isLoading = false;
  String? _error;

  List<MarketShop> get shops => _shops;
  List<MarketListing> get listings => _listings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ─────────────────────────────────────────────────────────────
  // Chargement / sauvegarde
  // ─────────────────────────────────────────────────────────────

  Future<void> loadMarket() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null && json.isNotEmpty) {
        final data = jsonDecode(json) as Map<String, dynamic>;
        _shops = ((data['shops'] as List?) ?? [])
            .map((e) => MarketShop.fromMap(Map<String, dynamic>.from(e)))
            .toList();
        _listings = ((data['listings'] as List?) ?? [])
            .map((e) => MarketListing.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        _shops = [];
        _listings = [];
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠️ MarketProvider.loadMarket: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode({
        'shops': _shops.map((s) => s.toMap()).toList(),
        'listings': _listings.map((l) => l.toMap()).toList(),
      }));
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('⚠️ MarketProvider._persist: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD Shops
  // ─────────────────────────────────────────────────────────────

  Future<void> addShop(MarketShop shop) async {
    _shops.add(shop);
    notifyListeners();
    await _persist();
  }

  Future<void> updateShop(MarketShop shop) async {
    final idx = _shops.indexWhere((s) => s.id == shop.id);
    if (idx == -1) return;
    _shops[idx] = shop;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteShop(String shopId) async {
    _shops.removeWhere((s) => s.id == shopId);
    _listings.removeWhere((l) => l.shopId == shopId);
    notifyListeners();
    await _persist();
  }

  MarketShop? shopById(String id) {
    try {
      return _shops.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CRUD Listings
  // ─────────────────────────────────────────────────────────────

  /// Ajoute [quantity] listings identiques (une cryo = un timer individuel).
  /// Le timer dépend du type (œuf 8 j, autres 30 j).
  Future<void> addListing(MarketListing listing, {int quantity = 1}) async {
    for (int i = 0; i < quantity.clamp(1, 99); i++) {
      final copy = listing.id == null || i == 0
          ? listing
          : _copyWithNewId(listing);
      if (i > 0) copy.relist();
      _listings.add(copy);
    }
    notifyListeners();
    await _persist();
  }

  /// Dépose des dinos de la bibliothèque : 1 listing par dino,
  /// sexe repris de la fiche, timer selon le type choisi.
  Future<void> addListingsFromDinos(
    String shopId,
    List<DinoLite> dinos, {
    required double price,
    required ListingType type,
  }) async {
    for (final d in dinos) {
      _listings.add(MarketListing(
        shopId: shopId,
        espece: d.espece,
        nom: d.nom,
        type: type,
        sexe: d.sexe,
        price: price,
      ));
    }
    notifyListeners();
    await _persist();
  }

  MarketListing _copyWithNewId(MarketListing l) => MarketListing(
        shopId: l.shopId,
        espece: l.espece,
        nom: l.nom,
        type: l.type,
        sexe: l.sexe,
        price: l.price,
        status: l.status,
      );

  Future<void> updateListing(MarketListing listing) async {
    final idx = _listings.indexWhere((l) => l.id == listing.id);
    if (idx == -1) return;
    _listings[idx] = listing;
    notifyListeners();
    await _persist();
  }

  Future<void> deleteListing(String listingId) async {
    _listings.removeWhere((l) => l.id == listingId);
    notifyListeners();
    await _persist();
  }

  /// Marque vendu (garde la trace, swipe gauche n°1).
  Future<void> markSold(String listingId) async {
    final idx = _listings.indexWhere((l) => l.id == listingId);
    if (idx == -1) return;
    _listings[idx].status = ListingStatus.vendu;
    _listings[idx].soldAt = DateTime.now();
    _listings[idx].timesSold += 1;
    notifyListeners();
    await _persist();
  }

  /// Remet en vente : nouveau cycle 30 j (swipe gauche n°2 sur un vendu).
  Future<void> relist(String listingId) async {
    final idx = _listings.indexWhere((l) => l.id == listingId);
    if (idx == -1) return;
    _listings[idx].relist();
    notifyListeners();
    await _persist();
  }

  // ─────────────────────────────────────────────────────────────
  // Agrégats pour l'UI
  // ─────────────────────────────────────────────────────────────

  List<MarketListing> activeListings(String shopId, {DateTime? now}) {
    final n = now ?? DateTime.now();
    return _listings
        .where((l) => l.shopId == shopId && l.status == ListingStatus.active)
        .toList()
      ..sort((a, b) => a.remainingDays(n).compareTo(b.remainingDays(n)));
  }

  List<MarketListing> soldListings(String shopId) => _listings
      .where((l) => l.shopId == shopId && l.status == ListingStatus.vendu)
      .toList();

  /// Délai mini restant sur un shop (null si aucun item actif).
  int? minRemainingDays(String shopId, {DateTime? now}) {
    final actives = activeListings(shopId, now: now);
    if (actives.isEmpty) return null;
    return actives.first.remainingDays(now ?? DateTime.now());
  }

  double shopTotalValue(String shopId) => activeListings(shopId)
      .fold<double>(0, (sum, l) => sum + l.price);

  /// Toutes les cryos en alerte (≤ 4 j) sur tous les shops.
  List<MarketListing> expiringSoon({DateTime? now}) {
    final n = now ?? DateTime.now();
    return _listings.where((l) => l.isExpiringSoon(n)).toList()
      ..sort((a, b) => a.remainingDays(n).compareTo(b.remainingDays(n)));
  }

  bool get hasExpiringItems => expiringSoon().isNotEmpty;
}
