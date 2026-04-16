import 'package:flutter/material.dart';

class DinoSexBadge extends StatelessWidget {
  final String sexe;
  final double size;

  const DinoSexBadge({
    super.key, 
    required this.sexe, 
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isBoth = sexe.contains('Mâle+Femelle') || 
                   sexe.toLowerCase().contains('both');
    
    if (isBoth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.purple, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.5),
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
                color: Colors.blue[300],
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '♀',
              style: TextStyle(
                color: Colors.pink[300],
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    // Badge standard
    final Color color = sexe == 'Mâle' 
        ? const Color(0xFF4FC3F7) 
        : sexe == 'Femelle' 
            ? const Color(0xFFF48FB1) 
            : Colors.grey;
    
    final String symbol = sexe == 'Mâle' 
        ? '♂' 
        : sexe == 'Femelle' 
            ? '♀' 
            : '?';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
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