// lib/models/ark_species_group.dart
// Groupe d'espèce ARK — détermine le fond interactif de la DinoCard.
// Trois groupes : terrestre (défaut), aquatique, volant.
// L'utilisateur pourra ajuster manuellement les assignations ici.

enum ArkSpeciesGroup { terrestre, aquatic, volant }

class ArkSpeciesGroupData {
  // ─── API publique ─────────────────────────────────────────────────────────
  /// Retourne le groupe d'une espèce. Défaut = terrestre si inconnue.
  static ArkSpeciesGroup groupFor(String species) =>
      _data[species] ?? ArkSpeciesGroup.terrestre;

  /// Emoji représentant le groupe
  static String groupEmoji(ArkSpeciesGroup g) {
    switch (g) {
      case ArkSpeciesGroup.terrestre: return '🦕';
      case ArkSpeciesGroup.aquatic:   return '🌊';
      case ArkSpeciesGroup.volant:    return '🦅';
    }
  }

  /// Label lisible du groupe
  static String groupLabel(ArkSpeciesGroup g) {
    switch (g) {
      case ArkSpeciesGroup.terrestre: return 'Terrestre';
      case ArkSpeciesGroup.aquatic:   return 'Aquatique';
      case ArkSpeciesGroup.volant:    return 'Volant';
    }
  }

