// market_shop_detail_screen.dart — Détail d'un shop : listings cryo.
// Gestes : swipe droite = supprimer · swipe gauche = vendu (puis re-swipe
// gauche sur un vendu = remise en vente, nouveau cycle 30 j).
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/market.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_picker_sheet.dart';
import 'market_shop_edit_screen.dart';

class MarketShopDetailScreen extends StatefulWidget {
  final String shopId;
  const MarketShopDetailScreen({super.key, required this.shopId});

  @override
  State<MarketShopDetailScreen> createState() => _MarketShopDetailScreenState();
}

class _MarketShopDetailScreenState extends State<MarketShopDetailScreen> {
  void _confirmDelete(MarketListing listing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2333),
        title: const Text('Supprimer le dino ?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text(
          '${listing.espece} sera retiré du suivi définitivement.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<MarketProvider>().deleteListing(listing.id);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _openEditSheet(MarketListing listing) {
    final priceCtrl =
        TextEditingController(text: listing.price.toStringAsFixed(0));
    // Valeurs de travail locales : les modifications ne sont écrites que
    // sur "Enregistrer" et le StatefulBuilder les rebuild correctement.
    DateTime deadline = listing.deadline;
    ListingType editType = listing.type;
    ListingSexe editSexe = listing.sexe;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C2333),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modifier le listing',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Prix (hexagones)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                  prefixIcon: Icon(Icons.hexagon_outlined,
                      color: AppTheme.accentPrimary),
                ),
              ),
              const SizedBox(height: 12),
              // ── Type + Sexe ──────────────────────────────────────
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<ListingType>(
                    initialValue: listing.type,
                    dropdownColor: const Color(0xFF1C2333),
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: ListingType.values
                        .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label,
                                style:
                                    const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => editType = v ?? editType),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<ListingSexe>(
                    initialValue: listing.sexe,
                    dropdownColor: const Color(0xFF1C2333),
                    decoration: const InputDecoration(
                      labelText: 'Sexe',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: ListingSexe.values
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label,
                                style:
                                    const TextStyle(color: Colors.white))))
                        .toList(),
                    onChanged: (v) =>
                        setSheetState(() => editSexe = v ?? editSexe),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // ── Deadline ─────────────────────────────────────────
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: deadline,
                    firstDate: DateTime.now().subtract(const Duration(days: 60)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setSheetState(() => deadline = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white24),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(children: [
                    const Icon(Icons.timer_outlined,
                        color: AppTheme.accentPrimary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Dépop : ${deadline.day}/${deadline.month}/${deadline.year}'
                      '  (${deadline.difference(DateTime.now()).inDays} j)',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    const Icon(Icons.edit_calendar_outlined,
                        color: Colors.white38, size: 18),
                  ]),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary),
                  onPressed: () {
                    listing.price =
                        double.tryParse(priceCtrl.text.replaceAll(',', '.')) ??
                            listing.price;
                    listing.deadline = deadline;
                    listing.type = editType;
                    listing.sexe = editSexe;
                    context.read<MarketProvider>().updateListing(listing);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Enregistrer',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddSheet() {
    final market = context.read<MarketProvider>();
    final shop = market.shopById(widget.shopId);
    if (shop == null) return;

    final picked = <DinoLite>[];
    final especeCtrl = TextEditingController();
    final nomCtrl = TextEditingController();
    final priceCtrl =
        TextEditingController(text: shop.defaultPrice.toStringAsFixed(0));
    var type = shop.defaultType;
    var sexe = shop.defaultSexe;
    var quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C2333),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Déposer un dino dans le shop',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),

                // ── Accès bibliothèque (comme les commandes) ──────────
                Material(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final result = await DinoPickerSheet.show(ctx);
                      if (result.isNotEmpty) {
                        setSheetState(() {
                          picked.clear();
                          picked.addAll(
                              result.map((d) => DinoLite.fromDino(d)));
                        });
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.accentPrimary
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.library_books_outlined,
                            color: AppTheme.accentPrimary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            picked.isEmpty
                                ? 'Choisir depuis ma bibliothèque'
                                : '${picked.length} dino${picked.length > 1 ? 's' : ''} sélectionné${picked.length > 1 ? 's' : ''}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (picked.isNotEmpty)
                          GestureDetector(
                            onTap: () => setSheetState(() => picked.clear()),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white54, size: 18),
                          )
                        else
                          const Icon(Icons.chevron_right,
                              color: Colors.white38),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                    child: Text('— ou saisie manuelle —',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 10.5))),
                const SizedBox(height: 6),
                TextField(
                  controller: especeCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Espèce (ex. Rex, Wyvern…)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nomCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Nom / lignée (optionnel)',
                    labelStyle: TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Prix (hexagones)',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(8),
                          child: _HexIcon(size: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(children: [
                      IconButton(
                        icon: const Icon(Icons.remove,
                            color: Colors.white70, size: 18),
                        onPressed: () => setSheetState(
                            () => quantity = (quantity > 1) ? quantity - 1 : 1),
                      ),
                      Text('$quantity',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800)),
                      IconButton(
                        icon: const Icon(Icons.add,
                            color: Colors.white70, size: 18),
                        onPressed: () => setSheetState(
                            () => quantity = (quantity < 99) ? quantity + 1 : 99),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<ListingType>(
                      value: type == ListingType.aucun ? null : type,
                      hint: const Text('Aucun',
                          style: TextStyle(color: Colors.white38)),
                      dropdownColor: const Color(0xFF1C2333),
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      items: ListingType.values
                          .where((t) => t != ListingType.aucun)
                          .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label,
                                  style:
                                      const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setSheetState(() => type = v ?? type),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<ListingSexe>(
                      value: sexe,
                      dropdownColor: const Color(0xFF1C2333),
                      decoration: const InputDecoration(
                        labelText: 'Sexe',
                        labelStyle: TextStyle(color: Colors.white54),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                      ),
                      items: ListingSexe.values
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.label,
                                  style: const TextStyle(color: Colors.white))))
                          .toList(),
                      onChanged: (v) => setSheetState(() => sexe = v ?? sexe),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Timer cryo : ${ListingTypeExt.defaultDurationDaysFor(type)} jours'
                  ' à partir du dépôt (modifiable plus tard).',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11.5),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary),
                    onPressed: () {
                      final price = double.tryParse(
                              priceCtrl.text.replaceAll(',', '.')) ??
                          shop.defaultPrice;
                      // 1) Dinos de la bibliothèque : 1 listing par dino
                      if (picked.isNotEmpty) {
                        context.read<MarketProvider>().addListingsFromDinos(
                              shop.id,
                              picked,
                              price: price,
                              type: type,
                            );
                      }
                      // 2) Saisie manuelle (compatible avec les 2 en même temps)
                      final espece = especeCtrl.text.trim();
                      if (espece.isNotEmpty) {
                        context.read<MarketProvider>().addListing(
                              MarketListing(
                                shopId: shop.id,
                                espece: espece,
                                nom: nomCtrl.text.trim(),
                                type: type,
                                sexe: sexe,
                                price: price,
                              ),
                              quantity: quantity,
                            );
                      }
                      if (picked.isNotEmpty || espece.isNotEmpty) {
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Déposer',
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _deadlineColor(int days) {
    if (days <= 0) return const Color(0xFFEF4444);
    if (days <= 4) return const Color(0xFFFF9800);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final shop = market.shopById(widget.shopId);

    if (shop == null) {
      return const Scaffold(
        backgroundColor: AppTheme.bgPrimary,
        body: Center(child: Text('Shop introuvable',
            style: TextStyle(color: Colors.white54))),
      );
    }

    final color = Color(shop.colorValue);
    final actives = market.activeListings(shop.id);
    final solds = market.soldListings(shop.id);

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(shop.name, style: TextStyle(color: color)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MarketShopEditScreen(shop: shop)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppTheme.accentPrimary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Déposer',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ── Résumé du shop ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${actives.length}', 'en vente'),
                _stat(
                    '${market.shopTotalValue(shop.id).toStringAsFixed(0)} ⬡',
                    'valeur totale'),
                _stat('${solds.length}', 'vendus'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── En vente ──────────────────────────────────────────────
          if (actives.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun dino en vente.\nUtilise « Déposer ».',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.5)),
            )
          else
            ...actives.map((l) => _buildTile(context, market, l, color)),

          // ── Vendus (trace) ────────────────────────────────────────
          if (solds.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Vendus (${solds.length}) — swipe ← pour remettre en vente',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...solds.map((l) => _buildTile(context, market, l, color)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );

  Widget _buildTile(BuildContext context, MarketProvider market,
      MarketListing listing, Color shopColor) {
    final now = DateTime.now();
    final days = listing.remainingDays(now);
    final isSold = listing.status == ListingStatus.vendu;
    final typeColor = switch (listing.type) {
      ListingType.aucun => Colors.white38,
      ListingType.oeuf => const Color(0xFF8BC34A),
      ListingType.bebe => const Color(0xFF4FC3F7),
      ListingType.clone => const Color(0xFFAB47BC),
      ListingType.adulte => const Color(0xFFFFB300),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(listing.id),
        // ── Swipe droite → SUPPRIMER (confirmé) ──────────────────
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF7F1D1D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        // ── Swipe gauche → VENDU / REMETTRE EN VENTE ─────────────
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: isSold ? const Color(0xFF1B5E20) : const Color(0xFF14532D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isSold ? Icons.restart_alt : Icons.sell_outlined,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            _confirmDelete(listing);
            return false; // suppression décidée dans le dialog
          }
          // Gauche : vendu ↔ remise en vente (pas de confirmation)
          if (isSold) {
            market.relist(listing.id);
          } else {
            market.markSold(listing.id);
          }
          return false; // on garde la tuile (état géré par le provider)
        },
        child: Opacity(
          opacity: isSold ? 0.55 : 1,
          child: Material(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openEditSheet(listing),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  // ── Prix hexagones ──────────────────────────────
                  Container(
                    width: 58,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              AppTheme.accentPrimary.withValues(alpha: 0.4)),
                    ),
                    child: Column(children: [
                      const _HexIcon(size: 16),
                      Text(
                        listing.price.toStringAsFixed(0),
                        style: const TextStyle(
                            color: AppTheme.accentPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  // ── Infos dino ──────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.nom.isNotEmpty
                              ? '${listing.espece} — ${listing.nom}'
                              : listing.espece,
                          style: TextStyle(
                            color: isSold ? Colors.white38 : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            decoration:
                                isSold ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          _badge(listing.type.label, typeColor),
                          const SizedBox(width: 5),
                          if (listing.sexe != ListingSexe.indefini) ...[
                            _badge(listing.sexe.label, Colors.white54),
                            const SizedBox(width: 5),
                          ],
                          if (listing.timesSold > 0)
                            Text('×${listing.timesSold} ventes',
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10.5)),
                        ]),
                      ],
                    ),
                  ),
                  // ── Deadline / statut ───────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isSold)
                        const Text('VENDU',
                            style: TextStyle(
                                color: Color(0xFF4ADE80),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.5))
                      else ...[
                        Text(
                          days <= 0 ? 'EXPIRÉ' : '$days j',
                          style: TextStyle(
                            color: _deadlineColor(days),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${listing.deadline.day}/${listing.deadline.month}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10.5),
                        ),
                      ],
                      if (isSold && listing.soldAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                            '${listing.soldAt!.day}/${listing.soldAt!.month}',
                            style: const TextStyle(
                                color: Colors.white24, fontSize: 10)),
                      ],
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.w800)),
      );
}

/// Icône hexagone du jeu (assets/icons/currencies/Hex.png),
/// avec fallback sur l'icône Material si l'asset est absent.
class _HexIcon extends StatelessWidget {
  final double size;
  const _HexIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/currencies/Hex.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.hexagon, color: AppTheme.accentPrimary, size: size),
    );
  }
}
