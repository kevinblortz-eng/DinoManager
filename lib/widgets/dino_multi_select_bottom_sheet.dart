import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/dino.dart';
import '../theme/app_theme.dart';

class DinoMultiSelectBottomSheet extends StatefulWidget {
  final List<Dino> availableDinos;
  final Dino referenceDino;
  final List<Dino> preSelectedDinos;

  const DinoMultiSelectBottomSheet({
    super.key,
    required this.availableDinos,
    required this.referenceDino,
    this.preSelectedDinos = const [],
  });

  @override
  State<DinoMultiSelectBottomSheet> createState() =>
      _DinoMultiSelectBottomSheetState();
}

class _DinoMultiSelectBottomSheetState
    extends State<DinoMultiSelectBottomSheet> {
  late Set<int> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    // Pré-sélectionner le dino de référence + les éventuels pré-sélectionnés
    _selectedIds = <int>{};

    // Le dino de base est pré-coché
    if (widget.referenceDino.id != null) {
      _selectedIds.add(widget.referenceDino.id!);
    }

    // Ajouter les pré-sélectionnés existants
    for (final d in widget.preSelectedDinos) {
      if (d.id != null) {
        _selectedIds.add(d.id!);
      }
    }
  }

  /// Liste filtrée : dino de base en premier, puis les autres variantes
  /// triées par ordre alphabétique
  List<Dino> get _filteredDinos {
    // 1. Récupérer toutes les vraies variantes (mêmes stats)
    //    INCLUANT le dino de base cette fois
    final List<Dino> others = [];

    for (final dino in widget.availableDinos) {
      // Exclure le dino de base (on l'ajoutera manuellement en premier)
      if (dino.id == widget.referenceDino.id) continue;

      // Vérifier que c'est une vraie variante (mêmes stats exactes)
      if (!dino.hasSameStats(widget.referenceDino)) continue;

      // Appliquer le filtre de recherche
      if (_searchQuery.isNotEmpty &&
          !dino.nom.toLowerCase().contains(_searchQuery.toLowerCase())) {
        continue;
      }

      others.add(dino);
    }

    // 2. Trier les autres par ordre alphabétique
    others.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    // 3. Le dino de base en premier (sauf s'il est filtré par la recherche)
    final List<Dino> result = [];

    final baseMatchesSearch = _searchQuery.isEmpty ||
        widget.referenceDino.nom
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());

    if (baseMatchesSearch) {
      result.add(widget.referenceDino);
    }

    result.addAll(others);

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final allFiltered = _filteredDinos;

    // Les dinos sélectionnés pour le retour
    final selectedDinos = <Dino>[];
    for (final dino in widget.availableDinos) {
      if (dino.id != null && _selectedIds.contains(dino.id!)) {
        selectedDinos.add(dino);
      }
    }
    // Inclure aussi le dino de base s'il est sélectionné
    if (widget.referenceDino.id != null &&
        _selectedIds.contains(widget.referenceDino.id!) &&
        !selectedDinos.any((d) => d.id == widget.referenceDino.id)) {
      selectedDinos.insert(0, widget.referenceDino);
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0A0E1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // ════════════════════════════════════════════════════════════
          // HEADER
          // ════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Barre de glissement
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Titre avec informations contextuelles
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Variantes de Couleur',
                            style: GoogleFonts.exo2(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_toTitleCase(widget.referenceDino.espece)} - Niveau ${widget.referenceDino.niveau}',
                            style: GoogleFonts.cinzelDecorative(
                              color: const Color(0xFFFFD700),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${allFiltered.length} variante(s) avec mêmes stats',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Compteur
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.accentPrimary,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${_selectedIds.length} / 6',
                        style: GoogleFonts.exo2(
                          color: AppTheme.accentPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Barre de recherche
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.accentPrimary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ════════════════════════════════════════════════════════════
          // LISTE DES VARIANTES
          // ════════════════════════════════════════════════════════════
          Expanded(
            child: allFiltered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.palette_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune variante trouvée',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Les variantes doivent avoir exactement\nles mêmes stats que ${widget.referenceDino.nom}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: allFiltered.length,
                    itemBuilder: (context, index) {
                      final dino = allFiltered[index];
                      final isBase = dino.id == widget.referenceDino.id;
                      final isSelected =
                          dino.id != null && _selectedIds.contains(dino.id!);

                      return _buildDinoSelectCard(
                        dino,
                        isSelected,
                        isBase: isBase,
                      );
                    },
                  ),
          ),

          // ════════════════════════════════════════════════════════════
          // FOOTER
          // ════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'ANNULER',
                        style: GoogleFonts.exo2(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _selectedIds.isNotEmpty
                          ? () => Navigator.pop(context, selectedDinos)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.accentPrimary,
                        disabledBackgroundColor:
                            AppTheme.accentPrimary.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'COMPARER (${_selectedIds.length})',
                        style: GoogleFonts.exo2(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // CARTE DE SÉLECTION
  // ════════════════════════════════════════════════════════════════════════
  Widget _buildDinoSelectCard(Dino dino, bool isSelected,
      {bool isBase = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppTheme.accentPrimary
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleSelection(dino),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox custom
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.accentPrimary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.accentPrimary
                          : Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                // Infos du dino
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              dino.nom,
                              style: GoogleFonts.exo2(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Badge "observé" pour le dino de base
                          if (isBase) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700)
                                    .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFFFD700)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                'observé',
                                style: GoogleFonts.exo2(
                                  color: const Color(0xFFFFD700),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dino.roleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: dino.roleColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              dino.role.toUpperCase(),
                              style: TextStyle(
                                color: dino.roleColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            dino.sexeSymbol,
                            style: TextStyle(
                              color: dino.sexeColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Aperçu couleurs (mini bande)
                SizedBox(
                  width: 60,
                  child: Row(
                    children: List.generate(6, (i) {
                      final id = _getColorId(dino, i);
                      final hex = _getColorHex(dino, i);
                      final isActive =
                          id > 0 && hex != '#808080' && hex != '#7F7F7F';
                      final color =
                          isActive ? _parseHex(hex) : const Color(0xFF222222);

                      return Expanded(
                        child: Container(
                          height: 20,
                          margin: EdgeInsets.only(right: i < 5 ? 2 : 0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(
                              color: isActive
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // LOGIQUE DE SÉLECTION
  // ════════════════════════════════════════════════════════════════════════
  void _toggleSelection(Dino dino) {
    if (dino.id == null) return;

    setState(() {
      if (_selectedIds.contains(dino.id!)) {
        _selectedIds.remove(dino.id!);
      } else {
        if (_selectedIds.length < 6) {
          _selectedIds.add(dino.id!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 6 variantes sélectionnables'),
              backgroundColor: AppTheme.danger,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ════════════════════════════════════════════════════════════════════════
  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  int _getColorId(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorId0;
      case 1: return dino.colorId1;
      case 2: return dino.colorId2;
      case 3: return dino.colorId3;
      case 4: return dino.colorId4;
      case 5: return dino.colorId5;
      default: return 0;
    }
  }

  String _getColorHex(Dino dino, int index) {
    switch (index) {
      case 0: return dino.colorHex0;
      case 1: return dino.colorHex1;
      case 2: return dino.colorHex2;
      case 3: return dino.colorHex3;
      case 4: return dino.colorHex4;
      case 5: return dino.colorHex5;
      default: return '#808080';
    }
  }

  Color? _parseHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return null;
  }
}
