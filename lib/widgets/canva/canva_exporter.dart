// lib/widgets/canva/canva_exporter.dart
//
// ╔════════════════════════════════════════════════════════════════════════╗
// ║ EXPORTEUR PNG DU CANVA                                                ║
// ║                                                                        ║
// ║ Génère un PNG 1080×1350 à partir d'un widget Canva fourni, en :       ║
// ║   1. Précachant et décodant explicitement toutes les images dinos     ║
// ║      (FileImage + AssetImage), pour éviter les bulles "noires".       ║
// ║   2. Construisant un render-tree offscreen avec un RepaintBoundary.   ║
// ║   3. Exécutant N passes de build/layout/paint (N adaptatif selon le   ║
// ║      nombre d'images) pour laisser le décodage interne se finir.      ║
// ║   4. Capturant en PNG via toImage().                                  ║
// ║   5. Sauvegardant via SaveImageHelper.                                ║
// ║                                                                        ║
// ║ API publique : CanvaExporter.capture(...)                             ║
// ║                CanvaExporter.precacheImages(...)                      ║
// ║                CanvaExporter.generateFileName(...)                    ║
// ╚════════════════════════════════════════════════════════════════════════╝
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import '../../models/dino.dart';
import '../../utils/save_image_helper.dart';

/// Dimensions standard d'un export 4:5 (Instagram-ready).
const double kCanvaExportWidth = 1080;
const double kCanvaExportHeight = 1350;

/// Mois utilisés pour générer un nom de fichier lisible.
const List<String> _moisFr = [
  'JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUN',
  'JUL', 'AOU', 'SEP', 'OCT', 'NOV', 'DEC',
];

class CanvaExporter {
  CanvaExporter._();

  // ───────────────────────────────────────────────────────────────────
  //  API PUBLIQUE
  // ───────────────────────────────────────────────────────────────────

  /// Capture le widget [canvasBuilder] en PNG 1080×1350 et le sauvegarde.
  ///
  /// - [context] : BuildContext courant (utilisé pour precache + View.of).
  /// - [dinos] : liste des dinos affichés (pour décoder leurs images).
  /// - [canvasBuilder] : fonction qui retourne le widget Canva à exporter,
  ///   appelée avec `exportScale=2.5` pour adapter typographies/badges.
  /// - [fileName] : nom du fichier (sans extension).
  /// - [displayName] : nom affiché dans la notification système.
  ///
  /// Retourne `true` si la sauvegarde a réussi, `false` sinon (toast déjà
  /// affiché en cas d'erreur).
  static Future<bool> capture({
    required BuildContext context,
    required List<Dino> dinos,
    required Widget Function(double exportScale) canvasBuilder,
    required String fileName,
    required String displayName,
  }) async {
    try {
      // 1. Précache de toutes les images dinos
      await precacheImages(context: context, dinos: dinos);

      // 2. Construction du widget d'export
      final exportWidget = Directionality(
        textDirection: TextDirection.ltr,
        child: Theme(
          data: ThemeData.dark(),
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(kCanvaExportWidth, kCanvaExportHeight),
              devicePixelRatio: 1.0,
              padding: EdgeInsets.zero,
            ),
            child: SizedBox(
              width: kCanvaExportWidth,
              height: kCanvaExportHeight,
              child: canvasBuilder(2.5),
            ),
          ),
        ),
      );

      // 3. Montage offscreen
      final repaintBoundary = RenderRepaintBoundary();
      final renderView = RenderView(
        view: View.of(context),
        child: RenderPositionedBox(
          alignment: Alignment.center,
          child: repaintBoundary,
        ),
        configuration: ViewConfiguration(
          logicalConstraints: const BoxConstraints(
            maxWidth: kCanvaExportWidth,
            maxHeight: kCanvaExportHeight,
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
        debugShortDescription: 'DinoCanvaExport',
        child: exportWidget,
      ).attachToRenderTree(buildOwner);

      // 4. Passes adaptatives selon nb d'images
      //    (l'ImageCache offscreen est isolé → décodage interne nécessite
      //    plusieurs passes avant que toImage() retourne une frame complète)
      final imageCount = dinos.length;
      final passes = imageCount <= 4 ? 3 : (imageCount <= 8 ? 5 : 8);
      final delayMs = imageCount <= 4 ? 80 : 120;

      for (int i = 0; i < passes; i++) {
        buildOwner.buildScope(rootElement);
        pipelineOwner.flushLayout();
        pipelineOwner.flushCompositingBits();
        pipelineOwner.flushPaint();
        await Future.delayed(Duration(milliseconds: delayMs));
      }

      // 5. Capture PNG
      final image = await repaintBoundary.toImage(pixelRatio: 1.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      buildOwner.finalizeTree();

      if (byteData == null) {
        if (context.mounted) {
          _showError(context, 'Erreur lors de la génération de l\'image');
        }
        return false;
      }
      if (!context.mounted) return false;

      // 6. Sauvegarde + notif système
      await SaveImageHelper.saveAndNotify(
        context: context,
        pngBytes: byteData.buffer.asUint8List(),
        fileName: fileName,
        displayName: displayName,
      );
      return true;
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Erreur: $e');
      }
      return false;
    }
  }

  /// Force le décodage en mémoire de toutes les images des dinos.
  ///
  /// Pour chaque dino, précache :
  ///   - son image personnalisée (FileImage) si présente,
  ///   - son asset de fallback (AssetImage) basé sur l'espèce.
  ///
  /// Garantit qu'aucune image ne sera "noire" à la capture offscreen.
  static Future<void> precacheImages({
    required BuildContext context,
    required List<Dino> dinos,
  }) async {
    final futures = <Future<void>>[];

    for (final d in dinos) {
      // Image personnalisée
      if (d.image != null && d.image!.isNotEmpty) {
        final file = File(d.image!);
        if (file.existsSync()) {
          final provider = FileImage(file);
          if (context.mounted) {
            futures.add(precacheImage(provider, context));
          }
          futures.add(_decodeImage(provider));
        }
      }
      // Asset de fallback
      final assetPath =
          'assets/images/dinos/${d.espece.replaceAll(' ', '_')}_ASA.png';
      final assetProvider = AssetImage(assetPath);
      if (context.mounted) {
        futures.add(precacheImage(assetProvider, context).catchError((_) {}));
      }
      futures.add(_decodeImage(assetProvider));
    }

    await Future.wait(futures);

    // Laisse 2 frames passer pour stabiliser le pipeline image
    await SchedulerBinding.instance.endOfFrame;
    await SchedulerBinding.instance.endOfFrame;
  }

  /// Génère un nom de fichier lisible : `Canva_<PREFIX>_<DDMMMYYHHMMSS>`
  ///
  /// Exemple : `Canva_REX_17MAI26143052`
  static String generateFileName(String prefix) {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = _moisFr[now.month - 1];
    final y = (now.year % 100).toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final sp = prefix.replaceAll(' ', '_').toUpperCase();
    return 'Canva_${sp}_$d$m$y$hh$mm$ss';
  }

  // ───────────────────────────────────────────────────────────────────
  //  HELPERS PRIVÉS
  // ───────────────────────────────────────────────────────────────────

  /// Décode explicitement une image (asset ou file) et retourne un Future
  /// qui complète quand l'image est prête à être peinte. Timeout 5s.
  static Future<void> _decodeImage(ImageProvider provider) {
    final completer = Completer<void>();
    final stream = provider.resolve(const ImageConfiguration());
    late ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
      onError: (error, stack) {
        if (!completer.isCompleted) completer.complete();
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}
