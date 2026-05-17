// lib/screens/tracker/tabs/journal_tab_stats_max.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/dino.dart';
import '../../../models/species_tracker.dart';
import '../../../models/ark_species_stat.dart';
import '../../../utils/dino_helpers.dart';

class JournalTabStatsMax extends StatelessWidget {
  final String species;
  final List<Dino> dinos;
  final SpeciesTracker? tracker;

  const JournalTabStatsMax({
    super.key,
    required this.species,
    required this.dinos,
    this.tracker,
  });

  // ─── Référentiel stats ──────────────────────────────────────────────────
  static const _statKeys = [
    'hp', 'stamina', 'degats',
    'poids', 'nourriture', 'oxygene',
  ];
  static const _statLabels = {
    'hp': 'VIE',
    'stamina': 'STAM',
    'degats': 'ATTACK',
    'poids': 'POIDS',
    'nourriture': 'FOOD',
    'oxygene': 'OXY',
  };
  static const _statColors = {
    'hp': Color(0xFF4CAF50),
    'stamina': Color(0xFFFFD700),
    'degats': Color(0xFFEF4444),
    'poids': Color(0xFF3B82F6),
    'nourriture': Color(0xFF8B5CF6),
    'oxygene': Color(0xFF10B981),
  };
  static const _statEmojis = {
    'hp': '❤️',
    'stamina': '⚡',
    'degats': '⚔️',
    'poids': '⚖️',
    'nourriture': '🍖',
    'oxygene': '🫧',
  };

  // ════════════════════════════════════════════════════════════════════════
  // FUSION library + tracker → meilleure valeur + points max
  // ════════════════════════════════════════════════════════════════════════
  Map<String, _BestStat> _mergeBests() {
    final result = <String, _BestStat>{};

    for (final d in dinos) {
      _consider(result, 'hp', d.hp.toDouble(), d.hpPoints);
      _consider(result, 'stamina', d.stamina.toDouble(), d.staminaPoints);
      _consider(result, 'degats', d.degats, d.degatsPoints);
      _consider(result, 'poids', d.poids.toDouble(), d.poidsPoints);
      _consider(result, 'nourriture', d.nourriture.toDouble(), d.nourriturePoints);
      _consider(result, 'oxygene', d.oxygene.toDouble(), d.oxygenePoints);
    }

    final t = tracker;
    if (t != null) {
      t.bestStats.forEach((key, rec) {
        _consider(result, key, rec.value, rec.points ?? 0);
      });
      for (final e in t.anonymousStatEntries) {
        e.stats.forEach((key, val) => _consider(result, key, val, 0));
      }
    }
    return result;
  }

