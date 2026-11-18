import 'package:material_ui/material_ui.dart';
import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../theme/app_theme.dart';

/// Widget d'affichage d'un dino avec sa silhouette stylisée
/// et les régions de couleur superposées (comme ARK Smart Breeding)
class DinoAvatarWidget extends StatelessWidget {
  final Dino dino;
  final double size;
  final bool showColorRegions;

  const DinoAvatarWidget({
    super.key,
    required this.dino,
    this.size = 120,
    this.showColorRegions = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.7,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fond avec gradient de la couleur dominante
          _buildBackground(),
          // Silhouette du dino (CustomPainter)
          CustomPaint(
            size: Size(size, size * 0.7),
            painter: DinoSilhouettePainter(dino: dino),
          ),
          // Indicateur d'espèce en bas à droite
          Positioned(
            bottom: 2,
            right: 4,
            child: _buildEspeceLabel(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    // Le fond utilise les 2 couleurs dominantes du dino (couleur0 + couleur3)
    final c0 = dino.colorRegion0;
    final c3 = dino.colorRegion3;
    return Container(
      width: size,
      height: size * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c0.withValues(alpha: 0.3),
            c3.withValues(alpha: 0.15),
            AppTheme.bgCard.withValues(alpha: 0.0),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildEspeceLabel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.bgPrimary.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        dino.especeEmoji,
        style: TextStyle(fontSize: size * 0.12),
      ),
    );
  }
}

/// Painter personnalisé pour dessiner la silhouette selon l'espèce
class DinoSilhouettePainter extends CustomPainter {
  final Dino dino;

  DinoSilhouettePainter({required this.dino});

  @override
  void paint(Canvas canvas, Size size) {
    // Sélectionne et dessine la silhouette selon l'espèce
    switch (dino.espece.toLowerCase()) {
      case 'rex':
      case 'giganotosaurus':
        _drawRex(canvas, size, dino);
        break;
      case 'raptor':
        _drawRaptor(canvas, size, dino);
        break;
      case 'wyvern':
        _drawWyvern(canvas, size, dino);
        break;
      case 'argentavis':
      case 'ptero':
      case 'quetzal':
        _drawFlyer(canvas, size, dino);
        break;
      case 'ankylosaurus':
        _drawAnky(canvas, size, dino);
        break;
      case 'triceratops':
        _drawTriceratops(canvas, size, dino);
        break;
      case 'spino':
        _drawSpino(canvas, size, dino);
        break;
      default:
        _drawGenericDino(canvas, size, dino);
        break;
    }
  }

  Paint _paintForRegion(Color color, {double opacity = 0.9}) {
    return Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
  }

  Paint _outlinePaint(Color color) {
    return Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
  }

  // ─── Rex / Giganotosaurus ───
  void _drawRex(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    // Corps principal (région 0)
    final bodyPath = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.8, h * 0.15, w * 0.85, h * 0.35)
      ..cubicTo(w * 0.9, h * 0.55, w * 0.75, h * 0.65, w * 0.6, h * 0.65)
      ..lineTo(w * 0.55, h * 0.8)
      ..lineTo(w * 0.45, h * 0.85)
      ..lineTo(w * 0.35, h * 0.8)
      ..lineTo(w * 0.3, h * 0.65)
      ..cubicTo(w * 0.15, h * 0.65, w * 0.1, h * 0.5, w * 0.2, h * 0.4)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    // Tête (région 1)
    final headPath = Path()
      ..moveTo(w * 0.62, h * 0.15)
      ..cubicTo(w * 0.75, h * 0.05, w * 0.92, h * 0.08, w * 0.95, h * 0.2)
      ..cubicTo(w * 0.98, h * 0.32, w * 0.9, h * 0.38, w * 0.82, h * 0.35)
      ..cubicTo(w * 0.72, h * 0.32, w * 0.62, h * 0.28, w * 0.62, h * 0.15)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion1));
    canvas.drawPath(headPath, _outlinePaint(d.colorRegion1));

    // Dos / crête (région 2)
    final spinePath = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..cubicTo(w * 0.45, h * 0.2, w * 0.55, h * 0.18, w * 0.62, h * 0.25)
      ..cubicTo(w * 0.5, h * 0.28, w * 0.38, h * 0.3, w * 0.3, h * 0.35)
      ..close();
    canvas.drawPath(spinePath, _paintForRegion(d.colorRegion2));

