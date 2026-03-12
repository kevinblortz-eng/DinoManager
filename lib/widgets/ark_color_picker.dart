import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ark_color_palette.dart';
import '../theme/app_theme.dart';

/// Sélecteur de couleur ARK avec palette officielle (IDs 1-254)
/// Affiche une grille de toutes les couleurs disponibles
class ArkColorPicker extends StatefulWidget {
  final int selectedId;
  final String selectedHex;
  final ValueChanged<({int id, String hex})> onColorSelected;
  final String regionName;
  final int regionIndex;

  const ArkColorPicker({
    super.key,
    required this.selectedId,
    required this.selectedHex,
    required this.onColorSelected,
    required this.regionName,
    required this.regionIndex,
  });

  @override
  State<ArkColorPicker> createState() => _ArkColorPickerState();
}

class _ArkColorPickerState extends State<ArkColorPicker> {
  late TextEditingController _searchCtrl;
  late TextEditingController _idCtrl;
  List<ArkColor> _filtered = [];
  int _selectedId = 0;
  String _selectedHex = '#808080';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _selectedHex = widget.selectedHex;
    _searchCtrl = TextEditingController();
    _idCtrl = TextEditingController(
      text: _selectedId > 0 ? _selectedId.toString() : '',
    );
    _filtered = ArkColorPalette.allColors;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  void _filterColors(String query) {
    setState(() {
      if (query.isEmpty) {
        _filtered = ArkColorPalette.allColors;
      } else {
        final lower = query.toLowerCase();
        _filtered = ArkColorPalette.allColors.where((c) =>
          c.name.toLowerCase().contains(lower) ||
          c.id.toString().contains(lower) ||
          c.hex.toLowerCase().contains(lower)
        ).toList();
      }
    });
  }

  void _selectColor(ArkColor color) {
    setState(() {
      _selectedId = color.id;
      _selectedHex = color.hex;
      _idCtrl.text = color.id.toString();
    });
  }

  void _applyIdInput(String val) {
    final id = int.tryParse(val);
    if (id != null) {
      final color = ArkColorPalette.fromId(id);
      if (color != null) {
        setState(() {
          _selectedId = color.id;
          _selectedHex = color.hex;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor = _selectedId > 0
        ? ArkColorPalette.fromId(_selectedId)
        : null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ─── Handle + Titre ───
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppTheme.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.regionIndex}',
                      style: TextStyle(
                        color: AppTheme.accentPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Région ${widget.regionIndex} — ${widget.regionName}',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${ArkColorPalette.count} couleurs ARK disponibles',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── Couleur sélectionnée + ID direct ───
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                // Grande pastille couleur sélectionnée
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: currentColor?.color ?? Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (currentColor?.color ?? Colors.grey).withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentColor?.name ?? 'Aucune couleur',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _selectedId > 0 ? 'ID: $_selectedId' : 'Aucun',
                              style: TextStyle(
                                color: AppTheme.accentPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedHex,
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Saisie ID direct
                SizedBox(
                  width: 72,
                  child: TextFormField(
                    controller: _idCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'ID ARK',
                      labelStyle: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      isDense: true,
                    ),
                    onChanged: _applyIdInput,
                    onFieldSubmitted: _applyIdInput,
                  ),
                ),
              ],
            ),
          ),

          // ─── Barre de recherche ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, ID ou code hex...',
                prefixIcon: Icon(Icons.search, color: AppTheme.accentSecondary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _filterColors('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                isDense: true,
              ),
              onChanged: _filterColors,
            ),
          ),

          // ─── Grille des couleurs ───
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 0.85,
              ),
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final c = _filtered[index];
                final isSelected = c.id == _selectedId;
                return GestureDetector(
                  onTap: () => _selectColor(c),
                  child: Tooltip(
                    message: '${c.id}: ${c.name}\n${c.hex}',
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: c.color,
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
                                  color: c.color.withValues(alpha: 0.6),
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
                              '${c.id}',
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
                  ),
                );
              },
            ),
          ),

          // ─── Bouton Appliquer ───
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      foregroundColor: AppTheme.textSecondary,
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      widget.onColorSelected((id: _selectedId, hex: _selectedHex));
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      'Appliquer (ID: $_selectedId)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton compact pour afficher la couleur d'une région (utilisé dans les listes)
class ArkColorBadge extends StatelessWidget {
  final int arkId;
  final String hex;
  final double size;
  final bool showId;

  const ArkColorBadge({
    super.key,
    required this.arkId,
    required this.hex,
    this.size = 24,
    this.showId = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return Tooltip(
      message: arkId > 0
          ? 'ID: $arkId\n${ArkColorPalette.fromId(arkId)?.name ?? ""}\n$hex'
          : hex,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 3,
            ),
          ],
        ),
        child: showId && arkId > 0
            ? Center(
                child: Text(
                  '$arkId',
                  style: TextStyle(
                    color: _isLight(color) ? Colors.black87 : Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }

  bool _isLight(Color c) {
    return (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.5;
  }
}
