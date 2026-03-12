import 'package:flutter/material.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';
import 'dino_image_widget.dart';

/// Carte dino unifiée utilisée dans la page d'accueil ET la bibliothèque.
/// Affiche l'image, les stats principales et la bande de couleurs.
class DinoCardWidget extends StatelessWidget {
  final Dino dino;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final bool showEditButton;

  const DinoCardWidget({
    super.key,
    required this.dino,
    this.onTap,
    this.onEdit,
    this.showEditButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.bgCard,
              AppTheme.bgCard.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dino.roleColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: dino.roleColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Image dino ───────────────────────────────────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                bottomLeft: Radius.circular(13),
              ),
              child: Container(
                width: 110,
                height: 84,
                color: AppTheme.bgPrimary.withValues(alpha: 0.6),
                child: DinoImageWidget(
                  species: dino.espece,
                  regionColors: dino.colorRegions,
                  width: 110,
                  height: 84,
                  showColorBand: false,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

            // ── Infos ────────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom + badge sexe
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dino.nom,
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _sexeBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Espèce + niveau
                    Text(
                      '${dino.espece}  ·  Lvl ${dino.niveau}',
                      style: TextStyle(
                        color: AppTheme.accentSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Stats principales : HP + Dégâts
                    Row(
                      children: [
                        _miniStat('❤️', '${dino.hp}', '+${dino.hpPoints}pts'),
                        const SizedBox(width: 8),
                        _miniStat('⚔️', '${dino.degats.toStringAsFixed(0)}%', '+${dino.degatsPoints}pts'),
                        const SizedBox(width: 8),
                        _roleBadge(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Bande de couleurs régionales
                    _colorBand(),
                  ],
                ),
              ),
            ),

            // ── Chevron ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sexeBadge() {
    if (dino.sexe == 'Inconnu') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: dino.sexeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: dino.sexeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        dino.sexe == 'Mâle' ? '♂' : '♀',
        style: TextStyle(color: dino.sexeColor, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _roleBadge() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: dino.roleColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: dino.roleColor.withValues(alpha: 0.3)),
        ),
        child: Text(
          dino.role,
          style: TextStyle(
            color: dino.roleColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _miniStat(String icon, String value, String pts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 10)),
            const SizedBox(width: 2),
            Text(
              value,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          pts,
          style: TextStyle(
            color: AppTheme.accentGreen.withValues(alpha: 0.8),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _colorBand() {
    final colors = dino.colorRegions;
    final hasAny = colors.any((c) => c != null && c != '#808080' && c != '#7F7F7F');
    if (!hasAny) {
      return Container(
        height: 5,
        decoration: BoxDecoration(
          color: AppTheme.borderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return SizedBox(
      height: 8,
      child: Row(
        children: List.generate(6, (i) {
          final hex = i < colors.length ? colors[i] : null;
          final isDefault = hex == null || hex == '#808080' || hex == '#7F7F7F';
          Color color;
          if (isDefault) {
            color = AppTheme.borderColor.withValues(alpha: 0.25);
          } else {
            color = _parseHex(hex) ?? AppTheme.borderColor.withValues(alpha: 0.25);
          }
          return Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        }),
      ),
    );
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
