// lib/screens/simulator_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../models/species_tracker.dart';
import '../models/ark_color_palette.dart';
import '../models/ark_species_data.dart';
import '../models/ark_species_color_regions.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  String _species = 'Rex';
  final List<int?> _selectedColors = List<int?>.filled(6, null);
  bool _useRegisteredOnly = false;

  Map<int, Set<int>> _mergedColorBank = {};
  List<_ColorSourceEntry> _colorSources = [];

  void _rebuildData(DinoProvider dinoProvider, TrackerProvider trackerProvider) {
    final libraryDinos = dinoProvider.dinos
        .where((d) => d.espece.toLowerCase() == _species.toLowerCase())
        .toList();

    final tracker = trackerProvider.trackers.cast<SpeciesTracker?>().firstWhere(
          (t) => t?.species.toLowerCase() == _species.toLowerCase(),
          orElse: () => null,
        );

    _mergedColorBank = {};
    for (int r = 0; r < 6; r++) {
      _mergedColorBank[r] = <int>{};
    }

    if (tracker != null) {
      tracker.colorBank.forEach((region, ids) {
        _mergedColorBank[region]!.addAll(ids);
      });
    }

    for (final dino in libraryDinos) {
      final ids = dino.colorIds;
      for (int r = 0; r < 6; r++) {
        if (ids[r] > 0) _mergedColorBank[r]!.add(ids[r]);
      }
    }

    _colorSources = [];
    for (final dino in libraryDinos) {
      final ids = dino.colorIds;
      _colorSources.add(_ColorSourceEntry(
        name: dino.nom.isNotEmpty ? dino.nom : 'Dino#${dino.id ?? 0}',
        colors: List.generate(6, (i) => ids[i] > 0 ? ids[i] : null),
        isLibrary: true,
      ));
    }

    if (tracker != null) {
      for (final obs in tracker.colorObservations) {
        _colorSources.add(_ColorSourceEntry(
          name:
              '${obs.recordedAt.day}/${obs.recordedAt.month}/${obs.recordedAt.year}',
          colors: List.generate(6, (i) {
            final c = obs.regionColors[i];
            return (c != null && c > 0) ? c : null;
          }),
          isLibrary: false,
        ));
      }
    }
  }

  Future<void> _showSpeciesPickerDialog() async {
    final allSpecies = Dino.especesDisponibles;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final searchCtrl = TextEditingController(text: '');
        List<String> filtered = List<String>.from(allSpecies);

        return StatefulBuilder(
          builder: (context, setLocalState) {
            void applyFilter(String query) {
              final q = query.toLowerCase().trim();
              setLocalState(() {
                filtered = allSpecies
                    .where((s) => s.toLowerCase().contains(q))
                    .toList();
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.bgCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Choisir une espece',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 420,
                child: Column(
                  children: [
                    TextField(
                      controller: searchCtrl,
                      onChanged: applyFilter,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une espece...',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        prefixIcon: const Icon(Icons.search,
                            color: AppTheme.accentPrimary),
                        filled: true,
                        fillColor: AppTheme.bgPrimary,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Text(
                                'Aucune espece trouvee',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final species = filtered[index];
                                final hasImg =
                                    ArkSpeciesData.hasImage(species);

                                return ListTile(
                                  dense: true,
                                  leading: hasImg
                                      ? Image.asset(
                                          'assets/images/dinos/${species.replaceAll(' ', '_')}_ASA.png',
                                          width: 40,
                                          height: 32,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                  Icons.help_outline,
                                                  color: Colors.white38,
                                                  size: 20),
                                        )
                                      : const Icon(Icons.help_outline,
                                          color: Colors.white38, size: 20),
                                  title: Text(
                                    species,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onTap: () => Navigator.pop(ctx, species),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Annuler',
                      style:
                          GoogleFonts.exo2(color: AppTheme.accentPrimary)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != _species) {
      setState(() {
        _species = result;
        for (int i = 0; i < 6; i++) {
          _selectedColors[i] = null;
        }
      });
    }
  }

  Future<void> _pickColor(int region) async {
    final List<ArkColor> available;

    if (_useRegisteredOnly) {
      final registeredIds = (_mergedColorBank[region] ?? {}).toList()..sort();
      if (registeredIds.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Aucune couleur enregistree pour la region $region'),
            backgroundColor: AppTheme.warning,
          ),
        );
        return;
      }
      available = registeredIds
          .map((id) => ArkColorPalette.fromId(id))
          .whereType<ArkColor>()
          .toList();
    } else {
      available = ArkColorPalette.allColors;
    }

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
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (_, scrollController) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Region $region',
                          style: GoogleFonts.exo2(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _useRegisteredOnly
                              ? '${available.length} enregistrees'
                              : '${available.length} couleurs',
                          style: GoogleFonts.exo2(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        controller: scrollController,
                        itemCount: available.length + 1,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1,
                        ),
                        itemBuilder: (_, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () => Navigator.pop(ctx, null),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Colors.grey.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Center(
                                  child: Icon(Icons.close,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            );
                          }
                          final ark = available[index - 1];
                          final isSelected =
                              _selectedColors[region] == ark.id;
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, ark.id),
                            child: Container(
                              decoration: BoxDecoration(
                                color: ark.color,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white
                                          .withValues(alpha: 0.3),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: ark.color
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  '${ark.id}',
                                  style: TextStyle(
                                    color: _isLight(ark.color)
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    setState(() {
      _selectedColors[region] = selected;
    });
  }

  // ── Actions rapides ──
  void _randomize() {
    final random = Random();
    setState(() {
      for (int i = 0; i < 6; i++) {
        if (_useRegisteredOnly) {
          final available = (_mergedColorBank[i] ?? {}).toList();
          if (available.isNotEmpty) {
            _selectedColors[i] =
                available[random.nextInt(available.length)];
          } else {
            _selectedColors[i] = null;
          }
        } else {
          final all = ArkColorPalette.allColors;
          if (all.isNotEmpty) {
            _selectedColors[i] = all[random.nextInt(all.length)].id;
          }
        }
      }
    });
  }

  void _testSolid() {
    if (_useRegisteredOnly) {
      Set<int>? common;
      for (int i = 0; i < 6; i++) {
        final colors = _mergedColorBank[i] ?? {};
        if (colors.isEmpty) continue;
        if (common == null) {
          common = Set<int>.from(colors);
        } else {
          common = common.intersection(colors);
        }
      }

      if (common == null || common.isEmpty) {
        setState(() {
          for (int i = 0; i < 6; i++) {
            final bank = _mergedColorBank[i] ?? {};
            _selectedColors[i] = bank.isNotEmpty ? bank.first : null;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Aucune couleur commune — 1ere couleur par region utilisee'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final colorId = (common.toList()..shuffle()).first;
      setState(() {
        for (int i = 0; i < 6; i++) {
          final bank = _mergedColorBank[i] ?? {};
          _selectedColors[i] = bank.contains(colorId) ? colorId : null;
        }
      });
    } else {
      final random = Random();
      final all = ArkColorPalette.allColors;
      if (all.isNotEmpty) {
        final colorId = all[random.nextInt(all.length)].id;
        setState(() {
          for (int i = 0; i < 6; i++) {
            _selectedColors[i] = colorId;
          }
        });
      }
    }
  }

  void _resetColors() {
    setState(() {
      for (int i = 0; i < 6; i++) {
        _selectedColors[i] = null;
      }
    });
  }

  /// Nettoie les couleurs sélectionnées pour ne garder que celles
  /// présentes dans la banque enregistrée. Les cases dont la couleur
  /// n'est pas dans la banque de leur région sont vidées.
  void _sanitizeColorsForRegisteredMode() {
    for (int i = 0; i < 6; i++) {
      final current = _selectedColors[i];
      if (current == null) continue;
      final bank = _mergedColorBank[i] ?? {};
      if (!bank.contains(current)) {
        _selectedColors[i] = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dinoProvider = context.watch<DinoProvider>();
    final trackerProvider = context.watch<TrackerProvider>();
    _rebuildData(dinoProvider, trackerProvider);

    // Si le mode "Enregistrées" est actif mais qu'il n'y a aucune couleur
    // enregistrée pour cette espèce, on force le retour en mode "Toutes"
    final hasRegisteredColors =
        _mergedColorBank.values.any((set) => set.isNotEmpty);
    if (_useRegisteredOnly && !hasRegisteredColors) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _useRegisteredOnly) {
          setState(() {
            _useRegisteredOnly = false;
            for (int i = 0; i < 6; i++) {
              _selectedColors[i] = null;
            }
          });
        }
      });
    }

    final hexColors = _selectedColors.map((id) {
      if (id == null || id == 0) return '#808080';
      return ArkColorPalette.fromId(id)?.hex ?? '#808080';
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SIMULATEUR',
                          style: GoogleFonts.cinzelDecorative(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Visualiseur de couleurs',
                          style: GoogleFonts.exo2(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _useRegisteredOnly,
                          onChanged: hasRegisteredColors
                              ? (v) {
                                  setState(() {
                                    _useRegisteredOnly = v;
                                    if (v) {
                                      _sanitizeColorsForRegisteredMode();
                                    }
                                  });
                                }
                              : null,
                          activeThumbColor: Colors.cyanAccent,
                          inactiveThumbColor: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        _useRegisteredOnly ? 'Enregistrees' : 'Toutes',
                        style: GoogleFonts.exo2(
                          fontSize: 9,
                          color: _useRegisteredOnly
                              ? Colors.cyanAccent
                              : AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Corps scrollable ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Column(
                  children: [
                    // ── Dino visuel ──
                    GestureDetector(
                      onTap: _showSpeciesPickerDialog,
                      child: Container(
                        height: 240,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                Colors.cyanAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: DinoImageWidget(
                                species: _species,
                                regionColors: hexColors,
                                width: double.infinity,
                                height: 240,
                                fit: BoxFit.contain,
                                showColorBand: false,
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgPrimary
                                      .withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.pets_rounded,
                                        color: Colors.cyanAccent,
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      _species,
                                      style: GoogleFonts.exo2(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgPrimary
                                      .withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.touch_app_rounded,
                                        color: AppTheme.textMuted
                                            .withValues(alpha: 0.7),
                                        size: 12),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Changer d\'espece',
                                      style: GoogleFonts.exo2(
                                        color: AppTheme.textMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 6 cases de couleur ──
                    _buildColorRegionsCard(),
                    const SizedBox(height: 16),
                    _buildColorSources(),
                  ],
                ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte de sélection des 6 régions de couleur avec style optimisé.
  /// Les zones inactives pour l'espèce sont affichées grisées et non cliquables.
 /// Carte de sélection des 6 régions de couleur.
/// Les zones inactives pour l'espèce sont marquées d'un Ø barré
/// mais restent entièrement modifiables (couleur sélectionnable).
Widget _buildColorRegionsCard() {
  final visibility = ArkSpeciesColorRegions.visibilityFor(_species);

  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.borderColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre + compteur de zones actives ──
        Row(
          children: [
            Text(
              'RÉGIONS DE COULEUR',
              style: GoogleFonts.exo2(
                color: Colors.cyanAccent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${ArkSpeciesColorRegions.visibleCount(_species)}/6 actives',
                style: GoogleFonts.exo2(
                  color: Colors.cyanAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 10),

        // ── 6 cases de couleur (toutes cliquables) ──
        Row(
          children: List.generate(6, (i) {
            final isActive = i < visibility.length ? visibility[i] : true;
            final id = _selectedColors[i];
            final hasColor = id != null;
            final color = hasColor
                ? (ArkColorPalette.fromId(id)?.color ?? Colors.grey)
                : Colors.grey.withValues(alpha: 0.18);

            return Expanded(
              child: GestureDetector(
                // ✅ Toujours cliquable, même pour les régions inactives.
                onTap: () => _pickColor(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  margin: EdgeInsets.only(right: i < 5 ? 5 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasColor
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                      width: hasColor ? 1.5 : 1,
                    ),
                    boxShadow: hasColor
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.45),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // Contenu principal : ID couleur ou icône +
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasColor)
                              Text(
                                '$id',
                                style: TextStyle(
                                  color: _isLight(color)
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            else
                              Icon(Icons.add_rounded,
                                  color:
                                      Colors.white.withValues(alpha: 0.45),
                                  size: 20),
                            const SizedBox(height: 2),
                            Text(
                              'R$i',
                              style: TextStyle(
                                color: hasColor
                                    ? (_isLight(color)
                                        ? Colors.black.withValues(alpha: 0.5)
                                        : Colors.white.withValues(alpha: 0.5))
                                    : Colors.white.withValues(alpha: 0.3),
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // ── Badge Ø barré en coin si zone inactive ──
                      if (!isActive)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.85),
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Ø',
                              style: TextStyle(
                                color: Colors.redAccent
                                    .withValues(alpha: 0.95),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),

        // ── Boutons rapides ──
        Row(
          children: [
            Expanded(
              child: _QuickButton(
                icon: Icons.shuffle_rounded,
                label: 'Aléatoire',
                color: Colors.purpleAccent,
                onTap: _randomize,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickButton(
                icon: Icons.star_rounded,
                label: 'Solid',
                color: Colors.amber,
                onTap: _testSolid,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickButton(
                icon: Icons.refresh_rounded,
                label: 'Reset',
                color: AppTheme.danger,
                onTap: _resetColors,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildColorSources() {
    return Container(
      width: double.infinity,
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
              Text(
                'SOURCES DE COULEURS',
                style: GoogleFonts.exo2(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                '${_colorSources.length} source${_colorSources.length > 1 ? 's' : ''}',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_colorSources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune source couleur pour $_species.\nEnregistre des dinos ou des observations.',
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
            )
          else
            ..._colorSources.take(10).map((source) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          source.isLibrary
                              ? Icons.auto_stories_rounded
                              : Icons.remove_red_eye_rounded,
                          size: 12,
                          color: source.isLibrary
                              ? Colors.orangeAccent
                              : Colors.greenAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            source.name,
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: (source.isLibrary
                                    ? Colors.orangeAccent
                                    : Colors.greenAccent)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            source.isLibrary ? 'Biblio' : 'Obs',
                            style: GoogleFonts.exo2(
                              color: source.isLibrary
                                  ? Colors.orangeAccent
                                  : Colors.greenAccent,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(6, (i) {
                        final colorId = source.colors[i];
                        if (colorId == null || colorId == 0) {
                          return Expanded(
                            child: Container(
                              height: 22,
                              margin: EdgeInsets.only(
                                  right: i < 5 ? 2 : 0),
                              decoration: BoxDecoration(
                                color: Colors.grey
                                    .withValues(alpha: 0.15),
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text('-',
                                    style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 9)),
                              ),
                            ),
                          );
                        }
                        final color =
                            ArkColorPalette.fromId(colorId)?.color ??
                                Colors.grey;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColors[i] = colorId;
                              });
                            },
                            child: Container(
                              height: 22,
                              margin: EdgeInsets.only(
                                  right: i < 5 ? 2 : 0),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius:
                                    BorderRadius.circular(4),
                              ),
                              child: Center(
                                child: Text(
                                  '$colorId',
                                  style: TextStyle(
                                    color: _isLight(color)
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  bool _isLight(Color color) => color.computeLuminance() > 0.5;
}

class _QuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              label,
              style: GoogleFonts.exo2(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSourceEntry {
  final String name;
  final List<int?> colors;
  final bool isLibrary;

  _ColorSourceEntry({
    required this.name,
    required this.colors,
    required this.isLibrary,
  });
}
