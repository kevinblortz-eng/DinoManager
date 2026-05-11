import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../models/ark_color_palette.dart';
import '../providers/dino_provider.dart';
import '../providers/tag_theme_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ark_color_picker.dart';

class TagThemeScreen extends StatelessWidget {
  const TagThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, TagThemeProvider>(
      builder: (context, dinoProvider, tagThemeProvider, _) {
        // Collecte tous les tags utilisés dans les DinoCards
        final usedTags = <String>{};
        for (final dino in dinoProvider.dinos) {
          usedTags.addAll(dino.tags);
        }
        // Ajoute les tags par défaut même si non utilisés
        usedTags.addAll(Dino.tagsParDefaut);
        final sortedTags = usedTags.toList()..sort();

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            backgroundColor: AppTheme.bgSecondary,
            title: Text(
              'Couleurs des tags',
              style: GoogleFonts.exo2(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Bouton reset global
              TextButton.icon(
                onPressed: tagThemeProvider.tagColors.isEmpty
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppTheme.bgCard,
                            title: Text(
                              'Réinitialiser ?',
                              style: GoogleFonts.exo2(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                            content: Text(
                              'Toutes les couleurs personnalisées seront supprimées.',
                              style: GoogleFonts.exo2(
                                  color: AppTheme.textSecondary),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: Text('Annuler',
                                    style: GoogleFonts.exo2(
                                        color: AppTheme.textMuted)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: Text('Réinitialiser',
                                    style: GoogleFonts.exo2(
                                        color: AppTheme.danger)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && context.mounted) {
                          await tagThemeProvider.resetAll();
                        }
                      },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: tagThemeProvider.tagColors.isEmpty
                      ? AppTheme.textMuted
                      : AppTheme.danger,
                ),
                label: Text(
                  'Reset',
                  style: GoogleFonts.exo2(
                    color: tagThemeProvider.tagColors.isEmpty
                        ? AppTheme.textMuted
                        : AppTheme.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          body: sortedTags.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedTags.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final tag = sortedTags[index];
                    return _buildTagRow(
                        context, tag, tagThemeProvider, dinoProvider);
                  },
                ),
        );
      },
    );
  }

  Widget _buildTagRow(
    BuildContext context,
    String tag,
    TagThemeProvider tagThemeProvider,
    DinoProvider dinoProvider,
  ) {
    final customHex = tagThemeProvider.hexForTag(tag);
    final hasCustom = customHex != null;

    // Couleur affichée : personnalisée ou défaut selon le rôle
    final displayColor = hasCustom
        ? _hexToColor(customHex)
        : _defaultTagColor(tag);

    // Nb de dinos utilisant ce tag
    final count =
        dinoProvider.dinos.where((d) => d.tags.contains(tag)).length;

    return GestureDetector(
      onTap: () => _openColorPicker(context, tag, customHex, tagThemeProvider),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCustom
                ? displayColor.withValues(alpha: 0.4)
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            // ── Carré couleur ──
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: displayColor.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: displayColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Nom du tag + infos ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.exo2(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasCustom) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Perso',
                            style: GoogleFonts.exo2(
                              color: displayColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasCustom
                        ? '$customHex · $count dino${count > 1 ? 's' : ''}'
                        : 'Couleur par défaut · $count dino${count > 1 ? 's' : ''}',
                    style: GoogleFonts.exo2(
                      color: AppTheme.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            // ── Actions ──
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton reset individuel (seulement si couleur perso)
                if (hasCustom)
                  GestureDetector(
                    onTap: () => tagThemeProvider.removeTagColor(tag),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppTheme.danger.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.danger, size: 14),
                    ),
                  ),
                // Bouton édition
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color:
                            AppTheme.accentPrimary.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.colorize_rounded,
                      color: AppTheme.accentPrimary, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openColorPicker(
    BuildContext context,
    String tag,
    String? currentHex,
    TagThemeProvider tagThemeProvider,
  ) {
    // ID ARK le plus proche de la couleur actuelle
    final currentId = currentHex != null
        ? ArkColorPalette.hexToClosestId(currentHex)
        : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArkColorPicker(
        selectedId: currentId,
        selectedHex: currentHex ?? '#808080',
        regionName: tag,
        regionIndex: 0,
        species: 'Rex', // Preview neutre
        currentColors: const [null, null, null, null, null, null],
        onColorSelected: (result) async {
          if (result.id > 0) {
            await tagThemeProvider.setTagColor(tag, result.hex);
          } else {
            await tagThemeProvider.removeTagColor(tag);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.label_off_rounded,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text(
            'Aucun tag utilisé',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Ajoute des tags à tes DinoCards pour les voir ici.',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _defaultTagColor(String tag) {
    switch (tag) {
      case 'Boss':
        return const Color(0xFFFF4444);
      case 'Breed':
      case 'Breeding':
        return const Color(0xFF4CAF50);
      case 'Solid':
        return const Color(0xFFFF6B00);
      case 'Farm':
        return const Color(0xFFFFD700);
      case 'Collection':
        return const Color(0xFF00BCD4);
      case 'Combat':
        return const Color(0xFF9C27B0);
      default:
        return AppTheme.textMuted;
    }
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }
}
