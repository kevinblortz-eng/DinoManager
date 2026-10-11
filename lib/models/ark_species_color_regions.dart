// lib/models/ark_species_color_regions.dart
// Données de visibilité des 6 régions de couleur ARK par espèce.
// Source : JSON officiel ARK Survival Ascended fourni + estimations pour variantes.
// true  = région visible sur le modèle 3D
// false = région invisible (pas de coloration affichée)
// Ordre : [R0, R1, R2, R3, R4, R5]
//
// NOTE : Les espèces marquées "// Verif" sont absentes de la référence JSON
// fournie — leurs valeurs sont des estimations ou des héritages depuis la
// version de base (cas des variantes Aberrant / Tek / Alpha / Zombie /
// déclinaisons saisonnières). À valider individuellement.

class ArkSpeciesColorRegions {
  /// Régions visibles par espèce (clé = nom exact de l'espèce dans l'app).
  /// Si une espèce est absente, on retourne [true,true,true,true,true,true] par défaut.
  static const Map<String, List<bool>> _data = {
    // ── A ─────────────────────────────────────────────────────────────
    'Achatina':                [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Achatina Aberrant':       [true,  true,  false, true,  true,  true ], // Verif (hérité d'Achatina)
    'Acrocanthosaurus':        [true,  true,  false,  false,  true,  true ], 
    'Allosaurus':              [true,  false, false, true,  true,  true ], // Corrigé JSON
    'Ammonite':                [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Anglerfish':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Anglerfish Aberrant':     [true,  false, false, false, true,  true ], // Verif (hérité d'Anglerfish)
    'Ankylosaurus':            [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Ankylosaurus Aberrant':   [true,  true,  true,  true,  true,  true ], // Verif (hérité d'Ankylosaurus)
    'Araneo':                  [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Araneo Aberrant':         [true,  false, true,  true,  true,  true ], // Verif (hérité d'Araneo)
    'Archaeopteryx':           [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Archelon':                [true,  true,  false, true,  true,  false ], 
    'Argentavis':              [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Armadoggo':               [true,  true,  true,  true, true,  false ], 
    'Arthropluera':            [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Arthropluera Aberrant':   [true,  true,  true,  true,  true,  true ], // Verif (hérité d'Arthropluera)
    'Astrocetus':              [true,  true,  true,  false, true,  true ], 
    'Aureliax':                [true,  true,  true,  false,  true,  true ], 

    // ── B ─────────────────────────────────────────────────────────────
    'Baryonyx':                [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Baryonyx Aberrant':       [true,  true,  false, false, true,  true ], // Verif (hérité de Baryonyx)
    'Basilisk':                [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Basilosaurus':            [true,  false, false, false, false, true ], // Corrigé JSON
    'Beelzebufo':              [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Beelzebufo Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Beelzebufo)
    'Bison':                   [true,  true,  true,  true,  true, false], 
    'Boaratos':                  [true,  true,  true,  true,  true,  true ], // Verif 
    'Bloodstalker':            [true,  true,  false,  true, true,  false ], // Verif (absent du JSON)
    'Brontosaurus':            [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Bulbdog':                 [true,  false, true,  true,  true,  true ], //
    'Burrowbuck':              [true,  true,  true,  false, true,  true ], //Pelage 1 / oeil / petit pellage /corne / pellage avant / pellage arriere Corrigé JSON

    // ── C ─────────────────────────────────────────────────────────────
    'Carbonemys':              [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Carbonemys Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Carbonemys)
    'Carcharodontosaurus':     [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Carnotaurus':             [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Carnotaurus Aberrant':    [true,  true,  false, false, true,  true ], // Verif (hérité de Carnotaurus)
    'Castoroides':             [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Cat':                     [true,  false,  false,  false,  true, true], 
    'Ceratosaurus':            [true,  true,  false,  true, true,  true ], // Verif (ASA Addition)
    'Cerberax':                 [true,  true,  true,  true,  true,  true ], // attente
    'Chalicotherium':          [true,  false, false, false, true,  true ], 
    'Chalk Elemental':         [true,  true,  false, false, false, false], // Verif (absent du JSON)
    'Cnidaria':                [false, false, false, false, false, false], // Corrigé JSON
    'Coelacanth':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Coelacanth Aberrant':     [true,  false, false, false, true,  true ], // Verif (hérité de Coelacanth)
    'Compy':                   [true,  false, false, true,  true,  true ], // Corrigé JSON
    'Concavenator':                [true,  false, true, false, false,  true ], // Corrigé JSON
    'Cosmo':                   [true,  true,  true,  true, true,  true ], // zone id 4 lighterif (Bob's Tall Tales)
    'Cryolophosaurus':         [true,  true,  true,  true,  true,  true ], // Verif (absent du JSON)

    // ── D ─────────────────────────────────────────────────────────────
    'Daeodon':                 [true,  false, true,  false, false, true ], // Corrigé JSON
    'Deinonychus':             [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Deinosuchus':             [true,  false,  false,  false, true,  true ], 
    'Deinotherium':            [true,  true,  false,  false,  true, true], 
    'Desmodus':                [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Dilophosaur':             [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Dimetrodon':              [true,  true,  true,  true,  true,  false], // Corrigé JSON
    'Dimetrodon Aberrant':     [true,  true,  true,  true,  true,  false], // Verif (hérité de Dimetrodon)
    'Dimorphodon':             [true,  false, false, false, true,  true ], // Corrigé JSON
    'Dimorphodon Aberrant':    [true,  false, false, false, true,  true ], // Verif (hérité de Dimorphodon)
    'Diplocaulus':             [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Diplocaulus Aberrant':    [true,  true,  false, false, true,  true ], // Verif (hérité de Diplocaulus)
    'Diplodocus':              [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Diplodocus Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Diplodocus)
    'Dire Bear':               [true,  false, false, false, false, true ], // Corrigé JSON
    'Dire Bear Aberrant':      [true,  false, false, false, false, true ], // Verif (hérité de Dire Bear)
    'Dire Polar Bear':         [true,  false, false, false, false, true ], // Verif (variante de Dire Bear)
    'Direwolf':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Dodo':                    [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Dodo Aberrant':           [true,  true,  true,  true,  true,  true ], // Verif (hérité de Dodo)
    'Doedicurus':              [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Doedicurus Aberrant':     [true,  true,  false, false, true,  true ], // Verif (hérité de Doedicurus)
    'Drakeling (Autumn)':      [true,  true,  true,  true,  true,  true ], 
    'Drakeling (Spring)':      [true,  true,  true,  true,  true,  true ], 
    'Drakeling (Summer)':      [true,  true,  true,  true,  true,  true ], 
    'Drakeling (Winter)':      [true,  true,  true,  true,  true,  true ], 
    'Dreadmare':               [true,  true,  true,  true,  true,  true ], // Verif (absent du JSON)
    'Dreadnoughtus':           [true,  true, false, false, true,  true,], // Verif (absent du JSON)
    'Dung Beetle':             [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Dung Beetle Aberrant':    [true,  true,  false, true,  true,  true ], // Verif (hérité de Dung Beetle)
    'Dunkleosteus':            [true,  false, false, false, true,  true ], // Corrigé JSON

    // ── E ─────────────────────────────────────────────────────────────
    'Elderclaw':               [true,  true,  true,  true,  true,  true ], // Verif (absent du JSON)
    'Electrophorus':           [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Electrophorus Aberrant':  [true,  true,  true,  true,  true,  true ], // Verif (hérité d'Electrophorus)
    'Enforcer':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Equus':                   [true,  false, false, false, true,  true ], // Corrigé JSON
    'Equus Aberrant':          [true,  false, false, false, true,  true ], // Verif (hérité d'Equus)
    'Eurypterid':              [true,  true,  true,  true,  true,  true ], // Corrigé JSON

    // ── F ─────────────────────────────────────────────────────────────
    'Fasolasuchus':            [true,  true,  true,  false, true,  true ], 
    'Fasolasuchus Aberrant':   [true,  true,  true,  false, true,  true ], // Verif (hérité de Fasolasuchus)
    'Featherlight':            [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Ferox':                   [true,  true,  false,  false, true,  true ], 
    'Fire Wyvern':             [true,  false, true,  false, true,  true ], // Corrigé JSON

    // ── G ─────────────────────────────────────────────────────────────
    'Gacha':                   [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Gallimimus':              [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Gargantar':                [true,  true,  true,  true,  true,  true ], // Verif (absent du JSON)
    'Gasbags':                 [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Giant Bee':               [true,  false, true,  false, false, true ], // Corrigé JSON
    'Giant Queen Bee':         [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Gigadesmodus':            [true,  true,  true,  true,  true,  false], // Verif (absent du JSON)
    'Giganotosaurus':          [true,  false, false, false, true,  true ], // Corrigé JSON
    'Giganotosaurus Tek':      [true,  true, true,true, true,  true ],
    'Gigantopithecus':         [true,  false, false, false, true,  true ], // Corrigé JSON
    'Gigantopithecus Aberrant':[true,  false, false, false, true,  true ], // Verif (hérité de Gigantopithecus)
    'Gigantoraptor':           [true,  true,  true,  true,  true,  true ], // Verif (ASA Addition)
    'Gigantoraptor Aberrant':  [true,  true,  true,  true,  true,  true ], // Verif (hérité de Gigantoraptor)
    'Gloon':                   [true,  true,  true,  false,  true,  false], 
    'Glowbug':                 [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Glowtail':                [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Grand Tortugar':          [true,  false,  true,  true,  true,  true ], // Verif (absent du JSON)
    'Griffin':                 [true,  false, false, false, true,  true ], // Corrigé JSON

    // ── H ─────────────────────────────────────────────────────────────
    'Helicoprion':             [true,  false, false, false,  true,  true], 
    'Hesperornis':             [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Hyaenodon':               [true,  false, false, false, true,  true ], // Verif (absent du JSON)

    // ── I ─────────────────────────────────────────────────────────────
    'Ice Elemental':           [true,  true,  false, false, false, false], // Verif (absent du JSON)
    'Ice Wyvern':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Ichthyornis':             [true,  true,  false, false, false, true ], // Corrigé JSON
    'Ichthyosaurus':           [true,  false, false, false, true,  true ], // Corrigé JSON
    'Iguanodon':               [true,  false, false, false, true,  true ], // Corrigé JSON
    'Iguanodon Aberrant':      [true,  false, false, false, true,  true ], // Verif (hérité d'Iguanodon)

    // ── J ─────────────────────────────────────────────────────────────
    'Jerboa':                  [true,  false, false, false, true,  true ], // Corrigé JSON

    // ── K ─────────────────────────────────────────────────────────────
    'Kairuku':                 [true,  true,  true,  false, true,  false], // Corrigé JSON
    'Kaprosuchus':             [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Karkinos':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Kentrosaurus':            [true,  true,  true,  true,  true,  true ], // Corrigé JSON

    // ── L ─────────────────────────────────────────────────────────────
    'Lamprey':                 [false, false, false, false, false, false], // Corrigé JSON
    'Lava Elemental':          [true,  false, false, false, false,  true], // Verif (absent du JSON)
    'Leech':                   [false, false, false, false, false, false], // Corrigé JSON
    'Leedsichthys':            [true,  false, false, false, true,  true ], // Corrigé JSON
    'Lightning Wyvern':        [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Liopleurodon':            [true,  false, false, false, true,  true ], // Corrigé JSON
    'Lumina':                    [true,  true,  true,  true,  true,  true ], // Verif (absent du JSON)
    'Lymantria':               [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Lystrosaurus':            [true,  false, false, false, true,  true ], // Corrigé JSON
    'Lystrosaurus Aberrant':   [true,  false, false, false, true,  true ], // Verif (hérité de Lystrosaurus)

    // ── M ─────────────────────────────────────────────────────────────
    'Maeguana':                [true,  true,  true,  true,  true,  true], 
    'Maewing':                 [true,  true,  true,  true,  true,  true], 
    'Magmasaur':               [true,  true,  true,  false, true,  true ], // Verif (absent du JSON)
    'Malwyn':                  [true,  false,  true,  false,  false,  true ], 
    'Mammoth':                 [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Managarmr':               [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Manta':                   [true,  true,  false, false, true,  false], // Corrigé JSON
    'Manta Aberrant':          [true,  true,  false, false, true,  false], // Verif (hérité de Manta)
    'Mantis':                  [true,  false, false, false, true,  true ], // Corrigé JSON
    'Megachelon':              [true,  true,  true,  false, true,  true ], // Verif (absent du JSON)
    'Megalania':               [true,  false, false, false, true,  true ], // Corrigé JSON
    'Megalania Aberrant':      [true,  false, false, false, true,  true ], // Verif (hérité de Megalania)
    'Megaloceros':             [true,  false, true,  false, true,  false], // Corrigé JSON
    'Megalodon':               [true,  false, false, false, true,  true ], // Corrigé JSON
    'Megalosaurus':            [true,  false, false, false, true,  true ], // Corrigé JSON
    'Megalosaurus Aberrant':   [true,  false, false, false, true,  true ], // Verif (hérité de Megalosaurus)
    'Meganeura':               [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Meganeura Aberrant':      [true,  false, true,  true,  true,  true ], // Verif (hérité de Meganeura)
    'Megaraptor':              [true,  false,  true,  true,  false,  true ], 
    'Megatherium':             [true,  false, false, false, false, true ], // Corrigé JSON
    'Mesopithecus':            [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Microraptor':             [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Morellatops':             [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Mosasaurus':              [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Moschops':                [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Moschops Aberrant':       [true,  true,  true,  true,  true,  true ], // Verif (hérité de Moschops)

    // ── N ─────────────────────────────────────────────────────────────
    'Nameless':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Neophyte':                [true,  true,  true,  true,  true,  false], // Verif (absent du JSON)

    // ── O ─────────────────────────────────────────────────────────────
    'Oasisaur':                [true,  true,  true,  true, true,  true ], 
    'Onyc':                    [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Ossidon':                 [true,  false,  true,  true,  true,  true ], 
    'Otter':                   [true,  false, false, false, true,  true ], // Corrigé JSON
    'Otter Aberrant':          [true,  false, false, false, true,  true ], // Verif (hérité d'Otter)
    'Oviraptor':               [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Oviraptor Aberrant':      [true,  true,  true,  false, true,  true ], // Verif (hérité d'Oviraptor)
    'Ovis':                    [true,  false, false, false, true,  true ], // Corrigé JSON
    'Ovis Aberrant':           [true,  false, false, false, true,  true ], // Verif (hérité d'Ovis)

    // ── P ─────────────────────────────────────────────────────────────
    'Pachy':                   [true,  false, false, true,  true,  true ], // Corrigé JSON
    'Pachyrhinosaurus':        [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Palaeoctopus':            [true,  true,  true,  true,  true,  true ], // Verif
    'Paraceratherium':         [true,  false, false, false, true,  true ], // Corrigé JSON
    'Paraceratherium Aberrant':[true,  false, false, false, true,  true ], // Verif (hérité de Paraceratherium)
    'Parasaur':                [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Parasaur Aberrant':       [true,  true,  true,  true,  true,  true ], // Verif (hérité de Parasaur)
    'Parasaur Tek':            [true,  true,  true,  true,  true,  true ], // Verif (hérité de Parasaur)
    'Pegomastax':              [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Pelagornis':              [true,  false, false, false, false, true ], // Corrigé JSON
    'Phiomia':                 [true,  false, false, false, true,  true ], // Corrigé JSON
    'Phoenix':                 [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Piranha':                 [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Piranha Aberrant':        [true,  true,  true,  false, true,  true ], // Verif (hérité de Piranha)
    'Plesiosaur':              [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Poison Wyvern':           [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Procoptodon':             [true,  false, false, false, true,  true ], // Corrigé JSON
    'Pteranodon':              [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Pulmonoscorpius':         [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Pulmonoscorpius Aberrant':[true,  true,  true,  true,  true,  true ], // Verif (hérité de Pulmonoscorpius)
    'Purlovia':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Purlovia Aberrant':       [true,  false, false, false, true,  true ], // Verif (hérité de Purlovia)
    'Pyromane':                [false,  false,  true, true, false, true ], // Verif (ASA Addition)

    // ── Q ─────────────────────────────────────────────────────────────
    'Quetzal':                 [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Quetzal Tek':             [true,  true,  true,  true,  true,  true ], // Verif (hérité de Quetzal)

    // ── R ─────────────────────────────────────────────────────────────
    'Raptor':                  [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Raptor Aberrant':         [true,  true,  false, true,  true,  true ], // Verif (hérité de Raptor)
    'Raptor Tek':              [true,  true,  false, true,  true,  true ], // Verif (hérité de Raptor)
    'Ravager':                 [true,  false, false, false, true,  true ], // Corrigé JSON
    'Reaper King':             [true,  false, true,  false, true,  true ], 
    'Rex':                     [true,  true,  false, false, true,  true ], // Corrigé JSON
    'Rex Tek':                 [true,  true,  false, false, true,  true ], // Verif (hérité de Rex)
    'Rhyniognatha':            [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Rhyniognatha Drone':      [true,  true,  true,  true,  true,  true ], // Verif (variante de Rhyniognatha)
    'Rock Drake':              [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Rock Elemental':          [false, true,  false, false, false, false], // Corrigé JSON
    'Roll Rat':                [true,  false, false, false, true,  true ], // Corrigé JSON
    'Rubble Golem':            [true,  true,  false, false, false, false], // Verif (absent du JSON)

    // ── S ─────────────────────────────────────────────────────────────
    'Sabertooth':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Sabertooth Salmon':       [true,  false, false, false, true,  true ], // Corrigé JSON
    'Salmon Aberrant':         [true,  false, false, false, true,  true ], // Verif (variante du Sabertooth Salmon)
    'Sarco':                   [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Sarco Aberrant':          [true,  false, true,  true,  true,  true ], // Verif (hérité de Sarco)
    'Scout':                   [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Seeker':                  [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Shadowmane':              [true,  false, true,  true,   true,  true ], 
    'Shastasaurus':            [true,  false,  true, false,  true, true], 
    'Shinehorn':               [true,  false, true,  true,  true,  true ], // Corrigé JSON
    'Snow Owl':                [true,  false, true,  false, true,  true ], // Corrigé (source ARK Wiki: région 3 non utilisée)
    'Solwyn':                  [true,  false,  true,  false,  true,  true ], 
    'Spino':                   [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Spino Aberrant':          [true,  true,  true,  false, true,  true ], // Verif (hérité de Spino)
    'Stegosaurus':             [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Stegosaurus Aberrant':    [true,  true,  true,  true,  true,  true ], // Verif (hérité de Stegosaurus)
    'Stegosaurus Tek':         [true,  true,  true,  true,  true,  true ], // Verif (hérité de Stegosaurus)

    // ── T ─────────────────────────────────────────────────────────────
    'Tapejara':                [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Terror Bird':             [true,  false, false, false, true,  true ], // Corrigé JSON
    'Therizinosaur':           [true,  false, true,  false, true,  true ], // Corrigé JSON
    'Thorny Dragon':           [true,  true,  true,  false, true,  true ], // Corrigé JSON
    'Thylacoleo':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Titanoboa':               [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Titanoboa Aberrant':      [true,  true,  true,  true,  true,  true ], // Verif (hérité de Titanoboa)
    'Titanomyrma':             [true,  false, false, false, true,  true ], // Verif (absent du JSON)
    'Titanosaur':              [true,  false, false, false, true,  true ], // Corrigé JSON
    'Triceratops':             [true,  true,  false, true,  true,  true ], // Corrigé JSON
    'Triceratops Aberrant':    [true,  true,  false, true,  true,  true ], // Verif (hérité de Triceratops)
    'Triceratops Tek':         [true,  true,  false, true,  true,  true ], // Verif (hérité de Triceratops)
    'Trilobite':               [false, false, false, false, false, false], // Corrigé JSON
    'Troodon':                 [true,  false, false, false, true,  true ], // Corrigé JSON
    'Tusoteuthis':             [true,  true,  false, false, true,  true ], // Corrigé JSON

    // ── U ─────────────────────────────────────────────────────────────
    'Unicorn':                 [false, false, false, false, false, false], // Corrigé JSON

    // ── V ─────────────────────────────────────────────────────────────
    'Veilwyn':                 [true,  true,  false,  true,  true,  true ], 
    'Velonasaur':              [true,  true,  true,  true,  true,  true ], // Corrigé JSON
    'Vulture':                 [true,  true,  false, false, true,  true ], // Corrigé JSON

    // ── W ─────────────────────────────────────────────────────────────
    'Woolly Rhino':            [true,  true,  false, false, true,  true ], // Corrigé JSON

    // ── X ─────────────────────────────────────────────────────────────
    'Xiphactinus':             [true, false,false,  false, true,  true ], 
    'Xerabos':                  [true,  true,  false,  true,  true,  true ],

    // ── Y ─────────────────────────────────────────────────────────────
    'Yi Ling':                 [true,  true,  false,  true,  true,  true ], 
    'Yutyrannus':              [true,  true,  false, false, true,  true ], // Corrigé JSON

    // ── Z ─────────────────────────────────────────────────────────────
    'Zombie Fire Wyvern':      [true,  true,  false, true, false, true ], // Verif (hérité de Fire Wyvern)
    'Zombie Lightning Wyvern':  [true,  true,  false, true, false, true ], // Verif (hérité de Lightning Wyvern)
    'Zombie Poison Wyvern':     [true,  true,  false, true, false, true ], // Verif (hérité de Poison Wyvern)
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