  void _consider(Map<String, _BestStat> map, String key, double v, int pts) {
    if (v <= 0 && pts <= 0) return;
    final cur = map[key];
    if (cur == null) {
      map[key] = _BestStat(value: v, points: pts);
    } else {
      map[key] = _BestStat(
        value: v > cur.value ? v : cur.value,
        points: pts > cur.points ? pts : cur.points,
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final bests = _mergeBests();
    final totalPoints = bests.values.fold<int>(0, (s, b) => s + b.points);

    // ⚠️ Typé en `dynamic` pour ne pas dépendre du nom exact de la classe.
    final dynamic baseStats = ArkSpeciesStatsDb.get(species);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTotalCard(totalPoints),
          const SizedBox(height: 14),
          // ── GRILLE 3×2 avec le MÊME rendu que dino_variant_screen ──────
          LayoutBuilder(
            builder: (context, constraints) {
              const int cols = 3;
              const int rows = 2;
              const double hGap = 8;
              const double vGap = 8;
              final cellW =
                  (constraints.maxWidth - hGap * (cols - 1)) / cols;
              // Hauteur de cellule un peu plus généreuse que la largeur
              // (comme dans la grille variant où vGap est respecté), ce qui
              // laisse 3 lignes lisibles (label / valeur / points).
              final cellH = cellW * 1.05;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows, (r) {
                  return Padding(
                    padding:
                        EdgeInsets.only(bottom: r == rows - 1 ? 0 : vGap),
                    child: Row(
                      children: List.generate(cols, (c) {
                        final i = r * cols + c;
                        final k = _statKeys[i];
                        return Padding(
                          padding: EdgeInsets.only(
                              right: c == cols - 1 ? 0 : hGap),
                          child: SizedBox(
                            width: cellW,
                            height: cellH,
                            child: _StatTile(
                              statKey: k,
                              label: _statLabels[k]!,
                              emoji: _statEmojis[k]!,
                              color: _statColors[k]!,
                              best: bests[k],
                              value: _resolveValue(k, bests[k], baseStats),
                              points: _resolvePoints(k, bests[k], baseStats),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Bandeau total cumulé ───────────────────────────────────────────────
  Widget _buildTotalCard(int total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withValues(alpha: 0.15),
            Colors.cyanAccent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ' Mes Meilleurs stats',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS résolution valeur & points (inchangés)
  // ════════════════════════════════════════════════════════════════════════
  String _resolveValue(String key, _BestStat? best, dynamic baseStats) {
    final v = best?.value ?? 0;
    final baseVal = _baseValueFor(key, baseStats);

    if (key == 'degats') {
      if (v > 0) return '${v.toStringAsFixed(0)}%';
      if (baseVal != null && baseVal > 0) {
        return '~${baseVal.toStringAsFixed(0)}%';
      }
      return '-';
    }

    if (v > 0) {
      return v == v.roundToDouble()
          ? DinoHelpers.formatNumber(v.round())
          : v.toStringAsFixed(1);
    }
    if (baseVal != null && baseVal > 0) {
      return '~${DinoHelpers.formatNumber(baseVal.round())}';
    }
    return '-';
  }

  int? _resolvePoints(String key, _BestStat? best, dynamic baseStats) {
    if (best == null) return null;
    if (best.points > 0) return best.points;
    if (best.value <= 0) return null;

    final baseVal = _baseValueFor(key, baseStats);
    if (baseVal == null || baseVal == 0) return null;

    final diff = best.value - baseVal;
    if (diff < 0) return -1;
    if (diff == 0) return 0;

    final divisor = key == 'degats' ? (baseVal * 0.05) : (baseVal * 0.1);
    final pts = (diff / divisor).round();
    return pts > 0 ? pts : 0;
  }

  double? _baseValueFor(String key, dynamic baseStats) {
    if (baseStats == null) return null;
    try {
      switch (key) {
        case 'hp':         return (baseStats.hp as num?)?.toDouble();
        case 'stamina':    return (baseStats.stamina as num?)?.toDouble();
        case 'degats':     return (baseStats.melee as num?)?.toDouble();
        case 'poids':      return (baseStats.weight as num?)?.toDouble();
        case 'nourriture': return (baseStats.food as num?)?.toDouble();
        case 'oxygene':    return (baseStats.oxygen as num?)?.toDouble();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class _BestStat {
  final double value;
  final int points;
  _BestStat({required this.value, required this.points});
}

// ═══════════════════════════════════════════════════════════════════════════
// TUILE — visuel STRICTEMENT identique à _StatCell du dino_variant_screen
// (fond noir 0.35, bordure colorée 0.35, 3 lignes 28% / 42% / 22%, FittedBox)
// ═══════════════════════════════════════════════════════════════════════════
class _StatTile extends StatelessWidget {
  final String statKey;
  final String label;
  final String emoji;
  final Color color;
  final _BestStat? best;
  final String value;
  final int? points;

  const _StatTile({
    required this.statKey,
    required this.label,
    required this.emoji,
    required this.color,
    required this.best,
    required this.value,
    required this.points,
  });

  bool get _hasData =>
      best != null && (best!.value > 0 || best!.points > 0);

  @override
  Widget build(BuildContext context) {
    final effColor = _hasData ? color : color.withValues(alpha: 0.50);

    // Logique du texte de points : identique à journal d'origine.
    String pointsText = '';
    Color pointsColor = Colors.transparent;
    if (points != null) {
      if (points == -1) {
        pointsText = '??? pts';
        pointsColor = Colors.white.withValues(alpha: 0.55);
      } else if (points! > 0) {
        pointsText = '+$points pts';
        pointsColor = effColor.withValues(alpha: 0.9);
      } else {
        pointsText = '+0 pts';
        pointsColor = effColor.withValues(alpha: 0.9);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Mêmes proportions que _StatCell du dino_variant_screen :
        //   label 28% / valeur 42% / points 22%  (≈ 92% utilisés + padding)
        final hLabel = h * 0.28;
        final hValue = h * 0.42;
        final hPoints = h * 0.22;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: effColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ligne 1 : emoji + label
              SizedBox(
                height: hLabel,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji,
                          style:
                              const TextStyle(fontSize: 14, height: 1.0)),
                      const SizedBox(width: 3),
                      Text(
                        label,
                        style: GoogleFonts.exo2(
                          color: Colors.white.withValues(
                              alpha: _hasData ? 0.85 : 0.45),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Ligne 2 : valeur (centrée, height:1.0, FittedBox)
              SizedBox(
                height: hValue,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      color: effColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Ligne 3 : points (zone réservée même si vide)
              SizedBox(
                height: hPoints,
                child: pointsText.isEmpty
                    ? const SizedBox.shrink()
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          pointsText,
                          style: GoogleFonts.exo2(
                            color: pointsColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
