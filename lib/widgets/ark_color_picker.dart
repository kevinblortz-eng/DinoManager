// lib/widgets/ark_color_picker.dart
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../models/ark_color_palette.dart';
import '../theme/app_theme.dart';
import 'common/dino_region_preview.dart';

class ArkColorPicker extends StatefulWidget {
  final int selectedId;
  final String selectedHex;
  final ValueChanged<({int id, String hex})> onColorSelected;
  final String regionName;
  final int regionIndex;

  // ── Nouveaux paramètres pour le preview ──
  final String species;
  final List<String?> currentColors;

  const ArkColorPicker({
    super.key,
    required this.selectedId,
    required this.selectedHex,
    required this.onColorSelected,
    required this.regionName,
    required this.regionIndex,
    required this.species,
    required this.currentColors,
  });

  @override
  State<ArkColorPicker> createState() => _ArkColorPickerState();
}

class _ArkColorPickerState extends State<ArkColorPicker> {
  static const String _emptyHex = '#808080';

  late TextEditingController _searchCtrl;
  late TextEditingController _idCtrl;

  List<ArkColor> _filtered = [];
  int _selectedId = 0;
  String _selectedHex = _emptyHex;
  bool _showEmptyTile = true;

  // Couleur prévisualisée en temps réel sur le dino
  String? _previewHex;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _selectedHex =
        widget.selectedHex.isEmpty ? _emptyHex : widget.selectedHex;

    // Preview initial = couleur déjà sélectionnée
    _previewHex = _selectedId > 0 ? _selectedHex : null;

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
      if (query.trim().isEmpty) {
        _filtered = ArkColorPalette.allColors;
        _showEmptyTile = true;
      } else {
        final lower = query.toLowerCase().trim();
        _showEmptyTile = 'aucune'.contains(lower) ||
            'none'.contains(lower) ||
            '0'.contains(lower) ||
            'vide'.contains(lower);
        _filtered = ArkColorPalette.allColors.where((c) {
          return c.name.toLowerCase().contains(lower) ||
              c.id.toString().contains(lower) ||
              c.hex.toLowerCase().contains(lower);
        }).toList();
      }
    });
  }

  void _selectColor(ArkColor color) {
    setState(() {
      _selectedId = color.id;
      _selectedHex = color.hex;
      _previewHex = color.hex; // ← mise à jour preview temps réel
      _idCtrl.text = color.id.toString();
    });
  }

  void _selectNoColor() {
    setState(() {
      _selectedId = 0;
      _selectedHex = _emptyHex;
      _previewHex = null; // ← reset preview
      _idCtrl.text = '';
    });
  }

  void _applyIdInput(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty || trimmed == '0') {
      _selectNoColor();
      return;
    }
    final id = int.tryParse(trimmed);
    if (id != null) {
      final color = ArkColorPalette.fromId(id);
      if (color != null) {
        setState(() {
          _selectedId = color.id;
          _selectedHex = color.hex;
          _previewHex = color.hex; // ← mise à jour preview
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentColor =
        _selectedId > 0 ? ArkColorPalette.fromId(_selectedId) : null;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ─── Handle ───
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ─── Titre région ───
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        style: const TextStyle(
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
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '${ArkColorPalette.count} couleurs ARK disponibles',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Zone principale : preview + sélection côte à côte ───
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mini dino preview (gauche) ──
                  SizedBox(
                    width: 160,
                    child: DinoRegionPreview(
                      species: widget.species,
                      currentColors: widget.currentColors,
                      activeRegion: widget.regionIndex,
                      previewColor: _previewHex,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ── Couleur sélectionnée + ID (droite) ──
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Carré couleur + nom
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: currentColor?.color ?? Colors.grey,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color:
                                        Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (currentColor?.color ??
                                              Colors.grey)
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: currentColor == null
                                    ? const Center(
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentColor?.name ??
                                          'Aucune couleur',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 5,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.accentPrimary
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    4),
                                          ),
                                          child: Text(
                                            _selectedId > 0
                                                ? 'ID: $_selectedId'
                                                : 'Aucun',
                                            style: const TextStyle(
                                              color:
                                                  AppTheme.accentPrimary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            _selectedHex,
                                            style: const TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                            overflow:
                                                TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Saisie ID directe
                          TextFormField(
                            controller: _idCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              labelText: 'ID ARK',
                              labelStyle: TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 10,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            onChanged: _applyIdInput,
                            onFieldSubmitted: _applyIdInput,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Barre de recherche ───
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, ID ou code hex...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTheme.accentSecondary,
                    size: 20,
                  ),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filterColors('');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
                onChanged: (value) {
                  _filterColors(value);
                  setState(() {});
                },
              ),
            ),

            // ─── Grille des couleurs ───
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.fromLTRB(12, 8, 12, 12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.85,
                ),
                itemCount:
                    _filtered.length + (_showEmptyTile ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_showEmptyTile && index == 0) {
                    final isSelected = _selectedId == 0;
                    return GestureDetector(
                      onTap: _selectNoColor,
                      child: Tooltip(
                        message: 'Aucune couleur\nID: 0\n$_emptyHex',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: const Color(0xFF808080),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.2),
                              width: isSelected ? 2.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Colors.white
                                          .withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Center(
                                  child: Icon(
                                    isSelected
                                        ? Icons.check
                                        : Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 1),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.black.withValues(alpha: 0.45),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(5),
                                    bottomRight: Radius.circular(5),
                                  ),
                                ),
                                child: const Text(
                                  '0',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
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
                  }

                  final colorIndex =
                      _showEmptyTile ? index - 1 : index;
                  final c = _filtered[colorIndex];
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
                              const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 10,
                              ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 1),
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

            // ─── Boutons bas ───
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, bottomInset + 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.borderColor),
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
                        widget.onColorSelected((
                          id: _selectedId,
                          hex: _selectedHex,
                        ));
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: Text(
                        _selectedId > 0
                            ? 'Appliquer (ID: $_selectedId)'
                            : 'Appliquer (aucune)',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700),
                      ),
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

/// Badge compact couleur — inchangé
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
          : 'Aucune couleur\n$hex',
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
                    color:
                        _isLight(color) ? Colors.black87 : Colors.white,
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : arkId == 0
                ? Center(
                    child: Icon(
                      Icons.close,
                      size: size * 0.45,
                      color: Colors.white70,
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

  bool _isLight(Color c) => c.computeLuminance() > 0.5;
}
