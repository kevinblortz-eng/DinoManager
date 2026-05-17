// lib/models/ark_species_color_regions.dart
// Données de visibilité des 6 régions de couleur ARK par espèce.
// Source : référence C# ARK Stats Extractor (ARKpedia / ARK wiki).
// true  = région visible sur le modèle 3D
// false = région invisible (pas de coloration affichée)
// Ordre : [R0, R1, R2, R3, R4, R5]
//
// NOTE : Les espèces marquées "// Verif" sont absentes de la référence C#
// fournie — leurs valeurs sont des estimations ou des héritages depuis la
// version de base (cas des variantes Aberrant / Tek / Alpha / Zombie /
// déclinaisons saisonnières). À valider individuellement.

class ArkSpeciesColorRegions {
  /// Régions visibles par espèce (clé = nom exact de l'espèce dans l'app).
  /// Si une espèce est absente, on retourne [true,true,true,true,true,true] par défaut.
  static const Map<String, List<bool>> _data = {
    // ── A ─────────────────────────────────────────────────────────────
    'Achatina':                [true,  true,  true,  true,  true,  true ],
    'Achatina Aberrant':       [true,  true,  true,  true,  true,  true ], // Verif (hérité d'Achatina, absent de la ref)
    'Acrocanthosaurus':        [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Allosaurus':              [true,  false, false,  false, true,  true ],
    'Ammonite':                [true,  false, false, false, false, false],
    'Anglerfish':              [true,  true,  false, false, true,  true ],
    'Anglerfish Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité d'Anglerfish, absent de la ref)
    'Ankylosaurus':            [true,  false, true,  false, true,  false],
    'Ankylosaurus Aberrant':   [true,  false, true,  false, true,  false], // Verif (hérité d'Ankylosaurus, absent de la ref)
    'Araneo':                  [true,  true,  false, false, true,  true ],
    'Araneo Aberrant':         [true,  true,  false, false, true,  true ], // Verif (hérité d'Araneo, absent de la ref)
    'Archaeopteryx':           [true,  false, true,  false, true,  true ],
    'Archelon':                [true,  true,  false,  true,  true, true], 
    'Argentavis':              [true,  false, true,  true,  true,  true ],
    'Armadoggo':               [true,  true,  true,  false, true,  true ], // Verif (Bob's Tall Tales — à valider)
    'Arthropluera':            [true,  true,  false, false, true,  true ],
    'Arthropluera Aberrant':   [true,  true,  false, false, true,  true ], // Verif (hérité d'Arthropluera, absent de la ref)
    'Astrocetus':              [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Aureliax':                [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)

    // ── B ─────────────────────────────────────────────────────────────
    'Baryonyx':                [true,  true,  true,  false, true,  true ],
    'Baryonyx Aberrant':       [true,  true,  true,  false, true,  true ], // Verif (hérité de Baryonyx, absent de la ref)
    'Basilisk':                [true,  true,  true,  false, true,  true ],
    'Basilosaurus':            [true,  false, true,  false, true,  false],
    'Beelzebufo':              [true,  true,  false, false, true,  true ],
    'Beelzebufo Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Beelzebufo, absent de la ref)
    'Bison':                   [true,  true,  true,  true,  false, false], // Verif (absent de la ref)
    'Bloodstalker':            [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Brontosaurus':            [true,  true,  false, false, true,  true ],
    'Bulbdog':                 [true,  false, true,  false, true,  true ],

    // ── C ─────────────────────────────────────────────────────────────
    'Carbonemys':              [true,  true,  true,  false, true,  true ],
    'Carbonemys Aberrant':     [true,  true,  true,  false, true,  true ], // Verif (hérité de Carbonemys, absent de la ref)
    'Carcharodontosaurus':     [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Carnotaurus':             [true,  false, true,  false, true,  true ],
    'Carnotaurus Aberrant':    [true,  false, true,  false, true,  true ], // Verif (hérité de Carnotaurus, absent de la ref)
    'Castoroides':             [true,  false, true,  false, true,  false],
    'Cat':                     [true,  true,  true,  true,  false, false], // Verif (absent de la ref)
    'Ceratosaurus':            [true,  true,  true,  false, true,  true ], // Verif (ASA Addition — à valider)
    'Chalicotherium':          [true,  false, true,  false, true,  true ],
    'Chalk Elemental':         [true,  true,  false, false, false, false], // Verif (absent de la ref)
    'Cnidaria':                [true,  false, false, false, false, false],
    'Coelacanth':              [true,  false, true,  false, true,  true ],
    'Coelacanth Aberrant':     [true,  false, true,  false, true,  true ], // Verif (hérité de Coelacanth, absent de la ref)
    'Compy':                   [true,  false, true,  false, true,  true ], // (mappé sur Compsognathus de la ref)
    'Cosmo':                   [true,  true,  true,  false, true,  true ], // Verif (Bob's Tall Tales — à valider)
    'Cryolophosaurus':         [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)

    // ── D ─────────────────────────────────────────────────────────────
    'Daeodon':                 [true,  false, true,  false, true,  true ],
    'Deinonychus':             [true,  true,  false,  true, true,  true ],
    'Deinosuchus':             [true,  true,  true,  false, true,  true ], // Verif (ASA Addition — à valider)
    'Deinotherium':            [true,  true,  true,  true,  false, false], // Verif (absent de la ref)
    'Desmodus':                [true,  true,  true,  true,  true,  false], // Verif (absent de la ref)
    'Dimetrodon':              [true,  true,  false, false, true,  true ],
    'Dimetrodon Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Dimetrodon, absent de la ref)
    'Dimorphodon':             [true,  false, true,  false, true,  true ],
    'Dimorphodon Aberrant':    [true,  false, true,  false, true,  true ], // Verif (hérité de Dimorphodon, absent de la ref)
    'Diplocaulus':             [true,  false, true,  false, true,  true ],
    'Diplocaulus Aberrant':    [true,  false, true,  false, true,  true ], // Verif (hérité de Diplocaulus, absent de la ref)
    'Diplodocus':              [true,  false, true,  false, true,  true ],
    'Diplodocus Aberrant':     [true,  false, true,  false, true,  true ], // Verif (hérité de Diplodocus, absent de la ref)
    'Dire Bear':               [true,  false, true,  false, true,  true ], // (mappé sur Direbear de la ref)
    'Dire Bear Aberrant':      [true,  false, true,  false, true,  true ], // Verif (hérité de Direbear, absent de la ref)
    'Dire Polar Bear':         [true,  false, true,  false, true,  true ], // Verif (variante de Direbear, absent de la ref)
    'Direwolf':                [true,  false, true,  false, true,  true ],
    'Dodo':                    [true,  false, true,  false, true,  true ],
    'Dodo Aberrant':           [true,  false, true,  false, true,  true ], // Verif (hérité de Dodo, absent de la ref)
    'Doedicurus':              [true,  false, true,  false, true,  false],
    'Doedicurus Aberrant':     [true,  false, true,  false, true,  false], // Verif (hérité de Doedicurus, absent de la ref)
    'Drakeling (Autumn)':      [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Drakeling (Spring)':      [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Drakeling (Summer)':      [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Drakeling (Winter)':      [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Dreadmare':               [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Dreadnoughtus':           [true,  true,  true,  true,  false, false], // Verif (absent de la ref)
    'Dung Beetle':             [true,  true,  false, false, true,  false], // (mappé sur DungBeetle de la ref)
    'Dung Beetle Aberrant':    [true,  true,  false, false, true,  false], // Verif (hérité de DungBeetle, absent de la ref)
    'Dunkleosteus':            [true,  false, false,  false, true,  true ],

    // ── E ─────────────────────────────────────────────────────────────
    'Elderclaw':               [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Electrophorus':           [true,  false, true,  false, true,  true ],
    'Electrophorus Aberrant':  [true,  false, true,  false, true,  true ], // Verif (hérité d'Electrophorus, absent de la ref)
    'Enforcer':                [true,  true,  true,  false, true,  true ],
    'Equus':                   [true,  false, true,  false, true,  true ],
    'Equus Aberrant':          [true,  false, true,  false, true,  true ], // Verif (hérité d'Equus, absent de la ref)
    'Eurypterid':              [true,  true,  false, false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)

    // ── F ─────────────────────────────────────────────────────────────
    'Fasolasuchus':            [true,  true,  true,  false, true,  true ], // Verif (ASA Addition — à valider)
    'Fasolasuchus Aberrant':   [true,  true,  true,  false, true,  true ], // Verif (hérité de Fasolasuchus, absent de la ref)
    'Featherlight':            [true,  true,  true,  true,  true,  true ],
    'Ferox':                   [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Fire Wyvern':             [true,  true,  true,  false, true,  true ], // (mappé sur FireWyvern de la ref)

    // ── G ─────────────────────────────────────────────────────────────
    'Gacha':                   [true,  false, true,  false, true,  true ],
    'Gallimimus':              [true,  false, true,  false, true,  true ],
    'Gasbags':                 [true,  true,  true,  false, true,  true ],
    'GiantBee':                [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Gigadesmodus':            [true,  true,  true,  true,  true,  false], // Verif (absent de la ref)
    'Giganotosaurus':          [true,  false, true,  false, true,  true ],
    'Giganotosaurus Tek':      [true,  true, true,  true, true,  true ], // Verif (hérité de Giganotosaurus, absent de la ref)
    'Gigantopithecus':         [true,  false, true,  false, true,  true ],
    'Gigantopithecus Aberrant':[true,  false, true,  false, true,  true ], // Verif (hérité de Gigantopithecus, absent de la ref)
    'Gigantoraptor':           [true,  true,  true,  true,  true,  true ], // Verif (ASA Addition — à valider)
    'Gigantoraptor Aberrant':  [true,  true,  true,  true,  true,  true ], // Verif (hérité de Gigantoraptor, absent de la ref)
    'Gloon':                   [true,  true,  true,  true,  true,  false], // Verif (absent de la ref)
    'Glowtail':                [true,  true,  true,  false, true,  true ],
    'Grand Tortugar':          [true,  true,  true,  true,  false, false], // Verif (absent de la ref)
    'Grendel (Alpha)':         [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Griffin':                 [true,  false, true,  false, true,  true ],

    // ── H ─────────────────────────────────────────────────────────────
    'Helicoprion':             [true,  true,  true,  false, false, false], // Verif (absent de la ref)
    'Hesperornis':             [true,  false, true,  true,  true,  true ],
    'Hyaenodon':               [true,  false, true,  false, true,  true ],
    'Hydraskos the Unbroken':  [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)

    // ── I ─────────────────────────────────────────────────────────────
    'Ice Elemental':           [true,  true,  false, false, false, false], // Verif (absent de la ref)
    'Ice Wyvern':              [true,  true,  true,  false, true,  true ], // Verif (héritée des Wyverns, absent de la ref)
    'Ichthyornis':             [true,  false, true,  true,  true,  true ],
    'Ichthyosaurus':           [true,  false, true,  false, true,  true ],
    'Iguanodon':               [true,  true,  true,  false, true,  true ],
    'Iguanodon Aberrant':      [true,  true,  true,  false, true,  true ], // Verif (hérité d'Iguanodon, absent de la ref)

    // ── J ─────────────────────────────────────────────────────────────
    'Jerboa':                  [true,  false, true,  false, true,  true ],

    // ── K ─────────────────────────────────────────────────────────────
    'Kairuku':                 [true,  false, true,  false, true,  true ],
    'Kaprosuchus':             [true,  false, true,  false, true,  true ],
    'Karkinos':                [true,  false, true,  false, true,  true ],
    'Kentrosaurus':            [true,  false, true,  false, true,  true ],

    // ── L ─────────────────────────────────────────────────────────────
    'Lamprey':                 [true,  false, false, false, false, false], // (ajout depuis la ref — pas présent dans ton Dart)
    'Lava Elemental':          [true,  true,  false, false, false, false], // Verif (absent de la ref)
    'Leech':                   [true,  false, false, false, false, false], // (ajout depuis la ref — pas présent dans ton Dart)
    'Leedsichthys':            [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Lightning Wyvern':        [true,  true,  true,  false, true,  true ], // (mappé sur LightningWyvern de la ref)
    'Liopleurodon':            [true,  false, true,  false, true,  true ],
    'Lymantria':               [true,  true,  true,  false, true,  true ],
    'Lystrosaurus':            [true,  false, true,  false, true,  true ],
    'Lystrosaurus Aberrant':   [true,  false, true,  false, true,  true ], // Verif (hérité de Lystrosaurus, absent de la ref)

    // ── M ─────────────────────────────────────────────────────────────
    'Maeguana':                [true,  true,  true,  true,  true,  false], // Verif (absent de la ref)
    'Maewing':                 [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Magmasaur':               [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Malwyn':                  [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Mammoth':                 [true,  false, true,  false, true,  true ],
    'Managarmr':               [true,  true,  true,  false, true,  true ],
    'Manta':                   [true,  true,  false, false, true,  true ],
    'Manta Aberrant':          [true,  true,  false, false, true,  true ], // Verif (hérité de Manta, absent de la ref)
    'Mantis':                  [true,  false,  false,  false, true,  true ],
    'Megachelon':              [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Megalania':               [true,  false, true,  false, true,  true ],
    'Megalania Aberrant':      [true,  false, true,  false, true,  true ], // Verif (hérité de Megalania, absent de la ref)
    'Megaloceros':             [true,  false, true,  false, true,  true ],
    'Megalodon':               [true,  false, true,  false, true,  true ],
    'Megalosaurus':            [true,  true,  false, false, true,  true ],
    'Megalosaurus Aberrant':   [true,  true,  false, false, true,  true ], // Verif (hérité de Megalosaurus, absent de la ref)
    'Meganeura':               [true,  false, false, false, true,  true ],
    'Meganeura Aberrant':      [true,  false, false, false, true,  true ], // Verif (hérité de Meganeura, absent de la ref)
    'Megaraptor':              [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Megatherium':             [true,  false, true,  false, true,  true ],
    'Mesopithecus':            [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Microraptor':             [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Minotarchos':             [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Morellatops':             [true,  false, true,  false, true,  true ],
    'Mosasaurus':              [true,  false, true,  false, true,  true ],
    'Moschops':                [true,  false, true,  false, true,  true ],
    'Moschops Aberrant':       [true,  false, true,  false, true,  true ], // Verif (hérité de Moschops, absent de la ref)

    // ── N ─────────────────────────────────────────────────────────────
    'Neophyte':                [true,  true,  true,  true,  true,  false], // Verif (absent de la ref)

    // ── O ─────────────────────────────────────────────────────────────
    'Oasisaur':                [true,  true,  true,  false, true,  true ], // Verif (Bob's Tall Tales — à valider)
    'Onyc':                    [true,  false, false, false, true,  true ],
    'Ossidon':                 [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Otter':                   [true,  false, true,  false, true,  true ],
    'Otter Aberrant':          [true,  false, true,  false, true,  true ], // Verif (hérité d'Otter, absent de la ref)
    'Oviraptor':               [true,  false, true,  false, true,  true ],
    'Oviraptor Aberrant':      [true,  false, true,  false, true,  true ], // Verif (hérité d'Oviraptor, absent de la ref)
    'Ovis':                    [true,  false, true,  false, true,  true ],
    'Ovis Aberrant':           [true,  false, true,  false, true,  true ], // Verif (hérité d'Ovis, absent de la ref)

    // ── P ─────────────────────────────────────────────────────────────
    'Pachy':                   [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Pachyrhinosaurus':        [true,  true,  true,  false, true,  true ],
    'Paraceratherium':         [true,  false, true,  false, true,  true ],
    'Paraceratherium Aberrant':[true,  false, true,  false, true,  true ], // Verif (hérité de Paraceratherium, absent de la ref)
    'Parasaur':                [true,  true,  true,  false, true,  true ],
    'Parasaur Aberrant':       [true,  true,  true,  false, true,  true ], // Verif (hérité de Parasaur, absent de la ref)
    'Parasaur Tek':            [true,  true,  true,  false, true,  true ], // Verif (hérité de Parasaur, absent de la ref)
    'Pegomastax':              [true,  false, true,  false, true,  true ],
    'Pelagornis':              [true,  false, true,  true,  true,  true ],
    'Phiomia':                 [true,  false, true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Phoenix':                 [true,  true,  true,  false, true,  true ],
    'Piranha':                 [true,  false, true,  false, true,  true ],
    'Piranha Aberrant':        [true,  false, true,  false, true,  true ], // Verif (hérité de Piranha, absent de la ref)
    'Plesiosaur':              [true,  false, true,  false, true,  true ],
    'Poison Wyvern':           [true,  true,  true,  false, true,  true ], // (mappé sur PoisonWyvern de la ref)
    'Procoptodon':             [true,  false, true,  false, true,  true ],
    'Pteranodon':              [true,  true,  true,  false, true,  true ],
    'Pulmonoscorpius':         [true,  true,  false, false, true,  true ],
    'Pulmonoscorpius Aberrant':[true,  true,  false, false, true,  true ], // Verif (hérité de Pulmonoscorpius, absent de la ref)
    'Purlovia':                [true,  false, true,  false, true,  true ],
    'Purlovia Aberrant':       [true,  false, true,  false, true,  true ], // Verif (hérité de Purlovia, absent de la ref)
    'Pyromane':                [true,  true,  true,  false, true,  true ], // (ASA Addition — issu de la ref, à valider)

    // ── Q ─────────────────────────────────────────────────────────────
    'Quetzal':                 [true,  true,  true,  true,  true,  true ],
    'Quetzal Tek':             [true,  true,  true,  true,  true,  true ], // Verif (hérité de Quetzal, absent de la ref)

    // ── R ─────────────────────────────────────────────────────────────
    'Raptor':                  [true,  true,  true,  false, true,  true ],
    'Raptor Aberrant':         [true,  true,  true,  false, true,  true ], // Verif (hérité de Raptor, absent de la ref)
    'Raptor Tek':              [true,  true,  true,  false, true,  true ], // Verif (hérité de Raptor, absent de la ref)
    'Ravager':                 [true,  true,  true,  false, true,  true ],
    'Reaper King':             [true,  false, true,  false, true,  true ], // (mappé sur Reaper de la ref)
    'Rex':                     [true,  true,  false, false, true,  true ],
    'Rex Tek':                 [true,  true,  false, false, true,  true ], // Verif (hérité de Rex, absent de la ref)
    'Rhyniognatha':            [true,  true,  true,  false, true,  true ], // (ASA Addition — issu de la ref, à valider)
    'Rhyniognatha Drone':      [true,  true,  true,  false, true,  true ], // Verif (variante de Rhyniognatha, absent de la ref)
    'Rock Drake':              [true,  true,  true,  false, true,  true ], // (mappé sur RockDrake de la ref)
    'Rock Elemental':          [true,  false, false, false, true,  false], // (mappé sur RockElemental de la ref)
    'Roll Rat':                [true,  false, true,  false, true,  true ], // (mappé sur RollRat de la ref)
    'Rubble Golem':            [true,  true,  false, false, false, false], // Verif (absent de la ref)

    // ── S ─────────────────────────────────────────────────────────────
    'Sabertooth':              [true,  false, true,  false, true,  true ],
    'Sabertooth Salmon':       [true,  false, true,  false, true,  true ], // (mappé sur SabertoothSalmon de la ref)
    'Salmon Aberrant':         [true,  false, true,  false, true,  true ], // Verif (variante du SabertoothSalmon, absent de la ref)
    'Sarco':                   [true,  true,  true,  false, true,  true ],
    'Sarco Aberrant':          [true,  true,  true,  false, true,  true ], // Verif (hérité de Sarco, absent de la ref)
    'Seeker':                  [true,  false, false, false, true,  false], // (ajout depuis la ref — pas présent dans ton Dart)
    'Shadowmane':              [true,  true,  true,  false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Shastasaurus':            [true,  true,  false, false, false, false], // Verif (absent de la ref)
    'Shinehorn':               [true,  true,  true,  false, true,  true ],
    'Snow Owl':                [true,  true,  true,  true,  true,  true ], // (mappé sur SnowOwl de la ref)
    'Solwyn':                  [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Spino':                   [true,  false, true,  false, true,  true ], // (mappé sur Spinosaurus de la ref)
    'Spino Aberrant':          [true,  false, true,  false, true,  true ], // Verif (hérité de Spinosaurus, absent de la ref)
    'Stegosaurus':             [true,  false, true,  false, true,  true ],
    'Stegosaurus Aberrant':    [true,  false, true,  false, true,  true ], // Verif (hérité de Stegosaurus, absent de la ref)
    'Stegosaurus Tek':         [true,  false, true,  false, true,  true ], // Verif (hérité de Stegosaurus, absent de la ref)

    // ── T ─────────────────────────────────────────────────────────────
    'Tapejara':                [true,  true,  true,  true,  true,  true ],
    'Terror Bird':             [true,  false, true,  false, true,  true ], // (mappé sur TerrorBird de la ref)
    'Therizinosaur':           [true,  false, true,  false, true,  true ],
    'Thorny Dragon':           [true,  false, true,  false, true,  true ], // (mappé sur ThornyDragon de la ref)
    'Thylacoleo':              [true,  false, true,  false, true,  true ],
    'Titanoboa':               [true,  false, true,  false, true,  true ],
    'Titanoboa Aberrant':      [true,  false, true,  false, true,  true ], // Verif (hérité de Titanoboa, absent de la ref)
    'Titanomyrma':             [true,  false, false, false, true,  true ], // (ajout depuis la ref — pas présent dans ton Dart)
    'Triceratops':             [true,  false, true,  false, true,  true ],
    'Triceratops Aberrant':    [true,  false, true,  false, true,  true ], // Verif (hérité de Triceratops, absent de la ref)
    'Triceratops Tek':         [true,  false, true,  false, true,  true ], // Verif (hérité de Triceratops, absent de la ref)
    'Trilobite':               [true,  false, false, false, false, false], // (ajout depuis la ref — pas présent dans ton Dart)
    'Troodon':                 [true,  true,  true,  false, true,  true ],
    'Tusoteuthis':             [true,  true,  true,  false, true,  false],

    // ── V ─────────────────────────────────────────────────────────────
    'Veilwyn':                 [true,  true,  true,  true,  true,  true ], // Verif (absent de la ref)
    'Velonasaur':              [true,  true,  true,  false, true,  true ],
    'Vulture':                 [true,  false, true,  false, true,  true ],

    // ── W ─────────────────────────────────────────────────────────────
    'Woolly Rhino':            [true,  false, true,  false, true,  true ], // (mappé sur WoollyRhino de la ref)

    // ── X ─────────────────────────────────────────────────────────────
    'Xiphactinus':             [true,  true,  true,  false, true,  true ], // (ASA Addition — issu de la ref, à valider)

    // ── Y ─────────────────────────────────────────────────────────────
    'Yi Ling':                 [true,  true,  true,  true,  true,  true ], // (mappé sur YiLing de la ref — ASA Addition, à valider)
    'Yutyrannus':              [true,  false, true,  false, true,  true ],

    // ── Z ─────────────────────────────────────────────────────────────
    'Zombie Fire Wyvern':      [true,  true,  true,  false, true,  true ], // Verif (hérité de FireWyvern, absent de la ref)
    'Zombie Lightning Wyvern': [true,  true,  true,  false, true,  true ], // Verif (hérité de LightningWyvern, absent de la ref)
    'Zombie Poison Wyvern':    [true,  true,  true,  false, true,  true ], // Verif (hérité de PoisonWyvern, absent de la ref)
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
