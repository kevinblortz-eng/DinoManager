import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'ark_species_data.dart';
import 'ark_color_palette.dart';

class Dino {
  final int? id;
  final String nom;
  final String espece;
  final String sexe;
  final String role;
  final int niveau;

  // Stats – valeurs totales (affichées dans ARK)
  final int hp;
  final int stamina;
  final int oxygene;
  final int nourriture;
  final int poids;
  final double degats;
  final double vitesse;

  // Points investis dans chaque stat (niveaux sauvages/domestiqués)
  final int hpPoints;
  final int staminaPoints;
  final int oxygenePoints;
  final int nourriturePoints;
  final int poidsPoints;
  final int degatsPoints;
  final int vitessePoints;

  final String mutations;      // ex: "0/20"
  final int mutationsMaternal;
  final int mutationsPaternal;

  // Couleurs régionales stockées sous forme "ID:HEX" (ex: "75:#FF7F00")
  // ID = code couleur ARK officiel (1-254), HEX = couleur hexadécimale
  final String couleur0;
  final String couleur1;
  final String couleur2;
  final String couleur3;
  final String couleur4;
  final String couleur5;

  final String tagVersion;   // héritage (conservé pour compat)
  final List<String> tags;   // multi-tags (nouveau)
  final String? image;
  final String notes;
  final DateTime dateAjout;

  Dino({
    this.id,
    required this.nom,
    required this.espece,
    this.sexe = 'Inconnu',
    this.role = 'Breed',
    required this.niveau,
    this.hp = 0,
    this.stamina = 0,
    this.oxygene = 0,
    this.nourriture = 0,
    this.poids = 0,
    this.degats = 0,
    this.vitesse = 0,
    this.hpPoints = 0,
    this.staminaPoints = 0,
    this.oxygenePoints = 0,
    this.nourriturePoints = 0,
    this.poidsPoints = 0,
    this.degatsPoints = 0,
    this.vitessePoints = 0,
    this.mutations = '0/0',
    this.mutationsMaternal = 0,
    this.mutationsPaternal = 0,
    this.couleur0 = '0:#808080',
    this.couleur1 = '0:#808080',
    this.couleur2 = '0:#808080',
    this.couleur3 = '0:#808080',
    this.couleur4 = '0:#808080',
    this.couleur5 = '0:#808080',
    this.tagVersion = '',
    List<String>? tags,
    this.image,
    this.notes = '',
    DateTime? dateAjout,
    List<String>? tagsInit,
  })  : tags = tags ?? tagsInit ?? const [],
        dateAjout = dateAjout ?? DateTime.now();

  // ─── Espèces ──────────────────────────────────────────────────────────────
  static List<String> get especesDisponibles => [
    ...ArkSpeciesData.speciesWithImages,
    'Autre',
  ];

  static const List<String> rolesDisponibles = [
    'Boss', 'Breed', 'Solid', 'Farm', 'Collection', 'Combat', 'Autre',
  ];

  /// Les valeurs possibles pour le sexe (peuvent être combinées : 'Mâle+Femelle').
  static const List<String> sexesDisponibles = ['Mâle', 'Femelle', 'Mâle+Femelle', 'Inconnu'];

  /// Vérifie si ce dino a le sexe demandé (supporte la combinaison).
  bool hasSexe(String s) {
    if (sexe == s) return true;
    if (s == 'Mâle' && sexe == 'Mâle+Femelle') return true;
    if (s == 'Femelle' && sexe == 'Mâle+Femelle') return true;
    return false;
  }

  // Tags par défaut (en mémoire, extensibles via shared_prefs ou Hive)
  static const List<String> tagsParDefaut = [
    'Boss', 'Breeding','Solid','Farm','Collection','Combat',
  ];
  // Pour la compat ascendante
  static const List<String> tagsDisponibles = [
    'Boss', 'Breeding',
  ];

