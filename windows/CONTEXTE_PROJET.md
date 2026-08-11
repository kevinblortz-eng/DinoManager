# 🦖 DinoManager — Fichier mémoire du projet

## Identité
- Nom : dino_manager (DinoManager)
- Description : ARK Dino Manager – Mobile Smart Breeding
- Version : 1.2.6+16
- Plateforme cible : Mobile (Android principalement)
- Environnement : VS Code + Flutter 3.41.7 / Dart 3.11.5 (Windows 11)

## Architecture (dossiers dans lib/)
- main.dart → point d'entrée
- models/ → structures de données
- database/ → stockage local (Hive)
- providers/ → gestion d'état (provider)
- screens/ → écrans de l'app
- widgets/ → composants UI réutilisables
- services/ → logique métier (scan/OCR, backup, IA Gemini, images)
- l10n/ + generated/ → traductions (FR, EN, DE, ES, IT, PT)
- theme/ → apparence
- utils/ → utilitaires divers

## Dépendances clés
- Stockage : hive, hive_flutter, shared_preferences
- État : provider
- Scan/OCR : google_mlkit_text_recognition, camera, image, image_picker
- IA : http (appels API Gemini ?)
- Export/partage : share_plus, file_picker, excel, saver_gallery
- UI : google_fonts, flutter_colorpicker, cached_network_image

## ⚠️ À vérifier / nettoyer
- Fichiers en double "copy" : app_fr copy.arb, ark_dino_card copy.dart, dino_card_widget copy.dart

## Fonctionnalités (à confirmer)
- Gestion de dinos
- Scan OCR de captures ARK
- Intégration IA Gemini
- Commandes / marchand avec devises
- Tracker d'espèces
- Génération de cartes de partage (canva / share card)
- Thèmes par rôle
- Sauvegarde / restauration

## Journal de travail
(on remplira ici au fur et à mesure : ce qu'on corrige, ce qu'on ajoute)

---
## Notes détaillées par fichier
(à compléter quand on analyse chaque fichier)
### main.dart (point d'entrée)
- Init : Flutter → Hive → DatabaseHelper().init() → orientation portrait → style barres système
- Charge les données AVANT runApp : dinos, trackers, orders, currency, language, gemini
- 8 providers via MultiProvider :
  - DinoProvider, TrackerProvider, OrderProvider, CurrencyProvider,
    LanguageProvider, GeminiProvider (créés avant runApp avec .value)
  - TagThemeProvider, RoleThemeProvider (créés avec create:)
- MaterialApp : thème AppTheme.theme, langue pilotée par LanguageProvider
- Langues actives : fr, en, it, es, pt (⚠️ de = allemand traduit mais NON activé)
- home: MainNavigationScreen

### main_navigation_screen.dart (navigation principale)
- Barre de nav à 5 onglets via IndexedStack (les écrans gardent leur état)
- Index : 0=Simulateur, 1=Bibliothèque, 2=Home, 3=Journal, 4=Commandes
- Démarre sur Home (index 2)
- Bouton central dynamique :
  - Sur Home → bouton vert "Ajouter" (+) → ouvre AddEditDinoScreen (slide vers le haut)
  - Ailleurs → bouton orange "Home" → revient au centre
- navigateToTab(index) passé à HomeScreen pour navigation inter-onglets
- Couleurs : fond 0xFF0D1117, accent commandes = cyan

### ⚠️ Constats à traiter plus tard
- Allemand (de) traduit mais non listé dans supportedLocales
### models/dino.dart (LE modèle central)
- Objet IMMUABLE (tous champs final) → modif via copyWith()
- Champs : id, nom, espece, sexe, role, niveau
- Stats DOUBLES : valeur totale (hp, stamina, oxygene, nourriture, poids,
  degats, vitesse) + points investis (hpPoints, etc.)
- Mutations : string "0/20" + maternal/paternal
- Couleurs : 6 régions au format "ID:HEX" (ID = code ARK 1-254, HEX = affichage)
  - parsing rétrocompatible (hex seul / ID seul / ID:HEX)
  - encodeColor(), encodeColorFromId(), colorToHex()
- Tags : ancien tagVersion (string, compat) + nouveau tags (List<String>, JSON)
- Logique métier :
  - hasSameStats() / isColorVariantOf() → détection variantes couleur
  - statsSignature → identifiant unique de stats
  - especeEmoji, roleColor, sexeColor, sexeSymbol → UI
  - totalPoints → somme des points
- Sérialisation : toMap() / fromMap() (clés en snake_case pour Hive)
- Factories : Dino.empty() (fallback), duplicate(), copyWith()
- Listes statiques : especesDisponibles, rolesDisponibles, sexesDisponibles,
  tagsParDefaut
  - Probleme de lecture de l'OCR, n'est pas fiable
  

### providers/dino_provider.dart (état des dinos)
- ChangeNotifier, utilise DatabaseHelper (singleton _db)
- 2 listes : _dinos (tous) + _filteredDinos (affichés)
  - getter dinos = filtrés / allDinos = tous
- Filtres : searchQuery (nom+espece), filterEspece, filterSexe, filterRole,
  filterTag → _applyFilters()
- CRUD : loadDinos, addDino, updateDino, deleteDino, replaceAllData (restore backup)
- Tags custom : stockés dans SharedPreferences (clé 'custom_tags')
  - allTags = tagsParDefaut + customTags
- Stats : getRoleStats(), getEspeceStats()

### ⚠️ Constats à traiter plus tard (suite)
- Vocabulaire : role 'Breed' vs tag 'Breeding' (incohérence à clarifier)
- roleColor : pas de cas 'Combat' ni 'Autre' → tombe en gris (à vérifier si voulu)
- tagVersion = code mort à terme (traîné "pour compat")
### database/database_helper.dart (stockage Hive)
- SINGLETON. 2 boîtes Hive : 'dinos_box' + 'orders_box'
- Stocke des Map (via toMap/fromMap), PAS d'adapters Hive générés
- ID maison : compteur sous clé '__id_counter__', _nextId() incrémente
  - dinos stockés sous clés 'dino_1', 'dino_2'... / orders sous 'order_<id>'
- init() : insère 4 dinos de démo si base vide (Alpha Prime, Shadow Blade,
  Frost Wing, Terra Stomper)
- CRUD dinos : insertDino, getAllDinos (trié par dateAjout desc), getDinoById,
  updateDino, deleteDino, replaceAllDinos (restore backup, gère IDs+compteur),
  searchDinos, getDinoCount, getDistinctEspeces, clearAll
- CRUD orders : insertOrder, updateOrder, deleteOrder, getOrder, getAllOrders,
  clearAllOrders
- close() : ferme les boîtes

### screens/home_screen.dart (tableau de bord, onglet index 2)
- StatefulWidget, reçoit onNavigateToTab depuis MainNavigationScreen
- Fond image background_home.png + overlay dégradé sombre (errorBuilder secours)
- Header fixe : "ARK MANAGER" (Cinzel) + bouton Paramètres → SettingScreen
- Contenu scrollable via Consumer2<DinoProvider, TrackerProvider>, max 640px :
  - Dino Spotlight : dino aléatoire (_pickSpotlightDino), image miroir, tags, couleurs
  - Répartition par rôle (barres %)
  - Top espèces (médailles)
  - Indice espèces sans tracker (croise dinos vs trackers)
  - Astuce du jour (depuis l10n.homeTips, varie selon date)
- Recharge loadDinos() après retour de détail/ajout

### ⚠️ Constats à traiter plus tard (suite)
- HomeScreen : nombreux textes FR codés en dur (non traduits) :
  sous-titre, Paramètres, empty state, titres de cartes, etc.
- INCOHÉRENCE COULEURS DE RÔLE entre 3 endroits :
  - Dino.roleColor : Breed=vert, Solid=orange, Boss=rouge, Farm=jaune...
  - HomeScreen roleColors : Breed=cyan, Solid=violet, Boss=rouge...
  → besoin d'UNE source de vérité unique (AppTheme ?)
- Pluriels FR codés en dur (ex: 's' conditionnel)
### theme/app_theme.dart (système visuel = source de vérité UI)
- Palette : bgPrimary→bgCard (sombres), accents orange/doré, textes, bordures, statuts
- Dégradés réutilisables (header, card, accent, green)
- ThemeData complet : polices Exo2 (corps) + Cinzel Decorative (titres),
  styles boutons/champs/chips/cards/snackbar
- ⚠️ NE contient PAS les couleurs de rôle (définies ailleurs → incohérence)

### utils/dino_helpers.dart (utilitaires partagés)
- sexeToL10nKey / sexeOptionsL10n (i18n du sexe)
- toTitleCase, formatNumber (12.5k / 1.2m)
- parseHex / hexToColor / isLight / contrastText
- getColorId / getColorHex / isColorActive (accès régions par index)
- getCardRarityColor (couleur selon niveau : or≥362, argent≥222, bronze≥150)
- getRoleDistribution / getSexDistribution / getHighestLevelDino

### models/ark_color_palette.dart (BDD couleurs ARK)
- ~227 couleurs officielles (IDs 1-254) + ID 255 fallback
- idToHex, hexToClosestId (distance RGB), byId, allColors, byIds
- Alimente le format "ID:HEX" des dinos

### models/ark_species_color_regions.dart (régions visibles par espèce)
- Map espèce → [bool x6] (quelles régions 0-5 sont colorables)
- Bcp d'entrées "// Verif" = estimations à valider
- visibilityFor / visibleCount / isVisible (fallback : tout visible)

### models/ark_species_data.dart (BDD espèces + assets)
- speciesWithImages (~230) + speciesWithMasks
- getImageAssetPath → assets/images/dinos/<Nom>_ASA.png
- getMaskAssetPath → <Nom>_ASA_m.png
- ⚠️ 'Minotarchos' dans images mais absente des autres tables

### models/ark_species_group.dart (groupe → fond de carte)
- enum : terrestre (défaut), aquatic, volant, fantastic, compagnon
- groupFor / groupEmoji / groupLabel
- détermine le fond interactif de la DinoCard

