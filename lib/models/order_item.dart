import 'package:uuid/uuid.dart';

enum OrderItemType { oeuf, bebe, adulte }

enum OrderItemGender { male, femelle, les2, indefini }

extension OrderItemTypeExt on OrderItemType {
  String get label {
    switch (this) {
      case OrderItemType.oeuf:
        return 'Œuf/Embryon';
      case OrderItemType.bebe:
        return 'Bébé';
      case OrderItemType.adulte:
        return 'Adulte/Clone';
    }
  }

  static OrderItemType fromString(String s) {
    try {
      return OrderItemType.values
          .firstWhere((e) => e.toString() == 'OrderItemType.$s');
    } catch (_) {
      return OrderItemType.bebe;
    }
  }
}

extension OrderItemGenderExt on OrderItemGender {
  String get label {
    switch (this) {
      case OrderItemGender.male:
        return 'Mâle';
      case OrderItemGender.femelle:
        return 'Femelle';
      case OrderItemGender.les2:
        return 'Paire';
      case OrderItemGender.indefini:
        return 'Indéfini';
    }
  }

  String get emoji {
    switch (this) {
      case OrderItemGender.male:
        return '♂️';
      case OrderItemGender.femelle:
        return '♀️';
      case OrderItemGender.les2:
        return '♂️♀️';
      case OrderItemGender.indefini:
        return '?';
    }
  }

  static OrderItemGender fromString(String s) {
    try {
      return OrderItemGender.values
          .firstWhere((e) => e.toString() == 'OrderItemGender.$s');
    } catch (_) {
      return OrderItemGender.les2;
    }
  }
}

class OrderItemValidation {
  final List<bool> validationStates;
  int maleValidatedCount;
  int femaleValidatedCount;

  OrderItemValidation({
    required int quantity,
    this.maleValidatedCount = 0,
    this.femaleValidatedCount = 0,
  }) : validationStates = List<bool>.filled(quantity, false);

  int get totalValidated {
    return validationStates.where((v) => v).length;
  }

  double get validationRatio {
    final total = validationStates.length;
    if (total == 0) return 0.0;
    return totalValidated / total;
  }

  void toggleAt(int index) {
    if (index >= 0 && index < validationStates.length) {
      validationStates[index] = !validationStates[index];
    }
  }

  void validateCount(int count) {
    for (int i = 0; i < count && i < validationStates.length; i++) {
      if (!validationStates[i]) {
        validationStates[i] = true;
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'validationStates': validationStates,
      'maleValidatedCount': maleValidatedCount,
      'femaleValidatedCount': femaleValidatedCount,
    };
  }

  factory OrderItemValidation.fromMap(
      Map<String, dynamic> map, int quantity) {
    final validation = OrderItemValidation(quantity: quantity);
    final states = (map['validationStates'] as List?)?.cast<bool>() ?? [];
    for (int i = 0;
        i < states.length && i < validation.validationStates.length;
        i++) {
      validation.validationStates[i] = states[i];
    }
    validation.maleValidatedCount = map['maleValidatedCount'] ?? 0;
    validation.femaleValidatedCount = map['femaleValidatedCount'] ?? 0;
    return validation;
  }
}

class OrderItem {
  final String id;
  final int dinoId;
  final String dinoName;
  final String dinoSpecies;
  final List<String> dinoColors;

  int quantity;
  OrderItemType type;
  OrderItemGender gender;
  double? unitPrice;
  OrderItemValidation? validation; // ✅ Mutable et nullable

  OrderItem({
    required this.id,
    required this.dinoId,
    required this.dinoName,
    required this.dinoSpecies,
    required this.dinoColors,
    required this.quantity,
    required this.type,
    required this.gender,
    this.unitPrice,
    this.validation,
  }) {
    // Initialiser validation si null
    this.validation ??= OrderItemValidation(quantity: quantity);
  }

  double? get itemTotal =>
      unitPrice != null ? unitPrice! * quantity : null;

  int get validatedCount => validation?.totalValidated ?? 0;

  double get validationRatio => validation?.validationRatio ?? 0.0;

  OrderItem copyWith({
    String? id,
    int? dinoId,
    String? dinoName,
    String? dinoSpecies,
    List<String>? dinoColors,
    int? quantity,
    OrderItemType? type,
    OrderItemGender? gender,
    double? unitPrice,
    OrderItemValidation? validation,
  }) {
    return OrderItem(
      id: id ?? this.id,
      dinoId: dinoId ?? this.dinoId,
      dinoName: dinoName ?? this.dinoName,
      dinoSpecies: dinoSpecies ?? this.dinoSpecies,
      dinoColors: dinoColors ?? this.dinoColors,
      quantity: quantity ?? this.quantity,
      type: type ?? this.type,
      gender: gender ?? this.gender,
      unitPrice: unitPrice ?? this.unitPrice,
      validation: validation ?? this.validation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dinoId': dinoId,
      'dinoName': dinoName,
      'dinoSpecies': dinoSpecies,
      'dinoColors': dinoColors,
      'quantity': quantity,
      'type': type.toString(),
      'gender': gender.toString(),
      'unitPrice': unitPrice,
      'validation': validation?.toMap(),
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    final colors = (map['dinoColors'] as List?)?.cast<String>() ?? [];
    while (colors.length < 6) {
      colors.add('808080');
    }

    return OrderItem(
      id: map['id'] ?? const Uuid().v4(),
      dinoId: map['dinoId'] ?? 0,
      dinoName: map['dinoName'] ?? '',
      dinoSpecies: map['dinoSpecies'] ?? '',
      dinoColors: colors,
      quantity: map['quantity'] ?? 1,
      type: OrderItemTypeExt.fromString(
          (map['type'] as String?)?.split('.').last ?? 'bebe'),
      gender: OrderItemGenderExt.fromString(
          (map['gender'] as String?)?.split('.').last ?? 'les2'),
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
      validation: map['validation'] != null
          ? OrderItemValidation.fromMap(map['validation'], map['quantity'] ?? 1)
          : null,
    );
  }
}
