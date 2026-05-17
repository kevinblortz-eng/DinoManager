// lib/screens/tracker/species_journal_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/dino.dart';
import '../../models/species_tracker.dart';
import '../../providers/dino_provider.dart';
import '../../providers/tracker_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dino_image_widget.dart';
import '../add_edit_dino_screen.dart';
import '../dino_canva_screen.dart';
import 'tabs/journal_tab_stats_max.dart';
import 'tabs/journal_tab_colors.dart';
import 'tabs/journal_tab_my_dinos.dart';
import 'tabs/journal_tab_simulator.dart';

class SpeciesJournalDetailScreen extends StatefulWidget {
  final String species;
  final SpeciesTracker? tracker;
  final Dino? initialSelectedDino;

  const SpeciesJournalDetailScreen({
    super.key,
    required this.species,
    this.tracker,
    this.initialSelectedDino,
  });

  @override
  State<SpeciesJournalDetailScreen> createState() =>
      _SpeciesJournalDetailScreenState();
}

class _SpeciesJournalDetailScreenState extends State<SpeciesJournalDetailScreen>
    with TickerProviderStateMixin {
  static const String _bgAsset = 'assets/images/ui/background_home.png';

  late TabController _tabController;
  int? _headerDinoId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHeaderDinoPref();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _prefKey => 'header_dino_${widget.species}';

  Future<void> _loadHeaderDinoPref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt(_prefKey);
      if (id != null) {
        if (mounted) setState(() => _headerDinoId = id);
        return;
      }
      // Pas de pref → fallback sur initialSelectedDino si fourni
      final fallback = widget.initialSelectedDino?.id;
      if (fallback != null && mounted) {
        setState(() => _headerDinoId = fallback);
        await prefs.setInt(_prefKey, fallback);
      }
    } catch (_) {}
  }

  Future<void> _saveHeaderDinoPref(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefKey, id);
    } catch (_) {}
  }

  List<Dino> _speciesDinos(DinoProvider p) => p.allDinos
      .where((d) => d.espece.toLowerCase() == widget.species.toLowerCase())
      .toList();

  Dino? _resolveHeaderDino(List<Dino> dinos) {
    if (dinos.isEmpty) return null;
    if (_headerDinoId != null) {
      final match = dinos.where((d) => d.id == _headerDinoId);
      if (match.isNotEmpty) return match.first;
    }
    return dinos.first;
  }

  SpeciesTracker? _currentTracker(TrackerProvider tp) {
    for (final t in tp.trackers) {
      if (t.species.toLowerCase() == widget.species.toLowerCase()) return t;
    }
    return null;
  }

  Future<void> _pickHeaderDino(List<Dino> dinos) async {
    if (dinos.isEmpty) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisir le dino vedette',
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: dinos.length,
                  itemBuilder: (_, i) {
                    final d = dinos[i];
                    final selected = d.id == _headerDinoId;
                    return ListTile(
                      dense: true,
                      onTap: () => Navigator.pop(ctx, d.id),
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: DinoImageWidget(
                          species: d.espece,
                          regionColors: d.colorRegions,
                          width: 44,
                          height: 44,
                          fit: BoxFit.contain,
                          showColorBand: false,
                        ),
                      ),
                      title: Text(
                        d.nom.isNotEmpty ? d.nom : '#${d.id}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Lvl ${d.niveau}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle,
                              color: Colors.cyanAccent)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked != null && mounted) {
      setState(() => _headerDinoId = picked);
      await _saveHeaderDinoPref(picked);
    }
  }

  Future<void> _addNewDino() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditDinoScreen(initialSpecies: widget.species),
      ),
    );
    if (!mounted) return;
    await context.read<DinoProvider>().loadDinos();
  }

  void _openCanva() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DinoCanvaScreen(
          species: widget.species,
          initialSelection: const <Dino>[],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dp, tp, _) {
        final dinos = _speciesDinos(dp);
        final headerDino = _resolveHeaderDino(dinos);
        final tracker = _currentTracker(tp);

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppTheme.bgPrimary),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(),
                    _buildHeader(headerDino, dinos, tracker),
                    _buildSpotlightTabBar(),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          JournalTabStatsMax(
                            species: widget.species,
                            dinos: dinos,
                            tracker: tracker,
                          ),
                          JournalTabColors(
                            species: widget.species,
                            dinos: dinos,
                            tracker: tracker,
                          ),
                          JournalTabMyDinos(
                            species: widget.species,
                            dinos: dinos,
                            tracker: tracker,
                          ),
                          JournalTabSimulator(species: widget.species),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── App bar ────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              widget.species.toUpperCase(),
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // ─── Bouton Canva rectangulaire ───────────────────────────────
          _CanvaHeaderButton(onTap: _openCanva),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.cyanAccent),
            tooltip: 'Nouveau Dinocard pour ${widget.species}',
            onPressed: _addNewDino,
          ),
        ],
      ),
    );
  }

  // ─── Header : image + infos ─────────────────────────────────────────────
  Widget _buildHeader(Dino? headerDino, List<Dino> dinos, SpeciesTracker? t) {
    final hasTracker = t != null;
    final colorsCount = t == null
        ? 0
        : t.colorBank.values.fold<int>(0, (s, l) => s + l.length);
    final lastUpdate = t?.updatedAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => _pickHeaderDino(dinos),
            child: Container(
              width: 110,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: headerDino == null
                        ? const Center(
                            child: Icon(Icons.pets,
                                color: Colors.white24, size: 36),
                          )
                        : DinoImageWidget(
                            species: headerDino.espece,
                            regionColors: headerDino.colorRegions,
                            width: 110,
                            height: 130,
                            fit: BoxFit.contain,
                            showColorBand: false,
                          ),
                  ),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit,
                          size: 12, color: Colors.cyanAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Journal d\'espèce',
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                _miniStat(Icons.pets, '${dinos.length} dinos'),
                const SizedBox(height: 2),
                _miniStat(
                  Icons.science,
                  hasTracker
                      ? 'Tracker actif · $colorsCount couleurs'
                      : 'Aucun tracker',
                ),
                if (lastUpdate != null) ...[
                  const SizedBox(height: 2),
                  _miniStat(
                    Icons.update,
                    'MAJ ${lastUpdate.day}/${lastUpdate.month}/${lastUpdate.year}',
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── TabBar 4 onglets, largeur égale, effet spotlight ───────────────────
  Widget _buildSpotlightTabBar() {
    const tabs = ['Stats Max', 'Couleurs', 'Mes dinos', 'Simulateur'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: false, // ← 4 onglets égaux (1/4 chacun)
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const _SpotlightIndicator(color: Colors.cyanAccent),
        dividerColor: Colors.transparent,
        labelPadding: EdgeInsets.zero,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.55),
        labelStyle: GoogleFonts.exo2(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
        unselectedLabelStyle: GoogleFonts.exo2(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        tabs: tabs
            .map((t) => Tab(
                  height: 40,
                  child: Center(
                    child: Text(t, textAlign: TextAlign.center),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Bouton Canva rectangulaire (header) — orange dégradé, bord sombre
// ═══════════════════════════════════════════════════════════════════════════
class _CanvaHeaderButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CanvaHeaderButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ouvrir le Canva',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B00), Color(0xFFFF9500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.dashboard_customize_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 5),
                Text(
                  'Canva',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicateur "spotlight" : halo radial centré derrière le label de l'onglet actif.
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
      RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(10)),
      paint,
    );

    final underline = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(rect.left + 14, rect.bottom - 4),
      Offset(rect.right - 14, rect.bottom - 4),
      underline,
    );
  }
}