  static List<String> _parseTags(Map<String, dynamic> map) {
    // Nouveau format : liste JSON dans 'tags'
    final tagsJson = map['tags'];
    if (tagsJson != null && tagsJson is String && tagsJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsJson);
        if (decoded is List) return decoded.cast<String>();
      } catch (_) {}
    }
    // Ancien format : tag_version était une string unique
    final old = map['tag_version'] as String? ?? '';
    if (old.isNotEmpty && old != 'Solid') return [old];
    return [];
  }

  // ─── Couleurs ─────────────────────────────────────────────────────────────

  /// Extraire l'ID ARK depuis le format "ID:HEX"
  static int _parseColorId(String value) {
    if (value.contains(':')) {
      final parts = value.split(':');
      return int.tryParse(parts[0]) ?? 0;
    }
    // Ancien format hex seul → trouver l'ID le plus proche
    if (value.startsWith('#')) {
      return ArkColorPalette.hexToClosestId(value);
    }
    return int.tryParse(value) ?? 0;
  }

  /// Extraire le code HEX depuis le format "ID:HEX"
  static String _parseColorHex(String value) {
    if (value.contains(':')) {
      final parts = value.split(':');
      if (parts.length >= 2 && parts[1].isNotEmpty) return parts[1];
    }
    // Ancien format hex seul
    if (value.startsWith('#')) return value;
    // ID seul → chercher dans la palette
    final id = int.tryParse(value);
    if (id != null) {
      return ArkColorPalette.idToHex(id) ?? '#808080';
    }
    return '#808080';
  }

  /// Créer un code couleur au format "ID:HEX"
  static String encodeColor(int arkId, String hex) => '$arkId:$hex';

  /// Créer depuis un ID ARK seul
  static String encodeColorFromId(int arkId) {
    final hex = ArkColorPalette.idToHex(arkId) ?? '#808080';
    return '$arkId:$hex';
  }

  // IDs ARK officiels
  int get colorId0 => _parseColorId(couleur0);
  int get colorId1 => _parseColorId(couleur1);
  int get colorId2 => _parseColorId(couleur2);
  int get colorId3 => _parseColorId(couleur3);
  int get colorId4 => _parseColorId(couleur4);
  int get colorId5 => _parseColorId(couleur5);

  // Codes hex
  String get colorHex0 => _parseColorHex(couleur0);
  String get colorHex1 => _parseColorHex(couleur1);
  String get colorHex2 => _parseColorHex(couleur2);
  String get colorHex3 => _parseColorHex(couleur3);
  String get colorHex4 => _parseColorHex(couleur4);
  String get colorHex5 => _parseColorHex(couleur5);

  // Couleurs Flutter
  Color get colorRegion0 => _hexToColor(colorHex0);
  Color get colorRegion1 => _hexToColor(colorHex1);
  Color get colorRegion2 => _hexToColor(colorHex2);
  Color get colorRegion3 => _hexToColor(colorHex3);
  Color get colorRegion4 => _hexToColor(colorHex4);
  Color get colorRegion5 => _hexToColor(colorHex5);

  List<Color> get allRegionColors => [
    colorRegion0, colorRegion1, colorRegion2,
    colorRegion3, colorRegion4, colorRegion5,
  ];

  /// Pour DinoImageWidget
  List<String?> get colorRegions => [
    colorHex0.isEmpty ? null : colorHex0,
    colorHex1.isEmpty ? null : colorHex1,
    colorHex2.isEmpty ? null : colorHex2,
    colorHex3.isEmpty ? null : colorHex3,
    colorHex4.isEmpty ? null : colorHex4,
    colorHex5.isEmpty ? null : colorHex5,
  ];

  /// IDs des 6 régions
  List<int> get colorIds => [colorId0, colorId1, colorId2, colorId3, colorId4, colorId5];

  static Color _hexToColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) return Color(int.parse('FF$cleanHex', radix: 16));
      if (cleanHex.length == 8) return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {}
    return Colors.grey;
  }

  /// Convertit une Color Flutter en string hex #RRGGBB
  /// Compatible Flutter 3.27+ (sans .red/.green/.blue dépréciés)
  static String colorToHex(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final g = (color.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    final b = (color.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }

  // ─── Stats ────────────────────────────────────────────────────────────────
  /// Total des points investis
  int get totalPoints =>
      hpPoints + staminaPoints + oxygenePoints + nourriturePoints +
      poidsPoints + degatsPoints + vitessePoints;

  // ─── Émoji espèce ─────────────────────────────────────────────────────────
  String get especeEmoji {
    final lower = espece.toLowerCase();
    if (lower.contains('rex') || lower.contains('yutyrannus')) return '🦖';
    if (lower.contains('wyvern') || lower.contains('dragon')) return '🐉';
    if (lower.contains('raptor') || lower.contains('deinonychus')) return '🦕';
    if (lower.contains('pteranodon') || lower.contains('argent') || lower.contains('quetz')) return '🦅';
    if (lower.contains('megalodon') || lower.contains('shark')) return '🦈';
    if (lower.contains('ankylo') || lower.contains('stego')) return '🦔';
    if (lower.contains('mammoth') || lower.contains('woolly')) return '🦣';
    if (lower.contains('wolf') || lower.contains('direwolf')) return '🐺';
    if (lower.contains('bear')) return '🐻';
    if (lower.contains('spider') || lower.contains('araneo')) return '🕷️';
    if (lower.contains('crab') || lower.contains('kark')) return '🦀';
    if (lower.contains('turtle') || lower.contains('carbo')) return '🐢';
    return '🦕';
  }

  // ─── Couleurs UI ──────────────────────────────────────────────────────────
  Color get roleColor {
    switch (role) {
      case 'Boss': return const Color(0xFFFF4444);
      case 'Breed': return const Color(0xFF4CAF50);
      case 'Solid': return const Color(0xFFFF6B00);
      case 'Farm': return const Color(0xFFFFD700);
      case 'Collection': return const Color(0xFF00BCD4);
      default: return const Color(0xFF9E9E9E);
    }
  }

  Color get sexeColor {
    switch (sexe) {
      case 'Mâle': return const Color(0xFF4FC3F7);
      case 'Femelle': return const Color(0xFFF48FB1);
      case 'Mâle+Femelle': return const Color(0xFFBB86FC);
      default: return const Color(0xFF9E9E9E);
    }
  }

  /// Symbole(s) de sexe à afficher
  String get sexeSymbol {
    switch (sexe) {
      case 'Mâle': return '♂';
      case 'Femelle': return '♀';
      case 'Mâle+Femelle': return '♂♀';
      default: return '';
    }
  }

  // ─── COMPARAISON DE STATS POUR VARIANTES ─────────────────────────────────────

  /// Signature unique des stats pour identifier les dinos identiques
  String get statsSignature =>
      '$espece|$niveau|$hp|$stamina|$oxygene|$nourriture|$poids|${degats.toStringAsFixed(1)}|${vitesse.toStringAsFixed(1)}';

  /// Vérifie si deux dinos ont exactement les mêmes stats (candidats pour variantes couleurs)
  bool hasSameStats(Dino other) {
    return espece == other.espece &&
           niveau == other.niveau &&
           hp == other.hp &&
           stamina == other.stamina &&
           oxygene == other.oxygene &&
           nourriture == other.nourriture &&
           poids == other.poids &&
           (degats - other.degats).abs() < 0.1 &&
           (vitesse - other.vitesse).abs() < 0.1;
  }

  /// Vérifie si c'est une vraie variante de couleur (stats identiques, couleurs différentes)
  bool isColorVariantOf(Dino other) {
    if (!hasSameStats(other)) return false;

    // Vérifier qu'au moins une couleur est différente
    return colorId0 != other.colorId0 ||
           colorId1 != other.colorId1 ||
           colorId2 != other.colorId2 ||
           colorId3 != other.colorId3 ||
           colorId4 != other.colorId4 ||
           colorId5 != other.colorId5;
  }

  // ─── Sérialisation ────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nom': nom,
      'espece': espece,
      'sexe': sexe,
      'role': role,
      'niveau': niveau,
      'hp': hp,
      'stamina': stamina,
      'oxygene': oxygene,
      'nourriture': nourriture,
      'poids': poids,
      'degats': degats,
      'vitesse': vitesse,
      'hp_points': hpPoints,
      'stamina_points': staminaPoints,
      'oxygene_points': oxygenePoints,
      'nourriture_points': nourriturePoints,
      'poids_points': poidsPoints,
      'degats_points': degatsPoints,
      'vitesse_points': vitessePoints,
      'mutations': mutations,
      'mutations_maternal': mutationsMaternal,
      'mutations_paternal': mutationsPaternal,
      'couleur0': couleur0,
      'couleur1': couleur1,
      'couleur2': couleur2,
      'couleur3': couleur3,
      'couleur4': couleur4,
      'couleur5': couleur5,
      'tag_version': tagVersion,
      'tags': jsonEncode(tags),
      'image': image,
      'notes': notes,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  factory Dino.fromMap(Map<String, dynamic> map) {
    return Dino(
      id: map['id'] as int?,
      nom: map['nom'] as String? ?? '',
      espece: map['espece'] as String? ?? 'Rex',
      sexe: map['sexe'] as String? ?? 'Inconnu',
      role: map['role'] as String? ?? 'Breed',
      niveau: map['niveau'] as int? ?? 0,
      hp: map['hp'] as int? ?? 0,
      stamina: map['stamina'] as int? ?? 0,
      oxygene: map['oxygene'] as int? ?? 0,
      nourriture: map['nourriture'] as int? ?? 0,
      poids: map['poids'] as int? ?? 0,
      degats: (map['degats'] as num?)?.toDouble() ?? 0.0,
      vitesse: (map['vitesse'] as num?)?.toDouble() ?? 0.0,
      hpPoints: map['hp_points'] as int? ?? 0,
      staminaPoints: map['stamina_points'] as int? ?? 0,
      oxygenePoints: map['oxygene_points'] as int? ?? 0,
      nourriturePoints: map['nourriture_points'] as int? ?? 0,
      poidsPoints: map['poids_points'] as int? ?? 0,
      degatsPoints: map['degats_points'] as int? ?? 0,
      vitessePoints: map['vitesse_points'] as int? ?? 0,
      mutations: map['mutations'] as String? ?? '0/0',
      mutationsMaternal: map['mutations_maternal'] as int? ?? 0,
      mutationsPaternal: map['mutations_paternal'] as int? ?? 0,
      couleur0: map['couleur0'] as String? ?? '0:#808080',
      couleur1: map['couleur1'] as String? ?? '0:#808080',
      couleur2: map['couleur2'] as String? ?? '0:#808080',
      couleur3: map['couleur3'] as String? ?? '0:#808080',
      couleur4: map['couleur4'] as String? ?? '0:#808080',
      couleur5: map['couleur5'] as String? ?? '0:#808080',
      tagVersion: map['tag_version'] as String? ?? '',
      tags: _parseTags(map),
      image: map['image'] as String?,
      notes: map['notes'] as String? ?? '',
      dateAjout: map['date_ajout'] != null
          ? DateTime.tryParse(map['date_ajout'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Crée une copie indépendante pour duplication (nouveau dino sans ID)
  Dino duplicate({String? newName}) {
    return Dino(
      id: null,
      espece: espece,
      nom: newName ?? '$nom (copie)',
      sexe: sexe,
      niveau: niveau,
      role: role,
      hp: hp,
      stamina: stamina,
      oxygene: oxygene,
      nourriture: nourriture,
      poids: poids,
      degats: degats,
      vitesse: vitesse,
      hpPoints: hpPoints,
      staminaPoints: staminaPoints,
      oxygenePoints: oxygenePoints,
      nourriturePoints: nourriturePoints,
      poidsPoints: poidsPoints,
      degatsPoints: degatsPoints,
      vitessePoints: vitessePoints,
      mutations: mutations,
      mutationsMaternal: mutationsMaternal,
      mutationsPaternal: mutationsPaternal,
      couleur0: couleur0,
      couleur1: couleur1,
      couleur2: couleur2,
      couleur3: couleur3,
      couleur4: couleur4,
      couleur5: couleur5,
      tagVersion: tagVersion,
      tags: List<String>.from(tags),
      image: image,
      notes: notes,
      dateAjout: DateTime.now(),
    );
  }

  /// Crée une copie du dino avec des champs modifiés
  Dino copyWith({
    int? id,
    String? nom,
    String? espece,
    String? sexe,
    String? role,
    int? niveau,
    int? hp,
    int? stamina,
    int? oxygene,
    int? nourriture,
    int? poids,
    double? degats,
    double? vitesse,
    int? hpPoints,
    int? staminaPoints,
    int? oxygenePoints,
    int? nourriturePoints,
    int? poidsPoints,
    int? degatsPoints,
    int? vitessePoints,
    String? mutations,
    int? mutationsMaternal,
    int? mutationsPaternal,
    String? couleur0,
    String? couleur1,
    String? couleur2,
    String? couleur3,
    String? couleur4,
    String? couleur5,
    String? tagVersion,
    List<String>? tags,
    String? image,
    String? notes,
    DateTime? dateAjout,
  }) {
    return Dino(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      espece: espece ?? this.espece,
      sexe: sexe ?? this.sexe,
      role: role ?? this.role,
      niveau: niveau ?? this.niveau,
      hp: hp ?? this.hp,
      stamina: stamina ?? this.stamina,
      oxygene: oxygene ?? this.oxygene,
      nourriture: nourriture ?? this.nourriture,
      poids: poids ?? this.poids,
      degats: degats ?? this.degats,
      vitesse: vitesse ?? this.vitesse,
      hpPoints: hpPoints ?? this.hpPoints,
      staminaPoints: staminaPoints ?? this.staminaPoints,
      oxygenePoints: oxygenePoints ?? this.oxygenePoints,
      nourriturePoints: nourriturePoints ?? this.nourriturePoints,
      poidsPoints: poidsPoints ?? this.poidsPoints,
      degatsPoints: degatsPoints ?? this.degatsPoints,
      vitessePoints: vitessePoints ?? this.vitessePoints,
      mutations: mutations ?? this.mutations,
      mutationsMaternal: mutationsMaternal ?? this.mutationsMaternal,
      mutationsPaternal: mutationsPaternal ?? this.mutationsPaternal,
      couleur0: couleur0 ?? this.couleur0,
      couleur1: couleur1 ?? this.couleur1,
      couleur2: couleur2 ?? this.couleur2,
      couleur3: couleur3 ?? this.couleur3,
      couleur4: couleur4 ?? this.couleur4,
      couleur5: couleur5 ?? this.couleur5,
      tagVersion: tagVersion ?? this.tagVersion,
      tags: tags ?? List<String>.from(this.tags),
      image: image ?? this.image,
      notes: notes ?? this.notes,
      dateAjout: dateAjout ?? this.dateAjout,
    );
  }
    /// Factory pour créer un dino vide (utilisé comme fallback)
  factory Dino.empty() {
    return Dino(
      id: null,
      nom: 'N/A',
      espece: 'N/A',
      sexe: 'Inconnu',
      role: 'Breed',
      niveau: 0,
      hp: 0,
      stamina: 0,
      oxygene: 0,
      nourriture: 0,
      poids: 0,
      degats: 0.0,
      vitesse: 0.0,
      hpPoints: 0,
      staminaPoints: 0,
      oxygenePoints: 0,
      nourriturePoints: 0,
      poidsPoints: 0,
      degatsPoints: 0,
      vitessePoints: 0,
      mutations: '0/0',
      mutationsMaternal: 0,
      mutationsPaternal: 0,
      couleur0: '0:#808080',
      couleur1: '0:#808080',
      couleur2: '0:#808080',
      couleur3: '0:#808080',
      couleur4: '0:#808080',
      couleur5: '0:#808080',
      tagVersion: '',
      tags: const [],
      image: null,
      notes: '',
      dateAjout: DateTime.now(),
    );
  }
}
