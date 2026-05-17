import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/dino_provider.dart';
import '../providers/currency_provider.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/dino.dart';
import '../models/currency.dart';
import '../theme/app_theme.dart';
import '../widgets/ark_dino_card.dart';
import '../widgets/dino_image_widget.dart';
import '../utils/dino_helpers.dart';
import '../widgets/dino_card_widget.dart';
import '../providers/role_theme_provider.dart';


// ─── Enum pour le tri ────────────────────────────────────────────────────────
enum ItemSortMode { nom, espece, niveau }

class OrderCreateEditScreen extends StatefulWidget {
  final Order? order;

  const OrderCreateEditScreen({
    super.key,
    this.order,
  });

  @override
  State<OrderCreateEditScreen> createState() => _OrderCreateEditScreenState();
}

class _OrderCreateEditScreenState extends State<OrderCreateEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _totalCostController;

  late Order _currentOrder;
  late Currency _selectedCurrency;
  bool _isLoading = false;

  ItemSortMode _sortMode = ItemSortMode.espece;

  bool _isDirty = false;

  late int _defaultQuantity;
  late OrderItemType _defaultType;
  late OrderItemGender _defaultGender;

  final ScrollController _scrollController = ScrollController();

  static const String _headerBgAsset = 'assets/images/ui/ark_header_bg.png';

  // ── Historique des validations pour annulation (max 3) ──────────────────
  // Chaque entrée = snapshot de la map {itemId: {maleCount, femaleCount}}
  final List<Map<String, Map<String, int>>> _validationHistory = [];
  static const int _maxHistory = 3;

  // ══════════════════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _initializeOrder();
  }

  Future<void> _loadDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _defaultQuantity = prefs.getInt('order_default_quantity') ?? 1;
      final typeStr = prefs.getString('order_default_type') ?? 'bebe';
      _defaultType = OrderItemTypeExt.fromString(typeStr);
      final genderStr = prefs.getString('order_default_gender') ?? 'les2';
      _defaultGender = OrderItemGenderExt.fromString(genderStr);
      final sortStr = prefs.getString('order_sort_mode') ?? 'espece';
      _sortMode = _sortModeFromString(sortStr);
    });
  }

  void _initializeOrder() {
    final currencyProvider = context.read<CurrencyProvider>();
    if (widget.order != null) {
      _currentOrder = widget.order!.copyWith();
      _selectedCurrency = currencyProvider.defaultCurrency;
    } else {
      _currentOrder = Order(name: '', clientName: '', items: []);
      _selectedCurrency = currencyProvider.defaultCurrency;
    }
    _nameController = TextEditingController(text: _currentOrder.name);
    _totalCostController = TextEditingController(
      text: _currentOrder.totalCost?.toStringAsFixed(2) ?? '',
    );
    _nameController.addListener(_markDirtyAndAutoSave);
    _totalCostController.addListener(_markDirtyAndAutoSave);
  }

  @override
  void dispose() {
    _nameController.removeListener(_markDirtyAndAutoSave);
    _totalCostController.removeListener(_markDirtyAndAutoSave);
    _nameController.dispose();
    _totalCostController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTO-SAVE
  // ══════════════════════════════════════════════════════════════════════════

  void _markDirtyAndAutoSave() {
    _isDirty = true;
    Future.delayed(const Duration(milliseconds: 800), () {
      if (_isDirty && mounted) {
        _autoSaveBackground();
      }
    });
  }

  Future<void> _autoSaveBackground() async {
    if (!_isDirty) return;
    _isDirty = false;

    try {
      String orderName = _nameController.text;
      if (orderName.isEmpty) {
        final now = DateTime.now();
        orderName = 'CMD-${DateFormat('ddMMM-HHmm').format(now).toUpperCase()}';
      }

      final orderToSave = _currentOrder.copyWith(
        name: orderName,
        clientName: orderName,
        totalCost: double.tryParse(_totalCostController.text),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<OrderProvider>();
      if (widget.order != null || _currentOrder.id.isNotEmpty) {
        await provider.updateOrder(orderToSave);
      } else {
        await provider.createOrder(orderToSave);
      }
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HISTORIQUE VALIDATIONS (UNDO)
  // ══════════════════════════════════════════════════════════════════════════

  /// Sauvegarde l'état actuel des validations dans l'historique
  void _saveValidationSnapshot() {
    final snapshot = <String, Map<String, int>>{};
    for (final item in _currentOrder.items) {
      snapshot[item.id] = {
        'male': item.validation?.maleValidatedCount ?? 0,
        'female': item.validation?.femaleValidatedCount ?? 0,
      };
    }
    _validationHistory.add(snapshot);
    if (_validationHistory.length > _maxHistory) {
      _validationHistory.removeAt(0);
    }
  }

  /// Annule la dernière modification de validation
  void _undoLastValidation() {
    if (_validationHistory.isEmpty) return;
    final snapshot = _validationHistory.removeLast();
    setState(() {
      for (final item in _currentOrder.items) {
        final saved = snapshot[item.id];
        if (saved == null) continue;
        item.validation ??= OrderItemValidation(quantity: item.quantity);
        item.validation!.maleValidatedCount = saved['male'] ?? 0;
        item.validation!.femaleValidatedCount = saved['female'] ?? 0;
      }
    });
      }

  /// Validation manuelle complète de la commande
  Future<void> _manualValidateOrder() async {
    final allDone = _completionRatio >= 0.99;
    
    String confirmMessage;
    if (allDone) {
      confirmMessage = 'Tous les dinos sont prêts. Valider la commande ?';
    } else {
      final pct = (_completionRatio * 100).toStringAsFixed(0);
      confirmMessage = 'La commande n\'est complète qu\'à $pct%.\nValider quand même ?';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 22),
            const SizedBox(width: 10),
            Text('Valider la commande',
                style: GoogleFonts.exo2(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(confirmMessage,
            style: GoogleFonts.exo2(color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.exo2(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label: const Text('Valider'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;
    
    final provider = context.read<OrderProvider>();
    await provider.validateOrder(_currentOrder.id);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Commande validée !'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TRI
  // ══════════════════════════════════════════════════════════════════════════

  List<OrderItem> get _sortedItems {
    final items = List<OrderItem>.from(_currentOrder.items);
    items.sort((a, b) {
      final aDone = _isItemFullyValidated(a);
      final bDone = _isItemFullyValidated(b);
      if (aDone && !bDone) return 1;
      if (!aDone && bDone) return -1;

      switch (_sortMode) {
        case ItemSortMode.nom:
          return a.dinoName.toLowerCase().compareTo(b.dinoName.toLowerCase());
        case ItemSortMode.espece:
          return a.dinoSpecies
              .toLowerCase()
              .compareTo(b.dinoSpecies.toLowerCase());
        case ItemSortMode.niveau:
          final dinoProvider = context.read<DinoProvider>();
          final dinoA = dinoProvider.dinos
              .cast<Dino?>()
              .firstWhere((d) => d?.id == a.dinoId, orElse: () => null);
          final dinoB = dinoProvider.dinos
              .cast<Dino?>()
              .firstWhere((d) => d?.id == b.dinoId, orElse: () => null);
          return (dinoB?.niveau ?? 0).compareTo(dinoA?.niveau ?? 0);
      }
    });
    return items;
  }

  bool _isItemFullyValidated(OrderItem item) {
    item.validation ??= OrderItemValidation(quantity: item.quantity);
    final v = item.validation!;
    final hasMale = item.gender == OrderItemGender.male ||
        item.gender == OrderItemGender.les2;
    final hasFemale = item.gender == OrderItemGender.femelle ||
        item.gender == OrderItemGender.les2;
    final maleOk = !hasMale || v.maleValidatedCount >= item.quantity;
    final femaleOk = !hasFemale || v.femaleValidatedCount >= item.quantity;
    return maleOk && femaleOk;
  }

  ItemSortMode _sortModeFromString(String s) {
    switch (s) {
      case 'nom':
        return ItemSortMode.nom;
      case 'niveau':
        return ItemSortMode.niveau;
      default:
        return ItemSortMode.espece;
    }
  }

  Future<void> _saveSortMode(ItemSortMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('order_sort_mode', mode.name);
  }

  String get _sortModeLabel {
    switch (_sortMode) {
      case ItemSortMode.nom:
        return '↑ NOM';
      case ItemSortMode.espece:
        return '↑ ESPÈCE';
      case ItemSortMode.niveau:
        return '↓ NIVEAU';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CALCULS RÉSUMÉ
  // ══════════════════════════════════════════════════════════════════════════

  String get _dinoSummaryText {
    int pairs = 0;
    int malesOnly = 0;
    int femalesOnly = 0;
    int indefini = 0;

    for (final item in _currentOrder.items) {
      switch (item.gender) {
        case OrderItemGender.les2:
          pairs += item.quantity;
          break;
        case OrderItemGender.male:
          malesOnly += item.quantity;
          break;
        case OrderItemGender.femelle:
          femalesOnly += item.quantity;
          break;
        case OrderItemGender.indefini:
          indefini += item.quantity;
          break;
      }
    }

    final parts = <String>[];
    if (pairs > 0) parts.add('$pairs paire${pairs > 1 ? 's' : ''}');
    if (malesOnly > 0) parts.add('$malesOnly ♂');
    if (femalesOnly > 0) parts.add('$femalesOnly ♀');
    if (indefini > 0) parts.add('$indefini ?');
    if (parts.isEmpty) return '—';
    return parts.join('  ·  ');
  }

  String get _costPerUnitText {
    final total = double.tryParse(_totalCostController.text) ??
        _currentOrder.computedTotalCost;
    if (total <= 0) return '';
    final onlyPairs =
        _currentOrder.items.every((i) => i.gender == OrderItemGender.les2);
    if (onlyPairs) {
      final totalPairs =
          _currentOrder.items.fold<int>(0, (sum, i) => sum + i.quantity);
      if (totalPairs == 0) return '';
      return '${_formatPrice(total / totalPairs)} / paire';
    } else {
      int totalDinos = 0;
      for (final item in _currentOrder.items) {
        totalDinos += item.gender == OrderItemGender.les2
            ? item.quantity * 2
            : item.quantity;
      }
      if (totalDinos == 0) return '';
      return '${_formatPrice(total / totalDinos)} / dino';
    }
  }

  double get _completionRatio {
    if (_currentOrder.items.isEmpty) return 0.0;
    int totalNeeded = 0;
    int totalDone = 0;

    for (final item in _currentOrder.items) {
      final v =
          item.validation ?? OrderItemValidation(quantity: item.quantity);
      if (item.gender == OrderItemGender.les2) {
        totalNeeded += item.quantity * 2;
        totalDone += (v.maleValidatedCount + v.femaleValidatedCount)
            .clamp(0, item.quantity * 2);
      } else if (item.gender == OrderItemGender.male) {
        totalNeeded += item.quantity;
        totalDone += v.maleValidatedCount.clamp(0, item.quantity);
      } else if (item.gender == OrderItemGender.femelle) {
        totalNeeded += item.quantity;
        totalDone += v.femaleValidatedCount.clamp(0, item.quantity);
      } else {
        totalNeeded += item.quantity;
        totalDone += v.totalValidated.clamp(0, item.quantity);
      }
    }
    if (totalNeeded == 0) return 0.0;
    return (totalDone / totalNeeded).clamp(0.0, 1.0);
  }

  // ── Label dynamique X/Y PAIRES ou X/Y DINOS ───────────────────────────
  String get _completionLabel {
    if (_currentOrder.items.isEmpty) return '0/0 DINOS PRÉPARÉS';

    final onlyPairs = _currentOrder.items
        .every((i) => i.gender == OrderItemGender.les2);

    if (onlyPairs) {
      int totalPaires = 0;
      int pairesFaites = 0;
      for (final item in _currentOrder.items) {
        final v = item.validation ??
            OrderItemValidation(quantity: item.quantity);
        totalPaires += item.quantity;
        // Une paire est complète si mâle ET femelle >= quantité
        if (v.maleValidatedCount >= item.quantity &&
            v.femaleValidatedCount >= item.quantity) {
          pairesFaites += item.quantity;
        }
      }
      return '$pairesFaites/$totalPaires PAIRES PRÉPARÉES';
    } else {
      int totalDinos = 0;
      int dinosFaits = 0;
      for (final item in _currentOrder.items) {
        final v = item.validation ??
            OrderItemValidation(quantity: item.quantity);
        if (item.gender == OrderItemGender.les2) {
          totalDinos += item.quantity * 2;
          dinosFaits += (v.maleValidatedCount + v.femaleValidatedCount)
              .clamp(0, item.quantity * 2);
        } else if (item.gender == OrderItemGender.male) {
          totalDinos += item.quantity;
          dinosFaits += v.maleValidatedCount.clamp(0, item.quantity);
        } else if (item.gender == OrderItemGender.femelle) {
          totalDinos += item.quantity;
          dinosFaits += v.femaleValidatedCount.clamp(0, item.quantity);
        } else {
          totalDinos += item.quantity;
          dinosFaits += v.totalValidated.clamp(0, item.quantity);
        }
      }
      return '$dinosFaits/$totalDinos DINOS PRÉPARÉS';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PARTAGE
  // ══════════════════════════════════════════════════════════════════════════

  void _shareOrder() {
    final dinoProvider = context.read<DinoProvider>();

    final sortedItems = List<OrderItem>.from(_currentOrder.items)
      ..sort((a, b) =>
          a.dinoSpecies.toLowerCase().compareTo(b.dinoSpecies.toLowerCase()));

    final lines = sortedItems.map((item) {
      final fullDino = dinoProvider.dinos
          .cast<Dino?>()
          .firstWhere((d) => d?.id == item.dinoId, orElse: () => null);
      final lvl = fullDino?.niveau ?? 0;
      final name =
          item.dinoName.isNotEmpty ? item.dinoName : item.dinoSpecies;
      return '${item.dinoSpecies} - $name - Lvl $lvl';
    }).toList();

    final orderName = _nameController.text.isNotEmpty
        ? _nameController.text
        : 'Commande';
    final header = '📋 $orderName\n${'─' * 30}';
    final footer =
        '─' * 30 + '\n${lines.length} dino${lines.length > 1 ? 's' : ''}';
    final fullText = '$header\n${lines.join('\n')}\n$footer';

    Clipboard.setData(ClipboardData(text: fullText));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SharePreviewSheet(
        text: fullText,
        itemCount: lines.length,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOG DEFAULTS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _saveDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('order_default_quantity', _defaultQuantity);
    await prefs.setString('order_default_type', _defaultType.toString());
    await prefs.setString('order_default_gender', _defaultGender.toString());
  }

  void _showDefaultsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Valeurs par défaut',
              style: GoogleFonts.exo2(color: AppTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantité',
                    style: GoogleFonts.exo2(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: AppTheme.accentPrimary),
                      onPressed: () {
                        if (_defaultQuantity > 1) {
                          setDlg(() => _defaultQuantity--);
                        }
                      },
                    ),
                    Expanded(
                      child: Text('$_defaultQuantity',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline,
                          color: AppTheme.accentPrimary),
                      onPressed: () => setDlg(() => _defaultQuantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Type',
                    style: GoogleFonts.exo2(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButton<OrderItemType>(
                  value: _defaultType,
                  dropdownColor: AppTheme.bgSecondary,
                  isExpanded: true,
                  items: OrderItemType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlg(() => _defaultType = val);
                  },
                ),
                const SizedBox(height: 16),
                Text('Genre',
                    style: GoogleFonts.exo2(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButton<OrderItemGender>(
                  value: _defaultGender,
                  dropdownColor: AppTheme.bgSecondary,
                  isExpanded: true,
                  items: OrderItemGender.values
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.label,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDlg(() => _defaultGender = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                _saveDefaults();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Valeurs par défaut mises à jour')),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FILTRE TRI
  // ══════════════════════════════════════════════════════════════════════════

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Trier par',
                  style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Les dinos validés sont toujours placés en bas',
                  style: GoogleFonts.exo2(
                      color: AppTheme.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 16),
                ...[
                  (ItemSortMode.espece, '🦕', 'Espèce',
                      'Ordre alphabétique par espèce'),
                  (ItemSortMode.nom, '🏷️', 'Nom',
                      'Ordre alphabétique par nom'),
                  (ItemSortMode.niveau, '⭐', 'Niveau',
                      'Du niveau le plus haut au plus bas'),
                ].map((entry) {
                  final (mode, emoji, label, desc) = entry;
                  final isSelected = _sortMode == mode;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _sortMode = mode);
                      _saveSortMode(mode);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.accentPrimary.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.accentPrimary.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label,
                                    style: GoogleFonts.exo2(
                                      color: isSelected
                                          ? AppTheme.accentPrimary
                                          : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    )),
                                Text(desc,
                                    style: GoogleFonts.exo2(
                                        color: AppTheme.textMuted,
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: AppTheme.accentPrimary, size: 18),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AJOUT DINOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _addDinosToOrder() async {
    final dinos = context.read<DinoProvider>().dinos;
    if (dinos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun dino disponible')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _DinoSelectionModal(
        dinos: dinos,
        defaultQuantity: _defaultQuantity,
        defaultType: _defaultType,
        defaultGender: _defaultGender,
        onDinosSelected: (selectedDinos) {
          setState(() {
            for (final item in selectedDinos) {
              _currentOrder.items.add(item);
            }
          });
          _markDirtyAndAutoSave();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _removeItem(String itemId) {
    setState(() {
      _currentOrder.items.removeWhere((i) => i.id == itemId);
    });
    _markDirtyAndAutoSave();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CONTEXT MENU
  // ══════════════════════════════════════════════════════════════════════════

  void _showItemContextMenu(OrderItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.accentPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DinoImageWidget(
                        species: item.dinoSpecies,
                        regionColors:
                            item.dinoColors.map<String?>((c) => c).toList(),
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        showColorBand: false,
                        alignment: Alignment.center,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.dinoName.isEmpty
                                ? item.dinoSpecies
                                : item.dinoName,
                            style: GoogleFonts.exo2(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.quantity}x · ${item.gender.label} · ${item.type.label}',
                            style: GoogleFonts.exo2(
                                color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 12),
                _buildContextMenuOption(
                  icon: Icons.arrow_back_rounded,
                  label: 'Retour',
                  color: AppTheme.textSecondary,
                  onTap: () => Navigator.pop(ctx),
                ),
                const SizedBox(height: 8),
                _buildContextMenuOption(
                  icon: Icons.edit_rounded,
                  label: 'Modifier',
                  color: AppTheme.accentPrimary,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showItemEditDialog(item);
                  },
                ),
                const SizedBox(height: 8),
                _buildContextMenuOption(
                  icon: Icons.delete_outline_rounded,
                  label: 'Supprimer',
                  color: AppTheme.danger,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteConfirmationDialog(item);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenuOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: color.withValues(alpha: 0.2), width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.exo2(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DIALOG MODIFIER ITEM
  // ══════════════════════════════════════════════════════════════════════════

  void _showItemEditDialog(OrderItem item) {
    int editQty = item.quantity;
    int editMaleQty =
        item.gender == OrderItemGender.les2 || item.gender == OrderItemGender.male
            ? item.quantity
            : 0;
    int editFemaleQty =
        item.gender == OrderItemGender.les2 ||
                item.gender == OrderItemGender.femelle
            ? item.quantity
            : 0;
    OrderItemType editType = item.type;
    OrderItemGender editGender = item.gender;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) {
          void updateQty() {
            if (editGender == OrderItemGender.les2) {
              editQty = editMaleQty > editFemaleQty ? editMaleQty : editFemaleQty;
            } else if (editGender == OrderItemGender.male) {
              editQty = editMaleQty;
            } else if (editGender == OrderItemGender.femelle) {
              editQty = editFemaleQty;
            } else {
              editQty = editMaleQty;
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F2E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            contentPadding: EdgeInsets.zero,
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: DinoImageWidget(
                            species: item.dinoSpecies,
                            regionColors:
                                item.dinoColors.map<String?>((c) => c).toList(),
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            showColorBand: false,
                            alignment: Alignment.center,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.dinoName.isEmpty
                                    ? item.dinoSpecies
                                    : item.dinoName,
                                style: GoogleFonts.exo2(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800),
                              ),
                              Text(item.dinoSpecies,
                                  style: GoogleFonts.exo2(
                                      color: AppTheme.textMuted, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TYPE',
                            style: GoogleFonts.exo2(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Row(
                          children: OrderItemType.values.map((t) {
                            final isSel = editType == t;
                            final tc = _typeColor(t);
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setDlg(() => editType = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: EdgeInsets.only(
                                      right: t != OrderItemType.values.last
                                          ? 6
                                          : 0),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSel
                                        ? tc.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: isSel
                                            ? tc
                                            : Colors.white
                                                .withValues(alpha: 0.1),
                                        width: isSel ? 2 : 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(_typeEmoji(t),
                                          style:
                                              const TextStyle(fontSize: 18)),
                                      const SizedBox(height: 4),
                                      Text(t.label,
                                          style: GoogleFonts.exo2(
                                              color: isSel
                                                  ? tc
                                                  : AppTheme.textMuted,
                                              fontSize: 10,
                                              fontWeight: isSel
                                                  ? FontWeight.w800
                                                  : FontWeight.w500),
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text('GENRE',
                            style: GoogleFonts.exo2(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: OrderItemGender.values.map((g) {
                            final isSel = editGender == g;
                            return GestureDetector(
                              onTap: () => setDlg(() {
                                editGender = g;
                                if (g == OrderItemGender.les2) {
                                  editMaleQty = editQty;
                                  editFemaleQty = editQty;
                                } else if (g == OrderItemGender.male) {
                                  editFemaleQty = 0;
                                } else if (g == OrderItemGender.femelle) {
                                  editMaleQty = 0;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppTheme.accentPrimary
                                          .withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isSel
                                          ? AppTheme.accentPrimary
                                          : Colors.white
                                              .withValues(alpha: 0.1),
                                      width: isSel ? 1.5 : 1),
                                ),
                                child: Text(g.label,
                                    style: GoogleFonts.exo2(
                                        color: isSel
                                            ? AppTheme.accentPrimary
                                            : AppTheme.textMuted,
                                        fontSize: 11,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500)),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text('QUANTITÉS',
                            style: GoogleFonts.exo2(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        if (editGender == OrderItemGender.male ||
                            editGender == OrderItemGender.les2)
                          _buildQtyRow(
                            label: '♂ Mâles',
                            color: const Color(0xFF4FC3F7),
                            value: editMaleQty,
                            onDecrement: () {
                              if (editMaleQty > 0) {
                                setDlg(() {
                                  editMaleQty--;
                                  updateQty();
                                });
                              }
                            },
                            onIncrement: () => setDlg(() {
                              editMaleQty++;
                              updateQty();
                            }),
                          ),
                        if (editGender == OrderItemGender.les2)
                          const SizedBox(height: 8),
                        if (editGender == OrderItemGender.femelle ||
                            editGender == OrderItemGender.les2)
                          _buildQtyRow(
                            label: '♀ Femelles',
                            color: const Color(0xFFF48FB1),
                            value: editFemaleQty,
                            onDecrement: () {
                              if (editFemaleQty > 0) {
                                setDlg(() {
                                  editFemaleQty--;
                                  updateQty();
                                });
                              }
                            },
                            onIncrement: () => setDlg(() {
                              editFemaleQty++;
                              updateQty();
                            }),
                          ),
                        if (editGender == OrderItemGender.indefini)
                          _buildQtyRow(
                            label: '? Indéfini',
                            color: AppTheme.textSecondary,
                            value: editQty,
                            onDecrement: () {
                              if (editQty > 0) {
                                setDlg(() => editMaleQty = --editQty);
                              }
                            },
                            onIncrement: () =>
                                setDlg(() => editMaleQty = ++editQty),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Annuler',
                    style: GoogleFonts.exo2(color: AppTheme.textMuted)),
              ),
              FilledButton(
                onPressed: () {
                  setState(() {
                    final idx = _currentOrder.items
                        .indexWhere((i) => i.id == item.id);
                    if (idx == -1) return;
                    final it = _currentOrder.items[idx];
                    int finalQty;
                    if (editGender == OrderItemGender.les2) {
                      finalQty = editMaleQty > editFemaleQty
                          ? editMaleQty
                          : editFemaleQty;
                    } else if (editGender == OrderItemGender.male) {
                      finalQty = editMaleQty;
                    } else if (editGender == OrderItemGender.femelle) {
                      finalQty = editFemaleQty;
                    } else {
                      finalQty = editQty;
                    }
                    if (finalQty < 1) finalQty = 1;
                    _currentOrder.items[idx] = it.copyWith(
                      quantity: finalQty,
                      type: editType,
                      gender: editGender,
                      validation: OrderItemValidation(quantity: finalQty),
                    );
                  });
                  _markDirtyAndAutoSave();
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Appliquer',
                    style: GoogleFonts.exo2(
                        fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQtyRow({
    required String label,
    required Color color,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.exo2(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const Spacer(),
          GestureDetector(
            onTap: onDecrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.danger.withValues(alpha: 0.4), width: 1),
              ),
              child: const Icon(Icons.remove_rounded,
                  color: AppTheme.danger, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.exo2(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onIncrement,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4), width: 1),
              ),
              child: const Icon(Icons.add_rounded,
                  color: Colors.green, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(OrderItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer ${item.dinoName} ?',
            style: GoogleFonts.exo2(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.exo2(
                color: AppTheme.textSecondary, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Retour',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              _removeItem(item.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // SAVE MANUEL
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _saveOrder() async {
    if (_nameController.text.isEmpty && _currentOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez un nom ou un dino')),
      );
      return;
    }
    if (_currentOrder.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un dino')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String orderName = _nameController.text;
      if (orderName.isEmpty) {
        final now = DateTime.now();
        orderName =
            'CMD-${DateFormat('ddMMM-HHmm').format(now).toUpperCase()}';
      }

      _currentOrder = _currentOrder.copyWith(
        name: orderName,
        clientName: orderName,
        totalCost: double.tryParse(_totalCostController.text),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<OrderProvider>();
      bool success;
      if (widget.order != null) {
        success = await provider.updateOrder(_currentOrder);
      } else {
        success = await provider.createOrder(_currentOrder);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.order != null
                ? 'Commande mise à jour ✅'
                : 'Commande créée ✅'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) Navigator.pop(context, _currentOrder);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Erreur lors de la sauvegarde'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HEADER STICKY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStickyHeader() {
    final ratio = _completionRatio;
    final pct = (ratio * 100).toStringAsFixed(0);
    final dateStr =
        DateFormat('dd-MMM').format(_currentOrder.updatedAt).toUpperCase();
    final Color progressColor = ratio == 1.0
        ? Colors.green
        : ratio > 0.5
            ? const Color(0xFFFFD700)
            : AppTheme.accentPrimary;

    return Consumer<CurrencyProvider>(
      builder: (context, currProvider, _) {
        return SizedBox(
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  _headerBgAsset,
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppTheme.bgSecondary),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0x44000000),
                        Color(0xBB0A0E1A),
                        Color(0xF00A0E1A),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xAA000000), Colors.transparent],
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withValues(alpha: 0.9),
                        progressColor.withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ligne 1 : Nom + date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              shadows: const [
                                Shadow(
                                    color: Colors.black,
                                    blurRadius: 6,
                                    offset: Offset(0, 1))
                              ],
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nom de la commande',
                              hintStyle: GoogleFonts.exo2(
                                  color: AppTheme.textMuted
                                      .withValues(alpha: 0.7),
                                  fontSize: 15),
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: progressColor.withValues(alpha: 0.8),
                                    width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1),
                          ),
                          child: Text(dateStr,
                              style: GoogleFonts.exo2(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Ligne 2 : Résumé + Prix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(_dinoSummaryText,
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                shadows: const [
                                  Shadow(color: Colors.black, blurRadius: 4)
                                ],
                              )),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: TextField(
                                    controller: _totalCostController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.exo2(
                                        color: progressColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      hintStyle: GoogleFonts.exo2(
                                          color: AppTheme.textMuted,
                                          fontSize: 14),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 4),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: UnderlineInputBorder(
                                        borderSide: BorderSide(
                                            color: progressColor
                                                .withValues(alpha: 0.6),
                                            width: 1),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _showCurrencySelector(
                                      context, currProvider),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                          _selectedCurrency.iconPath,
                                          width: 16,
                                          height: 16),
                                      const SizedBox(width: 3),
                                      Text(_selectedCurrency.name,
                                          style: GoogleFonts.exo2(
                                              color: AppTheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600)),
                                      const Icon(Icons.expand_more,
                                          color: AppTheme.textMuted, size: 14),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (_costPerUnitText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(_costPerUnitText,
                                    style: GoogleFonts.exo2(
                                        fontSize: 9,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ✅ Ligne 3 : Barre progression avec label dynamique
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ── Label X/Y PAIRES ou X/Y DINOS au lieu de "COMPLÉTION" ──
                        Text(
                          _completionLabel,
                          style: GoogleFonts.exo2(
                            fontSize: 9,
                            color: Colors.white.withValues(alpha: 0.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Text('$pct%',
                            style: GoogleFonts.exo2(
                                fontSize: 10,
                                color: progressColor,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                      color:
                                          progressColor.withValues(alpha: 0.6),
                                      blurRadius: 6)
                                ])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(progressColor),
                      ),
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

  // ══════════════════════════════════════════════════════════════════════════
  // CURRENCY SELECTOR
  // ══════════════════════════════════════════════════════════════════════════

  void _showCurrencySelector(
      BuildContext context, CurrencyProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Sélectionner une monnaie',
                style: GoogleFonts.exo2(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: provider.allCurrencies.length,
              itemBuilder: (context, i) {
                final currency = provider.allCurrencies[i];
                final isSelected = currency.id == _selectedCurrency.id;
                return ListTile(
                  leading: Image.asset(currency.iconPath,
                      width: 24, height: 24),
                  title: Text(currency.name,
                      style:
                          const TextStyle(color: AppTheme.textPrimary)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle,
                          color: AppTheme.accentPrimary)
                      : null,
                  onTap: () {
                    setState(() => _selectedCurrency = currency);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FORMAT PRIX
  // ══════════════════════════════════════════════════════════════════════════

  String _formatPrice(double price) {
    if (price == 0) return '0';
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(price % 1000000 == 0 ? 0 : 1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(price % 1000 == 0 ? 0 : 1)}k';
    } else {
      return price.toStringAsFixed(price % 1 == 0 ? 0 : 2);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final sortedItems = _sortedItems;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          widget.order == null
              ? 'Créer une commande'
              : 'Modifier une commande',
          style: GoogleFonts.cinzelDecorative(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
        actions: [
          if (_currentOrder.items.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: IconButton(
                icon: const Icon(Icons.ios_share_rounded,
                    color: Colors.white70, size: 20),
                onPressed: _shareOrder,
                tooltip: 'Partager la liste',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.sort_rounded,
                  color: Colors.white70, size: 20),
              onPressed: _showSortSheet,
              tooltip: 'Trier les dinos',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8, right: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15), width: 1),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded,
                  color: AppTheme.textMuted, size: 20),
              onPressed: _showDefaultsDialog,
              tooltip: 'Valeurs par défaut',
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Column(
          children: [
            IntrinsicHeight(child: _buildStickyHeader()),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 14,
                  bottom: 100 + bottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Barre titre + badge tri cliquable + bouton Ajouter ──
                    Row(
                      children: [
                        Text(
                          'DINOS À PRÉPARER',
                          style: GoogleFonts.exo2(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.accentPrimary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ✅ Badge tri cliquable → ouvre _showSortSheet
                        GestureDetector(
                          onTap: _showSortSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppTheme.accentPrimary
                                    .withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _sortModeLabel,
                                  style: GoogleFonts.exo2(
                                    fontSize: 9,
                                    color: AppTheme.accentPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  color: AppTheme.accentPrimary,
                                  size: 11,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_currentOrder.items.isNotEmpty)
                          GestureDetector(
                            onTap: _addDinosToOrder,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.accentPrimary
                                        .withValues(alpha: 0.4),
                                    width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add_rounded,
                                      color: AppTheme.accentPrimary,
                                      size: 14),
                                  const SizedBox(width: 4),
                                  Text('Ajouter',
                                      style: GoogleFonts.exo2(
                                          fontSize: 11,
                                          color: AppTheme.accentPrimary,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (sortedItems.isEmpty)
                      GestureDetector(
                        onTap: _addDinosToOrder,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                                width: 2),
                          ),
                          child: Column(
                            children: [
                              const Text('🦖',
                                  style: TextStyle(fontSize: 64)),
                              const SizedBox(height: 12),
                              Text('Ajouter un dino',
                                  style: GoogleFonts.exo2(
                                      color: Colors.green,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: sortedItems
                            .map((item) => _buildItemCard(item))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: AppTheme.bgSecondary,
        padding: EdgeInsets.all(12).copyWith(bottom: bottomPadding + 12),
        child: Row(
          children: [
            // ── Bouton Annuler (Undo) ──────────────────────────────────
            AnimatedOpacity(
              opacity: _validationHistory.isEmpty ? 0.35 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Tooltip(
                message: _validationHistory.isEmpty
                    ? 'Aucune action à annuler'
                    : 'Annuler (${_validationHistory.length}/$_maxHistory)',
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Material(
                    color: _validationHistory.isEmpty
                        ? Colors.white.withValues(alpha: 0.05)
                        : AppTheme.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _validationHistory.isEmpty
                          ? null
                          : _undoLastValidation,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.undo_rounded,
                            color: _validationHistory.isEmpty
                                ? AppTheme.textMuted
                                : AppTheme.warning,
                            size: 22,
                          ),
                          if (_validationHistory.isNotEmpty)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: AppTheme.warning,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${_validationHistory.length}',
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Bouton Enregistrer ─────────────────────────────────────
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    disabledBackgroundColor:
                        AppTheme.accentPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          widget.order == null ? 'Créer' : 'Mettre à jour',
                          style: GoogleFonts.exo2(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ),

            // ── Bouton Valider (uniquement si commande existante avec items) ──
            if (widget.order != null && _currentOrder.items.isNotEmpty) ...[  
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _manualValidateOrder,
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text('Valider',
                      style: GoogleFonts.exo2(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    disabledBackgroundColor:
                        AppTheme.success.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CARTE ITEM
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildItemCard(OrderItem item) {
    item.validation ??= OrderItemValidation(quantity: item.quantity);

    final dinoProvider = context.read<DinoProvider>();
    final Dino? fullDino = dinoProvider.dinos
        .cast<Dino?>()
        .firstWhere((d) => d?.id == item.dinoId, orElse: () => null);

    final roleColor = fullDino?.roleColor ?? AppTheme.accentPrimary;

    final bool hasMale = item.gender == OrderItemGender.male ||
        item.gender == OrderItemGender.les2;
    final bool hasFemale = item.gender == OrderItemGender.femelle ||
        item.gender == OrderItemGender.les2;

    final int maleValidated = item.validation!.maleValidatedCount;
    final int femaleValidated = item.validation!.femaleValidatedCount;
    final int qty = item.quantity;

    final bool maleFullyDone = !hasMale || maleValidated >= qty;
    final bool femaleFullyDone = !hasFemale || femaleValidated >= qty;
    final bool isFullyPrepared = maleFullyDone && femaleFullyDone;

    return GestureDetector(
      onLongPress: () => _showItemContextMenu(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1F2E), Color(0xFF111827)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFullyPrepared
                ? Colors.green.withValues(alpha: 0.5)
                : roleColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3)),
            BoxShadow(
                color: (isFullyPrepared ? Colors.green : roleColor)
                    .withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 86,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        _saveValidationSnapshot();
                        setState(() {
                          final idx = _currentOrder.items
                              .indexWhere((i) => i.id == item.id);
                          if (idx == -1) return;
                          final it = _currentOrder.items[idx];
                          it.validation ??=
                              OrderItemValidation(quantity: it.quantity);
                          if (isFullyPrepared) {
                            it.validation!.maleValidatedCount = 0;
                            it.validation!.femaleValidatedCount = 0;
                          } else {
                            if (hasMale) {
                              it.validation!.maleValidatedCount = qty;
                            }
                            if (hasFemale) {
                              it.validation!.femaleValidatedCount = qty;
                            }
                          }
                        });
                        _markDirtyAndAutoSave();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFullyPrepared
                              ? Colors.green.withValues(alpha: 0.15)
                              : Colors.red.withValues(alpha: 0.12),
                          border: Border.all(
                              color: isFullyPrepared
                                  ? Colors.green
                                  : AppTheme.danger,
                              width: 2.5),
                          boxShadow: [
                            BoxShadow(
                                color: (isFullyPrepared
                                        ? Colors.green
                                        : AppTheme.danger)
                                    .withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1),
                          ],
                        ),
                        child: Icon(
                          isFullyPrepared
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: isFullyPrepared
                              ? Colors.green
                              : AppTheme.danger,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasMale)
                      _buildGenderValidationRow(
                        isMale: true,
                        validated: maleValidated,
                        total: qty,
                        isFullyDone: maleFullyDone,
                        onDecrement: () {
                          _saveValidationSnapshot();
                          setState(() {
                            final idx = _currentOrder.items
                                .indexWhere((i) => i.id == item.id);
                            if (idx == -1) return;
                            final it = _currentOrder.items[idx];
                            it.validation ??=
                                OrderItemValidation(quantity: it.quantity);
                            if (it.validation!.maleValidatedCount > 0) {
                              it.validation!.maleValidatedCount--;
                            }
                          });
                          _markDirtyAndAutoSave();
                        },
                        onIncrement: () {
                          _saveValidationSnapshot();
                          setState(() {
                            final idx = _currentOrder.items
                                .indexWhere((i) => i.id == item.id);
                            if (idx == -1) return;
                            final it = _currentOrder.items[idx];
                            it.validation ??=
                                OrderItemValidation(quantity: it.quantity);
                            if (it.validation!.maleValidatedCount < qty) {
                              it.validation!.maleValidatedCount++;
                            }
                          });
                          _markDirtyAndAutoSave();
                        },
                      ),
                    if (hasMale && hasFemale) const SizedBox(height: 6),
                    if (hasFemale)
                      _buildGenderValidationRow(
                        isMale: false,
                        validated: femaleValidated,
                        total: qty,
                        isFullyDone: femaleFullyDone,
                        onDecrement: () {
                          _saveValidationSnapshot();
                          setState(() {
                            final idx = _currentOrder.items
                                .indexWhere((i) => i.id == item.id);
                            if (idx == -1) return;
                            final it = _currentOrder.items[idx];
                            it.validation ??=
                                OrderItemValidation(quantity: it.quantity);
                            if (it.validation!.femaleValidatedCount > 0) {
                              it.validation!.femaleValidatedCount--;
                            }
                          });
                          _markDirtyAndAutoSave();
                        },
                        onIncrement: () {
                          _saveValidationSnapshot();
                          setState(() {
                            final idx = _currentOrder.items
                                .indexWhere((i) => i.id == item.id);
                            if (idx == -1) return;
                            final it = _currentOrder.items[idx];
                            it.validation ??=
                                OrderItemValidation(quantity: it.quantity);
                            if (it.validation!.femaleValidatedCount < qty) {
                              it.validation!.femaleValidatedCount++;
                            }
                          });
                          _markDirtyAndAutoSave();
                        },
                      ),
                  ],
                ),
              ),

              Container(
                width: 1,
                height: 100,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isFullyPrepared ? Colors.green : roleColor)
                          .withValues(alpha: 0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SizedBox(
                  height: 110,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildDinoAvatarWithTypeBadge(
                          item, fullDino, roleColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.dinoName.toUpperCase(),
                              style: GoogleFonts.exo2(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isFullyPrepared
                                    ? Colors.green
                                    : Colors.white,
                                letterSpacing: 0.4,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              fullDino != null
                                  ? '${item.dinoSpecies} · Lvl ${fullDino.niveau}'
                                  : item.dinoSpecies,
                              style: GoogleFonts.exo2(
                                  fontSize: 9,
                                  color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            _buildInlineStatRow(fullDino),
                            const SizedBox(height: 4),
                            _buildColorStrip(item.dinoColors),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AVATAR + BADGE TYPE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDinoAvatarWithTypeBadge(
      OrderItem item, Dino? dino, Color roleColor) {
    final String? customImagePath =
        (dino != null && dino.image != null && dino.image!.isNotEmpty)
            ? dino.image
            : null;
    final bool hasCustomImage = customImagePath != null;
    final String safeImagePath = customImagePath ?? '';
    final typeColor = _typeColor(item.type);
    final typeEmoji = _typeEmoji(item.type);

    return SizedBox(
      width: 64,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 0,
            right: -6,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.diagonal3Values(-1.0, 1.0, 1.0),
              child: SizedBox(
                width: 76,
                height: 82,
                child: hasCustomImage
                    ? Image.file(
                        File(safeImagePath),
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => DinoImageWidget(
                          species: item.dinoSpecies,
                          regionColors:
                              dino?.colorRegions ?? List.filled(6, null),
                          width: 76,
                          height: 82,
                          fit: BoxFit.contain,
                          showColorBand: false,
                          alignment: Alignment.bottomCenter,
                        ),
                      )
                    : DinoImageWidget(
                        species: item.dinoSpecies,
                        regionColors:
                            dino?.colorRegions ?? List.filled(6, null),
                        width: 76,
                        height: 82,
                        fit: BoxFit.contain,
                        showColorBand: false,
                        alignment: Alignment.bottomCenter,
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: typeColor.withValues(alpha: 0.7), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: typeColor.withValues(alpha: 0.25),
                        blurRadius: 6)
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(typeEmoji, style: const TextStyle(fontSize: 9)),
                    const SizedBox(width: 3),
                    Text(item.type.label.toUpperCase(),
                        style: GoogleFonts.exo2(
                            color: typeColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS TYPE
  // ══════════════════════════════════════════════════════════════════════════

  Color _typeColor(OrderItemType type) {
    switch (type) {
      case OrderItemType.oeuf:
        return const Color(0xFFFFD700);
      case OrderItemType.bebe:
        return const Color(0xFF4FC3F7);
      case OrderItemType.adulte:
        return const Color(0xFF81C784);
    }
  }

  String _typeEmoji(OrderItemType type) {
    switch (type) {
      case OrderItemType.oeuf:
        return '🥚';
      case OrderItemType.bebe:
        return '🐣';
      case OrderItemType.adulte:
        return '🦕';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALIDATION PAR GENRE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildGenderValidationRow({
    required bool isMale,
    required int validated,
    required int total,
    required bool isFullyDone,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    final genderColor =
        isMale ? const Color(0xFF4FC3F7) : const Color(0xFFF48FB1);
    final genderSymbol = isMale ? '♂' : '♀';

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onDecrement,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppTheme.danger.withValues(alpha: 0.4), width: 1),
            ),
            child: const Icon(Icons.remove_rounded,
                color: AppTheme.danger, size: 13),
          ),
        ),
        const SizedBox(width: 5),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$validated',
                    style: GoogleFonts.exo2(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isFullyDone ? Colors.green : Colors.white),
                  ),
                  TextSpan(
                    text: '/$total',
                    style: GoogleFonts.exo2(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            Text(genderSymbol,
                style: TextStyle(
                    fontSize: 12,
                    color: genderColor,
                    fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(width: 5),
        GestureDetector(
          onTap: onIncrement,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: Colors.green.withValues(alpha: 0.4), width: 1),
            ),
            child:
                const Icon(Icons.add_rounded, color: Colors.green, size: 13),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS + COULEURS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildInlineStatRow(Dino? dino) {
    if (dino == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Text('Stats non disponibles',
            style: GoogleFonts.exo2(fontSize: 9, color: AppTheme.textMuted)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(children: [
            Expanded(
                child: _buildMiniStat('HP',
                    DinoHelpers.formatNumber(dino.hp), const Color(0xFF4CAF50))),
            _buildStatDivider(),
            Expanded(
                child: _buildMiniStat(
                    'Stam',
                    DinoHelpers.formatNumber(dino.stamina),
                    const Color(0xFFFFD700))),
            _buildStatDivider(),
            Expanded(
                child: _buildMiniStat('Dmg',
                    '${dino.degats.toStringAsFixed(0)}%', const Color(0xFFEF4444))),
          ]),
          const SizedBox(height: 2),
          Row(children: [
            Expanded(
                child: _buildMiniStat(
                    'Poids',
                    DinoHelpers.formatNumber(dino.poids),
                    const Color(0xFF3B82F6))),
            _buildStatDivider(),
            Expanded(
                child: _buildMiniStat(
                    'Food',
                    DinoHelpers.formatNumber(dino.nourriture),
                    const Color(0xFF8B5CF6))),
            _buildStatDivider(),
            Expanded(
                child: _buildMiniStat('O₂',
                    DinoHelpers.formatNumber(dino.oxygene),
                    const Color(0xFF10B981))),
          ]),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w700)),
          Text(' - ',
              style: GoogleFonts.exo2(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 8)),
          Text(value,
              style: GoogleFonts.exo2(
                  color: color, fontSize: 9, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildStatDivider() => Container(
        width: 1,
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: Colors.white.withValues(alpha: 0.15),
      );

  Widget _buildColorStrip(List<String> dinoColors) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(5),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Row(
        children: List.generate(6, (i) {
          final hex = i < dinoColors.length ? dinoColors[i] : null;
          final isInactive = hex == null ||
              hex == '808080' ||
              hex == '#808080' ||
              hex == '#7F7F7F';
          final color = isInactive
              ? const Color(0xFF1F2937)
              : DinoHelpers.parseHex(
                      hex.startsWith('#') ? hex : '#$hex') ??
                  const Color(0xFF1F2937);
          return Expanded(
            child: Container(
              height: 7,
              margin: EdgeInsets.only(right: i < 5 ? 1 : 0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                    color: Colors.white
                        .withValues(alpha: isInactive ? 0.05 : 0.2),
                    width: 0.5),
                boxShadow: !isInactive
                    ? [
                        BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 2)
                      ]
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHARE PREVIEW
// ═════════════════════════════════════════════════════════════════════════════

class _SharePreviewSheet extends StatelessWidget {
  final String text;
  final int itemCount;

  const _SharePreviewSheet({required this.text, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Liste copiée !',
                            style: GoogleFonts.exo2(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800)),
                        Text(
                            '$itemCount dino${itemCount > 1 ? 's' : ''} · trié par espèce',
                            style: GoogleFonts.exo2(
                                color: AppTheme.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_rounded,
                            color: Colors.green, size: 14),
                        const SizedBox(width: 4),
                        Text('Copié',
                            style: GoogleFonts.exo2(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxHeight: 220),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: SingleChildScrollView(
                child: Text(
                  text,
                  style: GoogleFonts.sourceCodePro(
                    color: const Color(0xFF9ECEF5),
                    fontSize: 11,
                    height: 1.6,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('✅ Copié dans le presse-papier'),
                              duration: Duration(seconds: 2)),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Recopier'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accentPrimary,
                        side: BorderSide(
                            color: AppTheme.accentPrimary
                                .withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text('Fermer',
                          style: GoogleFonts.exo2(
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MODAL SÉLECTION DINOS
// ═════════════════════════════════════════════════════════════════════════════

class _DinoSelectionModal extends StatefulWidget {
  final List<Dino> dinos;
  final int defaultQuantity;
  final OrderItemType defaultType;
  final OrderItemGender defaultGender;
  final Function(List<OrderItem>) onDinosSelected;

  const _DinoSelectionModal({
    required this.dinos,
    required this.defaultQuantity,
    required this.defaultType,
    required this.defaultGender,
    required this.onDinosSelected,
  });

  @override
  State<_DinoSelectionModal> createState() => _DinoSelectionModalState();
}

class _DinoSelectionModalState extends State<_DinoSelectionModal> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedDinoIds = {};
  late List<Dino> _filteredDinos;
  String _activeRoleFilter = '';

  @override
  void initState() {
    super.initState();
    _filteredDinos = widget.dinos;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDinos(String query) {
    setState(() {
      final q = query.toLowerCase();
      _filteredDinos = widget.dinos.where((d) {
        final matchesSearch = query.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.espece.toLowerCase().contains(q);
        final matchesRole =
            _activeRoleFilter.isEmpty || d.tags.contains(_activeRoleFilter);
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  void _toggleSelection(Dino dino) {
    final id = dino.id;
    if (id == null) return;
    setState(() {
      if (_selectedDinoIds.contains(id)) {
        _selectedDinoIds.remove(id);
      } else {
        _selectedDinoIds.add(id);
      }
    });
  }

  void _selectAllVisible() {
    setState(() {
      for (final d in _filteredDinos) {
        if (d.id != null) _selectedDinoIds.add(d.id!);
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedDinoIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final roleThemeProvider = context.watch<RoleThemeProvider>();

    return Column(
      children: [
        // ── Grip ─────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Titre + compteur + actions sélection ─────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Sélectionner des dinos',
                style: GoogleFonts.exo2(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (_selectedDinoIds.isNotEmpty)
                GestureDetector(
                  onTap: _clearSelection,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'Vider',
                      style: GoogleFonts.exo2(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _selectAllVisible,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    'Tout',
                    style: GoogleFonts.exo2(
                      fontSize: 11,
                      color: AppTheme.accentPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_selectedDinoIds.length} sélectionné${_selectedDinoIds.length > 1 ? 's' : ''}',
                  style: GoogleFonts.exo2(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Barre recherche ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF21304A), width: 1.2),
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.exo2(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rechercher un dino...',
                hintStyle: GoogleFonts.exo2(
                    color: const Color(0xFF4A5568), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF4A5568), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF4A5568), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterDinos('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              ),
              onChanged: _filterDinos,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Filtres rôle (chips horizontaux) ─────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              itemBuilder: (context, i) {
                const tags = [
                  '',
                  'Boss',
                  'Breeding',
                  'Solid',
                  'Farm',
                  'Collection',
                  'Combat'
                ];
                final label = i == 0 ? 'Tous' : tags[i];
                final val = tags[i];
                final isActive = _activeRoleFilter == val;
                return GestureDetector(
                  onTap: () {
                    setState(() => _activeRoleFilter = val);
                    _filterDinos(_searchController.text);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(colors: [
                              Color(0xFFFF6B00),
                              Color(0xFFFF9500),
                            ])
                          : null,
                      color: isActive ? null : const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? Colors.transparent
                            : const Color(0xFF21304A),
                        width: 1.2,
                      ),
                    ),
                    child: Text(label,
                        style: GoogleFonts.exo2(
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF6B7A8D),
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w500,
                          letterSpacing: 0.3,
                        )),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Liste des tuiles bibliothèque ────────────────────────────────
        Expanded(
          child: _filteredDinos.isEmpty
              ? Center(
                  child: Text(
                    'Aucun dino trouvé',
                    style: GoogleFonts.exo2(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  itemCount: _filteredDinos.length,
                  itemBuilder: (context, i) {
                    final dino = _filteredDinos[i];
                    final isSelected = _selectedDinoIds.contains(dino.id);
                    final roleTheme =
                        roleThemeProvider.themeForRole(dino.role);

                    return _SelectableLibraryTile(
                      dino: dino,
                      roleTheme: roleTheme,
                      isSelected: isSelected,
                      onTap: () => _toggleSelection(dino),
                    );
                  },
                ),
        ),

        // ── Boutons valider / annuler ────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDinoIds.isEmpty
                      ? null
                      : () {
                          final items = <OrderItem>[];
                          for (final dinoId in _selectedDinoIds) {
                            final dino = widget.dinos
                                .firstWhere((d) => d.id == dinoId);
                            items.add(OrderItem(
                              id: const Uuid().v4(),
                              dinoId: dino.id ?? 0,
                              dinoName: dino.nom,
                              dinoSpecies: dino.espece,
                              dinoColors: dino.colorRegions
                                  .map((c) => c ?? '808080')
                                  .toList(),
                              quantity: widget.defaultQuantity,
                              type: widget.defaultType,
                              gender: widget.defaultGender,
                            ));
                          }
                          widget.onDinosSelected(items);
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary),
                  child: Text('Ajouter (${_selectedDinoIds.length})'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
}// ═════════════════════════════════════════════════════════════════════════════
// TUILE BIBLIOTHÈQUE EN MODE SÉLECTION — utilisée uniquement dans Commande
// ═════════════════════════════════════════════════════════════════════════════
class _SelectableLibraryTile extends StatelessWidget {
  final Dino dino;
  final dynamic roleTheme; // RoleTheme? — typé dynamic pour ne pas forcer l'import ici
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableLibraryTile({
    required this.dino,
    required this.roleTheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Couleur d'accentuation pour l'encadrement sélectionné.
    const Color selectColor = AppTheme.accentPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 4),
        padding: EdgeInsets.all(isSelected ? 3 : 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected
                ? selectColor
                : Colors.transparent,
            width: isSelected ? 2.5 : 0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectColor.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // La VRAIE tuile bibliothèque — strictement identique à celle
            // affichée dans LibraryScreen.
            AbsorbPointer(
              // On absorbe les taps internes pour que la tuile entière
              // se comporte comme un simple bouton de sélection,
              // sans déclencher onTap / onEdit / onDelete.
              absorbing: true,
              child: DinoCardWidget(
                dino: dino,
                onTap: () {},
                onEdit: () {},
                onDelete: () {},
                roleTheme: roleTheme,
              ),
            ),

            // Voile coloré léger quand sélectionné, pour renforcer le feedback
            if (isSelected)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12), // aligne avec margin tuile
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: selectColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),

            // Badge ✓ en haut à droite
            if (isSelected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectColor,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: selectColor.withValues(alpha: 0.6),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

