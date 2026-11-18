// lib/screens/tracker/tracker_home_screen.dart
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/tracker_provider.dart';
import '../../models/dino.dart';
import '../../models/species_tracker.dart';
import '../../theme/app_theme.dart';
import 'species_tracker_detail_screen.dart';
import 'species_journal_home_screen.dart';

class TrackerHomeScreen extends StatefulWidget {
  const TrackerHomeScreen({super.key});

  @override
  State<TrackerHomeScreen> createState() => _TrackerHomeScreenState();
}

class _TrackerHomeScreenState extends State<TrackerHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();

  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<TrackerProvider>().loadTrackers();
    });
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _speciesController.dispose();
    _projectController.dispose();
    super.dispose();
  }

  List<SpeciesTracker> _filter(List<SpeciesTracker> trackers) {
    if (_query.isEmpty) return trackers;
    return trackers.where((tracker) {
      final species = tracker.species.toLowerCase();
      final project = (tracker.projectName ?? '').toLowerCase();
      return species.contains(_query) || project.contains(_query);
    }).toList();
  }

  int _countKnownColors(SpeciesTracker tracker) {
    int total = 0;
    tracker.colorBank.forEach((_, ids) {
      total += ids.length;
    });
    return total;
  }

  int _countBestStats(SpeciesTracker tracker) {
    return tracker.bestStats.values.where((e) => e.value > 0).length;
  }

  Future<void> _showCreateTrackerDialog() async {
    _speciesController.clear();
    _projectController.clear();

    List<String> suggestions = [];
    String? selectedSpecies;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                'Nouveau tracker',
                style: GoogleFonts.exo2(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _speciesController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Espèce',
                        hintText: 'Ex: Rex',
                        suffixIcon: selectedSpecies != null
                            ? Icon(Icons.check_circle_rounded,
                                color: AppTheme.success, size: 22)
                            : null,
                      ),
                      onChanged: (value) {
                        final input = value.trim().toLowerCase();
                        setStateDialog(() {
                          if (input.isEmpty) {
                            suggestions = [];
                            selectedSpecies = null;
                          } else {
                            suggestions = Dino.especesDisponibles
                                .where(
                                    (s) => s.toLowerCase().contains(input))
                                .toList();
                            final exactMatch = Dino.especesDisponibles
                                .where(
                                    (s) => s.toLowerCase() == input)
                                .toList();
                            selectedSpecies = exactMatch.isNotEmpty
                                ? exactMatch.first
                                : null;
                          }
                        });
                      },
                    ),
                    if (suggestions.isNotEmpty && selectedSpecies == null)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentSecondary
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          itemCount: suggestions.length,
                          itemBuilder: (_, i) {
                            final species = suggestions[i];
                            return InkWell(
                              onTap: () {
                                _speciesController.text = species;
                                _speciesController.selection =
                                    TextSelection.fromPosition(
                                  TextPosition(offset: species.length),
                                );
                                setStateDialog(() {
                                  selectedSpecies = species;
                                  suggestions = [];
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    _buildMiniPlaceholder(species),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        species,
                                        style: GoogleFonts.exo2(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    if (_speciesController.text.trim().isNotEmpty &&
                        suggestions.isEmpty &&
                        selectedSpecies == null)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                AppTheme.warning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: AppTheme.warning, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Espèce non reconnue.',
                                style: GoogleFonts.exo2(
                                  color: AppTheme.warning,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _projectController,
                      style: TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Nom du projet (optionnel)',
                        hintText: 'Ex: Lignée mutation mêlée',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Annuler',
                      style:
                          GoogleFonts.exo2(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final species = _speciesController.text.trim();
                    final project = _projectController.text.trim();

                    if (species.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Le nom de l\'espèce est requis')),
                      );
                      return;
                    }

                    final isValid = Dino.especesDisponibles.any(
                      (s) =>
                          s.toLowerCase() == species.toLowerCase(),
                    );

                    if (!isValid) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Espèce "$species" non reconnue.'),
                          backgroundColor: AppTheme.warning,
                        ),
                      );
                      return;
                    }

                    final officialName =
                        Dino.especesDisponibles.firstWhere(
                      (s) =>
                          s.toLowerCase() == species.toLowerCase(),
                    );

                    try {
                      await context
                          .read<TrackerProvider>()
                          .createTracker(officialName, project);

                      if (!mounted) return;
                      // ignore: use_build_context_synchronously
                      Navigator.pop(dialogContext);
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Tracker créé pour $officialName'),
                        ),
                      );
                    } catch (e) {
                      // ignore: use_build_context_synchronously
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  },
                  child: const Text('Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMiniPlaceholder(String species) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          species.isNotEmpty ? species[0].toUpperCase() : '?',
          style: GoogleFonts.exo2(
            color: AppTheme.accentSecondary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTracker(SpeciesTracker tracker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text('Supprimer ce tracker ?',
              style: GoogleFonts.exo2(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold)),
          content: Text(
            'Le tracker de ${tracker.species} sera supprimé.',
            style: GoogleFonts.exo2(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler',
                  style:
                      GoogleFonts.exo2(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // ignore: use_build_context_synchronously
    await context.read<TrackerProvider>().deleteTracker(tracker.id);

    if (!mounted) return;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Tracker ${tracker.species} supprimé')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TrackerProvider>();
    final trackers = [...provider.trackers];

    trackers.sort(
      (a, b) =>
          a.species.toLowerCase().compareTo(b.species.toLowerCase()),
    );

    final filtered = _filter(trackers);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildTopButtons(context),
              const SizedBox(height: 14),
              _buildSearchField(),
              const SizedBox(height: 14),
              _buildSummary(filtered.length, trackers.length),
              const SizedBox(height: 14),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final tracker = filtered[index];
                          return _TrackerCard(
                            tracker: tracker,
                            bestStatsCount: _countBestStats(tracker),
                            knownColorsCount:
                                _countKnownColors(tracker),
                            onOpen: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SpeciesTrackerDetailScreen(
                                    tracker: tracker,
                                  ),
                                ),
                              );
                            },
                            onDelete: () =>
                                _confirmDeleteTracker(tracker),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTrackerDialog,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppTheme.textPrimary,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gestion',
                  style: GoogleFonts.exo2(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(height: 2),
              Text('Dino Tracker',
                  style: GoogleFonts.cinzelDecorative(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.accentGradient,
            border: Border.all(
                color: AppTheme.accentSecondary, width: 1.4),
          ),
          child: const Icon(Icons.analytics_rounded,
              color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTopButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const SpeciesJournalHomeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Journal d\'espèces'),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: 'Rechercher une espèce ou un projet...',
        prefixIcon:
            Icon(Icons.search, color: AppTheme.textSecondary),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                onPressed: () => _searchController.clear(),
                icon: Icon(Icons.close,
                    color: AppTheme.textSecondary),
              ),
      ),
    );
  }

  Widget _buildSummary(int filteredCount, int totalCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.folder_special_rounded,
              color: AppTheme.accentSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _query.isEmpty
                  ? '$totalCount tracker${totalCount > 1 ? 's' : ''} enregistré${totalCount > 1 ? 's' : ''}'
                  : '$filteredCount résultat${filteredCount > 1 ? 's' : ''} / $totalCount tracker${totalCount > 1 ? 's' : ''}',
              style: GoogleFonts.exo2(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final searching = _query.isNotEmpty;
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              searching
                  ? Icons.search_off_rounded
                  : Icons.analytics_outlined,
              size: 54,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 14),
            Text(
              searching
                  ? 'Aucun tracker trouvé'
                  : 'Aucun tracker enregistré',
              style: GoogleFonts.cinzelDecorative(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              searching
                  ? 'Essaie une autre recherche.'
                  : 'Crée un tracker avec le bouton + pour commencer.',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final SpeciesTracker tracker;
  final int bestStatsCount;
  final int knownColorsCount;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _TrackerCard({
    required this.tracker,
    required this.bestStatsCount,
    required this.knownColorsCount,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.accentGradient,
                border: Border.all(
                    color: AppTheme.accentSecondary, width: 1.8),
              ),
              child: const Icon(Icons.pets_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tracker.species,
                    style: GoogleFonts.exo2(
                      color: AppTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if ((tracker.projectName ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      tracker.projectName!,
                      style: GoogleFonts.exo2(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniInfoChip(
                        icon: Icons.bar_chart_rounded,
                        label: '$bestStatsCount stats max',
                        color: AppTheme.warning,
                      ),
                      _MiniInfoChip(
                        icon: Icons.palette_rounded,
                        label: '$knownColorsCount couleurs',
                        color: AppTheme.info,
                      ),
                      _MiniInfoChip(
                        icon: Icons.edit_note_rounded,
                        label:
                            '${tracker.anonymousStatEntries.length} entrées',
                        color: AppTheme.success,
                      ),
                      _MiniInfoChip(
                        icon: Icons.remove_red_eye_rounded,
                        label:
                            '${tracker.colorObservations.length} obs',
                        color: AppTheme.accentSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onOpen,
                          icon: const Icon(
                              Icons.open_in_new_rounded),
                          label: const Text('Ouvrir'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                            Icons.delete_outline_rounded),
                        color: AppTheme.danger,
                        tooltip: 'Supprimer',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
