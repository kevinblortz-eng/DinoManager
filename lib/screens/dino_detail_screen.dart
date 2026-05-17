// lib/screens/dino_detail_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../providers/dino_provider.dart';
import '../providers/tag_theme_provider.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../widgets/common/dino_color_strip.dart';
import '../widgets/dino_multi_select_bottom_sheet.dart';
import '../widgets/share_card/dino_share_card_exporter.dart';
import '../utils/dino_helpers.dart';
import 'add_edit_dino_screen.dart';
import 'dino_variant_screen.dart';
import '../widgets/ark_dino_card.dart';
import '../widgets/share_card/ark_dino_card_exporter.dart';


class DinoDetailScreen extends StatefulWidget {
  final Dino dino;
  const DinoDetailScreen({super.key, required this.dino});

  @override
  State<DinoDetailScreen> createState() => _DinoDetailScreenState();
}

class _DinoDetailScreenState extends State<DinoDetailScreen> {
  late Dino _dino;
  bool _isCapturing = false;

  // ── Tailles du médaillon LVL sur la dinocard MOBILE uniquement ────────
  static const double _lvlMobileSize    = 54.0;
  static const double _lvlMobileFontLvl =  9.0;
  static const double _lvlMobileFontNum = 18.0;

  @override
  void initState() {
    super.initState();
    _dino = widget.dino;
  }

  // ════════════════════════════════════════════════════════════════════════
  // RÉSOLUTION COULEUR THÈME
  // ════════════════════════════════════════════════════════════════════════

  Color _resolveThemeColor(TagThemeProvider tagProvider) {
    for (final tag in _dino.tags) {
      final c = tagProvider.colorForTag(tag);
      if (c != null) return c;
    }
    return _dino.roleColor;
  }

  // ════════════════════════════════════════════════════════════════════════
  // CAPTURE — délégue entièrement à DinoShareCardExporter
  // ════════════════════════════════════════════════════════════════════════