    // Ventre (région 3)
    final bellyPath = Path()
      ..moveTo(w * 0.25, h * 0.5)
      ..cubicTo(w * 0.35, h * 0.45, w * 0.55, h * 0.42, w * 0.65, h * 0.48)
      ..cubicTo(w * 0.6, h * 0.62, w * 0.4, h * 0.65, w * 0.25, h * 0.58)
      ..close();
    canvas.drawPath(bellyPath, _paintForRegion(d.colorRegion3, opacity: 0.7));

    // Pattes (région 4)
    _drawLimb(canvas, Offset(w * 0.35, h * 0.65), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.52, h * 0.65), w * 0.08, h * 0.22, d.colorRegion4);

    // Queue (région 5)
    final tailPath = Path()
      ..moveTo(w * 0.28, h * 0.55)
      ..cubicTo(w * 0.1, h * 0.5, w * 0.05, h * 0.55, w * 0.02, h * 0.65)
      ..cubicTo(w * 0.05, h * 0.68, w * 0.15, h * 0.65, w * 0.25, h * 0.6)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion5));

    // Œil
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.2),
      w * 0.025,
      Paint()..color = Colors.red.shade900,
    );
    canvas.drawCircle(
      Offset(w * 0.86, h * 0.2),
      w * 0.012,
      Paint()..color = Colors.black,
    );
  }

  // ─── Raptor ───
  void _drawRaptor(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    // Corps (région 0)
    final bodyPath = Path()
      ..moveTo(w * 0.35, h * 0.25)
      ..cubicTo(w * 0.5, h * 0.1, w * 0.75, h * 0.12, w * 0.8, h * 0.3)
      ..cubicTo(w * 0.85, h * 0.45, w * 0.7, h * 0.58, w * 0.55, h * 0.58)
      ..lineTo(w * 0.5, h * 0.78)
      ..lineTo(w * 0.38, h * 0.82)
      ..lineTo(w * 0.3, h * 0.75)
      ..lineTo(w * 0.32, h * 0.6)
      ..cubicTo(w * 0.18, h * 0.55, w * 0.15, h * 0.4, w * 0.25, h * 0.32)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    // Tête allongée (région 1)
    final headPath = Path()
      ..moveTo(w * 0.62, h * 0.12)
      ..cubicTo(w * 0.78, h * 0.02, w * 0.95, h * 0.08, w * 0.96, h * 0.2)
      ..cubicTo(w * 0.97, h * 0.3, w * 0.85, h * 0.35, w * 0.75, h * 0.32)
      ..cubicTo(w * 0.65, h * 0.28, w * 0.6, h * 0.22, w * 0.62, h * 0.12)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion1));
    canvas.drawPath(headPath, _outlinePaint(d.colorRegion1));

    // Crête de plumes (région 2)
    for (int i = 0; i < 4; i++) {
      final featherPath = Path()
        ..moveTo(w * (0.38 + i * 0.07), h * 0.22)
        ..cubicTo(
          w * (0.38 + i * 0.07 + 0.02), h * 0.08,
          w * (0.38 + i * 0.07 + 0.04), h * 0.06,
          w * (0.38 + i * 0.07 + 0.03), h * 0.18,
        )
        ..close();
      canvas.drawPath(featherPath, _paintForRegion(d.colorRegion2));
    }

    // Ventre (région 3)
    final bellyPath = Path()
      ..moveTo(w * 0.28, h * 0.45)
      ..cubicTo(w * 0.4, h * 0.38, w * 0.58, h * 0.38, w * 0.65, h * 0.48)
      ..cubicTo(w * 0.6, h * 0.58, w * 0.35, h * 0.6, w * 0.28, h * 0.52)
      ..close();
    canvas.drawPath(bellyPath, _paintForRegion(d.colorRegion3, opacity: 0.65));

    // Pattes (région 4)
    _drawLimb(canvas, Offset(w * 0.35, h * 0.6), w * 0.07, h * 0.25, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.48, h * 0.6), w * 0.07, h * 0.25, d.colorRegion4);

    // Queue longue (région 5)
    final tailPath = Path()
      ..moveTo(w * 0.3, h * 0.45)
      ..cubicTo(w * 0.12, h * 0.38, w * 0.04, h * 0.42, w * 0.01, h * 0.5)
      ..cubicTo(w * 0.04, h * 0.58, w * 0.18, h * 0.58, w * 0.28, h * 0.52)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion5));

    // Œil
    canvas.drawCircle(Offset(w * 0.89, h * 0.18), w * 0.022, Paint()..color = Colors.amber.shade800);
    canvas.drawCircle(Offset(w * 0.89, h * 0.18), w * 0.01, Paint()..color = Colors.black);
  }

  // ─── Wyvern ───
  void _drawWyvern(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    // Corps central (région 0)
    final bodyPath = Path()
      ..moveTo(w * 0.45, h * 0.3)
      ..cubicTo(w * 0.55, h * 0.15, w * 0.75, h * 0.2, w * 0.78, h * 0.4)
      ..cubicTo(w * 0.8, h * 0.55, w * 0.68, h * 0.65, w * 0.55, h * 0.62)
      ..cubicTo(w * 0.42, h * 0.65, w * 0.35, h * 0.58, w * 0.38, h * 0.45)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));

    // Aile gauche grande (région 1)
    final wingLeftPath = Path()
      ..moveTo(w * 0.45, h * 0.35)
      ..cubicTo(w * 0.3, h * 0.1, w * 0.05, h * 0.05, w * 0.02, h * 0.28)
      ..cubicTo(w * 0.0, h * 0.45, w * 0.18, h * 0.58, w * 0.38, h * 0.5)
      ..close();
    canvas.drawPath(wingLeftPath, _paintForRegion(d.colorRegion1, opacity: 0.85));
    canvas.drawPath(wingLeftPath, _outlinePaint(d.colorRegion1));

    // Aile droite (région 1 miroir)
    final wingRightPath = Path()
      ..moveTo(w * 0.78, h * 0.35)
      ..cubicTo(w * 0.92, h * 0.1, w * 0.98, h * 0.08, w * 0.99, h * 0.28)
      ..cubicTo(w * 1.0, h * 0.45, w * 0.88, h * 0.56, w * 0.78, h * 0.5)
      ..close();
    canvas.drawPath(wingRightPath, _paintForRegion(d.colorRegion1, opacity: 0.85));
    canvas.drawPath(wingRightPath, _outlinePaint(d.colorRegion1));

    // Membranes alaires (région 2)
    _drawWingMembrane(canvas, w, h, d.colorRegion2);

    // Tête (région 3)
    final headPath = Path()
      ..moveTo(w * 0.7, h * 0.18)
      ..cubicTo(w * 0.82, h * 0.08, w * 0.96, h * 0.12, w * 0.97, h * 0.26)
      ..cubicTo(w * 0.96, h * 0.38, w * 0.85, h * 0.42, w * 0.76, h * 0.38)
      ..cubicTo(w * 0.67, h * 0.32, w * 0.65, h * 0.25, w * 0.7, h * 0.18)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion3));

    // Queue avec pointe (région 4)
    final tailPath = Path()
      ..moveTo(w * 0.42, h * 0.55)
      ..cubicTo(w * 0.28, h * 0.62, w * 0.12, h * 0.7, w * 0.05, h * 0.88)
      ..cubicTo(w * 0.08, h * 0.9, w * 0.12, h * 0.85, w * 0.2, h * 0.78)
      ..cubicTo(w * 0.3, h * 0.7, w * 0.42, h * 0.65, w * 0.48, h * 0.6)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion4));

    // Cornes (région 5)
    _drawHorns(canvas, w, h, d.colorRegion5);

    // Œil
    canvas.drawCircle(Offset(w * 0.9, h * 0.24), w * 0.028, Paint()..color = Colors.deepOrange);
    canvas.drawCircle(Offset(w * 0.9, h * 0.24), w * 0.012, Paint()..color = Colors.black);
  }

  // ─── Oiseau volant (Argentavis/Ptero/Quetzal) ───
  void _drawFlyer(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    final bodyPath = Path()
      ..moveTo(w * 0.5, h * 0.35)
      ..cubicTo(w * 0.6, h * 0.2, w * 0.72, h * 0.22, w * 0.75, h * 0.38)
      ..cubicTo(w * 0.76, h * 0.52, w * 0.62, h * 0.6, w * 0.5, h * 0.58)
      ..cubicTo(w * 0.38, h * 0.6, w * 0.26, h * 0.5, w * 0.28, h * 0.38)
      ..cubicTo(w * 0.3, h * 0.25, w * 0.42, h * 0.2, w * 0.5, h * 0.35)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));

    final wingLeft = Path()
      ..moveTo(w * 0.3, h * 0.42)
      ..cubicTo(w * 0.15, h * 0.15, w * 0.02, h * 0.1, w * 0.0, h * 0.35)
      ..cubicTo(w * 0.0, h * 0.55, w * 0.18, h * 0.62, w * 0.3, h * 0.52)
      ..close();
    canvas.drawPath(wingLeft, _paintForRegion(d.colorRegion1, opacity: 0.88));

    final wingRight = Path()
      ..moveTo(w * 0.72, h * 0.42)
      ..cubicTo(w * 0.88, h * 0.15, w * 0.99, h * 0.1, w * 1.0, h * 0.35)
      ..cubicTo(w * 1.0, h * 0.55, w * 0.85, h * 0.62, w * 0.72, h * 0.52)
      ..close();
    canvas.drawPath(wingRight, _paintForRegion(d.colorRegion1, opacity: 0.88));

    final headPath = Path()
      ..moveTo(w * 0.65, h * 0.22)
      ..cubicTo(w * 0.75, h * 0.08, w * 0.92, h * 0.1, w * 0.94, h * 0.25)
      ..cubicTo(w * 0.95, h * 0.38, w * 0.82, h * 0.42, w * 0.72, h * 0.38)
      ..cubicTo(w * 0.65, h * 0.34, w * 0.62, h * 0.28, w * 0.65, h * 0.22)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion2));

    final tailPath = Path()
      ..moveTo(w * 0.3, h * 0.5)
      ..cubicTo(w * 0.15, h * 0.6, w * 0.08, h * 0.75, w * 0.1, h * 0.88)
      ..lineTo(w * 0.2, h * 0.88)
      ..cubicTo(w * 0.22, h * 0.72, w * 0.3, h * 0.62, w * 0.38, h * 0.55)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion4));

    canvas.drawCircle(Offset(w * 0.87, h * 0.22), w * 0.022, Paint()..color = Colors.amber);
    canvas.drawCircle(Offset(w * 0.87, h * 0.22), w * 0.01, Paint()..color = Colors.black);
  }

  // ─── Ankylosaurus ───
  void _drawAnky(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    final bodyPath = Path()
      ..moveTo(w * 0.15, h * 0.4)
      ..cubicTo(w * 0.18, h * 0.2, w * 0.5, h * 0.12, w * 0.82, h * 0.2)
      ..cubicTo(w * 0.95, h * 0.28, w * 0.98, h * 0.5, w * 0.88, h * 0.6)
      ..cubicTo(w * 0.72, h * 0.75, w * 0.28, h * 0.75, w * 0.12, h * 0.6)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    // Plaques osseuses
    for (int i = 0; i < 6; i++) {
      final plateRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * (0.2 + i * 0.12), h * 0.24),
          width: w * 0.09,
          height: h * 0.14,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(plateRect, _paintForRegion(d.colorRegion2, opacity: 0.8));
      canvas.drawRRect(plateRect, _outlinePaint(d.colorRegion2));
    }

    // Épines (région 1)
    for (int i = 0; i < 5; i++) {
      final spinePath = Path()
        ..moveTo(w * (0.22 + i * 0.14), h * 0.2)
        ..lineTo(w * (0.19 + i * 0.14), h * 0.08)
        ..lineTo(w * (0.25 + i * 0.14), h * 0.08)
        ..close();
      canvas.drawPath(spinePath, _paintForRegion(d.colorRegion1));
    }

    // Tête (région 3)
    final headPath = Path()
      ..moveTo(w * 0.78, h * 0.28)
      ..cubicTo(w * 0.9, h * 0.2, w * 0.98, h * 0.3, w * 0.97, h * 0.45)
      ..cubicTo(w * 0.95, h * 0.55, w * 0.85, h * 0.58, w * 0.78, h * 0.52)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion3));

    // Masse caudale (région 4)
    final clubPath = Path()
      ..moveTo(w * 0.12, h * 0.52)
      ..cubicTo(w * 0.02, h * 0.48, w * 0.0, h * 0.55, w * 0.02, h * 0.62)
      ..cubicTo(w * 0.05, h * 0.7, w * 0.12, h * 0.68, w * 0.15, h * 0.6)
      ..close();
    canvas.drawPath(clubPath, _paintForRegion(d.colorRegion4));

    // Pattes
    _drawLimb(canvas, Offset(w * 0.25, h * 0.65), w * 0.07, h * 0.2, d.colorRegion5);
    _drawLimb(canvas, Offset(w * 0.4, h * 0.65), w * 0.07, h * 0.2, d.colorRegion5);
    _drawLimb(canvas, Offset(w * 0.6, h * 0.65), w * 0.07, h * 0.2, d.colorRegion5);
    _drawLimb(canvas, Offset(w * 0.75, h * 0.65), w * 0.07, h * 0.2, d.colorRegion5);

    canvas.drawCircle(Offset(w * 0.91, h * 0.35), w * 0.022, Paint()..color = Colors.amber.shade800);
    canvas.drawCircle(Offset(w * 0.91, h * 0.35), w * 0.01, Paint()..color = Colors.black);
  }

  // ─── Triceratops ───
  void _drawTriceratops(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    final bodyPath = Path()
      ..moveTo(w * 0.2, h * 0.35)
      ..cubicTo(w * 0.22, h * 0.18, w * 0.55, h * 0.12, w * 0.78, h * 0.22)
      ..cubicTo(w * 0.88, h * 0.3, w * 0.9, h * 0.52, w * 0.78, h * 0.62)
      ..cubicTo(w * 0.6, h * 0.74, w * 0.3, h * 0.74, w * 0.18, h * 0.62)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    // Collerette (région 1)
    final frillPath = Path()
      ..moveTo(w * 0.72, h * 0.18)
      ..cubicTo(w * 0.82, h * 0.02, w * 0.98, h * 0.05, w * 1.0, h * 0.22)
      ..cubicTo(w * 0.99, h * 0.38, w * 0.88, h * 0.44, w * 0.78, h * 0.38)
      ..cubicTo(w * 0.7, h * 0.32, w * 0.68, h * 0.24, w * 0.72, h * 0.18)
      ..close();
    canvas.drawPath(frillPath, _paintForRegion(d.colorRegion1));
    canvas.drawPath(frillPath, _outlinePaint(d.colorRegion1));

    // Tête (région 2)
    final headPath = Path()
      ..moveTo(w * 0.68, h * 0.25)
      ..cubicTo(w * 0.78, h * 0.15, w * 0.9, h * 0.2, w * 0.92, h * 0.35)
      ..cubicTo(w * 0.92, h * 0.48, w * 0.82, h * 0.52, w * 0.72, h * 0.48)
      ..cubicTo(w * 0.64, h * 0.42, w * 0.64, h * 0.3, w * 0.68, h * 0.25)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion2));

    // Cornes (région 3)
    _drawHornTri(canvas, Offset(w * 0.82, h * 0.18), w * 0.04, h * 0.14, -0.2, d.colorRegion3);
    _drawHornTri(canvas, Offset(w * 0.9, h * 0.2), w * 0.035, h * 0.1, 0.2, d.colorRegion3);
    _drawHornTri(canvas, Offset(w * 0.82, h * 0.38), w * 0.03, h * 0.08, 0.0, d.colorRegion3);

    // Pattes
    _drawLimb(canvas, Offset(w * 0.28, h * 0.64), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.42, h * 0.64), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.58, h * 0.64), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.7, h * 0.64), w * 0.08, h * 0.22, d.colorRegion4);

    // Queue (région 5)
    final tailPath = Path()
      ..moveTo(w * 0.2, h * 0.52)
      ..cubicTo(w * 0.08, h * 0.48, w * 0.02, h * 0.55, w * 0.02, h * 0.62)
      ..cubicTo(w * 0.04, h * 0.68, w * 0.14, h * 0.65, w * 0.2, h * 0.58)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion5));

    canvas.drawCircle(Offset(w * 0.87, h * 0.32), w * 0.022, Paint()..color = Colors.amber.shade700);
    canvas.drawCircle(Offset(w * 0.87, h * 0.32), w * 0.01, Paint()..color = Colors.black);
  }

  // ─── Spino ───
  void _drawSpino(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    // Corps (région 0)
    final bodyPath = Path()
      ..moveTo(w * 0.28, h * 0.35)
      ..cubicTo(w * 0.42, h * 0.15, w * 0.72, h * 0.18, w * 0.8, h * 0.38)
      ..cubicTo(w * 0.85, h * 0.55, w * 0.72, h * 0.68, w * 0.55, h * 0.66)
      ..lineTo(w * 0.5, h * 0.82)
      ..lineTo(w * 0.38, h * 0.85)
      ..lineTo(w * 0.3, h * 0.78)
      ..lineTo(w * 0.28, h * 0.65)
      ..cubicTo(w * 0.12, h * 0.62, w * 0.1, h * 0.48, w * 0.2, h * 0.4)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    // Voile dorsale (région 1) - caractéristique du Spino
    final sailPath = Path()
      ..moveTo(w * 0.3, h * 0.3)
      ..cubicTo(w * 0.35, h * 0.02, w * 0.42, h * 0.0, w * 0.5, h * 0.0)
      ..cubicTo(w * 0.58, h * 0.0, w * 0.65, h * 0.02, w * 0.7, h * 0.28)
      ..cubicTo(w * 0.6, h * 0.25, w * 0.42, h * 0.22, w * 0.3, h * 0.3)
      ..close();
    canvas.drawPath(sailPath, _paintForRegion(d.colorRegion1, opacity: 0.88));
    canvas.drawPath(sailPath, _outlinePaint(d.colorRegion1));

    // Nervures de la voile (région 2)
    for (int i = 0; i < 4; i++) {
      final nervurePath = Path()
        ..moveTo(w * (0.35 + i * 0.1), h * 0.26)
        ..cubicTo(
          w * (0.35 + i * 0.1), h * 0.12,
          w * (0.36 + i * 0.1), h * 0.04,
          w * (0.38 + i * 0.1), h * 0.02,
        );
      canvas.drawPath(
        nervurePath,
        Paint()
          ..color = d.colorRegion2.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Tête de croco (région 3)
    final headPath = Path()
      ..moveTo(w * 0.65, h * 0.2)
      ..cubicTo(w * 0.78, h * 0.08, w * 0.96, h * 0.12, w * 0.98, h * 0.28)
      ..cubicTo(w * 0.98, h * 0.4, w * 0.86, h * 0.44, w * 0.75, h * 0.4)
      ..cubicTo(w * 0.66, h * 0.36, w * 0.62, h * 0.28, w * 0.65, h * 0.2)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion3));
    canvas.drawPath(headPath, _outlinePaint(d.colorRegion3));

    // Pattes (région 4)
    _drawLimb(canvas, Offset(w * 0.32, h * 0.66), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.48, h * 0.66), w * 0.08, h * 0.22, d.colorRegion4);

    // Queue (région 5)
    final tailPath = Path()
      ..moveTo(w * 0.26, h * 0.55)
      ..cubicTo(w * 0.1, h * 0.5, w * 0.04, h * 0.55, w * 0.02, h * 0.65)
      ..cubicTo(w * 0.04, h * 0.7, w * 0.14, h * 0.68, w * 0.24, h * 0.62)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion5));

    canvas.drawCircle(Offset(w * 0.91, h * 0.22), w * 0.026, Paint()..color = Colors.teal.shade600);
    canvas.drawCircle(Offset(w * 0.91, h * 0.22), w * 0.012, Paint()..color = Colors.black);
  }

  // ─── Dino générique (pour toutes les autres espèces) ───
  void _drawGenericDino(Canvas canvas, Size s, Dino d) {
    final w = s.width;
    final h = s.height;

    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.35)
      ..cubicTo(w * 0.3, h * 0.15, w * 0.65, h * 0.1, w * 0.8, h * 0.28)
      ..cubicTo(w * 0.9, h * 0.45, w * 0.78, h * 0.65, w * 0.58, h * 0.65)
      ..lineTo(w * 0.52, h * 0.8)
      ..lineTo(w * 0.42, h * 0.85)
      ..lineTo(w * 0.35, h * 0.78)
      ..lineTo(w * 0.3, h * 0.65)
      ..cubicTo(w * 0.12, h * 0.62, w * 0.1, h * 0.48, w * 0.18, h * 0.4)
      ..close();
    canvas.drawPath(bodyPath, _paintForRegion(d.colorRegion0));
    canvas.drawPath(bodyPath, _outlinePaint(d.colorRegion0));

    final headPath = Path()
      ..moveTo(w * 0.65, h * 0.15)
      ..cubicTo(w * 0.78, h * 0.05, w * 0.95, h * 0.1, w * 0.96, h * 0.26)
      ..cubicTo(w * 0.96, h * 0.38, w * 0.84, h * 0.42, w * 0.75, h * 0.38)
      ..cubicTo(w * 0.66, h * 0.32, w * 0.62, h * 0.22, w * 0.65, h * 0.15)
      ..close();
    canvas.drawPath(headPath, _paintForRegion(d.colorRegion1));
    canvas.drawPath(headPath, _outlinePaint(d.colorRegion1));

    final bellyPath = Path()
      ..moveTo(w * 0.22, h * 0.48)
      ..cubicTo(w * 0.35, h * 0.42, w * 0.58, h * 0.42, w * 0.68, h * 0.5)
      ..cubicTo(w * 0.62, h * 0.62, w * 0.35, h * 0.64, w * 0.22, h * 0.56)
      ..close();
    canvas.drawPath(bellyPath, _paintForRegion(d.colorRegion3, opacity: 0.65));

    _drawLimb(canvas, Offset(w * 0.32, h * 0.65), w * 0.08, h * 0.22, d.colorRegion4);
    _drawLimb(canvas, Offset(w * 0.48, h * 0.65), w * 0.08, h * 0.22, d.colorRegion4);

    final tailPath = Path()
      ..moveTo(w * 0.24, h * 0.52)
      ..cubicTo(w * 0.08, h * 0.45, w * 0.02, h * 0.52, w * 0.02, h * 0.62)
      ..cubicTo(w * 0.05, h * 0.68, w * 0.16, h * 0.65, w * 0.24, h * 0.58)
      ..close();
    canvas.drawPath(tailPath, _paintForRegion(d.colorRegion5));

    canvas.drawCircle(Offset(w * 0.89, h * 0.2), w * 0.024, Paint()..color = Colors.amber.shade700);
    canvas.drawCircle(Offset(w * 0.89, h * 0.2), w * 0.01, Paint()..color = Colors.black);
  }

  // ─── Helpers ───
  void _drawLimb(Canvas canvas, Offset top, double w, double h, Color color) {
    final path = Path()
      ..moveTo(top.dx - w / 2, top.dy)
      ..cubicTo(
        top.dx - w / 2, top.dy + h * 0.5,
        top.dx + w / 2, top.dy + h * 0.5,
        top.dx + w / 2, top.dy,
      )
      ..cubicTo(
        top.dx + w / 2 + 2, top.dy + h,
        top.dx - w / 2 - 2, top.dy + h,
        top.dx - w / 2, top.dy,
      )
      ..close();
    canvas.drawPath(path, _paintForRegion(color));
    canvas.drawPath(path, _outlinePaint(color));
  }

  void _drawHorns(Canvas canvas, double w, double h, Color color) {
    final horn1 = Path()
      ..moveTo(w * 0.82, h * 0.12)
      ..lineTo(w * 0.78, h * 0.0)
      ..lineTo(w * 0.86, h * 0.05)
      ..close();
    canvas.drawPath(horn1, _paintForRegion(color));

    final horn2 = Path()
      ..moveTo(w * 0.92, h * 0.1)
      ..lineTo(w * 0.9, h * 0.0)
      ..lineTo(w * 0.96, h * 0.04)
      ..close();
    canvas.drawPath(horn2, _paintForRegion(color));
  }

  void _drawHornTri(Canvas canvas, Offset base, double w, double h, double angle, Color color) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle);
    final horn = Path()
      ..moveTo(-w / 2, 0)
      ..lineTo(0, -h)
      ..lineTo(w / 2, 0)
      ..close();
    canvas.drawPath(horn, _paintForRegion(color));
    canvas.restore();
  }

  void _drawWingMembrane(Canvas canvas, double w, double h, Color color) {
    final membrane = Path()
      ..moveTo(w * 0.45, h * 0.38)
      ..cubicTo(w * 0.35, h * 0.42, w * 0.22, h * 0.5, w * 0.12, h * 0.6)
      ..lineTo(w * 0.18, h * 0.65)
      ..cubicTo(w * 0.28, h * 0.56, w * 0.4, h * 0.5, w * 0.48, h * 0.52)
      ..close();
    canvas.drawPath(membrane, _paintForRegion(color, opacity: 0.5));
  }

  @override
  bool shouldRepaint(DinoSilhouettePainter oldDelegate) {
    return oldDelegate.dino != dino;
  }
}

