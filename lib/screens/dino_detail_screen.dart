// lib/screens/dino_detail_screen.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import '../providers/dino_provider.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/common/dino_stat_grid.dart';
import '../widgets/common/dino_color_strip.dart';
import '../widgets/dino_multi_select_bottom_sheet.dart';
import '../utils/dino_helpers.dart';
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

  /// Clé pour capturer la carte en PNG
  final GlobalKey _cardRepaintKey = GlobalKey();

  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _dino = widget.dino;
  }

  // ─────────────── CAPTURE PNG ───────────────

    Future<void> _captureAndShare() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      // ── Dimensions cibles ──
      const double targetWidth = 1080;
      const double targetHeight = 1350;

      // ── Construire le widget carte à la taille exacte, hors écran ──
      final widget = MediaQuery(
        data: const MediaQueryData(
          size: Size(targetWidth, targetHeight),
          devicePixelRatio: 1.0,
          padding: EdgeInsets.zero,
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: Scaffold(
            backgroundColor: const Color(0xFF0A0E1A),
            body: Center(
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildExportCard(),
                ),
              ),
            ),
          ),
        ),
      );

      // ── Rendre hors écran avec un pipeline custom ──
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
        debugShortDescription: 'DinoCardExport',
        child: widget,
      ).attachToRenderTree(buildOwner);

      buildOwner.buildScope(rootElement);
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();

      // ── Capturer en PNG ──
      final image = await repaintBoundary.toImage(
        pixelRatio: 1.0, // Déjà à 1080x1350
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Nettoyer
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

      // ── Sauvegarder et partager ──
      final tempDir = await getTemporaryDirectory();
      final fileName =
          '${_dino.espece.replaceAll(' ', '_')}_${_dino.nom.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${_dino.espece} — ${_dino.nom} (Lvl ${_dino.niveau}) #DinoManager',
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

  // ─────────────── BUILD ───────────────
  /// Carte optimisée pour l'export PNG 1080x1350
  Widget _buildExportCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: _dino.roleColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: -3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // ── Image (environ 40% de la hauteur) ──
            Expanded(
              flex: 40,
              child: _buildExportVisualSection(),
            ),
            // ── Titre ──
            _buildExportTitleSection(),
            // ── Stats ──
            Expanded(
              flex: 30,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: DinoStatGrid(dino: _dino),
              ),
            ),
            // ── Couleurs ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: DinoColorStrip(dino: _dino),
            ),
            // ── Watermark ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                border: const Border(
                  top: BorderSide(color: Color(0xFF5A5A5A), width: 1),
                ),
              ),
              child: Text(
                'DINO MANAGER',
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                  color: Colors.white.withOpacity(0.3),
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
    final hasCustomImage = _dino.image != null && _dino.image!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            _dino.roleColor.withOpacity(0.25),
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
          // Badge niveau
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau)
                        .withOpacity(0.5),
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
          // Badge sexe
          if (_dino.sexe != 'Inconnu')
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.85),
                  shape: BoxShape.circle,
                  border: Border.all(color: _dino.sexeColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: _dino.sexeColor.withOpacity(0.5),
                        blurRadius: 10)
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  _dino.sexeSymbol,
                  style: TextStyle(
                      color: _dino.sexeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.5), Colors.transparent],
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
                shadows: [
                  const Shadow(
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: _dino.roleColor.withOpacity(0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _dino.nom,
                    style: GoogleFonts.exo2(
                      color: Colors.white.withOpacity(0.9),
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
                    color: _dino.roleColor.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _dino.roleColor, width: 1),
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border:
                Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          // ── Bouton capture / partage ──
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF00E5FF).withOpacity(0.4),
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
                  : const Icon(Icons.share_rounded,
                      color: Color(0xFF00E5FF)),
              tooltip: 'Partager la DinoCard',
              onPressed: _isCapturing ? null : _captureAndShare,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          child: Column(
            children: [
              // ── La carte encapsulée dans RepaintBoundary ──
              RepaintBoundary(
                key: _cardRepaintKey,
                child: _buildArkCard(),
              ),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ARK CARD
  // ═══════════════════════════════════════════════

  Widget _buildArkCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5A5A5A), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _dino.roleColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildVisualSection(),
          _buildTitleSection(),
          DinoStatGrid(dino: _dino),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DinoColorStrip(dino: _dino),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildVisualSection() {
    final hasCustomImage = _dino.image != null && _dino.image!.isNotEmpty;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            _dino.roleColor.withOpacity(0.2),
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
              padding: const EdgeInsets.all(20),
              child: Hero(
                tag: 'dino_${_dino.id}',
                child: hasCustomImage
                    ? Image.file(
                        File(_dino.image!),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _buildSpeciesImage(),
                      )
                    : _buildSpeciesImage(),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: DinoHelpers.getCardRarityColor(_dino.niveau)
                        .withOpacity(0.5),
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
          if (_dino.sexe != 'Inconnu')
            Positioned(
              top: 16,
              right: 16,
              child: _buildSexBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildSexBadge() {
    final isBoth = _dino.sexe.contains('Mâle+Femelle');

    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
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
        color: Colors.black.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: _dino.sexeColor, width: 2),
        boxShadow: [
          BoxShadow(
              color: _dino.sexeColor.withOpacity(0.5), blurRadius: 8)
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _dino.roleColor.withOpacity(0.2), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: DinoImageWidget(
        species: _dino.espece,
        regionColors: _dino.colorRegions,
        width: double.infinity,
        height: 280,
        fit: BoxFit.contain,
        showColorBand: false,
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                shadows: [
                  const Shadow(
                      color: Colors.black,
                      blurRadius: 6,
                      offset: Offset(2, 2))
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _dino.roleColor.withOpacity(0.6), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _dino.nom,
                    style: GoogleFonts.exo2(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
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
                    color: _dino.roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _dino.roleColor, width: 1),
                  ),
                  child: Text(
                    _dino.role.toUpperCase(),
                    style: TextStyle(
                      color: _dino.roleColor,
                      fontSize: 10,
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
  // BOUTONS D'ACTION
  // ═══════════════════════════════════════════════

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
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
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
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
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.6), width: 2),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4)),
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
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════

  Future<void> _editDino() async {
    final updated = await Navigator.push<Dino>(
      context,
      MaterialPageRoute(builder: (_) => AddEditDinoScreen(dino: _dino)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

    if (confirm == true && mounted) {
      if (_dino.id != null) {
        await Provider.of<DinoProvider>(context, listen: false)
            .deleteDino(_dino.id!);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _viewVariants() async {
    final provider = Provider.of<DinoProvider>(context, listen: false);
    final sameSpecies =
        provider.dinos.where((dino) => dino.espece == _dino.espece).toList();

    if (sameSpecies.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Aucun autre dinosaure de cette espèce trouvé'),
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
        preSelectedDinos: const [],
      ),
    );

    if (selectedDinos != null && selectedDinos.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DinoVariantsScreen(
            baseDino: _dino,
            selectedVariants: selectedDinos,
          ),
        ),
      );
    }
  }
}
