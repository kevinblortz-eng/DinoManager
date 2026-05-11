// lib/screens/dino_detail_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter/rendering.dart';
=======
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../providers/dino_provider.dart';
<<<<<<< HEAD
=======
import '../providers/tag_theme_provider.dart';
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../widgets/common/dino_color_strip.dart';
import '../widgets/dino_multi_select_bottom_sheet.dart';
<<<<<<< HEAD
import '../utils/dino_helpers.dart';
import '../utils/save_image_helper.dart';
=======
import '../widgets/share_card/dino_share_card_exporter.dart';
import '../utils/dino_helpers.dart';
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
import 'add_edit_dino_screen.dart';
import 'dino_variant_screen.dart';

class DinoDetailScreen extends StatefulWidget {
  final Dino dino;
  const DinoDetailScreen({super.key, required this.dino});

  @override
  State<DinoDetailScreen> createState() => _DinoDetailScreenState();
}

class _DinoDetailScreenState extends State<DinoDetailScreen> {
  late Dino _dino;
<<<<<<< HEAD
  final GlobalKey _exportKey = GlobalKey();
  bool _isCapturing = false;
  bool _showExportWidget = false;
=======
  bool _isCapturing = false;

  // ── Tailles du médaillon LVL sur la dinocard MOBILE uniquement ────────
  static const double _lvlMobileSize    = 54.0;
  static const double _lvlMobileFontLvl =  9.0;
  static const double _lvlMobileFontNum = 18.0;
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

  @override
  void initState() {
    super.initState();
    _dino = widget.dino;
  }

<<<<<<< HEAD
  // ═══════════════════════════════════════════════
  // CAPTURE & SAUVEGARDE
  // ═══════════════════════════════════════════════

