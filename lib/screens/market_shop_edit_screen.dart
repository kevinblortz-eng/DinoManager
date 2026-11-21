// market_shop_edit_screen.dart — Création / paramètres d'un shop.
// NOTE : aucun DropdownButtonFormField — Flutter 3.50 a cassé la sélection
// interne des dropdowns (value: déprécié = sémantique initialValue:).
// Tous les choix Type/Sexe passent par des chips à choix direct.
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
    final market = context.read<MarketProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
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
      await market.deleteShop(widget.shop!.id);
      if (mounted) Navigator.pop(context);
    }
  }

  // ── Chips Type / Sexe (remplacent les dropdowns) ──────────────────────

  Widget _typeChips(ListingType current, void Function(ListingType) onSelect) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children:
          ListingType.values.where((t) => t != ListingType.aucun).map((t) {
        final active = t == current;
        return GestureDetector(
          onTap: () => onSelect(t),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active
                  ? AppTheme.accentPrimary.withValues(alpha: 0.18)
                  : AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active ? AppTheme.accentPrimary : Colors.white24,
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
                  : AppTheme.bgSecondary,
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
          const Text('Type par défaut',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          _typeChips(_defaultType,
              (t) => setState(() => _defaultType = t)),
          const SizedBox(height: 16),
          const Text('Sexe par défaut',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 8),
          _sexeChips(_defaultSexe,
              (s) => setState(() => _defaultSexe = s)),
          const SizedBox(height: 8),
          const Text(
            'Ex. : un shop "Œufs only" → Type par défaut = Œuf.\n'
            'Chaque dépôt démarre un timer cryo (8 j œuf / 30 j autres, modifiable).',
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
