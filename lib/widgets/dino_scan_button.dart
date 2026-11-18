// lib/widgets/dino_scan_button.dart
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ark_color_palette.dart';
import '../services/dino_ocr_service.dart';
import '../screens/add_edit_dino_screen.dart';
import '../theme/app_theme.dart';

class DinoScanButton extends StatelessWidget {
  const DinoScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSourcePicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00E5FF).withValues(alpha: 0.2),
                const Color(0xFF00E5FF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.document_scanner_rounded,
                  color: Color(0xFF00E5FF), size: 24),
              const SizedBox(width: 10),
              Text(
                'SCANNER CRYOPOD / TEK',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF00E5FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barre de tirage
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Scanner un dinosaure',
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photographiez le tooltip d\'un cryopod ou l\'écran des jumelles Tek',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _sourceButton(
                      ctx,
                      icon: Icons.camera_alt_rounded,
                      label: 'CAMÉRA',
                      subtitle: 'Prendre une photo',
                      source: ImageSource.camera,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _sourceButton(
                      ctx,
                      icon: Icons.photo_library_rounded,
                      label: 'GALERIE',
                      subtitle: 'Screenshot existant',
                      source: ImageSource.gallery,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.white.withValues(alpha: 0.4),
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Les jumelles Tek donnent les meilleurs résultats car elles affichent les points par stat (wild|tame|mut)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _scanFromSource(context, source);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00E5FF), size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanFromSource(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 95,
    );

    if (photo == null) return;
    if (!context.mounted) return;

    // Loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          color: AppTheme.bgCard,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                    color: Color(0xFF00E5FF)),
                const SizedBox(height: 16),
                Text('Analyse en cours...',
                    style: GoogleFonts.exo2(
                        color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text('Détection automatique du format',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final ocrService = DinoOcrService();
      final result = await ocrService.scanImage(File(photo.path));

      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le loader

      if (!result.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Aucune donnée détectée. Essayez avec une image plus nette ou recadrée sur le tooltip.'),
            backgroundColor: AppTheme.warning,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      _showScanResult(context, result);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de scan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  void _showScanResult(BuildContext context, DinoOcrResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.sourceType == OcrSourceType.tekBinoculars
                  ? Icons.visibility
                  : Icons.ac_unit_rounded,
              color: const Color(0xFF00E5FF),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Résultat du scan',
                    style:
                        GoogleFonts.exo2(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    'Source: ${result.sourceType.label}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Infos principales
                _resultLine('Espèce', result.species ?? '?'),
                _resultLine('Niveau', '${result.level ?? '?'}'),
                _resultLine('Sexe', result.sex ?? '?'),
                if (result.status != null)
                  _resultLine('Statut', result.status!),
                const Divider(color: Colors.white24, height: 20),

                // Stats
                _statResultLine('HP', result.hp),
                _statResultLine('Stamina', result.stamina),
                _statResultLine('Oxygen', result.oxygen),
                _statResultLine('Food', result.food),
                _statResultLine('Weight', result.weight),
                _statResultLine('Melee', result.melee),
                _statResultLine('Speed', result.speed),
                if (result.torpor != null)
                  _statResultLine('Torpor', result.torpor),
                const Divider(color: Colors.white24, height: 20),

                // Couleurs
                _resultLine(
                  'Couleurs',
                  result.colorIds
                      .map((c) => c > 0 ? '$c' : '-')
                      .join(' | '),
                ),
                // Aperçu visuel des couleurs
                const SizedBox(height: 6),
                Row(
                  children: List.generate(6, (i) {
                    final id = result.colorIds[i];
                    final hex = id > 0
                        ? _getColorHex(id)
                        : '#333333';
                    return Expanded(
                      child: Container(
                        height: 24,
                        margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                        decoration: BoxDecoration(
                          color: _parseHex(hex),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: id > 0
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          id > 0 ? '$id' : '-',
                          style: TextStyle(
                            color: id > 0 ? Colors.white : Colors.white24,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            shadows: id > 0
                                ? [
                                    const Shadow(
                                        color: Colors.black, blurRadius: 3)
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),

                // Mutations
                if (result.mutationsMale != null ||
                    result.mutationsFemale != null)
                  _resultLine(
                    'Mutations',
                    '♂ ${result.mutationsMale ?? '?'}  ♀ ${result.mutationsFemale ?? '?'}',
                  ),

                // Imprint
                if (result.imprinter != null)
                  _resultLine(
                    'Imprint',
                    '${result.imprintPercent ?? '?'}% - ${result.imprinter}',
                  ),

                const SizedBox(height: 12),

                // Texte brut (debug)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'Texte brut OCR',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        result.rawText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              final dino = result.toDino();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddEditDinoScreen(dino: dino),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'CRÉER DINOCARD',
              style: GoogleFonts.exo2(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statResultLine(String label, OcrStat? stat) {
    if (stat == null) {
      return _resultLine(label, '—');
    }

    final value = stat.isPercent
        ? '${stat.maxValue?.toStringAsFixed(1) ?? '?'}%'
        : '${stat.maxValue?.round() ?? '?'}';

    final hasPoints = stat.wildPoints != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hasPoints) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color:
                        const Color(0xFF00E5FF).withValues(alpha: 0.3)),
              ),
              child: Text(
                stat.pointsDisplay,
                style: const TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getColorHex(int id) {
    try {
      final entry = ArkColorPalette.allColors.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id'] == id,
            orElse: () => null,
          );
      return (entry?['hex'] as String?) ?? '#808080';
    } catch (_) {
      return '#808080';
    }
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}
