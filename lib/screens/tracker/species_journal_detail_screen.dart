// lib/screens/tracker/species_journal_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
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

class SpeciesJournalDetailScreen extends StatefulWidget {
  final String species;
  final Dino? initialSelectedDino;

  const SpeciesJournalDetailScreen({
    super.key,
    required this.species,
    this.initialSelectedDino, 
  });

  @override
  State<SpeciesJournalDetailScreen> createState() =>
      _SpeciesJournalDetailScreenState();
}

class _SpeciesJournalDetailScreenState
    extends State<SpeciesJournalDetailScreen> {
  late Dino? _selectedDino;
  bool _isColorsExpanded = false;

  @override
  void initState() {
    super.initState();
    _selectedDino = widget.initialSelectedDino;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dinoProvider, trackerProvider, _) {
        final bottomPadding = MediaQuery.of(context).padding.bottom;

        final libraryDinos = dinoProvider.dinos
            .where((dino) =>
                dino.espece.toLowerCase() == widget.species.toLowerCase())
            .toList();

        final tracker = trackerProvider.trackers.cast<SpeciesTracker?>().firstWhere(
              (t) => t?.species.toLowerCase() == widget.species.toLowerCase(),
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

        // ✅ CORRIGÉ : Vérifier que le dino sélectionné existe toujours dans la liste
        // Si elle n'existe pas, prendre le premier disponible
        if (_selectedDino == null || 
            !libraryDinos.any((d) => d.id == _selectedDino!.id)) {
          if (libraryDinos.isNotEmpty) {
            _selectedDino = libraryDinos.first;
          } else {
            _selectedDino = null;
          }
        }

        final previewColors = _selectedDino != null
            ? [
                _selectedDino!.colorHex0,
                _selectedDino!.colorHex1,
                _selectedDino!.colorHex2,
                _selectedDino!.colorHex3,
                _selectedDino!.colorHex4,
                _selectedDino!.colorHex5,
              ]
            : List.generate(6, (_) => '#808080');

        final totalColors = mergedColorBank.values
            .fold<int>(0, (sum, set) => sum + set.length);

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgSecondary,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.species.toUpperCase(),
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
                  species: widget.species,
                  previewColors: previewColors,
                  libraryDinos: libraryDinos,
                  tracker: tracker,
                  selectedDino: _selectedDino,
                  totalColors: totalColors,
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
    required Dino? selectedDino,
    required int totalColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // ── DINO VISUEL CLIQUABLE ──
          GestureDetector(
            onTap: libraryDinos.length > 1
                ? () => _showDinoSelector(context, libraryDinos)
                : null,
            child: Container(
              width: 110,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  DinoImageWidget(
                    species: species,
                    regionColors: previewColors,
                    width: 110,
                    height: 90,
                    fit: BoxFit.contain,
                    showColorBand: false,
                  ),
                  if (libraryDinos.length > 1)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.cyanAccent,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          // ── INFOS ──
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
                _infoLine('DinoCards', '${libraryDinos.length}'),
                _infoLine('Trackers', tracker != null ? '1' : '0'),
                _infoLine('Couleurs', '$totalColors'),
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

  // ─── DINO SELECTOR MODAL ──────────────────────────────────────────────────
  void _showDinoSelector(BuildContext context, List<Dino> dinos) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choisir un dino favoris',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: dinos.length,
                itemBuilder: (_, idx) {
                  final dino = dinos[idx];
                  final isSelected = _selectedDino?.id == dino.id;
                  return GestureDetector(
                    onTap: () {
                      // ✅ IMPORTANT : Mettre à jour l'état AVANT de fermer le modal
                      setState(() => _selectedDino = dino);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                            : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentPrimary
                              : AppTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  dino.nom,
                                  style: GoogleFonts.exo2(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Lvl ${dino.niveau}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.accentPrimary,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── STATS SECTION ────────────────────────────────────────────────────────
  Widget _buildStatsSection(Map<String, BestStatRecord> stats) {
    const statOrder = [
      'hp',
      'stamina',
      'oxygene',
      'nourriture',
      'poids',
      'degats',
    ];

    const labels = {
      'hp': 'VIE',
      'stamina': 'STAM',
      'oxygene': 'OXYGÈNE',
      'nourriture': 'FOOD',
      'poids': 'POIDS',
      'degats': 'ATTAQUE',
    };

    const emojis = {
      'hp': '❤️',
      'stamina': '⚡',
      'oxygene': '🫧',
      'nourriture': '🍖',
      'poids': '⚖️',
      'degats': '⚔️',
    };

    const colors = {
      'hp': Color(0xFF4CAF50),
      'stamina': Color(0xFFFFD700),
      'oxygene': Color(0xFF10B981),
      'nourriture': Color(0xFF8B5CF6),
      'poids': Color(0xFF3B82F6),
      'degats': Color(0xFFEF4444),
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
            // Ligne 1 : 3 stats
            Row(
              children: [
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[0],
                    labels[statOrder[0]]!,
                    emojis[statOrder[0]]!,
                    colors[statOrder[0]]!,
                    stats[statOrder[0]],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[1],
                    labels[statOrder[1]]!,
                    emojis[statOrder[1]]!,
                    colors[statOrder[1]]!,
                    stats[statOrder[1]],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[2],
                    labels[statOrder[2]]!,
                    emojis[statOrder[2]]!,
                    colors[statOrder[2]]!,
                    stats[statOrder[2]],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Ligne 2 : 3 stats
            Row(
              children: [
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[3],
                    labels[statOrder[3]]!,
                    emojis[statOrder[3]]!,
                    colors[statOrder[3]]!,
                    stats[statOrder[3]],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[4],
                    labels[statOrder[4]]!,
                    emojis[statOrder[4]]!,
                    colors[statOrder[4]]!,
                    stats[statOrder[4]],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMaxStatCard(
                    statOrder[5],
                    labels[statOrder[5]]!,
                    emojis[statOrder[5]]!,
                    colors[statOrder[5]]!,
                    stats[statOrder[5]],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaxStatCard(
    String statKey,
    String label,
    String emoji,
    Color color,
    BestStatRecord? record,
  ) {
    if (record == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF15181E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF454545), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'N/A',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    final displayValue = record.value % 1 == 0
        ? record.value.toInt().toString()
        : record.value.toStringAsFixed(1);

    final suffixe = statKey == 'degats' ? '%' : '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF454545), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$displayValue$suffixe',
            style: GoogleFonts.exo2(
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
        ],
      ),
    );
  }

  // ─── COLORS SECTION (COLLAPSIBLE) ──────────────────────────────────────────
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
            GestureDetector(
              onTap: () => setState(() => _isColorsExpanded = !_isColorsExpanded),
              child: Row(
                children: [
                  const Icon(Icons.palette_outlined, color: Colors.cyanAccent),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'BANQUE DE COULEURS',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    _isColorsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.cyanAccent,
                  ),
                ],
              ),
            ),
            if (_isColorsExpanded) ...[
              const SizedBox(height: 16),
              ...List.generate(6, (region) {
                final sorted = (colorBank[region] ?? {}).toList()..sort();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildRegionColorBar(region, sorted),
                );
              }),
            ],
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

      considerStat(
          statName: 'hp',
          value: dino.hp,
          points: dino.hpPoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'stamina',
          value: dino.stamina,
          points: dino.staminaPoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'oxygene',
          value: dino.oxygene,
          points: dino.oxygenePoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'nourriture',
          value: dino.nourriture,
          points: dino.nourriturePoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'poids',
          value: dino.poids,
          points: dino.poidsPoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'degats',
          value: dino.degats,
          points: dino.degatsPoints,
          sourceName: src,
          recordedAt: date);
      considerStat(
          statName: 'vitesse',
          value: dino.vitesse,
          points: dino.vitessePoints,
          sourceName: src,
          recordedAt: date);
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

    considerStat(
        statName: 'hp',
        value: dino.hp,
        points: dino.hpPoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'stamina',
        value: dino.stamina,
        points: dino.staminaPoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'oxygene',
        value: dino.oxygene,
        points: dino.oxygenePoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'nourriture',
        value: dino.nourriture,
        points: dino.nourriturePoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'poids',
        value: dino.poids,
        points: dino.poidsPoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'degats',
        value: dino.degats,
        points: dino.degatsPoints,
        sourceName: src,
        recordedAt: date);
    considerStat(
        statName: 'vitesse',
        value: dino.vitesse,
        points: dino.vitessePoints,
        sourceName: src,
        recordedAt: date);
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

