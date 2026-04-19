import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import 'dino_image_widget.dart';

// ══════════════════════════════════════════════════════════════════════════════
// CARTE DINO LISTE - VERSION OPTIMISÉE ET CORRIGÉE
// ══════════════════════════════════════════════════════════════════════════════
class ArkDinoCard extends StatelessWidget {
  final Dino dino;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // ✅ CONSTRUCTEUR CORRIGÉ - Plus de double déclaration
  const ArkDinoCard({
    super.key,
    required this.dino,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 125,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F2E), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dino.roleColor.withAlpha((0.3 * 255).round()),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.5 * 255).round()),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: dino.roleColor.withAlpha((0.15 * 255).round()),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Row(
            children: [
              _buildDinoSection(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 6),
                      Expanded(child: _buildStatsGrid()),
                      const SizedBox(height: 4),
                      _buildColorStrip(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withAlpha((0.2 * 255).round()),
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SECTION GAUCHE : BULLE NOIRE + DINO INVERSÉ (Inchangée)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDinoSection() {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.centerLeft,
          radius: 0.5,
          colors: [
            dino.roleColor.withAlpha((0.15 * 255).round()),
            Colors.transparent,
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.black.withAlpha((0.85 * 255).round()),
                  Colors.black.withAlpha((0.95 * 255).round()),
                ],
              ),
              border: Border.all(
                color: dino.roleColor.withAlpha((0.4 * 255).round()),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.7 * 255).round()),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.white.withAlpha((0.25 * 255).round()),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: dino.roleColor.withAlpha((0.3 * 255).round()),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
          ),
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
            child: Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withAlpha((0.2 * 255).round()),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: DinoImageWidget(
                  species: dino.espece,
                  regionColors: dino.colorRegions,
                  width: 104,
                  height: 104,
                  fit: BoxFit.cover,
                  showColorBand: false,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER : NOM + ESPÈCE/NIVEAU + BADGES (Inchangé)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                dino.nom,
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            if (dino.sexe != 'Inconnu') _buildSexBadge(),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                '${dino.espece}  ·  Lvl ${dino.niveau}',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildRoleBadge(),
          ],
        ),
      ],
    );
  }

  Widget _buildSexBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: dino.sexeColor.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: dino.sexeColor.withAlpha((0.6 * 255).round()),
          width: 1.5,
        ),
      ),
      child: Text(
        dino.sexeSymbol,
        style: TextStyle(
          color: dino.sexeColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: dino.roleColor.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: dino.roleColor.withAlpha((0.5 * 255).round()),
          width: 1,
        ),
      ),
      child: Text(
        dino.role.toUpperCase(),
        style: TextStyle(
          color: dino.roleColor,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ✅ STATS ULTRA-COMPACTES - FORMAT EXACT DEMANDÉ
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildStatsGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((0.25 * 255).round()),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withAlpha((0.1 * 255).round()),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Ligne 1 : HP | STAM | DMG ──
          Row(
            children: [
              Expanded(child: _buildCompactStat('HP', _formatNumber(dino.hp), const Color(0xFF4CAF50))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Stam', _formatNumber(dino.stamina), const Color(0xFFFFD700))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Dmg', '${dino.degats.toStringAsFixed(0)}%', const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 4),
          // ── Ligne 2 : POIDS | FOOD | SPEED ──
          Row(
            children: [
              Expanded(child: _buildCompactStat('Poids', _formatNumber(dino.poids), const Color(0xFF3B82F6))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Food', _formatNumber(dino.nourriture), const Color(0xFF8B5CF6))),
              _buildStatDivider(),
              Expanded(child: _buildCompactStat('Oxygen', _formatNumber(dino.oxygene), const Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  /// ✅ FORMAT EXACT : "HP - 1234" comme demandé
  Widget _buildCompactStat(String label, String value, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.exo2(
              color: Colors.white.withAlpha((0.7 * 255).round()),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            ' - ',
            style: GoogleFonts.exo2(
              color: Colors.white.withAlpha((0.4 * 255).round()),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.exo2(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  /// Séparateur vertical entre stats
  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: Colors.white.withAlpha((0.15 * 255).round()),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BANDE DE COULEURS (Inchangée)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildColorStrip() {
    final colors = dino.colorRegions;
    
    return Column(
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withAlpha((0.15 * 255).round()),
                Colors.transparent,
              ],
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha((0.2 * 255).round()),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withAlpha((0.08 * 255).round()),
              width: 1,
            ),
          ),
          child: Row(
            children: List.generate(6, (i) {
              final hex = i < colors.length ? colors[i] : null;
              final isInactive = hex == null || hex == '#808080' || hex == '#7F7F7F';
              final color = isInactive
                  ? const Color(0xFF1F2937)
                  : _parseHex(hex) ?? const Color(0xFF1F2937);

              return Expanded(
                child: Container(
                  height: 8,
                  margin: EdgeInsets.only(right: i < 5 ? 2 : 0),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Colors.white.withAlpha((isInactive ? 0.05 : 0.25 * 255).round()),
                      width: 0.5,
                    ),
                    boxShadow: !isInactive ? [
                      BoxShadow(
                        color: color.withAlpha((0.4 * 255).round()),
                        blurRadius: 2,
                      ),
                    ] : null,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  /// ✅ Formate les grands nombres pour gagner de l'espace
  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}m';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }
}

