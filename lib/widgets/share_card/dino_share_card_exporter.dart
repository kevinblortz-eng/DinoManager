import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import '../../models/dino.dart';
import '../../utils/save_image_helper.dart';
import '../../theme/app_theme.dart';
import 'dino_share_card.dart';

class DinoShareCardExporter {
  final Dino  dino;
  final Color themeColor;

  DinoShareCardExporter({
    required this.dino,
    required this.themeColor,
  });

  Future<void> captureAndSave(BuildContext context) async {
    final repaintKey = GlobalKey();
    OverlayEntry? entry;

    // Récupérer le pixel ratio réel du device AVANT tout await
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    try {
      // ── 1. Insérer le widget hors-écran dans l'Overlay ─────────
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -DinoShareCard.cardW * 2,
          top:  0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              // Force rendu propre sans influence du device
              // devicePixelRatio: 1.0 ici car la carte est en taille logique fixe
              // Le pixelRatio réel est appliqué à la capture toImage()
              data: const MediaQueryData(
                textScaler:       TextScaler.noScaling,
                padding:          EdgeInsets.zero,
                viewInsets:       EdgeInsets.zero,
                viewPadding:      EdgeInsets.zero,
                devicePixelRatio: 1.0,
              ),
              child: DefaultTextStyle(
                // Reset style hérité de l'app
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  height:     1.0,
                ),
                child: RepaintBoundary(
                  key: repaintKey,
                  child: DinoShareCard(
                    dino:       dino,
                    themeColor: themeColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // ignore: use_build_context_synchronously
      Overlay.of(context).insert(entry);

      // ── 2. Attendre le rendu complet ───────────────────────────
      await Future.delayed(const Duration(milliseconds: 400));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      final ctx = repaintKey.currentContext;
      if (ctx == null) throw Exception('Context null après rendu');

      // ignore: use_build_context_synchronously
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary introuvable');
      }

      // ── 3. Capturer avec le pixel ratio réel du device ────────
      // pixelRatio: 1.0 donnait une image basse résolution sur Android
      // On utilise le ratio réel pour une capture nette (2.0, 2.75, 3.0…)
      final image = await boundary.toImage(pixelRatio: devicePixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Erreur génération PNG');

      if (!context.mounted) return;

      // ── 4. Sauvegarder ─────────────────────────────────────────
      await SaveImageHelper.saveAndNotify(
        context:     context,
        pngBytes:    byteData.buffer.asUint8List(),
        fileName:    SaveImageHelper.generateFileName(dino.espece, dino.nom),
        displayName: '${dino.espece} — ${dino.nom}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:         Text('Erreur export: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      // ── 5. Toujours retirer l'Overlay ──────────────────────────
      entry?.remove();
    }
  }
}
