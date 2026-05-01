// lib/screens/tracker/species_journal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/dino.dart';
import '../../models/species_tracker.dart';
import '../../models/ark_color_palette.dart';
import '../../providers/dino_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dino_image_widget.dart';
import '../../widgets/ark_dino_card.dart';
import '../dino_detail_screen.dart';
import '../add_edit_dino_screen.dart';
import 'species_tracker_detail_screen.dart';

class SpeciesJournalDetailScreen extends StatelessWidget {
  final String species;

  const SpeciesJournalDetailScreen({
    super.key,
    required this.species,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dinoProvider, trackerProvider, _) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        final libraryDinos = dinoProvider.dinos
            .where((dino) => dino.espece.toLowerCase() == species.toLowerCase())
            .toList();

        final tracker = trackerProvider.trackers.cast<SpeciesTracker?>().firstWhere(
              (t) => t?.species.toLowerCase() == species.toLowerCase(),
              orElse: () => null,
            );

        final mergedBestStats = tracker == null
            ? _buildLibraryOnlyBestStats(libraryDinos)
            : _mergeTrackerAndLibraryBestStats(
                tracker: tracker,
                libraryDinos: libraryDinos,
              );

        final mergedColorBank = tracker == null
            ? _buildLibraryOnlyColorBank(libraryDinos)
            : _mergeTrackerAndLibraryColorBank(
                tracker: tracker,
                libraryDinos: libraryDinos,
              );

        final previewColors = libraryDinos.isNotEmpty
            ? [
                libraryDinos.first.colorHex0,
                libraryDinos.first.colorHex1,
                libraryDinos.first.colorHex2,
                libraryDinos.first.colorHex3,
                libraryDinos.first.colorHex4,
                libraryDinos.first.colorHex5,
              ]
            : List.generate(6, (_) => '#808080');

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgSecondary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  species.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'Journal d\'espece',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          body: SafeArea(
            bottom: true,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
              children: [
                _buildHeaderCard(
                  context,
                  species: species,
                  previewColors: previewColors,
                  libraryDinos: libraryDinos,
                  tracker: tracker,
                  mergedBestStats: mergedBestStats,
                  mergedColorBank: mergedColorBank,
                ),
                const SizedBox(height: 20),
                _buildStatsSection(mergedBestStats),
                const SizedBox(height: 20),
                _buildColorsSection(mergedColorBank),
                const SizedBox(height: 20),
                _buildDinosSection(context, dinoProvider, libraryDinos),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HEADER CARD ──────────────────────────────────────────────────────────
  Widget _buildHeaderCard(
    BuildContext context, {
    required String species,
    required List<String> previewColors,
    required List<Dino> libraryDinos,
    required SpeciesTracker? tracker,
    required Map<String, BestStatRecord> mergedBestStats,
    required Map<int, Set<int>> mergedColorBank,
  }) {
    final totalColors =
        mergedColorBank.values.fold<int>(0, (sum, set) => sum + set.length);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 110,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: DinoImageWidget(
              species: species,
              regionColors: previewColors,
              width: 110,
              height: 90,
              fit: BoxFit.contain,
              showColorBand: false,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  species,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _infoLine('Dinos', '${libraryDinos.length}'),
                _infoLine('Stats max', '${mergedBestStats.length}/7'),
                _infoLine('Couleurs', '$totalColors'),
                _infoLine(
                    'Tracker', tracker != null ? 'Disponible' : 'Absent'),
                const SizedBox(height: 10),
                if (tracker != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpeciesTrackerDetailScreen(
                              tracker: tracker,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.science),
                      label: const Text('OUVRIR LE LABO'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label : $value',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }

  // ─── STATS SECTION ────────────────────────────────────────────────────────
  Widget _buildStatsSection(Map<String, BestStatRecord> stats) {
    const statOrder = [
      'hp', 'stamina', 'oxygene', 'nourriture', 'poids', 'degats', 'vitesse',
    ];

    const labels = {
      'hp': 'HP',
      'stamina': 'Stamina',
      'oxygene': 'Oxygene',
      'nourriture': 'Food',
      'poids': 'Poids',
      'degats': 'Degats',
      'vitesse': 'Vitesse',
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  'STATS MAXIMALES',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              itemCount: statOrder.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final key = statOrder[index];
                final record = stats[key];

                if (record == null) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          labels[key]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Non enregistre',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                final displayValue = record.value % 1 == 0
                    ? record.value.toInt().toString()
                    : record.value.toStringAsFixed(1);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        labels[key]!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$displayValue${key == 'degats' || key == 'vitesse' ? '%' : ''}',
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${record.points ?? 0} pts',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        record.source ?? 'Inconnu',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── COLORS SECTION ───────────────────────────────────────────────────────
  Widget _buildColorsSection(Map<int, Set<int>> colorBank) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.palette_outlined, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  'BANQUE DE COULEURS',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(6, (region) {
              final sorted = (colorBank[region] ?? {}).toList()..sort();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRegionColorBar(region, sorted),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionColorBar(int region, List<int> colors) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Region $region',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (colors.isEmpty)
            const Text(
              'Aucune couleur enregistree',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            )
          else
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final id = colors[index];
                  final ark = ArkColorPalette.fromId(id);
                  final color = ark?.color ?? Colors.grey;
                  return Container(
                    width: 42,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$id',
                        style: TextStyle(
                          color:
                              _isLight(color) ? Colors.black : Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ─── DINOS SECTION ────────────────────────────────────────────────────────
  Widget _buildDinosSection(
    BuildContext context,
    DinoProvider dinoProvider,
    List<Dino> dinos,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_stories_rounded, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  'DINOS DE LA BIBLIOTHEQUE',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (dinos.isEmpty)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Aucun dino complet enregistre dans la bibliotheque.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...dinos.map((dino) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ArkDinoCard(
                    dino: dino,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DinoDetailScreen(dino: dino),
                        ),
                      ).then((_) => dinoProvider.loadDinos());
                    },
                    onEdit: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditDinoScreen(dino: dino),
                        ),
                      ).then((_) => dinoProvider.loadDinos());
                    },
                    onDelete: () =>
                        _confirmDelete(context, dinoProvider, dino),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── CONFIRM DELETE ───────────────────────────────────────────────────────
  void _confirmDelete(
      BuildContext context, DinoProvider provider, Dino dino) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Supprimer ${dino.nom} ?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Cette action est irreversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (dino.id != null) {
                provider.deleteDino(dino.id!);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ─── LIBRARY-ONLY BEST STATS ──────────────────────────────────────────────
  Map<String, BestStatRecord> _buildLibraryOnlyBestStats(List<Dino> dinos) {
    final merged = <String, BestStatRecord>{};

    void considerStat({
      required String statName,
      required num value,
      required int points,
      required String sourceName,
      required DateTime recordedAt,
    }) {
      final current = merged[statName];
      final doubleValue = value.toDouble();

      if (current == null || doubleValue > current.value) {
        merged[statName] = BestStatRecord(
          value: doubleValue,
          points: points,
          source: sourceName,
          recordedAt: recordedAt,
        );
      }
    }

    for (final dino in dinos) {
      final src = dino.nom.isNotEmpty ? dino.nom : 'Dino#${dino.id ?? 0}';
      final date = dino.dateAjout;

      considerStat(statName: 'hp', value: dino.hp, points: dino.hpPoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'stamina', value: dino.stamina, points: dino.staminaPoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'oxygene', value: dino.oxygene, points: dino.oxygenePoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'nourriture', value: dino.nourriture, points: dino.nourriturePoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'poids', value: dino.poids, points: dino.poidsPoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'degats', value: dino.degats, points: dino.degatsPoints, sourceName: src, recordedAt: date);
      considerStat(statName: 'vitesse', value: dino.vitesse, points: dino.vitessePoints, sourceName: src, recordedAt: date);
    }

    return merged;
  }

  // ─── LIBRARY-ONLY COLOR BANK ──────────────────────────────────────────────
  Map<int, Set<int>> _buildLibraryOnlyColorBank(List<Dino> libraryDinos) {
    final result = <int, Set<int>>{};

    void addColor(int region, int colorId) {
      if (colorId <= 0) return;
      result[region] ??= <int>{};
      result[region]!.add(colorId);
    }

    for (final dino in libraryDinos) {
      final ids = dino.colorIds;
      for (int r = 0; r < 6; r++) {
        addColor(r, ids[r]);
      }
    }

    return result;
  }

  bool _isLight(Color c) => c.computeLuminance() > 0.5;
}

// ═══════════════════════════════════════════════════════
// TOP-LEVEL MERGE HELPERS
// ═══════════════════════════════════════════════════════

Map<String, BestStatRecord> _mergeTrackerAndLibraryBestStats({
  required SpeciesTracker tracker,
  required List<Dino> libraryDinos,
}) {
  final merged = <String, BestStatRecord>{};

  // Start with tracker's best stats
  merged.addAll(tracker.bestStats);

  void considerStat({
    required String statName,
    required num value,
    required int points,
    required String sourceName,
    required DateTime recordedAt,
  }) {
    final current = merged[statName];
    final doubleValue = value.toDouble();

    if (current == null || doubleValue > current.value) {
      merged[statName] = BestStatRecord(
        value: doubleValue,
        points: points,
        source: sourceName,
        recordedAt: recordedAt,
      );
    }
  }

  for (final dino in libraryDinos) {
    final src = dino.nom.isNotEmpty ? dino.nom : 'Dino#${dino.id ?? 0}';
    final date = dino.dateAjout;

    considerStat(statName: 'hp', value: dino.hp, points: dino.hpPoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'stamina', value: dino.stamina, points: dino.staminaPoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'oxygene', value: dino.oxygene, points: dino.oxygenePoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'nourriture', value: dino.nourriture, points: dino.nourriturePoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'poids', value: dino.poids, points: dino.poidsPoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'degats', value: dino.degats, points: dino.degatsPoints, sourceName: src, recordedAt: date);
    considerStat(statName: 'vitesse', value: dino.vitesse, points: dino.vitessePoints, sourceName: src, recordedAt: date);
  }

  return merged;
}

Map<int, Set<int>> _mergeTrackerAndLibraryColorBank({
  required SpeciesTracker tracker,
  required List<Dino> libraryDinos,
}) {
  final merged = <int, Set<int>>{};

  // Start with tracker's color bank
  tracker.colorBank.forEach((region, colors) {
    merged[region] = <int>{...colors};
  });

  void addColor(int region, int colorId) {
    if (colorId <= 0) return;
    merged[region] ??= <int>{};
    merged[region]!.add(colorId);
  }

  for (final dino in libraryDinos) {
    final ids = dino.colorIds;
    for (int r = 0; r < 6; r++) {
      addColor(r, ids[r]);
    }
  }

  return merged;
}
