// lib/l10n/app_localizations.dart
// Implémentation manuelle des localisations – FR / EN / DE
// Pas de build_runner requis.

import 'package:flutter/material.dart';

/// Récupère l'instance depuis n'importe quel widget :
///   final l10n = AppLocalizations.of(context)!;
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ─── Helpers internes ────────────────────────────────────────────────────

  String _t(Map<String, String> map) =>
      map[locale.languageCode] ?? map['en'] ?? '';

  // ─── APP ─────────────────────────────────────────────────────────────────

  String get appTitle => _t({'fr': 'ARK Dino Manager', 'en': 'ARK Dino Manager', 'de': 'ARK Dino Manager'});

  // ─── SETTINGS ────────────────────────────────────────────────────────────

  String get settingsTitle => _t({'fr': 'Paramètres & Informations', 'en': 'Settings & Information', 'de': 'Einstellungen & Informationen'});
  String get settingsBackup => _t({'fr': 'SAUVEGARDE', 'en': 'BACKUP', 'de': 'SICHERUNG'});
  String get settingsBestiary => _t({'fr': 'BESTIAIRE', 'en': 'BESTIARY', 'de': 'BESTIARIUM'});
  String get settingsTags => _t({'fr': 'TAGS & COULEURS', 'en': 'TAGS & COLORS', 'de': 'TAGS & FARBEN'});
  String get settingsRoleThemes => _t({'fr': 'THÈMES PAR RÔLE', 'en': 'ROLE THEMES', 'de': 'ROLLEN-DESIGNS'});
  String get settingsLanguage => _t({'fr': 'LANGUE', 'en': 'LANGUAGE', 'de': 'SPRACHE'});
  String get settingsNews => _t({'fr': 'ACTUALITÉS', 'en': 'NEWS', 'de': 'NEUIGKEITEN'});

  // ─── LANGUAGE ────────────────────────────────────────────────────────────

  String get languageActive => _t({'fr': 'Langue active', 'en': 'Active language', 'de': 'Aktive Sprache'});
  String get languageSelectorTitle => _t({'fr': 'Choisir la langue', 'en': 'Choose language', 'de': 'Sprache wählen'});
  String get languageSelectorSubtitle => _t({'fr': 'La langue sera appliquée immédiatement', 'en': 'Language will be applied immediately', 'de': 'Die Sprache wird sofort angewendet'});

  // ─── BACKUP ──────────────────────────────────────────────────────────────

  String get backupAutoActive => _t({'fr': 'Google Auto-Backup actif', 'en': 'Google Auto-Backup active', 'de': 'Google Auto-Backup aktiv'});
  String get backupAutoDesc => _t({
    'fr': 'Tes données sont sauvegardées automatiquement dans Google Drive toutes les 24h.',
    'en': 'Your data is automatically backed up to Google Drive every 24h.',
    'de': 'Deine Daten werden alle 24h automatisch in Google Drive gesichert.',
  });
  String get backupManage => _t({'fr': 'Gérer les sauvegardes manuelles', 'en': 'Manage manual backups', 'de': 'Manuelle Sicherungen verwalten'});

  // ─── BESTIARY ────────────────────────────────────────────────────────────

  String get bestiaryDinoCards => 'DinoCards';
  String get bestiaryTrackers => 'Trackers';
  String get bestiarySpecies => _t({'fr': 'Espèces', 'en': 'Species', 'de': 'Spezies'});
  String get bestiaryArkBestiary => _t({'fr': 'Bestiaire ARK', 'en': 'ARK Bestiary', 'de': 'ARK-Bestiarium'});
  String bestiarySpeciesCount(int current, int total) => _t({
    'fr': '$current / $total espèces',
    'en': '$current / $total species',
    'de': '$current / $total Spezies',
  });
  String bestiaryDiscovered(String percent) => _t({
    'fr': '$percent% du bestiaire ARK découvert',
    'en': '$percent% of ARK bestiary discovered',
    'de': '$percent% des ARK-Bestiariums entdeckt',
  });

  // ─── TAGS ────────────────────────────────────────────────────────────────

  String get tagsTapToChange => _t({'fr': 'Appuie sur un tag pour changer sa couleur', 'en': 'Tap a tag to change its color', 'de': 'Tippe auf ein Tag, um seine Farbe zu ändern'});
  String get tagsLongPressReset => _t({'fr': 'Appui long sur un tag personnalisé pour le réinitialiser', 'en': 'Long press a custom tag to reset it', 'de': 'Langes Tippen auf ein benutzerdefiniertes Tag zum Zurücksetzen'});
  String get tagsResetAll => _t({'fr': 'Reset tout', 'en': 'Reset all', 'de': 'Alle zurücksetzen'});

  // ─── ROLE THEMES ─────────────────────────────────────────────────────────

  String get roleThemesTapHint => _t({'fr': 'Appuie sur un rôle pour personnaliser ses 3 couleurs', 'en': 'Tap a role to customize its 3 colors', 'de': 'Tippe auf eine Rolle, um ihre 3 Farben anzupassen'});
  String get roleThemesBackground => _t({'fr': 'Fond', 'en': 'Background', 'de': 'Hintergrund'});
  String get roleThemesBorder => _t({'fr': 'Bordure', 'en': 'Border', 'de': 'Rahmen'});
  String get roleThemesText => _t({'fr': 'Texte', 'en': 'Text', 'de': 'Text'});
  String get roleThemesApply => _t({'fr': 'Appliquer', 'en': 'Apply', 'de': 'Anwenden'});
  String get roleThemesCancel => _t({'fr': 'Annuler', 'en': 'Cancel', 'de': 'Abbrechen'});
  String get roleThemesPreview => _t({'fr': 'Aperçu', 'en': 'Preview', 'de': 'Vorschau'});

  // ─── COLOR REGIONS ───────────────────────────────────────────────────────

  String get colorRegionsTitle => _t({'fr': 'RÉGIONS DE COULEUR', 'en': 'COLOR REGIONS', 'de': 'FARBBEREICHE'});
  String get colorRegionVisible => _t({'fr': 'Visible', 'en': 'Visible', 'de': 'Sichtbar'});
  String get colorRegionInvisible => _t({'fr': 'Invisible', 'en': 'Invisible', 'de': 'Unsichtbar'});
  String colorRegionLabel(int index) => 'R$index';
  String get colorBankTitle => _t({'fr': 'BANQUE DE COULEURS', 'en': 'COLOR BANK', 'de': 'FARBBANK'});
  String get colorBankNoColor => _t({'fr': 'Aucune couleur enregistrée', 'en': 'No color recorded', 'de': 'Keine Farbe gespeichert'});
  String colorBankRegion(int index) => _t({'fr': 'Région $index', 'en': 'Region $index', 'de': 'Bereich $index'});

  // ─── SPECIES JOURNAL ─────────────────────────────────────────────────────

  String get speciesJournalTitle => _t({'fr': "Journal d'Espèce", 'en': 'Species Journal', 'de': 'Artenbuch'});
  String get speciesJournalSubtitle => _t({'fr': "Journal d'espece", 'en': 'Species journal', 'de': 'Artenbuch'});
  String get speciesJournalBestStats => _t({'fr': 'MEILLEURES STATS', 'en': 'BEST STATS', 'de': 'BESTE WERTE'});
  String get speciesJournalLibraryDinos => _t({'fr': 'DINOS DE LA BIBLIOTHÈQUE', 'en': 'LIBRARY DINOS', 'de': 'DINOS DER BIBLIOTHEK'});
  String get speciesJournalNoTracker => _t({'fr': 'Aucun tracker actif', 'en': 'No active tracker', 'de': 'Kein aktiver Tracker'});
  String speciesJournalTotalColors(int count) => _t({'fr': '$count couleurs', 'en': '$count colors', 'de': '$count Farben'});

  // ─── HOME ────────────────────────────────────────────────────────────────

  String get homeTitle => 'ARK MANAGER';
  String get homeSubtitle => _t({'fr': 'Ta bibliothèque de dinos', 'en': 'Your dino library', 'de': 'Deine Dino-Bibliothek'});
  String get homeNoDinos => _t({'fr': 'Aucun dino dans la bibliothèque', 'en': 'No dinos in the library', 'de': 'Keine Dinos in der Bibliothek'});
  String get homeAddFirst => _t({'fr': 'Ajoute ton premier dino !', 'en': 'Add your first dino!', 'de': 'Füge deinen ersten Dino hinzu!'});
  String get homeSearch => _t({'fr': 'Rechercher...', 'en': 'Search...', 'de': 'Suchen...'});
  String get homeFilter => _t({'fr': 'Filtrer', 'en': 'Filter', 'de': 'Filtern'});
  String get homeSortBy => _t({'fr': 'Trier par', 'en': 'Sort by', 'de': 'Sortieren nach'});
  String get homeSortName => _t({'fr': 'Nom', 'en': 'Name', 'de': 'Name'});
  String get homeSortLevel => _t({'fr': 'Niveau', 'en': 'Level', 'de': 'Level'});
  String get homeSortSpecies => _t({'fr': 'Espèce', 'en': 'Species', 'de': 'Spezies'});
  String get homeSortDate => _t({'fr': 'Date', 'en': 'Date', 'de': 'Datum'});
  String get homeSortMutations => _t({'fr': 'Mutations', 'en': 'Mutations', 'de': 'Mutationen'});

  // ─── LIBRARY ─────────────────────────────────────────────────────────────

  String get libraryTitle => _t({'fr': 'BIBLIOTHÈQUE', 'en': 'LIBRARY', 'de': 'BIBLIOTHEK'});
  String get libraryEmpty => _t({'fr': 'Bibliothèque vide', 'en': 'Empty library', 'de': 'Bibliothek leer'});
  String get libraryAddDino => _t({'fr': 'Ajouter un dino', 'en': 'Add a dino', 'de': 'Dino hinzufügen'});
  String get libraryImport => _t({'fr': 'Importer', 'en': 'Import', 'de': 'Importieren'});
  String get libraryExport => _t({'fr': 'Exporter', 'en': 'Export', 'de': 'Exportieren'});
  String get libraryExportExcel => _t({'fr': 'Exporter Excel', 'en': 'Export Excel', 'de': 'Excel exportieren'});
  String get libraryShare => _t({'fr': 'Partager', 'en': 'Share', 'de': 'Teilen'});

  // ─── DINO DETAIL ─────────────────────────────────────────────────────────

  String get dinoDetailEdit => _t({'fr': 'Modifier', 'en': 'Edit', 'de': 'Bearbeiten'});
  String get dinoDetailDelete => _t({'fr': 'Supprimer', 'en': 'Delete', 'de': 'Löschen'});
  String get dinoDetailShare => _t({'fr': 'Partager', 'en': 'Share', 'de': 'Teilen'});
  String get dinoDetailStats => _t({'fr': 'STATISTIQUES', 'en': 'STATISTICS', 'de': 'STATISTIKEN'});
  String get dinoDetailColors => _t({'fr': 'COULEURS', 'en': 'COLORS', 'de': 'FARBEN'});
  String get dinoDetailMutations => _t({'fr': 'MUTATIONS', 'en': 'MUTATIONS', 'de': 'MUTATIONEN'});
  String get dinoDetailNotes => _t({'fr': 'NOTES', 'en': 'NOTES', 'de': 'NOTIZEN'});
  String get dinoDetailBreeding => _t({'fr': 'ÉLEVAGE', 'en': 'BREEDING', 'de': 'ZUCHT'});
  String get dinoDetailConfirmDelete => _t({'fr': 'Supprimer ce dino ?', 'en': 'Delete this dino?', 'de': 'Diesen Dino löschen?'});
  String get dinoDetailConfirmDeleteDesc => _t({'fr': 'Cette action est irréversible.', 'en': 'This action is irreversible.', 'de': 'Diese Aktion kann nicht rückgängig gemacht werden.'});

  // ─── ADD/EDIT DINO ───────────────────────────────────────────────────────

  String get addEditDinoTitle => _t({'fr': 'Ajouter un Dino', 'en': 'Add a Dino', 'de': 'Dino hinzufügen'});
  String get editDinoTitle => _t({'fr': 'Modifier le Dino', 'en': 'Edit Dino', 'de': 'Dino bearbeiten'});
  String get addEditDinoSave => _t({'fr': 'Sauvegarder', 'en': 'Save', 'de': 'Speichern'});
  String get addEditDinoCancel => _t({'fr': 'Annuler', 'en': 'Cancel', 'de': 'Abbrechen'});
  String get addEditDinoSpecies => _t({'fr': 'Espèce', 'en': 'Species', 'de': 'Spezies'});
  String get addEditDinoName => _t({'fr': 'Nom', 'en': 'Name', 'de': 'Name'});
  String get addEditDinoLevel => _t({'fr': 'Niveau', 'en': 'Level', 'de': 'Level'});
  String get addEditDinoSexMale => _t({'fr': 'Mâle', 'en': 'Male', 'de': 'Männlich'});
  String get addEditDinoSexFemale => _t({'fr': 'Femelle', 'en': 'Female', 'de': 'Weiblich'});
  String get addEditDinoTamed => _t({'fr': 'Apprivoisé', 'en': 'Tamed', 'de': 'Gezähmt'});
  String get addEditDinoBred => _t({'fr': 'Élevé', 'en': 'Bred', 'de': 'Gezüchtet'});
  String get addEditDinoNotes => _t({'fr': 'Notes', 'en': 'Notes', 'de': 'Notizen'});
  String get addEditDinoTags => _t({'fr': 'Tags', 'en': 'Tags', 'de': 'Tags'});
  String get addEditDinoMutPaternal => _t({'fr': 'Paternelles', 'en': 'Paternal', 'de': 'Väterlich'});
  String get addEditDinoMutMaternal => _t({'fr': 'Maternelles', 'en': 'Maternal', 'de': 'Mütterlich'});

  // ─── SCAN ────────────────────────────────────────────────────────────────

  String get scanTitle => _t({'fr': 'Scanner un Dino', 'en': 'Scan a Dino', 'de': 'Dino scannen'});
  String get scanCapture => _t({'fr': 'Capturer', 'en': 'Capture', 'de': 'Aufnehmen'});
  String get scanAnalyze => _t({'fr': 'Analyser', 'en': 'Analyze', 'de': 'Analysieren'});
  String get scanRetry => _t({'fr': 'Réessayer', 'en': 'Retry', 'de': 'Wiederholen'});
  String get scanSuccess => _t({'fr': 'Scan réussi !', 'en': 'Scan successful!', 'de': 'Scan erfolgreich!'});
  String get scanFailed => _t({'fr': 'Scan échoué', 'en': 'Scan failed', 'de': 'Scan fehlgeschlagen'});
  String get scanNoText => _t({'fr': 'Aucun texte détecté', 'en': 'No text detected', 'de': 'Kein Text erkannt'});
  String get scanHint => _t({'fr': 'Pointez la caméra sur les stats ARK', 'en': 'Point the camera at ARK stats', 'de': 'Kamera auf ARK-Werte richten'});

  // ─── TRACKER ─────────────────────────────────────────────────────────────

  String get trackerTitle => 'Trackers';
  String get trackerEmpty => _t({'fr': 'Aucun tracker actif', 'en': 'No active tracker', 'de': 'Kein aktiver Tracker'});
  String get trackerAdd => _t({'fr': 'Nouveau tracker', 'en': 'New tracker', 'de': 'Neuer Tracker'});
  String get trackerStatusActive => _t({'fr': 'Actif', 'en': 'Active', 'de': 'Aktiv'});
  String get trackerStatusCompleted => _t({'fr': 'Terminé', 'en': 'Completed', 'de': 'Abgeschlossen'});
  String get trackerStatusPaused => _t({'fr': 'En pause', 'en': 'Paused', 'de': 'Pausiert'});

  // ─── ORDERS ──────────────────────────────────────────────────────────────

  String get ordersTitle => _t({'fr': 'Commandes', 'en': 'Orders', 'de': 'Bestellungen'});
  String get ordersEmpty => _t({'fr': 'Aucune commande', 'en': 'No orders', 'de': 'Keine Bestellungen'});
  String get ordersAdd => _t({'fr': 'Nouvelle commande', 'en': 'New order', 'de': 'Neue Bestellung'});
  String get ordersPending => _t({'fr': 'En attente', 'en': 'Pending', 'de': 'Ausstehend'});
  String get ordersCompleted => _t({'fr': 'Terminé', 'en': 'Completed', 'de': 'Abgeschlossen'});
  String get ordersCancelled => _t({'fr': 'Annulé', 'en': 'Cancelled', 'de': 'Abgebrochen'});

  // ─── COMMON ──────────────────────────────────────────────────────────────

  String get confirmYes => _t({'fr': 'Oui', 'en': 'Yes', 'de': 'Ja'});
  String get confirmNo => _t({'fr': 'Non', 'en': 'No', 'de': 'Nein'});
  String get confirmDelete => _t({'fr': 'Supprimer', 'en': 'Delete', 'de': 'Löschen'});
  String get confirmCancel => _t({'fr': 'Annuler', 'en': 'Cancel', 'de': 'Abbrechen'});
  String get confirmOk => 'OK';
  String get confirmSave => _t({'fr': 'Sauvegarder', 'en': 'Save', 'de': 'Speichern'});
  String get confirmClose => _t({'fr': 'Fermer', 'en': 'Close', 'de': 'Schließen'});
  String get confirmApply => _t({'fr': 'Appliquer', 'en': 'Apply', 'de': 'Anwenden'});
  String get confirmReset => _t({'fr': 'Réinitialiser', 'en': 'Reset', 'de': 'Zurücksetzen'});

  String get errorGeneric => _t({'fr': 'Une erreur s\'est produite', 'en': 'An error occurred', 'de': 'Ein Fehler ist aufgetreten'});
  String get errorLoading => _t({'fr': 'Erreur de chargement', 'en': 'Loading error', 'de': 'Ladefehler'});

  // ─── NAVIGATION ──────────────────────────────────────────────────────────

  String get navHome => _t({'fr': 'Accueil', 'en': 'Home', 'de': 'Start'});
  String get navLibrary => _t({'fr': 'Bibliothèque', 'en': 'Library', 'de': 'Bibliothek'});
  String get navScan => _t({'fr': 'Scanner', 'en': 'Scan', 'de': 'Scannen'});
  String get navTracker => 'Tracker';
  String get navSettings => _t({'fr': 'Paramètres', 'en': 'Settings', 'de': 'Einstellungen'});

  // ─── STATS NAMES ─────────────────────────────────────────────────────────

  String get statHp => _t({'fr': 'PV', 'en': 'HP', 'de': 'LP'});
  String get statStamina => _t({'fr': 'Endurance', 'en': 'Stamina', 'de': 'Ausdauer'});
  String get statTorpor => 'Torpor';
  String get statOxygen => _t({'fr': 'Oxygène', 'en': 'Oxygen', 'de': 'Sauerstoff'});
  String get statFood => _t({'fr': 'Nourriture', 'en': 'Food', 'de': 'Nahrung'});
  String get statWater => _t({'fr': 'Eau', 'en': 'Water', 'de': 'Wasser'});
  String get statWeight => _t({'fr': 'Poids', 'en': 'Weight', 'de': 'Gewicht'});
  String get statMelee => _t({'fr': 'Mêlée', 'en': 'Melee', 'de': 'Nahkampf'});
  String get statSpeed => _t({'fr': 'Vitesse', 'en': 'Speed', 'de': 'Geschwindigkeit'});
  String get statFortitude => _t({'fr': 'Vigueur', 'en': 'Fortitude', 'de': 'Robustheit'});
  String get statCrafting => _t({'fr': 'Artisanat', 'en': 'Crafting', 'de': 'Handwerk'});

  // ─── MISC ────────────────────────────────────────────────────────────────

  String get sexMale => _t({'fr': 'Mâle', 'en': 'Male', 'de': 'Männlich'});
  String get sexFemale => _t({'fr': 'Femelle', 'en': 'Female', 'de': 'Weiblich'});
  String get sexUnknown => _t({'fr': 'Inconnu', 'en': 'Unknown', 'de': 'Unbekannt'});
  String levelLabel(int level) => _t({'fr': 'Niv. $level', 'en': 'Lv. $level', 'de': 'Lv. $level'});
  String colorIdLabel(int id) => 'ID $id';
  String get changelogView => _t({'fr': 'Voir le changelog', 'en': 'View changelog', 'de': 'Changelog anzeigen'});
  String versionLabel(String version) => _t({'fr': 'Version $version', 'en': 'Version $version', 'de': 'Version $version'});
  String searchNoResults(String query) => _t({'fr': 'Aucun résultat pour "$query"', 'en': 'No results for "$query"', 'de': 'Keine Ergebnisse für "$query"'});
  String get deleteConfirmTitle => _t({'fr': 'Confirmer la suppression', 'en': 'Confirm deletion', 'de': 'Löschen bestätigen'});
  String get deleteConfirmMessage => _t({'fr': 'Cette action est irréversible.', 'en': 'This action is irreversible.', 'de': 'Diese Aktion kann nicht rückgängig gemacht werden.'});
  String get resetConfirmTitle => _t({'fr': 'Confirmer la réinitialisation', 'en': 'Confirm reset', 'de': 'Zurücksetzen bestätigen'});
  String get resetConfirmMessage => _t({'fr': 'Toutes les personnalisations seront supprimées.', 'en': 'All customizations will be deleted.', 'de': 'Alle Anpassungen werden gelöscht.'});
  String get mutationsPaternal => _t({'fr': 'Paternelles', 'en': 'Paternal', 'de': 'Väterlich'});
  String get mutationsMaternal => _t({'fr': 'Maternelles', 'en': 'Maternal', 'de': 'Mütterlich'});
  String get mutationsTotal => _t({'fr': 'Total mutations', 'en': 'Total mutations', 'de': 'Mutationen gesamt'});
}

// ─── Delegate ────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const List<String> _supported = ['fr', 'en', 'de'];

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
