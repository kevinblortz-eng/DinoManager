// AUTO-GENERATED - Couleurs officielles ARK Survival Ascended
// Source: https://ark.wiki.gg/wiki/Color_IDs
// IDs 1-254 (officiels) + quelques spéciaux

import 'package:flutter/material.dart';

class ArkColor {
  final int id;
  final String name;
  final String hex;

  const ArkColor({required this.id, required this.name, required this.hex});

  Color get color {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  String toString() => 'ArkColor($id: $name, $hex)';
}

class ArkColorPalette {
  // Map complète id -> couleur ARK
  static const Map<int, ({String name, String hex})> _colors = {
    1: (name: 'Red', hex: '#FF0000'),
    2: (name: 'Blue', hex: '#0000FF'),
    3: (name: 'Green', hex: '#00FF00'),
    4: (name: 'Yellow', hex: '#FFFF00'),
    5: (name: 'Cyan', hex: '#00FFFF'),
    6: (name: 'Magenta', hex: '#FF00FF'),
    7: (name: 'Light Green', hex: '#C0FFBA'),
    8: (name: 'Light Grey', hex: '#C8CACA'),
    9: (name: 'Dino Dark Grey', hex: '#786759'),
    10: (name: 'Dino Light Orange', hex: '#FFB46C'),
    11: (name: 'Dino Light Yellow', hex: '#FFFA8A'),
    12: (name: 'Dino Light Red', hex: '#FF756C'),
    13: (name: 'Dino Dark Grey2', hex: '#7B7B7B'),
    14: (name: 'Dino Darker Grey', hex: '#3B3B3B'),
    15: (name: 'Dino Light Brown', hex: '#593A2A'),
    16: (name: 'Dino Dark Green', hex: '#224900'),
    17: (name: 'Dino Dark Red', hex: '#812118'),
    18: (name: 'White', hex: '#FFFFFF'),
    19: (name: 'Dino Light Pink', hex: '#FFA8A8'),
    20: (name: 'Dino Dark Maroon', hex: '#592B2B'),
    21: (name: 'Dino Light Orange2', hex: '#FFB694'),
    22: (name: 'Dino Dark Brown', hex: '#88532F'),
    23: (name: 'Dino Cream', hex: '#CACAA0'),
    24: (name: 'Dino Light Yellow2', hex: '#94946C'),
    25: (name: 'Dino Light Green', hex: '#E0FFE0'),
    26: (name: 'Dino Forest Green', hex: '#799479'),
    27: (name: 'Dino Dark Green2', hex: '#224122'),
    28: (name: 'Dino Light Blue', hex: '#D9E0FF'),
    29: (name: 'Dino Dark Blue', hex: '#394263'),
    30: (name: 'Dino Light Purple', hex: '#E4D9FF'),
    31: (name: 'Dino Dark Purple', hex: '#403459'),
    32: (name: 'Dino Cream2', hex: '#FFE0BA'),
    33: (name: 'Dino Tan', hex: '#948575'),
    34: (name: 'Dino Dark Tan', hex: '#594E41'),
    35: (name: 'Dino Darker Grey', hex: '#595959'),
    36: (name: 'Dino White', hex: '#FFFFFF'),
    37: (name: 'Dino Peach', hex: '#B79683'),
    38: (name: 'Dino Skin Tan', hex: '#EADAD5'),
    39: (name: 'Dino Skin Brown', hex: '#D0A794'),
    40: (name: 'Dino Light Tan', hex: '#C3B39F'),
    41: (name: 'Dino Mid Tan', hex: '#887666'),
    42: (name: 'Dino Orange Brown', hex: '#A0664B'),
    43: (name: 'Dino Deep Orange', hex: '#CB7956'),
    44: (name: 'Dino Burnt Orange', hex: '#BC4F00'),
    45: (name: 'Dino Olive Green', hex: '#79846C'),
    46: (name: 'Dino Moss Green', hex: '#909C79'),
    47: (name: 'Dino Sage', hex: '#A5A48B'),
    48: (name: 'Dino Slate Blue', hex: '#74939C'),
    49: (name: 'Dino Mauve', hex: '#787496'),
    50: (name: 'Dino Light Mauve', hex: '#B0A2C0'),
    51: (name: 'Dino Slate', hex: '#6281A7'),
    52: (name: 'Dino Dark Slate', hex: '#485C75'),
    53: (name: 'Dino Blue', hex: '#5FA4EA'),
    54: (name: 'Dino Deep Blue', hex: '#4568D4'),
    55: (name: 'Dino Light Grey', hex: '#EDEDED'),
    56: (name: 'Dino Mid Grey', hex: '#515151'),
    57: (name: 'Dino Dark Teal', hex: '#184546'),
    58: (name: 'Dino Forest Teal', hex: '#007060'),
    59: (name: 'Dino Teal', hex: '#00C5AB'),
    60: (name: 'Dino Dark Forest', hex: '#40594C'),
    61: (name: 'Dino Dark Olive', hex: '#3E4F40'),
    62: (name: 'Dino Charcoal', hex: '#3B3938'),
    63: (name: 'Dino Dark Charcoal', hex: '#585554'),
    64: (name: 'Dino Light Charcoal', hex: '#9B9290'),
    65: (name: 'Dino Forest Grey', hex: '#525B56'),
    66: (name: 'Dino Sage Grey', hex: '#8AA196'),
    67: (name: 'Light Purple', hex: '#E8B0FF'),
    68: (name: 'Hot Pink', hex: '#FF119A'),
    69: (name: 'Dark Maroon', hex: '#730046'),
    70: (name: 'Deep Red', hex: '#B70042'),
    71: (name: 'Dark Brown Red', hex: '#7E331E'),
    72: (name: 'Rust', hex: '#A93000'),
    73: (name: 'Bright Red', hex: '#EF3100'),
    74: (name: 'Orange Red', hex: '#FF5834'),
    75: (name: 'Orange', hex: '#FF7F00'),
    76: (name: 'Amber', hex: '#FFA73A'),
    77: (name: 'Dark Gold', hex: '#AE7000'),
    78: (name: 'Olive Yellow', hex: '#949427'),
    79: (name: 'Almost Black', hex: '#171717'),
    80: (name: 'Dark Navy', hex: '#191D36'),
    81: (name: 'Dark Slate Blue', hex: '#152B3A'),
    82: (name: 'Dark Indigo', hex: '#302531'),
    83: (name: 'Neon Green', hex: '#A8FF44'),
    84: (name: 'Spring Green', hex: '#38E985'),
    85: (name: 'Dark Green3', hex: '#008840'),
    86: (name: 'Forest Green', hex: '#0F552E'),
    87: (name: 'Jungle Green', hex: '#005B45'),
    88: (name: 'Grass Green', hex: '#5B9725'),
    89: (name: 'Dark Purple2', hex: '#5E275F'),
    90: (name: 'Purple', hex: '#853587'),
    91: (name: 'Lavender', hex: '#BD77BE'),
    92: (name: 'Dark Teal2', hex: '#0E404A'),
    93: (name: 'Teal', hex: '#105563'),
    94: (name: 'Sky Blue', hex: '#14849C'),
    95: (name: 'Periwinkle', hex: '#82A7FF'),
    96: (name: 'Baby Blue', hex: '#ACEAFF'),
    97: (name: 'Dark Olive2', hex: '#505118'),
    98: (name: 'Olive', hex: '#766E3F'),
    99: (name: 'Yellow Green', hex: '#C0BD5E'),
    100: (name: 'Pale Yellow', hex: '#F4FFC0'),
    130: (name: 'Dark Red2', hex: '#360000'),
    131: (name: 'Deep Red2', hex: '#660000'),
    132: (name: 'Crimson', hex: '#B20000'),
    133: (name: 'Bright Red2', hex: '#FF0000'),
    134: (name: 'Light Red', hex: '#FF7272'),
    135: (name: 'Pale Red', hex: '#FFBEBE'),
    136: (name: 'Dusty Rose', hex: '#D88C8C'),
    137: (name: 'Terracotta', hex: '#A55454'),
    138: (name: 'Dark Terracotta', hex: '#361F00'),
    139: (name: 'Terracotta Coloring', hex: '#663600'),
    140: (name: 'Deep Orange2', hex: '#B25900'),
    141: (name: 'Cantaloupe', hex: '#FF7E00'),
    142: (name: 'Cantaloupe Coloring', hex: '#FFB872'),
    143: (name: 'Peach', hex: '#FFDEBE'),
    144: (name: 'Dusty Peach', hex: '#D8B28C'),
    145: (name: 'Tan', hex: '#A57B54'),
    146: (name: 'Dark Olive3', hex: '#363600'),
    147: (name: 'Olive2', hex: '#666600'),
    148: (name: 'Olive Yellow2', hex: '#B1B200'),
    149: (name: 'Yellow2', hex: '#FFFF00'),
    150: (name: 'Butter Yellow', hex: '#FFFF72'),
    151: (name: 'Buttermilk', hex: '#FFFFBE'),
    152: (name: 'Pale Yellow2', hex: '#D8D88C'),
    153: (name: 'Dark Olive Yellow', hex: '#A5A554'),
    154: (name: 'Dark Olive Green2', hex: '#1F3600'),
    155: (name: 'Olive Green2', hex: '#366600'),
    156: (name: 'Lime', hex: '#59B200'),
    157: (name: 'Chartreuse', hex: '#7FFF00'),
    158: (name: 'Yellow Green2', hex: '#B8FF72'),
    159: (name: 'Pale Green', hex: '#DEFFBE'),
    160: (name: 'Putrescence', hex: '#B2D88C'),
    161: (name: 'Sage', hex: '#7BA554'),
    162: (name: 'Dark Forest2', hex: '#003600'),
    163: (name: 'Forest', hex: '#006600'),
    164: (name: 'Mid Green', hex: '#00B200'),
    165: (name: 'Bright Green', hex: '#00FF00'),
    166: (name: 'Light Green2', hex: '#72FF72'),
    167: (name: 'Pistachio', hex: '#BEFFBE'),
    168: (name: 'Mint', hex: '#8CD88C'),
    169: (name: 'Sage2', hex: '#54A554'),
    170: (name: 'Dark Jungle', hex: '#003620'),
    171: (name: 'Jungle', hex: '#006636'),
    172: (name: 'Mid Jungle', hex: '#00B259'),
    173: (name: 'Spring Green2', hex: '#00FF7F'),
    174: (name: 'Aquamarine', hex: '#72FFB8'),
    175: (name: 'Pale Aquamarine', hex: '#BEFFDE'),
    176: (name: 'Turquoise', hex: '#8CD8B2'),
    177: (name: 'Sage Teal', hex: '#54A57B'),
    178: (name: 'Dark Teal3', hex: '#003636'),
    179: (name: 'Skobeloff', hex: '#006666'),
    180: (name: 'Mid Teal', hex: '#00B2B2'),
    181: (name: 'Cyan2', hex: '#00FFFF'),
    182: (name: 'Electricity', hex: '#72FFFF'),
    183: (name: 'Pale Cyan', hex: '#BEFFFF'),
    184: (name: 'Pale Teal', hex: '#8CD8D8'),
    185: (name: 'Slate Teal', hex: '#54A5A5'),
    186: (name: 'Dark Navy2', hex: '#002036'),
    187: (name: 'Navy', hex: '#003666'),
    188: (name: 'Mid Blue', hex: '#0059B2'),
    189: (name: 'Sky Blue2', hex: '#007EFF'),
    190: (name: 'Light Blue2', hex: '#72B8FF'),
    191: (name: 'Cornflower', hex: '#BEDEFF'),
    192: (name: 'Moonstone', hex: '#8BB1D8'),
    193: (name: 'Mid Slate', hex: '#547BA5'),
    194: (name: 'Very Dark Blue', hex: '#000036'),
    195: (name: 'Dark Blue2', hex: '#000066'),
    196: (name: 'Mid Dark Blue', hex: '#0000B2'),
    197: (name: 'Blue2', hex: '#0000FF'),
    198: (name: 'Light Blue3', hex: '#7272FF'),
    199: (name: 'Pale Blue', hex: '#BEBEFF'),
    200: (name: 'Pale Slate', hex: '#8B8BD8'),
    201: (name: 'Deepfreeze', hex: '#5454A5'),
    202: (name: 'Very Dark Indigo', hex: '#1F0036'),
    203: (name: 'Dark Indigo2', hex: '#360066'),
    204: (name: 'Indigo', hex: '#5900B2'),
    205: (name: 'Violet', hex: '#7F00FF'),
    206: (name: 'Light Violet', hex: '#B872FF'),
    207: (name: 'Pale Violet', hex: '#DEBEFF'),
    208: (name: 'Dusty Violet', hex: '#B28CD8'),
    209: (name: 'Parchment Coloring', hex: '#7B54A5'),
    210: (name: 'Very Dark Purple', hex: '#360036'),
    211: (name: 'Dark Purple3', hex: '#660066'),
    212: (name: 'Deep Magenta', hex: '#B100B2'),
    213: (name: 'Magenta2', hex: '#FF00FF'),
    214: (name: 'Light Magenta', hex: '#FF72FF'),
    215: (name: 'Cottoncandy', hex: '#FFBEFF'),
    216: (name: 'Dusty Rose2', hex: '#D88CD8'),
    217: (name: 'Tangerine Coloring', hex: '#A554A5'),
    218: (name: 'Very Dark Rose', hex: '#36001F'),
    219: (name: 'Dark Rose', hex: '#660036'),
    220: (name: 'Deep Rose', hex: '#B20059'),
    221: (name: 'Rose', hex: '#FF007E'),
    222: (name: 'Hot Pink2', hex: '#FF72B8'),
    223: (name: 'Valentine', hex: '#FFBEDE'),
    224: (name: 'Dusty Pink', hex: '#D88CB2'),
    225: (name: 'Mauve2', hex: '#A5547B'),
    226: (name: 'Near Black', hex: '#1F1F1F'),
    227: (name: 'Very Dark Grey', hex: '#363636'),
    228: (name: 'Dark Grey', hex: '#4E4E4E'),
    229: (name: 'Mid Dark Grey', hex: '#666666'),
    230: (name: 'Grey', hex: '#7F7F7F'),
    231: (name: 'Mid Grey2', hex: '#989898'),
    232: (name: 'Light Grey2', hex: '#B2B2B2'),
    233: (name: 'Pale Grey', hex: '#CBCBCB'),
    234: (name: 'Very Light Grey', hex: '#E6E6E6'),
    235: (name: 'Pure White', hex: '#FFFFFF'),
    236: (name: 'Dark Khaki', hex: '#423726'),
    237: (name: 'Khaki', hex: '#594828'),
    238: (name: 'Mid Khaki', hex: '#7F6430'),
    239: (name: 'Light Khaki', hex: '#98813F'),
    240: (name: 'Very Light Khaki', hex: '#B29B59'),
    241: (name: 'Parchment', hex: '#CBB166'),
    242: (name: 'Parchment Light', hex: '#E6C872'),
    243: (name: 'Pale Parchment', hex: '#FFEFBE'),
    244: (name: 'Tangerine', hex: '#F5F5DB'),
    245: (name: 'Tangerine2', hex: '#98452A'),
    246: (name: 'Tangerine3', hex: '#FFA328'),
    247: (name: 'Amber2', hex: '#FFBF00'),
    248: (name: 'Craggy-Dew', hex: '#F0F035'),
    249: (name: 'Craggy-Dew2', hex: '#B2E919'),
    250: (name: 'Craggy-Dew3', hex: '#277233'),
    251: (name: 'Craggy-Dew4', hex: '#2EC5B5'),
    252: (name: 'Craggy-Dew5', hex: '#007088'),
    253: (name: 'Craggy-Dew6', hex: '#545871'),
    254: (name: 'Bubblegum', hex: '#FFBECE'),
  };

