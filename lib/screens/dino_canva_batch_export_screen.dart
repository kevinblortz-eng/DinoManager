// lib/screens/dino_canva_batch_export_screen.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ EXPORT AUTOMATIQUE EN SÉRIE (BATCH)                                   ║
// ║                                                                        ║
// ║ Permet de générer plusieurs PNG 1080×1350 d'un coup à partir de la    ║
// ║ bibliothèque : on définit une source (toute la lib / une espèce /     ║
// ║ un tag), un nombre de dinos par image, un tri et quelques options,    ║
// ║ puis on lance la génération séquentielle automatique.                 ║
// ║                                                                        ║
// ║ Réutilise CanvaExporter (capture offscreen) et CanvaLayout pour le    ║
// ║ rendu identique à celui du canva interactif.                          ║
// ╚════════════════════════════════════════════════════════════════════════╝

import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/dino.dart';
import '../providers/dino_provider.dart';
import '../theme/app_theme.dart';
import '../utils/dino_helpers.dart';
import '../widgets/canva/canva_bubble_widgets.dart';
import '../widgets/canva/canva_exporter.dart';
import '../widgets/canva/canva_layout_engine.dart';

enum BatchSourceType { all, species, tag }

enum BatchSortType {
  alphaName,
  levelDesc,
  colorId0Asc,
  speciesThenName,
  dateAdded,
}

class DinoCanvaBatchExportScreen extends StatefulWidget {
  /// Pré-sélection éventuelle (ex: depuis DinoCanvaScreen avec dinos déjà choisis).
  final List<Dino> initialDinos;

  const DinoCanvaBatchExportScreen({
    super.key,
    this.initialDinos = const [],
  });

  @override
  State<DinoCanvaBatchExportScreen> createState() =>
      _DinoCanvaBatchExportScreenState();
}

