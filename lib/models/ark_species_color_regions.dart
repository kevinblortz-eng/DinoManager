// lib/models/ark_species_color_regions.dart
// Données de visibilité des 6 régions de couleur ARK par espèce.
// Source : ARKpedia / ARK wiki + ARKStatsExtractor species data.
// true  = région visible sur le modèle 3D
// false = région invisible (pas de coloration affichée)
// Ordre : [R0, R1, R2, R3, R4, R5]

class ArkSpeciesColorRegions {
  /// Régions visibles par espèce (clé = nom exact de l'espèce dans l'app).
  /// Si une espèce est absente, on retourne [true,true,true,true,true,true] par défaut.
  static const Map<String, List<bool>> _data = {
    // ── A ─────────────────────────────────────────────────────────────
    'Achatina':              [true,  true,  false, false, false, false],
    'Achatina Aberrant':     [true,  true,  false, false, false, false],
    'Acrocanthosaurus':      [true,  true,  true,  true,  true,  true ],
    'Allosaurus':            [true,  true,  true,  true,  false, false],
    'Anglerfish':            [true,  true,  true,  false, false, false],
    'Anglerfish Aberrant':   [true,  true,  true,  false, false, false],
    'Ankylosaurus':          [true,  true,  true,  true,  false, false],
    'Ankylosaurus Aberrant': [true,  true,  true,  true,  false, false],
    'Araneo':                [true,  true,  true,  false, false, false],
    'Araneo Aberrant':       [true,  true,  true,  false, false, false],
    'Archaeopteryx':         [true,  true,  true,  true,  false, false],
    'Archelon':              [true,  true,  true,  true,  false, false],
    'Argentavis':            [true,  true,  true,  true,  true,  true ],
    'Armadoggo':             [true,  true,  true,  true,  true,  false],
    'Arthropluera':          [true,  true,  false, false, false, false],
    'Arthropluera Aberrant': [true,  true,  false, false, false, false],
    'Aureliax':              [true,  true,  true,  true,  true,  true ],
    // ── B ─────────────────────────────────────────────────────────────
    'Baryonyx':              [true,  true,  true,  true,  true,  false],
    'Baryonyx Aberrant':     [true,  true,  true,  true,  true,  false],
    'Basilisk':              [true,  true,  true,  true,  true,  true ],
    'Basilosaurus':          [true,  true,  true,  false, false, false],
    'Beelzebufo':            [true,  true,  true,  true,  false, false],
    'Beelzebufo Aberrant':   [true,  true,  true,  true,  false, false],
    'Bison':                 [true,  true,  true,  true,  false, false],
    'Brontosaurus':          [true,  true,  true,  true,  false, false],
    'Bulbdog':               [true,  true,  true,  true,  true,  false],
    // ── C ─────────────────────────────────────────────────────────────
    'Carbonemys':            [true,  true,  true,  false, false, false],
    'Carbonemys Aberrant':   [true,  true,  true,  false, false, false],
    'Carcharodontosaurus':   [true,  true,  true,  true,  true,  true ],
    'Carnotaurus':           [true,  true,  true,  true,  true,  false],
    'Carnotaurus Aberrant':  [true,  true,  true,  true,  true,  false],
    'Castoroides':           [true,  true,  true,  true,  false, false],
    'Cat':                   [true,  true,  true,  true,  false, false],
    'Ceratosaurus':          [true,  true,  true,  true,  true,  true ],
    'Chalicotherium':        [true,  true,  true,  false, false, false],
    'Chalk Elemental':       [true,  true,  false, false, false, false],
    'Cnidaria':              [true,  true,  false, false, false, false],
    'Coelacanth':            [true,  true,  true,  false, false, false],
    'Coelacanth Aberrant':   [true,  true,  true,  false, false, false],
    'Compy':                 [true,  true,  true,  true,  false, false],
    'Cosmo':                 [true,  true,  true,  true,  true,  true ],
    'Cryolophosaurus':       [true,  true,  true,  true,  true,  true ],
    // ── D ─────────────────────────────────────────────────────────────
    'Daeodon':               [true,  true,  true,  true,  false, false],
    'Deinonychus':           [true,  true,  true,  true,  true,  true ],
    'Deinosuchus':           [true,  true,  true,  true,  true,  false],
    'Deinotherium':          [true,  true,  true,  true,  false, false],
    'Desmodus':              [true,  true,  true,  true,  true,  false],
    'Dimetrodon':            [true,  true,  true,  false, false, false],
    'Dimetrodon Aberrant':   [true,  true,  true,  false, false, false],
    'Dimorphodon':           [true,  true,  true,  true,  false, false],
    'Dimorphodon Aberrant':  [true,  true,  true,  true,  false, false],
    'Diplocaulus':           [true,  true,  false, false, false, false],
    'Diplocaulus Aberrant':  [true,  true,  false, false, false, false],
    'Diplodocus':            [true,  true,  true,  true,  false, false],
    'Diplodocus Aberrant':   [true,  true,  true,  true,  false, false],
    'Dire Bear':             [true,  true,  true,  true,  false, false],
    'Dire Bear Aberrant':    [true,  true,  true,  true,  false, false],
    'Dire Polar Bear':       [true,  true,  true,  true,  false, false],
    'Direwolf':              [true,  true,  true,  true,  false, false],
    'Dodo':                  [true,  true,  true,  true,  false, false],
    'Dodo Aberrant':         [true,  true,  true,  true,  false, false],
    'Doedicurus':            [true,  true,  true,  false, false, false],
    'Doedicurus Aberrant':   [true,  true,  true,  false, false, false],
    'Drakeling (Autumn)':    [true,  true,  true,  true,  true,  true ],
    'Drakeling (Spring)':    [true,  true,  true,  true,  true,  true ],
    'Drakeling (Summer)':    [true,  true,  true,  true,  true,  true ],
    'Drakeling (Winter)':    [true,  true,  true,  true,  true,  true ],
    'Dreadmare':             [true,  true,  true,  true,  true,  true ],
    'Dreadnoughtus':         [true,  true,  true,  true,  false, false],
    'Dung Beetle':           [true,  true,  true,  false, false, false],
    'Dung Beetle Aberrant':  [true,  true,  true,  false, false, false],
    'Dunkleosteus':          [true,  true,  false, false, false, false],
    // ── E ─────────────────────────────────────────────────────────────
    'Elderclaw':             [true,  true,  true,  true,  true,  true ],
    'Electrophorus':         [true,  true,  false, false, false, false],
    'Electrophorus Aberrant':[true,  true,  false, false, false, false],
    'Enforcer':              [true,  true,  true,  true,  false, false],
    'Equus':                 [true,  true,  true,  true,  true,  false],
    'Equus Aberrant':        [true,  true,  true,  true,  true,  false],
    // ── F ─────────────────────────────────────────────────────────────
    'Fasolasuchus':          [true,  true,  true,  true,  true,  false],
    'Fasolasuchus Aberrant': [true,  true,  true,  true,  true,  false],
    'Featherlight':          [true,  true,  true,  true,  true,  false],
    'Fire Wyvern':           [true,  true,  true,  false, false, false],
    // ── G ─────────────────────────────────────────────────────────────
    'Gacha':                 [true,  true,  true,  true,  false, false],
    'Gallimimus':            [true,  true,  true,  true,  false, false],
    'Gasbags':               [true,  true,  true,  false, false, false],
    'Gigadesmodus':          [true,  true,  true,  true,  true,  false],
    'Giganotosaurus':        [true,  true,  true,  true,  true,  false],
    'Giganotosaurus Tek':    [true,  true,  true,  true,  true,  false],
    'Gigantopithecus':       [true,  true,  true,  true,  false, false],
    'Gigantopithecus Aberrant':[true,true,  true,  true,  false, false],
    'Gigantoraptor':         [true,  true,  true,  true,  true,  true ],
    'Gigantoraptor Aberrant':[true,  true,  true,  true,  true,  true ],
    'Gloon':                 [true,  true,  true,  true,  true,  false],
    'Glowtail':              [true,  true,  true,  true,  true,  false],
    'Grand Tortugar':        [true,  true,  true,  true,  false, false],
    'Grendel (Alpha)':       [true,  true,  true,  true,  true,  true ],
    'Griffin':               [true,  true,  true,  true,  false, false],
    // ── H ─────────────────────────────────────────────────────────────
    'Helicoprion':           [true,  true,  true,  false, false, false],
    'Hesperornis':           [true,  true,  true,  true,  false, false],
    'Hyaenodon':             [true,  true,  true,  true,  false, false],
    'Hydraskos the Unbroken':[true,  true,  true,  true,  true,  true ],
    // ── I ─────────────────────────────────────────────────────────────
    'Ice Elemental':         [true,  true,  false, false, false, false],
    'Ice Wyvern':            [true,  true,  true,  false, false, false],
    'Ichthyornis':           [true,  true,  true,  false, false, false],
    'Ichthyosaurus':         [true,  true,  false, false, false, false],
    'Iguanodon':             [true,  true,  true,  true,  false, false],
    'Iguanodon Aberrant':    [true,  true,  true,  true,  false, false],
    // ── J ─────────────────────────────────────────────────────────────
    'Jerboa':                [true,  true,  true,  false, false, false],
    // ── K ─────────────────────────────────────────────────────────────
    'Kairuku':               [true,  true,  false, false, false, false],
    'Kaprosuchus':           [true,  true,  true,  true,  false, false],
    'Karkinos':              [true,  true,  true,  false, false, false],
    'Kentrosaurus':          [true,  true,  true,  true,  false, false],
    // ── L ─────────────────────────────────────────────────────────────
    'Lava Elemental':        [true,  true,  false, false, false, false],
    'Lightning Wyvern':      [true,  true,  true,  false, false, false],
    'Liopleurodon':          [true,  true,  false, false, false, false],
    'Lymantria':             [true,  true,  true,  true,  false, false],
    'Lystrosaurus':          [true,  true,  true,  false, false, false],
    'Lystrosaurus Aberrant': [true,  true,  true,  false, false, false],
    // ── M ─────────────────────────────────────────────────────────────
    'Maeguana':              [true,  true,  true,  true,  true,  false],
    'Malwyn':                [true,  true,  true,  true,  true,  true ],
    'Mammoth':               [true,  true,  true,  true,  false, false],
    'Managarmr':             [true,  true,  true,  true,  true,  false],
    'Manta':                 [true,  true,  true,  false, false, false],
    'Manta Aberrant':        [true,  true,  true,  false, false, false],
    'Mantis':                [true,  true,  true,  false, false, false],
    'Megalania':             [true,  true,  true,  true,  false, false],
    'Megalania Aberrant':    [true,  true,  true,  true,  false, false],
    'Megaloceros':           [true,  true,  true,  true,  false, false],
    'Megalodon':             [true,  true,  true,  false, false, false],
    'Megalosaurus':          [true,  true,  true,  true,  true,  false],
    'Megalosaurus Aberrant': [true,  true,  true,  true,  true,  false],
    'Meganeura':             [true,  true,  true,  false, false, false],
    'Meganeura Aberrant':    [true,  true,  true,  false, false, false],
    'Megaraptor':            [true,  true,  true,  true,  true,  true ],
    'Megatherium':           [true,  true,  true,  true,  false, false],
    'Minotarchos':           [true,  true,  true,  true,  true,  true ],
    'Morellatops':           [true,  true,  true,  false, false, false],
    'Mosasaurus':            [true,  true,  true,  false, false, false],
    'Moschops':              [true,  true,  true,  false, false, false],
    'Moschops Aberrant':     [true,  true,  true,  false, false, false],
    // ── N ─────────────────────────────────────────────────────────────
    'Neophyte':              [true,  true,  true,  true,  true,  false],
    // ── O ─────────────────────────────────────────────────────────────
    'Oasisaur':              [true,  true,  true,  true,  true,  true ],
    'Onyc':                  [true,  true,  true,  false, false, false],
    'Ossidon':               [true,  true,  true,  true,  true,  true ],
    'Otter':                 [true,  true,  true,  false, false, false],
    'Otter Aberrant':        [true,  true,  true,  false, false, false],
    'Oviraptor':             [true,  true,  true,  true,  false, false],
    'Oviraptor Aberrant':    [true,  true,  true,  true,  false, false],
    'Ovis':                  [true,  true,  true,  false, false, false],
    'Ovis Aberrant':         [true,  true,  true,  false, false, false],
    // ── P ─────────────────────────────────────────────────────────────
    'Pachyrhinosaurus':      [true,  true,  true,  true,  false, false],
    'Paraceratherium':       [true,  true,  true,  false, false, false],
    'Paraceratherium Aberrant':[true,true,  true,  false, false, false],
    'Parasaur':              [true,  true,  true,  true,  false, false],
    'Parasaur Aberrant':     [true,  true,  true,  true,  false, false],
    'Parasaur Tek':          [true,  true,  true,  true,  false, false],
    'Pegomastax':            [true,  true,  true,  false, false, false],
    'Pelagornis':            [true,  true,  true,  false, false, false],
    'Phoenix':               [true,  true,  true,  false, false, false],
    'Piranha':               [true,  true,  false, false, false, false],
    'Piranha Aberrant':      [true,  true,  false, false, false, false],
    'Plesiosaur':            [true,  true,  true,  false, false, false],
    'Poison Wyvern':         [true,  true,  true,  false, false, false],
    'Procoptodon':           [true,  true,  true,  true,  false, false],
    'Pteranodon':            [true,  true,  true,  true,  false, false],
    'Pulmonoscorpius':       [true,  true,  false, false, false, false],
    'Pulmonoscorpius Aberrant':[true,true,  false, false, false, false],
    'Purlovia':              [true,  true,  true,  false, false, false],
    'Purlovia Aberrant':     [true,  true,  true,  false, false, false],
    'Pyromane':              [true,  true,  true,  true,  true,  true ],
    // ── Q ─────────────────────────────────────────────────────────────
    'Quetzal':               [true,  true,  true,  true,  true,  true ],
    'Quetzal Tek':           [true,  true,  true,  true,  true,  true ],
    // ── R ─────────────────────────────────────────────────────────────
    'Raptor':                [true,  true,  true,  true,  true,  false],
    'Raptor Aberrant':       [true,  true,  true,  true,  true,  false],
    'Raptor Tek':            [true,  true,  true,  true,  true,  false],
    'Ravager':               [true,  true,  true,  true,  true,  false],
    'Reaper King':           [true,  true,  true,  true,  false, false],
    'Rex':                   [true,  true,  true,  true,  false, false],
    'Rex Tek':               [true,  true,  true,  true,  false, false],
    'Rhyniognatha':          [true,  true,  true,  true,  true,  false],
    'Rhyniognatha Drone':    [true,  true,  true,  true,  true,  false],
    'Rock Drake':            [true,  true,  true,  true,  true,  true ],
    'Rock Elemental':        [true,  true,  false, false, false, false],
    'Roll Rat':              [true,  true,  true,  true,  false, false],
    'Rubble Golem':          [true,  true,  false, false, false, false],
    // ── S ─────────────────────────────────────────────────────────────
    'Sabertooth':            [true,  true,  true,  true,  false, false],
    'Sabertooth Salmon':     [true,  true,  false, false, false, false],
    'Salmon Aberrant':       [true,  true,  false, false, false, false],
    'Sarco':                 [true,  true,  true,  false, false, false],
    'Sarco Aberrant':        [true,  true,  true,  false, false, false],
    'Shastasaurus':          [true,  true,  false, false, false, false],
    'Shinehorn':             [true,  true,  true,  true,  true,  false],
    'Snow Owl':              [true,  true,  true,  true,  false, false],
    'Solwyn':                [true,  true,  true,  true,  true,  true ],
    'Spino':                 [true,  true,  true,  true,  false, false],
    'Spino Aberrant':        [true,  true,  true,  true,  false, false],
    'Stegosaurus':           [true,  true,  true,  true,  false, false],
    'Stegosaurus Aberrant':  [true,  true,  true,  true,  false, false],
    'Stegosaurus Tek':       [true,  true,  true,  true,  false, false],
    // ── T ─────────────────────────────────────────────────────────────
    'Tapejara':              [true,  true,  true,  true,  false, false],
    'Terror Bird':           [true,  true,  true,  true,  false, false],
    'Therizinosaur':         [true,  true,  true,  true,  true,  true ],
    'Thorny Dragon':         [true,  true,  true,  false, false, false],
    'Thylacoleo':            [true,  true,  true,  true,  false, false],
    'Titanoboa':             [true,  true,  true,  false, false, false],
    'Titanoboa Aberrant':    [true,  true,  true,  false, false, false],
    'Triceratops':           [true,  true,  true,  true,  false, false],
    'Triceratops Aberrant':  [true,  true,  true,  true,  false, false],
    'Triceratops Tek':       [true,  true,  true,  true,  false, false],
    'Troodon':               [true,  true,  true,  true,  false, false],
    'Tusoteuthis':           [true,  true,  false, false, false, false],
    // ── V ─────────────────────────────────────────────────────────────
    'Veilwyn':               [true,  true,  true,  true,  true,  true ],
    'Velonasaur':            [true,  true,  true,  true,  true,  false],
    'Vulture':               [true,  true,  true,  false, false, false],
    // ── W ─────────────────────────────────────────────────────────────
    'Woolly Rhino':          [true,  true,  true,  true,  false, false],
    // ── X ─────────────────────────────────────────────────────────────
    'Xiphactinus':           [true,  true,  false, false, false, false],
    // ── Y ─────────────────────────────────────────────────────────────
    'Yi Ling':               [true,  true,  true,  true,  true,  true ],
    'Yutyrannus':            [true,  true,  true,  true,  false, false],
    // ── Z ─────────────────────────────────────────────────────────────
    'Zombie Fire Wyvern':    [true,  true,  true,  false, false, false],
    'Zombie Lightning Wyvern':[true, true,  true,  false, false, false],
    'Zombie Poison Wyvern':  [true,  true,  true,  false, false, false],
  };

  /// Noms des régions ARK (0-5)
  static const List<String> regionNames = [
    'Région 0', 'Région 1', 'Région 2',
    'Région 3', 'Région 4', 'Région 5',
  ];

  /// Retourne la liste des 6 booléens de visibilité pour une espèce.
  /// Si l'espèce est inconnue, toutes les régions sont visibles par défaut.
  static List<bool> visibilityFor(String species) {
    // Recherche exacte
    final exact = _data[species];
    if (exact != null) return exact;

    // Recherche insensible à la casse
    final lower = species.toLowerCase();
    for (final entry in _data.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }

    // Défaut : tout visible
    return [true, true, true, true, true, true];
  }

  /// Nombre de régions visibles pour une espèce
  static int visibleCount(String species) =>
      visibilityFor(species).where((v) => v).length;

  /// Retourne true si la région [index] est visible pour cette espèce
  static bool isVisible(String species, int region) {
    final vis = visibilityFor(species);
    if (region < 0 || region >= vis.length) return false;
    return vis[region];
  }
}