### models/role_theme.dart (thème perso par rôle)
- RoleTheme : background + border + text, sérialisable
- RoleThemeDefaults.defaults : Boss/Breed/Solid/Farm/Collection/Combat/Autre
- alimente RoleThemeProvider (couleurs personnalisables)

### models/species_tracker.dart (modèle du module Tracker)
- SpeciesTracker : bestStats, colorBank (couleurs par région),
  anonymousStatEntries, colorObservations
- sous-modèles : BestStatRecord, AnonymousStatEntry, ColorObservation
- factory empty() + toMap/fromMap

### 🔴 PROBLÈME MAJEUR : couleurs de rôle définies à 3+ endroits incohérents
- Dino.roleColor (modèle) ≈ RoleThemeDefaults (cohérents entre eux)
- HomeScreen roleColors = COMPLÈTEMENT décalé (Breed=cyan, Solid=violet...)
- Combat : gris dans Dino, violet dans RoleThemeDefaults, bleu dans Home
- ✅ SOLUTION FUTURE : tout faire pointer vers RoleThemeDefaults (le plus complet)
### widgets/ark_color_picker.dart (sélecteur couleur ARK)
- Bottom sheet 92% écran : preview dino temps réel (DinoRegionPreview) +
  grille 8 col de toutes les couleurs ARK + recherche + saisie ID directe
- Callback onColorSelected (id, hex), tuile "aucune couleur" (id=0)
- Contient aussi ArkColorBadge (badge couleur réutilisable)

### widgets/ark_dino_card.dart (CARTE COMPLÈTE portrait 242×428)
- Carte premium : détail + export. Positionnement pixel-perfect (scale=w/242)
- Fond généré par code (ArkDinoCardBackground selon groupe espèce)
- Éléments : image (avec halos flous), badge LVL, badge sexe, espèce, nom+tag,
  6 stats, 6 carrés couleur
- Force textScaler.noScaling (cohérence app/export)
- Logique Solid/VisualSolid (1ère couleur sur régions visibles)
- _tagColor() couleurs tags codées en dur
- ⚠️ utilise .withOpacity() DÉPRÉCIÉ partout (à migrer en .withValues)

### widgets/dino_card_widget.dart (TUILE compacte liste bibliothèque)
- Tuile horizontale 130px : image circulaire (clipper demi-cercle) + header +
  6 stats compactes + bande 6 couleurs
- _tagColor() DUPLIQUÉ (identique à ArkDinoCard)
- Même logique Solid/VisualSolid

### widgets/dino_image_widget.dart (MOTEUR de coloration ⭐)
- Reproduit l'algo ARKStatsExtractor : base PNG + masque → grain merge pixel
  par pixel (out = clamp(base+tint-128)) modulé par opacité de région
- Traitement Dart pur, avec cache (_lastColors), fallback emoji, bande couleurs
- Contient aussi DinoCardImage (version simple pour listes)
- ⚠️ code mort : _parseHexColor inutilisé + @override dupliqué avant build

### widgets/dino_display_widget.dart (DinoAvatarWidget = ANCIEN système ?)
- Silhouettes dessinées au CustomPainter (Rex/Raptor/Wyvern/Anky/Trike/Spino/
  générique) colorées par région
- PROBABLEMENT obsolète (remplacé par DinoImageWidget) → À VÉRIFIER usage
- ⚠️ MAIS contient aussi widgets utilisés ailleurs ? : ColorRegionsBar,
  DinoRegionColorGrid, StatBar, buildDinoIcon, isLightColor
  → démêler avant toute suppression

### 🔴 Constats techniques à corriger
- ark_dino_card.dart : .withOpacity() déprécié (Flutter 3.41) → migrer en masse
- _tagColor() dupliqué (ArkDinoCard + DinoCardWidget) → centraliser
- Couleurs de tags = ENCORE une palette différente (breed=rose, farm=vert...)
- dino_display_widget.dart : possiblement mort (à confirmer)

### screens/dino_detail_screen.dart (écran consultation d'un dino)
- StatefulWidget, reçoit le Dino. Affiche la ArkDinoCard premium (Hero `dino_${id}`)
- Couleur de thème résolue via _resolveThemeColor() : cherche d'abord une couleur
  de tag (TagThemeProvider), fallback sur dino.roleColor
- Export : bouton qui délègue TOUT à ArkDinoCardExporter.captureAndSave()
- 4 actions : MODIFIER / DUPLIQUER / SUPPRIMER / VARIANTES
- VARIANTES : ouvre DinoMultiSelectBottomSheet (dinos même espèce) → DinoVariantsScreen
- ⚠️ CODE MORT confirmé : _buildVisualSection, _buildMobileLevelBadge,
  _buildMobileGenderBadge, _buildFallbackBg, _buildMobileSpeciesImage,
  _buildTitleSection + constantes _lvlMobileSize/_lvlMobileFontLvl/_lvlMobileFontNum
  (plus appelés depuis que la carte = ArkDinoCard)
- ⚠️ Imports possiblement inutilisés : dino_color_strip, dino_stat_grid,
  dino_share_card_exporter, dino_image_widget → à confirmer via flutter analyze

### screens/dino_variant_screen.dart (export multi-variantes)
- Compose une carte d'export regroupant 1 à 6 variantes de la même espèce
- Capture via RepaintBoundary (_exportKey) à pixelRatio 3.0 → SaveImageHelper
- Layouts adaptatifs selon le nombre (1/2/3/4/5/6 variantes)
- Widgets locaux : _VariantStatGrid, _StatCell, _VariantColorStrip, _ColorSquare
- Bouton PARTAGE désactivé (onPressed: null, TODO "réactiver quand share prêt")
- ⚠️ CODE MORT probable : _buildExportSpeciesTitle (jamais appelé, build utilise
  _buildSpeciesTitle + _buildCommonStats)

### screens/add_edit_dino_screen.dart (éditeur WYSIWYG = cœur du CRUD)
- La DinoCard elle-même est éditable (tap sur chaque zone : nom, niveau, sexe,
  espèce, stats, couleurs)
- Référentiel design 242×428 (identique ArkDinoCard), positionnement via _posCentered
- Stats : valeur + 3 sous-points B(ase)/M(uta)/P(erso) par stat
- Points encodés dans les notes via bloc [PTS:hp=B/M/P,stamina=...]
  → _parsePointsFromNotes() / _buildPointsBlock()
