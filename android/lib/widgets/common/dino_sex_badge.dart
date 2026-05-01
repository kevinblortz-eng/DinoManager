import 'package:flutter/material.dart';

/// Badge de sexe réutilisable — utilise les couleurs ARK standards.
/// Supporte : Mâle, Femelle, Mâle+Femelle, Inconnu.
class DinoSexBadge extends StatelessWidget {
  final String sexe;
  final double size;

  const DinoSexBadge({
    super.key,
    required this.sexe,
    this.size = 44,
  });

  static Color colorForSexe(String sexe) {
    switch (sexe) {
      case 'Mâle':         return const Color(0xFF4FC3F7);
      case 'Femelle':      return const Color(0xFFF48FB1);
      case 'Mâle+Femelle': return Colors.purple;
      default:             return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBoth = sexe == 'Mâle+Femelle';

    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.purple, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.5),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '♂',
              style: TextStyle(
                color: const Color(0xFF4FC3F7),
                fontSize: size * 0.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '♀',
              style: TextStyle(
                color: const Color(0xFFF48FB1),
                fontSize: size * 0.4,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    final color = colorForSexe(sexe);
    final symbol = sexe == 'Mâle' ? '♂' : sexe == 'Femelle' ? '♀' : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 8,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          color: color,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
