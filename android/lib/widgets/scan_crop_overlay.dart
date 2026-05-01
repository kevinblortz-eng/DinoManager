// lib/widgets/scan_crop_overlay.dart
import 'package:flutter/material.dart';
import '../services/dino_ocr_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
/// Overlay de cadrage interactif dessiné sur le preview caméra ou une image.
/// - Zone semi-transparente sombre hors cadre
/// - Rectangle lumineux avec poignées de redimensionnement aux 4 coins
/// - Label contextuel selon le type de source attendu
// ─────────────────────────────────────────────────────────────────────────────
class ScanCropOverlay extends StatefulWidget {
  final Rect                cropRect;
  final ValueChanged<Rect>  onCropChanged;
  final OcrSourceType       expectedSource;
  final bool                showZoomHint;

  const ScanCropOverlay({
    super.key,
    required this.cropRect,
    required this.onCropChanged,
    this.expectedSource = OcrSourceType.unknown,
    this.showZoomHint   = true,
  });

  @override
  State<ScanCropOverlay> createState() => _ScanCropOverlayState();
}

class _ScanCropOverlayState extends State<ScanCropOverlay>
    with SingleTickerProviderStateMixin {

  // Rect de travail en coordonnées normalisées
  late Rect _rect;

  // Animation de pulsation du cadre
  late AnimationController _pulse;
  late Animation<double>   _pulseAnim;

  static const double _minW = 0.2;
  static const double _minH = 0.1;
  static const double _handleRadius = 18.0; // zone tactile poignée

  @override
  void initState() {
    super.initState();
    _rect = widget.cropRect;

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ScanCropOverlay old) {
    super.didUpdateWidget(old);
    if (old.cropRect != widget.cropRect) {
      _rect = widget.cropRect;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  // ── Détection de la poignée touchée ──────────────────────────────────────
  _Handle? _hitHandle(Offset local, Size size) {
    final Rect px = _toPixels(_rect, size);
    final corners = {
      _Handle.topLeft:     Offset(px.left,   px.top),
      _Handle.topRight:    Offset(px.right,  px.top),
      _Handle.bottomLeft:  Offset(px.left,   px.bottom),
      _Handle.bottomRight: Offset(px.right,  px.bottom),
      // Milieux des côtés
      _Handle.topCenter:   Offset(px.center.dx, px.top),
      _Handle.bottomCenter:Offset(px.center.dx, px.bottom),
      _Handle.leftCenter:  Offset(px.left,      px.center.dy),
      _Handle.rightCenter: Offset(px.right,     px.center.dy),
    };
    for (final e in corners.entries) {
      if ((local - e.value).distance <= _handleRadius) return e.key;
    }
    // Dragging du corps
    if (px.contains(local)) return _Handle.body;
    return null;
  }

  _Handle? _activeHandle;
  Offset?  _dragStart;
  Rect?    _rectAtDragStart;

  void _onPanStart(DragStartDetails d, Size size) {
    _activeHandle     = _hitHandle(d.localPosition, size);
    _dragStart        = d.localPosition;
    _rectAtDragStart  = _rect;
  }

  void _onPanUpdate(DragUpdateDetails d, Size size) {
    if (_activeHandle == null || _dragStart == null) return;

    final Offset delta = d.localPosition - _dragStart!;
    final double dx = delta.dx / size.width;
    final double dy = delta.dy / size.height;
    final Rect   r  = _rectAtDragStart!;

    Rect next;

    switch (_activeHandle!) {
      case _Handle.body:
        final double newL = (r.left + dx).clamp(0.0, 1.0 - r.width);
        final double newT = (r.top  + dy).clamp(0.0, 1.0 - r.height);
        next = Rect.fromLTWH(newL, newT, r.width, r.height);
        break;
      case _Handle.topLeft:
        next = _fromEdges(
          left:   (r.left  + dx).clamp(0.0, r.right  - _minW),
          top:    (r.top   + dy).clamp(0.0, r.bottom - _minH),
          right:  r.right,
          bottom: r.bottom,
        );
        break;
      case _Handle.topRight:
        next = _fromEdges(
          left:   r.left,
          top:    (r.top + dy).clamp(0.0, r.bottom - _minH),
          right:  (r.right + dx).clamp(r.left + _minW, 1.0),
          bottom: r.bottom,
        );
        break;
      case _Handle.bottomLeft:
        next = _fromEdges(
          left:   (r.left + dx).clamp(0.0, r.right - _minW),
          top:    r.top,
          right:  r.right,
          bottom: (r.bottom + dy).clamp(r.top + _minH, 1.0),
        );
        break;
      case _Handle.bottomRight:
        next = _fromEdges(
          left:   r.left,
          top:    r.top,
          right:  (r.right  + dx).clamp(r.left + _minW, 1.0),
          bottom: (r.bottom + dy).clamp(r.top  + _minH, 1.0),
        );
        break;
      case _Handle.topCenter:
        next = _fromEdges(
          left: r.left, right: r.right,
          top:    (r.top + dy).clamp(0.0, r.bottom - _minH),
          bottom: r.bottom,
        );
        break;
      case _Handle.bottomCenter:
        next = _fromEdges(
          left: r.left, right: r.right,
          top: r.top,
          bottom: (r.bottom + dy).clamp(r.top + _minH, 1.0),
        );
        break;
      case _Handle.leftCenter:
        next = _fromEdges(
          left:   (r.left + dx).clamp(0.0, r.right - _minW),
          top: r.top, right: r.right, bottom: r.bottom,
        );
        break;
      case _Handle.rightCenter:
        next = _fromEdges(
          left: r.left, top: r.top, bottom: r.bottom,
          right: (r.right + dx).clamp(r.left + _minW, 1.0),
        );
        break;
    }

    setState(() => _rect = next);
    widget.onCropChanged(next);
  }

  void _onPanEnd(DragEndDetails _) {
    _activeHandle = null;
    _dragStart    = null;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          onPanStart:  (d) => _onPanStart(d, size),
          onPanUpdate: (d) => _onPanUpdate(d, size),
          onPanEnd:    _onPanEnd,
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => CustomPaint(
              painter: _CropPainter(
                rect:      _rect,
                pulse:     _pulseAnim.value,
                sourceType: widget.expectedSource,
              ),
              child: _buildLabels(size),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabels(Size size) {
    final Rect px = _toPixels(_rect, size);
    final String hint = switch (widget.expectedSource) {
      OcrSourceType.tekBinoculars  => '⬟ Jumelles Tek — Cadrez la fenêtre de stats',
      OcrSourceType.cryopodTooltip => '❄ Cryopod — Cadrez l\'infobulle',
      _                            => '⊞ AUTO — Cadrez la zone de stats',
    };

    return Stack(
      children: [
        // Label en haut du cadre
        Positioned(
          left:  px.left,
          top:   px.top - 28,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              hint,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        // Dimensions en bas du cadre
        Positioned(
          left:  px.left,
          top:   px.bottom + 4,
          child: Text(
            '${(_rect.width * 100).toInt()}% × ${(_rect.height * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
            ),
          ),
        ),
        // Aide zoom (caméra seulement)
        if (widget.showZoomHint)
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 110,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '← → Déplacer\n↖ ↘ Redimensionner',
                style: TextStyle(color: Colors.white38, fontSize: 9),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Rect _toPixels(Rect norm, Size size) => Rect.fromLTWH(
        norm.left   * size.width,
        norm.top    * size.height,
        norm.width  * size.width,
        norm.height * size.height,
      );

  Rect _fromEdges(
      {required double left, required double top,
       required double right, required double bottom}) =>
      Rect.fromLTRB(
        left.clamp(0.0, 1.0),
        top.clamp(0.0, 1.0),
        right.clamp(0.0, 1.0),
        bottom.clamp(0.0, 1.0),
      );
}

// ─── Handles enum ─────────────────────────────────────────────────────────────
enum _Handle {
  topLeft, topRight, bottomLeft, bottomRight,
  topCenter, bottomCenter, leftCenter, rightCenter,
  body,
}

// ─── Painter ──────────────────────────────────────────────────────────────────
class _CropPainter extends CustomPainter {
  final Rect           rect;
  final double         pulse;
  final OcrSourceType  sourceType;

  _CropPainter({
    required this.rect,
    required this.pulse,
    required this.sourceType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect px = Rect.fromLTWH(
      rect.left   * size.width,
      rect.top    * size.height,
      rect.width  * size.width,
      rect.height * size.height,
    );

    // ── 1. Zones sombres hors cadre ──
    final darkPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, px.top), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, px.bottom, size.width, size.height - px.bottom), darkPaint);
    canvas.drawRect(Rect.fromLTWH(0, px.top, px.left, px.height), darkPaint);
    canvas.drawRect(Rect.fromLTWH(px.right, px.top, size.width - px.right, px.height), darkPaint);

    // ── 2. Bordure principale ──
    final borderColor = sourceType == OcrSourceType.cryopodTooltip
        ? const Color(0xFF64B5F6)   // bleu cryo
        : const Color(0xFF00E5FF);  // cyan tek/auto

    final borderPaint = Paint()
      ..color       = borderColor.withValues(alpha: pulse)
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(px, borderPaint);

    // ── 3. Coins en L ──
    final cornerPaint = Paint()
      ..color       = borderColor
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap   = StrokeCap.round;
    const double cLen = 20.0;

    // Coin TL
    canvas.drawLine(Offset(px.left, px.top + cLen), Offset(px.left, px.top), cornerPaint);
    canvas.drawLine(Offset(px.left, px.top), Offset(px.left + cLen, px.top), cornerPaint);
    // Coin TR
    canvas.drawLine(Offset(px.right - cLen, px.top), Offset(px.right, px.top), cornerPaint);
    canvas.drawLine(Offset(px.right, px.top), Offset(px.right, px.top + cLen), cornerPaint);
    // Coin BL
    canvas.drawLine(Offset(px.left, px.bottom - cLen), Offset(px.left, px.bottom), cornerPaint);
    canvas.drawLine(Offset(px.left, px.bottom), Offset(px.left + cLen, px.bottom), cornerPaint);
    // Coin BR
    canvas.drawLine(Offset(px.right - cLen, px.bottom), Offset(px.right, px.bottom), cornerPaint);
    canvas.drawLine(Offset(px.right, px.bottom), Offset(px.right, px.bottom - cLen), cornerPaint);

    // ── 4. Poignées de coin (cercles pleins) ──
    final handlePaint = Paint()..color = borderColor;
    const double hR = 6.0;
    for (final pt in [
      Offset(px.left,       px.top),
      Offset(px.right,      px.top),
      Offset(px.left,       px.bottom),
      Offset(px.right,      px.bottom),
      Offset(px.center.dx,  px.top),
      Offset(px.center.dx,  px.bottom),
      Offset(px.left,       px.center.dy),
      Offset(px.right,      px.center.dy),
    ]) {
      canvas.drawCircle(pt, hR, handlePaint);
    }

    // ── 5. Grille tierce (rule of thirds) ──
    final gridPaint = Paint()
      ..color       = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    for (int i = 1; i <= 2; i++) {
      final x = px.left + px.width  * i / 3;
      final y = px.top  + px.height * i / 3;
      canvas.drawLine(Offset(x, px.top),  Offset(x, px.bottom), gridPaint);
      canvas.drawLine(Offset(px.left, y), Offset(px.right, y),  gridPaint);
    }
  }

  @override
  bool shouldRepaint(_CropPainter old) =>
      old.rect != rect || old.pulse != pulse || old.sourceType != sourceType;
}