  /// Obtenir une couleur ARK par son ID
  static ArkColor? fromId(int id) {
    final data = _colors[id];
    if (data == null) return null;
    return ArkColor(id: id, name: data.name, hex: data.hex);
  }

  /// Convertir un ID ARK en code hex Flutter
  static String? idToHex(int id) => _colors[id]?.hex;

  /// Trouver l'ID ARK le plus proche d'un code hex
  static int hexToClosestId(String hex) {
    final target = _parseHexColor(hex);
    int bestId = 1;
    double bestDist = double.maxFinite;
    for (final entry in _colors.entries) {
      final c = _parseHexColor(entry.value.hex);
      final dist = _colorDistance(target, c);
      if (dist < bestDist) {
        bestDist = dist;
        bestId = entry.key;
      }
    }
    return bestId;
  }

  static List<int> _parseHexColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return [128, 128, 128];
    return [
      int.parse(h.substring(0, 2), radix: 16),
      int.parse(h.substring(2, 4), radix: 16),
      int.parse(h.substring(4, 6), radix: 16),
    ];
  }

  static double _colorDistance(List<int> a, List<int> b) {
    final dr = (a[0] - b[0]).toDouble();
    final dg = (a[1] - b[1]).toDouble();
    final db = (a[2] - b[2]).toDouble();
    return dr * dr + dg * dg + db * db;
  }

  /// Toutes les couleurs triées par ID
  static List<ArkColor> get allColors => _colors.entries
      .map((e) => ArkColor(id: e.key, name: e.value.name, hex: e.value.hex))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  /// Nombre total de couleurs
  static int get count => _colors.length;
}
