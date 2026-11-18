// lib/screens/dino_canva_screen.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ CANVA SCREEN — Mono-espèce (composition 4:5, 1080×1350)               ║
// ║                                                                        ║
// ║ Cet écran est un assembleur : il consomme les briques partagées       ║
// ║ (CanvaBubble, StatsBubble, SpeciesTitleBanner, CanvaLayout,           ║
// ║  CanvaExporter) et n'implémente que sa propre logique d'état :        ║
// ║   - sélection des dinos (via DinoCanvaPickerScreen),                  ║
// ║   - réordonnancement par drag & drop,                                 ║
// ║   - toggles "Titre espèce" et "Stats commune/favori",                 ║
// ║   - export PNG.                                                       ║
// ╚════════════════════════════════════════════════════════════════════════╝
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/canva/canva_bubble_widgets.dart';
import '../widgets/canva/canva_exporter.dart';
import '../widgets/canva/canva_layout_engine.dart';
import 'dino_canva_picker_screen.dart';
import 'dino_canva_batch_export_screen.dart';


class DinoCanvaScreen extends StatefulWidget {
  final String species;
  final List<Dino> initialSelection;
  final bool filterBySpecies; // ← AJOUT

  const DinoCanvaScreen({
    super.key,
    required this.species,
    this.initialSelection = const [],
    this.filterBySpecies = true, // ← AJOUT (défaut true = rétro-compatible)
  });

  @override
  State<DinoCanvaScreen> createState() => _DinoCanvaScreenState();
}

class _DinoCanvaScreenState extends State<DinoCanvaScreen> {
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
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  }

  // ═════════════════════════════════════════════════════════════════════
  //  STATS COMMUNES / FAVORI
  // ═════════════════════════════════════════════════════════════════════

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

  Dino get _statsSourceDino {
    if (_favorite != null) return _favorite!;
    if (_ordered.isEmpty) {
      return Dino.empty().copyWith(espece: widget.species, nom: widget.species);
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

  String get _statsLabel =>
      _favorite != null ? 'Stats favori' : 'Stats communes';

  bool get _statsToggleEnabled => !_allStatsAbsent && _ordered.isNotEmpty;

  // ═════════════════════════════════════════════════════════════════════
  //  REORDER & MODAL
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
  final result = await Navigator.push<DinoCanvaPickerResult>(
    context,
    MaterialPageRoute(
      builder: (_) => DinoCanvaPickerScreen(
        species: widget.species,
        initialSelection: _ordered,
        initialFavorite: _favorite,
        filterBySpecies: widget.filterBySpecies, // ← AJOUT
      ),
    ),
  );

    if (result == null || !mounted) return;
    setState(() {
      // Préserve l'ordre courant pour les dinos toujours présents,
      // ajoute les nouveaux à la fin (tri alphabétique).
      final keptInOrder = _ordered
          .where((d) => result.selected.any((r) => r.id == d.id))
          .toList();
      final newOnes = result.selected
          .where((r) => !_ordered.any((d) => d.id == r.id))
          .toList()
        ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
      _ordered = [...keptInOrder, ...newOnes];
      _favorite = result.favorite;
      if (_allStatsAbsent) _showStats = false;
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
      if (_allStatsAbsent) _showStats = false;
    });
  }

void _openBatchExport() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DinoCanvaBatchExportScreen(
        initialDinos: _ordered, // ou _dinos selon ton nom de variable
      ),
    ),
  );
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
      await CanvaExporter.capture(
        context: context,
        dinos: _ordered,
        canvasBuilder: (scale) =>
            _buildCanvasContent(forExport: true, exportScale: scale),
        fileName: CanvaExporter.generateFileName(widget.species),
        displayName:
            '${widget.species} — Canva ${_ordered.length} dinos',
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
            'CANVA',
            style: GoogleFonts.cinzelDecorative(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            widget.species.toUpperCase(),
            style: GoogleFonts.exo2(
              fontSize: 10,
              color: AppTheme.accentPrimary,
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
  return Row(
    children: [
      Expanded(
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
            _isCapturing ? 'Export…' : 'Exporter',
            style: GoogleFonts.exo2(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
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
      ),
      const SizedBox(width: 8),
      // ─── Bouton Export auto (série) ───────────────────────────────
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.auto_awesome_motion_rounded,
            color: Color(0xFFFFD700),
          ),
          tooltip: 'Export auto en série',
          onPressed: _isCapturing ? null : _openBatchExport,
        ),
      ),
    ],
  );
}

  Widget _buildTogglesRow() {
    return Row(
      children: [
        Expanded(
          child: _ToggleChip(
            label: 'Espèce',
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
                  const SnackBar(
                    content: Text('Aucune stat disponible'),
                    duration: Duration(seconds: 1),
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
          // ── Contenu principal (titre + grille) ─────────────────────
          Column(
            children: [
              if (_showSpeciesTitle)
                SpeciesTitleBanner(
                  species: widget.species,
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
                              isFavorite: _favorite?.id == _ordered[i].id,
                              onSwapWith: (other) => _swap(i, other),
                              onDoubleTapDelete: () => _confirmRemoveDino(i),
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
//  TOGGLE CHIP (utilisé localement pour les toggles "Espèce" et "Stats")
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
//  DRAGGABLE BUBBLE SLOT
//  - RepaintBoundary autour de chaque bulle (isole les repaints)
//  - Container simple (pas AnimatedContainer) pour le halo target
//  - Double-tap → callback de suppression
// ═══════════════════════════════════════════════════════════════════════════

class _DraggableBubbleSlot extends StatelessWidget {
  final int index;
  final Dino dino;
  final bool isFavorite;
  final void Function(int otherIndex) onSwapWith;
  final VoidCallback onDoubleTapDelete;
  final bool interactive;
  final double exportScale;

  const _DraggableBubbleSlot({
    required this.index,
    required this.dino,
    required this.isFavorite,
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
