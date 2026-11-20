// lib/screens/home_screen.dart — v2 "vitrine"
// Home courte et adaptative : bannière + alerte shop conditionnelle + astuce
// (affichée max 1×/jour, ancrée en bas). La navigation reste dans la barre
// du bas ; les stats vivront dans un espace dédié à venir.

import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/dino_provider.dart';
import '../providers/market_provider.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'market_screen.dart';
import 'setting_screen.dart';

class HomeScreen extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateToTab;

  const HomeScreen({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Fond fixe de la home ───────────────────────────────────────────────
  static const String _bgAsset = 'assets/images/ui/background_home.png';
  static const String _tipDayKey = 'home_tip_last_day';

  String _todayTip = '';
  bool _showTipToday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<DinoProvider>().loadDinos();
      _loadTipVisibility();
    });
  }

  /// Astuce : max 1×/jour. On stocke le dernier jour d'affichage ;
  /// un nouveau jour → nouvelle astuce (rotation), sinon rien.
  Future<void> _loadTipVisibility() async {
    final l10n = AppLocalizations.of(context);
    // Sécurité : si les localisations ne sont pas encore prêtes,
    // pas d'astuce ce cycle (retry au prochain build/postFrame).
    if (l10n == null) return;
    final tips = l10n.homeTips;
    final today = DateTime.now();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final prefs = await SharedPreferences.getInstance();
    final lastDay = prefs.getString(_tipDayKey);
    final shouldShow = lastDay != dayKey;

    setState(() {
      _todayTip = tips[today.millisecondsSinceEpoch ~/ 86400000 % tips.length];
      _showTipToday = shouldShow;
    });

    if (shouldShow) await prefs.setString(_tipDayKey, dayKey);
  }

  void _dismissTipToday() {
    setState(() => _showTipToday = false);
    final today = DateTime.now();
    final dayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    SharedPreferences.getInstance()
        .then((p) => p.setString(_tipDayKey, dayKey));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DinoProvider, MarketProvider>(
      builder: (context, dinoProvider, marketProvider, _) {
        final expiring = marketProvider.expiringSoon();
        final shortest = expiring.isNotEmpty ? expiring.first : null;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // ── FOND FIXE ──────────────────────────────────────────
              Positioned.fill(
                child: Image.asset(
                  _bgAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppTheme.bgPrimary),
                ),
              ),
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),

              // ── CONTENU ────────────────────────────────────────────
              Positioned.fill(
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      final contentWidth =
                          isWide ? 560.0 : constraints.maxWidth;
                      // Hauteurs max logiques : l'écran ne s'allonge pas,
                      // les blocs plafonnent (adaptatif mobile/tablette).
                      final alertMax = isWide ? 96.0 : 88.0;
                      final tipMax = isWide ? 150.0 : 130.0;

                      return Center(
                        child: ConstrainedBox(
                          constraints:
                              BoxConstraints(maxWidth: contentWidth),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 24 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── BANNIÈRE ────────────────────────
                                _buildHeader(isWide: isWide),

                                // ── ALERTE SHOP (conditionnelle) ────
                                if (shortest != null) ...[
                                  const SizedBox(height: 12),
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxHeight: alertMax),
                                    child: _buildMarketAlert(
                                        shortest, isWide: isWide),
                                  ),
                                ],

                                const Spacer(),

                                // ── ASTUCE (bas, max 1×/jour) ───────
                                if (_showTipToday)
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxHeight: tipMax),
                                    child: _buildTipCard(isWide: isWide),
                                  ),
                                SizedBox(
                                    height: MediaQuery.of(context)
                                        .padding
                                        .bottom),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BANNIÈRE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHeader({required bool isWide}) {
    final titleSize = isWide ? 30.0 : 24.0;
    final subSize = isWide ? 14.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ARK MANAGER',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gestionnaire de dinosaures',
                  style: GoogleFonts.exo2(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: subSize,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingScreen()),
            ),
            icon: const Icon(Icons.settings_outlined,
                color: Colors.white70, size: 26),
            tooltip: 'Paramètres',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ALERTE SHOP — cryo(s) proche(s) du dépop
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildMarketAlert(dynamic shortest, {required bool isWide}) {
    final days = shortest.remainingDays(DateTime.now()) as int;
    final urgent = days <= 0;
    final color = urgent ? const Color(0xFFEF4444) : const Color(0xFFFF9800);
    final count = context.read<MarketProvider>().expiringSoon().length;

    final label = urgent
        ? 'Cryo expirée — à récupérer !'
        : 'Dépop dans $days j — à récupérer';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Le market est l'onglet 4 → bascule de tab, pas de push.
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(4);
          } else {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MarketScreen()));
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      count > 1
                          ? '$count cryos bientôt dépopées'
                          : label,
                      style: GoogleFonts.exo2(
                        color: color,
                        fontSize: isWide ? 14 : 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shortest.espece} · ${shortest.nom.isNotEmpty ? shortest.nom + ' · ' : ''}Market',
                      style: GoogleFonts.exo2(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: isWide ? 12 : 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ASTUCE — bas d'écran, max 1×/jour, masquable
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildTipCard({required bool isWide}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: Colors.cyanAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded,
              color: Colors.cyanAccent.withValues(alpha: 0.6),
              size: isWide ? 20 : 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ASTUCE',
                  style: GoogleFonts.exo2(
                    color: Colors.cyanAccent.withValues(alpha: 0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayTip,
                  style: GoogleFonts.exo2(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: isWide ? 12.5 : 11,
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded,
                color: Colors.white24, size: 16),
            onPressed: _dismissTipToday,
            tooltip: 'Masquer',
          ),
        ],
      ),
    );
  }
}
