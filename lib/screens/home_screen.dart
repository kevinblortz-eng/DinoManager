// lib/screens/home_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../utils/dino_helpers.dart';
import '../widgets/dino_image_widget.dart';
<<<<<<< HEAD
import '../widgets/common/dino_sex_badge.dart';
import 'backup_screen.dart';
=======
import 'setting_screen.dart';
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
import 'add_edit_dino_screen.dart';
import 'dino_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Dino? _spotlightDino;
  final _random = Random();

<<<<<<< HEAD
=======
  // ── Fond fixe de la home ───────────────────────────────────────────────
  // Déclarer dans pubspec.yaml : assets/images/ui/background_home.png
  static const String _bgAsset = 'assets/images/ui/background_home.png';

>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  static const _tips = [
    'Enregistre les couleurs de chaque dino sauvage dans le tracker pour enrichir ta banque.',
    'Utilise le simulateur pour visualiser les combos avant de breed.',
    'Les stats anonymes du tracker permettent de suivre les max sans fiche complete.',
    'Exporte regulierement en Excel pour sauvegarder tes donnees.',
    'Le mode Solid du simulateur trouve les couleurs communes a toutes les regions.',
    'Tu peux dupliquer une DinoCard pour creer une variante rapidement.',
    'Ajoute des tags pour organiser tes dinos par projet de breeding.',
    'Le journal d\'espece fusionne les stats bibliotheque + tracker automatiquement.',
    'En mode Observer du tracker, toute la palette est disponible pour enregistrer de nouvelles couleurs.',
    'Le bouton Aleatoire du simulateur ne pioche que dans tes couleurs enregistrees.',
  ];

  late String _todayTip;

  @override
  void initState() {
    super.initState();
    _todayTip = _tips[DateTime.now().millisecondsSinceEpoch % _tips.length];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DinoProvider>().loadDinos();
      _pickSpotlightDino();
    });
  }

  void _pickSpotlightDino() {
    final dinos = context.read<DinoProvider>().dinos;
    if (dinos.isEmpty) {
      setState(() => _spotlightDino = null);
      return;
    }
    setState(() {
      _spotlightDino = dinos[_random.nextInt(dinos.length)];
    });
  }

<<<<<<< HEAD
  /// Ouvre la DinoCard en mode visuel (lecture seule)
=======
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  void _openSpotlightDino(Dino dino) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DinoDetailScreen(dino: dino),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<DinoProvider>().loadDinos();
      _pickSpotlightDino();
    });
  }
