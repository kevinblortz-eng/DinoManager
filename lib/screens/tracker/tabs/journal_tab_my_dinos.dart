// lib/screens/journal/journal_tab_my_dinos.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../models/ark_color_palette.dart';
import '../../../models/dino.dart';
import '../../../models/species_tracker.dart';
import '../../../providers/dino_provider.dart';
import '../../../providers/role_theme_provider.dart';
import '../../../providers/tracker_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/dino_card_widget.dart';
import '../../../widgets/share/selectable_halo.dart';
import '../../add_edit_dino_screen.dart';
import '../../dino_detail_screen.dart';
import '../../dino_canva_screen.dart';

class JournalTabMyDinos extends StatefulWidget {
  final String species;
  final List<Dino> dinos;
  final SpeciesTracker? tracker;

  const JournalTabMyDinos({
    super.key,
    required this.species,
    required this.dinos,
    this.tracker,
  });

  @override
  State<JournalTabMyDinos> createState() => _JournalTabMyDinosState();
}

class _JournalTabMyDinosState extends State<JournalTabMyDinos>
    with SingleTickerProviderStateMixin {
  late TabController _subTab;

  @override
  void initState() {
    super.initState();
    _subTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSubTabBar(),
        Expanded(
          child: TabBarView(
            controller: _subTab,
            children: [
              _LibrarySubTab(species: widget.species, dinos: widget.dinos),
              _TrackerSubTab(
                  species: widget.species, tracker: widget.tracker),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _subTab,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: _SpotlightIndicator(color: Colors.cyanAccent),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
        labelStyle:
            GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w800),
        unselectedLabelStyle:
            GoogleFonts.exo2(fontSize: 11, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(height: 34, text: 'Library'),
          Tab(height: 34, text: 'Trackers'),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIBRARY SUB-TAB
//
// Layout :
//   ┌─────────────────────────────────────────────────────┐
//   │ [🎨 Canva] [🗑️ Poubelle] ... [✅ Sélectionner] X/16 │  ← barre fixe
//   ├─────────────────────────────────────────────────────┤
//   │ Liste scrollable des tuiles                         │
//   └─────────────────────────────────────────────────────┘
//
// Mode NORMAL (défaut) :
//   - Tap court tuile  → ouvre DinoDetailScreen
//   - Tap long tuile   → popup delete unitaire
//   - Bouton Canva     → ouvre Canva VIDE (l'utilisateur ajoutera des dinos)
//   - Poubelle         → désactivée
//
// Mode SÉLECTION (après tap sur "Sélectionner") :
//   - Tap court tuile  → toggle halo
//   - Tap long tuile   → popup delete UNITAIRE (sur la tuile pressée)
//   - Bouton Canva     → ouvre Canva pré-rempli avec les cochés
//   - Poubelle         → supprime tous les cochés (avec confirmation)
//   - Tap sur "Sélectionner" à nouveau → sort du mode et vide la sélection
// ═══════════════════════════════════════════════════════════════════════════
class _LibrarySubTab extends StatefulWidget {
  final String species;
  final List<Dino> dinos;
  const _LibrarySubTab({required this.species, required this.dinos});

  @override
  State<_LibrarySubTab> createState() => _LibrarySubTabState();
}

class _LibrarySubTabState extends State<_LibrarySubTab> {
  bool _selectionMode = false;
  final Set<int> _selectedIds = <int>{};
  static const int _maxCanva = 16;

  // ─── Helpers ───────────────────────────────────────────────────────────
  bool get _allSelected {
    final selectable =
        widget.dinos.where((d) => d.id != null).map((d) => d.id!).toSet();
    if (selectable.isEmpty) return false;
    return selectable.every(_selectedIds.contains);
  }

  void _toggleAllOrNone() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        for (final d in widget.dinos) {
          if (d.id != null) _selectedIds.add(d.id!);
        }
      }
    });
  }

  void _toggleOne(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  // ─── Toast noir 1s centré ──────────────────────────────────────────────
  void _showCenterToast(String message) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (ctx) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Text(
              message,
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
    Future.delayed(const Duration(seconds: 1), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ─── Suppression ──────────────────────────────────────────────────────
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Supprimer $count dino${count > 1 ? 's' : ''} ?',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    final provider = context.read<DinoProvider>();
    for (final id in _selectedIds.toList()) {
      await provider.deleteDino(id);
    }
    if (!mounted) return;
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  /// Supprime UN dino précis (la tuile pressée), sans toucher aux autres
  /// dinos sélectionnés.
  Future<void> _deleteOne(Dino dino) async {
    if (dino.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ${dino.nom} ?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    await context.read<DinoProvider>().deleteDino(dino.id!);
    if (!mounted) return;
    setState(() => _selectedIds.remove(dino.id));
  }

  // ─── Ouverture Canva ───────────────────────────────────────────────────
  void _openCanva() {
    if (_selectedIds.length > _maxCanva) {
      _showCenterToast('Sélection limitée à $_maxCanva dinos pour le Canva');
      return;
    }

    // Si mode sélection actif : on passe les dinos cochés
    // Sinon : canvas vide, l'utilisateur ajoutera via "Modifier les dinos"
    final selectedDinos = _selectionMode
        ? widget.dinos
            .where((d) => d.id != null && _selectedIds.contains(d.id))
            .toList()
        : <Dino>[];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DinoCanvaScreen(
          species: widget.species,
          initialSelection: selectedDinos,
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.dinos.isEmpty) return _buildEmpty();

    return Column(
      children: [
        _buildActionBar(),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildEmpty() {
    // Même quand la liste est vide on garde la barre d'actions, parce que le
    // bouton Canva doit rester accessible (le user peut quand même créer un
    // canva vide… à condition d'avoir des dinos via "Modifier"). Mais comme
    // ici l'écran est scopé sur une espèce vide, on affiche surtout l'invite.
    return Column(
      children: [
        _buildActionBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🦕', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun dino pour cette espèce',
                    style: GoogleFonts.exo2(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Appuyez sur + dans l\'en-tête pour en ajouter un.',
                    style: GoogleFonts.exo2(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Barre d'actions (toujours visible) ───────────────────────────────
  Widget _buildActionBar() {
    final count = _selectedIds.length;
    final over = count > _maxCanva;
    final empty = count == 0;
    final counterColor =
        over ? AppTheme.danger : AppTheme.accentPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // ── Bouton Canva ─────────────────────────────────────────────
          _SquareIconButton(
            icon: Icons.dashboard_customize_rounded,
            color: const Color(0xFFFF6B00),
            enabled: !over,
            tooltip: 'Ouvrir le Canva',
            onTap: () {
              if (over) {
                _showCenterToast(
                    'Sélection limitée à $_maxCanva dinos pour le Canva');
                return;
              }
              _openCanva();
            },
          ),
          const SizedBox(width: 6),

          // ── Bouton Poubelle (actif seulement si sélection ≥ 1) ──────
          _SquareIconButton(
            icon: Icons.delete_outline_rounded,
            color: const Color(0xFF8B0000),
            bgColor: const Color(0xFFFFCCCC),
            enabled: !empty && _selectionMode,
            tooltip: empty
                ? 'Aucune sélection'
                : 'Supprimer ${count}',
            onTap: _deleteSelected,
          ),

          const Spacer(),

          // ── Compteur X/16 ────────────────────────────────────────────
          if (_selectionMode || count > 0)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: counterColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: counterColor.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$count/$_maxCanva',
                  style: GoogleFonts.exo2(
                    color: counterColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),

          // ── Bouton "Tous/Aucun" (visible seulement en mode sélection) ──
          if (_selectionMode) ...[
            GestureDetector(
              onTap: _toggleAllOrNone,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: _allSelected
                      ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _allSelected
                        ? AppTheme.accentPrimary
                        : Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _allSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: _allSelected
                          ? AppTheme.accentPrimary
                          : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _allSelected ? 'Aucun' : 'Tous',
                      style: GoogleFonts.exo2(
                        color: _allSelected
                            ? AppTheme.accentPrimary
                            : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],

          // ── Bouton "Sélectionner / Annuler" ──────────────────────────
          GestureDetector(
            onTap: _toggleSelectionMode,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: _selectionMode
                    ? null
                    : const LinearGradient(
                        colors: [
                          Color(0xFFFF6B00),
                          Color(0xFFFF9500),
                        ],
                      ),
                color: _selectionMode
                    ? Colors.white.withValues(alpha: 0.08)
                    : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _selectionMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _selectionMode
                        ? Icons.close_rounded
                        : Icons.check_box_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectionMode ? 'Annuler' : 'Sélectionner',
                    style: GoogleFonts.exo2(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Liste ─────────────────────────────────────────────────────────────
  Widget _buildList() {
    final roleTheme = context.watch<RoleThemeProvider>();
    final dinoProvider = context.read<DinoProvider>();
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(14, 4, 14, 24 + bottomPadding),
      itemCount: widget.dinos.length,
      itemBuilder: (context, i) {
        final dino = widget.dinos[i];
        final isSelected =
            dino.id != null && _selectedIds.contains(dino.id);

        final tile = DinoCardWidget(
          dino: dino,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => DinoDetailScreen(dino: dino)),
          ).then((_) => dinoProvider.loadDinos()),
          onEdit: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => AddEditDinoScreen(dino: dino)),
          ).then((_) => dinoProvider.loadDinos()),
          onDelete: () => _deleteOne(dino),
          roleTheme: roleTheme.themeForRole(dino.role),
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SelectableHalo(
              isSelected: isSelected,
              selectionMode: _selectionMode,
              // Mode sélection : tap court = toggle
              // Mode normal    : tap court = ouvre le détail (via le onTap
              //                  interne de la tuile, donc on laisse null)
              onTap: _selectionMode
                  ? () {
                      if (dino.id != null) _toggleOne(dino.id!);
                    }
                  : null,
              // Mode sélection : tap long = popup delete UNITAIRE
              //                  (sur cette tuile uniquement, pas les autres)
              // Mode normal    : tap long = popup delete unitaire aussi
              onLongPress: () => _deleteOne(dino),
              child: tile,
            ),
          ),
        );
      },
    );
  }
}

// ─── Bouton carré icône (utilisé pour Canva + Poubelle) ─────────────────
class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? bgColor;
  final bool enabled;
  final String? tooltip;
  final VoidCallback onTap;

  const _SquareIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.bgColor,
    this.enabled = true,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final effBg =
        bgColor ?? (enabled ? color.withValues(alpha: 0.15) : null);
    final btn = GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? effBg
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? color
                : Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: enabled
              ? color
              : Colors.white.withValues(alpha: 0.25),
          size: 20,
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TRACKER SUB-TAB — INCHANGÉ
// ═══════════════════════════════════════════════════════════════════════════
class _TrackerSubTab extends StatefulWidget {
  final String species;
  final SpeciesTracker? tracker;
  const _TrackerSubTab({required this.species, this.tracker});

  @override
  State<_TrackerSubTab> createState() => _TrackerSubTabState();
}

class _TrackerSubTabState extends State<_TrackerSubTab> {
  final Set<String> _hiddenStats = <String>{};
  final Set<int> _hiddenRegions = <int>{};

  static const _statLabels = {
    'hp': 'VIE',
    'stamina': 'STAM',
    'degats': 'ATTAQUE',
    'poids': 'POIDS',
    'nourriture': 'FOOD',
    'oxygene': 'OXYGENE',
  };
  static const _statColors = {
    'hp': Color(0xFF4CAF50),
    'stamina': Color(0xFFFFD700),
    'degats': Color(0xFFEF4444),
    'poids': Color(0xFF3B82F6),
    'nourriture': Color(0xFF8B5CF6),
    'oxygene': Color(0xFF10B981),
  };

  Future<void> _confirmDeleteStat(String trackerId, String key) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Supprimer ${_statLabels[key] ?? key} ?',
            style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Cette stat sera retirée du tracker et de toutes ses observations.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<TrackerProvider>().removeBestStat(
            trackerId: trackerId,
            statKey: key,
          );
    }
  }

  Future<void> _confirmDeleteColor(
      String trackerId, int region, int colorId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Retirer la couleur #$colorId (R$region) ?',
            style: const TextStyle(color: Colors.white)),
        content: const Text(
          'La couleur sera retirée de la banque et des observations.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<TrackerProvider>().removeAnonymousColor(
            trackerId: trackerId,
            region: region,
            colorId: colorId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<TrackerProvider>();
    SpeciesTracker? tracker;
    for (final t in tp.trackers) {
      if (t.species.toLowerCase() == widget.species.toLowerCase()) {
        tracker = t;
        break;
      }
    }

    if (tracker == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.science_outlined,
                  size: 48, color: Colors.white24),
              const SizedBox(height: 12),
              Text(
                'Aucun tracker pour ${widget.species}',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sauvegarde des stats ou couleurs depuis la fiche d\'un dino pour l\'initier.',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final tracker0 = tracker;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _buildStatsSection(tracker0),
        const SizedBox(height: 16),
        _buildColorBankSection(tracker0),
      ],
    );
  }

  Widget _buildStatsSection(SpeciesTracker tracker) {
    final entries = tracker.bestStats.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart,
                  color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'MEILLEURES STATS',
                style: GoogleFonts.exo2(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'Aucune stat enregistrée.',
              style: GoogleFonts.exo2(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...entries.map((e) {
              final key = e.key;
              final rec = e.value;
              final hidden = _hiddenStats.contains(key);
              final color = _statColors[key] ?? Colors.cyanAccent;
              final label = _statLabels[key] ?? key.toUpperCase();
              final isPct = key == 'degats';
              final display = isPct
                  ? '${rec.value.toStringAsFixed(1)}%'
                  : (rec.value == rec.value.roundToDouble()
                      ? rec.value.round().toString()
                      : rec.value.toStringAsFixed(1));

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withValues(alpha: hidden ? 0.15 : 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        label,
                        style: GoogleFonts.exo2(
                          color: hidden
                              ? Colors.white.withValues(alpha: 0.35)
                              : Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        display,
                        style: GoogleFonts.exo2(
                          color: hidden ? color.withValues(alpha: 0.3) : color,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (rec.points != null && rec.points! > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '+${rec.points} pts',
                          style: GoogleFonts.exo2(
                            color: color.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        hidden ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      tooltip: hidden ? 'Afficher' : 'Masquer',
                      onPressed: () => setState(() {
                        if (hidden) {
                          _hiddenStats.remove(key);
                        } else {
                          _hiddenStats.add(key);
                        }
                      }),
                    ),
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.danger),
                      tooltip: 'Supprimer la stat',
                      onPressed: () => _confirmDeleteStat(tracker.id, key),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildColorBankSection(SpeciesTracker tracker) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette_rounded,
                  color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 6),
              Text(
                'BANQUE DE COULEURS',
                style: GoogleFonts.exo2(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int r = 0; r < 6; r++) _buildRegionEditor(tracker, r),
        ],
      ),
    );
  }

  Widget _buildRegionEditor(SpeciesTracker tracker, int region) {
    final ids = (tracker.colorBank[region] ?? const <int>[]).toList()..sort();
    final hidden = _hiddenRegions.contains(region);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: hidden ? 0.05 : 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'R$region',
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${ids.length} couleur${ids.length > 1 ? 's' : ''}',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              IconButton(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  hidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
                onPressed: () => setState(() {
                  if (hidden) {
                    _hiddenRegions.remove(region);
                  } else {
                    _hiddenRegions.add(region);
                  }
                }),
              ),
            ],
          ),
          if (!hidden && ids.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: ids.map((id) {
                  final ark = ArkColorPalette.fromId(id);
                  final color = ark?.color ?? Colors.grey;
                  final textColor = color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white;
                  return GestureDetector(
                    onLongPress: () =>
                        _confirmDeleteColor(tracker.id, region, id),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 42,
                          height: 28,
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
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => _confirmDeleteColor(
                                tracker.id, region, id),
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: const BoxDecoration(
                                color: AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  size: 11, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else if (!hidden)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Aucune couleur',
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpotlightIndicator extends Decoration {
  final Color color;
  const _SpotlightIndicator({required this.color});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _SpotlightPainter(color);
}

class _SpotlightPainter extends BoxPainter {
  final Color color;
  _SpotlightPainter(this.color);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size ?? Size.zero;
    if (size == Size.zero) return;
    final rect = offset & size;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.7,
        colors: [
          color.withValues(alpha: 0.55),
          color.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(8)),
      paint,
    );

    final underline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(rect.left + 14, rect.bottom - 3),
      Offset(rect.right - 14, rect.bottom - 3),
      underline,
    );
  }
}
