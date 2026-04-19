// lib/services/dino_scan_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ark_color_palette.dart';
import '../screens/dino_scan_screen.dart';
import 'dino_ocr_service.dart';

/// Point d'entrée unique pour le scan depuis n'importe quel écran.
/// Ouvre [DinoScanScreen] en mode caméra ou galerie et retourne [DinoOcrResult].
class DinoScanHelper {
  static final ImagePicker _picker = ImagePicker();

  // ── Caméra live avec overlay ─────────────────────────────────────────────
  static Future<DinoOcrResult?> scanWithCamera(BuildContext context) async {
    return Navigator.push<DinoOcrResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const DinoScanScreen(mode: ScanMode.camera),
        fullscreenDialog: true,
      ),
    );
  }

  // ── Galerie : image picker + écran de recadrage ──────────────────────────
  static Future<DinoOcrResult?> scanFromGallery(BuildContext context) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );
    if (picked == null || !context.mounted) return null;

    return Navigator.push<DinoOcrResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const DinoScanScreen(mode: ScanMode.gallery),
        fullscreenDialog: true,
        settings: RouteSettings(arguments: File(picked.path)),
      ),
    );
  }

  // ── Méthode unifiée : affiche le choix caméra/galerie ────────────────────
  static Future<DinoOcrResult?> launchScan(BuildContext context) async {
    final source = await _showSourceDialog(context);
    if (source == null || !context.mounted) return null;

    if (source == 'camera') {
      return scanWithCamera(context);
    } else {
      return scanFromGallery(context);
    }
  }

  // ── Retourne le hex d'une couleur ARK par son ID ─────────────────────────
  /// Utilisé par add_edit_dino_screen et la vue de résultat de scan.
  /// Retourne '#808080' si l'ID est inconnu ou nul.
  static String getColorHex(int colorId) {
    if (colorId <= 0) return '#808080';
    final entry = ArkColorPalette.allColors
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (c) => c?['id'] == colorId,
          orElse: () => null,
        );
    return (entry?['hex'] as String?) ?? '#808080';
  }

  // ── Dialogue de sélection de source ──────────────────────────────────────
  static Future<String?> _showSourceDialog(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1E28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Scanner les stats ARK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Utilisez la caméra ou une capture d\'écran existante',
                style: TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _srcBtn(
                      ctx,
                      'camera',
                      Icons.camera_alt_rounded,
                      'CAMÉRA',
                      'Photo de l\'écran',
                      const Color(0xFF00E5FF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _srcBtn(
                      ctx,
                      'gallery',
                      Icons.photo_library_rounded,
                      'GALERIE',
                      'Screenshot existant',
                      const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _srcBtn(
    BuildContext ctx,
    String value,
    IconData icon,
    String label,
    String sub,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(ctx, value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  color: color.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
