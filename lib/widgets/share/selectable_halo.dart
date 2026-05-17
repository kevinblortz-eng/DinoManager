// lib/widgets/share/selectable_halo.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SelectableHalo extends StatelessWidget {
  final Widget child;
  final bool isSelected;
  final bool selectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showFavoriteToggle;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;
  final Color accentColor;

  const SelectableHalo({
    super.key,
    required this.child,
    required this.isSelected,
    required this.selectionMode,
    this.onTap,
    this.onLongPress,
    this.showFavoriteToggle = false,
    this.isFavorite = false,
    this.onFavoriteTap,
    this.accentColor = AppTheme.accentPrimary,
  });

  @override
  Widget build(BuildContext context) {
    // ─── Hors mode sélection : passthrough total ──────────────────────
    if (!selectionMode) {
      return GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTap: onTap,
        onLongPress: onLongPress,
        child: child,
      );
    }

    // ─── Mode sélection : on absorbe les pointeurs internes du child ──
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(isSelected ? 3 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AbsorbPointer(absorbing: true, child: child),

            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: accentColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),

            // ⭐ Badge favori (haut gauche) — Canva picker uniquement
            if (showFavoriteToggle)
              Positioned(
                top: 6,
                left: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFavoriteTap,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFavorite
                          ? const Color(0xFFFFD700)
                          : Colors.black.withValues(alpha: 0.55),
                      border: Border.all(
                        color: isFavorite
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        width: 2,
                      ),
                      boxShadow: isFavorite
                          ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isFavorite
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorite ? Colors.black87 : Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),

            // ✓ Badge sélection (haut droit)
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
