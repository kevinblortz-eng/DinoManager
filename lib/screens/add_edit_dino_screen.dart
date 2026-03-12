import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/dino.dart';
import '../models/ark_species_data.dart';
import '../models/ark_color_palette.dart';
import '../providers/dino_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/dino_image_widget.dart';
import '../widgets/ark_color_picker.dart';

class AddEditDinoScreen extends StatefulWidget {
  final Dino? dino;
  final bool isDuplicate;
  const AddEditDinoScreen({super.key, this.dino, this.isDuplicate = false});

  @override
  State<AddEditDinoScreen> createState() => _AddEditDinoScreenState();
}

class _AddEditDinoScreenState extends State<AddEditDinoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // ─── Contrôleurs identité ───
  late TextEditingController _nomCtrl;
  late TextEditingController _niveauCtrl;
  late TextEditingController _notesCtrl;

  // ─── Contrôleurs stats (valeurs totales) ───
  late TextEditingController _hpCtrl;
  late TextEditingController _staminaCtrl;
  late TextEditingController _oxygeneCtrl;
  late TextEditingController _nourritureCtrl;
  late TextEditingController _poidsCtrl;
  late TextEditingController _degatsCtrl;
  late TextEditingController _vitesseCtrl;

  // ─── Contrôleurs points investis ───
  late TextEditingController _hpPtsCtrl;
  late TextEditingController _staminaPtsCtrl;
  late TextEditingController _oxygenePtsCtrl;
  late TextEditingController _nourriturePtsCtrl;
  late TextEditingController _poidsPtsCtrl;
  late TextEditingController _degatsPtsCtrl;
  late TextEditingController _vitessePtsCtrl;

  // ─── État formulaire ───
  late String _espece;
  late String _sexe;
  late String _role;
  late String _tagVersion; // compat
  late List<String> _tags; // multi-tags

  // Couleurs ARK : liste de ({id, hex}) pour chaque région
  late List<({int id, String hex})> _couleurs;

  bool _isSaving = false;

  static const List<String> _regionNames = [
    'Corps', 'Tête / Crête', 'Dos / Nervures',
    'Ventre', 'Pattes', 'Queue / Extrémités',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final d = widget.dino;

    _nomCtrl = TextEditingController(text: d?.nom ?? '');
    _niveauCtrl = TextEditingController(text: d != null ? d.niveau.toString() : '');
    _notesCtrl = TextEditingController(text: d?.notes ?? '');

    _hpCtrl = TextEditingController(text: d != null ? d.hp.toString() : '');
    _staminaCtrl = TextEditingController(text: d != null ? d.stamina.toString() : '');
    _oxygeneCtrl = TextEditingController(text: d != null ? d.oxygene.toString() : '');
    _nourritureCtrl = TextEditingController(text: d != null ? d.nourriture.toString() : '');
    _poidsCtrl = TextEditingController(text: d != null ? d.poids.toString() : '');
    _degatsCtrl = TextEditingController(text: d != null ? d.degats.toString() : '');
    _vitesseCtrl = TextEditingController(text: d != null ? d.vitesse.toString() : '');

    _hpPtsCtrl = TextEditingController(text: d != null ? d.hpPoints.toString() : '0');
    _staminaPtsCtrl = TextEditingController(text: d != null ? d.staminaPoints.toString() : '0');
    _oxygenePtsCtrl = TextEditingController(text: d != null ? d.oxygenePoints.toString() : '0');
    _nourriturePtsCtrl = TextEditingController(text: d != null ? d.nourriturePoints.toString() : '0');
    _poidsPtsCtrl = TextEditingController(text: d != null ? d.poidsPoints.toString() : '0');
    _degatsPtsCtrl = TextEditingController(text: d != null ? d.degatsPoints.toString() : '0');
    _vitessePtsCtrl = TextEditingController(text: d != null ? d.vitessePoints.toString() : '0');

    _espece = d?.espece ?? 'Rex';
    _sexe = d?.sexe ?? 'Inconnu';
    _role = d?.role ?? 'Breed';
    _tagVersion = d?.tagVersion ?? '';
    _tags = List<String>.from(d?.tags ?? []);

    // Initialiser les couleurs ARK
    if (d != null) {
      _couleurs = [
        (id: d.colorId0, hex: d.colorHex0),
        (id: d.colorId1, hex: d.colorHex1),
        (id: d.colorId2, hex: d.colorHex2),
        (id: d.colorId3, hex: d.colorHex3),
        (id: d.colorId4, hex: d.colorHex4),
        (id: d.colorId5, hex: d.colorHex5),
      ];
    } else {
      _couleurs = List.generate(6, (_) => (id: 0, hex: '#808080'));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nomCtrl.dispose(); _niveauCtrl.dispose(); _notesCtrl.dispose();
    _hpCtrl.dispose(); _staminaCtrl.dispose(); _oxygeneCtrl.dispose();
    _nourritureCtrl.dispose(); _poidsCtrl.dispose(); _degatsCtrl.dispose(); _vitesseCtrl.dispose();
    _hpPtsCtrl.dispose(); _staminaPtsCtrl.dispose(); _oxygenePtsCtrl.dispose();
    _nourriturePtsCtrl.dispose(); _poidsPtsCtrl.dispose(); _degatsPtsCtrl.dispose(); _vitessePtsCtrl.dispose();
    super.dispose();
  }

  Dino _buildDinoFromForm() {
    // Déduire le rôle principal depuis les tags (rétrocompatibilité)
    final rolesCompatibles = ['Boss', 'Breed', 'PvP', 'Farm', 'Transport', 'Soins', 'Collection', 'Combat'];
    final roleFromTag = _tags.firstWhere(
      (t) => rolesCompatibles.contains(t),
      orElse: () => _tags.isNotEmpty ? _tags.first : 'Autre',
    );

    return Dino(
      id: widget.dino?.id,
      nom: _nomCtrl.text.trim(),
      espece: _espece,
      sexe: _sexe,
      role: roleFromTag,
      niveau: int.tryParse(_niveauCtrl.text) ?? 0,
      hp: int.tryParse(_hpCtrl.text) ?? 0,
      stamina: int.tryParse(_staminaCtrl.text) ?? 0,
      oxygene: int.tryParse(_oxygeneCtrl.text) ?? 0,
      nourriture: int.tryParse(_nourritureCtrl.text) ?? 0,
      poids: int.tryParse(_poidsCtrl.text) ?? 0,
      degats: double.tryParse(_degatsCtrl.text) ?? 0.0,
      vitesse: double.tryParse(_vitesseCtrl.text) ?? 100.0,
      hpPoints: int.tryParse(_hpPtsCtrl.text) ?? 0,
      staminaPoints: int.tryParse(_staminaPtsCtrl.text) ?? 0,
      oxygenePoints: int.tryParse(_oxygenePtsCtrl.text) ?? 0,
      nourriturePoints: int.tryParse(_nourriturePtsCtrl.text) ?? 0,
      poidsPoints: int.tryParse(_poidsPtsCtrl.text) ?? 0,
      degatsPoints: int.tryParse(_degatsPtsCtrl.text) ?? 0,
      vitessePoints: int.tryParse(_vitessePtsCtrl.text) ?? 0,
      couleur0: Dino.encodeColor(_couleurs[0].id, _couleurs[0].hex),
      couleur1: Dino.encodeColor(_couleurs[1].id, _couleurs[1].hex),
      couleur2: Dino.encodeColor(_couleurs[2].id, _couleurs[2].hex),
      couleur3: Dino.encodeColor(_couleurs[3].id, _couleurs[3].hex),
      couleur4: Dino.encodeColor(_couleurs[4].id, _couleurs[4].hex),
      couleur5: Dino.encodeColor(_couleurs[5].id, _couleurs[5].hex),
      tagVersion: _tagVersion,
      tags: List<String>.from(_tags),
      notes: _notesCtrl.text.trim(),
      dateAjout: widget.dino?.dateAjout ?? DateTime.now(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0);
      return;
    }
    setState(() => _isSaving = true);
    final provider = context.read<DinoProvider>();
    final dino = _buildDinoFromForm();
    bool success;
    if (widget.dino == null) {
      success = await provider.addDino(dino);
    } else {
      success = await provider.updateDino(dino);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) {
      Navigator.pop(context, dino);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.dino == null
            ? '${dino.nom} ajouté avec succès !'
            : '${dino.nom} mis à jour !'),
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 2),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Erreur lors de la sauvegarde'),
        backgroundColor: AppTheme.danger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSecondary,
        title: Text(
          widget.isDuplicate
              ? 'Dupliquer : ${widget.dino!.nom}'
              : widget.dino != null
                  ? 'Modifier ${widget.dino!.nom}'
                  : 'Nouveau Dino',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save, size: 18, color: AppTheme.accentPrimary),
              label: const Text('Sauver',
                  style: TextStyle(color: AppTheme.accentPrimary, fontWeight: FontWeight.w700)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentPrimary,
          labelColor: AppTheme.accentPrimary,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 18), text: 'Identité'),
            Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Stats'),
            Tab(icon: Icon(Icons.palette_outlined, size: 18), text: 'Couleurs'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildIdentityTab(),
            _buildStatsTab(),
            _buildColorsTab(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ONGLET 1 : IDENTITÉ
  // ══════════════════════════════════════════════════════════════
  Widget _buildIdentityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDinoPreview(),
          const SizedBox(height: 20),

          _buildSectionTitle('Nom du dino', Icons.label),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nomCtrl,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Ex: Alpha Prime, Shadow Blade...',
              prefixIcon: Icon(Icons.pets, color: AppTheme.accentSecondary),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Espèce', Icons.category),
          const SizedBox(height: 8),
          _buildSpeciesAutocomplete(),
          const SizedBox(height: 16),

          _buildSectionTitle('Niveau total', Icons.trending_up),
          const SizedBox(height: 8),
          TextFormField(
            controller: _niveauCtrl,
            style: TextStyle(color: AppTheme.textPrimary),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'Ex: 224',
              prefixIcon: Icon(Icons.star, color: AppTheme.accentSecondary),
              suffixText: 'Lvl',
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionTitle('Sexe', Icons.wc),
          const SizedBox(height: 4),
          Text(
            'Sélection multiple possible (ex: groupe mixte)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          _buildSexeSelector(),
          const SizedBox(height: 16),

          _buildSectionTitle('Tags', Icons.local_offer),
          const SizedBox(height: 4),
          Text(
            'Catégorisez ce dino (Boss, Farm, Volant, etc.) — utilisés dans les statistiques',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 8),
          _buildMultiTagSelector(),
          const SizedBox(height: 16),

          _buildSectionTitle('Notes', Icons.notes),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesCtrl,
            style: TextStyle(color: AppTheme.textPrimary),
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Infos supplémentaires, observations...',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 56),
                child: Icon(Icons.notes, color: AppTheme.accentSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ONGLET 2 : STATS
  // ══════════════════════════════════════════════════════════════
  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Stats avec points ───
          _buildSectionTitle('Statistiques', Icons.analytics),
          const SizedBox(height: 4),
          Text(
            'Valeur totale (affichée dans ARK)  ·  Points investis à droite',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 12),

          _buildStatWithPoints(
            label: 'HP',
            icon: Icons.favorite,
            color: AppTheme.danger,
            statCtrl: _hpCtrl,
            ptsCtrl: _hpPtsCtrl,
            hintStat: '15420',
          ),
          _buildStatWithPoints(
            label: 'Stamina',
            icon: Icons.bolt,
            color: AppTheme.accentGreen,
            statCtrl: _staminaCtrl,
            ptsCtrl: _staminaPtsCtrl,
            hintStat: '1850',
          ),
          _buildStatWithPoints(
            label: 'Oxygène',
            icon: Icons.air,
            color: AppTheme.info,
            statCtrl: _oxygeneCtrl,
            ptsCtrl: _oxygenePtsCtrl,
            hintStat: '150',
          ),
          _buildStatWithPoints(
            label: 'Nourriture',
            icon: Icons.restaurant,
            color: const Color(0xFF8BC34A),
            statCtrl: _nourritureCtrl,
            ptsCtrl: _nourriturePtsCtrl,
            hintStat: '12000',
          ),
          _buildStatWithPoints(
            label: 'Poids',
            icon: Icons.fitness_center,
            color: const Color(0xFF9C27B0),
            statCtrl: _poidsCtrl,
            ptsCtrl: _poidsPtsCtrl,
            hintStat: '450',
          ),
          _buildStatWithPoints(
            label: 'Dégâts',
            icon: Icons.gavel,
            color: AppTheme.accentPrimary,
            statCtrl: _degatsCtrl,
            ptsCtrl: _degatsPtsCtrl,
            hintStat: '423',
            isDouble: true,
            suffix: '%',
          ),
          _buildStatWithPoints(
            label: 'Vitesse',
            icon: Icons.speed,
            color: AppTheme.accentSecondary,
            statCtrl: _vitesseCtrl,
            ptsCtrl: _vitessePtsCtrl,
            hintStat: '100',
            isDouble: true,
            suffix: '%',
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatWithPoints({
    required String label,
    required IconData icon,
    required Color color,
    required TextEditingController statCtrl,
    required TextEditingController ptsCtrl,
    required String hintStat,
    bool isDouble = false,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône + label
          Container(
            width: 80,
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                      maxLines: 1),
                ),
              ],
            ),
          ),
          // Valeur totale
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: statCtrl,
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
              inputFormatters: isDouble
                  ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))]
                  : [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                hintText: hintStat,
                labelText: 'Valeur',
                suffixText: suffix,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Points investis
          Expanded(
            child: TextFormField(
              controller: ptsCtrl,
              style: TextStyle(color: AppTheme.accentSecondary, fontSize: 14, fontWeight: FontWeight.w700),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Points',
                hintText: '0',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                suffixIcon: Icon(Icons.add_circle_outline, color: AppTheme.accentSecondary, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // ONGLET 3 : COULEURS ARK
  // ══════════════════════════════════════════════════════════════
  Widget _buildColorsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDinoPreview(),
          const SizedBox(height: 20),

          _buildSectionTitle('Couleurs régionales ARK', Icons.palette),
          const SizedBox(height: 4),
          Text(
            'Tapez sur une région pour choisir parmi les ${ArkColorPalette.count} couleurs officielles ARK',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),

          ...List.generate(6, (i) => _buildArkColorRegionRow(i)),
          const SizedBox(height: 16),

          // Bouton reset
          Center(
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _couleurs = List.generate(6, (_) => (id: 0, hex: '#808080'));
              }),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réinitialiser les couleurs'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondary,
                side: const BorderSide(color: AppTheme.borderColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Les ID ARK (1-254) correspondent aux couleurs officielles du jeu. '
                    'Saisissez directement un ID ou choisissez dans la palette.',
                    style: TextStyle(color: AppTheme.info, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArkColorRegionRow(int index) {
    final c = _couleurs[index];
    final color = _parseHex(c.hex);
    final arkColor = c.id > 0 ? ArkColorPalette.fromId(c.id) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showArkColorPicker(index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          child: Row(
            children: [
              // Grande pastille couleur
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2),
                  ],
                ),
                child: Center(
                  child: Text(
                    c.id > 0 ? '${c.id}' : '?',
                    style: TextStyle(
                      color: _isLight(color) ? Colors.black87 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
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
                      'Région $index — ${_regionNames[index]}',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (c.id > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'ID: ${c.id}',
                              style: TextStyle(color: AppTheme.accentPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        if (c.id > 0) const SizedBox(width: 6),
                        Text(
                          arkColor?.name ?? c.hex,
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.colorize, color: AppTheme.textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showArkColorPicker(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArkColorPicker(
        selectedId: _couleurs[index].id,
        selectedHex: _couleurs[index].hex,
        regionName: _regionNames[index],
        regionIndex: index,
        onColorSelected: (result) {
          setState(() => _couleurs[index] = result);
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // APERÇU DINO
  // ══════════════════════════════════════════════════════════════
  Widget _buildDinoPreview() {
    final hexColors = _couleurs.map((c) => c.hex).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          DinoImageWidget(
            species: _espece,
            regionColors: hexColors,
            width: 110,
            height: 80,
            showColorBand: false,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nomCtrl.text.isEmpty ? 'Nouveau Dino' : _nomCtrl.text,
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text('$_espece · $_role',
                    style: TextStyle(color: AppTheme.accentSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                // Bande des 6 couleurs avec IDs
                Row(
                  children: List.generate(6, (i) {
                    final c = _couleurs[i];
                    final color = _parseHex(c.hex);
                    return Expanded(
                      child: Container(
                        height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Center(
                          child: Text(
                            c.id > 0 ? '${c.id}' : '-',
                            style: TextStyle(
                              color: _isLight(color) ? Colors.black87 : Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // AUTOCOMPLETE ESPÈCES
  // ══════════════════════════════════════════════════════════════
  Widget _buildSpeciesAutocomplete() {
    final allSpecies = Dino.especesDisponibles;
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _espece),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return allSpecies.take(30);
        final query = textEditingValue.text.toLowerCase();
        return allSpecies.where((s) => s.toLowerCase().contains(query)).take(25);
      },
      onSelected: (selected) => setState(() => _espece = selected),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Rechercher (260 espèces)...',
            prefixIcon: const Icon(Icons.search, color: AppTheme.accentSecondary),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                    onPressed: () { controller.clear(); setState(() => _espece = 'Rex'); },
                  )
                : null,
          ),
          onChanged: (v) { if (v.isNotEmpty) setState(() => _espece = v); },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: AppTheme.bgCard,
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 380),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final species = options.elementAt(index);
                  final hasImg = ArkSpeciesData.hasImage(species);
                  return ListTile(
                    dense: true,
                    leading: hasImg
                        ? Image.asset(
                            'assets/images/dinos/${species.replaceAll(' ', '_')}_ASA.png',
                            width: 40, height: 32, fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.help_outline, size: 20),
                          )
                        : const Icon(Icons.help_outline, size: 20),
                    title: Text(species, style: TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                    subtitle: ArkSpeciesData.hasMask(species)
                        ? Text('6 régions colorées', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10))
                        : null,
                    onTap: () => onSelected(species),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════

  Widget _buildMultiTagSelector() {
    final provider = context.read<DinoProvider>();
    final availableTags = provider.allTags;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chips des tags disponibles
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            ...availableTags.map((tag) {
              final selected = _tags.contains(tag);
              return FilterChip(
                label: Text(
                  tag,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                selected: selected,
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _tags.add(tag);
                    } else {
                      _tags.remove(tag);
                    }
                  });
                },
                backgroundColor: AppTheme.bgSecondary,
                selectedColor: AppTheme.accentPrimary.withValues(alpha: 0.8),
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: selected
                      ? AppTheme.accentPrimary
                      : AppTheme.borderColor.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            }),
            // Bouton "Ajouter tag personnalisé"
            ActionChip(
              avatar: Icon(Icons.add, size: 14, color: AppTheme.accentGreen),
              label: Text(
                'Nouveau',
                style: TextStyle(color: AppTheme.accentGreen, fontSize: 12),
              ),
              backgroundColor: AppTheme.bgSecondary,
              side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onPressed: () => _showAddTagDialog(provider),
            ),
          ],
        ),
        // Tags sélectionnés actifs
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.label, size: 12, color: AppTheme.accentPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _tags.join('  ·  '),
                    style: TextStyle(
                      color: AppTheme.accentPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showAddTagDialog(DinoProvider provider) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        title: Text('Nouveau tag', style: TextStyle(color: AppTheme.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Ex: Alpha, Mutant, Imprint...',
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text('Ajouter', style: TextStyle(color: AppTheme.accentGreen)),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await provider.addCustomTag(result.trim());
      if (mounted) {
        setState(() => _tags.add(result.trim()));
      }
    }
  }

  /// Sélecteur de sexe avec support multi-sélection.
  /// Valeurs possibles : 'Mâle', 'Femelle', 'Mâle+Femelle', 'Inconnu'
  Widget _buildSexeSelector() {
    // Détermine si Mâle et/ou Femelle sont actifs
    final hasMale = _sexe == 'Mâle' || _sexe == 'Mâle+Femelle';
    final hasFemelle = _sexe == 'Femelle' || _sexe == 'Mâle+Femelle';

    void toggle(String s) {
      setState(() {
        if (s == 'Inconnu') {
          _sexe = 'Inconnu';
          return;
        }
        bool newMale = hasMale;
        bool newFemelle = hasFemelle;
        if (s == 'Mâle') newMale = !newMale;
        if (s == 'Femelle') newFemelle = !newFemelle;

        if (newMale && newFemelle) {
          _sexe = 'Mâle+Femelle';
        } else if (newMale) {
          _sexe = 'Mâle';
        } else if (newFemelle) {
          _sexe = 'Femelle';
        } else {
          _sexe = 'Inconnu';
        }
      });
    }

    return Row(
      children: [
        // ── Mâle ──────────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: () => toggle('Mâle'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: hasMale
                    ? const LinearGradient(
                        colors: [Color(0xFF1A4A7A), Color(0xFF1565C0)],
                      )
                    : null,
                color: hasMale ? null : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasMale ? AppTheme.info : AppTheme.borderColor,
                  width: hasMale ? 2 : 1,
                ),
                boxShadow: hasMale
                    ? [BoxShadow(
                        color: AppTheme.info.withValues(alpha: 0.3),
                        blurRadius: 8,
                      )]
                    : null,
              ),
              child: Column(
                children: [
                  Text('♂',
                      style: TextStyle(
                        fontSize: 24,
                        color: hasMale ? Colors.white : AppTheme.textMuted,
                      )),
                  const SizedBox(height: 2),
                  Text('Mâle',
                      style: TextStyle(
                        color: hasMale ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: hasMale ? FontWeight.w700 : FontWeight.normal,
                      )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Femelle ───────────────────────────────────────────────
        Expanded(
          child: GestureDetector(
            onTap: () => toggle('Femelle'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: hasFemelle
                    ? const LinearGradient(
                        colors: [Color(0xFF7A1A4A), Color(0xFFC2185B)],
                      )
                    : null,
                color: hasFemelle ? null : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasFemelle
                      ? const Color(0xFFF48FB1)
                      : AppTheme.borderColor,
                  width: hasFemelle ? 2 : 1,
                ),
                boxShadow: hasFemelle
                    ? [BoxShadow(
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.3),
                        blurRadius: 8,
                      )]
                    : null,
              ),
              child: Column(
                children: [
                  Text('♀',
                      style: TextStyle(
                        fontSize: 24,
                        color: hasFemelle ? Colors.white : AppTheme.textMuted,
                      )),
                  const SizedBox(height: 2),
                  Text('Femelle',
                      style: TextStyle(
                        color: hasFemelle ? Colors.white : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: hasFemelle ? FontWeight.w700 : FontWeight.normal,
                      )),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // ── Inconnu ───────────────────────────────────────────────
        GestureDetector(
          onTap: () => toggle('Inconnu'),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _sexe == 'Inconnu' ? AppTheme.bgCard : AppTheme.bgSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _sexe == 'Inconnu' ? AppTheme.textMuted : AppTheme.borderColor,
                width: _sexe == 'Inconnu' ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text('?',
                    style: TextStyle(
                      fontSize: 20,
                      color: _sexe == 'Inconnu'
                          ? AppTheme.textSecondary
                          : AppTheme.textMuted,
                    )),
                const SizedBox(height: 2),
                Text('—', style: TextStyle(color: AppTheme.textMuted, fontSize: 9)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.accentSecondary),
        const SizedBox(width: 6),
        Text(title.toUpperCase(),
            style: TextStyle(
                color: AppTheme.accentSecondary, fontSize: 11,
                fontWeight: FontWeight.w700, letterSpacing: 1.2)),
      ],
    );
  }

  Color _parseHex(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return Colors.grey;
  }

  bool _isLight(Color c) => (c.r * 0.299 + c.g * 0.587 + c.b * 0.114) > 0.5;
}
