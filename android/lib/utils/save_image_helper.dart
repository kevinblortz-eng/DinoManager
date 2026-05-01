// lib/utils/save_image_helper.dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_theme.dart';

class SaveImageHelper {

  /// Demande les permissions nécessaires selon la version Android
  static Future<bool> requestPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      // Android 13+ : READ_MEDIA_IMAGES
      // Android 10-12 : READ/WRITE_EXTERNAL_STORAGE
      final androidInfo = await _getAndroidVersion();

      PermissionStatus status;
      if (androidInfo >= 33) {
        status = await Permission.photos.request();
      } else {
        status = await Permission.storage.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          _showPermissionDialog(context);
        }
        return false;
      }

      return status.isGranted;
    }
    // iOS : pas de permission nécessaire pour Documents
    return true;
  }

  /// Retourne la version Android SDK
  static Future<int> _getAndroidVersion() async {
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse(result.stdout.toString().trim()) ?? 30;
    } catch (_) {
      return 30;
    }
  }

  /// Dossier de sauvegarde : Pictures/DinoManager
  static Future<Directory> getSaveDirectory() async {
    Directory baseDir;

    if (Platform.isAndroid) {
      final extDirs = await getExternalStorageDirectories(
        type: StorageDirectory.pictures,
      );
      if (extDirs != null && extDirs.isNotEmpty) {
        // Remonte de Android/data/.../files/Pictures → Pictures
        final rawPath = extDirs.first.path;
        final cleanPath = rawPath.replaceAll(
          RegExp(r'Android/data/.*'),
          'Pictures',
        );
        baseDir = Directory(cleanPath);
      } else {
        baseDir = await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final dinoDir = Directory('${baseDir.path}/DinoManager');
    if (!await dinoDir.exists()) {
      await dinoDir.create(recursive: true);
    }
    return dinoDir;
  }

  /// Génère un nom de fichier : Espece-Nom-IDXYZ.png
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

  /// Sauvegarde les bytes PNG et affiche la notification
  static Future<void> saveAndNotify({
    required BuildContext context,
    required List<int> pngBytes,
    required String fileName,
    required String displayName,
  }) async {
    // Demande permission
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
                    'Permission refusée — autorise l\'accès au stockage dans les paramètres',
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

    final saveDir = await getSaveDirectory();
    final savedFile = File('${saveDir.path}/$fileName');
    await savedFile.writeAsBytes(pngBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$displayName sauvegardé !',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '📁 Pictures/DinoManager/$fileName',
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
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  /// Dialog si permission permanentement refusée
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
          'DinoManager a besoin d\'accéder à tes photos pour sauvegarder les DinoCards.\n\nVa dans Paramètres → Applications → DinoManager → Autorisations.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text('Ouvrir les paramètres',
                style: TextStyle(color: AppTheme.accentPrimary)),
          ),
        ],
      ),
    );
  }
}