<<<<<<< HEAD

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TrackerProvider>(
      builder: (context, dinoProvider, trackerProvider, _) {
        final dinos = dinoProvider.dinos;
        final totalDinos = dinos.length;
        final speciesSet = dinos.map((d) => d.espece.toLowerCase()).toSet();
        final totalSpecies = speciesSet.length;
        final totalTrackers = trackerProvider.trackers.length;
        final totalAvailableSpecies = Dino.especesDisponibles.length;

        // Répartition par rôle
        final roleCounts = <String, int>{};
        for (final d in dinos) {
          final role = d.role.isNotEmpty ? d.role : 'Autre';
          roleCounts[role] = (roleCounts[role] ?? 0) + 1;
        }
        final sortedRoles = roleCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Top espèces
        final speciesCounts = <String, int>{};
        for (final d in dinos) {
          speciesCounts[d.espece] = (speciesCounts[d.espece] ?? 0) + 1;
        }
        final topSpecies = speciesCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Espèces sans tracker
        final trackedSpecies = trackerProvider.trackers
            .map((t) => t.species.toLowerCase())
            .toSet();
        final untrackedSpecies = speciesSet
            .where((s) => !trackedSpecies.contains(s))
            .toList();

        // Vérifier si le spotlight est encore valide
        if (_spotlightDino != null &&
            !dinos.any((d) => d.id == _spotlightDino!.id)) {
          _spotlightDino =
              dinos.isNotEmpty ? dinos[_random.nextInt(dinos.length)] : null;
        }

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Header ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ARK MANAGER',
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Gestionnaire de dinosaures',
                            style: GoogleFonts.exo2(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.backup_rounded,
                          color: AppTheme.textMuted, size: 22),
                      tooltip: 'Sauvegardes',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const BackupScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── 3 Compteurs principaux ──
                Row(
                  children: [
                    _buildStatTile(
                      Icons.category_rounded,
                      'Espèces',
                      '$totalSpecies',
                      Colors.orangeAccent,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      Icons.style_rounded,
                      'DinoCards',
                      '$totalDinos',
                      AppTheme.accentPrimary,
                    ),
                    const SizedBox(width: 10),
                    _buildStatTile(
                      Icons.science_rounded,
                      'Trackers',
                      '$totalTrackers',
                      Colors.cyanAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Progression espèces ──
                _buildProgressCard(totalSpecies, totalAvailableSpecies),
                const SizedBox(height: 16),

                // ── Dino Spotlight ──
                if (_spotlightDino != null) ...[
                  _buildSpotlightCard(_spotlightDino!),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildEmptySpotlight(),
                  const SizedBox(height: 16),
                ],

                // ── Répartition par rôle ──
                if (sortedRoles.isNotEmpty) ...[
                  _buildRoleDistribution(sortedRoles, totalDinos),
                  const SizedBox(height: 16),
                ],

                // ── Top espèces ──
                if (topSpecies.length > 1) ...[
                  _buildTopSpecies(topSpecies.take(5).toList()),
                  const SizedBox(height: 16),
                ],

                // ── Espèces sans tracker ──
                if (untrackedSpecies.isNotEmpty) ...[
                  _buildUntrackedHint(untrackedSpecies),
                  const SizedBox(height: 16),
                ],

                // ── Tip du jour ──
                _buildTipCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════

  Widget _buildStatTile(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.exo2(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.exo2(
                fontSize: 9,
                color: color.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
=======
  
 @override
Widget build(BuildContext context) {
  return Consumer2<DinoProvider, TrackerProvider>(
    builder: (context, dinoProvider, trackerProvider, _) {
      final dinos = dinoProvider.dinos;
      final speciesSet =
          dinos.map((d) => d.espece.toLowerCase()).toSet();

      final roleCounts = <String, int>{};
      for (final d in dinos) {
        final role = d.role.isNotEmpty ? d.role : 'Autre';
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
      final sortedRoles = roleCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final speciesCounts = <String, int>{};
      for (final d in dinos) {
        speciesCounts[d.espece] =
            (speciesCounts[d.espece] ?? 0) + 1;
      }
      final topSpecies = speciesCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final trackedSpecies = trackerProvider.trackers
          .map((t) => t.species.toLowerCase())
          .toSet();
      final untrackedSpecies = speciesSet
          .where((s) => !trackedSpecies.contains(s))
          .toList();

      if (_spotlightDino != null &&
          !dinos.any((d) => d.id == _spotlightDino!.id)) {
        _spotlightDino = dinos.isNotEmpty
            ? dinos[_random.nextInt(dinos.length)]
            : null;
      }

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // ── FOND FIXE ───────────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                _bgAsset,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) =>
                    Container(color: AppTheme.bgPrimary),
              ),
            ),

            // ── OVERLAY sombre ──────────────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xDD050810),
                      Color(0xAA050810),
                      Color(0xDD050810),
                    ],
                  ),
                ),
              ),
            ),

            // ── CONTENU : header fixe + liste scrollable ────────────
            SafeArea(
              child: Column(
                children: [

                  // ══════════════════════════════════════════════════
                  // HEADER FIXE — ne scroll jamais
                  // ══════════════════════════════════════════════════
                  Container(
                    // Fond semi-transparent pour rester lisible
                    // même quand le contenu défile dessous
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF050810).withValues(alpha: 0.95),
                          const Color(0xFF050810).withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
                    child: Row(
                      children: [
                        // Titre + sous-titre
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ARK MANAGER',
                                style: GoogleFonts.cinzelDecorative(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gestionnaire de dinosaures',
                                style: GoogleFonts.exo2(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bouton paramètres
                        IconButton(
                          icon: const Icon(
                            Icons.settings_rounded,
                            color: AppTheme.textMuted,
                            size: 22,
                          ),
                          tooltip: 'Paramètres',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ══════════════════════════════════════════════════
                  // CONTENU SCROLLABLE
                  // ══════════════════════════════════════════════════
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 0),
                      children: [
                        if (_spotlightDino != null) ...[
                          _buildSpotlightCardEnhanced(_spotlightDino!),
                          const SizedBox(height: 20),
                        ] else ...[
                          _buildEmptySpotlight(),
                          const SizedBox(height: 20),
                        ],

                        if (sortedRoles.isNotEmpty) ...[
                          _buildRoleDistributionEnhanced(
                              sortedRoles.take(4).toList(),
                              dinos.length),
                          const SizedBox(height: 20),
                        ],

                        if (topSpecies.length > 1) ...[
                          _buildTopSpecies(
                              topSpecies.take(5).toList()),
                          const SizedBox(height: 20),
                        ],

                        if (untrackedSpecies.isNotEmpty) ...[
                          _buildUntrackedHint(untrackedSpecies),
                          const SizedBox(height: 20),
                        ],

                        _buildTipCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
              ),
            ),
          ],
        ),
<<<<<<< HEAD
      ),
    );
  }

  Widget _buildProgressCard(int current, int total) {
    final progress = total > 0 ? current / total : 0.0;
    final percent = (progress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.explore_rounded,
                  color: Colors.orangeAccent.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 8),
              Text(
                'PROGRESSION',
                style: GoogleFonts.exo2(
                  color: Colors.orangeAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Text(
                '$current / $total especes',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percent% du bestiaire ARK decouvert',
            style: GoogleFonts.exo2(
              color: AppTheme.textMuted,
              fontSize: 10,
=======
      );
    },
  );
}

  // ═══════════════════════════════════════════════════════════════════════════
  // DINO SPOTLIGHT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSpotlightCardEnhanced(Dino dino) {
    final previewColors = [
      dino.colorHex0,
      dino.colorHex1,
      dino.colorHex2,
      dino.colorHex3,
      dino.colorHex4,
      dino.colorHex5,
    ];

    return GestureDetector(
      onTap: () => _openSpotlightDino(dino),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Container principal ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 60),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xCC1C2333), Color(0xCC161B22)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header titre + bouton actualiser ────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      // Badge "DINO SPOTLIGHT"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentPrimary
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: AppTheme.accentPrimary, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              'DINO SPOTLIGHT',
                              style: GoogleFonts.exo2(
                                fontSize: 13,
                                color: const Color(0xFFBDCA08),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // ✅ Bouton actualiser : emoji 🔄 à droite du titre
                      GestureDetector(
                        onTap: () {
                          _pickSpotlightDino();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Dino aléatoire généré'),
                              duration: Duration(milliseconds: 800),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentPrimary
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.accentPrimary
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            '🔄',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Contenu : Texte gauche + espace image droite ────
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dino.nom.isNotEmpty
                                  ? dino.nom
                                  : dino.espece,
                              style: GoogleFonts.exo2(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${dino.espece} • Lvl ${dino.niveau}',
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (dino.tags.isNotEmpty)
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: dino.tags.take(2).map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.cyanAccent
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: GoogleFonts.exo2(
                                        color: Colors.cyanAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                      // Espace réservé pour l'image Positioned
                      const SizedBox(width: 100, height: 100),
                    ],
                  ),
                ),

                // ── Barre couleurs ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: List.generate(6, (i) {
                      final color = _hexToColor(previewColors[i]);
                      return Expanded(
                        child: Container(
                          height: 8,
                          margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ── Image dino Positioned (dépasse du haut) ─────────────────
          Positioned(
            top: 60,
            right: 16,
            width: 180,
            height: 180,
            child: Transform.scale(
              scaleX: -1,
              child: DinoImageWidget(
                species: dino.espece,
                regionColors: previewColors,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                showColorBand: false,
              ),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildSpotlightCard(Dino dino) {
    final previewColors = [
      dino.colorHex0, dino.colorHex1, dino.colorHex2,
      dino.colorHex3, dino.colorHex4, dino.colorHex5,
    ];

    return GestureDetector(
      onTap: () => _openSpotlightDino(dino),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C2333), Color(0xFF161B22)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.accentPrimary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          color: AppTheme.accentPrimary, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'DINO SPOTLIGHT',
                        style: GoogleFonts.exo2(
                          fontSize: 9,
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    _pickSpotlightDino();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.refresh_rounded,
                        color: AppTheme.textMuted, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 100,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: DinoImageWidget(
                      species: dino.espece,
                      regionColors: previewColors,
                      width: 100,
                      height: 80,
                      fit: BoxFit.contain,
                      showColorBand: false,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              dino.nom,
                              style: GoogleFonts.exo2(
                                fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          DinoSexBadge(sexe: dino.sexe, size: 24),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${dino.espece} · Lvl ${dino.niveau}',
                        style: GoogleFonts.exo2(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      if (dino.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: dino.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    Colors.cyanAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(tag,
                                  style: GoogleFonts.exo2(
                                      color: Colors.cyanAccent,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w700)),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: List.generate(6, (i) {
                          final color = _hexToColor(previewColors[i]);
                          return Expanded(
                            child: Container(
                              height: 6,
                              margin:
                                  EdgeInsets.only(right: i < 5 ? 2 : 0),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
=======
  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY SPOTLIGHT
  // ═══════════════════════════════════════════════════════════════════════════
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

  Widget _buildEmptySpotlight() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppTheme.bgCard,
=======
        color: AppTheme.bgCard.withValues(alpha: 0.85),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.pets_rounded,
<<<<<<< HEAD
              size: 40, color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            'Aucun dino enregistre',
            style: GoogleFonts.exo2(color: AppTheme.textMuted, fontSize: 14),
=======
              size: 40,
              color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            'Aucun dino enregistré',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 14),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
<<<<<<< HEAD
              MaterialPageRoute(builder: (_) => const AddEditDinoScreen()),
=======
              MaterialPageRoute(
                  builder: (_) => const AddEditDinoScreen()),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ).then((_) {
              if (!mounted) return;
              context.read<DinoProvider>().loadDinos();
              _pickSpotlightDino();
            }),
            child: Container(
<<<<<<< HEAD
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
=======
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accentGreen.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Ajouter mon premier dino',
                style: GoogleFonts.exo2(
                  color: AppTheme.accentGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildRoleDistribution(
=======
  // ═══════════════════════════════════════════════════════════════════════════
  // RÉPARTITION PAR RÔLE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRoleDistributionEnhanced(
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
      List<MapEntry<String, int>> roles, int total) {
    const roleColors = {
      'Solid': Colors.purpleAccent,
      'Breed': Colors.cyanAccent,
      'Boss': Colors.redAccent,
      'Farm': Colors.greenAccent,
      'Collection': Colors.orangeAccent,
      'Équilibré': Colors.amberAccent,
<<<<<<< HEAD
=======
      'Combat': Colors.blueAccent,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppTheme.bgCard,
=======
        color: AppTheme.bgCard.withValues(alpha: 0.85),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_rounded,
                  color: Colors.purpleAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
<<<<<<< HEAD
                'REPARTITION PAR ROLE',
                style: GoogleFonts.exo2(
                  color: Colors.purpleAccent,
                  fontSize: 11,
=======
                'RÉPARTITION PAR RÔLE',
                style: GoogleFonts.exo2(
                  color: Colors.purpleAccent,
                  fontSize: 14,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
<<<<<<< HEAD
          ...roles.take(6).map((entry) {
            final color = roleColors[entry.key] ?? AppTheme.textMuted;
=======
          ...roles.map((entry) {
            final color =
                roleColors[entry.key] ?? AppTheme.textMuted;
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            final ratio = total > 0 ? entry.value / total : 0.0;
            final percent = (ratio * 100).toStringAsFixed(0);

            return Padding(
<<<<<<< HEAD
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      entry.key,
                      style: GoogleFonts.exo2(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 45,
                    child: Text(
                      '${entry.value} ($percent%)',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.exo2(
                        color: AppTheme.textMuted,
                        fontSize: 9,
                      ),
=======
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.exo2(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$percent%',
                        style: GoogleFonts.exo2(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${entry.value}',
                        style: GoogleFonts.exo2(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  // ═══════════════════════════════════════════════════════════════════════════
  // TOP ESPÈCES
  // ═══════════════════════════════════════════════════════════════════════════

>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  Widget _buildTopSpecies(List<MapEntry<String, int>> species) {
    const medals = ['🥇', '🥈', '🥉'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: AppTheme.bgCard,
=======
        color: AppTheme.bgCard.withValues(alpha: 0.85),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded,
                  color: Colors.amber.withValues(alpha: 0.8), size: 16),
              const SizedBox(width: 8),
              Text(
<<<<<<< HEAD
                'TOP ESPECES',
                style: GoogleFonts.exo2(
                  color: Colors.amber,
                  fontSize: 11,
=======
                'TOP ESPÈCES',
                style: GoogleFonts.exo2(
                  color: Colors.amber,
                  fontSize: 14,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...species.asMap().entries.map((entry) {
            final index = entry.key;
<<<<<<< HEAD
            final species = entry.value;
            final medal =
                index < medals.length ? medals[index] : '${index + 1}.';
=======
            final sp = entry.value;
            final medal = index < medals.length
                ? medals[index]
                : '${index + 1}.';
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(medal,
                        style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
<<<<<<< HEAD
                      species.key,
=======
                      sp.key,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                      style: GoogleFonts.exo2(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
<<<<<<< HEAD
                      '${species.value} dinos',
=======
                      '${sp.value} dinos',
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                      style: GoogleFonts.exo2(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  // ═══════════════════════════════════════════════════════════════════════════
  // ESPÈCES SANS TRACKER
  // ═══════════════════════════════════════════════════════════════════════════

>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  Widget _buildUntrackedHint(List<String> untrackedSpecies) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
=======
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.orange.withValues(alpha: 0.2)),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              color: Colors.orange.withValues(alpha: 0.7), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
<<<<<<< HEAD
                  '${untrackedSpecies.length} espece${untrackedSpecies.length > 1 ? 's' : ''} sans tracker',
=======
                  '${untrackedSpecies.length} espèce${untrackedSpecies.length > 1 ? 's' : ''} sans tracker',
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  style: GoogleFonts.exo2(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
<<<<<<< HEAD
                  'Cree un tracker pour ${untrackedSpecies.take(3).join(', ')}${untrackedSpecies.length > 3 ? '...' : ''} pour suivre leurs stats et couleurs.',
=======
                  'Crée un tracker pour ${untrackedSpecies.take(3).join(', ')}${untrackedSpecies.length > 3 ? '...' : ''} pour suivre leurs stats et couleurs.',
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  style: GoogleFonts.exo2(
                    color: Colors.orange.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
=======
  // ═══════════════════════════════════════════════════════════════════════════
  // TIP DU JOUR
  // ═══════════════════════════════════════════════════════════════════════════

>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
<<<<<<< HEAD
        color: Colors.cyanAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: Colors.cyanAccent.withValues(alpha: 0.15)),
=======
        color: Colors.cyanAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.15)),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded,
              color: Colors.cyanAccent.withValues(alpha: 0.6), size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ASTUCE DU JOUR',
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayTip,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _hexToColor(String hex) => DinoHelpers.hexToColor(hex);
}
