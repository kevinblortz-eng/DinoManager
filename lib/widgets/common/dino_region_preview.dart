// lib/widgets/common/dino_region_preview.dart
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dino_image_widget.dart';

/// Mini-aperçu du dino avec surbrillance de la région active.
/// 
/// Affiche le dino colorisé en temps réel :
///   - Région [activeRegion] → couleur choisie (ou rouge #FF4444 si non encore choisie)
///   - Autres régions actives → leurs couleurs actuelles atténuées
///   - Régions inactives → gris neutre #808080
class DinoRegionPreview extends StatelessWidget {
  final String species;

  /// Couleurs actuelles des 6 régions (hex ou null)
  final List<String?> currentColors;

  /// Région 0-5 actuellement en cours d'édition
  final int activeRegion;

  /// Couleur prévisualisée pour la région active (hex, peut être null)
  final String? previewColor;

  const DinoRegionPreview({
    super.key,
    required this.species,
    required this.currentColors,
    required this.activeRegion,
    this.previewColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayColors = _buildDisplayColors();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Dino avec surbrillance ──
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1115),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFFF4444).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: DinoImageWidget(
              species: species,
              regionColors: displayColors,
              width: double.infinity,
              height: 130,
              fit: BoxFit.contain,
              showColorBand: false,
              alignment: Alignment.center,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // ── Indicateur régions ──
        Row(
          children: List.generate(6, (i) {
            final isActive = i == activeRegion;
            final hex = displayColors[i];
            final isGray = hex == null ||
                hex.toUpperCase().replaceAll('#', '') == '808080' ||
                hex.toUpperCase().replaceAll('#', '') == '7F7F7F';

            Color chipColor;
            if (isGray) {
              chipColor = const Color(0xFF2A2A2A);
            } else {
              try {
                final h = hex.replaceAll('#', '');
                chipColor = Color(int.parse('FF$h', radix: 16));
              } catch (_) {
                chipColor = const Color(0xFF2A2A2A);
              }
            }

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isActive ? 28 : 22,
                margin: EdgeInsets.only(right: i < 5 ? 3 : 0),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFFFF4444)
                        : Colors.white.withValues(alpha: 0.15),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4444).withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$i',
                  style: GoogleFonts.exo2(
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: isActive ? 11 : 9,
                    fontWeight: isActive
                        ? FontWeight.w900
                        : FontWeight.w500,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Construit la liste de couleurs pour l'affichage :
  /// - Région active → previewColor si définie, sinon rouge surbrillance
  /// - Autres régions → leur couleur actuelle (atténuée) ou gris
  List<String?> _buildDisplayColors() {
    final result = List<String?>.filled(6, null);

    for (int i = 0; i < 6; i++) {
      if (i == activeRegion) {
        // Région active : preview ou rouge surbrillance
        if (previewColor != null &&
            previewColor!.toUpperCase().replaceAll('#', '') != '808080' &&
            previewColor!.toUpperCase().replaceAll('#', '') != '7F7F7F') {
          result[i] = previewColor;
        } else {
          // Pas encore de couleur choisie → rouge pour montrer la zone
          result[i] = '#FF4444';
        }
      } else {
        // Autres régions → couleur existante ou gris neutre
        final existing = currentColors.length > i ? currentColors[i] : null;
        final isNeutral = existing == null ||
            existing.toUpperCase().replaceAll('#', '') == '808080' ||
            existing.toUpperCase().replaceAll('#', '') == '7F7F7F';
        result[i] = isNeutral ? '#808080' : existing;
      }
    }

    return result;
  }
}
