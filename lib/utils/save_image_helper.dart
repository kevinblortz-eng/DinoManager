// lib/utils/save_image_helper.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../theme/app_theme.dart';

class SaveImageHelper {

  // ════════════════════════════════════════════════════════════════════════
  // ANDROID SDK VERSION — via device_info_plus (Process.run ne marche pas)
  // ════════════════════════════════════════════════════════════════════════

  static Future<int> _getAndroidSdk() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return info.version.sdkInt;
    } catch (_) {
      return 30;
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ════════════════════════════════════════════════════════════════════════

  static Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdk();

      if (sdk >= 29) {
        // Android 10+ : saver_gallery utilise MediaStore, pas besoin de
        // permission WRITE. READ_MEDIA_IMAGES uniquement si skipIfExists=true.
        // On laisse saver_gallery gérer.
        return true;
      } else {
        // Android < 10 : WRITE_EXTERNAL_STORAGE requis
        final status = await Permission.storage.request();
        if (status.isPermanentlyDenied && context.mounted) {
          _showPermissionDialog(context);
          return false;
        }
        return status.isGranted;
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (status.isPermanentlyDenied && context.mounted) {
        _showPermissionDialog(context);
        return false;
      }
      return status.isGranted;
    }

    return false;
  }

  // ════════════════════════════════════════════════════════════════════════
  // NOM DE FICHIER
  // ════════════════════════════════════════════════════════════════════════

  static String generateFileName(String espece, String nom) {
    final especeClean = espece
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w]'), '');
    final nomClean = nom
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w]'), '');
    final random = Random().nextInt(900) + 100;
    return '$especeClean-$nomClean-ID$random.png';
  }

  // ════════════════════════════════════════════════════════════════════════
  // SAUVEGARDE PRINCIPALE
  // ════════════════════════════════════════════════════════════════════════

  static Future<void> saveAndNotify({
    required BuildContext context,
    required List<int> pngBytes,
    required String fileName,
    required String displayName,
  }) async {
    // ── 1. Permission ───────────────────────────────────────────────────
    final hasPermission = await requestPermissions(context);
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permission refusée — autorise l\'accès aux photos '
                    'dans les paramètres',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

  // ── 2. Conversion en Uint8List ──────────────────────────────────────────
final Uint8List bytes =
    pngBytes is Uint8List
        ? pngBytes
        : Uint8List.fromList(pngBytes);

// ── 3. Sauvegarde via saver_gallery ────────────────────────────────────
bool success = false;
try {
  final result = await SaverGallery.saveImage(
    bytes,
    quality: 100,
    extension: 'png',
    fileName: fileName,
    androidRelativePath: 'Pictures/DinoManager',
    skipIfExists: false,
  );
  success = result.isSuccess;
} catch (e) {
  success = false;
  debugPrint('SaverGallery error: $e');
}

    // ── 4. Feedback ─────────────────────────────────────────────────────
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    success
                        ? '$displayName sauvegardé !'
                        : 'Échec sauvegarde — réessaie',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (success)
                    Text(
                      '📁 Galerie › Pictures › DinoManager',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: success ? AppTheme.success : AppTheme.danger,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // DIALOG PERMISSION PERMANENTE
  // ════════════════════════════════════════════════════════════════════════

  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Permission requise',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'DinoManager a besoin d\'accéder à tes photos pour sauvegarder '
          'les DinoCards.\n\n'
          'Va dans Paramètres → Applications → DinoManager → Autorisations.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white38),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(
              'Ouvrir les paramètres',
              style: TextStyle(color: AppTheme.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