- Couleurs : 6 slots, règle Solid/SolidVisual (_applyColor / _finalizeColorsForSave)
- _applyColorForced() = pose couleur SANS règle solid (utilisé par l'OCR)
- OCR : _launchScanner remplit stats/couleurs, corrige l'imprint
  (raw / (1 + 0.2*imprint/100)) sur HP/Stam/Poids/Attaque
- Boutons "Sauver stats/couleurs" → écrivent dans le TrackerProvider
  (⚠️ créent un tracker silencieusement si absent)
- ✅ ASA : vitesse=100.0 / vitessePoints=0 codés EN DUR = VOLONTAIRE
  (sur ARK Ascended la vitesse n'est plus une stat investissable, seulement
   imprint + buffs) — NE PAS corriger, c'est correct

### screens/tag_theme_screen.dart (gestion couleurs des tags)
- StatelessWidget, Consumer2<DinoProvider, TagThemeProvider>
- Liste tous les tags utilisés + tagsParDefaut, attribue une couleur ARK perso
- _openColorPicker → ArkColorPicker → tagThemeProvider.setTagColor()
- Reset individuel (par tag) + reset global (resetAll)
- _defaultTagColor() = ENCORE une palette de couleurs (voir registre bugs)

---
## 🐛 REGISTRE DES BUGS & DETTE TECHNIQUE (dédupliqué)
Une entrée = un problème réel. Les "fichiers concernés" servent de carte de
localisation (c'est normal de retrouver ces fichiers cités plusieurs fois
ailleurs dans les notes — ici on ne compte le bug qu'UNE fois).

### BUG-01 🔴 Couleurs de tags/rôles définies à 5 endroits incohérents
- PRIORITÉ : haute (visuel cassé, un tag change de couleur selon l'écran)
- Sources divergentes :
  - Dino.roleColor (modèle)
  - HomeScreen roleColors
  - RoleThemeDefaults (models/role_theme.dart)
  - add_edit_dino_screen._tagColor() + ._roleColor()
  - tag_theme_screen._defaultTagColor()
- Exemple de divergence : Breed = rose (add_edit) vs vert (tag_theme) ;
  Solid = doré (add_edit) vs orange (tag_theme) ; Farm/Breed inversés
- SOLUTION : créer lib/utils/tag_color_helper.dart → fonction unique tagColor(tag),
  une seule palette de référence, remplacer les 5 définitions par des appels

### BUG-02 🟠 Logique Solid/SolidVisual dupliquée ET divergente
- PRIORITÉ : haute (rendu différent entre écrans)
- Fichiers : add_edit (_applyColor/_finalizeColorsForSave),
  dino_variant (_VariantColorStrip), ark_dino_card.dart
- DIVERGENCE confirmée : dino_variant reconnaît 'solid' + 'visualsolid' mais
  PAS 'solidvisual' → un dino taggé "solidvisual" s'affiche OK dans l'éditeur
  mais incorrectement dans l'écran variantes
- SOLUTION : extraire un helper unique (ex: SolidColorResolver) partagé

### BUG-03 🟡 Format de couleur incohérent dans _resolvePreviewStyle (add_edit)
- Le faux Dino utilise 'ID|HEX' (pipe) au lieu de 'ID:HEX' (deux-points)
- À VÉRIFIER : Dino._parseColorId/_parseColorHex accepte-t-il le '|' ?
  Sinon parsing silencieusement échoué (preview de fond potentiellement faux)

### BUG-04 🟡 Résidu ARK Survival Evolved : OCR lit encore result.speed
- Fichier : add_edit_dino_screen._launchScanner
- Sur ASA la vitesse n'est plus une stat → écrire "Vitesse: X%" dans les notes
  n'a aucun sens métier
- SOLUTION : supprimer le bloc result.speed du scanner

### BUG-05 🟢 Code mort à nettoyer
- dino_detail_screen : _buildVisualSection, _buildMobileLevelBadge,
  _buildMobileGenderBadge, _buildFallbackBg, _buildMobileSpeciesImage,
  _buildTitleSection + 3 constantes _lvlMobile*
- dino_variant_screen : _buildExportSpeciesTitle
- À confirmer via `flutter analyze` avant suppression

### BUG-06 🟢 Allemand (de) traduit mais absent de supportedLocales
- main.dart : app_de.arb existe, langue non activée

### BUG-07 🟢 Textes FR codés en dur malgré l10n (5-6 langues)
- Fichiers : home_screen, dino_detail, dino_variant, add_edit, tag_theme
- Ex : MODIFIER, DUPLIQUER, "Tap pour nommer", "RÉGION $i", pluriels en 's'
- À traiter en lot (gros volume, faible risque)

### BUG-08 🟢 Effet de bord : création silencieuse de tracker
- add_edit : "Sauver stats/couleurs" crée un tracker sans le dire à l'user
- Pas un bug, mais UX à clarifier (confirmation ?)
### 🔬 MODULE OCR / SCAN (vue d'ensemble)
⚠️ ARCHITECTURE À TRANCHER : DEUX moteurs OCR coexistent + 1 résiduel
- services/dino_ocr_service.dart → DinoOcrService (MOTEUR LOCAL ML Kit, BRANCHÉ)
  - Singleton. scanImage(File) → DinoOcrResult
  - _detectSourceType() : Cryopod vs Tek vs unknown (par marqueurs texte)
  - _parseCryopod() / _parseTekOrInventory() : 2 parsers dédiés
  - Matching espèces par distance de Levenshtein (_similarity ≥ 0.6/0.7)
  - 3 stratégies d'extraction couleurs (_extractColorsCryopod) → fragile
  - Gestion imprint : baseVal = displayed / (1 + 0.2*imprint/100)
  - Modèles : DinoOcrResult (+ toDino()), OcrStat, OcrSourceType (enum)
- services/gemini_ocr_service.dart → GeminiOcrService (MOTEUR IA DISTANT)
  - Envoie image base64 → API gemini-2.0-flash → JSON structuré
  - Quota 1500/j, 15/min. Clé via Paramètres. Fallback prévu → ML Kit local
  - validateApiKey() (static), GeminiOcrException
  - Retourne aussi un DinoOcrResult (même modèle, bonne nouvelle)
- ArkDinoScannerService (fichier ?) → VIEUX MOTEUR primitif, CODE MORT
  - Heuristique "plus grande valeur = HP", imports déjà commentés
  - Remplacé par DinoOcrService → À ARCHIVER/SUPPRIMER
- services/dino_scan_helper.dart → DinoScanHelper (POINT D'ENTRÉE)
  - launchScan() : dialog source → DinoScanScreen (caméra/galerie)
  - getColorHex(id) static (⚠️ dupliqué dans DinoScanButton)
- services/image_preprocessor.dart → ImagePreprocessor
  - checkQuality() : luminosité/contraste/flou(Laplacien)/taille
  - preprocess() : grayscale + blur + histogram stretch + seuil adaptatif + upscale
  - preprocessForGemini() : version douce (PAS de binarisation, IA lit mieux)

### widgets du scan
- widgets/dino_scan_button.dart → DinoScanButton
  - A SA PROPRE logique picker + DinoOcrService direct + _showScanResult (AlertDialog)
  - ⚠️ Doublonne DinoScanHelper → vérifier s'il est encore utilisé
- widgets/scan_crop_overlay.dart → ScanCropOverlay
  - Cadre de recadrage interactif (8 poignées), grille tierce, painter, pulsation
  - Coordonnées normalisées 0..1
- widgets/scan_result_review_sheet.dart → ScanResultReviewSheet
  - Bottom sheet de revue (DraggableScrollableSheet) avant transfert DinoCard
  - ⚠️ Doublonne _showScanResult de DinoScanButton (2 UI de revue concurrentes)
### widgets/capture_guide_overlay.dart (guide caméra)
- CaptureGuideDialog (StatefulWidget) : dialog affiché AVANT prise de photo
- 6 conseils rotatifs (Timer 3s, _tips), thème sombre 0xFF0A0E1A, accent cyan 0xFF00E5FF
- Cadre 16:9 + coins décoratifs (_buildCornerBrackets), bouton "OUVRIR LA CAMÉRA"
- ✅ Utilise déjà .withValues(alpha:) (pas de dépréciation ici)
- ⚠️ Textes FR codés en dur (titre, conseils, bouton) → BUG-07
- ⚠️ USAGE À CONFIRMER : aucun des fichiers analysés ne l'instancie
  (DinoScanButton ouvre directement le picker sans passer par ce guide)

### widgets/dino_scan_button.dart (bouton scan AUTONOME)
- StatelessWidget. Bouton "SCANNER CRYOPOD / TEK" (accent cyan)
- Flux COMPLET et INDÉPENDANT :
  _showSourcePicker → ImagePicker (camera/galerie, maxW 1920 maxH 1080 q95)
  → loader → DinoOcrService().scanImage() → _showScanResult (AlertDialog)
  → "CRÉER DINOCARD" → result.toDino() → AddEditDinoScreen
- ⚠️ N'UTILISE NI DinoScanHelper NI ScanResultReviewSheet
  → 2e chemin de scan concurrent confirmé (voir BUG-09 / BUG-12)
- ⚠️ _getColorHex() : traite ArkColorPalette.allColors comme List<Map>
  (c['id'], c['hex']) → INCOMPATIBLE avec l'usage de setting_screen (voir BUG-11)
- ⚠️ _parseHex() réimplémenté localement (déjà dans dino_helpers) → BUG-10
- ⚠️ Affiche/transfère result.speed (Speed) → résidu ASA (voir BUG-04/BUG-13)

### widgets/dino_multi_select_bottom_sheet.dart (sélecteur de variantes)
- DinoMultiSelectBottomSheet (StatefulWidget), hauteur 85% écran
- Reçoit availableDinos + referenceDino + preSelectedDinos
- _filteredDinos : dino de base en 1er, puis variantes (hasSameStats),
  triées alpha, filtrées par recherche nom
- Pré-coche le dino de base + préselectionnés ; limite stricte à 6
- Retourne List<Dino> via Navigator.pop → consommé par dino_detail (VARIANTES)
- ⚠️ _parseHex / _getColorId / _getColorHex / _toTitleCase réimplémentés
  localement (doublonnent dino_helpers / Dino) → dette de centralisation
- Utilise dino.roleColor directement (cohérent modèle, voir BUG-01)

### widgets/background/ark_dino_card_theme_resolver.dart (thèmes de carte)
- enum ArkCardTheme { goldDark, silver, oceanBlue, emerald, crimson, obsidian }
- ArkDinoCardThemes._themes : catalogue thème → ArkDinoCardBackgroundStyle
- ArkDinoCardThemeResolver.resolveTheme(dino) : règles ordonnées
  1) globalOverride (si défini, ignore tout)
  2) tag 'boss' → crimson
  3) tag 'collection' → obsidian
  4) groupe espèce : aquatic→oceanBlue, compagnon→emerald, autres→défaut
  5) défaut → goldDark
- resolveStyle(dino) = raccourci style appliqué
- 📌 NOTE : règles tags 'boss'/'collection' en dur ici = ENCORE une logique
  tag séparée (à rapprocher de la future source unique des tags, BUG-01)

### widgets/background/ark_dino_card_background.dart (fond carte généré par code)
- ArkDinoCardBackgroundStyle : ~50 params (dégradé, halo œuf ovoïde, bannière
  dorée à pans repliés, mini-bannière nom, 6 cases stats avec halo)
- Référentiel 242×428, scale = width/refW
- Presets statiques : goldDark (défaut), silver
- _ArkDinoCardBackgroundPainter : peint gradient → cases stats → halo œuf
  → bannière → bannière nom
