// lib/l10n/app_localizations.dart
// Implémentation manuelle des localisations – FR / EN / IT / ES / PT
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

  String get appTitle => 'ARK Dino Manager';

  // ─── SETTINGS ────────────────────────────────────────────────────────────

  String get settingsTitle => _t({
        'fr': 'Paramètres & Informations',
        'en': 'Settings & Information',
        'it': 'Impostazioni & Informazioni',
        'es': 'Ajustes & Información',
        'pt': 'Configurações & Informações',
      });

  String get settingsBackup => _t({
        'fr': 'SAUVEGARDE',
        'en': 'BACKUP',
        'it': 'BACKUP',
        'es': 'COPIA DE SEGURIDAD',
        'pt': 'BACKUP',
      });

  String get settingsBestiary => _t({
        'fr': 'BESTIAIRE',
        'en': 'BESTIARY',
        'it': 'BESTIARIO',
        'es': 'BESTIARIO',
        'pt': 'BESTIÁRIO',
      });

  String get settingsTags => _t({
        'fr': 'TAGS & COULEURS',
        'en': 'TAGS & COLORS',
        'it': 'TAG & COLORI',
        'es': 'ETIQUETAS & COLORES',
        'pt': 'ETIQUETAS & CORES',
      });

  String get settingsRoleThemes => _t({
        'fr': 'THÈMES PAR RÔLE',
        'en': 'ROLE THEMES',
        'it': 'TEMI PER RUOLO',
        'es': 'TEMAS POR ROL',
        'pt': 'TEMAS POR FUNÇÃO',
      });

  String get settingsLanguage => _t({
        'fr': 'LANGUE',
        'en': 'LANGUAGE',
        'it': 'LINGUA',
        'es': 'IDIOMA',
        'pt': 'IDIOMA',
      });

  String get settingsNews => _t({
        'fr': 'ACTUALITÉS',
        'en': 'NEWS',
        'it': 'NOVITÀ',
        'es': 'NOVEDADES',
        'pt': 'NOVIDADES',
      });

  String get settingsGemini => _t({
        'fr': 'OCR / GEMINI IA',
        'en': 'OCR / GEMINI AI',
        'it': 'OCR / GEMINI IA',
        'es': 'OCR / GEMINI IA',
        'pt': 'OCR / GEMINI IA',
      });

  // ─── LANGUAGE ────────────────────────────────────────────────────────────

  String get languageActive => _t({
        'fr': 'Langue active',
        'en': 'Active language',
        'it': 'Lingua attiva',
        'es': 'Idioma activo',
        'pt': 'Idioma ativo',
      });

  String get languageSelectorTitle => _t({
        'fr': 'Choisir la langue',
        'en': 'Choose language',
        'it': 'Scegli la lingua',
        'es': 'Elegir idioma',
        'pt': 'Escolher idioma',
      });

  String get languageSelectorSubtitle => _t({
        'fr': 'La langue sera appliquée immédiatement',
        'en': 'Language will be applied immediately',
        'it': 'La lingua verrà applicata immediatamente',
        'es': 'El idioma se aplicará inmediatamente',
        'pt': 'O idioma será aplicado imediatamente',
      });

  // ─── BACKUP ──────────────────────────────────────────────────────────────

  String get backupAutoActive => _t({
        'fr': 'Google Auto-Backup actif',
        'en': 'Google Auto-Backup active',
        'it': 'Google Auto-Backup attivo',
        'es': 'Google Auto-Backup activo',
        'pt': 'Google Auto-Backup ativo',
      });

  String get backupAutoDesc => _t({
        'fr':
            'Tes données sont sauvegardées automatiquement dans Google Drive toutes les 24h. Elles seront restaurées automatiquement à la réinstallation sur le même compte Google.',
        'en':
            'Your data is automatically backed up to Google Drive every 24h. It will be automatically restored on reinstallation with the same Google account.',
        'it':
            'I tuoi dati vengono salvati automaticamente su Google Drive ogni 24 ore. Verranno ripristinati automaticamente alla reinstallazione con lo stesso account Google.',
        'es':
            'Tus datos se guardan automáticamente en Google Drive cada 24 horas. Se restaurarán automáticamente al reinstalar con la misma cuenta de Google.',
        'pt':
            'Seus dados são salvos automaticamente no Google Drive a cada 24 horas. Eles serão restaurados automaticamente na reinstalação com a mesma conta Google.',
      });

  String get backupManage => _t({
        'fr': 'Gérer les sauvegardes manuelles',
        'en': 'Manage manual backups',
        'it': 'Gestisci i backup manuali',
        'es': 'Gestionar copias de seguridad manuales',
        'pt': 'Gerenciar backups manuais',
      });

  String get backupTitle => _t({
        'fr': 'SAUVEGARDE',
        'en': 'BACKUP',
        'it': 'BACKUP',
        'es': 'COPIA DE SEGURIDAD',
        'pt': 'BACKUP',
      });

  String get backupCreate => _t({
        'fr': 'Créer un backup',
        'en': 'Create backup',
        'it': 'Crea backup',
        'es': 'Crear copia de seguridad',
        'pt': 'Criar backup',
      });

  String get backupRestore => _t({
        'fr': 'Restaurer',
        'en': 'Restore',
        'it': 'Ripristina',
        'es': 'Restaurar',
        'pt': 'Restaurar',
      });

  String get backupDelete => _t({
        'fr': 'Supprimer',
        'en': 'Delete',
        'it': 'Elimina',
        'es': 'Eliminar',
        'pt': 'Excluir',
      });

  String get backupNoBackup => _t({
        'fr': 'Aucun backup disponible',
        'en': 'No backup available',
        'it': 'Nessun backup disponibile',
        'es': 'No hay copias de seguridad disponibles',
        'pt': 'Nenhum backup disponível',
      });

  String get backupSuccess => _t({
        'fr': 'Backup créé avec succès',
        'en': 'Backup created successfully',
        'it': 'Backup creato con successo',
        'es': 'Copia de seguridad creada con éxito',
        'pt': 'Backup criado com sucesso',
      });

  String get backupRestoreSuccess => _t({
        'fr': 'Restauration terminée',
        'en': 'Restore completed',
        'it': 'Ripristino completato',
        'es': 'Restauración completada',
        'pt': 'Restauração concluída',
      });

  String get backupDeleteConfirm => _t({
        'fr': 'Supprimer ce backup ?',
        'en': 'Delete this backup?',
        'it': 'Eliminare questo backup?',
        'es': '¿Eliminar esta copia de seguridad?',
        'pt': 'Excluir este backup?',
      });

  // ─── BESTIARY ────────────────────────────────────────────────────────────

  String get bestiaryDinoCards => 'DinoCards';
  String get bestiaryTrackers => 'Trackers';

  String get bestiarySpecies => _t({
        'fr': 'Espèces',
        'en': 'Species',
        'it': 'Specie',
        'es': 'Especies',
        'pt': 'Espécies',
      });

  String get bestiaryArkBestiary => _t({
        'fr': 'Bestiaire ARK',
        'en': 'ARK Bestiary',
        'it': 'Bestiario ARK',
        'es': 'Bestiario ARK',
        'pt': 'Bestiário ARK',
      });

  String bestiarySpeciesCount(int current, int total) => _t({
        'fr': '$current / $total espèces',
        'en': '$current / $total species',
        'it': '$current / $total specie',
        'es': '$current / $total especies',
        'pt': '$current / $total espécies',
      });

  String bestiaryDiscovered(String percent) => _t({
        'fr': '$percent% du bestiaire ARK découvert',
        'en': '$percent% of ARK bestiary discovered',
        'it': '$percent% del bestiario ARK scoperto',
        'es': '$percent% del bestiario ARK descubierto',
        'pt': '$percent% do bestiário ARK descoberto',
      });

  // ─── TAGS ────────────────────────────────────────────────────────────────

  String get tagsTapToChange => _t({
        'fr': 'Appuie sur un tag pour changer sa couleur',
        'en': 'Tap a tag to change its color',
        'it': 'Tocca un tag per cambiarne il colore',
        'es': 'Toca una etiqueta para cambiar su color',
        'pt': 'Toque em uma etiqueta para mudar sua cor',
      });

  String get tagsLongPressReset => _t({
        'fr': 'Appui long sur un tag personnalisé pour le réinitialiser',
        'en': 'Long press a custom tag to reset it',
        'it': 'Tieni premuto un tag personalizzato per reimpostarlo',
        'es': 'Mantén pulsada una etiqueta personalizada para restablecerla',
        'pt': 'Pressione uma etiqueta personalizada para redefini-la',
      });

  String get tagsResetAll => _t({
        'fr': 'Reset tout',
        'en': 'Reset all',
        'it': 'Reimposta tutto',
        'es': 'Restablecer todo',
        'pt': 'Redefinir tudo',
      });

  // ─── ROLE THEMES ─────────────────────────────────────────────────────────

  String get roleThemesTapHint => _t({
        'fr': 'Appuie sur un rôle pour personnaliser ses 3 couleurs',
        'en': 'Tap a role to customize its 3 colors',
        'it': 'Tocca un ruolo per personalizzare i suoi 3 colori',
        'es': 'Toca un rol para personalizar sus 3 colores',
        'pt': 'Toque em uma função para personalizar suas 3 cores',
      });

  String get roleThemesBackground => _t({
        'fr': 'Fond',
        'en': 'Background',
        'it': 'Sfondo',
        'es': 'Fondo',
        'pt': 'Fundo',
      });

  String get roleThemesBorder => _t({
        'fr': 'Bordure',
        'en': 'Border',
        'it': 'Bordo',
        'es': 'Borde',
        'pt': 'Borda',
      });

  String get roleThemesText => _t({
        'fr': 'Texte',
        'en': 'Text',
        'it': 'Testo',
        'es': 'Texto',
        'pt': 'Texto',
      });

  String get roleThemesApply => _t({
        'fr': 'Appliquer',
        'en': 'Apply',
        'it': 'Applica',
        'es': 'Aplicar',
        'pt': 'Aplicar',
      });

  String get roleThemesCancel => _t({
        'fr': 'Annuler',
        'en': 'Cancel',
        'it': 'Annulla',
        'es': 'Cancelar',
        'pt': 'Cancelar',
      });

  String get roleThemesPreview => _t({
        'fr': 'Aperçu',
        'en': 'Preview',
        'it': 'Anteprima',
        'es': 'Vista previa',
        'pt': 'Pré-visualização',
      });

  String get roleThemesConfirmReset => _t({
        'fr': 'Réinitialiser tous les thèmes ?',
        'en': 'Reset all themes?',
        'it': 'Reimpostare tutti i temi?',
        'es': '¿Restablecer todos los temas?',
        'pt': 'Redefinir todos os temas?',
      });

  String get roleThemesConfirmResetDesc => _t({
        'fr': 'Cette action supprimera toutes les personnalisations de rôles.',
        'en': 'This will delete all role customizations.',
        'it': 'Tutte le personalizzazioni dei ruoli verranno eliminate.',
        'es': 'Se eliminarán todas las personalizaciones de roles.',
        'pt': 'Todas as personalizações de funções serão excluídas.',
      });

  // ─── COLOR REGIONS ───────────────────────────────────────────────────────

  String get colorRegionsTitle => _t({
        'fr': 'RÉGIONS DE COULEUR',
        'en': 'COLOR REGIONS',
        'it': 'REGIONI DI COLORE',
        'es': 'REGIONES DE COLOR',
        'pt': 'REGIÕES DE COR',
      });

  String get colorRegionVisible => _t({
        'fr': 'Visible',
        'en': 'Visible',
        'it': 'Visibile',
        'es': 'Visible',
        'pt': 'Visível',
      });

  String get colorRegionInvisible => _t({
        'fr': 'Invisible',
        'en': 'Invisible',
        'it': 'Invisibile',
        'es': 'Invisible',
        'pt': 'Invisível',
      });

  String colorRegionLabel(int index) => 'R$index';

  String get colorBankTitle => _t({
        'fr': 'BANQUE DE COULEURS',
        'en': 'COLOR BANK',
        'it': 'BANCA COLORI',
        'es': 'BANCO DE COLORES',
        'pt': 'BANCO DE CORES',
      });

  String get colorBankNoColor => _t({
        'fr': 'Aucune couleur enregistrée',
        'en': 'No color recorded',
        'it': 'Nessun colore registrato',
        'es': 'Ningún color registrado',
        'pt': 'Nenhuma cor registrada',
      });

  String colorBankRegion(int index) => _t({
        'fr': 'Région $index',
        'en': 'Region $index',
        'it': 'Regione $index',
        'es': 'Región $index',
        'pt': 'Região $index',
      });

  // ─── SPECIES JOURNAL ─────────────────────────────────────────────────────

  String get speciesJournalTitle => _t({
        'fr': "Journal d'Espèce",
        'en': 'Species Journal',
        'it': 'Diario delle Specie',
        'es': 'Diario de Especies',
        'pt': 'Diário de Espécies',
      });

  String get speciesJournalSubtitle => _t({
        'fr': "Journal d'espece",
        'en': 'Species journal',
        'it': 'Diario delle specie',
        'es': 'Diario de especies',
        'pt': 'Diário de espécies',
      });

  String get speciesJournalBestStats => _t({
        'fr': 'MEILLEURES STATS',
        'en': 'BEST STATS',
        'it': 'STATISTICHE MIGLIORI',
        'es': 'MEJORES ESTADÍSTICAS',
        'pt': 'MELHORES STATS',
      });

  String get speciesJournalLibraryDinos => _t({
        'fr': 'DINOS DE LA BIBLIOTHÈQUE',
        'en': 'LIBRARY DINOS',
        'it': 'DINO DELLA LIBRERIA',
        'es': 'DINOS DE LA BIBLIOTECA',
        'pt': 'DINOS DA BIBLIOTECA',
      });

  String get speciesJournalNoTracker => _t({
        'fr': 'Aucun tracker actif',
        'en': 'No active tracker',
        'it': 'Nessun tracker attivo',
        'es': 'Ningún rastreador activo',
        'pt': 'Nenhum rastreador ativo',
      });

  String speciesJournalTotalColors(int count) => _t({
        'fr': '$count couleurs',
        'en': '$count colors',
        'it': '$count colori',
        'es': '$count colores',
        'pt': '$count cores',
      });

  // ─── HOME ────────────────────────────────────────────────────────────────

  String get homeTitle => 'ARK MANAGER';

  String get homeSubtitle => _t({
        'fr': 'Ta bibliothèque de dinos',
        'en': 'Your dino library',
        'it': 'La tua libreria di dino',
        'es': 'Tu biblioteca de dinos',
        'pt': 'Sua biblioteca de dinos',
      });

  String get homeNoDinos => _t({
        'fr': 'Aucun dino dans la bibliothèque',
        'en': 'No dinos in the library',
        'it': 'Nessun dino nella libreria',
        'es': 'No hay dinos en la biblioteca',
        'pt': 'Nenhum dino na biblioteca',
      });

  String get homeAddFirst => _t({
        'fr': 'Ajoute ton premier dino !',
        'en': 'Add your first dino!',
        'it': 'Aggiungi il tuo primo dino!',
        'es': '¡Añade tu primer dino!',
        'pt': 'Adicione seu primeiro dino!',
      });

  String get homeSearch => _t({
        'fr': 'Rechercher...',
        'en': 'Search...',
        'it': 'Cerca...',
        'es': 'Buscar...',
        'pt': 'Pesquisar...',
      });

  String get homeFilter => _t({
        'fr': 'Filtrer',
        'en': 'Filter',
        'it': 'Filtra',
        'es': 'Filtrar',
        'pt': 'Filtrar',
      });

  String get homeSortBy => _t({
        'fr': 'Trier par',
        'en': 'Sort by',
        'it': 'Ordina per',
        'es': 'Ordenar por',
        'pt': 'Ordenar por',
      });

  String get homeStats => _t({
        'fr': 'Statistiques',
        'en': 'Statistics',
        'it': 'Statistiche',
        'es': 'Estadísticas',
        'pt': 'Estatísticas',
      });

  String get homeSortName => _t({
        'fr': 'Nom',
        'en': 'Name',
        'it': 'Nome',
        'es': 'Nombre',
        'pt': 'Nome',
      });

  String get homeSortLevel => _t({
        'fr': 'Niveau',
        'en': 'Level',
        'it': 'Livello',
        'es': 'Nivel',
        'pt': 'Nível',
      });

  String get homeSortSpecies => _t({
        'fr': 'Espèce',
        'en': 'Species',
        'it': 'Specie',
        'es': 'Especie',
        'pt': 'Espécie',
      });

  String get homeSortDate => _t({
        'fr': 'Date',
        'en': 'Date',
        'it': 'Data',
        'es': 'Fecha',
        'pt': 'Data',
      });

  String get homeSortMutations => _t({
        'fr': 'Mutations',
        'en': 'Mutations',
        'it': 'Mutazioni',
        'es': 'Mutaciones',
        'pt': 'Mutações',
      });

  // ─── LIBRARY ─────────────────────────────────────────────────────────────

  String get libraryTitle => _t({
        'fr': 'BIBLIOTHÈQUE',
        'en': 'LIBRARY',
        'it': 'LIBRERIA',
        'es': 'BIBLIOTECA',
        'pt': 'BIBLIOTECA',
      });

  String get libraryEmpty => _t({
        'fr': 'Bibliothèque vide',
        'en': 'Empty library',
        'it': 'Libreria vuota',
        'es': 'Biblioteca vacía',
        'pt': 'Biblioteca vazia',
      });

  String get libraryAddDino => _t({
        'fr': 'Ajouter un dino',
        'en': 'Add a dino',
        'it': 'Aggiungi un dino',
        'es': 'Añadir un dino',
        'pt': 'Adicionar um dino',
      });

  String get libraryImport => _t({
        'fr': 'Importer',
        'en': 'Import',
        'it': 'Importa',
        'es': 'Importar',
        'pt': 'Importar',
      });

  String get libraryExport => _t({
        'fr': 'Exporter',
        'en': 'Export',
        'it': 'Esporta',
        'es': 'Exportar',
        'pt': 'Exportar',
      });

  String get libraryExportExcel => _t({
        'fr': 'Exporter Excel',
        'en': 'Export Excel',
        'it': 'Esporta Excel',
        'es': 'Exportar Excel',
        'pt': 'Exportar Excel',
      });

  String get libraryShare => _t({
        'fr': 'Partager',
        'en': 'Share',
        'it': 'Condividi',
        'es': 'Compartir',
        'pt': 'Compartilhar',
      });

  // ─── DINO DETAIL ─────────────────────────────────────────────────────────

  String get dinoDetailEdit => _t({
        'fr': 'Modifier',
        'en': 'Edit',
        'it': 'Modifica',
        'es': 'Editar',
        'pt': 'Editar',
      });

  String get dinoDetailDelete => _t({
        'fr': 'Supprimer',
        'en': 'Delete',
        'it': 'Elimina',
        'es': 'Eliminar',
        'pt': 'Excluir',
      });

  String get dinoDetailShare => _t({
        'fr': 'Partager',
        'en': 'Share',
        'it': 'Condividi',
        'es': 'Compartir',
        'pt': 'Compartilhar',
      });

  String get dinoDetailStats => _t({
        'fr': 'STATISTIQUES',
        'en': 'STATISTICS',
        'it': 'STATISTICHE',
        'es': 'ESTADÍSTICAS',
        'pt': 'ESTATÍSTICAS',
      });

  String get dinoDetailColors => _t({
        'fr': 'COULEURS',
        'en': 'COLORS',
        'it': 'COLORI',
        'es': 'COLORES',
        'pt': 'CORES',
      });

  String get dinoDetailMutations => _t({
        'fr': 'MUTATIONS',
        'en': 'MUTATIONS',
        'it': 'MUTAZIONI',
        'es': 'MUTACIONES',
        'pt': 'MUTAÇÕES',
      });

  String get dinoDetailNotes => _t({
        'fr': 'NOTES',
        'en': 'NOTES',
        'it': 'NOTE',
        'es': 'NOTAS',
        'pt': 'NOTAS',
      });

  String get dinoDetailBreeding => _t({
        'fr': 'ÉLEVAGE',
        'en': 'BREEDING',
        'it': 'ALLEVAMENTO',
        'es': 'CRÍA',
        'pt': 'CRIAÇÃO',
      });

  String get dinoDetailConfirmDelete => _t({
        'fr': 'Supprimer ce dino ?',
        'en': 'Delete this dino?',
        'it': 'Eliminare questo dino?',
        'es': '¿Eliminar este dino?',
        'pt': 'Excluir este dino?',
      });

  String get dinoDetailConfirmDeleteDesc => _t({
        'fr': 'Cette action est irréversible.',
        'en': 'This action is irreversible.',
        'it': 'Questa azione è irreversibile.',
        'es': 'Esta acción es irreversible.',
        'pt': 'Esta ação é irreversível.',
      });

  // ─── ADD/EDIT DINO ───────────────────────────────────────────────────────

  String get addEditDinoTitle => _t({
        'fr': 'Ajouter un Dino',
        'en': 'Add a Dino',
        'it': 'Aggiungi un Dino',
        'es': 'Añadir un Dino',
        'pt': 'Adicionar um Dino',
      });

  String get editDinoTitle => _t({
        'fr': 'Modifier le Dino',
        'en': 'Edit Dino',
        'it': 'Modifica Dino',
        'es': 'Editar Dino',
        'pt': 'Editar Dino',
      });

  String get addEditDinoSave => _t({
        'fr': 'Sauvegarder',
        'en': 'Save',
        'it': 'Salva',
        'es': 'Guardar',
        'pt': 'Salvar',
      });

  String get addEditDinoCancel => _t({
        'fr': 'Annuler',
        'en': 'Cancel',
        'it': 'Annulla',
        'es': 'Cancelar',
        'pt': 'Cancelar',
      });

  String get addEditDinoSpecies => _t({
        'fr': 'Espèce',
        'en': 'Species',
        'it': 'Specie',
        'es': 'Especie',
        'pt': 'Espécie',
      });

  String get addEditDinoName => _t({
        'fr': 'Nom',
        'en': 'Name',
        'it': 'Nome',
        'es': 'Nombre',
        'pt': 'Nome',
      });

  String get addEditDinoLevel => _t({
        'fr': 'Niveau',
        'en': 'Level',
        'it': 'Livello',
        'es': 'Nivel',
        'pt': 'Nível',
      });

  String get addEditDinoSexMale => _t({
        'fr': 'Mâle',
        'en': 'Male',
        'it': 'Maschio',
        'es': 'Macho',
        'pt': 'Macho',
      });

  String get addEditDinoSexFemale => _t({
        'fr': 'Femelle',
        'en': 'Female',
        'it': 'Femmina',
        'es': 'Hembra',
        'pt': 'Fêmea',
      });

  String get addEditDinoTamed => _t({
        'fr': 'Apprivoisé',
        'en': 'Tamed',
        'it': 'Addomesticato',
        'es': 'Domesticado',
        'pt': 'Domado',
      });

  String get addEditDinoBred => _t({
        'fr': 'Élevé',
        'en': 'Bred',
        'it': 'Allevato',
        'es': 'Criado',
        'pt': 'Criado',
      });

  String get addEditDinoNotes => _t({
        'fr': 'Notes',
        'en': 'Notes',
        'it': 'Note',
        'es': 'Notas',
        'pt': 'Notas',
      });

  String get addEditDinoTags => _t({
        'fr': 'Tags',
        'en': 'Tags',
        'it': 'Tag',
        'es': 'Etiquetas',
        'pt': 'Etiquetas',
      });

  String get addEditDinoStats => _t({
        'fr': 'Statistiques',
        'en': 'Statistics',
        'it': 'Statistiche',
        'es': 'Estadísticas',
        'pt': 'Estatísticas',
      });

  String get addEditDinoColors => _t({
        'fr': 'Couleurs',
        'en': 'Colors',
        'it': 'Colori',
        'es': 'Colores',
        'pt': 'Cores',
      });

  String get addEditDinoMutPaternal => _t({
        'fr': 'Paternelles',
        'en': 'Paternal',
        'it': 'Paterne',
        'es': 'Paternales',
        'pt': 'Paternas',
      });

  String get addEditDinoMutMaternal => _t({
        'fr': 'Maternelles',
        'en': 'Maternal',
        'it': 'Materne',
        'es': 'Maternales',
        'pt': 'Maternas',
      });

  // ─── SCAN ────────────────────────────────────────────────────────────────

  String get scanTitle => _t({
        'fr': 'Scanner un Dino',
        'en': 'Scan a Dino',
        'it': 'Scansiona un Dino',
        'es': 'Escanear un Dino',
        'pt': 'Escanear um Dino',
      });

  String get scanCapture => _t({
        'fr': 'Capturer',
        'en': 'Capture',
        'it': 'Cattura',
        'es': 'Capturar',
        'pt': 'Capturar',
      });

  String get scanAnalyze => _t({
        'fr': 'Analyser',
        'en': 'Analyze',
        'it': 'Analizza',
        'es': 'Analizar',
        'pt': 'Analisar',
      });

  String get scanRetry => _t({
        'fr': 'Réessayer',
        'en': 'Retry',
        'it': 'Riprova',
        'es': 'Reintentar',
        'pt': 'Tentar novamente',
      });

  String get scanSuccess => _t({
        'fr': 'Scan réussi !',
        'en': 'Scan successful!',
        'it': 'Scansione riuscita!',
        'es': '¡Escaneo exitoso!',
        'pt': 'Scan bem-sucedido!',
      });

  String get scanFailed => _t({
        'fr': 'Scan échoué',
        'en': 'Scan failed',
        'it': 'Scansione fallita',
        'es': 'Escaneo fallido',
        'pt': 'Scan falhou',
      });

  String get scanNoText => _t({
        'fr': 'Aucun texte détecté',
        'en': 'No text detected',
        'it': 'Nessun testo rilevato',
        'es': 'No se detectó texto',
        'pt': 'Nenhum texto detectado',
      });

  String get scanHint => _t({
        'fr': 'Pointez la caméra sur les stats ARK',
        'en': 'Point the camera at ARK stats',
        'it': 'Punta la fotocamera sulle statistiche ARK',
        'es': 'Apunta la cámara a las estadísticas ARK',
        'pt': 'Aponte a câmera para as estatísticas ARK',
      });

  // ─── TRACKER ─────────────────────────────────────────────────────────────

  String get trackerTitle => 'Trackers';

  String get trackerEmpty => _t({
        'fr': 'Aucun tracker actif',
        'en': 'No active tracker',
        'it': 'Nessun tracker attivo',
        'es': 'Ningún rastreador activo',
        'pt': 'Nenhum rastreador ativo',
      });

  String get trackerAdd => _t({
        'fr': 'Nouveau tracker',
        'en': 'New tracker',
        'it': 'Nuovo tracker',
        'es': 'Nuevo rastreador',
        'pt': 'Novo rastreador',
      });

  String get trackerSpecies => _t({
        'fr': 'Espèce suivie',
        'en': 'Tracked species',
        'it': 'Specie tracciata',
        'es': 'Especie rastreada',
        'pt': 'Espécie rastreada',
      });

  String get trackerGoal => _t({
        'fr': 'Objectif',
        'en': 'Goal',
        'it': 'Obiettivo',
        'es': 'Objetivo',
        'pt': 'Objetivo',
      });

  String get trackerProgress => _t({
        'fr': 'Progression',
        'en': 'Progress',
        'it': 'Progressione',
        'es': 'Progreso',
        'pt': 'Progresso',
      });

  String get trackerStatus => _t({
        'fr': 'Statut',
        'en': 'Status',
        'it': 'Stato',
        'es': 'Estado',
        'pt': 'Status',
      });

  String get trackerStatusActive => _t({
        'fr': 'Actif',
        'en': 'Active',
        'it': 'Attivo',
        'es': 'Activo',
        'pt': 'Ativo',
      });

  String get trackerStatusCompleted => _t({
        'fr': 'Terminé',
        'en': 'Completed',
        'it': 'Completato',
        'es': 'Completado',
        'pt': 'Concluído',
      });

  String get trackerStatusPaused => _t({
        'fr': 'En pause',
        'en': 'Paused',
        'it': 'In pausa',
        'es': 'En pausa',
        'pt': 'Em pausa',
      });

  String get trackerNotes => _t({
        'fr': 'Notes',
        'en': 'Notes',
        'it': 'Note',
        'es': 'Notas',
        'pt': 'Notas',
      });

  // ─── ORDERS ──────────────────────────────────────────────────────────────

  String get ordersTitle => _t({
        'fr': 'Commandes',
        'en': 'Orders',
        'it': 'Ordini',
        'es': 'Pedidos',
        'pt': 'Pedidos',
      });

  String get ordersEmpty => _t({
        'fr': 'Aucune commande',
        'en': 'No orders',
        'it': 'Nessun ordine',
        'es': 'Sin pedidos',
        'pt': 'Sem pedidos',
      });

  String get ordersAdd => _t({
        'fr': 'Nouvelle commande',
        'en': 'New order',
        'it': 'Nuovo ordine',
        'es': 'Nuevo pedido',
        'pt': 'Novo pedido',
      });

  String get ordersStatus => _t({
        'fr': 'Statut',
        'en': 'Status',
        'it': 'Stato',
        'es': 'Estado',
        'pt': 'Status',
      });

  String get ordersPending => _t({
        'fr': 'En attente',
        'en': 'Pending',
        'it': 'In attesa',
        'es': 'Pendiente',
        'pt': 'Pendente',
      });

  String get ordersCompleted => _t({
        'fr': 'Terminé',
        'en': 'Completed',
        'it': 'Completato',
        'es': 'Completado',
        'pt': 'Concluído',
      });

  String get ordersCancelled => _t({
        'fr': 'Annulé',
        'en': 'Cancelled',
        'it': 'Annullato',
        'es': 'Cancelado',
        'pt': 'Cancelado',
      });

  String get ordersTotal => _t({
        'fr': 'Total',
        'en': 'Total',
        'it': 'Totale',
        'es': 'Total',
        'pt': 'Total',
      });

  String get ordersCurrency => _t({
        'fr': 'Monnaie',
        'en': 'Currency',
        'it': 'Valuta',
        'es': 'Moneda',
        'pt': 'Moeda',
      });

  String get orderCreateTitle => _t({
        'fr': 'Nouvelle Commande',
        'en': 'New Order',
        'it': 'Nuovo Ordine',
        'es': 'Nuevo Pedido',
        'pt': 'Novo Pedido',
      });

  String get orderEditTitle => _t({
        'fr': 'Modifier la Commande',
        'en': 'Edit Order',
        'it': 'Modifica Ordine',
        'es': 'Editar Pedido',
        'pt': 'Editar Pedido',
      });

  String get orderBuyer => _t({
        'fr': 'Acheteur',
        'en': 'Buyer',
        'it': 'Acquirente',
        'es': 'Comprador',
        'pt': 'Comprador',
      });

  String get orderSeller => _t({
        'fr': 'Vendeur',
        'en': 'Seller',
        'it': 'Venditore',
        'es': 'Vendedor',
        'pt': 'Vendedor',
      });

  String get orderNote => _t({
        'fr': 'Note',
        'en': 'Note',
        'it': 'Nota',
        'es': 'Nota',
        'pt': 'Nota',
      });

  String get orderDeadline => _t({
        'fr': 'Échéance',
        'en': 'Deadline',
        'it': 'Scadenza',
        'es': 'Plazo',
        'pt': 'Prazo',
      });

  // ─── COMMON ──────────────────────────────────────────────────────────────

  String get confirmYes => _t({
        'fr': 'Oui',
        'en': 'Yes',
        'it': 'Sì',
        'es': 'Sí',
        'pt': 'Sim',
      });

  String get confirmNo => _t({
        'fr': 'Non',
        'en': 'No',
        'it': 'No',
        'es': 'No',
        'pt': 'Não',
      });

  String get confirmDelete => _t({
        'fr': 'Supprimer',
        'en': 'Delete',
        'it': 'Elimina',
        'es': 'Eliminar',
        'pt': 'Excluir',
      });

  String get confirmCancel => _t({
        'fr': 'Annuler',
        'en': 'Cancel',
        'it': 'Annulla',
        'es': 'Cancelar',
        'pt': 'Cancelar',
      });

  String get confirmOk => 'OK';

  String get confirmSave => _t({
        'fr': 'Sauvegarder',
        'en': 'Save',
        'it': 'Salva',
        'es': 'Guardar',
        'pt': 'Salvar',
      });

  String get confirmClose => _t({
        'fr': 'Fermer',
        'en': 'Close',
        'it': 'Chiudi',
        'es': 'Cerrar',
        'pt': 'Fechar',
      });

  String get confirmApply => _t({
        'fr': 'Appliquer',
        'en': 'Apply',
        'it': 'Applica',
        'es': 'Aplicar',
        'pt': 'Aplicar',
      });

  String get confirmReset => _t({
        'fr': 'Réinitialiser',
        'en': 'Reset',
        'it': 'Reimposta',
        'es': 'Restablecer',
        'pt': 'Redefinir',
      });

  String get confirmResetAll => _t({
        'fr': 'Tout réinitialiser',
        'en': 'Reset all',
        'it': 'Reimposta tutto',
        'es': 'Restablecer todo',
        'pt': 'Redefinir tudo',
      });

  // ─── ERRORS ──────────────────────────────────────────────────────────────

  String get errorGeneric => _t({
        'fr': "Une erreur s'est produite",
        'en': 'An error occurred',
        'it': 'Si è verificato un errore',
        'es': 'Se ha producido un error',
        'pt': 'Ocorreu um erro',
      });

  String get errorLoading => _t({
        'fr': 'Erreur de chargement',
        'en': 'Loading error',
        'it': 'Errore di caricamento',
        'es': 'Error de carga',
        'pt': 'Erro de carregamento',
      });

  String get errorSaving => _t({
        'fr': 'Erreur de sauvegarde',
        'en': 'Save error',
        'it': 'Errore di salvataggio',
        'es': 'Error al guardar',
        'pt': 'Erro ao salvar',
      });

  String get errorPermission => _t({
        'fr': 'Permission refusée',
        'en': 'Permission denied',
        'it': 'Autorizzazione negata',
        'es': 'Permiso denegado',
        'pt': 'Permissão negada',
      });

  String get errorCameraPermission => _t({
        'fr': 'Permission caméra requise',
        'en': 'Camera permission required',
        'it': 'Autorizzazione fotocamera richiesta',
        'es': 'Se requiere permiso de cámara',
        'pt': 'Permissão de câmera necessária',
      });

  String get errorImageGeneration => _t({
        'fr': "Erreur lors de la génération de l'image",
        'en': 'Error generating image',
        'it': "Errore durante la generazione dell'immagine",
        'es': 'Error al generar la imagen',
        'pt': 'Erro ao gerar a imagem',
      });

  // ─── NAVIGATION ──────────────────────────────────────────────────────────

  String get navHome => _t({
        'fr': 'Accueil',
        'en': 'Home',
        'it': 'Home',
        'es': 'Inicio',
        'pt': 'Início',
      });

  String get navLibrary => _t({
        'fr': 'Bibliothèque',
        'en': 'Library',
        'it': 'Libreria',
        'es': 'Biblioteca',
        'pt': 'Biblioteca',
      });

  String get navScan => _t({
        'fr': 'Scanner',
        'en': 'Scan',
        'it': 'Scansiona',
        'es': 'Escanear',
        'pt': 'Escanear',
      });

  String get navTracker => 'Tracker';

  String get navSettings => _t({
        'fr': 'Paramètres',
        'en': 'Settings',
        'it': 'Impostazioni',
        'es': 'Ajustes',
        'pt': 'Configurações',
      });

  // ─── STATS NAMES ─────────────────────────────────────────────────────────

  String get statHp => _t({
        'fr': 'PV',
        'en': 'HP',
        'it': 'PS',
        'es': 'PS',
        'pt': 'PV',
      });

  String get statStamina => _t({
        'fr': 'Endurance',
        'en': 'Stamina',
        'it': 'Stamina',
        'es': 'Resistencia',
        'pt': 'Stamina',
      });

  String get statTorpor => 'Torpor';

  String get statOxygen => _t({
        'fr': 'Oxygène',
        'en': 'Oxygen',
        'it': 'Ossigeno',
        'es': 'Oxígeno',
        'pt': 'Oxigênio',
      });

  String get statFood => _t({
        'fr': 'Nourriture',
        'en': 'Food',
        'it': 'Cibo',
        'es': 'Comida',
        'pt': 'Comida',
      });

  String get statWater => _t({
        'fr': 'Eau',
        'en': 'Water',
        'it': 'Acqua',
        'es': 'Agua',
        'pt': 'Água',
      });

  String get statTemperature => _t({
        'fr': 'Température',
        'en': 'Temperature',
        'it': 'Temperatura',
        'es': 'Temperatura',
        'pt': 'Temperatura',
      });

  String get statWeight => _t({
        'fr': 'Poids',
        'en': 'Weight',
        'it': 'Peso',
        'es': 'Peso',
        'pt': 'Peso',
      });

  String get statMelee => _t({
        'fr': 'Mêlée',
        'en': 'Melee',
        'it': 'Mischia',
        'es': 'Cuerpo a cuerpo',
        'pt': 'Corpo a corpo',
      });

  String get statSpeed => _t({
        'fr': 'Vitesse',
        'en': 'Speed',
        'it': 'Velocità',
        'es': 'Velocidad',
        'pt': 'Velocidade',
      });

  String get statFortitude => _t({
        'fr': 'Vigueur',
        'en': 'Fortitude',
        'it': 'Robustezza',
        'es': 'Fortaleza',
        'pt': 'Resistência',
      });

  String get statCrafting => _t({
        'fr': 'Artisanat',
        'en': 'Crafting',
        'it': 'Artigianato',
        'es': 'Artesanía',
        'pt': 'Artesanato',
      });

  // ─── SIMULATOR ───────────────────────────────────────────────────────────

  String get simulatorTitle => _t({
        'fr': 'SIMULATEUR',
        'en': 'SIMULATOR',
        'it': 'SIMULATORE',
        'es': 'SIMULADOR',
        'pt': 'SIMULADOR',
      });

  String get simulatorRandom => _t({
        'fr': 'Aléatoire',
        'en': 'Random',
        'it': 'Casuale',
        'es': 'Aleatorio',
        'pt': 'Aleatório',
      });

  String get simulatorReset => _t({
        'fr': 'Réinitialiser',
        'en': 'Reset',
        'it': 'Azzera',
        'es': 'Reiniciar',
        'pt': 'Reiniciar',
      });

  String get simulatorRegisteredOnly => _t({
        'fr': 'Couleurs enregistrées uniquement',
        'en': 'Registered colors only',
        'it': 'Solo colori registrati',
        'es': 'Solo colores registrados',
        'pt': 'Somente cores registradas',
      });

  String get simulatorSolidMode => _t({
        'fr': 'Mode Solide',
        'en': 'Solid Mode',
        'it': 'Modalità Solido',
        'es': 'Modo Sólido',
        'pt': 'Modo Sólido',
      });

  String get simulatorNoColors => _t({
        'fr': 'Aucune couleur disponible',
        'en': 'No colors available',
        'it': 'Nessun colore disponibile',
        'es': 'No hay colores disponibles',
        'pt': 'Nenhuma cor disponível',
      });

  String get simulatorSource => _t({
        'fr': 'Source',
        'en': 'Source',
        'it': 'Sorgente',
        'es': 'Fuente',
        'pt': 'Fonte',
      });

  String get simulatorLibrary => _t({
        'fr': 'Bibliothèque',
        'en': 'Library',
        'it': 'Libreria',
        'es': 'Biblioteca',
        'pt': 'Biblioteca',
      });

  String get simulatorObserver => _t({
        'fr': 'Observateur',
        'en': 'Observer',
        'it': 'Osservatore',
        'es': 'Observador',
        'pt': 'Observador',
      });

  // ─── SHARE / EXPORT ──────────────────────────────────────────────────────

  String get shareTitle => _t({
        'fr': 'PARTAGER',
        'en': 'SHARE',
        'it': 'CONDIVIDI',
        'es': 'COMPARTIR',
        'pt': 'COMPARTILHAR',
      });

  String get shareCard => _t({
        'fr': 'Carte Dino',
        'en': 'Dino Card',
        'it': 'Scheda Dino',
        'es': 'Tarjeta Dino',
        'pt': 'Cartão Dino',
      });

  String get sharePortrait => _t({
        'fr': 'Portrait',
        'en': 'Portrait',
        'it': 'Ritratto',
        'es': 'Retrato',
        'pt': 'Retrato',
      });

  String get shareExport => _t({
        'fr': 'Exporter image',
        'en': 'Export image',
        'it': 'Esporta immagine',
        'es': 'Exportar imagen',
        'pt': 'Exportar imagem',
      });

  // ─── VARIANTS ────────────────────────────────────────────────────────────

  String get variantsTitle => _t({
        'fr': 'VARIANTES',
        'en': 'VARIANTS',
        'it': 'VARIANTI',
        'es': 'VARIANTES',
        'pt': 'VARIANTES',
      });

  String get variantsSelect => _t({
        'fr': 'Sélectionner des variantes',
        'en': 'Select variants',
        'it': 'Seleziona varianti',
        'es': 'Seleccionar variantes',
        'pt': 'Selecionar variantes',
      });

  String get variantsExport => _t({
        'fr': 'Exporter les variantes',
        'en': 'Export variants',
        'it': 'Esporta varianti',
        'es': 'Exportar variantes',
        'pt': 'Exportar variantes',
      });

  String variantsCount(int count) => _t({
        'fr': '$count variante(s)',
        'en': '$count variant(s)',
        'it': '$count variante/i',
        'es': '$count variante(s)',
        'pt': '$count variante(s)',
      });

  // ─── JOURNAL ─────────────────────────────────────────────────────────────

  String get journalTabStats => _t({
        'fr': 'STATS',
        'en': 'STATS',
        'it': 'STATISTICHE',
        'es': 'STATS',
        'pt': 'STATS',
      });

  String get journalTabColors => _t({
        'fr': 'COULEURS',
        'en': 'COLORS',
        'it': 'COLORI',
        'es': 'COLORES',
        'pt': 'CORES',
      });

  String get journalTabDinos => _t({
        'fr': 'MES DINOS',
        'en': 'MY DINOS',
        'it': 'I MIEI DINO',
        'es': 'MIS DINOS',
        'pt': 'MEUS DINOS',
      });

  String get journalTabSimulator => _t({
        'fr': 'SIMULATEUR',
        'en': 'SIMULATOR',
        'it': 'SIMULATORE',
        'es': 'SIMULADOR',
        'pt': 'SIMULADOR',
      });

  String get journalBestMale => _t({
        'fr': 'Meilleur Mâle',
        'en': 'Best Male',
        'it': 'Miglior Maschio',
        'es': 'Mejor Macho',
        'pt': 'Melhor Macho',
      });

  String get journalBestFemale => _t({
        'fr': 'Meilleure Femelle',
        'en': 'Best Female',
        'it': 'Miglior Femmina',
        'es': 'Mejor Hembra',
        'pt': 'Melhor Fêmea',
      });

  String get journalObservations => _t({
        'fr': 'Observations',
        'en': 'Observations',
        'it': 'Osservazioni',
        'es': 'Observaciones',
        'pt': 'Observações',
      });

  String get journalAddObservation => _t({
        'fr': 'Ajouter une observation',
        'en': 'Add observation',
        'it': 'Aggiungi osservazione',
        'es': 'Añadir observación',
        'pt': 'Adicionar observação',
      });

  String get journalNoObservation => _t({
        'fr': 'Aucune observation',
        'en': 'No observations',
        'it': 'Nessuna osservazione',
        'es': 'Sin observaciones',
        'pt': 'Sem observações',
      });

  String get journalColorBank => _t({
        'fr': 'Banque de Couleurs',
        'en': 'Color Bank',
        'it': 'Banca Colori',
        'es': 'Banco de Colores',
        'pt': 'Banco de Cores',
      });

  String get journalSolidColor => _t({
        'fr': 'Couleur solide',
        'en': 'Solid color',
        'it': 'Colore solido',
        'es': 'Color sólido',
        'pt': 'Cor sólida',
      });

  String get journalAllRegions => _t({
        'fr': 'Toutes les régions',
        'en': 'All regions',
        'it': 'Tutte le regioni',
        'es': 'Todas las regiones',
        'pt': 'Todas as regiões',
      });

  // ─── GEMINI ──────────────────────────────────────────────────────────────

  String get geminiTitle => _t({
        'fr': 'OCR / GEMINI IA',
        'en': 'OCR / GEMINI AI',
        'it': 'OCR / GEMINI IA',
        'es': 'OCR / GEMINI IA',
        'pt': 'OCR / GEMINI IA',
      });

  String get geminiApiKey => _t({
        'fr': 'Clé API Gemini',
        'en': 'Gemini API Key',
        'it': 'Chiave API Gemini',
        'es': 'Clave API de Gemini',
        'pt': 'Chave API Gemini',
      });

  String get geminiSave => _t({
        'fr': 'Sauvegarder la clé',
        'en': 'Save key',
        'it': 'Salva chiave',
        'es': 'Guardar clave',
        'pt': 'Salvar chave',
      });

  String get geminiTest => _t({
        'fr': 'Tester OCR',
        'en': 'Test OCR',
        'it': 'Testa OCR',
        'es': 'Probar OCR',
        'pt': 'Testar OCR',
      });

  String get geminiSuccess => _t({
        'fr': 'Clé valide',
        'en': 'Valid key',
        'it': 'Chiave valida',
        'es': 'Clave válida',
        'pt': 'Chave válida',
      });

  String get geminiError => _t({
        'fr': 'Clé invalide',
        'en': 'Invalid key',
        'it': 'Chiave non valida',
        'es': 'Clave no válida',
        'pt': 'Chave inválida',
      });

  // ─── MISC ────────────────────────────────────────────────────────────────

  String get sexMale => _t({
        'fr': 'Mâle',
        'en': 'Male',
        'it': 'Maschio',
        'es': 'Macho',
        'pt': 'Macho',
      });

  String get sexFemale => _t({
        'fr': 'Femelle',
        'en': 'Female',
        'it': 'Femmina',
        'es': 'Hembra',
        'pt': 'Fêmea',
      });

  String get sexUnknown => _t({
        'fr': 'Inconnu',
        'en': 'Unknown',
        'it': 'Sconosciuto',
        'es': 'Desconocido',
        'pt': 'Desconhecido',
      });

  String levelLabel(int level) => _t({
        'fr': 'Niv. $level',
        'en': 'Lv. $level',
        'it': 'Lv. $level',
        'es': 'Nv. $level',
        'pt': 'Nv. $level',
      });

  String colorIdLabel(int id) => 'ID $id';

  String get changelogView => _t({
        'fr': 'Voir le changelog',
        'en': 'View changelog',
        'it': 'Visualizza changelog',
        'es': 'Ver registro de cambios',
        'pt': 'Ver registro de alterações',
      });

  String get changelogTitle => _t({
        'fr': 'Changelog',
        'en': 'Changelog',
        'it': 'Changelog',
        'es': 'Registro de cambios',
        'pt': 'Registro de alterações',
      });

  String versionLabel(String version) => _t({
        'fr': 'Version $version',
        'en': 'Version $version',
        'it': 'Versione $version',
        'es': 'Versión $version',
        'pt': 'Versão $version',
      });

  String searchNoResults(String query) => _t({
        'fr': 'Aucun résultat pour "$query"',
        'en': 'No results for "$query"',
        'it': 'Nessun risultato per "$query"',
        'es': 'Sin resultados para "$query"',
        'pt': 'Nenhum resultado para "$query"',
      });

  String get deleteConfirmTitle => _t({
        'fr': 'Confirmer la suppression',
        'en': 'Confirm deletion',
        'it': 'Conferma eliminazione',
        'es': 'Confirmar eliminación',
        'pt': 'Confirmar exclusão',
      });

  String get deleteConfirmMessage => _t({
        'fr': 'Cette action est irréversible.',
        'en': 'This action is irreversible.',
        'it': 'Questa azione è irreversibile.',
        'es': 'Esta acción es irreversible.',
        'pt': 'Esta ação é irreversível.',
      });

  String get resetConfirmTitle => _t({
        'fr': 'Confirmer la réinitialisation',
        'en': 'Confirm reset',
        'it': 'Conferma reimpostazione',
        'es': 'Confirmar restablecimiento',
        'pt': 'Confirmar redefinição',
      });

  String get resetConfirmMessage => _t({
        'fr': 'Toutes les personnalisations seront supprimées.',
        'en': 'All customizations will be deleted.',
        'it': 'Tutte le personalizzazioni verranno eliminate.',
        'es': 'Se eliminarán todas las personalizaciones.',
        'pt': 'Todas as personalizações serão excluídas.',
      });

  String get mutationsPaternal => _t({
        'fr': 'Paternelles',
        'en': 'Paternal',
        'it': 'Paterne',
        'es': 'Paternales',
        'pt': 'Paternas',
      });

  String get mutationsMaternal => _t({
        'fr': 'Maternelles',
        'en': 'Maternal',
        'it': 'Materne',
        'es': 'Maternales',
        'pt': 'Maternas',
      });

  String get mutationsTotal => _t({
        'fr': 'Total mutations',
        'en': 'Total mutations',
        'it': 'Totale mutazioni',
        'es': 'Total de mutaciones',
        'pt': 'Total de mutações',
      });

  // ─── TIPS ────────────────────────────────────────────────────────────────

  List<String> get homeTips => _locale == const Locale('fr')
      ? [
          'Enregistre les couleurs de chaque dino sauvage dans le tracker pour enrichir ta banque.',
          'Utilise le simulateur pour visualiser les combos avant de breed.',
          'Les stats anonymes du tracker permettent de suivre les max sans fiche complète.',
          'Exporte régulièrement en Excel pour sauvegarder tes données.',
          'Le mode Solid du simulateur trouve les couleurs communes à toutes les régions.',
          'Tu peux dupliquer une DinoCard pour créer une variante rapidement.',
          'Ajoute des tags pour organiser tes dinos par projet de breeding.',
          "Le journal d'espèce fusionne les stats bibliothèque + tracker automatiquement.",
          "En mode Observer du tracker, toute la palette est disponible pour enregistrer de nouvelles couleurs.",
          'Le bouton Aléatoire du simulateur ne pioche que dans tes couleurs enregistrées.',
        ]
      : _locale == const Locale('it')
          ? [
              'Registra i colori di ogni dino selvatico nel tracker per arricchire la tua banca colori.',
              'Usa il simulatore per visualizzare le combinazioni prima di allevare.',
              'Le statistiche anonime del tracker ti permettono di seguire i massimi senza scheda completa.',
              'Esporta regolarmente in Excel per salvare i tuoi dati.',
              'La modalità Solido del simulatore trova i colori comuni a tutte le regioni.',
              'Puoi duplicare una DinoCard per creare una variante rapidamente.',
              'Aggiungi tag per organizzare i tuoi dino per progetto di allevamento.',
              'Il diario delle specie unisce automaticamente le stats della libreria + tracker.',
              'In modalità Osservatore del tracker, tutta la palette è disponibile per registrare nuovi colori.',
              'Il pulsante Casuale del simulatore pesca solo dai tuoi colori registrati.',
            ]
          : _locale == const Locale('es')
              ? [
                  'Registra los colores de cada dino salvaje en el rastreador para enriquecer tu banco.',
                  'Usa el simulador para visualizar las combinaciones antes de criar.',
                  'Las estadísticas anónimas del rastreador te permiten seguir los máximos sin ficha completa.',
                  'Exporta regularmente a Excel para guardar tus datos.',
                  'El modo Sólido del simulador encuentra los colores comunes a todas las regiones.',
                  'Puedes duplicar una DinoCard para crear una variante rápidamente.',
                  'Añade etiquetas para organizar tus dinos por proyecto de cría.',
                  'El diario de especies fusiona automáticamente las estadísticas de biblioteca + rastreador.',
                  'En modo Observador del rastreador, toda la paleta está disponible para registrar nuevos colores.',
                  'El botón Aleatorio del simulador solo toma tus colores registrados.',
                ]
              : _locale == const Locale('pt')
                  ? [
                      'Registre as cores de cada dino selvagem no rastreador para enriquecer seu banco.',
                      'Use o simulador para visualizar as combinações antes de criar.',
                      'As estatísticas anônimas do rastreador permitem seguir os máximos sem ficha completa.',
                      'Exporte regularmente em Excel para salvar seus dados.',
                      'O modo Sólido do simulador encontra as cores comuns a todas as regiões.',
                      'Você pode duplicar uma DinoCard para criar uma variante rapidamente.',
                      'Adicione etiquetas para organizar seus dinos por projeto de criação.',
                      'O diário de espécies une automaticamente as stats da biblioteca + rastreador.',
                      'No modo Observador do rastreador, toda a paleta está disponível para registrar novas cores.',
                      'O botão Aleatório do simulador só usa suas cores registradas.',
                    ]
                  : [
                      'Record the colors of each wild dino in the tracker to enrich your bank.',
                      'Use the simulator to visualize combos before breeding.',
                      'Anonymous tracker stats allow you to track maximums without a full profile.',
                      'Export regularly to Excel to save your data.',
                      'The Solid mode of the simulator finds colors common to all regions.',
                      'You can duplicate a DinoCard to quickly create a variant.',
                      'Add tags to organize your dinos by breeding project.',
                      'The species journal automatically merges library + tracker stats.',
                      'In Observer mode, the full palette is available to record new colors.',
                      'The Random button only picks from your registered colors.',
                    ];

  Locale get _locale => locale;
}

// ─── Delegate ────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const List<String> _supported = ['fr', 'en', 'it', 'es', 'pt'];

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
  
}