  Future<void> _captureAndSave() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _showExportWidget = true;
    });

    // Laisser le temps à DinoImageWidget de calculer le grain-merge
    await Future.delayed(const Duration(milliseconds: 600));

    try {
      final boundary = _exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        throw Exception('Widget export introuvable');
      }

      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Erreur génération PNG');
      if (!mounted) return;

      final fileName = SaveImageHelper.generateFileName(
        _dino.espece,
        _dino.nom,
      );

      await SaveImageHelper.saveAndNotify(
        context: context,
        pngBytes: byteData.buffer.asUint8List(),
        fileName: fileName,
        displayName: '${_dino.espece} — ${_dino.nom}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _showExportWidget = false;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════
  // EXPORT CARD 1080×1350 — monté en Offstage
  // ═══════════════════════════════════════════════

  Widget _buildOffstageExport() {
    return Offstage(
      offstage: true,
      child: RepaintBoundary(
        key: _exportKey,
        child: SizedBox(
          width: 1080,
          height: 1350,
          child: _buildExportCard(),
        ),
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: _dino.roleColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            SizedBox(
              height: 540,
              child: _buildExportVisualSection(),
            ),
            _buildExportTitleSection(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: DinoStatGrid(dino: _dino),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DinoColorStrip(dino: _dino),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: const Border(
                  top: BorderSide(color: Color(0xFF5A5A5A), width: 1),
                ),
              ),
              child: Text(
                'DINO MANAGER',
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportVisualSection() {
    // ← champ correct du modèle Dino
    final hasCustomImage = _dino.image != null && _dino.image!.isNotEmpty;
    final assetPath =
        'assets/images/dinos/${_dino.espece.replaceAll(' ', '_')}_ASA.png';

    return Stack(
      children: [
        // ── FOND : image assombrie (sans BackdropFilter → compatible export) ──
        Positioned.fill(
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasCustomImage
                    ? Image.file(
                        File(_dino.image!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackBg(),
                      )
                    : Image.asset(
                        assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildFallbackBg(),
                      ),
                // Simulation flou : overlay blanc léger
                Container(color: Colors.white.withValues(alpha: 0.08)),
                // Overlay sombre + roleColor
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.62),
                        _dino.roleColor.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Bordure basse ──
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(height: 2, color: const Color(0xFF5A5A5A)),
        ),
        // ── Dino principal ──
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: hasCustomImage
                ? Image.file(
                    File(_dino.image!),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => DinoImageWidget(
                      species: _dino.espece,
                      regionColors: _dino.colorRegions,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      showColorBand: false,
                    ),
                  )
                : DinoImageWidget(
                    species: _dino.espece,
                    regionColors: _dino.colorRegions,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    showColorBand: false,
                  ),
          ),
        ),
        // ── Badge niveau ──
        Positioned(
          top: 20, left: 20,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: DinoHelpers.getCardRarityColor(_dino.niveau),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: DinoHelpers.getCardRarityColor(_dino.niveau)
                      .withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'LVL ${_dino.niveau}',
              style: GoogleFonts.exo2(
                color: DinoHelpers.getCardRarityColor(_dino.niveau),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        // ── Badge sexe ──
        if (_dino.sexe != 'Inconnu')
          Positioned(
            top: 20, right: 20,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: _dino.sexeColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _dino.sexeColor.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _dino.sexeSymbol,
                style: TextStyle(
                  color: _dino.sexeColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExportTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
        ),
        border: const Border(
            bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1)),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ).createShader(bounds),
            child: Text(
              DinoHelpers.toTitleCase(_dino.espece),
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: const [
                  Shadow(
                      color: Colors.black,
                      blurRadius: 8,
                      offset: Offset(2, 2)),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _dino.roleColor.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _dino.nom,
                    style: GoogleFonts.exo2(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _dino.roleColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: _dino.roleColor, width: 1),
                  ),
                  child: Text(
                    _dino.role.toUpperCase(),
                    style: TextStyle(
                      color: _dino.roleColor,
                      fontSize: 12,
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

  // ═══════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════
=======
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
      final tagProvider = context.read<TagThemeProvider>();
      final themeColor  = _resolveThemeColor(tagProvider);

      await DinoShareCardExporter(
        dino:       _dino,
        themeColor: themeColor,
      ).captureAndSave(context);
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ════════════════════════════════════════════════════════════════════════
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

<<<<<<< HEAD
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          // ── UI principale ──
          SafeArea(
            bottom: true,
            child: Column(
              children: [
                _buildAppBar(),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        16, 16, 16, 16 + bottomPadding),
                    child: Column(
                      children: [
<<<<<<< HEAD
                        _buildArkCard(),
=======
                        _buildArkCard(themeColor),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                        const SizedBox(height: 20),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
<<<<<<< HEAD
          // ── Widget export caché (Offstage) ──
          if (_showExportWidget) _buildOffstageExport(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
=======
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // APP BAR
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(Color themeColor) {
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
<<<<<<< HEAD
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: _isCapturing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E5FF),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_alt_rounded,
                      color: Color(0xFF00E5FF)),
              tooltip: 'Sauvegarder la DinoCard',
              onPressed: _isCapturing ? null : _captureAndSave,
            ),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  // ═══════════════════════════════════════════════
  // ARK CARD (affichage mobile)
  // ═══════════════════════════════════════════════

  Widget _buildArkCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _dino.roleColor.withValues(alpha: 0.3),
            blurRadius: 15,
=======
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
  // ARK CARD MOBILE
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildArkCard(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color:        const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: themeColor.withValues(alpha: 0.7), width: 3),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset:     const Offset(0, 10),
          ),
          BoxShadow(
            color:        themeColor.withValues(alpha: 0.35),
            blurRadius:   20,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
<<<<<<< HEAD
          _buildVisualSection(),
          _buildTitleSection(),
          DinoStatGrid(dino: _dino),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DinoColorStrip(dino: _dino),
=======
          _buildVisualSection(themeColor),
          _buildTitleSection(themeColor),
          DinoStatGrid(dino: _dino),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child:   DinoColorStrip(dino: _dino),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

<<<<<<< HEAD
  // ── Zone visuelle avec fond flouté (BackdropFilter OK — affichage live) ──
  Widget _buildVisualSection() {
=======
  // ════════════════════════════════════════════════════════════════════════
  // SECTION VISUELLE — image + badges LVL/GENRE (mobile)
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildVisualSection(Color themeColor) {
    const double visualHeight = 280.0;

>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    final hasCustomImage = _dino.image != null && _dino.image!.isNotEmpty;
    final assetPath =
        'assets/images/dinos/${_dino.espece.replaceAll(' ', '_')}_ASA.png';

    return SizedBox(
<<<<<<< HEAD
      height: 280,
      child: Stack(
        children: [
          // ── FOND FLOUTÉ ──
=======
      height: visualHeight,
      child: Stack(
        children: [
          // ── Fond flouté ──────────────────────────────────────────────
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          Positioned.fill(
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasCustomImage
<<<<<<< HEAD
                      ? Image.file(
                          File(_dino.image!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackBg(),
                        )
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackBg(),
                        ),
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: const SizedBox.expand(),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
<<<<<<< HEAD
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.50),
                          _dino.roleColor.withValues(alpha: 0.20),
=======
                        begin:  Alignment.topCenter,
                        end:    Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.50),
                          themeColor.withValues(alpha: 0.20),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
<<<<<<< HEAD
          // ── BORDURE BASSE ──
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(height: 2, color: const Color(0xFF5A5A5A)),
          ),
          // ── IMAGE DINO PRINCIPALE ──
=======

          // ── Ligne de séparation bas ──────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
                height: 2,
                color:  themeColor.withValues(alpha: 0.6)),
          ),

          // ── Image dino centrée ───────────────────────────────────────
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Hero(
                tag: 'dino_${_dino.id}',
                child: hasCustomImage
<<<<<<< HEAD
                    ? Image.file(
                        File(_dino.image!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildSpeciesImage(),
                      )
                    : _buildSpeciesImage(),
              ),
            ),
          ),
          // ── BADGE NIVEAU ──
          Positioned(
            top: 16, left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau)
                        .withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                'LVL ${_dino.niveau}',
                style: GoogleFonts.exo2(
                  color: DinoHelpers.getCardRarityColor(_dino.niveau),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          // ── BADGE SEXE ──
          if (_dino.sexe != 'Inconnu')
            Positioned(
              top: 16, right: 16,
              child: _buildSexBadge(),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildFallbackBg() {
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
<<<<<<< HEAD
            _dino.roleColor.withValues(alpha: 0.35),
=======
            themeColor.withValues(alpha: 0.35),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            const Color(0xFF0F1115),
          ],
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildSexBadge() {
    final isBoth = _dino.sexe.contains('Mâle+Femelle');

    if (isBoth) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.purple, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('♂',
                style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 4),
            Text('♀',
                style: TextStyle(
                    color: Colors.pink[300],
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: _dino.sexeColor, width: 2),
        boxShadow: [
          BoxShadow(
              color: _dino.sexeColor.withValues(alpha: 0.5), blurRadius: 8),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        _dino.sexeSymbol,
        style: TextStyle(
            color: _dino.sexeColor,
            fontSize: 22,
            fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildSpeciesImage() {
    return DinoImageWidget(
      species: _dino.espece,
      regionColors: _dino.colorRegions,
      width: double.infinity,
      height: 280,
      fit: BoxFit.contain,
      showColorBand: false,
      alignment: Alignment.center,
    );
  }

  Widget _buildTitleSection() {
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
<<<<<<< HEAD
          colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
        ),
        border: const Border(
            bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1)),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
      ),
      child: Column(
        children: [
          ShaderMask(
<<<<<<< HEAD
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
=======
            shaderCallback: (bounds) => LinearGradient(
              colors: [themeColor, themeColor.withValues(alpha: 0.7)],
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ).createShader(bounds),
            child: Text(
              DinoHelpers.toTitleCase(_dino.espece),
              style: GoogleFonts.cinzelDecorative(
<<<<<<< HEAD
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                shadows: const [
                  Shadow(
                      color: Colors.black,
                      blurRadius: 6,
                      offset: Offset(2, 2)),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
=======
                color:         Colors.white,
                fontSize:      32,
                fontWeight:    FontWeight.w900,
                letterSpacing: 2.5,
              ),
              textAlign: TextAlign.center,
              maxLines:  1,
              overflow:  TextOverflow.ellipsis,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
<<<<<<< HEAD
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _dino.roleColor.withValues(alpha: 0.6), width: 1),
=======
              color:        Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: themeColor.withValues(alpha: 0.55), width: 1),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _dino.nom,
                    style: GoogleFonts.exo2(
<<<<<<< HEAD
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
=======
                      color:      Colors.white.withValues(alpha: 0.9),
                      fontSize:   16,
                      fontStyle:  FontStyle.italic,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
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
<<<<<<< HEAD
                    color: _dino.roleColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: _dino.roleColor, width: 1),
=======
                    color:        themeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: themeColor, width: 1),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                  ),
                  child: Text(
                    _dino.role.toUpperCase(),
                    style: TextStyle(
<<<<<<< HEAD
                      color: _dino.roleColor,
                      fontSize: 10,
=======
                      color:      themeColor,
                      fontSize:   10,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
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

<<<<<<< HEAD
  // ═══════════════════════════════════════════════
  // BOUTONS D'ACTION
  // ═══════════════════════════════════════════════
=======
  // ════════════════════════════════════════════════════════════════════════
  // BOUTONS D'ACTION
  // ════════════════════════════════════════════════════════════════════════
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
<<<<<<< HEAD
                child: _buildActionButton(
              icon: Icons.edit_rounded,
              label: 'MODIFIER',
              color: AppTheme.accentSecondary,
              onPressed: _editDino,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildActionButton(
              icon: Icons.copy_all_rounded,
              label: 'DUPLIQUER',
              color: AppTheme.accentGreen,
              onPressed: _duplicateDino,
            )),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
<<<<<<< HEAD
                child: _buildActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'SUPPRIMER',
              color: AppTheme.danger,
              onPressed: _confirmDelete,
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildActionButton(
              icon: Icons.palette_outlined,
              label: 'VARIANTES',
              color: const Color(0xFF9C27B0),
              onPressed: _viewVariants,
            )),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
<<<<<<< HEAD
    required IconData icon,
    required String label,
    required Color color,
=======
    required IconData     icon,
    required String       label,
    required Color        color,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
<<<<<<< HEAD
        onTap: onPressed,
=======
        onTap:        onPressed,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
<<<<<<< HEAD
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
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
<<<<<<< HEAD
                    color: color,
                    fontSize: 14,
=======
                    color:      color,
                    fontSize:   14,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  // ═══════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════
=======
  // ════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ════════════════════════════════════════════════════════════════════════
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b

  Future<void> _editDino() async {
    final updated = await Navigator.push<Dino>(
      context,
<<<<<<< HEAD
      MaterialPageRoute(builder: (_) => AddEditDinoScreen(dino: _dino)),
=======
      MaterialPageRoute(
          builder: (_) => AddEditDinoScreen(dino: _dino)),
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
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
<<<<<<< HEAD
        title: Text('Supprimer ${_dino.nom}?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
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

=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
    if (confirm == true && mounted) {
      if (_dino.id != null) {
        await Provider.of<DinoProvider>(context, listen: false)
            .deleteDino(_dino.id!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _viewVariants() async {
<<<<<<< HEAD
    final provider = Provider.of<DinoProvider>(context, listen: false);
    final sameSpecies = provider.dinos
        .where((dino) => dino.espece == _dino.espece)
=======
    final provider    = Provider.of<DinoProvider>(context, listen: false);
    final sameSpecies = provider.dinos
        .where((d) => d.espece == _dino.espece)
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        .toList();

    if (sameSpecies.length <= 1) {
      if (!mounted) return;
<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun autre dinosaure de cette espèce trouvé'),
          backgroundColor: AppTheme.bgCard,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    final selectedDinos = await showModalBottomSheet<List<Dino>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DinoMultiSelectBottomSheet(
        availableDinos: sameSpecies,
        referenceDino: _dino,
=======
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
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
        preSelectedDinos: const [],
      ),
    );

<<<<<<< HEAD
    if (selectedDinos != null && selectedDinos.isNotEmpty && mounted) {
=======
    if (selected != null && selected.isNotEmpty && mounted) {
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DinoVariantsScreen(
<<<<<<< HEAD
            baseDino: _dino,
            selectedVariants: selectedDinos,
=======
            baseDino:         _dino,
            selectedVariants: selected,
>>>>>>> 530e4a57806049aaca6c1391e8e01e58391f871b
          ),
        ),
      );
    }
  }
}
