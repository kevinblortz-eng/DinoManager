// lib/widgets/share_card/dino_share_card_portrait_exporter.dart

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../models/dino.dart';
import '../../utils/save_image_helper.dart';
import '../../theme/app_theme.dart';
import 'dino_share_card_portrait.dart';

class DinoShareCardPortraitExporter {
  final Dino  dino;
  final Color themeColor;

  DinoShareCardPortraitExporter({
    required this.dino,
    required this.themeColor,
  });

  Future<void> captureAndSave(BuildContext context) async {
    final repaintKey = GlobalKey();
    OverlayEntry? entry;

    // Récupérer le pixel ratio réel du device AVANT tout await
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    try {
      entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -DinoShareCardPortrait.cardW * 2,
          top:  0,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: const MediaQueryData(
                textScaler:       TextScaler.noScaling,
                padding:          EdgeInsets.zero,
                viewInsets:       EdgeInsets.zero,
                viewPadding:      EdgeInsets.zero,
                devicePixelRatio: 1.0,
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  decoration: TextDecoration.none,
                  height:     1.0,
                ),
                child: RepaintBoundary(
                  key: repaintKey,
                  child: DinoShareCardPortrait(
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

      await Future.delayed(const Duration(milliseconds: 400));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 200));

      final ctx = repaintKey.currentContext;
      if (ctx == null) throw Exception('Context null après rendu');

      // ignore: use_build_context_synchronously
      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('RenderRepaintBoundary introuvable');

      // Capturer avec le pixel ratio réel → image nette sur Android
      final image    = await boundary.toImage(pixelRatio: devicePixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Erreur génération PNG');

      if (!context.mounted) return;

      await SaveImageHelper.saveAndNotify(
        context:     context,
        pngBytes:    byteData.buffer.asUint8List(),
        fileName:    SaveImageHelper.generateFileName(dino.espece, dino.nom),
        displayName: '${dino.espece} — ${dino.nom}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Erreur export: $e'),
          backgroundColor: AppTheme.danger,
        ));
      }
    } finally {
      entry?.remove();
    }
  }
}
