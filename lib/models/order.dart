// order.dart — CORRIGÉ
import 'package:uuid/uuid.dart';
import 'order_item.dart';

enum OrderStatus { created, inProgress, completed, validated }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.created:
        return 'Créée';
      case OrderStatus.inProgress:
        return 'En cours';
      case OrderStatus.completed:
        return 'Complète';
      case OrderStatus.validated:
        return 'Validée';
    }
  }

  static OrderStatus fromString(String s) {
    try {
      return OrderStatus.values
          .firstWhere((e) => e.toString() == 'OrderStatus.$s');
    } catch (_) {
      return OrderStatus.created;
    }
  }
}

class Order {
  final String id;
  final String name;
  final String clientName;
  double? totalCost;
  OrderStatus status;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    String? id,
    required this.name,
    required this.clientName,
    this.totalCost,
    this.status = OrderStatus.created,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.items,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // ─── Comptages ────────────────────────────────────────────────────────────

  /// Nombre total d'unités à préparer, en comptant chaque genre séparément.
  /// Une paire (les2) avec qty=2 = 4 unités (2 mâles + 2 femelles).
  int get totalUnitsCount {
    int total = 0;
    for (final item in items) {
      switch (item.gender) {
        case OrderItemGender.les2:
          total += item.quantity * 2;
          break;
        case OrderItemGender.male:
        case OrderItemGender.femelle:
        case OrderItemGender.indefini:
          total += item.quantity;
          break;
      }
    }
    return total;
  }

  /// Nombre total de dinos (quantité brute, sans doubler les paires).
  /// Utilisé pour l'affichage "X dinos".
  int get totalDinosCount {
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }

  /// Nombre d'unités validées, en lisant maleValidatedCount/femaleValidatedCount.
  int get totalValidatedCount {
    int validated = 0;
    for (final item in items) {
      final v = item.validation;
      if (v == null) continue;
      switch (item.gender) {
        case OrderItemGender.les2:
          validated += (v.maleValidatedCount + v.femaleValidatedCount)
              .clamp(0, item.quantity * 2);
          break;
        case OrderItemGender.male:
          validated += v.maleValidatedCount.clamp(0, item.quantity);
          break;
        case OrderItemGender.femelle:
          validated += v.femaleValidatedCount.clamp(0, item.quantity);
          break;
        case OrderItemGender.indefini:
          validated += v.totalValidated.clamp(0, item.quantity);
          break;
      }
    }
    return validated;
  }

  /// Taux de progression réel (0.0 à 1.0) — SANS minimum artificiel.
  double get progressionRatio {
    final total = totalUnitsCount;
    if (total == 0) return 0.0;
    return (totalValidatedCount / total).clamp(0.0, 1.0);
  }

  /// Coût total calculé ou renseigné
  double get computedTotalCost {
    if (totalCost != null && totalCost! > 0) return totalCost!;
    return items.fold<double>(
        0.0, (sum, item) => sum + (item.itemTotal ?? 0.0));
  }

  /// Résumé textuel du contenu : "3 paires · 1 ♂ · 2 ♀"
  String get contentSummary {
    int pairs = 0, males = 0, females = 0, indef = 0;
    for (final item in items) {
      switch (item.gender) {
        case OrderItemGender.les2:
          pairs += item.quantity;
          break;
        case OrderItemGender.male:
          males += item.quantity;
          break;
        case OrderItemGender.femelle:
          females += item.quantity;
          break;
        case OrderItemGender.indefini:
          indef += item.quantity;
          break;
      }
    }
    final parts = <String>[];
    if (pairs > 0) parts.add('$pairs paire${pairs > 1 ? 's' : ''}');
    if (males > 0) parts.add('$males ♂');
    if (females > 0) parts.add('$females ♀');
    if (indef > 0) parts.add('$indef ?');
    return parts.isEmpty ? '—' : parts.join('  ·  ');
  }

  /// Mise à jour automatique du statut
  void updateStatusBasedOnProgress() {
    if (status == OrderStatus.validated) return;
    if (totalValidatedCount == 0) {
      status = OrderStatus.created;
    } else if (totalValidatedCount < totalUnitsCount) {
      status = OrderStatus.inProgress;
    } else {
      status = OrderStatus.completed;
    }
  }

  Order copyWith({
    String? id,
    String? name,
    String? clientName,
    double? totalCost,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<OrderItem>? items,
  }) {
    return Order(
      id: id ?? this.id,
      name: name ?? this.name,
      clientName: clientName ?? this.clientName,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'totalCost': totalCost,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      totalCost: (map['totalCost'] as num?)?.toDouble(),
      status: OrderStatusExt.fromString(
        (map['status'] as String?)?.split('.').last ?? 'created',
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      items: ((map['items'] as List?)?.cast<Map<String, dynamic>>() ?? [])
          .map((itemMap) => OrderItem.fromMap(itemMap))
          .toList(),
    );
  }

  @override
  String toString() =>
      'Order(id: $id, name: $name, items: ${items.length}, status: ${status.label})';
}
