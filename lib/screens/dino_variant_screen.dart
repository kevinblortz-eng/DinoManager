// lib/screens/dino_variant_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../models/ark_species_color_regions.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../utils/dino_helpers.dart';
import '../utils/save_image_helper.dart';
import '../l10n/app_localizations.dart';

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

  // Clé attachée au RepaintBoundary visible dans l'arbre de widgets
  final GlobalKey _exportKey = GlobalKey();

  // ═══════════════════════════════════════════════
  // CAPTURE & SAUVEGARDE — via RepaintBoundary visible
  // ═══════════════════════════════════════════════

  Future<void> _captureAndSave() async {
    if (_isCapturing) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isCapturing = true);

    try {
      // Laisser le frame se rendre complètement
      await Future.delayed(const Duration(milliseconds: 150));

      final boundary = _exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorImageGeneration),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
        return;
      }

      // pixelRatio élevé pour une image haute résolution
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorImageGeneration),
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
        'Variants-x$count',
      );

      await SaveImageHelper.saveAndNotify(
        context: context,
        pngBytes: byteData.buffer.asUint8List(),
        fileName: fileName,
        displayName: '${widget.baseDino.espece} — $count ${l10n.variantsTitle.toLowerCase()}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.errorGeneric}: $e'),
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
                child: _VariantStatGrid(dino: widget.baseDino),
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
  // GRILLES
  // ═══════════════════════════════════════════════

  Widget _buildVariantsGridExport(int count) => _buildVariantsGrid(count);

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
  // CARTE INDIVIDUELLE
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
                  // FOND FLOUTÉ
                  Positioned.fill(
                    child: ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          hasCustomImage
                              ? Image.file(
                                  File(variantDino.image!),
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
                                  variantDino.roleColor
                                      .withValues(alpha: 0.20),
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // IMAGE DINO PRINCIPALE
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
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 72),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.82),
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
                            fontSize: isLarge ? 10 : 8,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Badge sexe
                  if (variantDino.sexe != 'Inconnu')
                    Positioned(
                      top: 4,
                      right: 4,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 48),
                        child: _buildCompactSexBadge(variantDino, isLarge),
                      ),
                    ),
                ],
              ),
            ),

            // ── BANDE DE COULEURS LOCALE (numéros adaptatifs + centrés) ──
            Expanded(
              flex: 3,
              child: _VariantColorStrip(dino: variantDino),
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
  // TITRES
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
                    color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              AppLocalizations.of(context)?.dinoDetailStats ?? 'Stats',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Grille de stats locale avec détail des points
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _VariantStatGrid(dino: widget.baseDino),
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
      canPop: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          // ── BOUTON RETOUR (fonctionnel) ───────────────────────────────
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
              tooltip: AppLocalizations.of(context)?.confirmClose ?? 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          // ── ACTIONS : bouton share DÉSACTIVÉ + bouton save actif ──────
          actions: [
            // Bouton share (désactivé pour l'instant)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.share_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
                tooltip: 'Partage temporairement désactivé',
                onPressed: null, // TODO: réactiver quand l'écran share sera prêt
              ),
            ),
            // Bouton save (actif)
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
                tooltip: AppLocalizations.of(context)?.variantsExport ?? 'Export variants',
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
            child: RepaintBoundary(
              key: _exportKey,
              child: Column(
                children: [
                  Expanded(
                    flex: dinoCount <= 2 ? 5 : 4,
                    child: _buildVariantsGrid(dinoCount),
                  ),
                  const SizedBox(height: 12),
                  _buildSpeciesTitle(),
                  const SizedBox(height: 8),
                  Flexible(
                    flex: 3,
                    child: _buildCommonStats(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS LOCAUX — Stats grid + Color strip (logique reprise d'ArkDinoCard)
// ═══════════════════════════════════════════════════════════════════════════

/// Grille 3×2 des stats du dino, avec détail des points (+N pts) sur 3e ligne.
class _VariantStatGrid extends StatelessWidget {
  final Dino dino;
  const _VariantStatGrid({required this.dino});

  String _intVal(int v) => v > 0 ? DinoHelpers.formatNumber(v) : '???';
  String _dmgVal(double v) => v > 0 ? '${v.toStringAsFixed(0)}%' : '???';
  int? _userPts(int pts) => pts > 0 ? pts : null;

  @override
  Widget build(BuildContext context) {
    final cells = <_VariantStatData>[
      _VariantStatData(
        emoji: '❤️', label: 'VIE',
        value: _intVal(dino.hp),
        color: const Color(0xFF4CAF50),
        isDefault: dino.hp == 0,
        points: dino.hp > 0 ? _userPts(dino.hpPoints) : null,
      ),
      _VariantStatData(
        emoji: '⚡', label: 'STAM',
        value: _intVal(dino.stamina),
        color: const Color(0xFFFFD700),
        isDefault: dino.stamina == 0,
        points: dino.stamina > 0 ? _userPts(dino.staminaPoints) : null,
      ),
      _VariantStatData(
        emoji: '⚔️', label: 'ATTACK',
        value: _dmgVal(dino.degats),
        color: const Color(0xFFEF4444),
        isDefault: dino.degats == 0,
        points: dino.degats > 0 ? _userPts(dino.degatsPoints) : null,
      ),
      _VariantStatData(
        emoji: '⚖️', label: 'POIDS',
        value: _intVal(dino.poids),
        color: const Color(0xFF3B82F6),
        isDefault: dino.poids == 0,
        points: dino.poids > 0 ? _userPts(dino.poidsPoints) : null,
      ),
      _VariantStatData(
        emoji: '🍖', label: 'FOOD',
        value: _intVal(dino.nourriture),
        color: const Color(0xFF8B5CF6),
        isDefault: dino.nourriture == 0,
        points: dino.nourriture > 0 ? _userPts(dino.nourriturePoints) : null,
      ),
      _VariantStatData(
        emoji: '🫧', label: 'OXY',
        value: _intVal(dino.oxygene),
        color: const Color(0xFF10B981),
        isDefault: dino.oxygene == 0,
        points: dino.oxygene > 0 ? _userPts(dino.oxygenePoints) : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 colonnes × 2 lignes
        const int cols = 3;
        const int rows = 2;
        const double hGap = 6;
        const double vGap = 6;
        final cellW = (constraints.maxWidth - hGap * (cols - 1)) / cols;
        final cellH = (constraints.maxHeight - vGap * (rows - 1)) / rows;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(rows, (r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r == rows - 1 ? 0 : vGap),
              child: Row(
                children: List.generate(cols, (c) {
                  final i = r * cols + c;
                  return Padding(
                    padding: EdgeInsets.only(right: c == cols - 1 ? 0 : hGap),
                    child: SizedBox(
                      width: cellW,
                      height: cellH,
                      child: _StatCell(data: cells[i]),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class _VariantStatData {
  final String emoji;
  final String label;
  final String value;
  final Color color;
  final bool isDefault;
  final int? points;

  const _VariantStatData({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
    required this.isDefault,
    required this.points,
  });
}

class _StatCell extends StatelessWidget {
  final _VariantStatData data;
  const _StatCell({required this.data});

  @override
  Widget build(BuildContext context) {
    final effColor = data.isDefault
        ? data.color.withValues(alpha: 0.50)
        : data.color;

    String pointsText = '';
    Color pointsColor = Colors.transparent;
    if (data.points != null && data.points! > 0) {
      pointsText = '+${data.points} pts';
      pointsColor = effColor.withValues(alpha: 0.9);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        // Répartition verticale : label 28%, valeur 42%, points 22%, padding 8%
        final hLabel = h * 0.28;
        final hValue = h * 0.42;
        final hPoints = h * 0.22;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: effColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Ligne 1 : emoji + label
              SizedBox(
                height: hLabel,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(data.emoji,
                          style: const TextStyle(fontSize: 14, height: 1.0)),
                      const SizedBox(width: 3),
                      Text(
                        data.label,
                        style: GoogleFonts.exo2(
                          color: Colors.white
                              .withValues(alpha: data.isDefault ? 0.45 : 0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Ligne 2 : valeur (centrée verticalement, sans descendre)
              SizedBox(
                height: hValue,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.value,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.exo2(
                      color: effColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      shadows: [
                        Shadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ),
              // Ligne 3 : points (zone réservée même si vide)
              SizedBox(
                height: hPoints,
                child: pointsText.isEmpty
                    ? const SizedBox.shrink()
                    : FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          pointsText,
                          style: GoogleFonts.exo2(
                            color: pointsColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bande horizontale de 6 carrés de couleurs.
/// Nouvelle règle simple :
///   - Couleur posée  → carré coloré + ID centré (FittedBox + height:1.0)
///   - Pas de couleur → carré gris uni
/// Plus de distinction visuelle active/inactive : une couleur déclarée
/// s'affiche toujours, même si la région est invisible sur le modèle 3D.
class _VariantColorStrip extends StatelessWidget {
  final Dino dino;
  const _VariantColorStrip({required this.dino});

  @override
  Widget build(BuildContext context) {
    final colors = _resolveDisplayColors();
    final ids = _resolveDisplayIds();

    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // On dimensionne le carré pour qu'il rentre dans la hauteur dispo,
          // sans dépasser une largeur raisonnable.
          const int n = 6;
          const double gap = 4;
          final maxByWidth = (constraints.maxWidth - gap * (n - 1)) / n;
          final maxByHeight = constraints.maxHeight;
          final cellSize = maxByWidth < maxByHeight ? maxByWidth : maxByHeight;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(n, (i) {
              final hex = i < colors.length ? colors[i] : null;
              final id = i < ids.length ? ids[i] : 0;
              final parsed = DinoHelpers.parseHex(hex);
              final isFilled = parsed != null &&
                  hex != '#808080' &&
                  hex != '#7F7F7F' &&
                  id > 0;

              return Padding(
                padding: EdgeInsets.only(right: i == n - 1 ? 0 : gap),
                child: SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: _ColorSquare(
                    color: parsed,
                    colorId: id,
                    isFilled: isFilled,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ─── Logique Solid / VisualSolid (identique à ArkDinoCard) ───────────────
  // On garde la consultation de la visibilité ici car elle sert à la logique
  // métier (propagation de la couleur Solid sur les régions visibles), pas
  // au rendu visuel des carrés.
  List<String?> _resolveDisplayColors() {
    final base = dino.colorRegions;
    final hasSolid = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid =
        dino.tags.any((t) => t.toLowerCase() == 'visualsolid');

    if (!hasSolid && !hasVisualSolid) return base;

    String? firstColor;
    for (final c in base) {
      if (c != null &&
          c.toUpperCase().replaceAll('#', '') != '808080' &&
          c.toUpperCase().replaceAll('#', '') != '7F7F7F') {
        firstColor = c;
        break;
      }
    }
    if (firstColor == null) return base;

    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);
    return List.generate(6, (i) {
      if (hasSolid) return firstColor;
      final active = i < visibility.length ? visibility[i] : true;
      return active ? firstColor : base[i];
    });
  }

  List<int> _resolveDisplayIds() {
    final baseIds = [
      dino.colorId0,
      dino.colorId1,
      dino.colorId2,
      dino.colorId3,
      dino.colorId4,
      dino.colorId5,
    ];
    final hasSolid = dino.tags.any((t) => t.toLowerCase() == 'solid');
    final hasVisualSolid =
        dino.tags.any((t) => t.toLowerCase() == 'visualsolid');

    if (!hasSolid && !hasVisualSolid) return baseIds;

    int firstId = 0;
    for (final id in baseIds) {
      if (id > 0) {
        firstId = id;
        break;
      }
    }
    if (firstId == 0) return baseIds;

    final visibility = ArkSpeciesColorRegions.visibilityFor(dino.espece);
    return List.generate(6, (i) {
      if (hasSolid) return firstId;
      final active = i < visibility.length ? visibility[i] : true;
      return active ? firstId : baseIds[i];
    });
  }
}

class _ColorSquare extends StatelessWidget {
  final Color? color;
  final int colorId;
  final bool isFilled;

  const _ColorSquare({
    required this.color,
    required this.colorId,
    required this.isFilled,
  });

  bool _isLight(Color c) => c.computeLuminance() > 0.5;

  @override
  Widget build(BuildContext context) {
    const double radius = 6.0;

    // ─── Case vide : carré gris uni ──────────────────────────────────────
    if (!isFilled) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF6B6B6B),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
      );
    }

    // ─── Couleur posée : carré coloré + ID adaptatif centré ──────────────
    final fill = color!;
    final textColor = _isLight(fill) ? Colors.black87 : Colors.white;
    final shadowColor = _isLight(fill)
        ? Colors.white.withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.8);

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: fill.withValues(alpha: 0.55),
            blurRadius: 3,
          ),
        ],
      ),
      // Center + FittedBox + height:1.0 → chiffre PARFAITEMENT centré
      // et qui s'adapte à la taille du carré (1, 2 ou 3 chiffres).
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$colorId',
              textAlign: TextAlign.center,
              style: GoogleFonts.exo2(
                color: textColor,
                fontSize: 22, // base élevée → FittedBox réduit selon la case
                fontWeight: FontWeight.w900,
                height: 1.0, // ← clé : supprime la descente du baseline
                letterSpacing: 0,
                decoration: TextDecoration.none,
                shadows: [
                  Shadow(color: shadowColor, blurRadius: 1.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
