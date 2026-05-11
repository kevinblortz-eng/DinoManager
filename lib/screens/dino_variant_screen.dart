// lib/screens/dino_variant_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../widgets/common/dino_color_strip.dart';
import '../utils/dino_helpers.dart';
import '../utils/save_image_helper.dart';

class DinoVariantsScreen extends StatefulWidget {
  final Dino baseDino;
  final List<Dino> selectedVariants;

  const DinoVariantsScreen({
    super.key,
    required this.baseDino,
    required this.selectedVariants,
  });

  @override
  State<DinoVariantsScreen> createState() => _DinoVariantsScreenState();
}

class _DinoVariantsScreenState extends State<DinoVariantsScreen> {
  bool _isCapturing = false;

  // ═══════════════════════════════════════════════
  // CAPTURE & SAUVEGARDE
  // ═══════════════════════════════════════════════

  Future<void> _captureAndSave() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    // Récupérer le pixel ratio réel du device AVANT tout await
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    try {
      const double targetWidth = 1080;
      const double targetHeight = 1350;

      // ── Widget export sans MaterialApp imbriqué ──
      // On utilise Directionality + Theme directement pour éviter
      // qu'un MaterialApp parasite intercepte le bouton retour
      final exportWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData.dark(),
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(targetWidth, targetHeight),
              devicePixelRatio: 1.0, // 1.0 ici : la carte est en coords logiques
              padding: EdgeInsets.zero,
            ),
            child: Container(
              width: targetWidth,
              height: targetHeight,
              color: const Color(0xFF0A0E1A),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildExportCard(),
                ),
              ),
            ),
          ),
        ),
      );

      final repaintBoundary = RenderRepaintBoundary();
      final renderView = RenderView(
        view: View.of(context),
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: const BoxConstraints(
            maxWidth: targetWidth,
            maxHeight: targetHeight,
          ),
          devicePixelRatio: 1.0,
        ),
      );

      final pipelineOwner = PipelineOwner();
      pipelineOwner.rootNode = renderView;
      renderView.prepareInitialFrame();

      final buildOwner = BuildOwner(focusManager: FocusManager());
      final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
        container: repaintBoundary,
        debugShortDescription: 'DinoVariantsExport',
        child: exportWidget,
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      // Capturer avec le pixel ratio réel → image nette sur Android
      final image = await repaintBoundary.toImage(pixelRatio: devicePixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      buildOwner.finalizeTree();

      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la génération de l\'image'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final count = widget.selectedVariants.length;
      final fileName = SaveImageHelper.generateFileName(
        widget.baseDino.espece,
        'Variantes-x$count',
      );

      await SaveImageHelper.saveAndNotify(
        context: context,
        pngBytes: byteData.buffer.asUint8List(),
        fileName: fileName,
        displayName: '${widget.baseDino.espece} — $count variantes',
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
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // ═══════════════════════════════════════════════
  // EXPORT CARD 1080x1350
  // ═══════════════════════════════════════════════

  Widget _buildExportCard() {
    final dinoCount = widget.selectedVariants.length;

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
            color: widget.baseDino.roleColor.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Expanded(
              flex: 55,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildVariantsGridExport(dinoCount),
              ),
            ),
            _buildExportSpeciesTitle(),
            Expanded(
              flex: 30,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: DinoStatGrid(dino: widget.baseDino),
              ),
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

  // ═══════════════════════════════════════════════
  // GRILLES (export et affichage — identiques)
  // ═══════════════════════════════════════════════

  Widget _buildVariantsGridExport(int count) =>
      _buildVariantsGrid(count);

  Widget _buildVariantsGrid(int count) {
    final variants = widget.selectedVariants;
    if (count == 0) return _buildVariantCard(widget.baseDino, isLarge: true);
    if (count == 1) return _buildVariantCard(variants[0], isLarge: true);

    if (count == 2) {
      return Row(children: [
        Expanded(child: _buildVariantCard(variants[0])),
        const SizedBox(width: 8),
        Expanded(child: _buildVariantCard(variants[1])),
      ]);
    }

    if (count == 3) {
      return Column(children: [
        Expanded(child: _buildVariantCard(variants[0], isLarge: true)),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildVariantCard(variants[1])),
            const SizedBox(width: 8),
            Expanded(child: _buildVariantCard(variants[2])),
          ]),
        ),
      ]);
    }

    if (count == 4) {
      return Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _buildVariantCard(variants[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildVariantCard(variants[1])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildVariantCard(variants[2])),
            const SizedBox(width: 8),
            Expanded(child: _buildVariantCard(variants[3])),
          ]),
        ),
      ]);
    }

    if (count == 5) {
      return Column(children: [
        Expanded(
          child: Row(children: [
            Expanded(child: _buildVariantCard(variants[0])),
            const SizedBox(width: 8),
            Expanded(child: _buildVariantCard(variants[1])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(children: [
            Expanded(child: _buildVariantCard(variants[2])),
            const SizedBox(width: 8),
            Expanded(child: _buildVariantCard(variants[3])),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildVariantCard(variants[4], isLarge: true)),
      ]);
    }

    // 6 variantes
    return Column(children: [
      Expanded(
        child: Row(children: [
          Expanded(child: _buildVariantCard(variants[0])),
          const SizedBox(width: 8),
          Expanded(child: _buildVariantCard(variants[1])),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Row(children: [
          Expanded(child: _buildVariantCard(variants[2])),
          const SizedBox(width: 8),
          Expanded(child: _buildVariantCard(variants[3])),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Row(children: [
          Expanded(child: _buildVariantCard(variants[4])),
          const SizedBox(width: 8),
          Expanded(child: _buildVariantCard(variants[5])),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════
  // CARTE INDIVIDUELLE — fond simulé sans BackdropFilter
  // ═══════════════════════════════════════════════

Widget _buildVariantCard(Dino variantDino, {bool isLarge = false}) {
  final hasCustomImage =
      variantDino.image != null && variantDino.image!.isNotEmpty;
  final assetPath =
      'assets/images/dinos/${variantDino.espece.replaceAll(' ', '_')}_ASA.png';

  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: variantDino.roleColor, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Stack(
              fit: StackFit.expand,
              children: [

                // ✅ FOND FLOUTÉ CORRIGÉ — variantDino au lieu de _dino
                Positioned.fill(
  child: ClipRect(
    child: Stack(
      fit: StackFit.expand,
      children: [
        hasCustomImage
            ? Image.file(
                File(variantDino.image!), // ✅ variantDino
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildVariantFallbackBg(variantDino),
              )
            : Image.asset(
                assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    _buildVariantFallbackBg(variantDino),
              ),
        BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: const SizedBox.expand(),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.50),
                variantDino.roleColor.withValues(alpha: 0.20), // ✅ variantDino
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
),

                // IMAGE DINO PRINCIPALE (au-dessus du fond)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return hasCustomImage
                            ? Image.file(
                                File(variantDino.image!),
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) =>
                                    _buildDinoImageWidget(
                                  variantDino,
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                ),
                              )
                            : _buildDinoImageWidget(
                                variantDino,
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                      },
                    ),
                  ),
                ),

                // Badge niveau
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: DinoHelpers.getCardRarityColor(
                            variantDino.niveau),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'LVL ${variantDino.niveau}',
                      style: GoogleFonts.exo2(
                        color: DinoHelpers.getCardRarityColor(
                            variantDino.niveau),
                        fontSize: isLarge ? 11 : 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                // Badge sexe
                if (variantDino.sexe != 'Inconnu')
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _buildCompactSexBadge(variantDino, isLarge),
                  ),
              ],
            ),
          ),

          // Bande de couleurs — widget partagé DinoColorStrip
          Expanded(
            flex: 3,
            child: DinoColorStrip(
              dino:   variantDino,
              height: isLarge ? 36 : 28,
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildVariantFallbackBg(Dino dino) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            dino.roleColor.withValues(alpha: 0.35),
            const Color(0xFF0F1115),
          ],
        ),
      ),
    );
  }

  Widget _buildDinoImageWidget(Dino dino, double width, double height) {
    return DinoImageWidget(
      species: dino.espece,
      regionColors: dino.colorRegions,
      width: width,
      height: height,
      fit: BoxFit.contain,
      showColorBand: false,
      alignment: Alignment.center,
    );
  }

  Widget _buildCompactSexBadge(Dino dino, bool isLarge) {
    final isBoth = dino.sexe.contains('Mâle+Femelle');

    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.purple, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('♂',
                style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: isLarge ? 10 : 8,
                    fontWeight: FontWeight.w900)),
            Text('♀',
                style: TextStyle(
                    color: Colors.pink[300],
                    fontSize: isLarge ? 10 : 8,
                    fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return Container(
      width: isLarge ? 24 : 20,
      height: isLarge ? 24 : 20,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: dino.sexeColor, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: isLarge ? 12 : 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TITRE ESPÈCE + STATS — affichage mobile
  // ═══════════════════════════════════════════════

  Widget _buildExportSpeciesTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFF5A5A5A), width: 1),
          bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1),
        ),
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ).createShader(bounds),
            child: Text(
              DinoHelpers.toTitleCase(widget.baseDino.espece),
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
          const SizedBox(height: 6),
          Container(
            height: 2,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.selectedVariants.length} variante${widget.selectedVariants.length > 1 ? 's' : ''}',
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ).createShader(bounds),
          child: Text(
            DinoHelpers.toTitleCase(widget.baseDino.espece),
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              shadows: const [
                Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildCommonStats() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: widget.baseDino.roleColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.transparent,
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF5A5A5A), width: 1),
              ),
            ),
            child: Text(
              'Stats Communes',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: DinoStatGrid(dino: widget.baseDino),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final dinoCount = widget.selectedVariants.length;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      // ── Garantit que le bouton retour physique pop correctement ──
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          // automaticallyImplyLeading: false pour contrôler nous-mêmes
          automaticallyImplyLeading: false,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
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
                tooltip: 'Sauvegarder la DinoCard variantes',
                onPressed: _isCapturing ? null : _captureAndSave,
              ),
            ),
          ],
        ),
        body: SafeArea(
          bottom: true,
          child: Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: bottomPadding > 0 ? 8 : 24,
            ),
            child: Column(
              children: [
                Expanded(
                  flex: dinoCount <= 2 ? 5 : 4,
                  child: _buildVariantsGrid(dinoCount),
                ),
                const SizedBox(height: 16),
                _buildSpeciesTitle(),
                const SizedBox(height: 12),
                Expanded(
                  flex: 3,
                  child: _buildCommonStats(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