- ⚠️ UTILISE .withOpacity() (DÉPRÉCIÉ) à plusieurs endroits
  (haloGlowColor, leftTailPaint, foldPaint, shine, statCellFill...)
  → migration .withValues(alpha:) à faire (mêmes constats qu'ark_dino_card)

### utils/save_image_helper.dart (sauvegarde galerie)
- _getAndroidSdk() via device_info_plus (fallback 30)
- requestPermissions() : Android SDK≥29 → laisse SaverGallery gérer (return true) ;
  SDK<29 → Permission.storage ; iOS → Permission.photosAddOnly ;
  permanentlyDenied → _showPermissionDialog
- generateFileName(espece, nom) : nettoie + ID aléatoire 100-999 → "<esp>-<nom>-ID<n>.png"
- saveAndNotify() : SaverGallery.saveImage(quality 100, png,
  androidRelativePath 'Pictures/DinoManager', skipIfExists false) + Snackbar
- ✅ Utilise déjà .withValues(alpha:)
- ⚠️ Textes FR codés en dur (snackbars, dialog permission) → BUG-07
- 📌 Point d'entrée d'export utilisé par dino_variant_screen (RepaintBoundary→png)

### screens/setting_screen.dart (paramètres = hub central)
- SettingScreen → Consumer<LanguageProvider> → _SettingScreenContent (Stateful)
- Consumer4<DinoProvider, TrackerProvider, TagThemeProvider, RoleThemeProvider>
- Sections : Header(version) / Langue / Sauvegarde(→BackupScreen) /
  Bestiaire(stats+progression espèces) / Tags / Thèmes de rôle / Gemini OCR /
  Actualités(changelog) / Version footer
- Langue : LanguageProvider.supportedLanguages (liste affichée ici)
- Tags : _buildTagsSection RÉIMPLÉMENTE la gestion couleur tags
  (_openTagColorPicker + ArkColorPicker) → DOUBLONNE screens/tag_theme_screen.dart
- Thèmes rôle : _RoleThemeEditorSheet (3 slots fond/bordure/texte) + _ArkColorGrid
- Gemini : _GeminiApiKeyField (setApiKey/validate/clear), toggle isEnabled,
  tutoriel "how to get key", quota 1500/j 15/min, fallback ML Kit annoncé
- ⚠️ _defaultTagColor() + _hexToColor() = COPIE EXACTE de tag_theme_screen
  → confirme la duplication palette tags (BUG-01)
- ⚠️ _ArkColorGrid : ArkColorPalette.allColors traité comme List<objet>
  (arkColor.color, arkColor.id) → INCOMPATIBLE avec dino_scan_button (BUG-11)
- ⚠️ Beaucoup de libellés Gemini/tutoriel en EN/FR codés en dur (i18n partielle)
- 📌 Onglet "Bestiaire" croise dinos vs especesDisponibles vs trackers

### screens/tag_theme_screen.dart vs setting_screen (DUPLICATION ÉCRAN)
- DEUX gestionnaires de couleurs de tags coexistent :
  • screens/tag_theme_screen.dart (StatelessWidget dédié, liste verticale)
  • setting_screen._buildTagsSection (Wrap de chips dans la page Paramètres)
- Les deux : même _defaultTagColor, même ArkColorPicker, même TagThemeProvider
- ⚠️ À TRANCHER : lequel est réellement routé ? supprimer le mort

---
## 🐛 MISE À JOUR DU REGISTRE (suite, après analyse des nouveaux fichiers)

### BUG-01 🔴 (renforcé) — la palette de tags est dupliquée à 6+ endroits
- AJOUT : setting_screen._defaultTagColor() = copie EXACTE de
  tag_theme_screen._defaultTagColor()
- AJOUT : règles tag 'boss'/'collection' dans ark_dino_card_theme_resolver
- => source unique tagColor(tag) à imposer partout (helper lib/utils/)

### BUG-11 🟡 (précisé, à VÉRIFIER EN PRIORITÉ) — ArkColorPalette.allColors
- USAGES INCOMPATIBLES constatés :
  • dino_scan_button._getColorHex → allColors AS List<Map> (c['id']/c['hex'])
  • setting_screen._ArkColorGrid → allColors AS List<objet> (.color/.id)
  • tag_theme_screen / setting_screen → ArkColorPalette.hexToClosestId(hex)
- L'un des deux accès est forcément cassé silencieusement
  (DinoScanButton tombe sur orElse:null → '#808080' = gris par défaut)
- ACTION : ouvrir models/ark_color_palette.dart, vérifier le type réel de
  allColors (List<Map> ou List<ArkColor>) + existence de .color/.id/idToHex,
  puis corriger l'accès fautif AVANT toute autre modif scan

### BUG-09/12 🟠 (confirmés) — DinoScanButton = 2e chemin de scan complet
- DinoScanButton ne passe PAS par DinoScanHelper ni ScanResultReviewSheet
- Il appelle DinoOcrService directement + _showScanResult (AlertDialog)
- => décider du chemin canonique, supprimer/archiver l'autre

### BUG-10 🟢 (confirmé + élargi) — helpers couleur réimplémentés partout
- _getColorHex : DinoScanButton + DinoScanHelper
- _parseHex / _hexToColor : dino_scan_button, dino_multi_select,
  tag_theme_screen, setting_screen (alors que dino_helpers.parseHex existe)
- _toTitleCase / _getColorId : dino_multi_select (déjà dans Dino/dino_helpers)
- => centraliser vers dino_helpers.dart

### BUG-14 🟢 (nouveau) — .withOpacity déprécié dans ark_dino_card_background.dart
- Migration partielle de l'app : fichiers récents en .withValues(alpha:),
  ce fichier + ark_dino_card encore en .withOpacity()
- => migrer en lot (faible risque, géré par flutter analyze / dart fix)

### BUG-15 🟢 (nouveau) — CaptureGuideDialog usage non confirmé
- Aucun fichier analysé ne l'instancie ; DinoScanButton ouvre le picker direct
- => vérifier les références (grep CaptureGuideDialog) avant de le garder
### 🟫 MODULE SHARE / EXPORT — DEUX GÉNÉRATIONS (décision archi clé)

⚠️ DÉCISION D'ARCHITECTURE VALIDÉE PAR LE PROPRIÉTAIRE :
Les premières cartes de partage (DinoShareCard + DinoShareCardPortrait) ont été
ABANDONNÉES car elles RECOPIAIENT manuellement la mise en page d'ArkDinoCard,
ce qui créait des INCOHÉRENCES entre l'aperçu écran et l'image exportée.
=> Solution retenue : exporter DIRECTEMENT la vraie ArkDinoCard via
   ArkDinoCardExporter (pas de recopie → zéro divergence visuel/export).
SOURCE DE VÉRITÉ EXPORT = ArkDinoCard. Ne JAMAIS recréer une carte parallèle.

— GÉNÉRATION ABANDONNÉE (code legacy, candidats archivage) —
• widgets/share_card/dino_share_card.dart → DinoShareCard (paysage 1280×807)
  - Recopie manuelle d'ArkDinoCard (header, stats grid, color strip)
  - Fond assets/images/ui/share_card_bg.png
  - _RoleBadge._tagColor() = ENCORE une palette tags (Boss=EF4444,
    breeding=F48FB1, solid/visualsolid=FFD700, farm=4CAF50, collection=8B5CF6,
    combat=FF6B00) + _dietColor via ArkSpeciesStatsDb
• widgets/share_card/dino_share_card_exporter.dart → DinoShareCardExporter
  - OverlayEntry hors-écran + RepaintBoundary + toImage(devicePixelRatio réel)
• widgets/share_card/dino_share_card_portrait.dart → DinoShareCardPortrait (607×1077)
  - Recopie manuelle avec coordonnées ABSOLUES mesurées sur le fond
    (_Rect/_Circle codés en dur : ovale, parchemin, bandeau, 6 stats, couleurs)
  - Fond share_card_portrait_bg.png + assets icônes stats (hp/stamina/...)
  - _NameBand._tagColor() = MÊME palette dupliquée que ci-dessus
  - Utilise ArkSpeciesColorRegions.visibilityFor (masque zones inactives) ✅
• widgets/share_card/dino_share_card_portrait_exporter.dart
  → DinoShareCardPortraitExporter (même technique Overlay+RepaintBoundary)

— GÉNÉRATION ACTIVE (à conserver) —
• widgets/share_card/ark_dino_card_exporter.dart → ArkDinoCardExporter ⭐
  - Exporte la VRAIE ArkDinoCard (dino + roleTheme) dans un SizedBox 242×428
  - pixelRatio = exportWidth(1080)/242 ≈ 4.46 → PNG final ~1080×1908
  - Technique : OverlayEntry hors-écran + RepaintBoundary + toImage
  - Délais de rendu : 500ms + endOfFrame + 300ms (laisse charger asset/file)
  - Appelé par dino_detail_screen (bouton export)
  - ⚠️ Commentaire dit "1080×1908" mais ratio 242:428 → vérifier dimension réelle

⚠️ ACTION FUTURE : confirmer qu'AUCUN écran n'importe encore DinoShareCard /
   DinoShareCardPortrait (grep), puis archiver/supprimer les 4 fichiers legacy.
   NB : dino_detail_screen avait un import "dino_share_card_exporter" listé
   comme potentiellement inutilisé (BUG-05) → cohérent avec l'abandon.

### widgets/share/canva_edit_dinos_modal.dart (sélecteur Canva)
- CanvaEditDinosModal (StatefulWidget) + helper .show() (bottom sheet 95%)
- Sélection multi-dinos d'UNE espèce pour un "Canva" (planche multi-cartes)
- Recherche nom OU tag, chips top-4 tags, "Effacer filtres", "Tous/Aucun"
- Limite maxSelection=16 (toast si dépassé à la validation)
- 1 favori max (⭐) parmi les cochés ; filtre n'efface jamais la sélection
- Retourne CanvaEditResult(selected, favorite) au canvas appelant
- Affiche chaque dino via DinoCardWidget enveloppé dans SelectableHalo
- 📌 RÉVÈLE un module "Canva" non encore cartographié (écran Canva appelant ?)
  → À TROUVER : qui appelle CanvaEditDinosModal.show et où vit le canvas

### widgets/share/selectable_halo.dart (halo de sélection réutilisable)
- SelectableHalo : enveloppe un child pour mode sélection
- Hors selectionMode → passthrough (onTap/onLongPress)
- En selectionMode → AbsorbPointer sur child + halo accent + badge ✓ +
  badge ⭐ favori optionnel (showFavoriteToggle)
- ✅ Widget propre et générique, réutilisable

### widgets/common/dino_stat_grid.dart (grille stats détaillée)
- DinoStatGrid : 2×3 cases (VIE/STAM/ATTAQUE, POIDS/FOOD/OXYGÈNE) + emojis
- 3e PARSER du bloc [PTS:...] (après add_edit et dino_variant) :
  _parsePointsData / _parseNum (gère virgule+point) / _formatNum
  → clés attendues : hp, stamina, degats, poids, nourriture, oxygene
- ⚠️ DUPLICATION logique points (voir dette : parser [PTS:] à centraliser)
- ⚠️ Import listé comme potentiellement inutilisé dans dino_detail (BUG-05)
  → confirmer usage réel

### widgets/common/dino_sex_badge.dart (badge sexe réutilisable)
- DinoSexBadge : Mâle(4FC3F7)/Femelle(F48FB1)/Mâle+Femelle(purple)/Inconnu(grey)
- static colorForSexe() — ENCORE une définition couleur sexe en parallèle
  de Dino.sexeColor → vérifier cohérence avec le modèle (dette mineure)
- 📌 Supporte 'Mâle+Femelle' (variante bi-sexe gérée à plusieurs endroits)

### widgets/common/dino_region_preview.dart (preview coloration région)
- DinoRegionPreview : mini-aperçu DinoImageWidget + 6 chips régions
- Région active → previewColor sinon rouge #FF4444 (surbrillance)
- Autres → couleur actuelle ou gris neutre #808080/#7F7F7F
- Utilisé par ArkColorPicker (preview temps réel) — cohérent
- 📌 Réimplémente sa propre détection "gris neutre" (808080/7F7F7F)
  → 4e endroit où cette règle apparaît (à centraliser)

### widgets/common/dino_color_strip.dart (bande couleurs ✅ MODÈLE PROPRE)
- DinoColorStrip : 6 cases avec ID, via DinoHelpers exclusivement
  (getColorId, getColorHex, isColorActive, parseHex, contrastText, isLight)
- ✅ EXEMPLE À SUIVRE : aucune réimplémentation locale, tout délégué à dino_helpers
- ⚠️ Import listé comme potentiellement inutilisé dans dino_detail (BUG-05)

---
## 🐛 MISE À JOUR DU REGISTRE (lot share/common)

### BUG-01 🔴 (renforcé encore) — palette de tags dupliquée
- AJOUT : dino_share_card._RoleBadge._tagColor (palette "add_edit")
- AJOUT : dino_share_card_portrait._NameBand._tagColor (idem)
- NB : ces 2 sont dans du code legacy abandonné → ne comptent QUE si non archivés
- Total recensé des _tagColor/_defaultTagColor/_roleColor : add_edit,
  tag_theme_screen, setting_screen, ark_dino_card, dino_card_widget,
  ark_dino_card_theme_resolver(boss/collection), + 2 legacy share_card

### BUG-16 🟢 (nouveau) — parser du bloc [PTS:...] dupliqué 3×
- add_edit_dino_screen (_parsePointsFromNotes), dino_variant_screen,
  dino_stat_grid (_parsePointsData)
- => extraire un util unique parsePoints(notes) dans dino_helpers
- ⚠️ Vérifier que les 3 utilisent le MÊME jeu de clés (hp/stamina/degats/
  poids/nourriture/oxygene) et le même séparateur '/'

### BUG-17 🟢 (nouveau) — détection "gris neutre" (#808080/#7F7F7F) éparpillée
- dino_share_card, dino_share_card_portrait, dino_region_preview,
  dino_multi_select, dino_scan_button (+ DinoHelpers.isColorActive existe déjà)
- => imposer DinoHelpers.isColorActive partout (dino_color_strip le fait déjà)

### BUG-18 🟢 (nouveau) — couleurs de sexe définies en double
- Dino.sexeColor (modèle) vs DinoSexBadge.colorForSexe (widget)
- valeurs à comparer (Mâle 4FC3F7, Femelle F48FB1...) → vérifier identité

### DETTE-ARCHI (nouveau) — module CANVA partiellement inconnu
- CanvaEditDinosModal existe mais l'écran Canva (canvas multi-cartes) appelant
  n'a pas encore été fourni → à cartographier (planche 16 dinos max, 1 favori)

### 🟦 MODULE CANVA — composition & export 4:5 (1080×1350) ✅ CARTOGRAPHIÉ
- ARCHITECTURE PROPRE : moteur de layout pur + exporteur offscreen + briques
  visuelles partagées + 3 écrans assembleurs + 2 pickers + 1 écran batch
- SOURCE DE VÉRITÉ EXPORT = la vraie CanvaBubble rendue à exportScale=2.5
  (confirme l'abandon des DinoShareCard)

#### Moteur (logique pure, zéro dépendance UI au-delà de Rect/Size)
- widgets/canva/canva_layout_engine.dart → CanvaLayout (static)
  - compute(nDinos, withStatsBubble, zoneSize, scale)
    → CanvaPlacements(dinoSlots, statsRect?)
  - Recherche auto grille (_findBestLayout) : maximise surface cellule,
    ratio ~carré, pénalités ratio + remplissage
  - Cas spéciaux : 0 dino+stats (stats plein cadre), 1 dino+stats (split 50/50),
    0+0 (vide)
  - Stats = 2 cellules sur dernière ligne, s'étire pour combler ;
    dernière ligne sans stats centrée
  - Constantes : _baseGap=6, _basePadding=8, _minCellSize=30, _maxColsToTry=6
  - GridShape(rows, cols), CanvaPlacements immuables

#### Exporteur offscreen
- widgets/canva/canva_exporter.dart → CanvaExporter ⭐ (génération ACTIVE)
  - capture(...) : precache → render-tree offscreen
    (RenderView + PipelineOwner + BuildOwner) → N passes build/layout/paint
    → toImage → SaveImageHelper
  - kCanvaExportWidth=1080, kCanvaExportHeight=1350 (4:5 STRICT, contrairement
    à ArkDinoCardExporter qui est ~1080×1908)
  - Passes adaptatives selon nb images : ≤4→3 passes/80ms, ≤8→5/120ms, sinon 8/120ms
  - precacheImages() : FileImage perso + AssetImage fallback (<Espece>_ASA.png)
    + _decodeImage (timeout 5s) + 2× endOfFrame
  - generateFileName(prefix) : Canva_<PREFIX>_<DDMMMYYHHMMSS> (mois FR)
  - ✅ Utilise déjà .withValues(alpha:)

#### Briques visuelles partagées
- widgets/canva/canva_bubble_widgets.dart (tout public, exportScale propagé)
  - CanvaBubble (fond flouté radial + image nette + badge LVL + badge sexe/favori
    + CanvaColorStrip ; speciesTagOverride pour multi)
  - SpeciesNameTag (bandeau espèce au-dessus d'une bulle, multi)
  - SpeciesTitleBanner (titre général en haut, ShaderMask doré)
  - StatsBubble → CanvaStatGrid (3×2) → CanvaStatCell (emoji + label + valeur + pts)
  - CanvaColorStrip → CanvaColorSquare (6 cases avec ID)
  - ✅ Utilise déjà .withValues(alpha:) partout

#### Écrans assembleurs
- screens/dino_canva_screen.dart → DinoCanvaScreen (MONO-espèce, param filterBySpecies)
  - State : _ordered, _favorite, _showSpeciesTitle, _showStats, _isCapturing
  - Drag&drop (_swap), double-tap suppression, toggles Espèce/Stats, compteur /16
  - Bouton export + bouton "Export auto série" → DinoCanvaBatchExportScreen
  - _statsSourceDino : favori OU stats communes (commonInt/commonDbl)
- screens/dino_canva_multi_screen.dart → DinoCanvaMultiScreen (MULTI-espèces)
  - Variante : titre "COMPOSITION MULTI" si >1 espèce, bandeau espèce par bulle
  - Stats DÉSACTIVÉES si multi-espèces (_statsToggleEnabled = !_isMultiSpecies && ...)
  - ⚠️ PAS de bouton batch export ici (présent uniquement en mono)

#### Pickers
- screens/dino_canva_picker_screen.dart → DinoCanvaPickerScreen (+ DinoCanvaPickerResult)
  - filterBySpecies=true → 1 espèce ; false → toutes + chips espèce
  - Max 16, 1 favori, recherche nom/espèce/tag, chips tags top-4, toast overlay
- screens/dino_canva_multi_picker_screen.dart → DinoCanvaMultiPickerScreen (+ result)
  - Toujours toutes espèces + chips espèce + badge "N esp." dans la barre sélection

#### Batch
- screens/dino_canva_batch_export_screen.dart → DinoCanvaBatchExportScreen
  - Source (all/species/tag) + filtres extra + nb/image (4/6/8/9/12/16)
    + tri (5 types) + options (titre/stats/numérotation)
  - Génération séquentielle via CanvaExporter, log temps réel, annulation,
    reprise (_resumeFrom)
  - _buildPageCanvas réserve titleHeight et shift les slots de canvasZoneTop

---
## 🐛 MISE À JOUR DU REGISTRE (lot Canva)

### BUG-CANVA-01 🟠 (nouveau) — batch : RangeError si zone titre > zone canvas
- _buildPageCanvas : canvasZoneHeight = h - titleHeight ; si ≤ 0, CanvaLayout
  renvoie dinoSlots:[] mais la boucle accède placements.dinoSlots[i] → crash
- Improbable en offscreen 1350px, mais la garde manque

### BUG-CANVA-02 🟠 (nouveau) — batch : accès non gardé dinoSlots[i]
- mono/multi font `i < placements.dinoSlots.length` ; le batch NE le fait PAS
- Si _findBestLayout renvoie null (trop de dinos / zone trop petite)
  → dinoSlots vide → RangeError
- => aligner le batch sur la garde mono/multi

### BUG-CANVA-03 🟢 (nouveau) — paramètre mort
- _titleForPage(pageIndex, total, pageDinos) reçoit pageDinos sans l'utiliser
  → flutter analyze

### BUG-CANVA-04 🟢 (nouveau) — _DraggableBubbleSlot + _ToggleChip dupliqués
- Copie quasi-intégrale entre dino_canva_screen et dino_canva_multi_screen
  (seule diff : speciesTag)
- => le mono est un cas particulier du multi (speciesTag=null) ;
  fusionner dans canva_bubble_widgets ou un fichier partagé

### BUG-CANVA-05 🟠 (nouveau, = BUG-02) — Solid/VisualSolid redupliqué (4e occurrence)
- CanvaColorStrip._resolveDisplayColors() + _resolveDisplayIds() réimplémentent
  la résolution Solid/VisualSolid
- ⚠️ reconnaît 'solid' + 'visualsolid' mais PAS 'solidvisual' → même angle mort
  que dino_variant (cf BUG-02)
- => brancher sur le futur SolidColorResolver

### BUG-CANVA-06 🟢 (nouveau) — _statsSourceDino divergent mono vs multi
- mono : Dino.empty().copyWith(espece, nom) si vide ; multi : Dino.empty() seul
- cas quasi-inatteignable (gardé en amont) → cohérence mineure

### BUG-CANVA-07 🟢 (nouveau) — commonInt/commonDbl dupliqués 2×
- Identiques dans dino_canva_screen et dino_canva_multi_screen
- => util partagé commonStats(dinos)

### BUG-CANVA-08 🟢 (nouveau) — fragilités batch mineures
- tri dateAdded utilise (id ?? 0) comme proxy de date → suppose IDs monotones
  (fragile si Hive réutilise des clés)
- chemin asset <Espece>_ASA.png reconstruit en dur dans precacheImages ET
  CanvaBubble → idéalement ArkSpeciesData.getImageAssetPath
- passes adaptatives empiriques (3/5/8 + délais) → robustes mais lentes sur
  grandes séries

### DETTE-ARCHI (résolue) ✅ — module CANVA cartographié
- L'écran Canva appelant CanvaEditDinosModal correspond à cette famille
  (DinoCanvaScreen/Multi + pickers)
- ⚠️ RESTE À TRANCHER : widgets/share/canva_edit_dinos_modal.dart fait doublon
  fonctionnel avec les nouveaux pickers → grep qui l'instancie, archiver si mort
  (candidat BUG-05 / legacy)
- ⚠️ À CONFIRMER : bouton batch export absent du multi-écran (oubli ou voulu ?)
### 🟩 MODULE SAUVEGARDE / RESTAURATION ✅ CARTOGRAPHIÉ
- ARCHITECTURE : service de fusion pur (BackupMergeService) + service I/O
  fichier (BackupService) ; aucun écran lu ici (BackupScreen toujours en attente)
- FORMAT : JSON v3, type `full_backup`, partage via SharePlus, import via FilePicker

#### Service de fusion (logique pure)
- services/backup_merge_service.dart → BackupMergeService (static)
  - mergeAll({existingDinos, importedDinos, existingTags, importedTags,
    existingTrackers, importedTrackers}) → BackupMergeResult
  - mergeDinos : fusion par id (l'importé écrase l'existant à id égal),
    conserve les dinos id==null (ajoutés en double potentiel), tri espèce→nom
  - mergeCustomTags : trim + dédup (Set) + tri alpha
  - mergeTrackers : fusion par id ; conflit → mergeTwoTrackers ; tri species→projectName
  - mergeTwoTrackers : species/projectName/createdAt(min)/updatedAt(max)/bestStats/
    colorBank/anonymousStatEntries/colorObservations
  - mergeBestStats : garde la valeur la plus haute par clé
  - mergeColorBanks : régions 0..5, dédup IDs > 0, tri
  - mergeAnonymousEntries / mergeColorObservations : fusion par id, tri recordedAt
  - BackupMergeResult immuable (dinos, customTags, trackers)

#### Service I/O fichier
- services/backup_service.dart → BackupService (static)
  - _backupVersion=3, _appName='ARK Dino Manager', _backupType='full_backup'
  - exportData(...) : build map JSON (version/type/exportDate/appName/dinoCount/
    trackerCount/dinos.toMap/customTags/trackers.toMap) → fichier temp
    ark_dino_full_backup_<timestamp>.json → SharePlus ; web bloqué
  - importData() : FilePicker (json) → lecture path OU bytes → _parseBackupJson ;
    web bloqué ; gère cancelled
  - _parseBackupJson : valide clé 'dinos', lit version(def 1)/type(def legacy),
    parse Dino.fromMap / SpeciesTracker.fromMap avec try/catch par entrée
    (warnings non bloquants), tags trim+dédup+tri
  - BackupImportResult : success/cancelled/error + dinos/tags/trackers +
    version/backupType/warnings ; factories success/error/cancelled

---
### 🟧 MODULE COMMANDES / MARCHAND ✅ CARTOGRAPHIÉ
- ARCHITECTURE : écran liste (OrdersScreen) + écran création/édition WYSIWYG
  (OrderCreateEditScreen) ; providers OrderProvider + CurrencyProvider ;
  modèles Order / OrderItem / Currency ; DatabaseHelper orders_box déjà documenté
- FOND FIXE : assets/images/ui/background_cmd.png (Stack hors ListView → immobile au scroll)

#### Écran liste
- screens/orders_screen.dart → OrdersScreen
  - State : _searchQuery, _sortBy (recent/status), _showCompleted (persistés SharedPreferences)
  - Header : compteurs en cours / terminées (terminé = completed||validated)
  - Recherche nom/clientName, filtre sheet (tri + affichage terminées)
  - Carte commande : jauge circulaire (% OU ✓ "prête" OU 🏆 "validée"),
    badge statut, prix+monnaie, barre progression
  - États : "prête" = ratio≥0.99 non validée (bouton ✓ central) ; "validée" = status
  - Long press → options (modifier/valider/supprimer)

#### Écran création / édition
- screens/order_create_edit_screen.dart → OrderCreateEditScreen
  - Auto-save background (debounce 800ms) + save manuel + validation manuelle
  - Historique validations UNDO (max 3 snapshots {itemId:{male,female}})
  - Tri items (ItemSortMode nom/espece/niveau), validés poussés en bas
  - Header sticky : nom, date, résumé genres (paires/♂/♀/?), prix+monnaie,
    coût/unité, barre complétion avec label dynamique X/Y PAIRES|DINOS
  - Carte item : validation par genre (±), check global, avatar miroir + badge type,
    stats inline (HP/Stam/Dmg/Poids/Food/O₂), color strip 6 cases
  - Modal sélection dinos (_DinoSelectionModal) : recherche + chips rôle +
    multi-sélection via vraie DinoCardWidget en AbsorbPointer (_SelectableLibraryTile)
  - Partage texte trié par espèce (_SharePreviewSheet, copie presse-papier)
  - Valeurs par défaut (quantité/type/genre) persistées SharedPreferences

---
### 🟪 MODULE SIMULATEUR (onglet 0) ✅ CARTOGRAPHIÉ
- screens/simulator_screen.dart → SimulatorScreen (visualiseur de couleurs, PAS de breeding)
  - State : _species, _selectedColors[6], _useRegisteredOnly
  - _rebuildData : fusionne colorBank tracker + colorIds bibliothèque →
    _mergedColorBank[region] + liste _colorSources (biblio + observations)
  - Mode "Toutes" (ArkColorPalette.allColors) vs "Enregistrées" (banque espèce)
  - Sélecteur espèce (dialog recherche + image ASA), sélecteur couleur par région
    (bottom sheet grille 6 col, IDs)
  - Actions : Aléatoire / Solid (intersection banque) / Reset
  - Régions inactives (ArkSpeciesColorRegions.visibilityFor) marquées Ø mais
    restent cliquables ; compteur N/6 actives
  - Aperçu DinoImageWidget live, sources couleurs cliquables pour appliquer
  - ⚠️ "Smart Breeding" du nom de l'app PAS ici → Laboratoire reste à trouver

---
## 🐛 MISE À JOUR DU REGISTRE (lot Backup / Commandes / Simulateur)

### BUG-BKP-01 🟠 (nouveau) — mergeDinos : doublons sur dinos id==null
- Tout dino sans id (existant OU importé) est ajouté tel quel dans noId
- Réimporter une sauvegarde contenant des dinos non encore persistés
  (id null) les duplique à chaque import → croissance silencieuse
- => dédup heuristique (espèce+nom+stats) ou forcer un id avant merge

### BUG-BKP-02 🟢 (nouveau) — FilePicker.pickFiles API
- Commentaire "✅ APRÈS" + `FilePicker.pickFiles(...)` : vérifier que c'est bien
  `FilePicker.platform.pickFiles(...)` selon la version du package
  (sinon erreur de compilation)

### BUG-BKP-03 🟢 (nouveau) — import sans merge explicite
- BackupService.importData renvoie un BackupImportResult brut ; le branchement
  sur BackupMergeService.mergeAll n'est PAS visible (fait dans BackupScreen ?)
- => confirmer que l'écran appelle bien la fusion, sinon import = écrasement

### BUG-CMD-01 🟠 (nouveau, = BUG-01 global) — couleur rôle/type locale
- OrderCreateEditScreen._typeColor/_typeEmoji + fullDino.roleColor réimplémentent
  des couleurs ; cohérent avec la dette tagColor centralisé
- => brancher sur tagColor() / RoleThemeDefaults quand dispo

### BUG-CMD-02 🟢 (nouveau) — _getStatusColor mort dans OrdersScreen
- _getStatusColor(OrderStatus) défini mais la carte calcule `accent` à part
  → méthode potentiellement non utilisée → flutter analyze

### BUG-CMD-03 🟡 (nouveau) — double définition "terminé"
- "terminé" parfois = `completed||validated`, parfois = `ratio≥0.99 || completed
  || validated` (cf _showOrderOptions vs _buildHeader)
- => incohérence de filtrage possible ; unifier via un getter Order.isFinished

### BUG-CMD-04 🟢 (nouveau) — _DinoSelectionModal chips rôle en dur
- Tags ['Boss','Breeding','Solid','Farm','Collection','Combat'] codés en dur
  → ne reflètent pas les tags custom réels ; idem migration i18n (BUG-07)

### BUG-SIM-01 🟢 (nouveau) — Solid simulateur ≠ SolidColorResolver
- _testSolid réimplémente une logique "solid" (intersection banque) maison,
  distincte de la résolution Solid/VisualSolid (BUG-02/BUG-CANVA-05)
- => cohérence conceptuelle à vérifier (ce n'est PAS le même "solid", à documenter)

### BUG-SIM-02 🟢 (nouveau) — '#7F7F7F' / '#808080' gris magiques
- Valeurs gris "inactif" codées en dur (ici et dans order_create_edit color strip)
- => constante partagée kInactiveColorHex
### 🟫 MODULE TRACKER / JOURNAL D'ESPÈCES ✅ CARTOGRAPHIÉ
- ARCHITECTURE : 2 familles d'écrans distinctes alimentées par le même
  TrackerProvider + DinoProvider, fusionnant SYSTÉMATIQUEMENT
  bibliothèque (Dino) + tracker (SpeciesTracker)
  - Famille A « Trackers » : TrackerHomeScreen → SpeciesTrackerDetailScreen
    (édition directe du tracker, 2 onglets STATS/COULEURS)
  - Famille B « Journal » : SpeciesJournalHomeScreen → SpeciesJournalDetailScreen
    (vue synthèse par espèce, 4 onglets + header dino vedette + bouton Canva)
- ⚠️ FORTE REDONDANCE entre les deux familles (dialogue création tracker,
  pickers couleur, logiques merge, _testSolid, _isLight) → cf BUG-TRK-*

#### Famille A — Trackers (gestion brute)
- screens/tracker/tracker_home_screen.dart → TrackerHomeScreen
  - loadTrackers() en postFrame, recherche species/projectName, tri species
  - _TrackerCard : 4 _MiniInfoChip (stats max / couleurs / entrées / obs)
  - Dialogue création : autocomplétion Dino.especesDisponibles + validation
    espèce reconnue (officialName) ; FAB +
  - Bouton "Journal d'espèces" → SpeciesJournalHomeScreen
- screens/tracker/species_tracker_detail_screen.dart → SpeciesTrackerDetailScreen
  - TabController 2 onglets (STATS / COULEURS), refresh via Consumer2
  - _buildMergedStats : 7 clés (hp/stam/oxy/food/poids/degats/vitesse),
    library prime si > tracker, source nommée + flags isFromLibrary/isAnonymous
  - _buildMergedColorBank : library colorIds + observations + colorBank
  - _StatsTab : form saisie stat anonyme (registerAnonymousStats) + cards
  - _ColorsTab : toggle Observer/Simuler, 6 slots, picker (toutes en Observer /
    banque en Simuler), _saveObservation, random/solid/reset,
    bank par région (ExpansionTile) avec suppression long-press

#### Famille B — Journal (synthèse + WYSIWYG)
- screens/tracker/species_journal_home_screen.dart → SpeciesJournalHomeScreen
  - Agrège espèces depuis dinos + trackers, _SpeciesJournalItem (preview 6
    couleurs du 1er dino, compteurs, hasTracker, defaultFavoriteDino)
  - Même dialogue création tracker (DUPLIQUÉ) + navigation directe vers détail
- screens/tracker/species_journal_detail_screen.dart → SpeciesJournalDetailScreen
  - Fond background_home.png + overlay noir 0.55
  - Header dino vedette persisté SharedPreferences (clé header_dino_<species>)
    + picker bottom sheet
  - Bouton _CanvaHeaderButton (orange) → DinoCanvaScreen
  - TabBar 4 onglets custom _SpotlightIndicator (halo radial + underline) :
    Stats Max / Couleurs / Mes dinos / Simulateur

#### Onglets du Journal (lib/screens/tracker/tabs/)
- journal_tab_stats_max.dart → JournalTabStatsMax
  - _mergeBests (library + bestStats + anonymousStatEntries), grille 3×2
    _StatTile « strictement identique » à _StatCell de dino_variant_screen
  - Résolution valeur/points avec base ArkSpeciesStatsDb.get(species)
    (typé dynamic volontairement → divisor degats×0.05 sinon ×0.1)
- journal_tab_colors.dart → JournalTabColors
  - Lecture seule : visibilité régions (ArkSpeciesColorRegions) + banque fusionnée
- journal_tab_my_dinos.dart → JournalTabMyDinos (sous-TabBar Library/Trackers)
  - _LibrarySubTab : mode sélection (halo SelectableHalo), barre Canva/poubelle,
    /16, suppression unitaire + lot, toast overlay 1s
  - _TrackerSubTab : édition stats (masquer/supprimer) + banque couleurs
    (removeBestStat / removeAnonymousColor) par région
- journal_tab_simulator.dart → JournalTabSimulator
  - ⭐ QUASI-CLONE de SimulatorScreen (onglet 0) mais scopé sur 1 espèce :
    toggle Toutes/Enregistrées, 6 régions cliquables même inactives (badge Ø),
    random/solid/reset, _ColorSourceEntry (library + observations cliquables)

---
## 🐛 MISE À JOUR DU REGISTRE (lot Tracker / Journal)

### BUG-TRK-01 🟠 (nouveau) — dialogue création tracker DUPLIQUÉ
- _showCreateTrackerDialog quasi-identique dans tracker_home_screen ET
  species_journal_home_screen (autocomplétion + validation + officialName)
- => extraire un CreateTrackerDialog partagé (widget ou helper)

### BUG-TRK-02 🟠 (nouveau, = BUG-02 / BUG-CANVA-05) — _testSolid réimplémenté ×3
- Logique "solid = intersection des banques" dupliquée dans
  species_tracker_detail (_ColorsTab), journal_tab_simulator, simulator_screen
- ⚠️ aucune ne passe par SolidColorResolver → angle mort solidvisual persiste
- => converger sur le helper Solid central

### BUG-TRK-03 🟠 (nouveau) — picker couleur bottom sheet DUPLIQUÉ ×3+
- _pickColor (grid 6 col, case close en index 0, _isLight) réécrit dans
  _ColorsTab, journal_tab_simulator, et déjà repéré ailleurs
- => widget ColorRegionPickerSheet partagé

### BUG-TRK-04 🟡 (nouveau) — set de stats INCOHÉRENT entre écrans
- SpeciesTrackerDetail merge 7 stats (inclut 'vitesse')
- JournalTabStatsMax + JournalTabMyDinos n'en gèrent que 6 (PAS de vitesse)
- recoupe BUG-04/BUG-13 (Speed/ASA résiduel) → trancher : vitesse trackée ou non ?

### BUG-TRK-05 🟢 (nouveau) — _isLight / _SpotlightIndicator dupliqués
- _isLight redéfini dans presque chaque fichier ; _SpotlightIndicator +
  _SpotlightPainter copiés à l'identique dans journal_detail ET journal_tab_my_dinos
- => utils couleur partagé + widget indicateur unique

### BUG-TRK-06 🟠 (nouveau) — incohérence thème : AppTheme.* divergent
- tracker_home_screen utilise AppTheme.cardColor/backgroundColor/accentSecondary/
  success/warning/danger ; les autres écrans utilisent bgPrimary/bgSecondary/
  bgCard/accentPrimary/borderColor/textMuted
- => deux conventions de nommage AppTheme coexistent → auditer app_theme.dart
  (risque de doublons d'alias ou de getters morts)

### BUG-TRK-07 🟢 (nouveau) — DinoCanvaScreen signature variable
- journal_detail appelle DinoCanvaScreen(species:, initialSelection:)
  alors que le bloc Canva documentait DinoCanvaScreen(filterBySpecies:)
- => vérifier la vraie signature du constructeur (params renommés ?)

### BUG-TRK-08 🟢 (nouveau) — champs morts dialogue Journal
- species_journal_home : title Text('') vide + FAB label '' vide + import
  add_edit_dino_screen NON utilisé → flutter analyze (unused_import + UI vide)

### BUG-TRK-09 🟢 (nouveau) — _dinoNameCtrl jamais transmis
- species_tracker_detail _ColorsTab : champ "Nom du dino" (Observer) saisi mais
  _saveObservation n'envoie PAS le nom à saveAnonymousColorObservation
  → donnée perdue silencieusement (idem _confirmDeleteColor existe mais bank
  via long-press uniquement, pas de croix visible)

### BUG-TRK-10 🟡 (nouveau) — '#808080' / '#7F7F7F' gris magique (récidive)
- Couleur "non définie" recodée en dur ici (#808080) ET dans simulator_screen
  (#7F7F7F vs #808080) → cf BUG-SIM-02, valeurs DIVERGENTES entre écrans
- => constante partagée kInactiveColorHex (à uniformiser)

### DETTE-ARCHI (nouvelle) ⚠️ — DEUX visualiseurs de couleurs quasi-clones
- SimulatorScreen (onglet 0, toutes espèces) ET JournalTabSimulator
  (scopé 1 espèce) partagent ~90% du code (random/solid/reset/picker/sources)
- => extraire un SpeciesColorSimulator paramétrable (species? nullable)
- ⚠️ confirme aussi : DEUX entrées « tracker » (onglet dédié ? + via Journal)
  → clarifier le point d'entrée canonique dans la nav
### 🟨 MODULE PROVIDERS & PERSISTANCE ✅ CARTOGRAPHIÉ
- ⚠️ DEUX BACKENDS DE STOCKAGE COEXISTENT :
  - Hive (DatabaseHelper) : Dino + orders_box documentés précédemment
  - SharedPreferences : Tracker, Tags, RoleTheme, Gemini, Currency, ET Order
    (orders_list) → ⚠️ OrderProvider n'utilise PAS orders_box Hive !

#### providers/tracker_provider.dart → TrackerProvider ⭐
- Persistance : SharedPreferences clé 'species_trackers' (List<String> JSON)
- CRUD : createTracker (refuse doublon species+projectName), deleteTracker,
  replaceAllTrackers (utilisé par BackupScreen), getTrackerById
- Stats : updateBestStat, registerAnonymousStats (push entry + maj bestStats),
  deleteAnonymousStat / deleteBestStat / removeBestStat (rebuild depuis entries)
- Couleurs : registerColorObservation → saveAnonymousColorObservation
  (push obs + ajout colorBank trié), deleteColorObservation,
  removeColorFromBank, removeAnonymousColor (rebuild depuis observations)
- _rebuildBestStats / _rebuildColorBank : reconstruction cohérente après suppression
- _sortTrackers : species puis projectName

#### providers/order_provider.dart → OrderProvider
- ⚠️ Persistance SharedPreferences 'orders_list' (PAS Hive orders_box !)
- CRUD createOrder/updateOrder/deleteOrder/validateOrder (→ OrderStatus.validated)
- ⚠️ debugPrint massif (émojis 🔵🔴✅) → bruit logs en prod (BUG-PRV-01)
- ⚠️ mutation directe _orders[idx].status (Order non-immuable) avant save

#### providers/currency_provider.dart → CurrencyProvider
- Currency.getDefaults() (TEK par défaut, _allCurrencies.first)
- loadPreferences (default_currency_id + custom_currencies),
  add/removeCustomCurrency (id custom_<ms>)

#### providers/tag_theme_provider.dart → TagThemeProvider
- SharedPreferences 'tag_colors' (Map tag→hex), colorForTag/hexForTag/setTagColor/
  removeTagColor/resetAll ; _hexToColor maison (FF + 6 hex)
- ⚠️ source de couleur tag CONCURRENTE de tagColor() (BUG-01)

#### providers/role_theme_provider.dart → RoleThemeProvider
- SharedPreferences 'role_themes' {themes, deleted}
- _customThemes + _deletedDefaults (rôle défaut masquable),
  themeForRole (perso > défaut > neutre si supprimé), allRoles, setTheme/
  resetToDefault/deleteTheme/resetAll ; s'appuie sur RoleThemeDefaults

#### providers/gemini_provider.dart → GeminiProvider
- SharedPreferences 'gemini_api_key' + 'gemini_ocr_enabled'
- setApiKey : validation format "AIza" + GeminiOcrService.validateApiKey (réseau)
- isEnabled = _enabled && key non vide ; maskedKey (AIza...xxxx) ;
  getter service → GeminiOcrService(key) ou null
- ⭐ point de bascule OCR Gemini vs ML Kit (cf BUG-09/12)

---
### 🟦 MODULE i18n (l10n/app_fr.arb) ✅ CARTOGRAPHIÉ — fichier de RÉFÉRENCE
- ARB FR complet et riche (≈ 250 clés) couvrant : settings, backup, bestiary,
  tags, roleThemes, colorRegions/Bank, speciesJournal, home, library, dinoDetail,
  addEditDino, scan (OCR détaillé), tracker, orders, nav, stats, mutations, sex,
  messages succès/erreur/validation, scanRows, boutons
- ⭐ L'INFRA i18n EXISTE DÉJÀ — le vrai problème (BUG-07) n'est PAS l'absence
  de clés mais que les ÉCRANS n'utilisent quasiment PAS ces clés (textes FR
  codés en dur partout dans les widgets cartographiés)
- ⚠️ INCOHÉRENCES internes dans l'ARB lui-même :
  - doublons sémantiques : confirmCancel/buttonCancel/roleThemesCancel ; OK ×3 ;
    Supprimer ×3 ; "Mâle/Femelle" en double (addEditDinoSex* + sex*) ;
    Région/region/colorRegion/regionDetail = 4 familles pour le même concept
  - stats nommées 2× : statHp(PV)/statLabelHp(VIE), statMelee(Mêlée)/
    statLabelAttack(ATTAQUE) → vocabulaire FR divergent (cf dette "vocabulaire")
  - speciesJournalSubtitle "Journal d'espece" non accentué
  - statSpeed/statLabel sans Speed → cohérent avec décision "vitesse" à trancher

---
## 🐛 MISE À JOUR DU REGISTRE (lot Providers / i18n / Backup)

### BUG-PRV-01 🟡 (nouveau) — OrderProvider : logs debugPrint en prod
- ~25 debugPrint emoji par cycle CRUD → pollue logcat, fuite éventuelle d'IDs
- => kDebugMode guard ou retirer

### BUG-PRV-02 🟠 (nouveau) — Order stocké SharedPreferences, pas Hive
- DatabaseHelper expose orders_box + CRUD (documenté) MAIS OrderProvider
  persiste dans 'orders_list' SharedPreferences → la couche Hive orders_box
  est MORTE / non utilisée
- => trancher : migrer vers Hive (cohérence Dino) OU archiver orders_box

### BUG-PRV-03 🟢 (nouveau) — validateOrder mute objet non-immuable
- _orders[idx].status = ... + .updatedAt = ... (setters directs)
- incohérent avec le style copyWith des autres modèles → risque d'effets de bord

### BUG-PRV-04 🟠 (nouveau, = BUG-01) — TagThemeProvider concurrent de tagColor()
- 'tag_colors' (provider) est une 4e/5e source de couleur de tag en plus de
  Dino.roleColor / RoleThemeDefaults / _tagColor / _defaultTagColor
- => le futur tagColor() centralisé DOIT lire TagThemeProvider comme source
  unique, sinon la centralisation est incomplète

### BUG-I18N-01 🔴 (promu, = BUG-07) — clés ARB présentes mais NON consommées
- L'ARB couvre l'essentiel mais les écrans cartographiés (Tracker, Journal,
  Orders, Canva, Backup…) utilisent des littéraux FR en dur
- => chantier de branchement AppLocalizations.of(context) écran par écran
  (gros volume) ; commencer par les écrans à fort trafic (home/library/detail)

### BUG-I18N-02 🟡 (nouveau) — doublons & vocabulaire divergent dans l'ARB
- Cancel ×3, OK ×3, Supprimer ×3, Mâle/Femelle ×2, Région ×4 familles,
  PV vs VIE, Mêlée vs ATTAQUE
- => dédupliquer l'ARB et fixer un glossaire FR canonique avant de brancher
  massivement (sinon on fige l'incohérence dans tous les écrans)

### BUG-I18N-03 🟢 (nouveau) — typo source : "Journal d'espece"
- speciesJournalSubtitle non accentué ; idem plusieurs hints sans accents
  dans le code (cf species_tracker_detail "TRACKER D'ESPECE", "Degats", "Oxygene")

### DETTE-ARCHI (résolue) ✅ BUG-BKP-03 — BackupScreen FUSIONNE bien
- screens/backup_screen.dart confirme : import JSON ET Excel passent par
  BackupMergeService.mergeAll puis dinoProvider.replaceAllData +
  trackerProvider.replaceAllTrackers → PAS d'écrasement, fusion confirmée
- ⭐ NOUVEAU : 4e canal Excel découvert → ExcelBackupService
  (exportAndShareFullBackup / importFullBackupFromPicker, FullExcelImportResult)
  NON encore cartographié (fichier à fournir)
- aperçu pré-import (dinos/tags/trackers + warnings) avant commit ✅

### BUG-BKP-01 (rappel, toujours ouvert) 🟠 — mergeDinos doublons id==null
- BackupScreen ne dédup PAS avant mergeAll → réimport répété duplique les
  dinos sans id (confirmé par le flux replaceAllData)
 BUG-OCR-02 — TRANCHÉ : toDino est bien cassé
ArkColorPalette.allColors retourne une List<ArkColor> — des objets, pas des Map. Le code de toDino dans dino_ocr_service.dart qui faisait .cast<Map<String,dynamic>?>().firstWhere((c) => c?['id'] == id) est donc garanti faux : le .cast<Map> lèvera un TypeError au runtime dès qu'on itère (un ArkColor n'est pas un Map), ou au mieux ne matchera jamais. Confirmé bug réel, à corriger. Le bon usage est ArkColorPalette.fromId(id) (retourne null si inconnu) ou byId(id) (retourne le placeholder « Unknown »). Recommandation : utiliser fromId dans toDino pour pouvoir ignorer proprement les IDs invalides plutôt que d'injecter un gris fantôme.

BUG-OCR-01 — RECADRÉ : ce n'est pas 0-256, c'est une plage trouée
La palette n'est pas continue : IDs 1-100, puis 128-255 (les 101-127 n'existent pas). Donc :

Le prompt Gemini disant « 0-100 » est doublement faux : il exclut toute la gamme des Coloring Dyes (128-255) que l'OCR pourrait légitimement lire, et il inclut 0 qui n'existe pas. À corriger en : « IDs ARK valides : 1-100 et 128-255 ».

Surtout, nouveau BUG-OCR-04 : tout consommateur d'ID doit gérer le trou 101-127. byId renvoie le placeholder id:0 / Unknown / #E6E6E6 pour ces valeurs — un gris clair silencieux. Un OCR qui hallucine « 115 » produira donc un dino gris sans erreur visible. Préférer fromId + validation explicite partout où une couleur vient de l'OCR ou d'un import.

Incohérences internes de la palette (à nettoyer)
ID 255 « White Undefined » est en minuscules (#ffffff) alors que tout le reste est en MAJUSCULES. color et idToHex s'en moquent (parse insensible à la casse), mais une comparaison de hex string ailleurs dans le code (ex. kInactiveColorHex, BUG-TRK-10) pourrait rater. Uniformiser en #FFFFFF.
ID 0 n'existe pas dans la map. Or byId(0) renvoie le placeholder avec id:0, et le placeholder Unknown a id:0 lui aussi. Conséquence directe sur BUG-BKP-05 / BUG-BKP-01 : un dino dont colorId == 0 (souvent la valeur par défaut « pas de couleur ») devient un faux gris #E6E6E6 au lieu d'être traité comme « slot vide ». Il faut une sentinelle claire pour « région non peinte » distincte d'un vrai gris. Lien aussi avec kInactiveColorHex (#808080 vs #7F7F7F, BUG-TRK-10) — trois gris différents circulent : #E6E6E6 (placeholder Unknown), #808080/#7F7F7F (inactif), et le vrai « Slate Coloring » #7F7F7F (id 228). À unifier dans un glossaire couleur.
hexToClosestId parcourt toute la map y compris les Coloring Dyes, dont beaucoup dupliquent exactement des couleurs normales (#FF0000 = id 1 ET id 131 ; #00FF00 = 3 et 163 ; #FFFFFF = 18, 36, 233, 255). Le « plus proche » est donc non déterministe selon l'ordre d'itération. Si l'app vise ASA-vanilla, filtrer 1-100 dans hexToClosestId ; sinon documenter le choix. → BUG-OCR-05.
BUG-OCR-03 — ORCHESTRATION : partiellement résolu, fallback ABSENT
GeminiProvider expose proprement service (null si pas activé/clé). Donc le pattern attendu côté écran Scan est geminiProvider.service ?? <ML Kit>. Mais ce fichier ne contient aucun routeur ni fallback — il faut le confirmer dans l'écran Scan. Deux risques détectés ici :

isEnabled exige _enabled && _apiKey.isNotEmpty, et setApiKey force _enabled = true dès qu'une clé valide est posée. Cohérent. En revanche rien ne gère l'épuisement du quota (1500/j, 15/min documentés dans GeminiOcrService) : si Gemini renvoie 429 en cours d'usage, service reste non-null et l'app ne bascule pas automatiquement sur ML Kit. Le fallback runtime (pas seulement « clé absente ») doit vivre dans l'écran Scan ou dans un wrapper. → BUG-OCR-06 (fallback quota/erreur réseau).

Note sécurité mineure (BUG-OCR-07) : la clé API est stockée en clair dans SharedPreferences. Acceptable pour une app perso, mais à signaler si distribution. flutter_secure_storage serait le bon réflexe.

REGISTRE DE BUGS — module OCR / Palette consolidé
Critiques confirmés : BUG-OCR-02 (toDino cast Map → utiliser fromId), BUG-BKP-04 (FilePicker.platform.pickFiles), BUG-BKP-05/01 (ID/colorId nullable + sentinelle 0).

Importants : BUG-OCR-01 (prompt 0-100 → 1-100 & 128-255), BUG-OCR-04 (trou 101-127 → gris silencieux), BUG-OCR-06 (fallback runtime quota Gemini→ML Kit), DETTE triple simulateur.

Mineurs : BUG-OCR-05 (hexToClosestId ambigu sur doublons hex), BUG-OCR-07 (clé en clair), uniformisation ID 255 minuscule, glossaire des trois gris.

ÉTAT GLOBAL DE L'AUDIT