import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';

class DinoStatGrid extends StatelessWidget {
  final Dino dino;

  const DinoStatGrid({super.key, required this.dino});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('❤️', 'VIE', '${dino.hp}', dino.hpPoints, const Color(0xFF4CAF50))),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('⚡', 'STAM', '${dino.stamina}', dino.staminaPoints, const Color(0xFFFFD700))),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('⚔️', 'ATTAQUE', '${dino.degats.toStringAsFixed(0)}%', dino.degatsPoints, const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              Expanded(child: _buildStatCard('⚖️', 'POIDS', '${dino.poids}', dino.poidsPoints, const Color(0xFF3B82F6))),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('🍖', 'FOOD', '${dino.nourriture}', dino.nourriturePoints, const Color(0xFF8B5CF6))),
              const SizedBox(width: 10),
              Expanded(child: _buildStatCard('🫧', 'OXYGÈNE', '${dino.oxygene}', dino.oxygenePoints, const Color(0xFF10B981))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String emoji, String label, String value, int points, Color color) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF454545), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withOpacity(0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (points > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${points}pts',
                  style: GoogleFonts.exo2(
                    color: const Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
