// market_shop_detail_screen.dart — Détail d'un shop : listings cryo.
// Style tuile proche des commandes : image dino + couleurs, espèce + nom,
// prix (monnaie globale), timer dépop modifiable unitairement.
// Gestes : double-tap = DUPLIQUER · appui long = MODIFIER
//          swipe ← = supprimer (dialog) · swipe → = vendu (re-swipe → = remise en vente).
// NOTE : aucun DropdownButtonFormField — Flutter 3.50 a cassé la sélection
// interne des dropdowns (value: déprécié = sémantique initialValue:).
// Tous les choix Type/Sexe passent par des chips à choix direct.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/market.dart';
import '../providers/market_provider.dart';
import '../providers/dino_provider.dart';
import '../providers/currency_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_picker_sheet.dart';
import '../widgets/dino_image_widget.dart';
import 'market_shop_edit_screen.dart';

class MarketShopDetailScreen extends StatefulWidget {
  final String shopId;
  const MarketShopDetailScreen({super.key, required this.shopId});

  @override
  State<MarketShopDetailScreen> createState() => _MarketShopDetailScreenState();
}

class _MarketShopDetailScreenState extends State<MarketShopDetailScreen> {
  // ═══════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════

  void _confirmDelete(MarketListing listing) {
    // Capture du provider AVANT le dialog : aucune dépendance au context
    // à l'intérieur du builder (immunisé aux async gaps).
    final market = context.read<MarketProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le dino ?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: Text(
          '${listing.espece} sera retiré du shop définitivement.',
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
              market.deleteListing(listing.id);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  void _duplicate(MarketListing listing) {
    final market = context.read<MarketProvider>();
    market.duplicateListing(listing.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${listing.espece} dupliqué — nouveau timer démarré.'),
        backgroundColor: AppTheme.bgCard,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CHIPS — Type / Sexe (remplace les dropdowns cassés)
  // ═══════════════════════════════════════════════════════

  Widget _typeChips(ListingType current, void Function(ListingType) onSelect) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ListingType.values.where((t) => t != ListingType.aucun).map((t) {
        final active = t == current;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                  : AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? AppTheme.accentPrimary
                    : Colors.white24,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              t.label,
              style: TextStyle(
                color: active ? AppTheme.accentPrimary : Colors.white70,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sexeChips(ListingSexe current, void Function(ListingSexe) onSelect) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ListingSexe.values.map((s) {
        final active = s == current;
        return GestureDetector(
          onTap: () => onSelect(s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? Colors.cyanAccent.withValues(alpha: 0.15)
                  : AppTheme.bgPrimary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? Colors.cyanAccent : Colors.white24,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Text(
              s.label,
              style: TextStyle(
                color: active ? Colors.cyanAccent : Colors.white70,
                fontSize: 12.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SHEET — Modifier un listing (prix, type, sexe, timer)
  // ═══════════════════════════════════════════════════════
  void _openEditSheet(MarketListing listing) {
    final market = context.read<MarketProvider>();
    final currency = context.read<CurrencyProvider>().defaultCurrency;
    final priceCtrl =
        TextEditingController(text: listing.price.toStringAsFixed(0));
    // Valeurs de travail locales : les modifications ne sont écrites que
    // sur "Enregistrer".
    DateTime deadline = listing.deadline;
    ListingType editType = listing.type;
    ListingSexe editSexe = listing.sexe;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: SingleChildScrollView(
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
                // ── Prix ──────────────────────────────────────────
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Prix (${currency.name})',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white24)),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _CurrencyIcon(
                          iconPath: currency.iconPath, size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Type (chips — pas de dropdown) ─────────────────
                const Text('Type',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                _typeChips(editType,
                    (t) => setSheetState(() => editType = t)),
                const SizedBox(height: 16),
                // ── Sexe (chips — pas de dropdown) ─────────────────
                const Text('Sexe',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                _sexeChips(editSexe,
                    (s) => setSheetState(() => editSexe = s)),
                const SizedBox(height: 16),
                // ── Deadline (modifiable unitairement) ─────────────
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetCtx,
                      initialDate: deadline,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 60)),
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
                      listing.price = double.tryParse(
                              priceCtrl.text.replaceAll(',', '.')) ??
                          listing.price;
                      listing.deadline = deadline;
                      listing.type = editType;
                      listing.sexe = editSexe;
                      market.updateListing(listing);
                      Navigator.pop(sheetCtx);
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SHEET — Déposer (bibliothèque ou saisie manuelle)
  // ═══════════════════════════════════════════════════════
  void _openAddSheet() {
    final market = context.read<MarketProvider>();
    final currency = context.read<CurrencyProvider>().defaultCurrency;
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
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(sheetCtx).viewInsets.bottom),
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
                      // Contexte de l'ÉCRAN (pas de la sheet) : le picker
                      // s'ouvre par-dessus, retour via setSheetState.
                      final result = await DinoPickerSheet.show(context);
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
                      decoration: InputDecoration(
                        labelText: 'Prix (${currency.name})',
                        labelStyle: const TextStyle(color: Colors.white54),
                        enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24)),
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(8),
                          child: _CurrencyIcon(
                              iconPath: currency.iconPath, size: 20),
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
                const SizedBox(height: 14),
                // ── Type (chips) ────────────────────────────────────
                const Text('Type',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                _typeChips(type, (t) => setSheetState(() => type = t)),
                const SizedBox(height: 14),
                // ── Sexe (chips) ────────────────────────────────────
                const Text('Sexe',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                _sexeChips(sexe, (s) => setSheetState(() => sexe = s)),
                const SizedBox(height: 8),
                Text(
                  'Timer cryo : ${ListingTypeExt.defaultDurationDaysFor(type)} jours'
                  ' à partir du dépôt (modifiable par tuile ensuite).',
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
                        market.addListingsFromDinos(
                              shop.id,
                              picked,
                              price: price,
                              type: type,
                            );
                      }
                      // 2) Saisie manuelle (compatible avec les 2 en même temps)
                      final espece = especeCtrl.text.trim();
                      if (espece.isNotEmpty) {
                        market.addListing(
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
                        Navigator.pop(sheetCtx);
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

  // ═══════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════

  Color _deadlineColor(int days) {
    if (days <= 0) return const Color(0xFFEF4444);
    if (days <= 4) return const Color(0xFFFF9800);
    return Colors.white54;
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketProvider>();
    final currency = context.watch<CurrencyProvider>().defaultCurrency;
    final dinoProvider = context.watch<DinoProvider>();
    // Index id → dino pour l'affichage image + couleurs sur les tuiles.
    final dinoById = <int, dynamic>{
      for (final d in dinoProvider.allDinos)
        if (d.id != null) d.id!: d,
    };

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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.10),
                  AppTheme.bgSecondary,
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('${actives.length}', 'en vente'),
                _currencyStat(
                  market.shopTotalValue(shop.id).toStringAsFixed(0),
                  'valeur totale',
                  currency.iconPath,
                ),
                _stat('${solds.length}', 'vendus'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ── Aide gestes ───────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Double-tap : dupliquer · Appui long : modifier · ← supprimer · → vendu',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white24, fontSize: 10.5),
            ),
          ),
          const SizedBox(height: 6),

          // ── En vente ──────────────────────────────────────────────
          if (actives.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Aucun dino en vente.\nUtilise « Déposer ».',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, height: 1.5)),
            )
          else
            ...actives.map((l) => _buildTile(
                context, market, l, color, currency.iconPath, dinoById)),

          // ── Vendus (trace) ────────────────────────────────────────
          if (solds.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text('Vendus (${solds.length}) — swipe → pour remettre en vente',
                style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...solds.map((l) => _buildTile(
                context, market, l, color, currency.iconPath, dinoById)),
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

  Widget _currencyStat(String value, String label, String iconPath) => Column(
        children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            _CurrencyIcon(iconPath: iconPath, size: 15),
            const SizedBox(width: 5),
            Text(value,
                style: const TextStyle(
                    color: AppTheme.accentPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );

  // ═══════════════════════════════════════════════════════
  // TUILE LISTING — style proche des commandes
  // ═══════════════════════════════════════════════════════
  Widget _buildTile(
    BuildContext context,
    MarketProvider market,
    MarketListing listing,
    Color shopColor,
    String currencyIconPath,
    Map<int, dynamic> dinoById,
  ) {
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
    final accent = isSold ? AppTheme.success : typeColor;
    final dino = listing.dinoId != null ? dinoById[listing.dinoId] : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(listing.id),
        // ── Swipe droite → VENDU (ou remise en vente si déjà vendu) ──
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF14532D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            isSold ? Icons.restart_alt : Icons.sell_outlined,
            color: Colors.white,
          ),
        ),
        // ── Swipe gauche → SUPPRIMER (confirmé) ───────────────────
        secondaryBackground: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF7F1D1D),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            // Droite : vendu ↔ remise en vente (pas de confirmation)
            if (isSold) {
              market.relist(listing.id);
            } else {
              market.markSold(listing.id);
            }
            return false; // la tuile reste, l'état est géré par le provider
          }
          // Gauche : suppression décidée dans le dialog
          _confirmDelete(listing);
          return false;
        },
        child: Opacity(
          opacity: isSold ? 0.55 : 1,
          child: GestureDetector(
            // Double-tap = DUPLIQUER · Appui long = MODIFIER
            onDoubleTap: () => _duplicate(listing),
            onLongPress: () => _openEditSheet(listing),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: 0.10),
                    AppTheme.bgSecondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Image dino + bandeau couleurs (ou fallback) ──
                    dino != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: DinoCardImage(dino: dino, size: 52),
                          )
                        : Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: typeColor.withValues(alpha: 0.4)),
                            ),
                            child: Icon(Icons.hexagon_outlined,
                                color: typeColor, size: 28),
                          ),
                    const SizedBox(width: 12),
                    // ── Bloc texte ──────────────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Ligne 1 : Espèce — Nom
                          Text(
                            listing.nom.isNotEmpty
                                ? '${listing.espece} — ${listing.nom}'
                                : listing.espece,
                            style: TextStyle(
                              color: isSold ? Colors.white38 : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              decoration: isSold
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Ligne 2 : prix + badges
                          Row(children: [
                            _priceChip(listing.price, currencyIconPath),
                            const SizedBox(width: 6),
                            _badge(listing.type.label, typeColor),
                            const SizedBox(width: 5),
                            if (listing.sexe != ListingSexe.indefini)
                              _badge(listing.sexe.label, Colors.white54),
                            if (listing.timesSold > 0) ...[
                              const Spacer(),
                              Text('×${listing.timesSold} ventes',
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 10.5)),
                            ],
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ── Timer / statut ──────────────────────────────
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceChip(double price, String currencyIconPath) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentPrimary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppTheme.accentPrimary.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CurrencyIcon(iconPath: currencyIconPath, size: 13),
            const SizedBox(width: 4),
            Text(
              price.toStringAsFixed(0),
              style: const TextStyle(
                  color: AppTheme.accentPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5),
            ),
          ],
        ),
      );

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

/// Icône de la monnaie globale de l'app (CurrencyProvider).
/// Affiche l'asset configuré (ex. Hexagon) avec fallback Material.
class _CurrencyIcon extends StatelessWidget {
  final String iconPath;
  final double size;
  const _CurrencyIcon({required this.iconPath, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(Icons.hexagon,
          color: AppTheme.accentPrimary, size: size),
    );
  }
}
