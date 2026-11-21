// market_screen.dart — Hub Market : commandes directes + suivi des shops.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/market_provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';
import 'market_shop_detail_screen.dart';
import 'market_shop_edit_screen.dart';
import 'orders_screen.dart';

class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final expiring = market.expiringSoon();

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Market & Commandes'),
        backgroundColor: Colors.transparent,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MarketShopEditScreen(),
          ),
        ),
        backgroundColor: AppTheme.accentPrimary,
        icon: const Icon(Icons.add_business_outlined, color: Colors.black),
        label: const Text('Nouveau shop',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: market.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                // ── Alerte cryos bientôt dépopées ────────────────────────
                if (expiring.isNotEmpty) _buildAlertBanner(context, expiring),

                // ── Accès commandes directes ─────────────────────────────
                _buildOrdersEntry(context),
                const SizedBox(height: 20),

                // ── Liste des shops ──────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined,
                        size: 18, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      'Mes shops (${market.shops.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (market.shops.isEmpty)
                  _buildEmptyShops()
                else
                  ...market.shops
                      .map((shop) => _buildShopCard(context, market, shop)),
              ],
            ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, dynamic expiring) {
    final count = expiring.length as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFF9800).withValues(alpha: 0.14),
                  const Color(0xFF161B22),
                ],
              ),
              border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.55),
                  width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFFB300), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count cryo${count > 1 ? 's' : ''} bientôt dépopé${count > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFFFCC80),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        '≤ 4 j restants — à récupérer au shop !',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersEntry(BuildContext context) {
    return Material(
      color: const Color(0xFF161B22),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppTheme.accentPrimary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Suivre mes commandes',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15)),
                    SizedBox(height: 2),
                    Text('Commandes directes des joueurs',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
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

  Widget _buildEmptyShops() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Column(
        children: [
          Icon(Icons.store_mall_directory_outlined,
              color: Colors.white24, size: 40),
          SizedBox(height: 10),
          Text(
            'Aucun shop pour le moment.\nCrée ton premier shop pour suivre\n'
            'tes dinos en vente (hexagones + cryo 30 j).',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38, fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildShopCard(
      BuildContext context, MarketProvider market, dynamic shop) {
    final actives = market.activeListings(shop.id as String);
    final minDays = market.minRemainingDays(shop.id as String);
    final hasAlert = actives.any((l) => l.isExpiringSoon(DateTime.now()));
    final color = Color(shop.colorValue as int);
    // Monnaie globale de l'app : icône Hexagon (ou autre) réelle partout.
    final currency = context.watch<CurrencyProvider>().defaultCurrency;
    final totalValue = actives.fold<double>(0, (s, l) => s + l.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MarketShopDetailScreen(shopId: shop.id as String),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasAlert
                    ? const Color(0xFFFF9800).withValues(alpha: 0.6)
                    : color.withValues(alpha: 0.35),
                width: hasAlert ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                // ── Image du shop (asset fourni par l'utilisateur) ──
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 52,
                    height: 52,
                    color: color.withValues(alpha: 0.18),
                    child: Image.asset(
                      'assets/images/shop.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.hexagon_outlined,
                        color: color,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name as String,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '${actives.length} dino${actives.length > 1 ? 's' : ''} en vente',
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 12),
                          ),
                          if (actives.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Image.asset(
                              currency.iconPath,
                              width: 13,
                              height: 13,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.hexagon,
                                  size: 13,
                                  color: AppTheme.accentPrimary),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              totalValue.toStringAsFixed(0),
                              style: const TextStyle(
                                  color: AppTheme.accentPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        minDays == null
                            ? 'Shop vide'
                            : minDays <= 0
                                ? '⚠ Cryo expirée dans le shop !'
                                : 'Dépop min. dans $minDays j',
                        style: TextStyle(
                          color: minDays == null
                              ? Colors.white38
                              : minDays <= 0
                                  ? const Color(0xFFEF4444)
                                  : minDays <= 4
                                      ? const Color(0xFFFF9800)
                                      : Colors.white54,
                          fontSize: 11.5,
                          fontWeight: minDays != null && minDays <= 4
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white38, size: 20),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarketShopEditScreen(shop: shop),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
