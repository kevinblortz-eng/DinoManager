import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../providers/tag_theme_provider.dart';
import '../providers/role_theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_color_palette.dart';
import '../utils/changelog_data.dart';
import '../widgets/changelog_dialog.dart';
import '../widgets/ark_color_picker.dart';
import 'backup_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer4<DinoProvider, TrackerProvider, TagThemeProvider,
        RoleThemeProvider>(
      builder: (context, dinoProvider, trackerProvider, tagThemeProvider,
          roleThemeProvider, _) {
        final dinos = dinoProvider.dinos;
        final totalDinos = dinos.length;
        final totalSpecies =
            dinos.map((d) => d.espece.toLowerCase()).toSet().length;
        final totalTrackers = trackerProvider.trackers.length;
        final totalAvailableSpecies = Dino.especesDisponibles.length;
        final speciesProgress = totalAvailableSpecies > 0
            ? totalSpecies / totalAvailableSpecies
            : 0.0;

        final usedTags = <String>{};
        for (final dino in dinos) {
          usedTags.addAll(dino.tags);
        }
        usedTags.addAll(Dino.tagsParDefaut);
        final sortedTags = usedTags.toList()..sort();

        return Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),

                // ── Bloc 6 : Sauvegarde ──
                _buildBackupSection(context),
                const SizedBox(height: 24),

                // ── Bloc 2 : Bestiaire ──
                _buildBestiaryStats(
                  context,
                  totalDinos: totalDinos,
                  totalSpecies: totalSpecies,
                  totalTrackers: totalTrackers,
                  totalAvailableSpecies: totalAvailableSpecies,
                  speciesProgress: speciesProgress,
                ),
                const SizedBox(height: 24),

                // ── Bloc 4 : Tags ──
                _buildTagsSection(
                    context, sortedTags, tagThemeProvider, dinoProvider),
                const SizedBox(height: 24),

                // ── Bloc 5 : Thèmes rôles ──
                _buildRoleThemesSection(context, roleThemeProvider),
                const SizedBox(height: 24),

                // ── Bloc 7 : Langue ──
                _buildLanguageSection(),
                const SizedBox(height: 24),

                // ── Bloc 3 : Actualités ──
                _buildNewsSection(),
                const SizedBox(height: 24),

                // ── Bloc 8 : Version ──
                _buildVersionFooter(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARK MANAGER',
                style: GoogleFonts.cinzelDecorative(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Paramètres & Informations',
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_rounded,
                  color: Colors.purpleAccent, size: 14),
              const SizedBox(width: 6),
              Text(
                'v${ChangelogData.currentVersion}',
                style: GoogleFonts.exo2(
                  color: Colors.purpleAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 6 — Sauvegarde
  // ═══════════════════════════════════════════════════════
  Widget _buildBackupSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cloud_rounded,
                  color: Colors.blueAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'SAUVEGARDE',
                style: GoogleFonts.exo2(
                  color: Colors.blueAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.blueAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('☁️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Auto-Backup actif',
                        style: GoogleFonts.exo2(
                          color: Colors.blueAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tes données sont sauvegardées automatiquement '
                        'dans Google Drive toutes les 24h. Elles seront '
                        'restaurées automatiquement à la réinstallation '
                        'sur le même compte Google.',
                        style: GoogleFonts.exo2(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const BackupScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.15),
                    Colors.blueAccent.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings_backup_restore_rounded,
                      color: Colors.blueAccent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Gérer les sauvegardes manuelles',
                    style: GoogleFonts.exo2(
                      color: Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.blueAccent.withValues(alpha: 0.6),
                      size: 11),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 2 — Bestiaire
  // ═══════════════════════════════════════════════════════
  Widget _buildBestiaryStats(
    BuildContext context, {
    required int totalDinos,
    required int totalSpecies,
    required int totalTrackers,
    required int totalAvailableSpecies,
    required double speciesProgress,
  }) {
    final percent = (speciesProgress * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  color: Colors.orangeAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'BESTIAIRE',
                style: GoogleFonts.exo2(
                  color: Colors.orangeAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatLine(Icons.loyalty_rounded, 'DinoCards',
                  '$totalDinos', AppTheme.accentPrimary),
              _buildStatDivider(),
              _buildStatLine(Icons.pets_rounded, 'Trackers',
                  '$totalTrackers', Colors.cyanAccent),
              _buildStatDivider(),
              _buildStatLine(Icons.military_tech_rounded, 'Espèces',
                  '$totalSpecies', Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.explore_rounded,
                  color: Colors.orangeAccent.withValues(alpha: 0.6),
                  size: 13),
              const SizedBox(width: 6),
              Text(
                'Bestiaire ARK',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$totalSpecies / $totalAvailableSpecies espèces',
                style: GoogleFonts.exo2(
                    color: AppTheme.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: speciesProgress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.orangeAccent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percent% du bestiaire ARK découvert',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildStatLine(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value,
              style: GoogleFonts.exo2(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.exo2(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 48,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 4 — Tags
  // ═══════════════════════════════════════════════════════
  Widget _buildTagsSection(
    BuildContext context,
    List<String> sortedTags,
    TagThemeProvider tagThemeProvider,
    DinoProvider dinoProvider,
  ) {
    final customCount = tagThemeProvider.tagColors.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_rounded,
                  color: Colors.purpleAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'TAGS & COULEURS',
                style: GoogleFonts.exo2(
                  color: Colors.purpleAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (customCount > 0)
                GestureDetector(
                  onTap: () =>
                      _confirmResetAllTags(context, tagThemeProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Reset tout',
                      style: GoogleFonts.exo2(
                        color: AppTheme.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Appuie sur un tag pour changer sa couleur',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: sortedTags.map((tag) {
              final customHex = tagThemeProvider.hexForTag(tag);
              final color = customHex != null
                  ? _hexToColor(customHex)
                  : _defaultTagColor(tag);
              final isCustom = customHex != null;
              final count = dinoProvider.dinos
                  .where((d) => d.tags.contains(tag))
                  .length;

              return GestureDetector(
                onTap: () => _openTagColorPicker(
                    context, tag, customHex, tagThemeProvider),
                onLongPress: isCustom
                    ? () => tagThemeProvider.removeTagColor(tag)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(
                          alpha: isCustom ? 0.6 : 0.3),
                      width: isCustom ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: isCustom
                              ? [
                                  BoxShadow(
                                    color:
                                        color.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tag,
                        style: GoogleFonts.exo2(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.exo2(
                              color: color.withValues(alpha: 0.9),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                      if (isCustom) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.colorize_rounded,
                            color: color.withValues(alpha: 0.7),
                            size: 10),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (customCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Appui long sur un tag personnalisé pour le réinitialiser',
              style: GoogleFonts.exo2(
                color: AppTheme.textMuted.withValues(alpha: 0.6),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 5 — Thèmes par rôle
  // ═══════════════════════════════════════════════════════
  Widget _buildRoleThemesSection(
    BuildContext context,
    RoleThemeProvider roleThemeProvider,
  ) {
    final roles = RoleThemeDefaults.defaults.keys.toList();
    final hasAnyCustom =
        roles.any((r) => roleThemeProvider.hasCustomTheme(r));

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.style_rounded,
                  color: Colors.amberAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'THÈMES PAR RÔLE',
                style: GoogleFonts.exo2(
                  color: Colors.amberAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (hasAnyCustom)
                GestureDetector(
                  onTap: () => _confirmResetAllRoles(
                      context, roleThemeProvider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color:
                              AppTheme.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      'Reset tout',
                      style: GoogleFonts.exo2(
                        color: AppTheme.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Appuie sur un rôle pour personnaliser ses 3 couleurs',
            style: GoogleFonts.exo2(
                color: AppTheme.textMuted, fontSize: 10),
          ),
          const SizedBox(height: 14),
          ...roles.where((r) => !roleThemeProvider.isDefaultDeleted(r)).map((role) {
            final theme = roleThemeProvider.themeForRole(role);
            final isCustom = roleThemeProvider.hasCustomTheme(role);

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _openRoleThemeEditor(
                    context, role, theme, roleThemeProvider),
                onLongPress: isCustom
                    ? () => roleThemeProvider.resetToDefault(role)
                    : () => roleThemeProvider.deleteTheme(role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.border
                          .withValues(alpha: isCustom ? 0.6 : 0.3),
                      width: isCustom ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Preview 3 couleurs
                      _buildColorDot(theme.background,
                          tooltip: 'Fond'),
                      const SizedBox(width: 4),
                      _buildColorDot(theme.border,
                          tooltip: 'Bordure'),
                      const SizedBox(width: 4),
                      _buildColorDot(theme.text, tooltip: 'Texte'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              role,
                              style: GoogleFonts.exo2(
                                color: theme.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (isCustom) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.border
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Perso',
                                  style: GoogleFonts.exo2(
                                    color: theme.border,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isCustom)
                            GestureDetector(
                              onTap: () => roleThemeProvider
                                  .resetToDefault(role),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                margin:
                                    const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.danger
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Icon(
                                    Icons.refresh_rounded,
                                    color: AppTheme.danger,
                                    size: 12),
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _openRoleThemeEditor(context,
                                role, theme, roleThemeProvider),
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.amberAccent
                                        .withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.amberAccent, size: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Text(
            'Appui long : reset perso  •  Appui long sur défaut : supprimer',
            style: GoogleFonts.exo2(
              color: AppTheme.textMuted.withValues(alpha: 0.5),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 7 — Langue (placeholder i18n)
  // ═══════════════════════════════════════════════════════
  Widget _buildLanguageSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded,
                  color: Colors.greenAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'LANGUE',
                style: GoogleFonts.exo2(
                  color: Colors.greenAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                          Colors.greenAccent.withValues(alpha: 0.2)),
                ),
                child: Text(
                  'Bientôt',
                  style: GoogleFonts.exo2(
                    color: Colors.greenAccent.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Langue active (FR uniquement pour l'instant)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Text('🇫🇷', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Français',
                        style: GoogleFonts.exo2(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Langue active',
                        style: GoogleFonts.exo2(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.greenAccent
                            .withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.greenAccent, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Langues futures grisées
          Opacity(
            opacity: 0.35,
            child: Row(
              children: [
                _buildLanguageTile('🇬🇧', 'English'),
                const SizedBox(width: 8),
                _buildLanguageTile('🇩🇪', 'Deutsch'),
                const SizedBox(width: 8),
                _buildLanguageTile('🇪🇸', 'Español'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le support multilingue sera disponible dans une prochaine mise à jour.',
            style: GoogleFonts.exo2(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 9,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(String flag, String name) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgPrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              name,
              style: GoogleFonts.exo2(
                color: AppTheme.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 3 — Actualités
  // ═══════════════════════════════════════════════════════
  Widget _buildNewsSection() {
    final versions = ChangelogData.history;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.newspaper_rounded,
                  color: Colors.cyanAccent.withValues(alpha: 0.8),
                  size: 16),
              const SizedBox(width: 8),
              Text(
                'ACTUALITÉS',
                style: GoogleFonts.exo2(
                  color: Colors.cyanAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...versions.asMap().entries.map((entry) {
            final index = entry.key;
            final version = entry.value;
            final isLast = index == versions.length - 1;
            final totalItems = version.sections
                .fold<int>(0, (sum, s) => sum + s.items.length);
            final isLatest = index == 0;
            final color =
                isLatest ? Colors.cyanAccent : AppTheme.textMuted;
            final versionEmoji = isLatest ? '🚀' : '📦';

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: color.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(versionEmoji,
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                version.date,
                                style: GoogleFonts.exo2(
                                  color: AppTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (isLatest) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.cyanAccent
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'Dernière',
                                    style: GoogleFonts.exo2(
                                      color: Colors.cyanAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Version ${version.version}',
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...version.sections.map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Text(section.type.emoji,
                                      style: const TextStyle(
                                          fontSize: 11)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${section.type.label} — ${section.items.length} élément${section.items.length > 1 ? 's' : ''}',
                                      style: GoogleFonts.exo2(
                                        color: section.type.color
                                            .withValues(alpha: 0.8),
                                        fontSize: 11,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalItems changement${totalItems > 1 ? 's' : ''} au total',
                            style: GoogleFonts.exo2(
                              color: AppTheme.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC 8 — Version
  // ═══════════════════════════════════════════════════════
  Widget _buildVersionFooter(BuildContext context) {
    final current = ChangelogData.current;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purpleAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ARK Dino Manager',
                style: GoogleFonts.exo2(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Version ${current.version} — ${current.date}',
                style: GoogleFonts.exo2(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ChangelogDialog(),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Nouveautés',
                style: GoogleFonts.exo2(
                  color: Colors.purpleAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS TAGS
  // ═══════════════════════════════════════════════════════
  void _openTagColorPicker(
    BuildContext context,
    String tag,
    String? currentHex,
    TagThemeProvider tagThemeProvider,
  ) {
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
        species: 'Rex',
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

  void _confirmResetAllTags(
      BuildContext context, TagThemeProvider tagThemeProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Réinitialiser tous les tags ?',
            style: GoogleFonts.exo2(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Toutes les couleurs personnalisées seront supprimées.',
          style: GoogleFonts.exo2(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              tagThemeProvider.resetAll();
            },
            child: Text('Réinitialiser',
                style: GoogleFonts.exo2(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS RÔLES
  // ═══════════════════════════════════════════════════════
  Widget _buildColorDot(Color color, {String tooltip = ''}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.4), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  void _openRoleThemeEditor(
    BuildContext context,
    String role,
    RoleTheme currentTheme,
    RoleThemeProvider roleThemeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoleThemeEditorSheet(
        role: role,
        currentTheme: currentTheme,
        onSave: (theme) => roleThemeProvider.setTheme(role, theme),
      ),
    );
  }

  void _confirmResetAllRoles(
      BuildContext context, RoleThemeProvider roleThemeProvider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Réinitialiser tous les thèmes ?',
            style: GoogleFonts.exo2(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Tous les thèmes personnalisés seront supprimés.',
          style: GoogleFonts.exo2(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              roleThemeProvider.resetAll();
            },
            child: Text('Réinitialiser',
                style: GoogleFonts.exo2(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS COULEURS
  // ═══════════════════════════════════════════════════════
  Color _defaultTagColor(String tag) {
    switch (tag) {
      case 'Boss':       return const Color(0xFFFF4444);
      case 'Breed':
      case 'Breeding':   return const Color(0xFF4CAF50);
      case 'Solid':      return const Color(0xFFFF6B00);
      case 'Farm':       return const Color(0xFFFFD700);
      case 'Collection': return const Color(0xFF00BCD4);
      case 'Combat':     return const Color(0xFF9C27B0);
      default:           return AppTheme.textMuted;
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

// ════════════════════════════════════════════════════════════════════════════
// ÉDITEUR THÈME RÔLE — Bottom Sheet
// ════════════════════════════════════════════════════════════════════════════
class _RoleThemeEditorSheet extends StatefulWidget {
  final String role;
  final RoleTheme currentTheme;
  final ValueChanged<RoleTheme> onSave;

  const _RoleThemeEditorSheet({
    required this.role,
    required this.currentTheme,
    required this.onSave,
  });

  @override
  State<_RoleThemeEditorSheet> createState() =>
      _RoleThemeEditorSheetState();
}

class _RoleThemeEditorSheetState
    extends State<_RoleThemeEditorSheet> {
  late Color _background;
  late Color _border;
  late Color _text;
  int _activeSlot = 1; // 0=fond, 1=bordure, 2=texte

  @override
  void initState() {
    super.initState();
    _background = widget.currentTheme.background;
    _border = widget.currentTheme.border;
    _text = widget.currentTheme.text;
  }

  Color get _activeColor {
    switch (_activeSlot) {
      case 0: return _background;
      case 1: return _border;
      default: return _text;
    }
  }

  void _setActiveColor(Color color) {
    setState(() {
      switch (_activeSlot) {
        case 0: _background = color; break;
        case 1: _border = color; break;
        default: _text = color; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titre + preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'Thème — ${widget.role}',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                // Preview badge animé
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _border.withValues(alpha: 0.7),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _border.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.role.toUpperCase(),
                    style: GoogleFonts.exo2(
                      color: _text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sélecteur de slot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildSlotButton(0, _background, 'Fond'),
                const SizedBox(width: 10),
                _buildSlotButton(1, _border, 'Bordure'),
                const SizedBox(width: 10),
                _buildSlotButton(2, _text, 'Texte'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Grille couleurs ARK
          Expanded(
            child: _ArkColorGrid(
              selectedColor: _activeColor,
              onColorSelected: _setActiveColor,
            ),
          ),

          // Boutons
          Padding(
            padding:
                EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      foregroundColor: AppTheme.textSecondary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Annuler',
                        style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onSave(RoleTheme(
                        role: widget.role,
                        background: _background,
                        border: _border,
                        text: _text,
                      ));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                      foregroundColor: Colors.black,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Appliquer',
                        style: GoogleFonts.exo2(
                            fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotButton(int slot, Color color, String label) {
    final isActive = _activeSlot == slot;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeSlot = slot),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? color.withValues(alpha: 0.2)
                : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? color.withValues(alpha: 0.7)
                  : AppTheme.borderColor,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.exo2(
                  color:
                      isActive ? color : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GRILLE COULEURS ARK
// ════════════════════════════════════════════════════════════════════════════
class _ArkColorGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ArkColorGrid({
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ArkColorPalette.allColors;

    return GridView.builder(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.85,
      ),
      itemCount: colors.length,
      itemBuilder: (context, index) {
        final arkColor = colors[index];
        final color = arkColor.color;
        final isSelected = _colorDistance(color, selectedColor) < 100;

        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2.5 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isSelected)
                  const Icon(Icons.check,
                      color: Colors.white, size: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(5),
                      bottomRight: Radius.circular(5),
                    ),
                  ),
                  child: Text(
                    '${arkColor.id}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _colorDistance(Color a, Color b) {
    final dr = (a.r - b.r) * 255;
    final dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    return dr * dr + dg * dg + db * db;
  }
}
