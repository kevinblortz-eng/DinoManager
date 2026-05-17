// lib/screens/orders_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';
import '../theme/app_theme.dart';
import 'order_create_edit_screen.dart';
import '../providers/currency_provider.dart';
import '../models/currency.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent';
  bool _showCompleted = false;

  // ── Chemin de l'image de fond fixe ────────────────────────────────────────
  // À déclarer dans pubspec.yaml : assets/images/ui/background_cmd.png
  static const String _bgAsset = 'assets/images/ui/background_cmd.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
      _loadPreferences();
    });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showCompleted = prefs.getBool('orders_show_completed') ?? false;
      _sortBy = prefs.getString('orders_sort_by') ?? 'recent';
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('orders_show_completed', _showCompleted);
    await prefs.setString('orders_sort_by', _sortBy);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor transparent : le Stack gère le fond
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── FOND FIXE — ne bouge PAS quand on scrolle ─────────────────────
          // Positioned.fill + Image.asset avec BoxFit.cover couvre toute la
          // page. Comme il est en dehors du ListView, il reste immobile.
          Positioned.fill(
            child: Image.asset(
              _bgAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.bgPrimary,
              ),
            ),
          ),

          // ── OVERLAY sombre pour lisibilité ────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xCC050810), // haut : très sombre
                    Color(0xAA050810), // milieu : semi-transparent
                    Color(0xCC050810), // bas : très sombre
                  ],
                ),
              ),
            ),
          ),

          // ── CONTENU par-dessus le fond ─────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                Expanded(child: _buildOrdersList()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final provider = context.read<OrderProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const OrderCreateEditScreen()),
          );
          if (!mounted) return;
          provider.loadOrders();
        },
        backgroundColor: AppTheme.accentPrimary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        // ✅ Commande terminée = progressionRatio >= 0.99 OU status completed/validated
        // Dans _buildHeader (Consumer builder), remplace inProgress/completed par :
final inProgress = provider.orders
    .where((o) =>
        o.status != OrderStatus.completed &&
        o.status != OrderStatus.validated)
    .length;
final completed = provider.orders
    .where((o) =>
        o.status == OrderStatus.completed ||
        o.status == OrderStatus.validated)
    .length;


        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMANDES',
                      style: GoogleFonts.cinzelDecorative(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                              color: Colors.black,
                              blurRadius: 8,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildHeaderStat(
                          '$inProgress',
                          'en cours',
                          Colors.orangeAccent,
                        ),
                        const SizedBox(width: 12),
                        _buildHeaderStat(
                          '$completed',
                          'terminées',
                          AppTheme.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderStat(String count, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          count,
          style: GoogleFonts.exo2(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.exo2(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SEARCH + FILTER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSearchAndFilter() {
    return Container(
      // Fond semi-transparent pour que la searchbar reste lisible
      color: Colors.black.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF21304A), width: 1.2),
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.exo2(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: GoogleFonts.exo2(
                      color: const Color(0xFF4A5568), fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF4A5568), size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Color(0xFF4A5568), size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 4),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showFilterSheet(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (_showCompleted || _sortBy != 'recent')
                    ? AppTheme.accentPrimary.withValues(alpha: 0.2)
                    : const Color(0xFF161B22).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_showCompleted || _sortBy != 'recent')
                      ? AppTheme.accentPrimary.withValues(alpha: 0.5)
                      : const Color(0xFF21304A),
                  width: 1.2,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: (_showCompleted || _sortBy != 'recent')
                    ? AppTheme.accentPrimary
                    : const Color(0xFF4A5568),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOrdersList() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    color: AppTheme.accentPrimary,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Chargement...',
                    style: GoogleFonts.exo2(
                        color: const Color(0xFF4A5568), fontSize: 13)),
              ],
            ),
          );
        }

        var filtered = provider.orders.where((order) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!order.name.toLowerCase().contains(q) &&
                !order.clientName.toLowerCase().contains(q)) {
              return false;
            }
          }
          // ✅ Commande terminée = ratio >= 0.99 OU status completed/validated
          final isCompleted = order.status == OrderStatus.completed ||
    order.status == OrderStatus.validated;
