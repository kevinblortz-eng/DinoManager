// lib/screens/tracker/tabs/journal_tab_colors.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/ark_color_palette.dart';
import '../../../models/ark_species_color_regions.dart';
import '../../../models/dino.dart';
import '../../../models/species_tracker.dart';
import '../../../theme/app_theme.dart';

class JournalTabColors extends StatelessWidget {
  final String species;
  final List<Dino> dinos;
  final SpeciesTracker? tracker;

  const JournalTabColors({
    super.key,
    required this.species,
    required this.dinos,
    this.tracker,
  });

  /// Fusionne couleurs library + tracker par région.
  Map<int, Set<int>> _mergeBank() {
    final bank = <int, Set<int>>{
      0: <int>{}, 1: <int>{}, 2: <int>{}, 3: <int>{}, 4: <int>{}, 5: <int>{},
    };
    for (final d in dinos) {
      final ids = d.colorIds;
      for (int r = 0; r < 6; r++) {
        if (ids[r] > 0) bank[r]!.add(ids[r]);
      }
    }
    final t = tracker;
    if (t != null) {
      t.colorBank.forEach((r, ids) {
        bank[r]?.addAll(ids);
      });
    }
    return bank;
  }

  @override
  Widget build(BuildContext context) {
    final visibility = ArkSpeciesColorRegions.visibilityFor(species);
    final bank = _mergeBank();

    final rows = <Widget>[];
    for (int r = 0; r < 6; r++) {
      final active = r < visibility.length ? visibility[r] : true;
      final ids = (bank[r] ?? <int>{}).toList()..sort();
      if (ids.isEmpty && !active) continue;

      rows.add(_buildRegionRow(region: r, active: active, ids: ids));
      rows.add(const SizedBox(height: 8));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVisibilityRow(visibility),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }

  // ─── Ligne 1 : 6 mini-cases visible / invisible ─────────────────────────
  Widget _buildVisibilityRow(List<bool> visibility) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ZONES DE L\'ESPÈCE',
            style: GoogleFonts.exo2(
              color: Colors.cyanAccent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(6, (i) {
              final active = i < visibility.length ? visibility[i] : true;
              return Expanded(
                child: Container(
                  height: 30,
                  margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.cyanAccent.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: active
                          ? Colors.cyanAccent.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    active ? 'R$i' : '—',
                    style: GoogleFonts.exo2(
                      color: active
                          ? Colors.cyanAccent
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─── Une ligne par région (avec wrap) ───────────────────────────────────
  Widget _buildRegionRow({
    required int region,
    required bool active,
    required List<int> ids,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active
            ? AppTheme.bgCard
            : AppTheme.bgCard.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? AppTheme.borderColor
              : Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: active
                      ? Colors.cyanAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'R$region',
                  style: GoogleFonts.exo2(
                    color: active
                        ? Colors.cyanAccent
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!active)
                Text(
                  'Zone inactive',
                  style: GoogleFonts.exo2(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const Spacer(),
              Text(
                '${ids.length}',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (ids.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Aucune couleur enregistrée',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: ids.map((id) {
                  final ark = ArkColorPalette.fromId(id);
                  final color = ark?.color ?? Colors.grey;
                  final textColor = color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white;
                  return Container(
                    width: 32,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$id',
                      style: GoogleFonts.exo2(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
