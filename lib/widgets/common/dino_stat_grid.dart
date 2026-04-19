// lib/widgets/common/dino_stat_grid.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/dino.dart';

class DinoStatGrid extends StatelessWidget {
  final Dino dino;

  const DinoStatGrid({super.key, required this.dino});

  /// Parse un nombre qui peut contenir une virgule ou un point
  static double _parseNum(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Affiche un nombre proprement : entier si pas de décimale, sinon 1 décimale
  static String _formatNum(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    return v.toStringAsFixed(1);
  }

  /// Parse le bloc [PTS:hp=50/13/0,stamina=20.5/5/2,...] depuis les notes
  /// Accepte int, double, virgule, point
  Map<String, List<double>> _parsePointsData() {
    final result = <String, List<double>>{};
    final notes = dino.notes;
    final regex = RegExp(r'\[PTS:(.+?)\]');
    final match = regex.firstMatch(notes);
    if (match == null) return result;

    final content = match.group(1)!;
    for (final part in content.split(',')) {
      final kv = part.split('=');
      if (kv.length != 2) continue;
      final key = kv[0].trim();
      final values = kv[1].trim().split('/');
      if (values.length == 3) {
        result[key] = [
          _parseNum(values[0]),
          _parseNum(values[1]),
          _parseNum(values[2]),
        ];
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ptsData = _parsePointsData();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '❤️', 'VIE', '${dino.hp}',
                  const Color(0xFF4CAF50), ptsData['hp'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '⚡', 'STAM', '${dino.stamina}',
                  const Color(0xFFFFD700), ptsData['stamina'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '⚔️', 'ATTAQUE', '${dino.degats.toStringAsFixed(1)}%',
                  const Color(0xFFEF4444), ptsData['degats'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '⚖️', 'POIDS', '${dino.poids}',
                  const Color(0xFF3B82F6), ptsData['poids'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '🍖', 'FOOD', '${dino.nourriture}',
                  const Color(0xFF8B5CF6), ptsData['nourriture'],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  '🫧', 'OXYGÈNE', '${dino.oxygene}',
                  const Color(0xFF10B981), ptsData['oxygene'],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String emoji,
    String label,
    String value,
    Color color,
    List<double>? ptsValues,
  ) {
    final bool hasPoints = ptsValues != null &&
        (ptsValues[0] > 0 || ptsValues[1] > 0 || ptsValues[2] > 0);
    final double total =
        hasPoints ? ptsValues[0] + ptsValues[1] + ptsValues[2] : 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF15181E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF454545), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.exo2(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (hasPoints) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${_formatNum(total)}pts',
                      style: GoogleFonts.exo2(
                        color: const Color(0xFFFF6B00),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        '|',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.2),
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatNum(ptsValues[0])} - ${_formatNum(ptsValues[1])} - ${_formatNum(ptsValues[2])}',
                      style: GoogleFonts.exo2(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.8),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
