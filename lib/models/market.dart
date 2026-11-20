// market.dart — Modèles Market (shops + listings cryopod)
import 'package:uuid/uuid.dart';

/// Type de dino mis en vente (aligné sur les usages ARK / commandes).
enum ListingType { aucun, oeuf, bebe, clone, adulte }

extension ListingTypeExt on ListingType {
  String get label {
    switch (this) {
      case ListingType.aucun:
        return 'Aucun';
      case ListingType.oeuf:
        return 'Œuf';
      case ListingType.bebe:
        return 'Bébé';
      case ListingType.clone:
        return 'Clone';
      case ListingType.adulte:
        return 'Adulte';
    }
  }

  static ListingType fromString(String s) {
    try {
      return ListingType.values
          .firstWhere((e) => e.toString() == 'ListingType.$s');
    } catch (_) {
      return ListingType.adulte;
    }
  }

  /// Durée du timer cryo par défaut selon le type.
  /// Modifie les valeurs ici pour ajuster les délais.
  static int defaultDurationDaysFor(ListingType t) {
    switch (t) {
      case ListingType.oeuf:
        return 8; // œufs : timer plus court
      case ListingType.bebe:
      case ListingType.clone:
      case ListingType.adulte:
        return 30;
      case ListingType.aucun:
        return 30;
    }
  }
}

enum ListingSexe { male, femelle, indefini }

extension ListingSexeExt on ListingSexe {
  String get label {
    switch (this) {
      case ListingSexe.male:
        return 'Mâle';
      case ListingSexe.femelle:
        return 'Femelle';
      case ListingSexe.indefini:
        return '—';
    }
  }

  static ListingSexe fromString(String s) {
    try {
      return ListingSexe.values
          .firstWhere((e) => e.toString() == 'ListingSexe.$s');
    } catch (_) {
      return ListingSexe.indefini;
    }
  }
}

enum ListingStatus { active, vendu }

extension ListingStatusExt on ListingStatus {
  static ListingStatus fromString(String s) {
    try {
      return ListingStatus.values
          .firstWhere((e) => e.toString() == 'ListingStatus.$s');
    } catch (_) {
      return ListingStatus.active;
    }
  }
}

/// Un shop du market Bob's Tall Tales (vente contre hexagones).
class MarketShop {
  final String id;
  String name;
  /// Couleur d'accent du shop (stockée en int 0xAARRGGBB).
  int colorValue;
  /// Prix par défaut en hexagones pour les nouveaux items.
  double defaultPrice;
  /// Type proposé par défaut sur ce shop (œufs only, mâles only…).
  ListingType defaultType;
  ListingSexe defaultSexe;
  final DateTime createdAt;

  MarketShop({
    String? id,
    required this.name,
    this.colorValue = 0xFFFF6B00,
    this.defaultPrice = 100,
    this.defaultType = ListingType.adulte,
    this.defaultSexe = ListingSexe.indefini,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'defaultPrice': defaultPrice,
        'defaultType': defaultType.toString().split('.').last,
        'defaultSexe': defaultSexe.toString().split('.').last,
        'createdAt': createdAt.toIso8601String(),
      };

  factory MarketShop.fromMap(Map<String, dynamic> map) => MarketShop(
        id: map['id'] as String? ?? const Uuid().v4(),
        name: map['name'] as String? ?? 'Shop',
        colorValue: map['colorValue'] as int? ?? 0xFFFF6B00,
        defaultPrice: (map['defaultPrice'] as num?)?.toDouble() ?? 100,
        defaultType: ListingTypeExt.fromString(
            map['defaultType'] as String? ?? 'adulte'),
        defaultSexe: ListingSexeExt.fromString(
            map['defaultSexe'] as String? ?? 'indefini'),
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Un dino (cryopod) déposé dans un shop.
/// Le décompte est basé sur la DATE DE L'APPAREIL : deadline stockée,
/// recalculée à chaque affichage → survit à la fermeture de l'app.
class MarketListing {
  final String id;
  final String shopId;
  String espece;
  /// Nom custom optionnel (ex. lignée).
  String nom;
  ListingType type;
  ListingSexe sexe;
  /// Prix unitaire en hexagones.
  double price;
  /// Date de dépôt dans le shop.
  DateTime listedAt;
  /// Date de péremption de la cryo (= listedAt + 30 j, modifiable).
  DateTime deadline;
  ListingStatus status;
  /// Date du dernier marquage "vendu" (statistique).
  DateTime? soldAt;
  /// Nombre de ventes cumulées si remis en vente plusieurs fois.
  int timesSold;

  static const int defaultDurationDays = 30;

  MarketListing({
    String? id,
    required this.shopId,
    required this.espece,
    this.nom = '',
    required this.type,
    this.sexe = ListingSexe.indefini,
    required this.price,
    DateTime? listedAt,
    DateTime? deadline,
    this.status = ListingStatus.active,
    this.soldAt,
    this.timesSold = 0,
  })  : id = id ?? const Uuid().v4(),
        listedAt = listedAt ?? DateTime.now(),
        deadline = deadline ??
            DateTime.now().add(const Duration(days: defaultDurationDays));

  /// Jours restants avant dépop (base date seule, indépendant de l'heure).
  /// Négatif = déjà expiré.
  int remainingDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(deadline.year, deadline.month, deadline.day);
    return end.difference(today).inDays;
  }

  /// Alerte cryo : ≤ 4 jours restants.
  bool isExpiringSoon(DateTime now) =>
      status == ListingStatus.active && remainingDays(now) <= 4;

  /// Remise en vente : nouveau cycle complet selon le type.
  void relist({DateTime? now}) {
    final n = now ?? DateTime.now();
    final days = ListingTypeExt.defaultDurationDaysFor(type);
    listedAt = n;
    deadline = n.add(Duration(days: days));
    status = ListingStatus.active;
    soldAt = null;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'shopId': shopId,
        'espece': espece,
        'nom': nom,
        'type': type.toString().split('.').last,
        'sexe': sexe.toString().split('.').last,
        'price': price,
        'listedAt': listedAt.toIso8601String(),
        'deadline': deadline.toIso8601String(),
        'status': status.toString().split('.').last,
        'soldAt': soldAt?.toIso8601String(),
        'timesSold': timesSold,
      };

  factory MarketListing.fromMap(Map<String, dynamic> map) => MarketListing(
        id: map['id'] as String? ?? const Uuid().v4(),
        shopId: map['shopId'] as String? ?? '',
        espece: map['espece'] as String? ?? 'Rex',
        nom: map['nom'] as String? ?? '',
        type: ListingTypeExt.fromString(map['type'] as String? ?? 'adulte'),
        sexe: ListingSexeExt.fromString(map['sexe'] as String? ?? 'indefini'),
        price: (map['price'] as num?)?.toDouble() ?? 0,
        listedAt: map['listedAt'] != null
            ? DateTime.tryParse(map['listedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        deadline: map['deadline'] != null
            ? DateTime.tryParse(map['deadline'] as String) ??
                DateTime.now().add(const Duration(days: 30))
            : DateTime.now().add(const Duration(days: 30)),
        status:
            ListingStatusExt.fromString(map['status'] as String? ?? 'active'),
        soldAt: map['soldAt'] != null
            ? DateTime.tryParse(map['soldAt'] as String)
            : null,
        timesSold: map['timesSold'] as int? ?? 0,
      );
}