class _DinoCanvaBatchExportScreenState
    extends State<DinoCanvaBatchExportScreen> {
  // ── Config ────────────────────────────────────────────────────────────
  BatchSourceType _sourceType = BatchSourceType.all;
  String _selectedSpecies = '';
  String _selectedTag = '';
  // Filtres combinés optionnels (en plus de la source principale)
  String _extraSpeciesFilter = '';
  String _extraTagFilter = '';

  int _perImage = 9;
  BatchSortType _sort = BatchSortType.alphaName;

  bool _showTitle = true;
  bool _showStats = false; // n'a de sens qu'en mono-espèce
  bool _showPageNumber = true;
  String _customTitleBase = '';

  // ── Run state ─────────────────────────────────────────────────────────
  bool _running = false;
  bool _cancelRequested = false;
  int _currentPage = 0;
  int _totalPages = 0;
  final List<String> _log = [];
  int _firstFailedPage = -1; // pour reprise après annulation

  static const List<int> _perImageOptions = [4, 6, 8, 9, 12, 16];

  @override
  void initState() {
    super.initState();
    if (widget.initialDinos.isNotEmpty) {
      // Si on arrive depuis le canva avec dinos pré-sélectionnés → mode all
      // (la sélection initiale n'est pas un filtre, juste un cas d'usage)
      _sourceType = BatchSourceType.all;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DinoProvider>().loadDinos();
    });
  }

  // ─────────────────────────────────────────────────────────────────────
  //  RÉSOLUTION DES DINOS À EXPORTER
  // ─────────────────────────────────────────────────────────────────────

  List<Dino> _resolveDinos(DinoProvider provider) {
    Iterable<Dino> src = provider.allDinos;

    switch (_sourceType) {
      case BatchSourceType.all:
        break;
      case BatchSourceType.species:
        if (_selectedSpecies.isNotEmpty) {
          src = src.where((d) =>
              d.espece.toLowerCase() == _selectedSpecies.toLowerCase());
        }
        break;
      case BatchSourceType.tag:
        if (_selectedTag.isNotEmpty) {
          src = src.where((d) => d.tags.contains(_selectedTag));
        }
        break;
    }

    // Filtres combinés (s'appliquent quel que soit le source type, sauf
    // doublon avec la source principale)
    if (_extraSpeciesFilter.isNotEmpty &&
        _sourceType != BatchSourceType.species) {
      src = src.where((d) =>
          d.espece.toLowerCase() == _extraSpeciesFilter.toLowerCase());
    }
    if (_extraTagFilter.isNotEmpty && _sourceType != BatchSourceType.tag) {
      src = src.where((d) => d.tags.contains(_extraTagFilter));
    }

    final list = src.toList();
    _applySort(list);
    return list;
  }

  void _applySort(List<Dino> list) {
    switch (_sort) {
      case BatchSortType.alphaName:
        list.sort(
            (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        break;
      case BatchSortType.levelDesc:
        list.sort((a, b) => b.niveau.compareTo(a.niveau));
        break;
      case BatchSortType.colorId0Asc:
        list.sort((a, b) {
          final c = a.colorId0.compareTo(b.colorId0);
          if (c != 0) return c;
          return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
        });
        break;
      case BatchSortType.speciesThenName:
        list.sort((a, b) {
          final s =
              a.espece.toLowerCase().compareTo(b.espece.toLowerCase());
          if (s != 0) return s;
          return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
        });
        break;
      case BatchSortType.dateAdded:
        list.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
        break;
    }
  }

  bool get _statsAvailable {
    // Stats commune ne fait du sens que mono-espèce
    return _sourceType == BatchSourceType.species &&
        _selectedSpecies.isNotEmpty;
  }

  int _computePageCount(int totalDinos) {
    if (totalDinos == 0) return 0;
    return (totalDinos / _perImage).ceil();
  }

  String _titleForPage(int pageIndex, int total, List<Dino> pageDinos) {
    final base = _customTitleBase.trim().isNotEmpty
        ? _customTitleBase.trim()
        : _autoTitleBase();
    final page = '${pageIndex + 1}/$total';
    if (_showPageNumber) return '$base — Page $page';
    return base;
  }

  String _autoTitleBase() {
    switch (_sourceType) {
      case BatchSourceType.all:
        return 'Ma collection';
      case BatchSourceType.species:
        return _selectedSpecies.isEmpty
            ? 'Espèce'
            : DinoHelpers.toTitleCase(_selectedSpecies);
      case BatchSourceType.tag:
        return _selectedTag.isEmpty ? 'Tag' : _selectedTag;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  LANCEMENT DE L'EXPORT BATCH
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _startExport() async {
    final provider = context.read<DinoProvider>();
    final allTargets = _resolveDinos(provider);
    if (allTargets.isEmpty) {
      _toast('Aucun dino correspond aux critères', danger: true);
      return;
    }
    final totalPages = _computePageCount(allTargets.length);
    setState(() {
      _running = true;
      _cancelRequested = false;
      _totalPages = totalPages;
      _currentPage = 0;
      _firstFailedPage = -1;
      _log.clear();
    });
    await _runBatch(allTargets, startPage: 0);
  }

  /// Reprise : ne (re)lance que les pages à partir de [startPage].
  Future<void> _resumeFrom(int startPage) async {
    final provider = context.read<DinoProvider>();
    final allTargets = _resolveDinos(provider);
    if (allTargets.isEmpty) return;
    final totalPages = _computePageCount(allTargets.length);
    setState(() {
      _running = true;
      _cancelRequested = false;
      _totalPages = totalPages;
      _currentPage = startPage;
      _firstFailedPage = -1;
    });
    await _runBatch(allTargets, startPage: startPage);
  }

  Future<void> _runBatch(List<Dino> all, {required int startPage}) async {
    final totalPages = _computePageCount(all.length);

    for (int p = startPage; p < totalPages; p++) {
      if (_cancelRequested) {
        setState(() => _firstFailedPage = p);
        _log.insert(0, '⛔ Annulé à la page ${p + 1}/$totalPages');
        break;
      }
      setState(() => _currentPage = p);

      final fromIdx = p * _perImage;
      final toIdx = (fromIdx + _perImage).clamp(0, all.length);
      final pageDinos = all.sublist(fromIdx, toIdx);
      final pageTitle = _titleForPage(p, totalPages, pageDinos);

      try {
        await CanvaExporter.capture(
          context: context,
          dinos: pageDinos,
          canvasBuilder: (scale) =>
              _buildPageCanvas(pageDinos, pageTitle, scale),
          fileName: CanvaExporter.generateFileName(
              '${_autoTitleBase()}_P${p + 1}'),
          displayName: '$pageTitle (${pageDinos.length} dinos)',
        );
        _log.insert(0, '✓ Page ${p + 1}/$totalPages sauvegardée');
      } catch (e) {
        _log.insert(0, '✗ Page ${p + 1} échouée : $e');
        if (_firstFailedPage == -1) {
          setState(() => _firstFailedPage = p);
        }
      }

      if (!mounted) return;
      setState(() {});

      // Respiration pour l'OS / image cache
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (!mounted) return;
    setState(() => _running = false);

    if (!_cancelRequested && _firstFailedPage == -1) {
      _toast('$totalPages images sauvegardées dans la galerie');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  //  RENDU D'UNE PAGE (réutilise CanvaLayout + CanvaBubble + StatsBubble)
  // ─────────────────────────────────────────────────────────────────────

  Widget _buildPageCanvas(
      List<Dino> pageDinos, String title, double scale) {
    final withStats = _showStats && _statsAvailable && pageDinos.isNotEmpty;
    final statsDino = withStats ? pageDinos.first : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Espace réservé au titre (proportionnel à scale)
        final titleHeight = _showTitle ? 80.0 * (scale / 2.5) : 0.0;
        final canvasZoneTop = titleHeight;
        final canvasZoneHeight = h - canvasZoneTop;

        final placements = CanvaLayout.compute(
          nDinos: pageDinos.length,
          withStatsBubble: withStats,
          zoneSize: Size(w, canvasZoneHeight),
          scale: scale,
        );

        return Container(
          color: const Color(0xFF0F1115),
          child: Stack(
            children: [
              // Titre
              if (_showTitle)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: titleHeight,
                  child: SpeciesTitleBanner(
                    species: title,
                    exportScale: scale,
                  ),
                ),
              // Bulles dinos
              for (int i = 0; i < pageDinos.length; i++)
                Positioned.fromRect(
                  rect: placements.dinoSlots[i].shift(Offset(0, canvasZoneTop)),
                  child: CanvaBubble(
                    dino: pageDinos[i],
                    isFavorite: false,
                    exportScale: scale,
                    speciesTagOverride:
                        _sourceType == BatchSourceType.species
                            ? null
                            : pageDinos[i].espece,
                  ),
                ),
              // Bulle stats
              if (withStats &&
                  placements.statsRect != null &&
                  statsDino != null)
                Positioned.fromRect(
                  rect: placements.statsRect!
                      .shift(Offset(0, canvasZoneTop)),
                  child: StatsBubble(
                    dino: statsDino,
                    label: 'Stats communes',
                    exportScale: scale,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  //  UI
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: _running ? _buildRunningUI() : _buildConfigUI(),
      ),
    );
  }

  // ─── UI de configuration ────────────────────────────────────────────
  Widget _buildConfigUI() {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        final preview = _resolveDinos(provider);
        final totalPages = _computePageCount(preview.length);

        // Espèces & tags disponibles
        final speciesSet = <String, int>{};
        final tagSet = <String, int>{};
        for (final d in provider.allDinos) {
          speciesSet[d.espece] = (speciesSet[d.espece] ?? 0) + 1;
          for (final t in d.tags) {
            tagSet[t] = (tagSet[t] ?? 0) + 1;
          }
        }
        final speciesList = speciesSet.keys.toList()
          ..sort((a, b) => speciesSet[b]!.compareTo(speciesSet[a]!));
        final tagList = tagSet.keys.toList()
          ..sort((a, b) => tagSet[b]!.compareTo(tagSet[a]!));

        return Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _sectionTitle('📦 SOURCE'),
                  _radio(
                    label:
                        'Toute la bibliothèque (${provider.allDinos.length} dinos)',
                    selected: _sourceType == BatchSourceType.all,
                    onTap: () =>
                        setState(() => _sourceType = BatchSourceType.all),
                  ),
                  _radio(
                    label: 'Une espèce',
                    selected: _sourceType == BatchSourceType.species,
                    onTap: () => setState(
                        () => _sourceType = BatchSourceType.species),
                    trailing: _sourceType == BatchSourceType.species
                        ? _dropdown(
                            value: _selectedSpecies,
                            hint: 'Choisir',
                            items: speciesList
                                .map((s) =>
                                    '$s (${speciesSet[s]})')
                                .toList(),
                            rawValues: speciesList,
                            onChanged: (v) {
                              setState(() {
                                _selectedSpecies = v ?? '';
                                if (!_statsAvailable) _showStats = false;
                              });
                            },
                          )
                        : null,
                  ),
                  _radio(
                    label: 'Un tag',
                    selected: _sourceType == BatchSourceType.tag,
                    onTap: () =>
                        setState(() => _sourceType = BatchSourceType.tag),
                    trailing: _sourceType == BatchSourceType.tag
                        ? _dropdown(
                            value: _selectedTag,
                            hint: 'Choisir',
                            items: tagList
                                .map((t) => '$t (${tagSet[t]})')
                                .toList(),
                            rawValues: tagList,
                            onChanged: (v) =>
                                setState(() => _selectedTag = v ?? ''),
                          )
                        : null,
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('🎯 FILTRES SUPPLÉMENTAIRES (optionnel)'),
                  Row(
                    children: [
                      Expanded(
                        child: _labeledDropdown(
                          label: 'Espèce',
                          value: _extraSpeciesFilter,
                          items: ['Aucun', ...speciesList],
                          rawValues: ['', ...speciesList],
                          enabled: _sourceType != BatchSourceType.species,
                          onChanged: (v) => setState(
                              () => _extraSpeciesFilter = v ?? ''),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _labeledDropdown(
                          label: 'Tag',
                          value: _extraTagFilter,
                          items: ['Aucun', ...tagList],
                          rawValues: ['', ...tagList],
                          enabled: _sourceType != BatchSourceType.tag,
                          onChanged: (v) =>
                              setState(() => _extraTagFilter = v ?? ''),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('🔢 NOMBRE PAR IMAGE'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _perImageOptions.map((n) {
                      final active = _perImage == n;
                      return GestureDetector(
                        onTap: () => setState(() => _perImage = n),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: active
                                ? const LinearGradient(colors: [
                                    Color(0xFFFF6B00),
                                    Color(0xFFFF9500),
                                  ])
                                : null,
                            color: active ? null : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: active
                                  ? Colors.transparent
                                  : AppTheme.borderColor,
                            ),
                          ),
                          child: Text(
                            '$n',
                            style: GoogleFonts.exo2(
                              color: active
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('🔤 TRI'),
                  ..._sortOption(
                      BatchSortType.alphaName, 'Alphabétique (nom)'),
                  ..._sortOption(
                      BatchSortType.levelDesc, 'Niveau décroissant'),
                  ..._sortOption(BatchSortType.colorId0Asc,
                      'Couleur région 0 (ID croissant)'),
                  ..._sortOption(BatchSortType.speciesThenName,
                      'Espèce → nom'),
                  ..._sortOption(
                      BatchSortType.dateAdded, 'Date d\'ajout'),

                  const SizedBox(height: 16),
                  _sectionTitle('🎨 OPTIONS CANVA'),
                  _checkbox(
                    label: 'Afficher le titre',
                    value: _showTitle,
                    onChanged: (v) => setState(() => _showTitle = v),
                  ),
                  if (_showTitle)
                    Padding(
                      padding: const EdgeInsets.only(left: 28, top: 4),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Titre personnalisé (vide = auto : ${_autoTitleBase()})',
                          hintStyle: GoogleFonts.exo2(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                          filled: true,
                          fillColor: AppTheme.bgCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: AppTheme.borderColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                        ),
                        style: GoogleFonts.exo2(
                            color: AppTheme.textPrimary, fontSize: 13),
                        onChanged: (v) =>
                            setState(() => _customTitleBase = v),
                      ),
                    ),
                  _checkbox(
                    label: _statsAvailable
                        ? 'Bulle de stats communes'
                        : 'Bulle de stats (mono-espèce uniquement)',
                    value: _showStats,
                    enabled: _statsAvailable,
                    onChanged: (v) => setState(() => _showStats = v),
                  ),
                  _checkbox(
                    label: 'Numérotation (Page X/N)',
                    value: _showPageNumber,
                    onChanged: (v) => setState(() => _showPageNumber = v),
                  ),

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            AppTheme.accentPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📊 APERÇU',
                          style: GoogleFonts.exo2(
                            color: AppTheme.accentPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${preview.length} dinos → $totalPages image${totalPages > 1 ? 's' : ''} de 1080×1350px',
                          style: GoogleFonts.exo2(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estimation : ~${(totalPages * 2.5).toStringAsFixed(0)} secondes',
                          style: GoogleFonts.exo2(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildConfigActionBar(preview.isEmpty),
          ],
        );
      },
    );
  }

  Widget _buildConfigActionBar(bool disabled) {
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + systemBottom),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: disabled ? null : _startExport,
              icon: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                'Lancer l\'export',
                style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w800, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentPrimary,
                disabledBackgroundColor:
                    AppTheme.accentPrimary.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── UI de progression ──────────────────────────────────────────────
  Widget _buildRunningUI() {
    final pct = _totalPages == 0
        ? 0.0
        : ((_currentPage + 1) / _totalPages).clamp(0.0, 1.0);
    final done = _firstFailedPage == -1 && !_cancelRequested
        ? null
        : (_cancelRequested ? 'Annulé' : 'Échec partiel');

    return Column(
      children: [
        _buildHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            children: [
              if (_running)
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6B00),
                    strokeWidth: 4,
                  ),
                )
              else
                Icon(
                  _cancelRequested
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  color: _cancelRequested
                      ? AppTheme.danger
                      : AppTheme.accentPrimary,
                  size: 56,
                ),
              const SizedBox(height: 16),
              Text(
                _running
                    ? 'Image ${_currentPage + 1} / $_totalPages'
                    : (done ?? 'Terminé'),
                style: GoogleFonts.cinzelDecorative(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _running ? pct : 1.0,
                  minHeight: 10,
                  backgroundColor: AppTheme.bgCard,
                  valueColor: const AlwaysStoppedAnimation(
                      Color(0xFFFF6B00)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${(pct * 100).round()}%',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: _log.isEmpty
                ? Center(
                    child: Text(
                      'Préparation...',
                      style: GoogleFonts.exo2(
                          color: AppTheme.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _log[i],
                        style: GoogleFonts.exo2(
                          color: _log[i].startsWith('✗')
                              ? AppTheme.danger
                              : _log[i].startsWith('⛔')
                                  ? const Color(0xFFFFD700)
                                  : AppTheme.textPrimary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        _buildRunActionBar(),
      ],
    );
  }

  Widget _buildRunActionBar() {
    final systemBottom = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + systemBottom),
      child: Row(
        children: [
          if (_running)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() => _cancelRequested = true);
                },
                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                label: const Text('Annuler'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(
                      color: AppTheme.danger.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            )
          else ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Fermer'),
              ),
            ),
            if (_firstFailedPage >= 0) ...[
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _resumeFrom(_firstFailedPage),
                  icon: const Icon(Icons.replay_rounded, size: 16),
                  label: Text(
                    'Reprendre page ${_firstFailedPage + 1}',
                    style: GoogleFonts.exo2(
                        fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─── Header commun ──────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 4),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: _running ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPORT AUTO',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _running ? 'GÉNÉRATION EN COURS' : 'CONFIGURATION',
                  style: GoogleFonts.exo2(
                    fontSize: 11,
                    color: AppTheme.accentPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers UI ─────────────────────────────────────────────────────
  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 6),
        child: Text(
          text,
          style: GoogleFonts.exo2(
            color: AppTheme.accentSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.4,
          ),
        ),
      );

  Widget _radio({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentPrimary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? AppTheme.accentPrimary.withValues(alpha: 0.4)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? AppTheme.accentPrimary
                    : AppTheme.textMuted,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.exo2(
                    color: selected
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  Widget _checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? () => onChanged(!value) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              Icon(
                value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                color: !enabled
                    ? AppTheme.textMuted.withValues(alpha: 0.4)
                    : (value
                        ? AppTheme.accentPrimary
                        : AppTheme.textMuted),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.exo2(
                    color: !enabled
                        ? AppTheme.textMuted.withValues(alpha: 0.5)
                        : AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sortOption(BatchSortType type, String label) {
    final selected = _sort == type;
    return [
      _radio(
        label: label,
        selected: selected,
        onTap: () => setState(() => _sort = type),
      ),
    ];
  }

  Widget _dropdown({
    required String value,
    required String hint,
    required List<String> items,
    required List<String> rawValues,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isDense: true,
          isExpanded: true,
          value: value.isEmpty ? null : value,
          hint: Text(
            hint,
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 12),
          ),
          dropdownColor: AppTheme.bgCard,
          style: GoogleFonts.exo2(
              color: AppTheme.textPrimary, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down,
              color: AppTheme.textMuted, size: 18),
          items: [
            for (int i = 0; i < items.length; i++)
              DropdownMenuItem(
                value: rawValues[i],
                child: Text(
                  items[i],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _labeledDropdown({
    required String label,
    required String value,
    required List<String> items,
    required List<String> rawValues,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: enabled ? 1 : 0.4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.exo2(
              color: AppTheme.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              value: enabled
                  ? (value.isEmpty ? '' : value)
                  : '',
              dropdownColor: AppTheme.bgCard,
              style: GoogleFonts.exo2(
                  color: enabled
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                  fontSize: 12),
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppTheme.textMuted, size: 18),
              items: [
                for (int i = 0; i < items.length; i++)
                  DropdownMenuItem(
                    value: rawValues[i],
                    child: Text(
                      items[i],
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  void _toast(String msg, {bool danger = false}) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: danger
                    ? AppTheme.danger.withValues(alpha: 0.6)
                    : AppTheme.accentPrimary.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: Text(
              msg,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (entry.mounted) entry.remove();
    });
  }
}
