// lib/screens/dino_canva_multi_screen.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ CANVA SCREEN — Multi-espèces (composition 4:5, 1080×1350)             ║
// ║                                                                        ║
// ║ Variante de DinoCanvaScreen qui accepte des dinos de plusieurs        ║
// ║ espèces. Différences notables :                                       ║
// ║   - Le bandeau titre général ne montre l'espèce que si UNE seule est  ║
// ║     présente ; sinon il affiche "COMPOSITION MULTI".                  ║
// ║   - Chaque bulle reçoit un petit bandeau d'espèce au-dessus DÈS qu'il ║
// ║     y a plus d'une espèce dans la sélection.                          ║
// ║   - Le toggle "Stats commune/favori" est désactivé si > 1 espèce      ║
// ║     (et _showStats est forcé à false dans ce cas).                    ║
// ║   - Le picker ouvert est DinoCanvaMultiPickerScreen (toutes espèces). ║
// ╚════════════════════════════════════════════════════════════════════════╝
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/canva/canva_bubble_widgets.dart';
import '../widgets/canva/canva_exporter.dart';
import '../widgets/canva/canva_layout_engine.dart';
import 'dino_canva_multi_picker_screen.dart';

class DinoCanvaMultiScreen extends StatefulWidget {
  final List<Dino> initialSelection;

  const DinoCanvaMultiScreen({
    super.key,
    this.initialSelection = const [],
  });

  @override
  State<DinoCanvaMultiScreen> createState() => _DinoCanvaMultiScreenState();
}