  // ─── Table d'assignation espèce → groupe ──────────────────────────────────
  // À compléter manuellement selon les besoins.
  // Toute espèce absente de cette map est considérée comme Terrestre.
  static const Map<String, ArkSpeciesGroup> _data = {

    // ══════════════════════════════════════════════════════
    // AQUATIQUES
    // ══════════════════════════════════════════════════════
    'Anglerfish':           ArkSpeciesGroup.aquatic,
    'Anglerfish Aberrant':  ArkSpeciesGroup.aquatic,
    'Archelon':             ArkSpeciesGroup.aquatic,
    'Basilosaurus':         ArkSpeciesGroup.aquatic,
    'Cnidaria':             ArkSpeciesGroup.aquatic,
    'Coelacanth':           ArkSpeciesGroup.aquatic,
    'Coelacanth Aberrant':  ArkSpeciesGroup.aquatic,
    'Dunkleosteus':         ArkSpeciesGroup.aquatic,
    'Electrophorus':        ArkSpeciesGroup.aquatic,
    'Electrophorus Aberrant': ArkSpeciesGroup.aquatic,
    'Helicoprion':          ArkSpeciesGroup.aquatic,
    'Ichthyosaurus':        ArkSpeciesGroup.aquatic,
    'Liopleurodon':         ArkSpeciesGroup.aquatic,
    'Manta':                ArkSpeciesGroup.aquatic,
    'Manta Aberrant':       ArkSpeciesGroup.aquatic,
    'Megalodon':            ArkSpeciesGroup.aquatic,
    'Mosasaurus':           ArkSpeciesGroup.aquatic,
    'Piranha':              ArkSpeciesGroup.aquatic,
    'Piranha Aberrant':     ArkSpeciesGroup.aquatic,
    'Plesiosaur':           ArkSpeciesGroup.aquatic,
    'Sabertooth Salmon':    ArkSpeciesGroup.aquatic,
    'Salmon Aberrant':      ArkSpeciesGroup.aquatic,
    'Shastasaurus':         ArkSpeciesGroup.aquatic,
    'Tusoteuthis':          ArkSpeciesGroup.aquatic,
    'Xiphactinus':          ArkSpeciesGroup.aquatic,

    // Semi-aquatiques — classés aquatique car principalement dans l'eau
    'Baryonyx':             ArkSpeciesGroup.aquatic,
    'Baryonyx Aberrant':    ArkSpeciesGroup.aquatic,
    'Deinosuchus':          ArkSpeciesGroup.aquatic,
    'Diplocaulus':          ArkSpeciesGroup.aquatic,
    'Diplocaulus Aberrant': ArkSpeciesGroup.aquatic,
    'Hesperornis':          ArkSpeciesGroup.aquatic,
    'Kaprosuchus':          ArkSpeciesGroup.aquatic,
    'Sarco':                ArkSpeciesGroup.aquatic,
    'Sarco Aberrant':       ArkSpeciesGroup.aquatic,

    // ══════════════════════════════════════════════════════
    // VOLANTS
    // ══════════════════════════════════════════════════════
    'Argentavis':           ArkSpeciesGroup.volant,
    'Archaeopteryx':        ArkSpeciesGroup.volant,
    'Aureliax':             ArkSpeciesGroup.volant,
    'Dimorphodon':          ArkSpeciesGroup.volant,
    'Dimorphodon Aberrant': ArkSpeciesGroup.volant,
    'Drakeling (Autumn)':   ArkSpeciesGroup.volant,
    'Drakeling (Spring)':   ArkSpeciesGroup.volant,
    'Drakeling (Summer)':   ArkSpeciesGroup.volant,
    'Drakeling (Winter)':   ArkSpeciesGroup.volant,
    'Dreadmare':            ArkSpeciesGroup.volant,
    'Elderclaw':            ArkSpeciesGroup.volant,
    'Fire Wyvern':          ArkSpeciesGroup.volant,
    'Gasbags':              ArkSpeciesGroup.volant,
    'Gigadesmodus':         ArkSpeciesGroup.volant,
    'Griffin':              ArkSpeciesGroup.volant,
    'Ice Wyvern':           ArkSpeciesGroup.volant,
    'Ichthyornis':          ArkSpeciesGroup.volant,
    'Lightning Wyvern':     ArkSpeciesGroup.volant,
    'Lymantria':            ArkSpeciesGroup.volant,
    'Maeguana':             ArkSpeciesGroup.volant,
    'Malwyn':               ArkSpeciesGroup.volant,
    'Managarmr':            ArkSpeciesGroup.volant,
    'Onyc':                 ArkSpeciesGroup.volant,
    'Pelagornis':           ArkSpeciesGroup.volant,
    'Phoenix':              ArkSpeciesGroup.volant,
    'Poison Wyvern':        ArkSpeciesGroup.volant,
    'Pteranodon':           ArkSpeciesGroup.volant,
    'Quetzal':              ArkSpeciesGroup.volant,
    'Quetzal Tek':          ArkSpeciesGroup.volant,
    'Rock Drake':           ArkSpeciesGroup.volant,
    'Snow Owl':             ArkSpeciesGroup.volant,
    'Solwyn':               ArkSpeciesGroup.volant,
    'Tapejara':             ArkSpeciesGroup.volant,
    'Veilwyn':              ArkSpeciesGroup.volant,
    'Yi Ling':              ArkSpeciesGroup.volant,
    'Zombie Fire Wyvern':   ArkSpeciesGroup.volant,
    'Zombie Lightning Wyvern': ArkSpeciesGroup.volant,
    'Zombie Poison Wyvern': ArkSpeciesGroup.volant,

    // Desmodus vole, mais chasse aussi au sol — volant
    'Desmodus':             ArkSpeciesGroup.volant,

    // ══════════════════════════════════════════════════════
    // TERRESTRES (explicites — le reste est terrestre par défaut)
    // ══════════════════════════════════════════════════════
    // (listés ici pour documentation ; le lookup retourne terrestre si absent)
    'Rex':              ArkSpeciesGroup.terrestre,
    'Rex Tek':          ArkSpeciesGroup.terrestre,
    'Raptor':           ArkSpeciesGroup.terrestre,
    'Raptor Aberrant':  ArkSpeciesGroup.terrestre,
    'Raptor Tek':       ArkSpeciesGroup.terrestre,
    'Giganotosaurus':   ArkSpeciesGroup.terrestre,
  };
}