/// Widget compact pour afficher les pastilles de couleurs régionales
class ColorRegionsBar extends StatelessWidget {
  final Dino dino;
  final double dotSize;
  final bool showLabels;

  const ColorRegionsBar({
    super.key,
    required this.dino,
    this.dotSize = 18,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(6, (i) {
        final color = dino.allRegionColors[i];
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Tooltip(
            message: 'Région $i',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (showLabels) ...[
                  const SizedBox(height: 2),
                  Text(
                    'R$i',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Widget grand format pour la fiche détaillée - affiche les couleurs ARK avec IDs
class DinoRegionColorGrid extends StatelessWidget {
  final Dino dino;

  const DinoRegionColorGrid({super.key, required this.dino});

  static const List<String> _regionNames = [
    'Corps', 'Tête / Crête', 'Dos / Nervures',
    'Ventre', 'Pattes', 'Queue / Ext.',
  ];

  @override
  Widget build(BuildContext context) {
    final colorIds = dino.colorIds;
    final colorHexes = [
      dino.colorHex0, dino.colorHex1, dino.colorHex2,
      dino.colorHex3, dino.colorHex4, dino.colorHex5,
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.8,
      ),
      itemCount: 6,
      itemBuilder: (context, i) {
        final color = dino.allRegionColors[i];
        final arkId = colorIds[i];
        final hex = colorHexes[i];
        final arkColor = arkId > 0 ? ArkColorPalette.fromId(arkId) : null;
        final isLight = (color.r * 0.299 + color.g * 0.587 + color.b * 0.114) > 0.5;

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgSecondary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              // Bloc couleur avec ID ARK
              Container(
                width: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(9),
                    bottomLeft: Radius.circular(9),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    arkId > 0 ? '$arkId' : '?',
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'R$i — ${_regionNames[i]}',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        arkColor?.name ?? hex,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      if (arkId > 0)
                        Text(
                          hex.toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 8,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Barre de stat (HP, Stamina, etc.) avec points investis
class StatBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String? displayValue;
  final int? points; // Points investis (niveaux sauvages/domestiqués)

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    this.displayValue,
    this.points,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSecondary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.borderColor, width: 0.5),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withValues(alpha: 0.7), color],
                      ),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Valeur principale
          SizedBox(
            width: 56,
            child: Text(
              displayValue ?? value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1),
              textAlign: TextAlign.right,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Points investis (badge)
          if (points != null && points! > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Text(
                '+$points',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else
            const SizedBox(width: 32),
        ],
      ),
    );
  }
}

/// Icône de dino par espèce (emoji large)
Widget buildDinoIcon(String espece, {double size = 48}) {
  final emojis = {
    'rex': '🦖', 'giganotosaurus': '🦖', 'spino': '🦕',
    'raptor': '🦕', 'wyvern': '🐉', 'quetzal': '🦜',
    'ptero': '🦅', 'argentavis': '🦅', 'megalodon': '🦈',
    'ankylosaurus': '🪨', 'triceratops': '🦏', 'mammoth': '🦣',
    'ovis': '🐑', 'equus': '🐴', 'sarco': '🐊',
  };
  final emoji = emojis[espece.toLowerCase()] ?? '🦕';
  return Text(emoji, style: TextStyle(fontSize: size));
}

/// Calcul de luminance pour déterminer si un texte doit être noir ou blanc
bool isLightColor(Color color) {
  final luminance = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
  return luminance > 0.5;
}