class _DinoCanvaMultiScreenState extends State<DinoCanvaMultiScreen> {
  // ─── State ─────────────────────────────────────────────────────────────
  late List<Dino> _ordered;
  Dino? _favorite;
  bool _showSpeciesTitle = true;
  bool _showStats = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _ordered = List.of(widget.initialSelection)
      // Tri : espèce puis nom (regroupe les espèces dans le canva)
      ..sort((a, b) {
        final s = a.espece.toLowerCase().compareTo(b.espece.toLowerCase());
        if (s != 0) return s;
        return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
      });
  }

  // ═════════════════════════════════════════════════════════════════════
  //  ESPÈCES & STATS
  // ═════════════════════════════════════════════════════════════════════

  /// Ensemble distinct des espèces présentes dans la sélection.
  Set<String> get _uniqueSpecies =>
      _ordered.map((d) => d.espece.toLowerCase()).toSet();

  bool get _isMultiSpecies => _uniqueSpecies.length > 1;

  /// L'unique espèce si mono-espèce, sinon null.
  String? get _singleSpeciesOrNull =>
      _uniqueSpecies.length == 1 ? _ordered.first.espece : null;

  bool get _allStatsAbsent {
    if (_ordered.isEmpty) return true;
    for (final d in _ordered) {
      if (d.hp > 0 ||
          d.stamina > 0 ||
          d.degats > 0 ||
          d.poids > 0 ||
          d.nourriture > 0 ||
          d.oxygene > 0) {
        return false;
      }
    }
    return true;
  }

  /// Stats activable uniquement si mono-espèce ET au moins une stat présente.
  bool get _statsToggleEnabled =>
      !_isMultiSpecies && !_allStatsAbsent && _ordered.isNotEmpty;

  String get _statsLabel =>
      _favorite != null ? 'Stats favori' : 'Stats communes';

  /// Source pour la bulle stats (favori en priorité, sinon stats communes).
  /// Appelée uniquement en mono-espèce → safe.
  Dino get _statsSourceDino {
    if (_favorite != null) return _favorite!;
    if (_ordered.isEmpty) {
      return Dino.empty();
    }
    final first = _ordered.first;

    int commonInt(int Function(Dino) g) {
      final v = g(first);
      for (final d in _ordered) {
        if (g(d) != v) return 0;
      }
      return v;
    }

    double commonDbl(double Function(Dino) g) {
      final v = g(first);
      for (final d in _ordered) {
        if (g(d) != v) return 0;
      }
      return v;
    }

    return first.copyWith(
      hp: commonInt((d) => d.hp),
      stamina: commonInt((d) => d.stamina),
      degats: commonDbl((d) => d.degats),
      poids: commonInt((d) => d.poids),
      nourriture: commonInt((d) => d.nourriture),
      oxygene: commonInt((d) => d.oxygene),
      hpPoints: 0,
      staminaPoints: 0,
      degatsPoints: 0,
      poidsPoints: 0,
      nourriturePoints: 0,
      oxygenePoints: 0,
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  //  REORDER & PICKER
  // ═════════════════════════════════════════════════════════════════════

  void _swap(int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    if (from >= _ordered.length || to >= _ordered.length) return;
    setState(() {
      final tmp = _ordered[from];
      _ordered[from] = _ordered[to];
      _ordered[to] = tmp;
    });
  }

  Future<void> _openEditModal() async {
    final result = await Navigator.push<DinoCanvaMultiPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DinoCanvaMultiPickerScreen(
          initialSelection: _ordered,
          initialFavorite: _favorite,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      // Préserve l'ordre courant pour les dinos toujours présents,
      // ajoute les nouveaux à la fin (tri espèce+nom).
      final keptInOrder = _ordered
          .where((d) => result.selected.any((r) => r.id == d.id))
          .toList();
      final newOnes = result.selected
          .where((r) => !_ordered.any((d) => d.id == r.id))
          .toList()
        ..sort((a, b) {
          final s =
              a.espece.toLowerCase().compareTo(b.espece.toLowerCase());
          if (s != 0) return s;
          return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
        });
      _ordered = [...keptInOrder, ...newOnes];
      _favorite = result.favorite;
      // Force stats à false si on passe en multi-espèces ou si plus de stats
      if (!_statsToggleEnabled) _showStats = false;
    });
  }

  Future<void> _confirmRemoveDino(int index) async {
    if (index < 0 || index >= _ordered.length) return;
    final dino = _ordered[index];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Retirer ${dino.nom.isEmpty ? "ce dino" : dino.nom} du Canva ?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Le dino reste dans ta bibliothèque, il est juste retiré de cette composition.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() {
      final removed = _ordered.removeAt(index);
      if (_favorite?.id == removed.id) _favorite = null;
      if (!_statsToggleEnabled) _showStats = false;
    });
  }

  Future<void> _confirmHideStats() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Masquer la bulle Stats ?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Tu pourras la réafficher avec le bouton "Stats" en bas.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentPrimary,
            ),
            child: const Text('Masquer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _showStats = false);
  }

  // ═════════════════════════════════════════════════════════════════════
  //  EXPORT
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _captureAndSave() async {
    if (_isCapturing || _ordered.isEmpty) return;
    setState(() => _isCapturing = true);
    try {
      final prefix = _isMultiSpecies
          ? 'MULTI_${_uniqueSpecies.length}sp'
          : (_singleSpeciesOrNull ?? 'MULTI');
      await CanvaExporter.capture(
        context: context,
        dinos: _ordered,
        canvasBuilder: (scale) =>
            _buildCanvasContent(forExport: true, exportScale: scale),
        fileName: CanvaExporter.generateFileName(prefix),
        displayName: _isMultiSpecies
            ? 'Canva multi — ${_ordered.length} dinos, ${_uniqueSpecies.length} esp.'
            : '${_singleSpeciesOrNull ?? "Canva"} — Canva ${_ordered.length} dinos',
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  //  BUILD PRINCIPAL
  // ═════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isEmpty = _ordered.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildExportButton(),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _buildCanvasContent(
                        forExport: false,
                        exportScale: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _buildTogglesRow(),
              if (!isEmpty) ...[
                const SizedBox(height: 6),
                _buildEditButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    final subtitle = _ordered.isEmpty
        ? 'AUCUN DINO'
        : (_isMultiSpecies
            ? '${_uniqueSpecies.length} ESPÈCES • ${_ordered.length} DINOS'
            : '${(_singleSpeciesOrNull ?? "").toUpperCase()} • ${_ordered.length} DINOS');
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CANVA MULTI',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.exo2(
              fontSize: 10,
              color: const Color(0xFF00E5FF),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    final disabled = _isCapturing || _ordered.isEmpty;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: disabled ? null : _captureAndSave,
        icon: _isCapturing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_alt_rounded, size: 18),
        label: Text(
          _isCapturing ? 'Export en cours…' : 'Exporter le Canva',
          style: GoogleFonts.exo2(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00E5FF),
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildTogglesRow() {
    final statsTooltip = _isMultiSpecies
        ? 'Indisponible avec plusieurs espèces'
        : (_allStatsAbsent ? 'Aucune stat disponible' : '');
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Titre',
            icon: Icons.title_rounded,
            active: _showSpeciesTitle,
            onTap: () =>
                setState(() => _showSpeciesTitle = !_showSpeciesTitle),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ToggleChip(
            label: _statsLabel,
            icon: Icons.bar_chart_rounded,
            active: _showStats,
            enabled: _statsToggleEnabled,
            onTap: () {
              if (!_statsToggleEnabled) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(statsTooltip),
                    duration: const Duration(seconds: 1),
                  ),
                );
                return;
              }
              setState(() => _showStats = !_showStats);
            },
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            '${_ordered.length}/16',
            style: GoogleFonts.exo2(
              color: _ordered.length > 16
                  ? AppTheme.danger
                  : Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openEditModal,
        icon: const Icon(Icons.tune_rounded, size: 18),
        label: Text(
          'Modifier les dinos (${_ordered.length})',
          style: GoogleFonts.exo2(
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════
  //  CANVAS CONTENT
  // ═════════════════════════════════════════════════════════════════════

  Widget _buildCanvasContent({
    required bool forExport,
    required double exportScale,
  }) {
    final showStatsBubble = _showStats && _statsToggleEnabled;
    final isMulti = _isMultiSpecies;

    // Titre général :
    //   - mono : nom de l'espèce
    //   - multi : "COMPOSITION MULTI"
    final headerTitle = isMulti
        ? 'COMPOSITION MULTI'
        : (_singleSpeciesOrNull ?? '');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: const Color(0xFF5A5A5A),
          width: 3 * exportScale,
        ),
        borderRadius: forExport ? null : BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              if (_showSpeciesTitle && headerTitle.isNotEmpty)
                SpeciesTitleBanner(
                  species: headerTitle,
                  exportScale: exportScale,
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final placements = CanvaLayout.compute(
                      nDinos: _ordered.length,
                      withStatsBubble: showStatsBubble,
                      zoneSize: size,
                      scale: exportScale,
                    );

                    return Stack(
                      children: [
                        for (int i = 0;
                            i < _ordered.length &&
                                i < placements.dinoSlots.length;
                            i++)
                          Positioned.fromRect(
                            rect: placements.dinoSlots[i],
                            child: _DraggableBubbleSlot(
                              index: i,
                              dino: _ordered[i],
                              isFavorite:
                                  _favorite?.id == _ordered[i].id,
                              // En multi : chaque bulle reçoit le nom
                              // de son espèce au-dessus.
                              speciesTag: isMulti
                                  ? _ordered[i].espece
                                  : null,
                              onSwapWith: (other) => _swap(i, other),
                              onDoubleTapDelete: () =>
                                  _confirmRemoveDino(i),
                              interactive: !forExport,
                              exportScale: exportScale,
                            ),
                          ),
                        if (placements.statsRect != null)
                          Positioned.fromRect(
                            rect: placements.statsRect!,
                            child: forExport
                                ? StatsBubble(
                                    dino: _statsSourceDino,
                                    label: _statsLabel,
                                    exportScale: exportScale,
                                  )
                                : GestureDetector(
                                    onDoubleTap: _confirmHideStats,
                                    child: RepaintBoundary(
                                      child: StatsBubble(
                                        dino: _statsSourceDino,
                                        label: _statsLabel,
                                        exportScale: exportScale,
                                      ),
                                    ),
                                  ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // ── Bouton "Modifier les dinos" central si canvas vide ──────
          if (_ordered.isEmpty && !forExport)
            Positioned.fill(
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: _openEditModal,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  label: Text(
                    'Modifier les dinos',
                    style: GoogleFonts.exo2(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TOGGLE CHIP
// ═══════════════════════════════════════════════════════════════════════════

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = !enabled;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: (active && !disabled)
              ? const LinearGradient(colors: [
                  Color(0xFFFF6B00),
                  Color(0xFFFF9500),
                ])
              : null,
          color: (active && !disabled)
              ? null
              : (disabled
                  ? Colors.white.withValues(alpha: 0.03)
                  : Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? Colors.white.withValues(alpha: 0.08)
                : (active
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.2)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: disabled
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.exo2(
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  DRAGGABLE BUBBLE SLOT (variante multi : passe speciesTag à CanvaBubble)
// ═══════════════════════════════════════════════════════════════════════════

class _DraggableBubbleSlot extends StatelessWidget {
  final int index;
  final Dino dino;
  final bool isFavorite;

  /// Nom de l'espèce à afficher au-dessus de la bulle (multi-espèces).
  /// null en mono-espèce → pas de bandeau.
  final String? speciesTag;

  final void Function(int otherIndex) onSwapWith;
  final VoidCallback onDoubleTapDelete;
  final bool interactive;
  final double exportScale;

  const _DraggableBubbleSlot({
    required this.index,
    required this.dino,
    required this.isFavorite,
    required this.speciesTag,
    required this.onSwapWith,
    required this.onDoubleTapDelete,
    required this.interactive,
    required this.exportScale,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = RepaintBoundary(
      child: CanvaBubble(
        dino: dino,
        isFavorite: isFavorite,
        exportScale: exportScale,
        speciesTagOverride: speciesTag,
      ),
    );

    if (!interactive) return bubble;

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onSwapWith(d.data),
      builder: (context, candidate, rejected) {
        final isTarget = candidate.isNotEmpty;
        return GestureDetector(
          onDoubleTap: onDoubleTapDelete,
          child: Draggable<int>(
            data: index,
            feedback: Material(
              color: Colors.transparent,
              child: Opacity(
                opacity: 0.85,
                child: SizedBox(
                  width: 130,
                  height: 130,
                  child: bubble,
                ),
              ),
            ),
            childWhenDragging: Opacity(opacity: 0.25, child: bubble),
            child: Container(
              decoration: isTarget
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPrimary
                              .withValues(alpha: 0.6),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ],
                    )
                  : null,
              child: bubble,
            ),
          ),
        );
      },
    );
  }
}
