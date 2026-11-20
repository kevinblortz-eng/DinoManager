// dino_picker_sheet.dart — Sélecteur de dinos réutilisable (bibliothèque).
// Version publique du modal de sélection utilisé par les commandes :
// recherche + filtres tags + multi-sélection → List<Dino>.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dino.dart';
import '../providers/dino_provider.dart';
import '../utils/dino_helpers.dart';
import '../theme/app_theme.dart';
import 'dino_image_widget.dart';

class DinoPickerSheet extends StatefulWidget {
  /// Sélections pré-cochées (ids).
  final Set<int> initialSelected;
  const DinoPickerSheet({super.key, this.initialSelected = const {}});

  /// Ouvre le sheet et retourne les dinos sélectionnés (vide = annulé).
  static Future<List<Dino>> show(BuildContext context,
      {Set<int> initialSelected = const {}}) async {
    final result = await showModalBottomSheet<List<Dino>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DinoPickerSheet(initialSelected: initialSelected),
    );
    return result ?? [];
  }

  @override
  State<DinoPickerSheet> createState() => _DinoPickerSheetState();
}

class _DinoPickerSheetState extends State<DinoPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Set<int> _selected;
  List<Dino> _all = [];
  List<Dino> _filtered = [];
  String _activeTag = '';

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
    _load();
  }

  Future<void> _load() async {
    _all = context.read<DinoProvider>().dinos;
    setState(() => _filtered = _all);
  }

  void _filter(String query) {
    setState(() {
      final q = query.toLowerCase();
      _filtered = _all.where((d) {
        final matchSearch = query.isEmpty ||
            d.nom.toLowerCase().contains(q) ||
            d.espece.toLowerCase().contains(q);
        final matchTag =
            _activeTag.isEmpty || d.tags.contains(_activeTag);
        return matchSearch && matchTag;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tags = <String>{};
    for (final d in _all) {
      tags.addAll(d.tags);
    }
    final height = MediaQuery.of(context).size.height * 0.85;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          // ── Grip + titre ─────────────────────────────────────────
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(children: [
              const Text('Sélectionner des dinos',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_selected.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _selected.clear()),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('Vider',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              GestureDetector(
                onTap: () => setState(() {
                  for (final d in _filtered) {
                    if (d.id != null) _selected.add(d.id!);
                  }
                }),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Tout',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.accentPrimary,
                          fontWeight: FontWeight.w700)),
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
                  '${_selected.length} sélectionné${_selected.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accentPrimary),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // ── Recherche ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF21304A), width: 1.2),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un dino...',
                  hintStyle:
                      TextStyle(color: Color(0xFF4A5568), fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Color(0xFF4A5568), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                ),
                onChanged: _filter,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // ── Filtres tags ─────────────────────────────────────────
          if (tags.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: tags
                    .map((t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(t,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _activeTag == t
                                        ? Colors.black
                                        : Colors.white70)),
                            selected: _activeTag == t,
                            selectedColor: AppTheme.accentPrimary,
                            backgroundColor: const Color(0xFF1C2333),
                            onSelected: (_) {
                              setState(() =>
                                  _activeTag = _activeTag == t ? '' : t);
                              _filter(_searchCtrl.text);
                            },
                          ),
                        ))
                    .toList(),
              ),
            ),
          // ── Liste ────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? const Center(
                    child: Text('Aucun dino trouvé',
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final d = _filtered[i];
                      final isSel = d.id != null && _selected.contains(d.id);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSel
                              ? AppTheme.accentPrimary.withValues(alpha: 0.12)
                              : const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? AppTheme.accentPrimary
                                : Colors.white.withValues(alpha: 0.06),
                            width: isSel ? 1.4 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () =>
                              setState(() => isSel
                                  ? _selected.remove(d.id)
                                  : _selected.add(d.id!)),
                          leading: DinoCardImage(dino: d, size: 44),
                          title: Text(
                            d.nom.isNotEmpty
                                ? d.nom
                                : DinoHelpers.toTitleCase(d.espece),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${DinoHelpers.toTitleCase(d.espece)} · ${d.sexe} · Nv ${d.niveau}',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isSel
                              ? const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.accentPrimary)
                              : const Icon(Icons.radio_button_unchecked,
                                  color: Colors.white24),
                        ),
                      );
                    },
                  ),
          ),
          // ── Valider ──────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accentPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    final picked = _all
                        .where((d) => d.id != null && _selected.contains(d.id))
                        .toList();
                    Navigator.pop(context, picked);
                  },
                  child: Text(
                    'Ajouter ${_selected.isEmpty ? '' : '(${_selected.length})'}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                        fontSize: 15),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
