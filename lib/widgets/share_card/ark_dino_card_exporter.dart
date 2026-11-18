// lib/widgets/share_card/ark_dino_card_exporter.dart
import 'dart:ui' as ui;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import '../../models/dino.dart';
import '../../models/role_theme.dart';
import '../../utils/save_image_helper.dart';
import '../../theme/app_theme.dart';
import '../ark_dino_card.dart';

/// Exporte une [ArkDinoCard] en PNG haute résolution (1080×1908 par défaut)
/// puis sauvegarde dans la galerie via [SaveImageHelper].
class ArkDinoCardExporter {
  final Dino       dino;
  final RoleTheme? roleTheme;

  /// Largeur logique de la carte (référentiel design 242 px).
  static const double _logicalW = 242.0;
  /// Hauteur logique de la carte (référentiel design 428 px).
  static const double _logicalH = 428.0;

  /// Largeur PNG exportée (modifiable si besoin).
  static const double exportWidth = 1080.0;

  ArkDinoCardExporter({
    required this.dino,
    this.roleTheme,
  });

  /// Pixel ratio nécessaire pour atteindre [exportWidth] px de large
  /// à partir du référentiel logique 242 px → ≈ 4.46.
  static const double _pixelRatio = exportWidth / _logicalW;

  Future<void> captureAndSave(BuildContext context) async {
    final repaintKey = GlobalKey();
    OverlayEntry? entry;

    try {
      entry = OverlayEntry(
        builder: (_) => Positioned(
          // Hors écran à gauche pour ne pas être visible pendant le rendu.
          left: -_logicalW * 3,
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
                  // On force la taille logique : ArkDinoCard est en AspectRatio
                  // 242/428 → un SizedBox de cette taille la rend pile.
                  child: SizedBox(
                    width:  _logicalW,
                    height: _logicalH,
                    child: ArkDinoCard(
                      dino:      dino,
                      roleTheme: roleTheme,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // ignore: use_build_context_synchronously
      Overlay.of(context).insert(entry);

      // Laisse le temps aux Image.asset / Image.file de se charger
      // (sinon le PNG sort sans le fond ou sans le dino).
      await Future.delayed(const Duration(milliseconds: 500));
      await WidgetsBinding.instance.endOfFrame;
      await Future.delayed(const Duration(milliseconds: 300));

      final ctx = repaintKey.currentContext;
      if (ctx == null) throw Exception('Context null après rendu');

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('RenderRepaintBoundary introuvable');
      }

      // Capture à pixelRatio ≈ 4.46 → image finale 1080×1908 px.
      final image    = await boundary.toImage(pixelRatio: _pixelRatio);
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
