// lib/screens/tracker/species_tracker_detail_screen.dart
import 'dart:math';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';
import '../../models/species_tracker.dart';
import '../../models/ark_color_palette.dart';
import '../../providers/dino_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dino_image_widget.dart';

class SpeciesTrackerDetailScreen extends StatefulWidget {
  final SpeciesTracker tracker;

  const SpeciesTrackerDetailScreen({super.key, required this.tracker});

  @override
  State<SpeciesTrackerDetailScreen> createState() =>
      _SpeciesTrackerDetailScreenState();
}

class _SpeciesTrackerDetailScreenState
    extends State<SpeciesTrackerDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SpeciesTracker _tracker;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tracker = widget.tracker;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshTracker() {
    final tp = Provider.of<TrackerProvider>(context, listen: false);
    final updated = tp.trackers.where((t) => t.id == _tracker.id).firstOrNull;
    if (updated != null) setState(() => _tracker = updated);
  }

  List<Dino> _getLibraryDinos(DinoProvider dp) {
    return dp.allDinos // FIX BUG-LIB-01
        .where((d) => d.espece.toLowerCase() == _tracker.species.toLowerCase())
        .toList();
  }

  Map<String, _MergedStat> _buildMergedStats(
      List<Dino> libraryDinos, SpeciesTracker tracker) {
    final merged = <String, _MergedStat>{};
    const keys = [
      'hp', 'stamina', 'oxygene', 'nourriture', 'poids', 'degats', 'vitesse'
    ];
    for (final k in keys) {
      merged[k] = _MergedStat(key: k, value: 0, source: '—');
    }

    final getters = <String, double Function(Dino)>{
      'hp': (d) => d.hp.toDouble(),
      'stamina': (d) => d.stamina.toDouble(),
      'oxygene': (d) => d.oxygene.toDouble(),
      'nourriture': (d) => d.nourriture.toDouble(),
      'poids': (d) => d.poids.toDouble(),
      'degats': (d) => d.degats,
      'vitesse': (d) => d.vitesse,
    };
    final ptsGetters = <String, int Function(Dino)>{
      'hp': (d) => d.hpPoints,
      'stamina': (d) => d.staminaPoints,
      'oxygene': (d) => d.oxygenePoints,
      'nourriture': (d) => d.nourriturePoints,
      'poids': (d) => d.poidsPoints,
      'degats': (d) => d.degatsPoints,
      'vitesse': (d) => d.vitessePoints,
    };

    for (final dino in libraryDinos) {
      getters.forEach((k, getter) {
        final v = getter(dino);
        if (v > 0 && v > merged[k]!.value) {
          merged[k] = _MergedStat(
            key: k,
            value: v,
            points: ptsGetters[k]!(dino),
            source: dino.nom.isNotEmpty ? dino.nom : 'Dino#${dino.id ?? 0}',
            isFromLibrary: true,
          );
        }
      });
    }

    for (final e in tracker.bestStats.entries) {
      if (!merged.containsKey(e.key)) continue;
      if (e.value.value > merged[e.key]!.value) {
        merged[e.key] = _MergedStat(
          key: e.key,
          value: e.value.value,
          points: e.value.points,
          source: e.value.source ?? 'anonymous',
          isFromLibrary: false,
          isAnonymous:
              e.value.source == null || e.value.source == 'anonymous',
        );
      }
    }
    return merged;
  }

  Map<int, Set<int>> _buildMergedColorBank(
      List<Dino> libraryDinos, SpeciesTracker tracker) {
    final bank = <int, Set<int>>{};
    for (int r = 0; r < 6; r++) {
      bank[r] = <int>{};
    }

    for (final dino in libraryDinos) {
      final ids = dino.colorIds;
      for (int r = 0; r < 6; r++) {
        if (ids[r] > 0) bank[r]!.add(ids[r]);
      }
    }
    for (final obs in tracker.colorObservations) {
      obs.regionColors.forEach((region, colorId) {
        if (bank.containsKey(region) && colorId > 0) {
          bank[region]!.add(colorId);
        }
      });
    }
    tracker.colorBank.forEach((region, ids) {
      bank[region] ??= <int>{};
      for (final id in ids) {
        if (id > 0) bank[region]!.add(id);
      }
    });
    return bank;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dinoProvider, trackerProvider, _) {
        final fresh =
            trackerProvider.trackers.where((t) => t.id == _tracker.id).firstOrNull;
        if (fresh != null) _tracker = fresh;

        final libraryDinos = _getLibraryDinos(dinoProvider);
        final mergedStats = _buildMergedStats(libraryDinos, _tracker);
        final mergedColorBank = _buildMergedColorBank(libraryDinos, _tracker);

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgSecondary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tracker.species.toUpperCase(),
                  style: GoogleFonts.exo2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'TRACKER D\'ESPECE',
                  style: GoogleFonts.exo2(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, trackerProvider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentPrimary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.5),
              labelStyle:
                  GoogleFonts.exo2(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'STATS'),
                Tab(icon: Icon(Icons.palette, size: 18), text: 'COULEURS'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _StatsTab(
                tracker: _tracker,
                mergedStats: mergedStats,
                libraryDinos: libraryDinos,
                onRefresh: _refreshTracker,
              ),
              _ColorsTab(
                tracker: _tracker,
                mergedColorBank: mergedColorBank,
                libraryDinos: libraryDinos,
                onRefresh: _refreshTracker,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, TrackerProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        title: Text('Supprimer le tracker ?',
            style: GoogleFonts.exo2(color: Colors.white)),
        content: Text(
          'Toutes les donnees du tracker "${_tracker.species}" seront perdues.',
          style: GoogleFonts.exo2(color: Colors.white.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.exo2(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Supprimer', style: GoogleFonts.exo2(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteTracker(_tracker.id);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

// ═══════════════════════════════════════════════════════
// STATS TAB
// ═══════════════════════════════════════════════════════
class _StatsTab extends StatefulWidget {
  final SpeciesTracker tracker;
  final Map<String, _MergedStat> mergedStats;
  final List<Dino> libraryDinos;
  final VoidCallback onRefresh;

  const _StatsTab({
    required this.tracker,
    required this.mergedStats,
    required this.libraryDinos,
    required this.onRefresh,
  });

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  bool _showAddForm = false;
  final _sourceCtrl = TextEditingController();
  final Map<String, TextEditingController> _valCtrls = {};
  final Map<String, TextEditingController> _ptsCtrls = {};

  static const _keys = [
    'hp', 'stamina', 'oxygene', 'nourriture', 'poids', 'degats', 'vitesse'
  ];
  static const _labels = {
    'hp': 'HP',
    'stamina': 'Stamina',
    'oxygene': 'Oxygene',
    'nourriture': 'Nourriture',
    'poids': 'Poids',
    'degats': 'Degats',
    'vitesse': 'Vitesse',
  };
  static const _icons = {
    'hp': Icons.favorite,
    'stamina': Icons.flash_on,
    'oxygene': Icons.water_drop,
    'nourriture': Icons.restaurant,
    'poids': Icons.fitness_center,
    'degats': Icons.gps_fixed,
    'vitesse': Icons.speed,
  };
  static const _colors = {
    'hp': Color(0xFF4CAF50),
    'stamina': Color(0xFFFFD700),
    'oxygene': Color(0xFF00BCD4),
    'nourriture': Color(0xFF8BC34A),
    'poids': Color(0xFF9C27B0),
    'degats': Color(0xFFFF5252),
    'vitesse': Color(0xFFFF9800),
  };

  @override
  void initState() {
    super.initState();
    for (final k in _keys) {
      _valCtrls[k] = TextEditingController();
      _ptsCtrls[k] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    _sourceCtrl.dispose();
    for (final c in _valCtrls.values) {
      c.dispose();
    }
    for (final c in _ptsCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libCount = widget.libraryDinos.length;
    final anonCount = widget.tracker.anonymousStatEntries.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Info card + toggle ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.white.withValues(alpha: 0.5), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _showAddForm
                          ? 'Ajoutez une stat anonyme ou partielle sans modifier vos fiches individuelles.'
                          : 'Meilleures stats fusionnees depuis la bibliotheque + le tracker.',
                      style: GoogleFonts.exo2(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showAddForm,
                    onChanged: (v) => setState(() => _showAddForm = v),
                    activeThumbColor: Colors.cyanAccent,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge('Dinos bibliotheque : $libCount',
                      AppTheme.accentPrimary),
                  const SizedBox(width: 8),
                  _badge('Entrees anonymes : $anonCount', Colors.cyanAccent),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_showAddForm) ...[
          _buildAddForm(),
          const SizedBox(height: 16),
        ],

        // ── Stats cards ──
        ..._keys.map((k) => _buildStatRow(k)),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: GoogleFonts.exo2(
              color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Source name
          TextField(
            controller: _sourceCtrl,
            style: GoogleFonts.exo2(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.pets,
                  color: Colors.white.withValues(alpha: 0.4), size: 18),
              hintText: 'Nom du dino source (optionnel)',
              hintStyle: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
              filled: true,
              fillColor: AppTheme.bgPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // Stat fields
          ..._keys.map((k) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Row(
                        children: [
                          Icon(_icons[k], color: _colors[k], size: 14),
                          const SizedBox(width: 4),
                          Text(_labels[k]!,
                              style: GoogleFonts.exo2(
                                  color: _colors[k],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _valCtrls[k],
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))
                        ],
                        style: GoogleFonts.exo2(
                            color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Valeur',
                          hintStyle: GoogleFonts.exo2(
                              color: Colors.white24, fontSize: 12),
                          filled: true,
                          fillColor: AppTheme.bgPrimary,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 55,
                      child: TextField(
                        controller: _ptsCtrls[k],
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: GoogleFonts.exo2(
                            color: Colors.cyanAccent, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Pts',
                          labelStyle: GoogleFonts.exo2(
                              color: Colors.white24, fontSize: 10),
                          filled: true,
                          fillColor: AppTheme.bgPrimary,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submitStats,
              icon: const Icon(Icons.save, size: 18),
              label: Text('ENREGISTRER LES STATS',
                  style: GoogleFonts.exo2(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitStats() async {
    final tp = Provider.of<TrackerProvider>(context, listen: false);
    final stats = <String, double>{};
    final points = <String, int>{};

    for (final k in _keys) {
      final v = double.tryParse(_valCtrls[k]!.text.trim());
      if (v != null && v > 0) {
        stats[k] = v;
        final p = int.tryParse(_ptsCtrls[k]!.text.trim());
        if (p != null && p > 0) points[k] = p;
      }
    }

    if (stats.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune stat saisie'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final src = _sourceCtrl.text.trim();
    await tp.registerAnonymousStats(
      trackerId: widget.tracker.id,
      stats: stats,
      points: points.isNotEmpty ? points : null,
      sourceName: src.isNotEmpty ? src : null,
    );

    for (final c in _valCtrls.values) {
      c.clear();
    }
    for (final c in _ptsCtrls.values) {
      c.text = '0';
    }
    _sourceCtrl.clear();
    widget.onRefresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${stats.length} stats enregistrees'),
      backgroundColor: AppTheme.success,
    ));
  }

  Widget _buildStatRow(String k) {
    final stat = widget.mergedStats[k]!;
    final color = _colors[k] ?? Colors.white;
    final hasValue = stat.value > 0;

    final displayVal = hasValue
        ? (stat.value % 1 == 0
            ? stat.value.toInt().toString()
            : stat.value.toStringAsFixed(1))
        : 'Non enregistre';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icons[k], color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_labels[k]!,
                    style: GoogleFonts.exo2(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(
                  hasValue ? displayVal : 'Non enregistre',
                  style: GoogleFonts.exo2(
                    color: hasValue ? Colors.white : Colors.white38,
                    fontSize: hasValue ? 18 : 12,
                    fontWeight: hasValue ? FontWeight.w800 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          if (hasValue) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (stat.points != null)
                  Text('${stat.points} pts',
                      style: GoogleFonts.exo2(
                          color: Colors.cyanAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                Text(stat.source,
                    style: GoogleFonts.exo2(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 9),
                    overflow: TextOverflow.ellipsis),
                if (stat.isFromLibrary)
                  _miniTag('Biblio', AppTheme.accentPrimary)
                else if (stat.isAnonymous)
                  _miniTag('Anon', Colors.orange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniTag(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: GoogleFonts.exo2(
              color: color, fontSize: 8, fontWeight: FontWeight.w700)),
    );
  }
}

// ═══════════════════════════════════════════════════════
// COLORS TAB (Observer + Simuler fusionnes)
// ═══════════════════════════════════════════════════════
class _ColorsTab extends StatefulWidget {
  final SpeciesTracker tracker;
  final Map<int, Set<int>> mergedColorBank;
  final List<Dino> libraryDinos;
  final VoidCallback onRefresh;

  const _ColorsTab({
    required this.tracker,
    required this.mergedColorBank,
    required this.libraryDinos,
    required this.onRefresh,
  });

  @override
  State<_ColorsTab> createState() => _ColorsTabState();
}

class _ColorsTabState extends State<_ColorsTab> {
  final List<int?> _colors = List<int?>.filled(6, null);
  bool _isSimulateMode = false;
  final _dinoNameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadColorsFromTracker();
  }

  /// ✅ Charger les couleurs depuis le tracker
  void _loadColorsFromTracker() {
    if (widget.tracker.colorBank.isEmpty) return;
    
    for (int r = 0; r < 6; r++) {
      final ids = widget.tracker.colorBank[r];
      if (ids != null && ids.isNotEmpty) {
        _colors[r] = ids.last; // Dernière couleur enregistrée
      }
    }
  }

  /// ✅ IMPORTANT : Recharger si le widget change (revenir de la navigation)
  @override
  void didUpdateWidget(_ColorsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Si le tracker a changé, recharger les couleurs
    if (oldWidget.tracker.id != widget.tracker.id ||
        oldWidget.tracker.colorBank != widget.tracker.colorBank) {
      setState(() {
        // Reset avant de recharger
        for (int i = 0; i < 6; i++) {
          _colors[i] = null;
        }
        _loadColorsFromTracker();
      });
    }
  }

  @override
  void dispose() {
    _dinoNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hexColors = _colors.map((id) {
      if (id == null || id == 0) return '#808080';
      return ArkColorPalette.fromId(id)?.hex ?? '#808080';
    }).toList();

    final libColorCount = widget.libraryDinos.length;
    final obsCount = widget.tracker.colorObservations.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Dino visual ──
        Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Mode toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSimulateMode = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isSimulateMode
                                ? Colors.cyanAccent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: !_isSimulateMode
                                  ? Colors.cyanAccent.withValues(alpha: 0.5)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_red_eye,
                                  size: 14,
                                  color: !_isSimulateMode
                                      ? Colors.cyanAccent
                                      : Colors.white38),
                              const SizedBox(width: 6),
                              Text('Observer',
                                  style: GoogleFonts.exo2(
                                    color: !_isSimulateMode
                                        ? Colors.cyanAccent
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSimulateMode = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isSimulateMode
                                ? Colors.purpleAccent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isSimulateMode
                                  ? Colors.purpleAccent.withValues(alpha: 0.5)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.science,
                                  size: 14,
                                  color: _isSimulateMode
                                      ? Colors.purpleAccent
                                      : Colors.white38),
                              const SizedBox(width: 6),
                              Text('Simuler',
                                  style: GoogleFonts.exo2(
                                    color: _isSimulateMode
                                        ? Colors.purpleAccent
                                        : Colors.white38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Dino image
              SizedBox(
                height: 160,
                child: DinoImageWidget(
                  species: widget.tracker.species,
                  regionColors: hexColors,
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.contain,
                  showColorBand: false,
                ),
              ),
              const SizedBox(height: 12),

              // 6 color slots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: List.generate(6, (i) {
                    final id = _colors[i];
                    final color = id != null
                        ? (ArkColorPalette.fromId(id)?.color ?? Colors.grey)
                        : Colors.grey.withValues(alpha: 0.25);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _pickColor(i),
                        child: Container(
                          height: 44,
                          margin: EdgeInsets.only(right: i < 5 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Center(
                            child: id != null
                                ? Text('$id',
                                    style: TextStyle(
                                      color: _isLight(color)
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ))
                                : Icon(Icons.add,
                                    color: Colors.white.withValues(alpha: 0.4),
                                    size: 18),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),

              // Action buttons depending on mode
              if (!_isSimulateMode) ...[
                // Observer mode: dino name + save button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: TextField(
                    controller: _dinoNameCtrl,
                    style: GoogleFonts.exo2(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Nom du dino (optionnel)',
                      hintStyle: GoogleFonts.exo2(
                          color: Colors.white24, fontSize: 12),
                      filled: true,
                      fillColor: AppTheme.bgPrimary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveObservation,
                      icon: const Icon(Icons.save, size: 18),
                      label: Text('ENREGISTRER LES COULEURS',
                          style:
                              GoogleFonts.exo2(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Simulate mode: random/solid/reset
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Expanded(
                          child: _actionBtn(
                              'Aleatoire', Icons.shuffle, Colors.purpleAccent,
                              _randomize)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _actionBtn(
                              'Solid', Icons.star, Colors.amber, _testSolid)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _actionBtn(
                              'Reset', Icons.refresh, Colors.redAccent, () {
                        setState(() {
                          for (int i = 0; i < 6; i++) {
                            _colors[i] = null;
                          }
                        });
                      })),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Color bank ──
        _buildColorBank(libColorCount, obsCount),
      ],
    );
  }

  Widget _actionBtn(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label,
                style: GoogleFonts.exo2(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _randomize() {
    final random = Random();
    setState(() {
      for (int i = 0; i < 6; i++) {
        final available = (widget.mergedColorBank[i] ?? {}).toList();
        if (available.isNotEmpty) {
          _colors[i] = available[random.nextInt(available.length)];
        }
      }
    });
  }

  void _testSolid() {
    Set<int>? common;
    for (int i = 0; i < 6; i++) {
      final c = widget.mergedColorBank[i] ?? {};
      if (c.isEmpty) continue;
      common = common == null ? Set.from(c) : common.intersection(c);
    }
    if (common == null || common.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucune couleur commune'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    final id = common.first;
    setState(() {
      for (int i = 0; i < 6; i++) {
        _colors[i] = id;
      }
    });
  }

  Future<void> _pickColor(int region) async {
    final List<ArkColor> colorList;

    if (_isSimulateMode) {
      // Mode Simuler : uniquement les couleurs enregistrées
      final available = (widget.mergedColorBank[region] ?? {}).toList()..sort();
      if (available.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Aucune couleur enregistrée pour la région $region'),
          backgroundColor: Colors.orange,
        ));
        return;
      }
      colorList = available
          .map((id) => ArkColorPalette.fromId(id))
          .whereType<ArkColor>()
          .toList();
    } else {
      // Mode Observer : TOUTES les couleurs pour pouvoir en enregistrer de nouvelles
      colorList = ArkColorPalette.allColors;
    }

    final modeLabel = _isSimulateMode
        ? '${colorList.length} enregistrées'
        : '${colorList.length} couleurs';

    final selected = await showModalBottomSheet<int?>(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.8,
          minChildSize: 0.3,
          builder: (_, sc) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Region $region',
                            style: GoogleFonts.exo2(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(modeLabel,
                            style: GoogleFonts.exo2(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        controller: sc,
                        itemCount: colorList.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 5,
                          mainAxisSpacing: 5,
                        ),
                        itemBuilder: (_, i) {
                          if (i == 0) {
                            return GestureDetector(
                              onTap: () => Navigator.pop(ctx, null),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Center(
                                    child: Icon(Icons.close,
                                        color: Colors.white, size: 16)),
                              ),
                            );
                          }
                          final ark = colorList[i - 1];
                          final sel = _colors[region] == ark.id;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, ark.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: ark.color,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: sel
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: sel ? 2.5 : 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text('${ark.id}',
                                    style: TextStyle(
                                      color: _isLight(ark.color)
                                          ? Colors.black
                                          : Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    )),
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
          },
        );
      },
    );

    if (!mounted) return;
    setState(() => _colors[region] = selected);
  }

  /// ✅ Sauvegarde PERMANENTE
  Future<void> _saveObservation() async {
    final regionColors = <int, int>{};
    for (int i = 0; i < 6; i++) {
      if (_colors[i] != null && _colors[i]! > 0) {
        regionColors[i] = _colors[i]!;
      }
    }
    if (regionColors.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Selectionnez au moins une couleur'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    final tp = Provider.of<TrackerProvider>(context, listen: false);
    await tp.saveAnonymousColorObservation(
      trackerId: widget.tracker.id,
      regionColors: regionColors,
    );

    // ✅ Recharger depuis la base
    widget.onRefresh();

    _dinoNameCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✓ Observation enregistrée et sauvegardée'),
      backgroundColor: AppTheme.success,
    ));
  }

  /// Confirme puis supprime une couleur du colorBank du tracker
  Future<void> _confirmDeleteColor(int region, int colorId) async {
    final ark = ArkColorPalette.fromId(colorId);
    final colorName = ark?.name ?? 'Couleur $colorId';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: ark?.color ?? Colors.grey,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white24),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Supprimer $colorName ?',
                style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          ],
        ),
        content: Text(
          'La couleur ID $colorId sera retirée de la région $region du tracker.\n\nCette action est irréversible.',
          style: GoogleFonts.exo2(
              color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: Text('Supprimer',
                style: GoogleFonts.exo2(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final tp = Provider.of<TrackerProvider>(context, listen: false);
    await tp.removeColorFromBank(
      trackerId: widget.tracker.id,
      region: region,
      colorId: colorId,
    );

    widget.onRefresh();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Couleur $colorId supprimée de la région $region'),
      backgroundColor: Colors.redAccent,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildColorBank(int libCount, int obsCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('MES COULEURS SAUVEGARDÉES',
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniTag2('Bibliotheque : $libCount', Colors.orangeAccent),
              const SizedBox(width: 6),
              _miniTag2('Obs. tracker : $obsCount', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(6, (r) {
            final colors = (widget.mergedColorBank[r] ?? {}).toList()..sort();
            return _buildRegionRow(r, colors);
          }),
        ],
      ),
    );
  }

  Widget _buildRegionRow(int region, List<int> colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Row(
          children: [
            Text('Region $region',
                style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${colors.length}',
                  style: GoogleFonts.exo2(
                      color: Colors.deepPurpleAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        iconColor: Colors.white38,
        collapsedIconColor: Colors.white38,
        children: [
          if (colors.isEmpty)
            Text('Aucune couleur',
                style: GoogleFonts.exo2(color: Colors.white24, fontSize: 11))
          else
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: colors.map((id) {
                final ark = ArkColorPalette.fromId(id);
                final c = ark?.color ?? Colors.grey;
                return GestureDetector(
                  onTap: () {
                    for (int i = 0; i < 6; i++) {
                      if (_colors[i] == null) {
                        setState(() => _colors[i] = id);
                        return;
                      }
                    }
                    setState(() => _colors[0] = id);
                  },
                  onLongPress: () => _confirmDeleteColor(region, id),
                  child: Tooltip(
                    message: '${ark?.name ?? "?"} (ID: $id) — Maintenir pour supprimer',
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: Center(
                        child: Text('$id',
                            style: TextStyle(
                              color:
                                  _isLight(c) ? Colors.black87 : Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _miniTag2(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.exo2(
              color: color, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }

  bool _isLight(Color c) => c.computeLuminance() > 0.5;
}

// ═══════════════════════════════════════════════════════
// DATA MODEL
// ═══════════════════════════════════════════════════════
class _MergedStat {
  final String key;
  final double value;
  final int? points;
  final String source;
  final bool isFromLibrary;
  final bool isAnonymous;

  const _MergedStat({
    required this.key,
    required this.value,
    this.points,
    required this.source,
    this.isFromLibrary = false,
    this.isAnonymous = false,
  });
}
