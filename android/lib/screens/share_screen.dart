// lib/screens/share_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../providers/dino_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../widgets/common/dino_color_strip.dart';
import '../utils/dino_helpers.dart';
import '../utils/save_image_helper.dart';

class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key});

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  bool _isExporting = false;
  String? _lastSavedPath;
  final GlobalKey _exportKey = GlobalKey();

  // ═══════════════════════════════════════════════
  // SAUVEGARDE
  // ═══════════════════════════════════════════════

  Future<void> _saveDino(Dino dino) async {
    if (_isExporting) return;
    setState(() {
      _isExporting = true;
      _lastSavedPath = null;
    });

    try {
      final imageBytes = await _renderDinoCard(dino);
      if (imageBytes == null) {
        _showError('Erreur lors de la génération de l\'image');
        return;
      }

      final fileName = SaveImageHelper.generateFileName(dino.espece, dino.nom);

      await SaveImageHelper.saveAndNotify(
        context: context,
        pngBytes: imageBytes,
        fileName: fileName,
        displayName: '${dino.espece} — ${dino.nom}',
      );

      if (mounted) {
        final saveDir = await SaveImageHelper.getSaveDirectory();
        setState(() => _lastSavedPath = '${saveDir.path}/$fileName');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<List<int>?> _renderDinoCard(Dino dino) async {
    const double targetWidth  = 1080;
    const double targetHeight = 1350;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => Positioned(
        left:  -targetWidth  * 2,
        top:   -targetHeight * 2,
        width:  targetWidth,
        height: targetHeight,
        child: RepaintBoundary(
          key: _exportKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData.dark(),
            home: Scaffold(
              backgroundColor: const Color(0xFF0A0E1A),
              body: SizedBox(
                width:  targetWidth,
                height: targetHeight,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildExportCard(dino),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);

    // Attendre que Flutter rende le widget hors-écran
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      final boundary = _exportKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        _showError('Erreur : widget non rendu');
        return null;
      }

      final image    = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      _showError('Erreur rendu : $e');
      return null;
    } finally {
      entry.remove();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // EXPORT CARD 1080x1350
  // ═══════════════════════════════════════════════

  Widget _buildExportCard(Dino dino) {
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
            color: dino.roleColor.withValues(alpha: 0.4),
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
              flex: 40,
              child: _buildExportVisual(dino),
            ),
            _buildExportTitle(dino),
            Expanded(
              flex: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: DinoStatGrid(dino: dino),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DinoColorStrip(dino: dino),
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

  Widget _buildExportVisual(Dino dino) {
    final hasCustomImage = dino.image != null && dino.image!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            dino.roleColor.withValues(alpha: 0.25),
            const Color(0xFF0F1115),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF5A5A5A), width: 2),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: hasCustomImage
                  ? Image.file(
                      File(dino.image!),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => DinoImageWidget(
                        species: dino.espece,
                        regionColors: dino.colorRegions,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        showColorBand: false,
                      ),
                    )
                  : DinoImageWidget(
                      species: dino.espece,
                      regionColors: dino.colorRegions,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      showColorBand: false,
                    ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DinoHelpers.getCardRarityColor(dino.niveau),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DinoHelpers.getCardRarityColor(dino.niveau)
                        .withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Text(
                'LVL ${dino.niveau}',
                style: GoogleFonts.exo2(
                  color: DinoHelpers.getCardRarityColor(dino.niveau),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (dino.sexe != 'Inconnu')
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: dino.sexeColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: dino.sexeColor.withValues(alpha: 0.5),
                        blurRadius: 10)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  dino.sexeSymbol,
                  style: TextStyle(
                      color: dino.sexeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportTitle(Dino dino) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.5),
            Colors.transparent
          ],
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
              DinoHelpers.toTitleCase(dino.espece),
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                shadows: const [
                  Shadow(
                      color: Colors.black,
                      blurRadius: 8,
                      offset: Offset(2, 2))
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: dino.roleColor.withValues(alpha: 0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    dino.nom,
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
                    color: dino.roleColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: dino.roleColor, width: 1),
                  ),
                  child: Text(
                    dino.role.toUpperCase(),
                    style: TextStyle(
                      color: dino.roleColor,
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
  // BUILD UI
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDinoGrid(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.save_alt_rounded,
                  color: Color(0xFF4CAF50), size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde DinoCards',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Sélectionnez un dino pour sauvegarder sa DinoCard',
                    style: TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_lastSavedPath != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle,
                    color: AppTheme.success, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dernière sauvegarde : ${_lastSavedPath!.split('/').last}',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDinoGrid(BuildContext context) {
    return Consumer<DinoProvider>(
      builder: (context, provider, _) {
        if (provider.dinos.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.pets_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                      size: 60),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun dino enregistré',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SÉLECTIONNEZ UN DINO',
                  style: TextStyle(
                    color: AppTheme.accentSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${provider.dinos.length} dinos',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.dinos.length,
              itemBuilder: (ctx, i) {
                final dino = provider.dinos[i];
                return _buildDinoRow(dino);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDinoRow(Dino dino) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: dino.roleColor.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.bgPrimary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: dino.roleColor.withValues(alpha: 0.3),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: DinoImageWidget(
                  species: dino.espece,
                  regionColors: dino.colorRegions,
                  width: 50,
                  height: 50,
                  fit: BoxFit.contain,
                  showColorBand: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dino.nom.isEmpty ? dino.espece : dino.nom,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        dino.espece,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              dino.roleColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: dino.roleColor
                                  .withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'Lvl ${dino.niveau}',
                          style: TextStyle(
                            color: dino.roleColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _actionIcon(
              icon: Icons.save_alt_rounded,
              color: const Color(0xFF4CAF50),
              tooltip: 'Sauvegarder la DinoCard',
              onTap: _isExporting ? null : () => _saveDino(dino),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                color.withValues(alpha: onTap != null ? 0.4 : 0.1),
          ),
        ),
        child: _isExporting
            ? Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: color,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, color: color, size: 18),
      ),
    );
  }
}