 Future<void> _captureAndSave() async {
  if (_isCapturing) return;
  setState(() => _isCapturing = true);

  try {
    await ArkDinoCardExporter(
      dino: _dino,
      // roleTheme: null par défaut → ArkDinoCard utilisera dino.roleColor
      // Si tu veux forcer un thème custom via les tags, tu peux passer
      // un RoleTheme construit depuis themeColor ici.
    ).captureAndSave(context);
  } finally {
    if (mounted) setState(() => _isCapturing = false);
  }
}
  // ════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Consumer<TagThemeProvider>(
      builder: (context, tagProvider, _) {
        final themeColor = _resolveThemeColor(tagProvider);

        return Scaffold(
          backgroundColor: const Color(0xFF0A0E1A),
          body: SafeArea(
            bottom: true,
            child: Column(
              children: [
                _buildAppBar(themeColor),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, 16 + bottomPadding),
                    child: Column(
                      children: [
                        _buildArkCard(themeColor),
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Color themeColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          _circleButton(
            child:       const Icon(Icons.arrow_back, color: Colors.white),
            onTap:       () => Navigator.pop(context),
            borderColor: Colors.white.withValues(alpha: 0.2),
          ),
          const Spacer(),
          _circleButton(
            child: _isCapturing
                ? SizedBox(
                    width:  20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: themeColor, strokeWidth: 2),
                  )
                : Icon(Icons.ios_share_rounded, color: themeColor),
            onTap:       _isCapturing ? null : _captureAndSave,
            borderColor: themeColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required Widget  child,
    VoidCallback?    onTap,
    required Color   borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  44,
        height: 44,
        decoration: BoxDecoration(
          color:  Colors.black.withValues(alpha: 0.6),
          shape:  BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }

// ════════════════════════════════════════════════════════════════════════
// ARK CARD MOBILE — dimensionné comme dans add_edit_dino_screen
// ════════════════════════════════════════════════════════════════════════
Widget _buildArkCard(Color themeColor) {
  // Mêmes proportions de référence que dans AddEditDinoScreen
  const double refW = 242;
  const double refH = 428;

  return Center(
    child: ConstrainedBox(
      // Largeur max raisonnable sur mobile, le reste s'adapte
      constraints: const BoxConstraints(maxWidth: 360),
      child: AspectRatio(
        aspectRatio: refW / refH,
        child: Hero(
          tag: 'dino_${_dino.id}',
          child: Material(
            color: Colors.transparent,
            child: ArkDinoCard(
              dino: _dino,
            ),
          ),
        ),
      ),
    ),
  );
}

  // ════════════════════════════════════════════════════════════════════════
  // SECTION VISUELLE — image + badges LVL/GENRE (mobile)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildVisualSection(Color themeColor) {
    const double visualHeight = 280.0;

    final hasCustomImage = _dino.image != null && _dino.image!.isNotEmpty;
    final assetPath =
        'assets/images/dinos/${_dino.espece.replaceAll(' ', '_')}_ASA.png';

    return SizedBox(
      height: visualHeight,
      child: Stack(
        children: [
          // ── Fond flouté ──────────────────────────────────────────────
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasCustomImage
                      ? Image.file(File(_dino.image!),
                          fit:          BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackBg(themeColor))
                      : Image.asset(assetPath,
                          fit:          BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildFallbackBg(themeColor)),
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child:  const SizedBox.expand(),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin:  Alignment.topCenter,
                        end:    Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.50),
                          themeColor.withValues(alpha: 0.20),
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ligne de séparation bas ──────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
                height: 2,
                color:  themeColor.withValues(alpha: 0.6)),
          ),

          // ── Image dino centrée ───────────────────────────────────────
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Hero(
                tag: 'dino_${_dino.id}',
                child: hasCustomImage
                    ? Image.file(File(_dino.image!),
                        fit:          BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            _buildMobileSpeciesImage())
                    : _buildMobileSpeciesImage(),
              ),
            ),
          ),

          // ── Badge LVL mobile — petit (54 px) ────────────────────────
          Positioned(
            top:  9,
            left: 9,
            child: _buildMobileLevelBadge(),
          ),

          // ── Badge genre mobile ───────────────────────────────────────
          if (_dino.sexe != 'Inconnu')
            Positioned(
              top:   9,
              right: 9,
              child: _buildMobileGenderBadge(),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BADGE LVL MOBILE — taille fixe 54 px, stylistique dinocard
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMobileLevelBadge() {
    final rarityColor = DinoHelpers.getCardRarityColor(_dino.niveau);
    return Container(
      width:  _lvlMobileSize,
      height: _lvlMobileSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.82),
        border: Border.all(color: rarityColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color:      rarityColor.withValues(alpha: 0.6),
            blurRadius: _lvlMobileSize * 0.25,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'LVL',
            style: GoogleFonts.exo2(
              color:         rarityColor.withValues(alpha: 0.85),
              fontSize:      _lvlMobileFontLvl,
              fontWeight:    FontWeight.w700,
              letterSpacing: 1.5,
              height:        1.1,
            ),
          ),
          Text(
            '${_dino.niveau}',
            style: GoogleFonts.exo2(
              color:      rarityColor,
              fontSize:   _lvlMobileFontNum,
              fontWeight: FontWeight.w900,
              height:     1.0,
              shadows: [
                Shadow(
                  color:      rarityColor.withValues(alpha: 0.7),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BADGE GENRE MOBILE — taille fixe 36 px
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildMobileGenderBadge() {
    final isBoth = _dino.sexe == 'Mâle+Femelle';
    final isMale = _dino.sexe == 'Mâle';

    if (isBoth) {
      return Container(
        width:  46,
        height: 36,
        decoration: BoxDecoration(
          color:        Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(6),
          border:       Border.all(color: Colors.purple, width: 2.0),
          boxShadow: [
            BoxShadow(
              color:      Colors.purple.withValues(alpha: 0.4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('♂',
                style: TextStyle(
                    color:      Colors.blue[300],
                    fontSize:   16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 2),
            Text('♀',
                style: TextStyle(
                    color:      Colors.pink[300],
                    fontSize:   16,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    final genderColor  = isMale ? Colors.blue[300]! : Colors.pink[300]!;
    final genderSymbol = isMale ? '♂' : '♀';

    return Container(
      width:  36,
      height: 36,
      decoration: BoxDecoration(
        color:  Colors.black.withValues(alpha: 0.75),
        shape:  BoxShape.circle,
        border: Border.all(color: genderColor, width: 2.0),
        boxShadow: [
          BoxShadow(
            color:      genderColor.withValues(alpha: 0.45),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        genderSymbol,
        style: TextStyle(
            color:      genderColor,
            fontSize:   18,
            fontWeight: FontWeight.w900),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS VISUELS
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildFallbackBg(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            themeColor.withValues(alpha: 0.35),
            const Color(0xFF0F1115),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSpeciesImage() {
    return DinoImageWidget(
      species:       _dino.espece,
      regionColors:  _dino.colorRegions,
      width:         double.infinity,
      height:        280,
      fit:           BoxFit.contain,
      showColorBand: false,
      alignment:     Alignment.center,
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // SECTION TITRE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildTitleSection(Color themeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: themeColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [themeColor, themeColor.withValues(alpha: 0.7)],
            ).createShader(bounds),
            child: Text(
              DinoHelpers.toTitleCase(_dino.espece),
              style: GoogleFonts.cinzelDecorative(
                color:         Colors.white,
                fontSize:      32,
                fontWeight:    FontWeight.w900,
                letterSpacing: 2.5,
              ),
              textAlign: TextAlign.center,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color:        Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: themeColor.withValues(alpha: 0.55), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _dino.nom,
                    style: GoogleFonts.exo2(
                      color:      Colors.white.withValues(alpha: 0.9),
                      fontSize:   16,
                      fontStyle:  FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:        themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColor, width: 1),
                  ),
                  child: Text(
                    _dino.role.toUpperCase(),
                    style: TextStyle(
                      color:      themeColor,
                      fontSize:   10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // BOUTONS D'ACTION
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon:      Icons.edit_rounded,
                label:     'MODIFIER',
                color:     AppTheme.accentSecondary,
                onPressed: _editDino,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon:      Icons.copy_all_rounded,
                label:     'DUPLIQUER',
                color:     AppTheme.accentGreen,
                onPressed: _duplicateDino,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon:      Icons.delete_outline_rounded,
                label:     'SUPPRIMER',
                color:     AppTheme.danger,
                onPressed: _confirmDelete,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon:      Icons.palette_outlined,
                label:     'VARIANTES',
                color:     const Color(0xFF9C27B0),
                onPressed: _viewVariants,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData     icon,
    required String       label,
    required Color        color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:        onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color:        color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                color:      color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset:     const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.exo2(
                    color:      color,
                    fontSize:   14,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _editDino() async {
    final updated = await Navigator.push<Dino>(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditDinoScreen(dino: _dino)),
    );
    if (updated != null && mounted) {
      setState(() => _dino = updated);
    }
  }

  Future<void> _duplicateDino() async {
    final copy = _dino.duplicate(newName: '${_dino.nom} (copie)');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditDinoScreen(dino: copy)),
    ).then((_) {
      if (mounted) {
        Provider.of<DinoProvider>(context, listen: false).loadDinos();
      }
    });
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
            'Supprimer ${_dino.nom}?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text(
            'Cette action est irréversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppTheme.textMuted))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      if (_dino.id != null) {
        await Provider.of<DinoProvider>(context, listen: false)
            .deleteDino(_dino.id!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _viewVariants() async {
    final provider    = Provider.of<DinoProvider>(context, listen: false);
    final sameSpecies = provider.dinos
        .where((d) => d.espece == _dino.espece)
        .toList();

    if (sameSpecies.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:         Text('Aucun autre dinosaure de cette espèce'),
        backgroundColor: AppTheme.bgCard,
        behavior:        SnackBarBehavior.floating,
      ));
      return;
    }
    if (!mounted) return;

    final selected = await showModalBottomSheet<List<Dino>>(
      context:            context,
      useSafeArea:        true,
      isScrollControlled: true,
      backgroundColor:    Colors.transparent,
      builder: (context) => DinoMultiSelectBottomSheet(
        availableDinos:   sameSpecies,
        referenceDino:    _dino,
        preSelectedDinos: const [],
      ),
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DinoVariantsScreen(
            baseDino:         _dino,
            selectedVariants: selected,
          ),
        ),
      );
    }
  }
}
