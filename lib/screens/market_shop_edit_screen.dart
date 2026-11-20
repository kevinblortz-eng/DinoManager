// market_shop_edit_screen.dart — Création / paramètres d'un shop.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/market.dart';
import '../providers/market_provider.dart';
import '../theme/app_theme.dart';

class MarketShopEditScreen extends StatefulWidget {
  final MarketShop? shop; // null = création
  const MarketShopEditScreen({super.key, this.shop});

  @override
  State<MarketShopEditScreen> createState() => _MarketShopEditScreenState();
}

class _MarketShopEditScreenState extends State<MarketShopEditScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late int _colorValue;
  late ListingType _defaultType;
  late ListingSexe _defaultSexe;

  static const List<int> _palette = [
    0xFFFF6B00, // orange ARK
    0xFFC9A24A, // or
    0xFFB8B8B8, // argent
    0xFF4FC3F7, // bleu glace
    0xFF66BB6A, // vert
    0xFFAB47BC, // violet
    0xFFEF4444, // rouge
    0xFF2DD4BF, // turquoise
    0xFFF472B6, // rose
    0xFF94A3B8, // gris acier
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.shop;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _priceCtrl =
        TextEditingController(text: (s?.defaultPrice ?? 100).toStringAsFixed(0));
    _colorValue = s?.colorValue ?? _palette.first;
    _defaultType = s?.defaultType ?? ListingType.adulte;
    _defaultSexe = s?.defaultSexe ?? ListingSexe.indefini;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final price =
        double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 100;
    final market = context.read<MarketProvider>();

    if (widget.shop == null) {
      await market.addShop(MarketShop(
        name: name,
        colorValue: _colorValue,
        defaultPrice: price,
        defaultType: _defaultType,
        defaultSexe: _defaultSexe,
      ));
    } else {
      final s = widget.shop!;
      s.name = name;
      s.colorValue = _colorValue;
      s.defaultPrice = price;
      s.defaultType = _defaultType;
      s.defaultSexe = _defaultSexe;
      await market.updateShop(s);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteShop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2333),
        title: const Text('Supprimer ce shop ?',
            style: TextStyle(color: Colors.white, fontSize: 17)),
        content: const Text(
          'Tous les dinos suivis dans ce shop seront également supprimés.',
          style: TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<MarketProvider>().deleteShop(widget.shop!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shop != null;
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(isEdit ? 'Paramètres du shop' : 'Nouveau shop'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: _deleteShop,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Nom du shop',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.accentPrimary)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Couleur du shop',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _palette
                .map((c) => GestureDetector(
                      onTap: () => setState(() => _colorValue = c),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == c
                                ? Colors.white
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Prix par défaut (hexagones)',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24)),
              prefixIcon:
                  Icon(Icons.hexagon_outlined, color: AppTheme.accentPrimary),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<ListingType>(
                initialValue: _defaultType == ListingType.aucun ? null : _defaultType,
                hint: const Text('Aucun',
                    style: TextStyle(color: Colors.white38)),
                dropdownColor: const Color(0xFF1C2333),
                decoration: const InputDecoration(
                  labelText: 'Type par défaut',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24)),
                ),
                items: ListingType.values
                    .where((t) => t != ListingType.aucun)
                    .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label,
                            style: const TextStyle(color: Colors.white))))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _defaultType = v ?? ListingType.aucun),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<ListingSexe>(
                initialValue: _defaultSexe,
                dropdownColor: const Color(0xFF1C2333),
                decoration: const InputDecoration(
                  labelText: 'Sexe par défaut',
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
                onChanged: (v) =>
                    setState(() => _defaultSexe = v ?? _defaultSexe),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Ex. : un shop "Œufs only" → Type par défaut = Œuf.\n'
            'Chaque dépôt démarre un timer cryo de 30 jours (modifiable).',
            style: TextStyle(color: Colors.white38, fontSize: 11.5, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: _save,
              child: Text(isEdit ? 'Enregistrer' : 'Créer le shop',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
