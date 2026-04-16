// lib/services/dino_scan_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ark_color_palette.dart';
import '../theme/app_theme.dart';
import 'dino_ocr_service.dart';

/// Classe utilitaire pour lancer un scan OCR depuis n'importe quel écran.
/// Retourne un DinoOcrResult ou null si annulé/échoué.
class DinoScanHelper {
  DinoScanHelper._();

  /// Affiche le bottom sheet caméra/galerie, scanne, et retourne le résultat.
  /// Retourne null si l'utilisateur annule ou si aucune donnée n'est détectée.
  static Future<DinoOcrResult?> launchScan(BuildContext context) async {
    final source = await _showSourcePicker(context);
    if (source == null) return null;
    if (!context.mounted) return null;

    return _scanFromSource(context, source);
  }

  /// Affiche le picker caméra / galerie
  static Future<ImageSource?> _showSourcePicker(BuildContext context) async {
    return showModalBottomSheet<ImageSource>(
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

  static Widget _sourceButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required ImageSource source,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
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

  /// Prend la photo / sélectionne l'image, lance l'OCR, retourne le résultat
  static Future<DinoOcrResult?> _scanFromSource(
      BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 95,
    );

    if (photo == null) return null;
    if (!context.mounted) return null;

    // Loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          color: AppTheme.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF00E5FF)),
                const SizedBox(height: 16),
                Text('Analyse en cours...',
                    style:
                        GoogleFonts.exo2(color: Colors.white, fontSize: 14)),
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

      if (!context.mounted) return null;
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
        return null;
      }

      return result;
    } catch (e) {
      if (!context.mounted) return null;
      Navigator.pop(context); // Fermer le loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de scan: $e'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return null;
    }
  }

  /// Convertit un color ID ARK en hex
  static String getColorHex(int id) {
    if (id <= 0) return '#808080';
    try {
      final entry = ArkColorPalette.allColors
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (c) => c?['id'] == id,
            orElse: () => null,
          );
      return (entry?['hex'] as String?) ?? '#808080';
    } catch (_) {
      return '#808080';
    }
  }
}
