// lib/screens/setting_screen.dart
import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dino_provider.dart';
import '../providers/tracker_provider.dart';
import '../providers/tag_theme_provider.dart';
import '../providers/role_theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/gemini_provider.dart';
import '../theme/app_theme.dart';
import '../models/dino.dart';
import '../models/role_theme.dart';
import '../models/ark_color_palette.dart';
import '../utils/changelog_data.dart';
import '../widgets/changelog_dialog.dart';
import '../widgets/ark_color_picker.dart';
import '../l10n/app_localizations.dart';
import 'backup_screen.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return _SettingScreenContent(languageProvider: languageProvider);
      },
    );
  }
}

class _SettingScreenContent extends StatefulWidget {
  final LanguageProvider languageProvider;
  const _SettingScreenContent({required this.languageProvider});

  @override
  State<_SettingScreenContent> createState() => _SettingScreenContentState();
}

class _SettingScreenContentState extends State<_SettingScreenContent> {
  LanguageProvider get languageProvider => widget.languageProvider;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Consumer4<DinoProvider, TrackerProvider, TagThemeProvider,
        RoleThemeProvider>(
      builder: (context, dinoProvider, trackerProvider, tagThemeProvider,
          roleThemeProvider, _) {
        final dinos = dinoProvider.allDinos; // FIX BUG-LIB-01: stats globales = liste complete
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // ── Header ──
                _buildHeader(l10n),
                const SizedBox(height: 20),

                // ── Menu direct : Langue ──
                _SettingsRow(
                  icon: Icons.language_rounded,
                  iconColor: Colors.greenAccent,
                  title: l10n.settingsLanguage,
                  subtitle:
                      '${languageProvider.currentLanguageInfo['flag']}  ${languageProvider.currentLanguageInfo['label']}',
                  onTap: () => _showLanguageSheet(context, l10n),
                ),
                const SizedBox(height: 12),

                // ── Menu direct : Sauvegardes ──
                _SettingsRow(
                  icon: Icons.settings_backup_restore_rounded,
                  iconColor: Colors.blueAccent,
                  title: l10n.settingsBackup,
                  subtitle: l10n.backupManage,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Sections encapsulées (fermées par défaut) ──
                _CollapsibleSection(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Colors.orangeAccent,
                  title: l10n.settingsBestiary,
                  initiallyExpanded: false,
                  child: _buildBestiaryStats(
                    context,
                    l10n: l10n,
                    totalDinos: totalDinos,
                    totalSpecies: totalSpecies,
                    totalTrackers: totalTrackers,
                    totalAvailableSpecies: totalAvailableSpecies,
                    speciesProgress: speciesProgress,
                  ),
                ),
                const SizedBox(height: 12),

                _CollapsibleSection(
                  icon: Icons.label_rounded,
                  iconColor: Colors.purpleAccent,
                  title: l10n.settingsTags,
                  subtitle: l10n.tagsTapToChange,
                  initiallyExpanded: false,
                  child: _buildTagsSection(
                      context, l10n, sortedTags, tagThemeProvider, dinoProvider),
                ),
                const SizedBox(height: 12),

                _CollapsibleSection(
                  icon: Icons.style_rounded,
                  iconColor: Colors.amberAccent,
                  title: l10n.settingsRoleThemes,
                  subtitle: l10n.roleThemesTapHint,
                  initiallyExpanded: false,
                  child:
                      _buildRoleThemesSection(context, l10n, roleThemeProvider),
                ),
                const SizedBox(height: 12),

                _CollapsibleSection(
                  icon: Icons.auto_awesome_rounded,
                  iconColor: const Color(0xFF4285F4),
                  title: l10n.settingsGemini,
                  subtitle: _getGeminiSubtitle(l10n),
                  initiallyExpanded: false,
                  child: _buildGeminiSection(context, l10n),
                ),
                const SizedBox(height: 12),

                _CollapsibleSection(
                  icon: Icons.newspaper_rounded,
                  iconColor: Colors.cyanAccent,
                  title: l10n.settingsNews,
                  initiallyExpanded: false,
                  child: _buildNewsSection(l10n),
                ),
                const SizedBox(height: 12),

                // ── Version ──
                _buildVersionFooter(context, l10n),
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
  Widget _buildHeader(AppLocalizations l10n) {
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
                l10n.settingsTitle,
                style: GoogleFonts.exo2(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
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
  // BOTTOM SHEET — Choix unique de langue
  // ═══════════════════════════════════════════════════════
  void _showLanguageSheet(BuildContext context, AppLocalizations l10n) {
    final langs = LanguageProvider.supportedLanguages;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<LanguageProvider>(
          builder: (context, languageProvider, _) {
            final activeCode = languageProvider.currentCode;

            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgSecondary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(top: 12, bottom: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Titre
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Icon(Icons.language_rounded,
                              color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            l10n.languageSelectorTitle,
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Liste à choix unique
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: langs.length,
                        itemBuilder: (context, index) {
                          final lang = langs[index];
                          final code = lang['code']!;
                          final isActive = code == activeCode;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(sheetContext);
                                languageProvider.setLocale(code);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.greenAccent
                                          .withValues(alpha: 0.08)
                                      : AppTheme.bgCard,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.greenAccent
                                            .withValues(alpha: 0.5)
                                        : AppTheme.borderColor,
                                    width: isActive ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(lang['flag']!,
                                        style:
                                            const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        lang['label']!,
                                        style: GoogleFonts.exo2(
                                          color: isActive
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                          fontSize: 14,
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.greenAccent
                                                  .withValues(alpha: 0.4)),
                                        ),
                                        child: const Icon(Icons.check_rounded,
                                            color: Colors.greenAccent,
                                            size: 12),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC — Bestiaire (contenu, encapsulé)
  // ═══════════════════════════════════════════════════════
  Widget _buildBestiaryStats(
    BuildContext context, {
    required AppLocalizations l10n,
    required int totalDinos,
    required int totalSpecies,
    required int totalTrackers,
    required int totalAvailableSpecies,
    required double speciesProgress,
  }) {
    final percent = (speciesProgress * 100).toStringAsFixed(0);

    return Column(
      children: [
        Row(
          children: [
            _buildStatLine(Icons.loyalty_rounded, l10n.bestiaryDinoCards,
                '$totalDinos', AppTheme.accentPrimary),
            _buildStatDivider(),
            _buildStatLine(Icons.pets_rounded, l10n.bestiaryTrackers,
                '$totalTrackers', Colors.cyanAccent),
            _buildStatDivider(),
            _buildStatLine(Icons.military_tech_rounded,
                l10n.bestiarySpecies, '$totalSpecies', Colors.orangeAccent),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.explore_rounded,
                color: Colors.orangeAccent.withValues(alpha: 0.6), size: 13),
            const SizedBox(width: 6),
            Text(
              l10n.bestiaryArkBestiary,
              style: GoogleFonts.exo2(
                color: AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              l10n.bestiarySpeciesCount(totalSpecies, totalAvailableSpecies),
              style: GoogleFonts.exo2(color: AppTheme.textMuted, fontSize: 10),
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
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.bestiaryDiscovered(percent),
          style: GoogleFonts.exo2(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
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
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
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
  // BLOC — Tags (contenu, encapsulé)
  // ═══════════════════════════════════════════════════════
  Widget _buildTagsSection(
    BuildContext context,
    AppLocalizations l10n,
    List<String> sortedTags,
    TagThemeProvider tagThemeProvider,
    DinoProvider dinoProvider,
  ) {
    final customCount = tagThemeProvider.tagColors.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (customCount > 0)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () =>
                  _confirmResetAllTags(context, l10n, tagThemeProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.tagsResetAll,
                  style: GoogleFonts.exo2(
                    color: AppTheme.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        if (customCount > 0) const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: sortedTags.map((tag) {
            final customHex = tagThemeProvider.hexForTag(tag);
            final color = customHex != null
                ? _hexToColor(customHex)
                : _defaultTagColor(tag);
            final isCustom = customHex != null;
            final count = dinoProvider.allDinos
                .where((d) => d.tags.contains(tag))
                .length;

            return GestureDetector(
              onTap: () => _openTagColorPicker(
                  context, tag, customHex, tagThemeProvider),
              onLongPress:
                  isCustom ? () => tagThemeProvider.removeTagColor(tag) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        color.withValues(alpha: isCustom ? 0.6 : 0.3),
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
                                  color: color.withValues(alpha: 0.5),
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
                          color: color.withValues(alpha: 0.7), size: 10),
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
            l10n.tagsLongPressReset,
            style: GoogleFonts.exo2(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC — Thèmes par rôle (contenu, encapsulé)
  // ═══════════════════════════════════════════════════════
  Widget _buildRoleThemesSection(
    BuildContext context,
    AppLocalizations l10n,
    RoleThemeProvider roleThemeProvider,
  ) {
    final roles = RoleThemeDefaults.defaults.keys.toList();
    final hasAnyCustom = roles.any((r) => roleThemeProvider.hasCustomTheme(r));

    return Column(
      children: [
        if (hasAnyCustom)
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () =>
                  _confirmResetAllRoles(context, l10n, roleThemeProvider),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.tagsResetAll,
                  style: GoogleFonts.exo2(
                    color: AppTheme.danger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        if (hasAnyCustom) const SizedBox(height: 8),
        ...roles
            .where((r) => !roleThemeProvider.isDefaultDeleted(r))
            .map((role) {
          final theme = roleThemeProvider.themeForRole(role);
          final isCustom = roleThemeProvider.hasCustomTheme(role);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
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
                  _buildColorDot(theme.background,
                      tooltip: l10n.roleThemesBackground),
                  const SizedBox(width: 4),
                  _buildColorDot(theme.border,
                      tooltip: l10n.roleThemesBorder),
                  const SizedBox(width: 4),
                  _buildColorDot(theme.text,
                      tooltip: l10n.roleThemesText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            role,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.exo2(
                              color: theme.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isCustom) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: theme.border.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.roleThemesPreview,
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
                          onTap: () =>
                              roleThemeProvider.resetToDefault(role),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.danger
                                      .withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.refresh_rounded,
                                color: AppTheme.danger, size: 12),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _openRoleThemeEditor(
                            context, l10n, role, theme, roleThemeProvider),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.1),
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
          );
        }),
        Text(
          '${l10n.confirmReset} custom  •  ${l10n.confirmDelete} default',
          style: GoogleFonts.exo2(
            color: AppTheme.textMuted.withValues(alpha: 0.5),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC — OCR / Gemini IA (contenu, encapsulé)
  // ═══════════════════════════════════════════════════════
  Widget _buildGeminiSection(BuildContext context, AppLocalizations l10n) {
    return Consumer<GeminiProvider>(
      builder: (context, gemini, _) {
        return Column(
          children: [
            // Info quota
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🤖', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini 2.0 Flash — Free',
                          style: GoogleFonts.exo2(
                            color: const Color(0xFF4285F4),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '1 500 req/day • 15 req/min',
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
            const SizedBox(height: 16),

            // Tutorial
            _buildGeminiTutorial(l10n),
            const SizedBox(height: 16),

            // Champ clé API
            _GeminiApiKeyField(gemini: gemini, l10n: l10n),
            const SizedBox(height: 12),

            // Toggle Gemini activé
            if (gemini.hasKey) ...[
              GestureDetector(
                onTap: () => gemini.setEnabled(!gemini.isEnabled),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: gemini.isEnabled
                        ? const Color(0xFF4285F4).withValues(alpha: 0.08)
                        : AppTheme.bgPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: gemini.isEnabled
                          ? const Color(0xFF4285F4).withValues(alpha: 0.4)
                          : AppTheme.borderColor,
                      width: gemini.isEnabled ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        gemini.isEnabled
                            ? Icons.psychology_rounded
                            : Icons.psychology_alt_outlined,
                        color: gemini.isEnabled
                            ? const Color(0xFF4285F4)
                            : AppTheme.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gemini.isEnabled
                                  ? '${l10n.geminiTitle} ON'
                                  : '${l10n.geminiTitle} OFF',
                              style: GoogleFonts.exo2(
                                color: gemini.isEnabled
                                    ? Colors.white
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              gemini.isEnabled
                                  ? 'AI Mode — Key: ${gemini.maskedKey}'
                                  : 'Local OCR Mode (ML Kit)',
                              style: GoogleFonts.exo2(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: gemini.isEnabled,
                        onChanged: (v) => gemini.setEnabled(v),
                        activeThumbColor: const Color(0xFF4285F4),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Statut sans clé
            if (!gemini.hasKey)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Without API key, local ML Kit OCR is used',
                        style: GoogleFonts.exo2(
                          color: Colors.orange.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  String _getGeminiSubtitle(AppLocalizations l10n) {
    final code = l10n.locale.languageCode;
    switch (code) {
      case 'fr':
        return 'Utilise Gemini AI pour lire les stats ARK avec une précision supérieure';
      case 'it':
        return 'Usa Gemini AI per leggere le statistiche ARK con precisione superiore';
      case 'es':
        return 'Usa Gemini AI para leer las estadísticas ARK con mayor precisión';
      case 'pt':
        return 'Use o Gemini AI para ler as estatísticas ARK com maior precisão';
      default:
        return 'Use Gemini AI to read ARK stats with superior accuracy';
    }
  }

  Widget _buildGeminiTutorial(AppLocalizations l10n) {
    final code = l10n.locale.languageCode;
    final howToGet = code == 'fr'
        ? 'Comment obtenir une clé API Gemini ?'
        : code == 'it'
            ? 'Come ottenere una chiave API Gemini?'
            : code == 'es'
                ? '¿Cómo obtener una clave API de Gemini?'
                : code == 'pt'
                    ? 'Como obter uma chave API do Gemini?'
                    : 'How to get a Gemini API key?';

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      iconColor: const Color(0xFF4285F4),
      collapsedIconColor: AppTheme.textMuted,
      title: Row(
        children: [
          const Icon(Icons.help_outline_rounded,
              color: Color(0xFF4285F4), size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              howToGet,
              style: GoogleFonts.exo2(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgPrimary,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tutorialStep('1', 'Go to', 'aistudio.google.com', Colors.blue),
              _tutorialStep(
                  '2', 'Sign in with your Google account', '', Colors.green),
              _tutorialStep('3', 'Click', '"Get API key" → "Create API key"',
                  Colors.orange),
              _tutorialStep(
                  '4', 'Copy the key (starts with', '"AIza..."', Colors.purple),
              _tutorialStep(
                  '5',
                  'Paste it in the field below',
                  '→ Dino Manager activates it automatically',
                  Colors.cyan),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '💡 The key is stored locally on your phone, never sent to our servers.',
                  style: GoogleFonts.exo2(
                    color: AppTheme.textSecondary,
                    fontSize: 9,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tutorialStep(
      String num, String text, String highlight, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: GoogleFonts.exo2(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.exo2(
                    color: AppTheme.textSecondary, fontSize: 10, height: 1.3),
                children: [
                  TextSpan(text: text),
                  if (highlight.isNotEmpty) ...[
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: highlight,
                      style: GoogleFonts.exo2(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC — Actualités (contenu, encapsulé)
  // ═══════════════════════════════════════════════════════
  Widget _buildNewsSection(AppLocalizations l10n) {
    final versions = ChangelogData.history;

    return Column(
      children: [
        ...versions.asMap().entries.map((entry) {
          final index = entry.key;
          final version = entry.value;
          final isLast = index == versions.length - 1;
          final totalItems = version.sections
              .fold<int>(0, (sum, s) => sum + s.items.length);
          final isLatest = index == 0;
          final color = isLatest ? Colors.cyanAccent : AppTheme.textMuted;
          final versionEmoji = isLatest ? '🚀' : '📦';
          final latestLabel = l10n.locale.languageCode == 'fr'
              ? 'Dernière'
              : l10n.locale.languageCode == 'it'
                  ? 'Ultima'
                  : l10n.locale.languageCode == 'es'
                      ? 'Última'
                      : l10n.locale.languageCode == 'pt'
                          ? 'Última'
                          : 'Latest';
          final changesLabel = l10n.locale.languageCode == 'fr'
              ? '$totalItems changement${totalItems > 1 ? 's' : ''} au total'
              : l10n.locale.languageCode == 'it'
                  ? '$totalItems modifica${totalItems > 1 ? 'he' : ''} in totale'
                  : l10n.locale.languageCode == 'es'
                      ? '$totalItems cambio${totalItems > 1 ? 's' : ''} en total'
                      : l10n.locale.languageCode == 'pt'
                          ? '$totalItems alteraç${totalItems > 1 ? 'ões' : 'ão'} no total'
                          : '$totalItems change${totalItems > 1 ? 's' : ''} in total';

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
                      border:
                          Border.all(color: color.withValues(alpha: 0.3)),
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  latestLabel,
                                  style: GoogleFonts.exo2(
                                    color: Colors.cyanAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.versionLabel(version.version),
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
                                    style: const TextStyle(fontSize: 11)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${section.type.label} — ${section.items.length}',
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
                          changesLabel,
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
    );
  }

  // ═══════════════════════════════════════════════════════
  // BLOC — Version footer
  // ═══════════════════════════════════════════════════════
  Widget _buildVersionFooter(BuildContext context, AppLocalizations l10n) {
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
          Expanded(
            child: Column(
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
                  '${l10n.versionLabel(current.version)} — ${current.date}',
                  style: GoogleFonts.exo2(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const ChangelogDialog(),
            ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.purpleAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.3)),
              ),
              child: Text(
                l10n.changelogView,
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
  // HELPERS
  // ═══════════════════════════════════════════════════════
  void _openTagColorPicker(
    BuildContext context,
    String tag,
    String? currentHex,
    TagThemeProvider tagThemeProvider,
  ) {
    final currentId =
        currentHex != null ? ArkColorPalette.hexToClosestId(currentHex) : 0;

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
    BuildContext context,
    AppLocalizations l10n,
    TagThemeProvider tagThemeProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.resetConfirmTitle,
            style: GoogleFonts.exo2(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.resetConfirmMessage,
          style: GoogleFonts.exo2(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirmCancel,
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              tagThemeProvider.resetAll();
            },
            child: Text(l10n.confirmReset,
                style: GoogleFonts.exo2(
                    color: AppTheme.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

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
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4),
          ],
        ),
      ),
    );
  }

  void _openRoleThemeEditor(
    BuildContext context,
    AppLocalizations l10n,
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
        l10n: l10n,
        onSave: (theme) => roleThemeProvider.setTheme(role, theme),
      ),
    );
  }

  void _confirmResetAllRoles(
    BuildContext context,
    AppLocalizations l10n,
    RoleThemeProvider roleThemeProvider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.roleThemesConfirmReset,
            style: GoogleFonts.exo2(
                color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          l10n.roleThemesConfirmResetDesc,
          style: GoogleFonts.exo2(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.confirmCancel,
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              roleThemeProvider.resetAll();
            },
            child: Text(l10n.confirmReset,
                style: GoogleFonts.exo2(
                    color: AppTheme.danger, fontWeight: FontWeight.w700)),
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

// ════════════════════════════════════════════════════════════════════════════
// SETTINGS ROW — Ligne de menu directe (tap → action)
// ════════════════════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.exo2(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.exo2(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COLLAPSIBLE SECTION — Encapsulée par défaut, chevron rotatif
// ════════════════════════════════════════════════════════════════════════════
class _CollapsibleSection extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool initiallyExpanded;
  final Widget child;

  const _CollapsibleSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? widget.iconColor.withValues(alpha: 0.3)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          // En-tête cliquable
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Icon(widget.icon,
                      color: widget.iconColor.withValues(alpha: 0.8),
                      size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.exo2(
                        color: widget.iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded,
                        color: AppTheme.textMuted, size: 20),
                  ),
                ],
              ),
            ),
          ),
          // Sous-titre (visible même fermé, sur une ligne)
          if (!_expanded && widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text(
                widget.subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.exo2(color: AppTheme.textMuted, fontSize: 10),
              ),
            ),
          // Contenu
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: widget.child,
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GEMINI API KEY FIELD
// ════════════════════════════════════════════════════════════════════════════
class _GeminiApiKeyField extends StatefulWidget {
  final GeminiProvider gemini;
  final AppLocalizations l10n;

  const _GeminiApiKeyField({required this.gemini, required this.l10n});

  @override
  State<_GeminiApiKeyField> createState() => _GeminiApiKeyFieldState();
}

class _GeminiApiKeyFieldState extends State<_GeminiApiKeyField> {
  late final TextEditingController _ctrl;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.gemini.apiKey);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _ctrl.text.trim();
    if (key == widget.gemini.apiKey) return;

    if (key.isEmpty) {
      await widget.gemini.clearApiKey();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.l10n.errorGeneric),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final ok = await widget.gemini.setApiKey(key);
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(widget.l10n.geminiSuccess,
                  style: GoogleFonts.exo2(fontWeight: FontWeight.w700)),
            ],
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.gemini.validationError ?? widget.l10n.geminiError),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemini = widget.gemini;
    final l10n = widget.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.geminiApiKey.toUpperCase(),
          style: GoogleFonts.exo2(
            color: AppTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgPrimary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: gemini.hasKey
                        ? const Color(0xFF4285F4).withValues(alpha: 0.4)
                        : AppTheme.borderColor,
                    width: gemini.hasKey ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  obscureText: _obscure,
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 12,
                    letterSpacing: _obscure ? 2 : 0,
                  ),
                  decoration: InputDecoration(
                    hintText: 'AIzaSy...',
                    hintStyle:
                        GoogleFonts.exo2(color: AppTheme.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _save(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: gemini.isValidating ? null : _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF4285F4).withValues(alpha: 0.4)),
                ),
                child: gemini.isValidating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4285F4),
                        ),
                      )
                    : Text(
                        l10n.confirmOk,
                        style: GoogleFonts.exo2(
                          color: const Color(0xFF4285F4),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (gemini.hasKey) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () async {
                  _ctrl.clear();
                  await gemini.clearApiKey();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppTheme.danger, size: 18),
                ),
              ),
            ],
          ],
        ),
        if (gemini.validationError != null) ...[
          const SizedBox(height: 6),
          Text(
            gemini.validationError!,
            style: GoogleFonts.exo2(color: AppTheme.danger, fontSize: 10),
          ),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROLE THEME EDITOR SHEET
// ════════════════════════════════════════════════════════════════════════════
class _RoleThemeEditorSheet extends StatefulWidget {
  final String role;
  final RoleTheme currentTheme;
  final AppLocalizations l10n;
  final ValueChanged<RoleTheme> onSave;

  const _RoleThemeEditorSheet({
    required this.role,
    required this.currentTheme,
    required this.l10n,
    required this.onSave,
  });

  @override
  State<_RoleThemeEditorSheet> createState() => _RoleThemeEditorSheetState();
}

class _RoleThemeEditorSheetState extends State<_RoleThemeEditorSheet> {
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
      case 0:
        return _background;
      case 1:
        return _border;
      default:
        return _text;
    }
  }

  void _setActiveColor(Color color) {
    setState(() {
      switch (_activeSlot) {
        case 0:
          _background = color;
          break;
        case 1:
          _border = color;
          break;
        default:
          _text = color;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.78,
      decoration: const BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
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
                Expanded(
                  child: Text(
                    '${l10n.roleThemesPreview} — ${widget.role}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.exo2(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _border.withValues(alpha: 0.7), width: 1.5),
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
                _buildSlotButton(0, _background, l10n.roleThemesBackground),
                const SizedBox(width: 10),
                _buildSlotButton(1, _border, l10n.roleThemesBorder),
                const SizedBox(width: 10),
                _buildSlotButton(2, _text, l10n.roleThemesText),
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
            padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      foregroundColor: AppTheme.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.roleThemesCancel,
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w600)),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(l10n.roleThemesApply,
                        style: GoogleFonts.exo2(fontWeight: FontWeight.w800)),
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
            color: isActive ? color.withValues(alpha: 0.2) : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive ? color.withValues(alpha: 0.7) : AppTheme.borderColor,
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
                      color: Colors.white.withValues(alpha: 0.3), width: 1),
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
                  color: isActive ? color : AppTheme.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ARK COLOR GRID
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
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 600 ? 12 : 8;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
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
                  const Icon(Icons.check, color: Colors.white, size: 10),
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
