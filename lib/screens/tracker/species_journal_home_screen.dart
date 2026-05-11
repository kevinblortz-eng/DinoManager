// lib/screens/tracker/species_journal_home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/dino.dart';
import '../../models/species_tracker.dart';
import '../../providers/dino_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dino_image_widget.dart';
import 'species_journal_detail_screen.dart';

class SpeciesJournalHomeScreen extends StatelessWidget {
  final Dino? initialSelectedDino;

  const SpeciesJournalHomeScreen({
    super.key,
    this.initialSelectedDino,
  });

  @override
  Widget build(BuildContext context) {
    return _SpeciesJournalHomeScreenBody(
      initialSelectedDino: initialSelectedDino,
    );
  }
}

class _SpeciesJournalHomeScreenBody extends StatefulWidget {
  final Dino? initialSelectedDino;

  const _SpeciesJournalHomeScreenBody({
    this.initialSelectedDino,
  });

  @override
  State<_SpeciesJournalHomeScreenBody> createState() =>
      _SpeciesJournalHomeScreenBodyState();
}

class _SpeciesJournalHomeScreenBodyState
    extends State<_SpeciesJournalHomeScreenBody> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SpeciesJournalItem> _buildAndFilter(
    List<Dino> dinos,
    List<SpeciesTracker> trackers,
  ) {
    final speciesSet = <String>{};
    for (final dino in dinos) {
      speciesSet.add(dino.espece);
    }
    for (final tracker in trackers) {
      speciesSet.add(tracker.species);
    }

    final result = <_SpeciesJournalItem>[];

    for (final species in speciesSet) {
      final speciesDinos = dinos
          .where((d) => d.espece.toLowerCase() == species.toLowerCase())
          .toList();
      final tracker = trackers.cast<SpeciesTracker?>().firstWhere(
            (t) => t?.species.toLowerCase() == species.toLowerCase(),
            orElse: () => null,
          );

      final colorSet = <int>{};
      for (final dino in speciesDinos) {
        if (dino.colorId0 > 0) colorSet.add(dino.colorId0);
        if (dino.colorId1 > 0) colorSet.add(dino.colorId1);
        if (dino.colorId2 > 0) colorSet.add(dino.colorId2);
        if (dino.colorId3 > 0) colorSet.add(dino.colorId3);
        if (dino.colorId4 > 0) colorSet.add(dino.colorId4);
        if (dino.colorId5 > 0) colorSet.add(dino.colorId5);
      }
      if (tracker != null) {
        for (final colors in tracker.colorBank.values) {
          colorSet.addAll(colors);
        }
      }

      List<String> previewColors = List.generate(6, (_) => '#808080');
      if (speciesDinos.isNotEmpty) {
        final d = speciesDinos.first;
        previewColors = [
          d.colorHex0, d.colorHex1, d.colorHex2,
          d.colorHex3, d.colorHex4, d.colorHex5,
        ];
      }

      // Prendre le premier dino comme favoris par défaut
      final defaultFavoriteDino =
          speciesDinos.isNotEmpty ? speciesDinos.first : null;

      result.add(_SpeciesJournalItem(
        species: species,
        previewColors: previewColors,
        libraryDinosCount: speciesDinos.length,
        bestStatsCount: tracker?.bestStats.length ?? 0,
        totalUniqueColors: colorSet.length,
        hasTracker: tracker != null,
        defaultFavoriteDino: defaultFavoriteDino,
      ));
    }

    result.sort((a, b) => a.species.toLowerCase().compareTo(b.species.toLowerCase()));

    // Filtrer par recherche
    if (_query.isEmpty) return result;
    return result
        .where((item) => item.species.toLowerCase().contains(_query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dinoProvider, trackerProvider, _) {
        final allItems = _buildAndFilter(
          dinoProvider.dinos,
          trackerProvider.trackers,
        );

        // Compter le total (sans filtre) pour l'affichage
        final speciesSetTotal = <String>{};
        for (final d in dinoProvider.dinos) {
          speciesSetTotal.add(d.espece);
        }
        for (final t in trackerProvider.trackers) {
          speciesSetTotal.add(t.species);
        }
        final totalCount = speciesSetTotal.length;

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'JOURNAL D\'ESPÈCES',
                              style: GoogleFonts.cinzelDecorative(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vue synthèse par espèce',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Barre de recherche ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une espèce...',
                      prefixIcon: const Icon(Icons.search,
                          color: AppTheme.accentPrimary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              onPressed: () => _searchController.clear(),
                              icon: const Icon(Icons.close,
                                  color: AppTheme.textMuted),
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.bgSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.accentPrimary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Compteur ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        _query.isEmpty
                            ? '$totalCount espèce${totalCount > 1 ? 's' : ''}'
                            : '${allItems.length} résultat${allItems.length > 1 ? 's' : ''} / $totalCount',
                        style: GoogleFonts.exo2(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Liste ──
                Expanded(
                  child: allItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: allItems.length,
                          itemBuilder: (context, index) {
                            return _buildSpeciesCard(
                                context, allItems[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final searching = _query.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching ? Icons.search_off_rounded : Icons.menu_book_rounded,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              searching
                  ? 'Aucune espèce trouvée'
                  : 'Aucune espèce enregistrée',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                color: AppTheme.textMuted,
                fontSize: 15,
              ),
            ),
            if (!searching) ...[
              const SizedBox(height: 4),
              Text(
                'Ajoute des dinos ou crée un tracker',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesCard(BuildContext context, _SpeciesJournalItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpeciesJournalDetailScreen(
                species: item.species,
                initialSelectedDino: item.defaultFavoriteDino,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 65,
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: DinoImageWidget(
                  species: item.species,
                  regionColors: item.previewColors,
                  width: 80,
                  height: 65,
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
                      item.species,
                      style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _miniBadge('Dinos', '${item.libraryDinosCount}',
                            Colors.orangeAccent),
                        _miniBadge('Stats', '${item.bestStatsCount}/7',
                            Colors.greenAccent),
                        _miniBadge('Couleurs', '${item.totalUniqueColors}',
                            Colors.purpleAccent),
                        _miniBadge(
                          'Tracker',
                          item.hasTracker ? 'Oui' : 'Non',
                          item.hasTracker
                              ? Colors.cyanAccent
                              : AppTheme.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        '$label : $value',
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SpeciesJournalItem {
  final String species;
  final List<String> previewColors;
  final int libraryDinosCount;
  final int bestStatsCount;
  final int totalUniqueColors;
  final bool hasTracker;
  final Dino? defaultFavoriteDino;

  _SpeciesJournalItem({
    required this.species,
    required this.previewColors,
    required this.libraryDinosCount,
    required this.bestStatsCount,
    required this.totalUniqueColors,
    required this.hasTracker,
    this.defaultFavoriteDino,
  });
}
