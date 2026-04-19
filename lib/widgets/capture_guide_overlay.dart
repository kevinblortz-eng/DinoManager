// lib/widgets/capture_guide_overlay.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dialog affiché avant la prise de photo caméra
/// pour guider l'utilisateur sur le cadrage
class CaptureGuideDialog extends StatefulWidget {
  const CaptureGuideDialog({super.key});

  @override
  State<CaptureGuideDialog> createState() => _CaptureGuideDialogState();
}

class _CaptureGuideDialogState extends State<CaptureGuideDialog> {
  int _tipIndex = 0;
  late Timer _tipTimer;

  static const _tips = [
    '📸  Cadrez la fenêtre de stats du dino',
    '💡  Évitez les reflets sur l\'écran',
    '🔍  Zoomez pour que le texte soit lisible',
    '⏸️  Prenez la capture en mode pause',
    '📱  Tenez l\'appareil bien stable',
    '🌙  Augmentez la luminosité de l\'écran du jeu',
  ];

  @override
  void initState() {
    super.initState();
    _tipTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      }
    });
  }

  @override
  void dispose() {
    _tipTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0A0E1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Titre ──
            Row(
              children: [
                const Icon(Icons.document_scanner_rounded,
                    color: Color(0xFF00E5FF), size: 28),
                const SizedBox(width: 12),
                Text(
                  'Guide de capture',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Zone de cadrage visuel ──
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF15181E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Fond sombre simulant un écran de jeu
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          gradient: RadialGradient(
                            colors: [
                              Colors.grey.withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Rectangle de cadrage
                    Center(
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00E5FF),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.crop_free_rounded,
                              color: const Color(0xFF00E5FF).withOpacity(0.4),
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Placez la fenêtre de stats ici',
                              style: GoogleFonts.exo2(
                                color:
                                    const Color(0xFF00E5FF).withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Coins de guide
                    ..._buildCornerBrackets(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Tip rotatif ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Container(
                key: ValueKey(_tipIndex),
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                  ),
                ),
                child: Text(
                  _tips[_tipIndex],
                  style: GoogleFonts.exo2(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Bouton OK ──
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(
                  'OUVRIR LA CAMÉRA',
                  style: GoogleFonts.exo2(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Coins décoratifs aux 4 angles de la zone de cadrage
  List<Widget> _buildCornerBrackets() {
    const size = 20.0;
    const thickness = 3.0;
    const color = Color(0xFF00E5FF);
    const margin = 12.0;

    Widget corner(
        {required Alignment alignment,
        required BorderRadius radius,
        required Border border}) {
      return Align(
        alignment: alignment,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(margin),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
          ),
        ),
      );
    }

    return [
      corner(
        alignment: Alignment.topLeft,
        radius: const BorderRadius.only(topLeft: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.topRight,
        radius: const BorderRadius.only(topRight: Radius.circular(4)),
        border: const Border(
          top: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.bottomLeft,
        radius: const BorderRadius.only(bottomLeft: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          left: BorderSide(color: color, width: thickness),
        ),
      ),
      corner(
        alignment: Alignment.bottomRight,
        radius: const BorderRadius.only(bottomRight: Radius.circular(4)),
        border: const Border(
          bottom: BorderSide(color: color, width: thickness),
          right: BorderSide(color: color, width: thickness),
        ),
      ),
    ];
  }
}
