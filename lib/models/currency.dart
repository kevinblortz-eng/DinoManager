class Currency {
  final String id;
  final String name;
  final String iconPath;
  final String symbol;
  final bool isCustom;

  Currency({
    required this.id,
    required this.name,
    required this.iconPath,
    this.symbol = '',
    this.isCustom = false,
  });

  Currency copyWith({
    String? id,
    String? name,
    String? iconPath,
    String? symbol,
    bool? isCustom,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      iconPath: iconPath ?? this.iconPath,
      symbol: symbol ?? this.symbol,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconPath': iconPath,
      'symbol': symbol,
      'isCustom': isCustom,
    };
  }

  factory Currency.fromMap(Map<String, dynamic> map) {
    return Currency(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      iconPath: map['iconPath'] ?? '',
      symbol: map['symbol'] ?? '',
      isCustom: map['isCustom'] ?? false,
    );
  }

  static List<Currency> getDefaults() {
    return [
      Currency(
        id: 'Hex',
        name: 'Hexagon',
        iconPath: 'assets/icons/currencies/Hex.png',
        symbol: '💠',
      ),
      Currency(
        id: 'poly',
        name: 'Poly',
        iconPath: 'assets/icons/currencies/poly.png',
        symbol: '🟦',
      ),
      Currency(
        id: 'ing',
        name: 'Ing',
        iconPath: 'assets/icons/currencies/ing.png',
        symbol: '🔲',
      ),
      Currency(
        id: 'crystal',
        name: 'Crystal',
        iconPath: 'assets/icons/currencies/crystal.png',
        symbol: '💎',
      ),
      Currency(
        id: 'dino',
        name: 'Dino',
        iconPath: 'assets/icons/currencies/dino.png',
        symbol: '🦖',
      ),
    ];
  }
}