if (!_showCompleted && isCompleted) {
  return false;
}
          return true;
        }).toList();

        if (_sortBy == 'recent') {
          filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        } else {
          filtered.sort((a, b) {
            final statusOrder = {
              OrderStatus.created: 0,
              OrderStatus.inProgress: 1,
              OrderStatus.completed: 2,
              OrderStatus.validated: 3,
            };
            return (statusOrder[a.status] ?? 0)
                .compareTo(statusOrder[b.status] ?? 0);
          });
        }

        if (filtered.isEmpty) {
          return _buildEmptyState(
              _searchQuery.isNotEmpty || _showCompleted);
        }

        final bottomPadding = MediaQuery.of(context).padding.bottom;

        return RefreshIndicator(
          color: AppTheme.accentPrimary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => provider.loadOrders(),
          child: ListView.builder(
            // ✅ physics normal : le ListView scrolle mais le fond Stack
            // reste fixe car il est en dehors du scroll.
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(14, 8, 14, 100 + bottomPadding),
            itemCount: filtered.length,
            itemBuilder: (context, i) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: _buildOrderCard(context, provider, filtered[i]),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CARTE COMMANDE
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // CARTE COMMANDE — version retravaillée
  //
  // Règles :
  //   - "Prête" = progressionRatio >= 0.99 mais PAS encore validée.
  //     → badge "PRÊTE", anneau plein doré, bouton ✓ au centre du cercle.
  //   - "Terminée" = status validated (ou completed).
  //     → badge "VALIDÉE", anneau plein vert, trophée au centre.
  //   - Sinon → progression normale + % au centre.
  //
  // Mise en page :
  //   Ligne 1 : Nom · NbDinos                            Date
  //   Ligne 2 : Prix + monnaie                           Statut
  //   Barre fine de progression en bas.
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildOrderCard(
      BuildContext context, OrderProvider provider, Order order) {
    final ratio = order.progressionRatio.clamp(0.0, 1.0);
    final pct = (ratio * 100).round();

    final bool isValidated = order.status == OrderStatus.completed ||
        order.status == OrderStatus.validated;
    final bool isReadyToValidate = !isValidated && ratio >= 0.99;

    // Couleur d'accent selon l'état.
    final Color accent = isValidated
        ? AppTheme.success
        : isReadyToValidate
            ? const Color(0xFFFFC107) // doré "prête"
            : ratio > 0.5
                ? Colors.orangeAccent
                : AppTheme.accentPrimary;

    // Total dinos commandés (toutes paires/genres confondus).
    final int totalDinos = order.items.fold<int>(0, (sum, it) {
      // une "paire" = 2 dinos, sinon quantity
      final isPair = it.gender.toString().toLowerCase().contains('les2');
      return sum + (isPair ? it.quantity * 2 : it.quantity);
    });

    final dateStr =
        '${order.createdAt.day.toString().padLeft(2, '0')}-${_monthName(order.createdAt.month).toUpperCase()}-${order.createdAt.year.toString().substring(2)}';

    // Monnaie globale de l'app
    final currency = context.watch<CurrencyProvider>().defaultCurrency;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => OrderCreateEditScreen(order: order)),
        );
        if (!mounted) return;
        provider.loadOrders();
      },
      onLongPress: () => _showOrderOptions(context, provider, order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: isValidated ? 0.14 : 0.08),
              const Color(0xFF111827).withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: accent.withValues(
                alpha: isValidated || isReadyToValidate ? 0.7 : 0.35),
            width: isValidated || isReadyToValidate ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
            BoxShadow(
              color: accent.withValues(
                  alpha: isValidated || isReadyToValidate ? 0.20 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ── Jauge circulaire avec action centrale ────────────────
                  _buildCircularProgress(
                    pct: pct,
                    ratio: ratio,
                    color: accent,
                    isValidated: isValidated,
                    isReadyToValidate: isReadyToValidate,
                    onValidate: () => _confirmValidate(provider, order),
                  ),
                  const SizedBox(width: 14),

                  // ── Bloc texte ───────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ligne 1 : Nom · NbDinos                Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                  children: [
                                    if (isValidated) ...[
                                      const WidgetSpan(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Text('🏆',
                                              style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ] else if (isReadyToValidate) ...[
                                      const WidgetSpan(
                                        child: Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Text('✨',
                                              style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                    TextSpan(
                                      text: order.name.isEmpty
                                          ? '— Sans nom —'
                                          : order.name,
                                      style: GoogleFonts.exo2(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: isValidated
                                            ? AppTheme.success
                                            : Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '  ·  ',
                                      style: GoogleFonts.exo2(
                                        fontSize: 13,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          '$totalDinos dino${totalDinos > 1 ? 's' : ''}',
                                      style: GoogleFonts.exo2(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.10),
                                    width: 1),
                              ),
                              child: Text(
                                dateStr,
                                style: GoogleFonts.exo2(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Ligne 2 : Prix + monnaie               Badge statut
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildPriceChip(order, currency),
                            const Spacer(),
                            _buildStatusBadge(
                              isValidated: isValidated,
                              isReadyToValidate: isReadyToValidate,
                              order: order,
                              accent: accent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Barre fine de progression collée en bas ───────────────────
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIX + MONNAIE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPriceChip(Order order, Currency currency) {
    if (order.computedTotalCost <= 0) {
      return Text(
        '— prix non défini',
        style: GoogleFonts.exo2(
          fontSize: 11,
          color: AppTheme.textMuted,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.accentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            currency.iconPath,
            width: 14,
            height: 14,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.monetization_on_rounded,
              size: 12,
              color: AppTheme.accentPrimary,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _formatPrice(order.computedTotalCost),
            style: GoogleFonts.exo2(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.accentPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            currency.name,
            style: GoogleFonts.exo2(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BADGE STATUT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatusBadge({
    required bool isValidated,
    required bool isReadyToValidate,
    required Order order,
    required Color accent,
  }) {
    final String label;
    if (isValidated) {
      label = '✓ VALIDÉE';
    } else if (isReadyToValidate) {
      label = '✨ PRÊTE';
    } else {
      label = order.status.label.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: accent.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.exo2(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JAUGE CIRCULAIRE — avec bouton ✓ au centre quand "prête à valider"
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCircularProgress({
    required int pct,
    required double ratio,
    required Color color,
    required bool isValidated,
    required bool isReadyToValidate,
    required VoidCallback onValidate,
  }) {
    const double size = 62;

    Widget center;
    if (isValidated) {
      center = const Text('🏆', style: TextStyle(fontSize: 22));
    } else if (isReadyToValidate) {
      // Bouton ✓ tactile au centre — déclenche la validation explicite.
      center = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onValidate,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.check_rounded, color: color, size: 22),
          ),
        ),
      );
    } else {
      center = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$pct',
            style: GoogleFonts.exo2(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          Text(
            '%',
            style: GoogleFonts.exo2(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
              height: 1,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Anneau de fond
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Anneau de progression
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: ratio,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          center,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VALIDATION EXPLICITE DEPUIS LA TUILE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _confirmValidate(
      OrderProvider provider, Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.success, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Valider cette commande ?',
                style: GoogleFonts.exo2(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Text(
          'Tous les dinos sont prêts. Confirmer la validation finale de "${order.name.isEmpty ? '— Sans nom —' : order.name}" ?',
          style: GoogleFonts.exo2(
              color: AppTheme.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.success),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await provider.validateOrder(order.id);
    if (!mounted) return;
    provider.loadOrders();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              hasFilters ? 'Aucune commande trouvée' : 'Aucune commande',
              style: GoogleFonts.cinzelDecorative(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Modifiez vos filtres'
                  : 'Appuyez sur + pour créer votre première commande',
              style: GoogleFonts.exo2(
                  color: const Color(0xFF4A5568), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTER SHEET
  // ═══════════════════════════════════════════════════════════════════════════

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('FILTRES',
                style: GoogleFonts.cinzelDecorative(
                  color: AppTheme.accentSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                )),
            const SizedBox(height: 16),
            Text('Tri',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF6B7A8D),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _filterChip('Récentes', _sortBy == 'recent', () {
                  setState(() => _sortBy = 'recent');
                  _savePreferences();
                  Navigator.pop(context);
                }),
                _filterChip('Par statut', _sortBy == 'status', () {
                  setState(() => _sortBy = 'status');
                  _savePreferences();
                  Navigator.pop(context);
                }),
              ],
            ),
            const SizedBox(height: 16),
            Text('Affichage',
                style: GoogleFonts.exo2(
                  color: const Color(0xFF6B7A8D),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                )),
            const SizedBox(height: 8),
            _filterChip(
              _showCompleted ? 'Avec terminées ✓' : 'Sans terminées',
              _showCompleted,
              () {
                setState(() => _showCompleted = !_showCompleted);
                _savePreferences();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFFFF6B00), Color(0xFFFF9500)])
              : null,
          color: isActive ? null : const Color(0xFF1C2333),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : const Color(0xFF2D3748),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.exo2(
            color: isActive ? Colors.white : const Color(0xFF6B7A8D),
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIONS COMMANDE (long press)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showOrderOptions(
      BuildContext context, OrderProvider provider, Order order) {
    final bool isFinished = order.progressionRatio >= 0.99 ||
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.validated;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isFinished) ...[
                  const Text('👾', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                ],
                Text(
                  order.name.isEmpty ? '— Sans nom —' : order.name,
                  style: GoogleFonts.exo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isFinished ? AppTheme.success : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              order.contentSummary,
              style: GoogleFonts.exo2(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF2D3748), height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_rounded,
                  color: AppTheme.accentPrimary),
              title: Text('Modifier',
                  style: GoogleFonts.exo2(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          OrderCreateEditScreen(order: order)),
                ).then((_) => provider.loadOrders());
              },
            ),
            if (!isFinished && order.status != OrderStatus.validated)
              ListTile(
                leading: const Icon(Icons.check_circle,
                    color: AppTheme.success),
                title: Text('Valider la commande',
                    style: GoogleFonts.exo2(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  provider.validateOrder(order.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded,
                  color: AppTheme.danger),
              title: Text('Supprimer',
                  style: GoogleFonts.exo2(color: AppTheme.danger)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, provider, order);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, OrderProvider provider, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ${order.name} ?',
            style: const TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteOrder(order.id);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  String _monthName(int month) {
    const months = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
      'juil', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.created:
        return Colors.blueGrey;
      case OrderStatus.inProgress:
        return Colors.orangeAccent;
      case OrderStatus.completed:
        return Colors.cyanAccent;
      case OrderStatus.validated:
        return AppTheme.success;
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(1)}k';
    }
    return price.toStringAsFixed(0);
  }
}
