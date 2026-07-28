///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Flymap';
	@override late final _TranslationsCommonDe common = _TranslationsCommonDe._(_root);
	@override late final _TranslationsHomeDe home = _TranslationsHomeDe._(_root);
	@override late final _TranslationsSkyCameraDe skyCamera = _TranslationsSkyCameraDe._(_root);
	@override late final _TranslationsMediaDe media = _TranslationsMediaDe._(_root);
	@override late final _TranslationsLearnDe learn = _TranslationsLearnDe._(_root);
	@override late final _TranslationsSettingsDe settings = _TranslationsSettingsDe._(_root);
	@override late final _TranslationsSubscriptionDe subscription = _TranslationsSubscriptionDe._(_root);
	@override late final _TranslationsCreateFlightDe createFlight = _TranslationsCreateFlightDe._(_root);
	@override late final _TranslationsPreviewDe preview = _TranslationsPreviewDe._(_root);
	@override late final _TranslationsFlightDe flight = _TranslationsFlightDe._(_root);
	@override late final _TranslationsShareFlightDe shareFlight = _TranslationsShareFlightDe._(_root);
	@override late final _TranslationsShareImageDe shareImage = _TranslationsShareImageDe._(_root);
	@override late final _TranslationsFlightVideoDe flightVideo = _TranslationsFlightVideoDe._(_root);
	@override late final _TranslationsAboutDe about = _TranslationsAboutDe._(_root);
	@override late final _TranslationsOnboardingDe onboarding = _TranslationsOnboardingDe._(_root);
	@override late final _TranslationsCountriesDe countries = _TranslationsCountriesDe._(_root);
}

// Path: common
class _TranslationsCommonDe extends TranslationsCommonEn {
	_TranslationsCommonDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get kContinue => 'Weiter';
	@override String get back => 'Zurück';
	@override String get cancel => 'Abbrechen';
	@override String get ok => 'OK';
	@override String get retry => 'Erneut versuchen';
	@override String get manage => 'Verwalten';
	@override String get edit => 'Bearbeiten';
	@override String get upgrade => 'Zu Pro upgraden';
	@override String get loading => 'Wird geladen...';
	@override String get readMore => 'Mehr lesen';
	@override String get pro => 'PRO';
	@override String get search => 'Suchen';
	@override String get debug => 'Debug';
}

// Path: home
class _TranslationsHomeDe extends TranslationsHomeEn {
	_TranslationsHomeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Start';
	@override String get aboutTooltip => 'Info';
	@override String get settingsTooltip => 'Einstellungen';
	@override String get tabFlights => 'Flüge';
	@override String get tabLearn => 'Lernen';
	@override String get tabMedia => 'Medien';
	@override String get openSkyCamera => 'Sky Camera öffnen';
	@override String get loadingFlights => 'Flüge werden geladen...';
	@override String get failedToLoadFlights => 'Flüge konnten nicht geladen werden';
	@override String get newFlight => 'Neuer Flug';
	@override String get addFirstFlight => 'Ersten Flug hinzufügen';
	@override String get addNextFlight => 'Nächsten Flug hinzufügen';
	@override String get welcomeTitle => 'Willkommen bei Flymap';
	@override String get welcomeTitlePro => 'Willkommen bei Flymap Pro';
	@override String get welcomeSubtitle => 'Offline-Karten für Flüge';
	@override String get greetingOnline => 'Bereit für den nächsten Flug?';
	@override String greetingOnlineWithName({required Object name}) => 'Hallo ${name}, bereit für den nächsten Flug?';
	@override String get greetingOffline => 'Bereit, deinen Flug zu entdecken?';
	@override String greetingOfflineWithName({required Object name}) => 'Hallo ${name}, bereit, deinen Flug zu entdecken?';
	@override String get greetingInProgress => 'Dein Flug ist im Gange';
	@override String greetingInProgressWithName({required Object name}) => 'Hallo ${name}, dein Flug ist im Gange';
	@override String get totalFlights => 'Flüge insgesamt';
	@override String get storageUsed => 'Verwendeter Speicher';
	@override String get totalDistance => 'Gesamtdistanz';
	@override String upcomingFlightsCount({required Object count}) => 'Bevorstehende Flüge (${count})';
	@override String get flightInProgressTitle => 'Flug läuft';
	@override String get noFlightsTitle => 'Bereit, die Welt von oben zu entdecken?';
	@override String get noFlightsSubtitle => 'Füge deinen ersten Flug hinzu und beginne, deine nächste Reise zu entdecken.';
	@override String get noFlightsTitleNext => 'Bereit für deine nächste Reise?';
	@override String get noFlightsSubtitleNext => 'Deine abgeschlossenen Flüge findest du im Verlauf. Füge deinen nächsten Flug hinzu, um weiterzumachen.';
	@override String get flightActions => 'Flugaktionen';
	@override String get viewAll => 'Alle anzeigen';
	@override String get open => 'Öffnen';
	@override String get shareRoute => 'Route teilen';
	@override String get completeFlight => 'Flug archivieren';
	@override String get deleteFlight => 'Flug löschen';
	@override String get failedDeleteFlight => 'Flug konnte nicht gelöscht werden';
	@override String get noOfflineMap => 'Keine Offline-Karte';
	@override String placesCount({required Object count}) => '${count} Orte';
	@override String regionsCount({required Object count}) => '${count} Regionen';
	@override String offlineArticlesCount({required Object count}) => '${count} Artikel';
	@override String savedTime({required Object time}) => '${time} gespeichert';
	@override String get justNow => 'Gerade eben';
	@override String daysAgo({required Object days}) => 'vor ${days} T';
	@override String hoursAgo({required Object hours}) => 'vor ${hours} Std';
	@override String minutesAgo({required Object minutes}) => 'vor ${minutes} Min';
	@override late final _TranslationsHomeSortDe sort = _TranslationsHomeSortDe._(_root);
}

// Path: skyCamera
class _TranslationsSkyCameraDe extends TranslationsSkyCameraEn {
	_TranslationsSkyCameraDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Kamera wird geladen...';
	@override String get loadingGpsData => 'GPS-Daten werden geladen';
	@override String get zoom => 'Zoom';
	@override String get flash => 'Blitz';
	@override String get cameraUnavailable => 'Die Kamera ist gerade nicht verfügbar.';
	@override String get cameraPermissionDenied => 'Für Fotos wird Kamerazugriff benötigt.';
	@override String get captureFailed => 'Das Foto konnte gerade nicht aufgenommen werden.';
	@override String get savedMessage => 'Foto gespeichert';
	@override String get share => 'Teilen';
	@override String get noActiveFlightTitle => 'Kein aktiver Flug';
	@override String get noActiveFlightMessage => 'Sky Camera funktioniert auch ohne Flug, aber Routendetails erscheinen nur während eines aktiven Flugs.';
	@override String get telemetrySpeed => 'Geschwindigkeit';
	@override String get telemetryAltitude => 'Höhe';
	@override String get telemetryHeading => 'Kurs';
	@override String get telemetryTime => 'Zeit';
	@override String get contextCaption => 'Kontext';
	@override String get mapCaption => 'Karte';
	@override String get coordinatesCaption => 'Koordinaten';
	@override String get noValuePlaceholder => '--';
	@override String get placeholderRoute => 'LHR -> BCN';
	@override String get placeholderOriginCode => 'LHR';
	@override String get placeholderDestinationCode => 'BCN';
	@override String get placeholderContext => 'Mittelmeer';
	@override String get placeholderMap => 'Routenvorschau';
	@override String get settingsTitle => 'Kameraeinstellungen';
	@override String get recordAudio => 'Ton aufnehmen';
	@override String get recordAudioHint => 'Videos nehmen Mikrofonton auf.';
	@override String get microphonePermissionDenied => 'Mikrofonzugriff ist aus — Videos werden ohne Ton aufgenommen.';
	@override String get preparingVideo => 'Video wird vorbereitet…';
}

// Path: media
class _TranslationsMediaDe extends TranslationsMediaEn {
	_TranslationsMediaDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Medien vom Fensterplatz';
	@override String get loading => 'Medien werden geladen...';
	@override String get failedToLoad => 'Medien konnten nicht geladen werden';
	@override String get filesTab => 'Dateien';
	@override String get flightsTab => 'Flüge';
	@override String get emptyTitle => 'Willkommen bei deiner Sky Camera am Fensterplatz';
	@override String get emptySubtitle => 'Halte wunderschöne Ausblicke von deinem Fensterplatz fest und teile sie mit Flug- und GPS-Daten-Overlays.';
	@override String get emptyFlightsTitle => 'Noch keine Flugordner';
	@override String get emptyFlightsSubtitle => 'Mit gespeicherten Flügen verknüpfte Aufnahmen erscheinen hier.';
	@override String get deleteAction => 'Löschen';
	@override String get share => 'Teilen';
	@override String selectedCount({required Object count}) => '${count} ausgewählt';
	@override String get groupNoFlight => 'Kein Flugkontext';
	@override String get groupNoFlightSubtitle => 'Aufnahmen außerhalb eines aktiven Flugs';
	@override String get groupUnknownFlight => 'Flugaufnahme';
	@override String get previewTitle => 'Aufnahme';
	@override String captureCount({required Object count}) => '${count} Aufnahmen';
	@override String get deleteFolder => 'Ordner löschen';
	@override String deleteFolders({required Object count}) => '${count} Ordner löschen';
	@override String get deleteFile => 'Datei löschen';
	@override String deleteFiles({required Object count}) => '${count} Dateien löschen';
	@override String deleteFolderConfirm({required Object count}) => 'Diesen Ordner und alle ${count} Dateien löschen?';
	@override String deleteFoldersConfirm({required Object count}) => '${count} Ordner und alle enthaltenen Dateien löschen?';
	@override String get deleteFileConfirm => 'Diese Datei löschen?';
	@override String deleteFilesConfirm({required Object count}) => '${count} Dateien löschen?';
}

// Path: learn
class _TranslationsLearnDe extends TranslationsLearnEn {
	_TranslationsLearnDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get loadingCategories => 'Lernkategorien werden geladen...';
	@override String get failedToLoadCategories => 'Kategorien konnten nicht geladen werden';
	@override String get emptyCategoriesTitle => 'Noch keine Kategorien';
	@override String get emptyCategoriesSubtitle => 'Lernkategorien werden hier bald erscheinen.';
	@override String articlesCount({required Object count}) => '${count} Artikel';
	@override String get loadingArticles => 'Artikel werden geladen...';
	@override String get failedToLoadArticles => 'Artikel konnten nicht geladen werden';
	@override String get emptyArticlesTitle => 'Noch keine Artikel';
	@override String get emptyArticlesSubtitle => 'Artikel für diese Kategorie werden bald erscheinen.';
	@override String get upgradeRequiresInternet => 'Premium-Inhalte sind mit Pro verfügbar. Stelle eine Internetverbindung her, um upzugraden.';
	@override String get proListPreviewHint => 'Du kannst diese Artikeltitel jetzt ansehen. Entsperre das Lesen mit Flymap Pro.';
	@override String get failedToLoadArticle => 'Dieser Artikel konnte gerade nicht geöffnet werden.';
	@override String get quizzesTitle => 'Quizze';
	@override String get articlesTitle => 'Artikel';
	@override late final _TranslationsLearnGeoQuizDe geoQuiz = _TranslationsLearnGeoQuizDe._(_root);
}

// Path: settings
class _TranslationsSettingsDe extends TranslationsSettingsEn {
	_TranslationsSettingsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get loading => 'Einstellungen werden geladen...';
	@override String get profile => 'Profil';
	@override String get profileSubtitle => 'Name, Fluggewohnheiten, Heimatflughafen und Interessen';
	@override String profileSummaryNameHome({required Object name, required Object code}) => '${name} · ${code}';
	@override String profileSummaryHome({required Object code}) => 'Heimatflughafen: ${code}';
	@override String get profileEditHint => 'Tippe auf einen Eintrag, um deine Profildaten zu bearbeiten.';
	@override String get profileNotSet => 'Nicht festgelegt';
	@override String profileInterestsSelected({required Object count}) => '${count} ausgewählt';
	@override String get historyTitle => 'Verlauf';
	@override String get historySubtitle => 'Alle Flüge und Statistiken';
	@override String get historyLoading => 'Verlauf wird geladen...';
	@override String get historyLoadError => 'Flugverlauf konnte nicht geladen werden.';
	@override String get historyFlightsLabel => 'Flüge insgesamt';
	@override String get historyDistanceLabel => 'Gesamtdistanz';
	@override String get historyAllFlights => 'Alle Flüge';
	@override String get historyStatusUpcoming => 'Bevorstehend';
	@override String get historyStatusInProgress => 'Im Gange';
	@override String get historyStatusCompleted => 'Abgeschlossen';
	@override String historyMapChip({required Object size}) => 'Karte ${size}';
	@override String get historyNoMapChip => 'Keine Karte';
	@override String get historySortName => 'Name';
	@override String get historySortDistance => 'Distanz';
	@override String get historySortDate => 'Datum';
	@override String get historyEmpty => 'Noch keine Flüge.';
	@override String get historySearchHint => 'Nach Flughafen oder Stadt suchen';
	@override String get historyNoResults => 'Keine passenden Flüge gefunden.';
	@override String get historyDeleteOfflineData => 'Nur Karte löschen';
	@override String get appearance => 'Darstellung';
	@override String get language => 'Sprache';
	@override String get languageSubtitle => 'App-Sprache';
	@override String get languageSystem => 'System';
	@override String languageSystemFormat({required Object language}) => '${language} (System)';
	@override String get languageEnglish => 'English';
	@override String get languageSpanish => 'Español';
	@override String get languageFrench => 'Français';
	@override String get languageGerman => 'Deutsch';
	@override String get theme => 'Design';
	@override String get system => 'System';
	@override String get dark => 'Dunkel';
	@override String get light => 'Hell';
	@override String get units => 'Einheiten';
	@override String get storage => 'Speicher';
	@override String get storageTitle => 'Speicher';
	@override String get storageSubtitle => 'Heruntergeladene Karten und Speicherverbrauch';
	@override String get storageLoading => 'Speicher wird geladen...';
	@override String get storageLoadError => 'Speicherdaten konnten nicht geladen werden.';
	@override String get storageMapsLabel => 'Heruntergeladene Karten';
	@override String get storageTotalSizeLabel => 'Gesamtgröße';
	@override String get storageDownloadedMaps => 'Heruntergeladene Karten';
	@override String get storageSortName => 'Name';
	@override String get storageSortSize => 'Größe';
	@override String storageMapSize({required Object size}) => 'Größe: ${size}';
	@override String get storageEmpty => 'Noch keine Karten heruntergeladen.';
	@override String get altitude => 'Höhe';
	@override String get altitudeUnit => 'Höheneinheit';
	@override String get speed => 'Geschwindigkeit';
	@override String get speedUnit => 'Geschwindigkeitseinheit';
	@override String get temperatureUnit => 'Temperatureinheit';
	@override String get timeFormat => 'Zeitformat';
	@override String get distanceUnit => 'Distanzeinheit';
	@override String get dateFormat => 'Datumsformat';
	@override String get support => 'Support';
	@override String get about => 'Über die App';
	@override String get aboutSubtitle => 'Mehr über die App erfahren';
	@override String get privacyPolicy => 'Datenschutzrichtlinie';
	@override String get privacyPolicySubtitle => 'Unsere Datenschutzrichtlinie lesen';
	@override String get termsOfService => 'Nutzungsbedingungen';
	@override String get termsOfServiceSubtitle => 'Unsere Nutzungsbedingungen lesen';
	@override String get flymapProActivated => 'Flymap Pro aktiviert.';
	@override String get upgradeCancelled => 'Upgrade abgebrochen.';
	@override String get noPaywall => 'Derzeit keine Bezahlschranke verfügbar.';
	@override String get failedOpenPaywall => 'Paywall konnte nicht geöffnet werden.';
	@override String couldNotOpenUrl({required Object url}) => '${url} konnte nicht geöffnet werden';
	@override String get rateUs => 'Bewerten';
	@override String get rateUsSubtitle => 'Hinterlasse eine Bewertung im Store';
	@override String get leaveFeedback => 'Feedback senden';
	@override String get leaveFeedbackSubtitle => 'Teile deine Gedanken, damit wir uns verbessern können';
	@override String get couldNotOpenStorePage => 'Store-Seite konnte nicht geöffnet werden';
	@override String get rateDialogTitle => 'Gefällt dir die App?';
	@override String get rateDialogBody => 'Wir arbeiten hart daran, jeden Flug angenehmer zu machen, und dein Feedback hilft uns wirklich weiter.';
	@override String get rateDialogYes => 'Ja';
	@override String get rateDialogNo => 'Nein';
	@override String get advocacyDialogTitle => 'Schön, dass dir Flymap gefällt';
	@override String get advocacyDialogBody => 'Hilf anderen Reisenden, Flymap zu entdecken.';
	@override String get advocacyDialogShare => 'Mit Freunden teilen';
	@override String get advocacyDialogRate => 'Flymap bewerten';
	@override String get advocacyDialogNotNow => 'Nicht jetzt';
	@override String get feedbackTitle => 'Feedback senden';
	@override String get feedbackBody => 'Hilf uns, Flymap besser zu machen';
	@override String get feedbackCategoryTitle => 'Feedback-Typ';
	@override String get feedbackCategoryGeneral => 'Allgemein';
	@override String get feedbackCategoryFeatureRequest => 'Funktionswunsch';
	@override String get feedbackCategoryBugReport => 'Fehlerbericht';
	@override String get feedbackHint => 'Teile dein Feedback...';
	@override String get feedbackEmailHint => 'E-Mail (optional)';
	@override String get feedbackEmailInvalid => 'Bitte gib eine gültige E-Mail ein oder lasse das Feld leer.';
	@override String get feedbackSend => 'Senden';
	@override String get feedbackThanks => 'Danke für dein Feedback!';
	@override String get feedbackSendFailed => 'Feedback konnte nicht gesendet werden. Bitte versuche es erneut.';
	@override String get proBannerTitle => 'Flymap Pro';
	@override String get proBannerTitleActive => 'Flymap Pro aktiv';
	@override String get proBannerSubtitleActive => 'Detaillierter Kartenmodus und vollständige Offline-Artikelpakete freigeschaltet.';
	@override String get proBannerSubtitleFree => 'Schalte detaillierte Karten und vollständige Offline-Artikelpakete frei';
	@override String get proBannerBadgeActive => 'PRO AKTIV';
}

// Path: subscription
class _TranslationsSubscriptionDe extends TranslationsSubscriptionEn {
	_TranslationsSubscriptionDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Abonnement';
	@override String get contactSupport => 'Support kontaktieren';
	@override String get cardTitle => 'Flymap Pro';
	@override String get periodTitle => 'Abonnementzeitraum';
	@override String get renewsOrExpires => 'Verlängert sich oder läuft ab';
	@override String get noExpiration => 'Kein Ablaufdatum';
	@override String get lastChecked => 'Zuletzt geprüft';
	@override String get flightUnlockSheetTitle => 'Pro-Funktionen freischalten';
	@override String get flightUnlockOptionTitle => 'Einmalkauf';
	@override String get flightUnlockOptionBody => 'Schalte Pro für einen einzelnen Flug frei';
	@override String get flightUnlockAction => 'Für einen Flug kaufen';
	@override String get flightUnlockUseAction => 'Für einen Flug verwenden';
	@override String get flightUnlockPriceLoading => 'Preis wird geladen...';
	@override String get flightUnlockProOptionTitle => 'Flymap Pro Abonnement';
	@override String flightUnlockAvailableCount({required Object count}) => '${count} Flug-Freischaltungen verfügbar';
	@override String get flightUnlockProOptionBody => 'Schalte Pro für unbegrenzt viele Flüge frei';
	@override String get flightUnlockProAction => 'Pro-Tarife ansehen';
	@override String get flightUnlockUnavailable => 'Die Flug-Freischaltung ist derzeit nicht verfügbar.';
	@override String get flightUnlockPurchaseCancelled => 'Kauf der Flug-Freischaltung abgebrochen.';
	@override String get flightUnlockPurchaseFailed => 'Kauf der Flug-Freischaltung fehlgeschlagen. Bitte versuche es erneut.';
	@override String get proFeaturesTitle => 'Was Flymap Pro freischaltet';
	@override String get proFeatureRoutesTitle => 'Präzise Routenvorschauen';
	@override String get proFeatureMapsTitle => 'Detailliertere Offline-Karten';
	@override String get proFeatureTimelineTitle => 'Vollständige Routen-Timeline';
	@override String get proFeaturePoiTitle => '10-mal mehr Orte auf der Route';
	@override String get proFeatureArticlesTitle => 'Vollständige Offline-Artikelpakete';
	@override String get checkingStatus => 'Dein Abonnementstatus wird geprüft...';
	@override String get freePlan => 'Du nutzt den Gratis-Tarif.';
	@override String get active => 'Aktiv';
	@override String get notActive => 'Nicht aktiv';
	@override String get unknown => 'Unbekannt';
	@override String get manageSubscription => 'Abonnement verwalten';
	@override String get restorePurchases => 'Käufe wiederherstellen';
	@override String get upgradeToPro => 'Zu Pro upgraden';
	@override String get restoreNoSubscription => 'Kein aktives Abonnement gefunden.';
	@override String get supportEmailSubject => 'Flymap Abonnement-Support';
	@override String get couldNotOpenEmailApp => 'E-Mail-App konnte nicht geöffnet werden';
	@override String get couldNotOpenSubscriptionSettings => 'Abonnement-Einstellungen konnten nicht geöffnet werden';
	@override String get proRestored => 'Flymap Pro wiederhergestellt.';
	@override String get failedOpenPaywall => 'Paywall konnte nicht geöffnet werden.';
	@override String get serviceUnavailable => 'Der Abonnementdienst ist vorübergehend nicht verfügbar.';
}

// Path: createFlight
class _TranslationsCreateFlightDe extends TranslationsCreateFlightEn {
	_TranslationsCreateFlightDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsCreateFlightStepsDe steps = _TranslationsCreateFlightStepsDe._(_root);
	@override late final _TranslationsCreateFlightWeatherDe weather = _TranslationsCreateFlightWeatherDe._(_root);
	@override late final _TranslationsCreateFlightRouteTypeSelectorDe routeTypeSelector = _TranslationsCreateFlightRouteTypeSelectorDe._(_root);
	@override late final _TranslationsCreateFlightProAccessDe proAccess = _TranslationsCreateFlightProAccessDe._(_root);
	@override late final _TranslationsCreateFlightTravelDateDe travelDate = _TranslationsCreateFlightTravelDateDe._(_root);
	@override late final _TranslationsCreateFlightFlightNumberSearchDe flightNumberSearch = _TranslationsCreateFlightFlightNumberSearchDe._(_root);
	@override late final _TranslationsCreateFlightRealRouteAirportSearchDe realRouteAirportSearch = _TranslationsCreateFlightRealRouteAirportSearchDe._(_root);
	@override late final _TranslationsCreateFlightSearchDe search = _TranslationsCreateFlightSearchDe._(_root);
	@override late final _TranslationsCreateFlightMapPreviewDe mapPreview = _TranslationsCreateFlightMapPreviewDe._(_root);
	@override late final _TranslationsCreateFlightOverviewDe overview = _TranslationsCreateFlightOverviewDe._(_root);
	@override late final _TranslationsCreateFlightWikipediaDe wikipedia = _TranslationsCreateFlightWikipediaDe._(_root);
	@override late final _TranslationsCreateFlightDownloadingDe downloading = _TranslationsCreateFlightDownloadingDe._(_root);
	@override late final _TranslationsCreateFlightErrorsDe errors = _TranslationsCreateFlightErrorsDe._(_root);
	@override late final _TranslationsCreateFlightPaywallDe paywall = _TranslationsCreateFlightPaywallDe._(_root);
	@override late final _TranslationsCreateFlightRealRouteChoiceDe realRouteChoice = _TranslationsCreateFlightRealRouteChoiceDe._(_root);
}

// Path: preview
class _TranslationsPreviewDe extends TranslationsPreviewEn {
	_TranslationsPreviewDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get calculatingRoute => 'Flugroute wird berechnet...';
	@override String get errorTitle => 'Fehler';
	@override String get errorSomethingWrong => 'Etwas ist schiefgelaufen';
	@override String get tryAgain => 'Erneut versuchen';
	@override String get downloadCongratsTitle => 'Glückwunsch! Alles ist bereit.';
	@override String get offlineSavedDetail => 'Karte und ausgewählte Flugdaten wurden für die Offline-Nutzung während deines Flugs gespeichert.';
	@override String get downloadCompletedTitle => 'Download abgeschlossen';
	@override String get shareFlightCard => 'Zeig deinen großartigen Flug';
	@override String get shareVideo => 'Flugvideo teilen';
	@override String get shareVideoNewBadge => 'NEU';
	@override String get share => 'Flugkarte teilen';
	@override String get home => 'Start';
	@override String get navigatingHome => 'Zur Startseite...';
	@override String get downloadingMapTitle => 'Ressourcen werden heruntergeladen';
	@override String get cancelDownload => 'Download abbrechen';
	@override String get download => 'Herunterladen';
	@override String flightRoute({required Object distance}) => 'Flugroute (~ ${distance})';
}

// Path: flight
class _TranslationsFlightDe extends TranslationsFlightEn {
	_TranslationsFlightDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tabMap => 'Karte';
	@override String get tabDashboard => 'Dashboard';
	@override String get tabRoute => 'Route';
	@override String get tabRead => 'Lesen';
	@override String get tabCamera => 'Kamera';
	@override String get tabInfo => 'Info';
	@override String get completeDialogTitle => 'Flug abschließen?';
	@override String get completeDialogBody => 'Damit wird dein Flug als abgeschlossen markiert.';
	@override String get completeDialogDeleteOffline => 'Karte und Offline-Artikel löschen';
	@override String get completeDialogConfirm => 'Abschließen';
	@override String get deleteDialogTitle => 'Bist du sicher?';
	@override String deleteDialogMessage({required Object size}) => 'Dadurch wird dieser Flug dauerhaft gelöscht, einschließlich Offline-Karte und gespeicherter Offline-Artikel.\n\nWiedergewonnener Speicherplatz: ${size}.';
	@override String get yes => 'Ja';
	@override String get shareRoute => 'Route teilen';
	@override String get copyRoute => 'Route kopieren';
	@override String get deleteFlight => 'Flug löschen';
	@override String get routeSummaryCopied => 'Routenzusammenfassung kopiert';
	@override String get deleted => 'Flug gelöscht';
	@override String deleteError({required Object error}) => 'Fehler beim Löschen des Flugs: ${error}';
	@override late final _TranslationsFlightMapDe map = _TranslationsFlightMapDe._(_root);
	@override late final _TranslationsFlightDashboardDe dashboard = _TranslationsFlightDashboardDe._(_root);
	@override late final _TranslationsFlightUpcomingDe upcoming = _TranslationsFlightUpcomingDe._(_root);
	@override late final _TranslationsFlightInfoDe info = _TranslationsFlightInfoDe._(_root);
	@override late final _TranslationsFlightRouteDe route = _TranslationsFlightRouteDe._(_root);
}

// Path: shareFlight
class _TranslationsShareFlightDe extends TranslationsShareFlightEn {
	_TranslationsShareFlightDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flug teilen';
	@override String get preparingMap => 'Vorschaukarte wird vorbereitet...';
	@override String get preparingScreenshot => 'Screenshot wird vorbereitet...';
	@override String get share => 'Teilen';
	@override String get route => 'Route';
	@override String get offlineMapMissing => 'Offline-Karte fehlt. Online-Stil wird verwendet.';
	@override String get offlineStyleFailed => 'Offline-Stil konnte nicht geladen werden. Online-Stil wird verwendet.';
	@override String get captureFailed => 'Routen-Screenshot konnte nicht erstellt werden';
	@override String get shareFailed => 'Routen-Screenshot konnte nicht geteilt werden';
	@override String shareText({required Object from, required Object to}) => 'Flugroute ${from}-${to}';
	@override String get watermark => 'Flymap';
	@override String get flightDistance => 'Flugdistanz';
	@override String distanceKm({required Object distance}) => '${distance} km';
}

// Path: shareImage
class _TranslationsShareImageDe extends TranslationsShareImageEn {
	_TranslationsShareImageDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flug teilen';
	@override String get generating => 'Deine Flugkarte wird erstellt...';
	@override String get share => 'Teilen';
	@override String get sharing => 'Wird geteilt...';
	@override String get retry => 'Erneut versuchen';
	@override String get error => 'Flugkarte konnte nicht erstellt werden';
	@override String get tagline => 'Jeder Flug ist eine Entdeckung';
	@override String get brand => 'Flymap';
	@override String get exploreYourFlight => 'Entdecke deinen Flug';
	@override String get countrySingle => '1 Land';
	@override String countries({required Object count}) => '${count} Länder';
	@override String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) auf Flymap ✈️';
	@override String get unknownCity => 'Unbekannt';
	@override String get durationUnavailable => '--';
	@override String durationMinutes({required Object minutes}) => '${minutes} Min';
	@override String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} Std ${minutes} Min';
}

// Path: flightVideo
class _TranslationsFlightVideoDe extends TranslationsFlightVideoEn {
	_TranslationsFlightVideoDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flugvideo';
	@override String get preparing => 'Karte wird vorbereitet...';
	@override String get rendering => 'Dein Video wird erstellt...';
	@override String get export => 'Video speichern';
	@override String get savedToGallery => 'In deiner Galerie gespeichert';
	@override String get saveSkipped => 'Speichern in der Galerie nicht möglich — du kannst es trotzdem teilen';
	@override String get share => 'Teilen';
	@override String get sharing => 'Wird geteilt...';
	@override String get retry => 'Erneut versuchen';
	@override String get errorNetwork => 'Kartenbilder konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';
	@override String get errorGeneric => 'Flugvideo konnte nicht erstellt werden';
	@override String get errorOfflineTitle => 'Du bist offline';
	@override String get errorOffline => 'Flugvideos laden aktuelle Kartenbilder und brauchen daher eine Internetverbindung. Deaktiviere den Flugmodus oder verbinde dich neu und versuche es erneut.';
	@override String get offlineStyleChange => 'Für einen Wechsel des Kartenstils ist eine Verbindung nötig.';
	@override String get madeWith => 'Erstellt mit Flymap';
	@override String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) auf Flymap ✈️';
	@override String get removeWatermark => 'Wasserzeichen entfernen';
	@override String get styleSatellite => 'Satellit';
	@override String get styleDefault => 'Standard';
	@override String get videoSettings => 'Video-Einstellungen';
	@override String get mapStyle => 'Kartenstil';
	@override String get mysteryDestination => 'Geheimes Ziel';
	@override String get mysteryDestinationHint => '"?" anzeigen, bis das Flugzeug landet';
	@override String get showPins => 'Länder-Pins';
	@override String get showPinsHint => 'Setzt eine Markierung, wenn das Flugzeug ein Land überquert';
	@override String get showEndCard => 'Übersichtskarte';
	@override String get showEndCardHint => 'Übersichtskarte am Ende anzeigen';
	@override String get styleShine => 'Lè Shine';
	@override String get applySettings => 'Änderungen anwenden';
	@override String get applying => 'Änderungen werden angewendet...';
	@override String get avatarTitle => 'Dein Avatar';
	@override String get avatarHint => 'Fliege deine Route mit deinem eigenen Foto';
	@override String get avatarSetupTitle => 'Dein Avatar';
	@override String get avatarPick => 'Foto wählen';
	@override String get avatarChange => 'Foto ändern';
	@override String get avatarNameLabel => 'Name oder @Handle';
	@override String get avatarNameHint => 'Optional – auf der Zusammenfassungskarte sichtbar';
	@override String get avatarSave => 'Avatar speichern';
	@override String get mysteryTitle => 'Rate, wohin ich fliege? ✈️';
	@override String get avatarCardTagline => 'Meine Flugkarte';
}

// Path: about
class _TranslationsAboutDe extends TranslationsAboutEn {
	_TranslationsAboutDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Über Flymap';
	@override String get tagline => 'Mach aus jedem Flug ein Fenster zur Welt.';
	@override String get chipCuriosity => 'Neugier';
	@override String get chipGeography => 'Geografie';
	@override String get chipAwareness => 'Bewusstsein';
	@override String get missionTitle => 'Warum Flymap';
	@override String get missionText => 'Wir fliegen über Ozeane, Berge und ganze Länder, ohne es je zu wissen. Flymap holt das Staunen zurück.';
	@override String get valuesTitle => 'Wofür wir stehen';
	@override String get valueCuriosityTitle => 'Neugier';
	@override String get valueCuriosityText => 'Wisse immer, was unter dir liegt.';
	@override String get valueGeographyTitle => 'Geografie';
	@override String get valueGeographyText => 'Die Welt wird zum lebendigen Atlas.';
	@override String get valueAwarenessTitle => 'Bewusstsein';
	@override String get valueAwarenessText => 'Verbinde dich wieder mit der Reise.';
	@override String get valueOfflineTitle => 'Offline & privat';
	@override String get valueOfflineText => 'Auf deinem Gerät. Nichts wird getrackt.';
	@override String get closingTitle => 'Sieh die Welt mit neuen Augen';
	@override String get closingText => 'Danke, dass du sie mit uns erkundest.';
}

// Path: onboarding
class _TranslationsOnboardingDe extends TranslationsOnboardingEn {
	_TranslationsOnboardingDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Überspringen';
	@override String get letsStart => 'Los geht’s';
	@override String get welcomeTitle => 'Entdecke, was unter dir liegt';
	@override String get welcomeSubtitle => 'zeigt dir Offline-Karten und interessante Orte entlang deines Flugs';
	@override String get nameTitle => 'Wähle einen Benutzernamen';
	@override String get nameSubtitle => 'Mache Entdeckungen persönlicher. Du kannst ihn jederzeit ändern.';
	@override String get nameHint => 'Dein Name';
	@override String get nameExample => 'Alex';
	@override String get frequencyTitle => 'Wie oft fliegst du?';
	@override String get frequencySubtitle => 'Flymap personalisiert dein Erlebnis und macht Vorschläge relevanter';
	@override String get frequencyFirstFlight => 'Das ist mein erster Flug';
	@override String get frequencyFewPerYear => 'Ein paar Mal pro Jahr';
	@override String get frequencyMonthly => 'Ungefähr monatlich';
	@override String get frequencyFrequent => 'Sehr oft';
	@override String get homeAirportTitle => 'Lege deinen Heimatflughafen fest';
	@override String get homeAirportSubtitle => 'Schnellere Flugplanung. Du kannst ihn jederzeit ändern.';
	@override String get homeAirportHint => 'Heimatflughafen suchen';
	@override String get popularAirports => 'Beliebte Flughäfen';
	@override String get removeHomeAirport => 'Heimatflughafen entfernen';
	@override String get noHomeAirportFound => 'Für diese Suche wurden keine Flughäfen gefunden.';
	@override String get interestsTitle => 'Welche Orte möchtest du häufiger auf deiner Karte sehen?';
	@override String get interestsSubtitle => 'Wähle bis zu 3 Themen, um relevantere Orte und Geschichten entlang deines Flugs zu sehen.';
	@override String get interestsHelper => 'Wähle bis zu 3 Themen.';
	@override String interestsSelected({required Object count, required Object max}) => '${count} von ${max} ausgewählt';
	@override String get interestMountains => 'Berge & Grate';
	@override String get interestVolcanoes => 'Vulkane & Geologie';
	@override String get interestRegions => 'Städte & Regionen';
	@override String get interestIslands => 'Inseln & Küstenlinien';
	@override String get interestNationalParks => 'Nationalparks & Reservate';
	@override String get interestRivers => 'Flüsse & Seen';
	@override String get planFirstFlight => 'Meinen ersten Flug planen';
	@override String get failedLoadProfile => 'Dein Profil konnte nicht geladen werden.';
	@override late final _TranslationsOnboardingPayoffDe payoff = _TranslationsOnboardingPayoffDe._(_root);
}

// Path: countries
class _TranslationsCountriesDe extends TranslationsCountriesEn {
	_TranslationsCountriesDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get AE => 'Vereinigte Arabische Emirate';
	@override String get AF => 'Afghanistan';
	@override String get AG => 'Antigua und Barbuda';
	@override String get AL => 'Albanien';
	@override String get AM => 'Armenien';
	@override String get AO => 'Angola';
	@override String get AR => 'Argentinien';
	@override String get AT => 'Österreich';
	@override String get AU => 'Australien';
	@override String get AZ => 'Aserbaidschan';
	@override String get BA => 'Bosnien und Herzegowina';
	@override String get BB => 'Barbados';
	@override String get BD => 'Bangladesch';
	@override String get BE => 'Belgien';
	@override String get BF => 'Burkina Faso';
	@override String get BG => 'Bulgarien';
	@override String get BH => 'Bahrain';
	@override String get BI => 'Burundi';
	@override String get BJ => 'Benin';
	@override String get BN => 'Brunei Darussalam';
	@override String get BO => 'Bolivien';
	@override String get BR => 'Brasilien';
	@override String get BS => 'Bahamas';
	@override String get BT => 'Bhutan';
	@override String get BW => 'Botswana';
	@override String get BY => 'Belarus';
	@override String get BZ => 'Belize';
	@override String get CA => 'Kanada';
	@override String get CD => 'Kongo, Demokratische Republik';
	@override String get CF => 'Zentralafrikanische Republik';
	@override String get CG => 'Kongo';
	@override String get CH => 'Schweiz';
	@override String get CI => 'Côte d\'Ivoire';
	@override String get CL => 'Chile';
	@override String get CM => 'Kamerun';
	@override String get CN => 'China';
	@override String get CO => 'Kolumbien';
	@override String get CR => 'Costa Rica';
	@override String get CU => 'Kuba';
	@override String get CV => 'Kap Verde';
	@override String get CY => 'Zypern';
	@override String get CZ => 'Tschechien';
	@override String get DE => 'Deutschland';
	@override String get DJ => 'Dschibuti';
	@override String get DK => 'Dänemark';
	@override String get DO => 'Dominikanische Republik';
	@override String get DZ => 'Algerien';
	@override String get EC => 'Ecuador';
	@override String get EE => 'Estland';
	@override String get EG => 'Ägypten';
	@override String get EH => 'Westsahara';
	@override String get ER => 'Eritrea';
	@override String get ES => 'Spanien';
	@override String get ET => 'Äthiopien';
	@override String get FI => 'Finnland';
	@override String get FJ => 'Fidschi';
	@override String get FR => 'Frankreich';
	@override String get GA => 'Gabun';
	@override String get GB => 'Vereinigtes Königreich';
	@override String get GE => 'Georgien';
	@override String get GF => 'Französisch-Guayana';
	@override String get GH => 'Ghana';
	@override String get GM => 'Gambia';
	@override String get GN => 'Guinea';
	@override String get GP => 'Guadeloupe';
	@override String get GQ => 'Äquatorialguinea';
	@override String get GR => 'Griechenland';
	@override String get GT => 'Guatemala';
	@override String get GW => 'Guinea-Bissau';
	@override String get GY => 'Guyana';
	@override String get HK => 'Hongkong, China';
	@override String get HN => 'Honduras';
	@override String get HR => 'Kroatien';
	@override String get HT => 'Haiti';
	@override String get HU => 'Ungarn';
	@override String get ID => 'Indonesien';
	@override String get IE => 'Irland';
	@override String get IL => 'Israel';
	@override String get IN => 'Indien';
	@override String get IQ => 'Irak';
	@override String get IR => 'Iran';
	@override String get IS => 'Island';
	@override String get IT => 'Italien';
	@override String get JM => 'Jamaika';
	@override String get JO => 'Jordanien';
	@override String get JP => 'Japan';
	@override String get KE => 'Kenia';
	@override String get KG => 'Kirgisistan';
	@override String get KH => 'Kambodscha';
	@override String get KM => 'Komoren';
	@override String get KP => 'Nordkorea';
	@override String get KR => 'Südkorea';
	@override String get KW => 'Kuwait';
	@override String get KZ => 'Kasachstan';
	@override String get LA => 'Laos';
	@override String get LB => 'Libanon';
	@override String get LK => 'Sri Lanka';
	@override String get LR => 'Liberia';
	@override String get LS => 'Lesotho';
	@override String get LT => 'Litauen';
	@override String get LU => 'Luxemburg';
	@override String get LV => 'Lettland';
	@override String get LY => 'Libyen';
	@override String get MA => 'Marokko';
	@override String get MD => 'Moldau';
	@override String get ME => 'Montenegro';
	@override String get MG => 'Madagaskar';
	@override String get MK => 'Nordmazedonien';
	@override String get ML => 'Mali';
	@override String get MM => 'Myanmar';
	@override String get MN => 'Mongolei';
	@override String get MO => 'Macao, China';
	@override String get MQ => 'Martinique';
	@override String get MR => 'Mauretanien';
	@override String get MU => 'Mauritius';
	@override String get MV => 'Malediven';
	@override String get MW => 'Malawi';
	@override String get MT => 'Malta';
	@override String get MX => 'Mexiko';
	@override String get MY => 'Malaysia';
	@override String get MZ => 'Mosambik';
	@override String get NA => 'Namibia';
	@override String get NC => 'Neukaledonien';
	@override String get NE => 'Niger';
	@override String get NG => 'Nigeria';
	@override String get NI => 'Nicaragua';
	@override String get NL => 'Niederlande';
	@override String get NO => 'Norwegen';
	@override String get NP => 'Nepal';
	@override String get NZ => 'Neuseeland';
	@override String get OM => 'Oman';
	@override String get PA => 'Panama';
	@override String get PE => 'Peru';
	@override String get PG => 'Papua-Neuguinea';
	@override String get PH => 'Philippinen';
	@override String get PK => 'Pakistan';
	@override String get PL => 'Polen';
	@override String get PR => 'Puerto Rico';
	@override String get PS => 'Westjordanland und Gazastreifen';
	@override String get PT => 'Portugal';
	@override String get PY => 'Paraguay';
	@override String get QA => 'Katar';
	@override String get RE => 'Réunion';
	@override String get RO => 'Rumänien';
	@override String get RS => 'Serbien';
	@override String get RU => 'Russische Föderation';
	@override String get RW => 'Ruanda';
	@override String get SA => 'Saudi-Arabien';
	@override String get SB => 'Salomonen';
	@override String get SD => 'Sudan';
	@override String get SE => 'Schweden';
	@override String get SG => 'Singapur';
	@override String get SI => 'Slowenien';
	@override String get SK => 'Slowakei';
	@override String get SL => 'Sierra Leone';
	@override String get SN => 'Senegal';
	@override String get SO => 'Somalia';
	@override String get SR => 'Suriname';
	@override String get SS => 'Südsudan';
	@override String get ST => 'São Tomé und Príncipe';
	@override String get SV => 'El Salvador';
	@override String get SY => 'Syrien';
	@override String get SZ => 'Eswatini';
	@override String get TD => 'Tschad';
	@override String get TG => 'Togo';
	@override String get TH => 'Thailand';
	@override String get TJ => 'Tadschikistan';
	@override String get TL => 'Timor-Leste';
	@override String get TM => 'Turkmenistan';
	@override String get TN => 'Tunesien';
	@override String get TR => 'Türkei';
	@override String get TT => 'Trinidad und Tobago';
	@override String get TW => 'Taiwan, China';
	@override String get TZ => 'Tansania';
	@override String get UA => 'Ukraine';
	@override String get UG => 'Uganda';
	@override String get US => 'Vereinigte Staaten';
	@override String get UY => 'Uruguay';
	@override String get UZ => 'Usbekistan';
	@override String get VE => 'Venezuela';
	@override String get VI => 'Amerikanische Jungferninseln';
	@override String get VN => 'Vietnam';
	@override String get YE => 'Jemen';
	@override String get ZA => 'Südafrika';
	@override String get ZM => 'Sambia';
	@override String get ZW => 'Simbabwe';
}

// Path: home.sort
class _TranslationsHomeSortDe extends TranslationsHomeSortEn {
	_TranslationsHomeSortDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get mostRecent => 'Neueste';
	@override String get longest => 'Längste';
	@override String get alphabetical => 'A-Z';
}

// Path: learn.geoQuiz
class _TranslationsLearnGeoQuizDe extends TranslationsLearnGeoQuizEn {
	_TranslationsLearnGeoQuizDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Geo Quiz';
	@override String get geographyTitle => 'Geografie';
	@override String get geographySubtitle => 'Meere, Gebirge, Seen, Inseln und mehr';
	@override String get countriesTitle => 'Länder auf der Karte';
	@override String get subtitle => 'Errate das Land anhand seines Umrisses';
	@override String get loading => 'Geo Quiz wird geladen...';
	@override String get failedToLoad => 'Quizze konnten nicht geladen werden';
	@override String get failedToLoadQuiz => 'Quiz konnte nicht geladen werden';
	@override String get emptyTitle => 'Noch keine Quizze';
	@override String get emptySubtitle => 'Geo-Quizze werden hier bald erscheinen.';
	@override String get countryHint => 'Regionsname...';
	@override String progressCount({required Object solved, required Object total}) => '${solved} / ${total}';
	@override String nextCount({required Object next, required Object total}) => '${next} von ${total}';
	@override String correctCount({required Object count}) => '${count} richtig';
	@override String get reset => 'Fortschritt zurücksetzen';
	@override String get mapPlaceholder => 'Kartendaten werden als Nächstes hinzugefügt';
	@override String get newBadge => 'NEU';
	@override String get correct => 'Richtig';
	@override String get wrong => 'Falsch';
	@override String get hintTitle => 'Hinweis';
	@override String get hintSubtitle => 'Tippe auf einen Buchstaben, um ihn aufzudecken';
	@override String get next => 'Weiter';
	@override String get pause => 'Pausieren';
	@override String get resume => 'Fortsetzen';
	@override String get finish => 'Fertig';
	@override String get completeTitle => 'Quiz abgeschlossen';
	@override String completeMessage({required Object total, required Object quiz}) => 'Du hast alle ${total} Länder in ${quiz} gefunden.';
	@override String get backToQuizzes => 'Zurück zu den Quizzen';
	@override String get playAgain => 'Erneut spielen';
	@override String get progressReady => 'Bereit zum Spielen';
	@override String progressFinished({required Object count}) => '${count} abgeschlossen';
	@override String progressInProgress({required Object count}) => '${count} in Arbeit';
	@override String get progressAllCompleted => 'Alle abgeschlossen';
	@override String get quizCountriesAfricaTitle => 'Afrika';
	@override String get quizCountriesEuropeTitle => 'Europa';
	@override String get quizCountriesAsiaTitle => 'Asien';
	@override String get quizCountriesNorthAmericaTitle => 'Nordamerika';
	@override String get quizCountriesSouthAmericaTitle => 'Südamerika';
	@override String get quizCountriesOceaniaTitle => 'Ozeanien';
	@override String get quizCountriesAllTitle => 'Alle Länder';
	@override String get quizCountriesSubtitle => 'Länder';
	@override String get quizCountriesAllSubtitle => 'Welt';
	@override String get quizGeographySeasTitle => 'Meere';
	@override String get quizGeographyMountainRangesTitle => 'Gebirge';
	@override String get quizGeographyLakesTitle => 'Seen';
	@override String get quizGeographyIslandsTitle => 'Inseln';
	@override String get quizGeographyOtherTitle => 'Weitere';
	@override String get quizGeographyOtherSubtitle => 'Buchten, Meerengen, Golfe, Wüsten und mehr';
	@override String get descriptionUnavailable => 'Beschreibung ist noch nicht verfügbar.';
}

// Path: createFlight.steps
class _TranslationsCreateFlightStepsDe extends TranslationsCreateFlightStepsEn {
	_TranslationsCreateFlightStepsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get departureTitle => 'Abflughafen wählen';
	@override String get arrivalTitle => 'Zielflughafen wählen';
	@override String get routeNotSupportedTitle => 'Route wird nicht unterstützt';
	@override String get mapPreviewTitle => 'Kartenvorschau';
	@override String get overviewTitle => 'Routenübersicht';
	@override String get wikipediaTitle => 'Wikipedia-Artikel';
	@override String get weatherTitle => 'Flugwetter';
}

// Path: createFlight.weather
class _TranslationsCreateFlightWeatherDe extends TranslationsCreateFlightWeatherEn {
	_TranslationsCreateFlightWeatherDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wirst du den Boden sehen?';
	@override String get loading => 'Wir prüfen den Himmel entlang deiner Route…';
	@override String get loadFailed => 'Die Vorhersage konnte gerade nicht geladen werden. Versuche es erneut oder fahre ohne sie fort.';
	@override String get estimatedBadge => 'Zeiten geschätzt';
	@override String get departureLabel => 'Abflug';
	@override String get arrivalLabel => 'Ankunft';
	@override String get tomorrow => 'morgen';
	@override String get localTimesHint => 'Zeiten sind Ortszeit des jeweiligen Flughafens.';
	@override String get verdictClearTitle => 'Klare Sicht';
	@override String get verdictClearBody => 'Der Fensterplatz lohnt sich — der Boden sollte fast den ganzen Flug sichtbar sein.';
	@override String get verdictPatchyTitle => 'Aufgelockerte Bewölkung';
	@override String get verdictPatchyBody => 'Die Sicht kommt und geht zwischen den Wolken.';
	@override String get verdictCarpetTitle => 'Wolkenteppich unter dir';
	@override String get verdictCarpetBody => 'Ein weißes Wolkenmeer unter dir — wunderschön, aber der Boden bleibt meist verborgen.';
	@override String get verdictOvercastTitle => 'Bedeckter Himmel';
	@override String get verdictOvercastBody => 'Die beste Sicht gibt es bei Start und Landung.';
	@override String get expectClear => '☀️ Klar';
	@override String get expectPatchy => '⛅ Aufgelockert';
	@override String get expectCarpet => '☁️ Wolkenteppich';
	@override String get expectOvercast => '🌫 Bedeckt';
	@override String get segmentAfterTakeoff => 'nach dem Start';
	@override String get segmentMidFlight => 'in der Flugmitte';
	@override String get segmentBeforeLanding => 'vor der Landung';
	@override String segmentOver({required Object name}) => 'über ${name}';
	@override String get proTeaserTitle => 'Wolkenkarte entlang deiner Route';
	@override String get proTeaserBody => 'Sieh, wo die Wolken sein werden — und schau deinem Flugzeug zu, wie es die ganze Route darüber fliegt.';
	@override String get attribution => 'Wetterdaten: MET Norwegen';
	@override String get hedge => 'Vorhersagen werden näher am Abflug genauer.';
	@override String forecastFor({required Object date}) => 'Vorhersage für ${date}';
	@override String updatedAt({required Object time}) => 'Aktualisiert ${time}';
}

// Path: createFlight.routeTypeSelector
class _TranslationsCreateFlightRouteTypeSelectorDe extends TranslationsCreateFlightRouteTypeSelectorEn {
	_TranslationsCreateFlightRouteTypeSelectorDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Neuer Flug';
	@override String get basicTitle => 'Ungefähre Route';
	@override String get basicSubtitle => 'Von Flughäfen';
	@override String get basicDescription => 'Funktioniert gut für Kurz- und viele Mittelstreckenflüge.';
	@override String get proTitle => 'Echte Route';
	@override String get proSubtitle => 'Von jüngsten Flügen';
	@override String get proDescription => 'Basiert auf der zuletzt aufgezeichneten Route desselben Flugs.';
	@override String get mostAccurate => 'Am genauesten';
}

// Path: createFlight.proAccess
class _TranslationsCreateFlightProAccessDe extends TranslationsCreateFlightProAccessEn {
	_TranslationsCreateFlightProAccessDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get subscriber => 'Flymap Pro';
	@override String get subscriberBody => 'Dieser Flug hat über dein Flymap Pro Abonnement vollen Pro-Zugriff.';
	@override String get unlockedFlight => 'Dieser Flug ist freigeschaltet';
	@override String get unlockedFlightBody => 'Alle Pro-Funktionen sind für diesen Flug aktiviert.';
	@override String get tooltip => 'Infos zum Pro-Zugriff';
}

// Path: createFlight.travelDate
class _TranslationsCreateFlightTravelDateDe extends TranslationsCreateFlightTravelDateEn {
	_TranslationsCreateFlightTravelDateDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String inDays({required Object count}) => 'In ${count} Tagen';
	@override String get today => 'Heute';
	@override String get tomorrow => 'Morgen';
	@override String get stepTitle => 'Wann fliegst du?';
	@override String get customDate => 'Anderes Datum wählen';
	@override String get skipDate => 'Ohne Datum fortfahren';
}

// Path: createFlight.flightNumberSearch
class _TranslationsCreateFlightFlightNumberSearchDe extends TranslationsCreateFlightFlightNumberSearchEn {
	_TranslationsCreateFlightFlightNumberSearchDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Flugnummer';
	@override String get subtitle => 'Gib eine Flugnummer ein (zum Beispiel BA117).';
	@override String get hint => 'z. B. BA117';
	@override String get loading => 'Dein Flug wird gesucht';
	@override String get loadingHint => 'Das kann ein paar Sekunden dauern, während wir aktuelle Flüge prüfen.';
	@override String get invalidFormatError => 'Gib eine gültige Flugnummer wie BA117 ein.';
	@override String get notFoundError => 'Wir konnten diese Flugnummer nicht finden. Prüfe sie und versuche es erneut oder suche nach Flughäfen.';
	@override String get rateLimitedError => 'Im Moment gibt es zu viele Flugabfragen. Bitte versuche es gleich noch einmal oder suche nach Flughäfen.';
	@override String get providerUnavailableError => 'Flugdaten sind vorübergehend nicht verfügbar. Bitte versuche es gleich noch einmal oder suche nach Flughäfen.';
	@override String get unexpectedError => 'Beim Suchen dieses Flugs ist ein Fehler aufgetreten. Bitte versuche es erneut oder suche nach Flughäfen.';
	@override String get findByAirports => 'Nach Flughäfen suchen';
	@override String get airportsFallbackButton => 'Nach Flughäfen suchen';
	@override String get confirmTitle => 'Flug bestätigen';
	@override String get foundTitle => 'Wir haben deinen Flug gefunden';
	@override String get beyondWindowHint => 'Fliegst du später? Für die aktuellste und genaueste Flugkarte empfehlen wir den Download innerhalb von 7 Tagen vor deinem Flug.';
	@override String get basedOnSameFlightOn => '* Basierend auf der zuletzt aufgezeichneten Route für denselben Flug';
}

// Path: createFlight.realRouteAirportSearch
class _TranslationsCreateFlightRealRouteAirportSearchDe extends TranslationsCreateFlightRealRouteAirportSearchEn {
	_TranslationsCreateFlightRealRouteAirportSearchDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Echte Flüge nach Flughäfen finden';
	@override String get subtitle => 'Wähle Abflug- und Zielflughafen, um aktuelle echte Flüge auf dieser Strecke zu finden.';
	@override String get searchAction => 'Aktuelle Flüge suchen';
	@override String get loading => 'Aktuelle echte Flüge werden gesucht';
	@override String get loadingHint => 'Das kann ein paar Sekunden dauern, während wir den jüngsten Streckenverlauf prüfen.';
	@override String sorryNoFlightFromTo({required Object departure, required Object arrival}) => 'Entschuldigung, wir konnten keine Flüge von ${departure} nach ${arrival} finden.';
	@override String get emptyTitle => 'Wir konnten keine aktuellen Flüge zwischen diesen Flughäfen finden';
	@override String get emptyResults => 'Achte darauf, dass du dieselben Abflug- und Zielflughäfen wie auf deinem Flugticket ausgewählt hast.';
	@override String get searchReverse => 'Gegenrichtung versuchen';
	@override String get rateLimitedError => 'Im Moment gibt es zu viele Flugabfragen. Bitte versuche es gleich noch einmal.';
	@override String get providerUnavailableError => 'Echte Flugdaten sind vorübergehend nicht verfügbar. Bitte versuche es gleich noch einmal.';
	@override String get unexpectedError => 'Beim Suchen dieser Strecke ist ein Fehler aufgetreten. Bitte versuche es erneut.';
	@override String get foundOneTitle => '1 Flug gefunden';
	@override String foundManyTitle({required Object count}) => '${count} Flüge gefunden';
	@override String get ticketMatchHint => 'Achte darauf, dass diese den Flughäfen auf deinem Flugticket entsprechen.';
	@override String get findByFlightNumber => 'Nach Flugnummer suchen';
}

// Path: createFlight.search
class _TranslationsCreateFlightSearchDe extends TranslationsCreateFlightSearchEn {
	_TranslationsCreateFlightSearchDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get departureHint => 'Abflughafen suchen';
	@override String get arrivalHint => 'Zielflughafen suchen';
	@override String get removeFavorite => 'Favorit entfernen';
	@override String get addFavorite => 'Zu Favoriten hinzufügen';
	@override String get removeSelectedAirport => 'Ausgewählten Flughafen entfernen';
	@override String get favorites => 'Favoriten';
	@override String get recentAirports => 'Kürzlich verwendete Flughäfen';
	@override String get popularAirports => 'Beliebte Flughäfen';
	@override String get removeFromFavorites => 'Aus Favoriten entfernen';
	@override String get noDepartureFound => 'Keine Abflughäfen gefunden.';
	@override String get noArrivalFound => 'Keine Zielflughäfen gefunden.';
	@override String airportCodeCity({required Object code, required Object city}) => '${code} · ${city}';
	@override String airportNameCode({required Object name, required Object code}) => '${name} (${code})';
}

// Path: createFlight.mapPreview
class _TranslationsCreateFlightMapPreviewDe extends TranslationsCreateFlightMapPreviewEn {
	_TranslationsCreateFlightMapPreviewDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get routeNotSupportedMsg => 'Leider werden Antimeridian-Flüge noch nicht unterstützt.';
	@override String get basic => 'Basis';
	@override String get pro => 'Pro';
	@override String get mapDetailInfoTooltip => 'Hinweis zur Route';
	@override String get legendButton => 'Legende';
	@override String get legendTitle => 'POI-Legende';
	@override String estimatedMapSize({required Object size}) => 'Geschätzte Kartengröße: ${size}';
	@override String get upgradeToPro => 'Zu Pro upgraden';
	@override String get basicHint => 'Einfache Kartendetails mit begrenzten Orten';
	@override String get proGateHint => 'Upgrade auf Pro für eine detaillierte Karte mit allen Orten';
	@override String proHint({required Object count}) => 'Detaillierte Offline-Karte mit ${count} Orten';
	@override String get optionsTitle => 'Ungefähre Route';
	@override String get optionsBody => 'Die Route ist ungefähr — der tatsächliche Flugweg kann abweichen, besonders bei Langstreckenflügen.';
}

// Path: createFlight.overview
class _TranslationsCreateFlightOverviewDe extends TranslationsCreateFlightOverviewEn {
	_TranslationsCreateFlightOverviewDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get routeNotReady => 'Die Route ist noch nicht bereit.';
	@override String get proPoiUpsell => 'Der Gratis-Tarif enthält eine einfache Karte und begrenzte Orte';
	@override String get routeNoteTooltip => 'Hinweis zur Route';
	@override String get routeNoteTitle => 'Ungefähre Route';
	@override String get routeNoteBody => 'Die Route ist ungefähr — der tatsächliche Flugweg kann abweichen, besonders bei Langstreckenflügen.';
	@override String get realRouteNoteTitle => 'Echte Route';
	@override String get realRouteNoteBody => 'Diese Route basiert auf der zuletzt aufgezeichneten Route für denselben Flug.\nDie tatsächliche Streckenführung kann wegen Wetter, Luftverkehr und betrieblicher Einschränkungen abweichen.';
	@override String get approximateRouteLongHaulWarningTitle => 'Dies ist eine ungefähre Route';
	@override String get approximateRouteLongHaulWarningBody => 'Ungefähre Routen können bei Langstreckenflügen ungenau sein. Verwende stattdessen eine echte Route mit einer Flugnummer.';
	@override String get approximateRouteUltraLongHaulUnsupportedBody => 'Ungefähre Routen werden für Ultra-Langstreckenflüge nicht unterstützt. Verwende stattdessen eine echte Route mit einer Flugnummer.';
	@override String get startReview => 'Überprüfung starten';
	@override String get skipReview => 'Überspringen';
	@override String get premiumGateTitle => 'Vollständige Routenübersicht freischalten';
	@override String get premiumGateBody => 'Der Gratis-Tarif enthält nur eine eingeschränkte Routenvorschau. Upgrade auf Pro, um jede Region auf dieser Route zu sehen.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Schalte alle ${count} Regionen dieser Route mit Pro frei.';
	@override String get premiumGateCta => 'Zu Pro upgraden';
	@override String get buildingHint => 'Bei längeren Strecken kann das ein paar Sekunden dauern…';
	@override String get routeReviewedTitle => 'Route geprüft';
	@override String routeReviewedSubtitle({required Object regions, required Object departure, required Object arrival}) => 'Du wirst ${regions} von ${departure} nach ${arrival} überfliegen.';
	@override String get fullSummary => 'Vollständige Zusammenfassung';
	@override String get routeSummaryTitle => 'Routenzusammenfassung';
	@override String get routeSummaryDistanceLabel => 'Distanz';
	@override String get routeSummaryDurationLabel => 'Dauer';
	@override String get routeSummaryRegionsLabel => 'Regionen';
	@override String get routeSummaryRegionsTitle => 'Du fliegst über';
	@override String get routeSummaryPlacesLabel => 'Orte';
	@override String get routeSummaryTimelineTitle => 'Zeitachse';
	@override String get routeSummaryPlacesTitle => 'Orte entlang der Route';
	@override String get routeSummaryPoiSearchHint => 'Orte suchen';
	@override String get routeSummaryPoiNoMatches => 'Keine Orte passen zu deiner Suche.';
	@override late final _TranslationsCreateFlightOverviewAirportCardDe airportCard = _TranslationsCreateFlightOverviewAirportCardDe._(_root);
	@override late final _TranslationsCreateFlightOverviewRegionInfoDe regionInfo = _TranslationsCreateFlightOverviewRegionInfoDe._(_root);
	@override late final _TranslationsCreateFlightOverviewTimelineDe timeline = _TranslationsCreateFlightOverviewTimelineDe._(_root);
}

// Path: createFlight.wikipedia
class _TranslationsCreateFlightWikipediaDe extends TranslationsCreateFlightWikipediaEn {
	_TranslationsCreateFlightWikipediaDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lade Artikel herunter und lies sie während des Flugs';
	@override String get loadingIntro => 'Routenbezogene Artikel werden gesucht...';
	@override String foundIntro({required Object count}) => 'Basierend auf deiner Route haben wir ${count} relevante Artikel gefunden';
	@override String get emptyIntro => 'Keine routenbezogenen Wikipedia-Artikel gefunden. Du kannst nur mit dem Kartendownload fortfahren.';
	@override String selectedCount({required Object count}) => '${count} ausgewählt';
	@override String get unselectAll => 'Auswahl aufheben';
	@override String get selectAll => 'Alle auswählen';
	@override String basicHint({required Object count}) => 'Ausgewählte Offline-Artikel: ${count}';
	@override String get proHint => 'Karte und Offline-Datenpaket';
	@override String get proGateHint => 'Upgrade für das vollständige Offline-Artikelpaket';
	@override String get proActiveTitle => 'Pro aktiv';
	@override String get proActiveMessage => 'Vollständiges Artikelpaket freigeschaltet.';
	@override String get freeLimitHint => 'Der Gratis-Tarif enthält bis zu 3 Offline-Artikel';
	@override String estimatedDownloadSize({required Object size}) => 'Geschätzte Downloadgröße: ${size}';
	@override String get upgrade => 'Zu Pro upgraden';
	@override String get loadingSuggestions => 'Artikelsvorschläge werden geladen...';
	@override String get downloadMapOnly => 'Karte herunterladen';
	@override String get downloadMapPlusOne => 'Karte + 1 Artikel herunterladen';
	@override String downloadMapPlusMany({required Object count}) => 'Karte + ${count} Artikel herunterladen';
	@override String get couldNotOpenLink => 'Link konnte nicht geöffnet werden';
}

// Path: createFlight.downloading
class _TranslationsCreateFlightDownloadingDe extends TranslationsCreateFlightDownloadingEn {
	_TranslationsCreateFlightDownloadingDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get articlesTitle => 'Ausgewählte Artikel werden heruntergeladen...';
	@override String get mapTitle => 'Offline-Karte wird heruntergeladen...';
	@override String get mapSectionTitle => 'Karte';
	@override String get poiSectionTitle => 'Orte';
	@override String get articlesSectionTitle => 'Artikel';
	@override String get cancelDownload => 'Download abbrechen';
	@override String get doNotClose => 'Schließe diesen Bildschirm nicht, bis der Download abgeschlossen ist';
	@override String get currentStep => 'Aktuell';
	@override String get pending => 'Ausstehend';
	@override String get inProgress => 'In Bearbeitung';
	@override String get completed => 'Abgeschlossen';
	@override String get completedWithIssues => 'Mit Problemen abgeschlossen';
	@override String get failed => 'Fehlgeschlagen';
	@override String get skipped => 'Übersprungen';
	@override String get waitingForMap => 'Warte auf Kartendownload...';
	@override String get mapFailed => 'Kartendownload fehlgeschlagen.';
	@override String get noPoiSelected => 'Keine Ortszusammenfassungen ausgewählt.';
	@override String get preparingPoi => 'Ortszusammenfassungen werden vorbereitet...';
	@override String poiProgress({required Object completed, required Object total}) => 'Orte: ${completed}/${total}';
	@override String poiProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Orte: ${completed}/${total} (${failed} fehlgeschlagen)';
	@override String get noArticlesSelected => 'Keine Artikel ausgewählt.';
	@override String get preparingArticles => 'Artikel-Downloads werden vorbereitet...';
	@override String articlesProgress({required Object completed, required Object total}) => 'Artikel: ${completed}/${total}';
	@override String articlesProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Artikel: ${completed}/${total} (${failed} fehlgeschlagen)';
	@override String get preparingMap => 'Kartendownload wird vorbereitet...';
	@override String get computingTiles => 'Kartenkacheln werden berechnet...';
	@override String computingTilesWithCount({required Object count}) => 'Kartenkacheln werden berechnet (${count})...';
	@override String get preparingForDownload => 'Download wird vorbereitet...';
	@override String downloaded({required Object size}) => 'Heruntergeladen: ${size}';
	@override String get finalizing => 'Kartenpaket wird finalisiert...';
	@override String get verifying => 'Kartenpaket wird überprüft...';
}

// Path: createFlight.errors
class _TranslationsCreateFlightErrorsDe extends TranslationsCreateFlightErrorsEn {
	_TranslationsCreateFlightErrorsDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get failedLoadAirports => 'Flughäfen konnten nicht geladen werden. Bitte versuche es erneut.';
	@override String get airportSearchFailed => 'Flughafensuche fehlgeschlagen. Versuche eine andere Anfrage.';
	@override String get someArticlesFailed => 'Einige Artikel sind fehlgeschlagen. Kartendownload wird fortgesetzt.';
	@override String get someOptionalDownloadsFailed => 'Karte heruntergeladen. Einige optionale Inhalte konnten nicht heruntergeladen werden.';
	@override String get failedBuildPreview => 'Routenvorschau konnte nicht erstellt werden. Bitte versuche es erneut.';
	@override String get overviewUnavailableContinue => 'Routenübersicht konnte nicht geladen werden. Du kannst trotzdem fortfahren.';
	@override String get noInternet => 'Keine Internetverbindung. Bitte prüfe deine Verbindung und versuche es erneut.';
	@override String failedStartDownload({required Object error}) => 'Download konnte nicht gestartet werden: ${error}';
}

// Path: createFlight.paywall
class _TranslationsCreateFlightPaywallDe extends TranslationsCreateFlightPaywallEn {
	_TranslationsCreateFlightPaywallDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get upgradeCancelled => 'Upgrade abgebrochen.';
	@override String get noPaywall => 'Derzeit keine Bezahlschranke verfügbar.';
	@override String get failedOpenPaywall => 'Paywall konnte nicht geöffnet werden.';
}

// Path: createFlight.realRouteChoice
class _TranslationsCreateFlightRealRouteChoiceDe extends TranslationsCreateFlightRealRouteChoiceEn {
	_TranslationsCreateFlightRealRouteChoiceDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Echte Flugroute holen?';
	@override String get body => 'Auf diesem Flug ist jetzt alles freigeschaltet. Er nutzt aber noch eine ungefähre Route — gib deine Flugnummer ein und wir bauen ihn aus dem echten Flugverlauf neu auf.';
	@override String get ctaEnterFlightNumber => 'Meine Flugnummer eingeben';
	@override String get ctaKeepRoute => 'Ungefähre Route behalten';
}

// Path: flight.map
class _TranslationsFlightMapDe extends TranslationsFlightMapEn {
	_TranslationsFlightMapDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get initializing => 'Karte wird geladen';
	@override String get loadingStyle => 'Karte wird geladen';
	@override String get offlineNotAvailable => 'Offline-Karte ist für diesen Flug nicht verfügbar.';
	@override String get offlineMissing => 'Offline-Kartendatei fehlt. Bitte lade diese Route erneut herunter.';
	@override String get validationFailed => 'Validierung der Offline-Karte fehlgeschlagen. Bitte lade diese Route erneut herunter.';
	@override String get loadStyleFailed => 'Offline-Kartenstil konnte nicht geladen werden.';
	@override String sunriseInMinutes({required Object minutes}) => 'Sonnenaufgang in ${minutes} Min';
	@override String sunsetInMinutes({required Object minutes}) => 'Sonnenuntergang in ${minutes} Min';
	@override String get switchTo2D => 'Zu 2D wechseln';
	@override String get switchTo3D => 'Zu 3D wechseln';
	@override String get switchToLightMapStyle => 'Zum hellen Kartenstil wechseln';
	@override String get switchToDarkMapStyle => 'Zum dunklen Kartenstil wechseln';
	@override String get uncenterMap => 'Karte nicht zentrieren';
	@override String get centerOnMe => 'Auf mich zentrieren';
}

// Path: flight.dashboard
class _TranslationsFlightDashboardDe extends TranslationsFlightDashboardEn {
	_TranslationsFlightDashboardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get gpsOffTitle => 'Standortdienste sind deaktiviert';
	@override String get gpsOffSubtitle => 'Aktiviere die Standortdienste in den Systemeinstellungen, um Live-Flugverfolgung und Kartenverfolgung fortzusetzen.';
	@override String get openLocationSettings => 'Standorteinstellungen öffnen';
	@override String get permissionTitle => 'Standortberechtigung erforderlich';
	@override String get permissionSubtitle => 'Erlaube den Standortzugriff, damit das Dashboard Live-Kurs, Geschwindigkeit und Höhe anzeigen kann.';
	@override String get grantPermissions => 'Berechtigungen erteilen';
	@override String gpsAccuracy({required Object label, required Object accuracy}) => 'GPS-Genauigkeit: ${label} (±${accuracy} m)';
	@override String get accuracyExcellent => 'Ausgezeichnet';
	@override String get accuracyGood => 'Gut';
	@override String get accuracyPoor => 'Schlecht';
	@override String get gpsOff => 'GPS aus';
	@override String get gpsOffHint => 'Aktiviere die Standortdienste, um die Verfolgung zu starten.';
	@override String get gpsPermissionRequired => 'GPS-Berechtigung erforderlich';
	@override String get gpsPermissionHint => 'Erteile die Berechtigung, um auf Live-Flugdaten zuzugreifen.';
	@override String get gpsSearching => 'GPS wird gesucht';
	@override String get gpsSearchingHint => 'Suche nach einem zuverlässigen Signal';
	@override String gpsSearchingHintWithAge({required Object age}) => 'Suche nach GPS. Letzter Fix ${age}.';
	@override String get gpsWeak => 'Schwaches GPS-Signal';
	@override String get gpsWeakHint => 'Das Signal ist instabil. Halte das Gerät unter freiem Himmel.';
	@override String gpsWeakHintWithAge({required Object age}) => 'Signal instabil. Letzter Fix ${age}.';
	@override String get gpsActive => 'GPS aktiv';
	@override String get gpsActiveHint => 'Live-Telemetrie wird empfangen.';
	@override String gpsActiveHintWithAge({required Object age}) => 'Letztes GPS-Update ${age}.';
	@override String get gpsShowingLastKnownData => 'Letzte bekannte Daten werden angezeigt';
	@override String get gpsHelpTooltip => 'GPS-Fehlerbehebung';
	@override String get gpsHelpTitle => 'GPS-Fehlerbehebung';
	@override String get gpsHelpBody => 'Es sieht so aus, als sei das GPS-Signal auf deinem Telefon nicht zuverlässig.';
	@override String get gpsHelpStepsTitle => 'Versuche Folgendes';
	@override String get gpsHelpTipLocation => 'Stelle sicher, dass die Standortdienste aktiviert sind';
	@override String get gpsHelpTipWindow => 'Bewege dein Telefon näher ans Fenster';
	@override String get gpsHelpTipCase => 'Entferne dicke Hüllen oder Metallzubehör';
	@override String get gpsHelpTipFlat => 'Halte dein Telefon kurz ruhig';
	@override String get gpsHelpFooter => 'Die Live-Verfolgung wird automatisch fortgesetzt, sobald sich das Signal stabilisiert.';
	@override String get ageJustNow => 'gerade eben';
	@override String ageSeconds({required Object seconds}) => 'vor ${seconds} s';
	@override String ageMinutes({required Object minutes}) => 'vor ${minutes} Min';
	@override String get signalGood => 'Gut';
	@override String get signalPoor => 'Schlecht';
	@override String get signalBad => 'Sehr schlecht';
	@override String get signalSearching => 'Suche';
	@override String gpsQuality({required Object quality}) => 'GPS ${quality}';
	@override String get gpsSearchingLabel => 'GPS-Suche';
	@override String get gpsPermissionNeededLabel => 'GPS-Berechtigung nötig';
	@override String get gpsOffLabel => 'GPS aus';
	@override String get aircraftHeading => 'Flugzeugkurs';
	@override String headingShort({required Object heading}) => 'KURS ${heading}°';
	@override String get liveInstruments => 'Live-Instrumente';
	@override String get groundSpeed => 'Bodengeschwindigkeit';
	@override String get altitudeMsl => 'Höhe über Meer';
	@override String get outsideAirApprox => 'Außentemperatur';
	@override String temperatureAvailableAfter({required Object threshold}) => 'Verfügbar nach ${threshold}';
	@override String get temperatureApproxHint => 'Grober Schätzwert basierend auf der Höhe';
	@override String get headingPanel => 'Kurs';
	@override String get flightPhaseTaxi => 'Rollen';
	@override String get flightPhaseGroundRoll => 'Bodenlauf';
	@override String get flightPhaseTakeoffRoll => 'Startlauf';
	@override String get flightPhaseLandingRoll => 'Landelauf';
	@override String get flightPhaseAscending => 'Steigend';
	@override String get flightPhaseCruising => 'Reiseflug';
	@override String get flightPhaseDescending => 'Sinkend';
	@override String get acquiringGpsSignal => 'GPS-Signal wird erfasst';
	@override String get acquiringGpsHint => 'Halte das Gerät ruhig und unter freiem Himmel für einen zuverlässigen Fix.';
	@override String get weakSignalBanner => 'Schwaches GPS-Signal. Werte können abweichen, bis sich die Genauigkeit verbessert.';
	@override String get preparingDashboard => 'Dashboard wird vorbereitet...';
	@override String get navigation => 'Navigation';
	@override String heading({required Object heading}) => 'Kurs ${heading}';
	@override String get routeProgress => 'Routenfortschritt';
	@override String get covered => 'Zurückgelegt';
	@override String get remaining => 'Verbleibend';
	@override String get total => 'Gesamt';
}

// Path: flight.upcoming
class _TranslationsFlightUpcomingDe extends TranslationsFlightUpcomingEn {
	_TranslationsFlightUpcomingDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get mapTitle => 'Starte deine Flugreise';
	@override String get mapSubtitle => 'Starte die Live-Verfolgung, sobald dein Flug beginnt';
	@override String get dashboardTitle => 'Starte deine Flugreise';
	@override String get dashboardSubtitle => 'Beginne, um dein Live-Dashboard zu sehen';
	@override String get checkInButton => 'Starten';
	@override String get checkInSuccess => 'Flug gestartet';
	@override String get checkInError => 'Konnte jetzt nicht gestartet werden. Bitte versuche es erneut';
}

// Path: flight.info
class _TranslationsFlightInfoDe extends TranslationsFlightInfoEn {
	_TranslationsFlightInfoDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get overviewTitle => 'Übersicht';
	@override String get overviewLoading => 'Routenübersicht wird erstellt...';
	@override String get overviewEmpty => 'Für diese Route ist noch keine Übersicht verfügbar.';
	@override String get loadingRouteInformation => 'Routeninformationen werden geladen...';
	@override String get flyOverTitle => 'Highlights deiner Route';
	@override String get airportsTitle => 'Flughäfen';
	@override String get departure => 'Abflug';
	@override String get arrival => 'Ankunft';
	@override String get showAll => 'Alle anzeigen';
	@override String showAllCount({required Object count}) => 'Alle ${count} anzeigen';
	@override String get showLess => 'Weniger anzeigen';
	@override String get sortByRank => 'Nach Rang';
	@override String get sortByRouteProgress => 'Nach Route';
	@override String get sortByType => 'Nach Typ';
	@override String get routeTimelineTitle => 'Routen-Zeitachse';
	@override String plannedWaypoints({required Object count}) => '${count} geplante Wegpunkte';
	@override String get pointsOfInterestTitle => 'Sehenswürdigkeiten';
	@override String get noPoi => 'Noch keine POIs verfügbar.';
	@override String poiType({required Object type}) => 'Typ: ${type}';
	@override String poiFlyOver({required Object view}) => 'Überflug: ${view}';
	@override String get offlineArticlesTitle => 'Offline-Artikel';
	@override String get regionArticlesTitle => 'Regionsartikel';
	@override String get otherArticlesTitle => 'Andere Artikel';
	@override String get noOfflineArticles => 'Keine Offline-Artikel heruntergeladen.';
	@override String get openSource => 'Quelle öffnen';
	@override String get openSourcePage => 'Quellseite öffnen';
	@override String get openSourcePageTooltip => 'Quellseite öffnen';
	@override String distanceKm({required Object distance}) => '${distance} km';
	@override String get speed => 'Geschwindigkeit';
	@override String get altitude => 'Höhe';
	@override String get copyRouteTitle => 'Flymap-Route';
	@override String copyRouteCode({required Object routeCode}) => 'Routencode: ${routeCode}';
	@override String copyDistance({required Object distance}) => 'Distanz: ${distance} km';
	@override String get copyFrom => 'Von';
	@override String get copyTo => 'Nach';
	@override String copyCity({required Object city, required Object countryCode}) => 'Stadt: ${city}, ${countryCode}';
	@override String copyAirport({required Object airport}) => 'Flughafen: ${airport}';
	@override String copyCodes({required Object iata, required Object icao}) => 'Codes: IATA ${iata} | ICAO ${icao}';
}

// Path: flight.route
class _TranslationsFlightRouteDe extends TranslationsFlightRouteEn {
	_TranslationsFlightRouteDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get loadingRouteTimeline => 'Routen-Zeitachse wird geladen...';
	@override String get noSavedOfflineRegions => 'Keine gespeicherten Offline-Regionen für diesen Flug.';
	@override String currentProgress({required Object percentage, required Object minute}) => 'Aktueller Fortschritt: ${percentage}% (etwa ${minute} nach dem Start)';
	@override String get nowLabel => 'Jetzt';
	@override String get currentRegionLabel => 'Aktuell';
	@override String get nextRegionLabel => 'Nächste';
	@override String get arrivingLabel => 'Anflug';
	@override String get arrivedLabel => 'Angekommen';
	@override String etaLabel({required Object time}) => 'ETA: ${time}';
	@override String etaInLabel({required Object time}) => 'in ${time}';
	@override String get flyingOverLabel => 'Du fliegst über:';
	@override String get premiumLockedChipLabel => 'Freischalten';
	@override String get premiumGateTitle => 'Vollständige Routen-Zeitachse freischalten';
	@override String get premiumGateBody => 'Upgrade auf Pro, um alle Regionen entlang deiner Route und Details der Zeitachse zu sehen.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Schalte alle ${count} Regionen dieser Route mit Premium frei.';
	@override String get premiumGateCta => 'Zu Pro upgraden';
	@override String get premiumOfflineTitle => 'Internet für Upgrade erforderlich';
	@override String get premiumOfflineBody => 'Du bist gerade offline. Stelle eine Internetverbindung her, um upzugraden und die vollständige Routenansicht freizuschalten.';
	@override String nextHintLabel({required Object region, required Object eta}) => 'Als Nächstes: ${region} (${eta})';
	@override String get etaUnknownLabel => 'wird geschätzt...';
}

// Path: onboarding.payoff
class _TranslationsOnboardingPayoffDe extends TranslationsOnboardingPayoffEn {
	_TranslationsOnboardingPayoffDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String title({required Object airport}) => 'Orte rund um ${airport}, die du nicht verpassen solltest';
	@override String get subtitle => 'Du fliegst jedes Mal direkt darüber hinweg — halte auf deinem nächsten Flug Ausschau:';
	@override String scanning({required Object airport}) => 'Wir scannen den Himmel rund um ${airport}…';
	@override String moreNearby({required Object count}) => '…und ${count}+ weitere Orte in der Nähe:';
	@override String get fallbackTitle => 'Verpasse nie wieder, was unter dir liegt';
	@override String get fallbackSubtitle => 'Jeder Flug führt über Vulkane, Berge, Inseln und Seen, die die meisten Reisenden nie bemerken. Flymap zeigt dir, was vor deinem Fenster liegt.';
}

// Path: createFlight.overview.airportCard
class _TranslationsCreateFlightOverviewAirportCardDe extends TranslationsCreateFlightOverviewAirportCardEn {
	_TranslationsCreateFlightOverviewAirportCardDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String departureDescription({required Object airport}) => 'Du startest deine Reise von ${airport}.';
	@override String arrivalDescription({required Object airport}) => 'Du kommst in ${airport} an.';
}

// Path: createFlight.overview.regionInfo
class _TranslationsCreateFlightOverviewRegionInfoDe extends TranslationsCreateFlightOverviewRegionInfoEn {
	_TranslationsCreateFlightOverviewRegionInfoDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get descriptionUnavailable => 'Beschreibung ist noch nicht verfügbar.';
	@override String get wikipediaSectionTitle => 'Wikipedia';
	@override String get wikipediaUnavailable => 'Der Wikipedia-Artikel ist momentan nicht verfügbar.';
	@override String get openWikipedia => 'Wikipedia öffnen';
}

// Path: createFlight.overview.timeline
class _TranslationsCreateFlightOverviewTimelineDe extends TranslationsCreateFlightOverviewTimelineEn {
	_TranslationsCreateFlightOverviewTimelineDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get takeOffTimeline => 'Start';
	@override String get land => 'Landung';
	@override String get alsoAroundThisTime => 'Auch ungefähr zur gleichen Zeit:';
	@override String get minuteUnit => 'Min';
	@override String get hourCompactUnit => 'Std';
	@override String get minuteCompactUnit => 'Min';
	@override late final _TranslationsCreateFlightOverviewTimelineRegionTypeDe regionType = _TranslationsCreateFlightOverviewTimelineRegionTypeDe._(_root);
}

// Path: createFlight.overview.timeline.regionType
class _TranslationsCreateFlightOverviewTimelineRegionTypeDe extends TranslationsCreateFlightOverviewTimelineRegionTypeEn {
	_TranslationsCreateFlightOverviewTimelineRegionTypeDe._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get country => 'Land';
	@override String get region => 'Region';
	@override String get state => 'Bundesland';
	@override String get province => 'Provinz';
	@override String get sea => 'Meer';
	@override String get ocean => 'Ozean';
	@override String get strait => 'Meerenge';
	@override String get channel => 'Kanal';
	@override String get gulf => 'Golf';
	@override String get bay => 'Bucht';
	@override String get lake => 'See';
	@override String get alkalineLake => 'Salzsee';
	@override String get island => 'Insel';
	@override String get archipelago => 'Archipel';
	@override String get peninsula => 'Halbinsel';
	@override String get coast => 'Küste';
	@override String get mountainRange => 'Gebirge';
	@override String get valley => 'Tal';
	@override String get plateau => 'Hochebene';
	@override String get plain => 'Ebene';
	@override String get basin => 'Becken';
	@override String get lowland => 'Tiefland';
	@override String get tundra => 'Tundra';
	@override String get wetlands => 'Feuchtgebiet';
	@override String get desert => 'Wüste';
	@override String get delta => 'Delta';
	@override String get reservoir => 'Stausee';
	@override String get continent => 'Kontinent';
	@override String get geoarea => 'Geografisches Gebiet';
	@override String get isthmus => 'Isthmus';
	@override String get unknown => 'Unbekannter Regionstyp';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Flymap',
			'common.kContinue' => 'Weiter',
			'common.back' => 'Zurück',
			'common.cancel' => 'Abbrechen',
			'common.ok' => 'OK',
			'common.retry' => 'Erneut versuchen',
			'common.manage' => 'Verwalten',
			'common.edit' => 'Bearbeiten',
			'common.upgrade' => 'Zu Pro upgraden',
			'common.loading' => 'Wird geladen...',
			'common.readMore' => 'Mehr lesen',
			'common.pro' => 'PRO',
			'common.search' => 'Suchen',
			'common.debug' => 'Debug',
			'home.title' => 'Start',
			'home.aboutTooltip' => 'Info',
			'home.settingsTooltip' => 'Einstellungen',
			'home.tabFlights' => 'Flüge',
			'home.tabLearn' => 'Lernen',
			'home.tabMedia' => 'Medien',
			'home.openSkyCamera' => 'Sky Camera öffnen',
			'home.loadingFlights' => 'Flüge werden geladen...',
			'home.failedToLoadFlights' => 'Flüge konnten nicht geladen werden',
			'home.newFlight' => 'Neuer Flug',
			'home.addFirstFlight' => 'Ersten Flug hinzufügen',
			'home.addNextFlight' => 'Nächsten Flug hinzufügen',
			'home.welcomeTitle' => 'Willkommen bei Flymap',
			'home.welcomeTitlePro' => 'Willkommen bei Flymap Pro',
			'home.welcomeSubtitle' => 'Offline-Karten für Flüge',
			'home.greetingOnline' => 'Bereit für den nächsten Flug?',
			'home.greetingOnlineWithName' => ({required Object name}) => 'Hallo ${name}, bereit für den nächsten Flug?',
			'home.greetingOffline' => 'Bereit, deinen Flug zu entdecken?',
			'home.greetingOfflineWithName' => ({required Object name}) => 'Hallo ${name}, bereit, deinen Flug zu entdecken?',
			'home.greetingInProgress' => 'Dein Flug ist im Gange',
			'home.greetingInProgressWithName' => ({required Object name}) => 'Hallo ${name}, dein Flug ist im Gange',
			'home.totalFlights' => 'Flüge insgesamt',
			'home.storageUsed' => 'Verwendeter Speicher',
			'home.totalDistance' => 'Gesamtdistanz',
			'home.upcomingFlightsCount' => ({required Object count}) => 'Bevorstehende Flüge (${count})',
			'home.flightInProgressTitle' => 'Flug läuft',
			'home.noFlightsTitle' => 'Bereit, die Welt von oben zu entdecken?',
			'home.noFlightsSubtitle' => 'Füge deinen ersten Flug hinzu und beginne, deine nächste Reise zu entdecken.',
			'home.noFlightsTitleNext' => 'Bereit für deine nächste Reise?',
			'home.noFlightsSubtitleNext' => 'Deine abgeschlossenen Flüge findest du im Verlauf. Füge deinen nächsten Flug hinzu, um weiterzumachen.',
			'home.flightActions' => 'Flugaktionen',
			'home.viewAll' => 'Alle anzeigen',
			'home.open' => 'Öffnen',
			'home.shareRoute' => 'Route teilen',
			'home.completeFlight' => 'Flug archivieren',
			'home.deleteFlight' => 'Flug löschen',
			'home.failedDeleteFlight' => 'Flug konnte nicht gelöscht werden',
			'home.noOfflineMap' => 'Keine Offline-Karte',
			'home.placesCount' => ({required Object count}) => '${count} Orte',
			'home.regionsCount' => ({required Object count}) => '${count} Regionen',
			'home.offlineArticlesCount' => ({required Object count}) => '${count} Artikel',
			'home.savedTime' => ({required Object time}) => '${time} gespeichert',
			'home.justNow' => 'Gerade eben',
			'home.daysAgo' => ({required Object days}) => 'vor ${days} T',
			'home.hoursAgo' => ({required Object hours}) => 'vor ${hours} Std',
			'home.minutesAgo' => ({required Object minutes}) => 'vor ${minutes} Min',
			'home.sort.mostRecent' => 'Neueste',
			'home.sort.longest' => 'Längste',
			'home.sort.alphabetical' => 'A-Z',
			'skyCamera.loading' => 'Kamera wird geladen...',
			'skyCamera.loadingGpsData' => 'GPS-Daten werden geladen',
			'skyCamera.zoom' => 'Zoom',
			'skyCamera.flash' => 'Blitz',
			'skyCamera.cameraUnavailable' => 'Die Kamera ist gerade nicht verfügbar.',
			'skyCamera.cameraPermissionDenied' => 'Für Fotos wird Kamerazugriff benötigt.',
			'skyCamera.captureFailed' => 'Das Foto konnte gerade nicht aufgenommen werden.',
			'skyCamera.savedMessage' => 'Foto gespeichert',
			'skyCamera.share' => 'Teilen',
			'skyCamera.noActiveFlightTitle' => 'Kein aktiver Flug',
			'skyCamera.noActiveFlightMessage' => 'Sky Camera funktioniert auch ohne Flug, aber Routendetails erscheinen nur während eines aktiven Flugs.',
			'skyCamera.telemetrySpeed' => 'Geschwindigkeit',
			'skyCamera.telemetryAltitude' => 'Höhe',
			'skyCamera.telemetryHeading' => 'Kurs',
			'skyCamera.telemetryTime' => 'Zeit',
			'skyCamera.contextCaption' => 'Kontext',
			'skyCamera.mapCaption' => 'Karte',
			'skyCamera.coordinatesCaption' => 'Koordinaten',
			'skyCamera.noValuePlaceholder' => '--',
			'skyCamera.placeholderRoute' => 'LHR -> BCN',
			'skyCamera.placeholderOriginCode' => 'LHR',
			'skyCamera.placeholderDestinationCode' => 'BCN',
			'skyCamera.placeholderContext' => 'Mittelmeer',
			'skyCamera.placeholderMap' => 'Routenvorschau',
			'skyCamera.settingsTitle' => 'Kameraeinstellungen',
			'skyCamera.recordAudio' => 'Ton aufnehmen',
			'skyCamera.recordAudioHint' => 'Videos nehmen Mikrofonton auf.',
			'skyCamera.microphonePermissionDenied' => 'Mikrofonzugriff ist aus — Videos werden ohne Ton aufgenommen.',
			'skyCamera.preparingVideo' => 'Video wird vorbereitet…',
			'media.title' => 'Medien vom Fensterplatz',
			'media.loading' => 'Medien werden geladen...',
			'media.failedToLoad' => 'Medien konnten nicht geladen werden',
			'media.filesTab' => 'Dateien',
			'media.flightsTab' => 'Flüge',
			'media.emptyTitle' => 'Willkommen bei deiner Sky Camera am Fensterplatz',
			'media.emptySubtitle' => 'Halte wunderschöne Ausblicke von deinem Fensterplatz fest und teile sie mit Flug- und GPS-Daten-Overlays.',
			'media.emptyFlightsTitle' => 'Noch keine Flugordner',
			'media.emptyFlightsSubtitle' => 'Mit gespeicherten Flügen verknüpfte Aufnahmen erscheinen hier.',
			'media.deleteAction' => 'Löschen',
			'media.share' => 'Teilen',
			'media.selectedCount' => ({required Object count}) => '${count} ausgewählt',
			'media.groupNoFlight' => 'Kein Flugkontext',
			'media.groupNoFlightSubtitle' => 'Aufnahmen außerhalb eines aktiven Flugs',
			'media.groupUnknownFlight' => 'Flugaufnahme',
			'media.previewTitle' => 'Aufnahme',
			'media.captureCount' => ({required Object count}) => '${count} Aufnahmen',
			'media.deleteFolder' => 'Ordner löschen',
			'media.deleteFolders' => ({required Object count}) => '${count} Ordner löschen',
			'media.deleteFile' => 'Datei löschen',
			'media.deleteFiles' => ({required Object count}) => '${count} Dateien löschen',
			'media.deleteFolderConfirm' => ({required Object count}) => 'Diesen Ordner und alle ${count} Dateien löschen?',
			'media.deleteFoldersConfirm' => ({required Object count}) => '${count} Ordner und alle enthaltenen Dateien löschen?',
			'media.deleteFileConfirm' => 'Diese Datei löschen?',
			'media.deleteFilesConfirm' => ({required Object count}) => '${count} Dateien löschen?',
			'learn.loadingCategories' => 'Lernkategorien werden geladen...',
			'learn.failedToLoadCategories' => 'Kategorien konnten nicht geladen werden',
			'learn.emptyCategoriesTitle' => 'Noch keine Kategorien',
			'learn.emptyCategoriesSubtitle' => 'Lernkategorien werden hier bald erscheinen.',
			'learn.articlesCount' => ({required Object count}) => '${count} Artikel',
			'learn.loadingArticles' => 'Artikel werden geladen...',
			'learn.failedToLoadArticles' => 'Artikel konnten nicht geladen werden',
			'learn.emptyArticlesTitle' => 'Noch keine Artikel',
			'learn.emptyArticlesSubtitle' => 'Artikel für diese Kategorie werden bald erscheinen.',
			'learn.upgradeRequiresInternet' => 'Premium-Inhalte sind mit Pro verfügbar. Stelle eine Internetverbindung her, um upzugraden.',
			'learn.proListPreviewHint' => 'Du kannst diese Artikeltitel jetzt ansehen. Entsperre das Lesen mit Flymap Pro.',
			'learn.failedToLoadArticle' => 'Dieser Artikel konnte gerade nicht geöffnet werden.',
			'learn.quizzesTitle' => 'Quizze',
			'learn.articlesTitle' => 'Artikel',
			'learn.geoQuiz.title' => 'Geo Quiz',
			'learn.geoQuiz.geographyTitle' => 'Geografie',
			'learn.geoQuiz.geographySubtitle' => 'Meere, Gebirge, Seen, Inseln und mehr',
			'learn.geoQuiz.countriesTitle' => 'Länder auf der Karte',
			'learn.geoQuiz.subtitle' => 'Errate das Land anhand seines Umrisses',
			'learn.geoQuiz.loading' => 'Geo Quiz wird geladen...',
			'learn.geoQuiz.failedToLoad' => 'Quizze konnten nicht geladen werden',
			'learn.geoQuiz.failedToLoadQuiz' => 'Quiz konnte nicht geladen werden',
			'learn.geoQuiz.emptyTitle' => 'Noch keine Quizze',
			'learn.geoQuiz.emptySubtitle' => 'Geo-Quizze werden hier bald erscheinen.',
			'learn.geoQuiz.countryHint' => 'Regionsname...',
			'learn.geoQuiz.progressCount' => ({required Object solved, required Object total}) => '${solved} / ${total}',
			'learn.geoQuiz.nextCount' => ({required Object next, required Object total}) => '${next} von ${total}',
			'learn.geoQuiz.correctCount' => ({required Object count}) => '${count} richtig',
			'learn.geoQuiz.reset' => 'Fortschritt zurücksetzen',
			'learn.geoQuiz.mapPlaceholder' => 'Kartendaten werden als Nächstes hinzugefügt',
			'learn.geoQuiz.newBadge' => 'NEU',
			'learn.geoQuiz.correct' => 'Richtig',
			'learn.geoQuiz.wrong' => 'Falsch',
			'learn.geoQuiz.hintTitle' => 'Hinweis',
			'learn.geoQuiz.hintSubtitle' => 'Tippe auf einen Buchstaben, um ihn aufzudecken',
			'learn.geoQuiz.next' => 'Weiter',
			'learn.geoQuiz.pause' => 'Pausieren',
			'learn.geoQuiz.resume' => 'Fortsetzen',
			'learn.geoQuiz.finish' => 'Fertig',
			'learn.geoQuiz.completeTitle' => 'Quiz abgeschlossen',
			'learn.geoQuiz.completeMessage' => ({required Object total, required Object quiz}) => 'Du hast alle ${total} Länder in ${quiz} gefunden.',
			'learn.geoQuiz.backToQuizzes' => 'Zurück zu den Quizzen',
			'learn.geoQuiz.playAgain' => 'Erneut spielen',
			'learn.geoQuiz.progressReady' => 'Bereit zum Spielen',
			'learn.geoQuiz.progressFinished' => ({required Object count}) => '${count} abgeschlossen',
			'learn.geoQuiz.progressInProgress' => ({required Object count}) => '${count} in Arbeit',
			'learn.geoQuiz.progressAllCompleted' => 'Alle abgeschlossen',
			'learn.geoQuiz.quizCountriesAfricaTitle' => 'Afrika',
			'learn.geoQuiz.quizCountriesEuropeTitle' => 'Europa',
			'learn.geoQuiz.quizCountriesAsiaTitle' => 'Asien',
			'learn.geoQuiz.quizCountriesNorthAmericaTitle' => 'Nordamerika',
			'learn.geoQuiz.quizCountriesSouthAmericaTitle' => 'Südamerika',
			'learn.geoQuiz.quizCountriesOceaniaTitle' => 'Ozeanien',
			'learn.geoQuiz.quizCountriesAllTitle' => 'Alle Länder',
			'learn.geoQuiz.quizCountriesSubtitle' => 'Länder',
			'learn.geoQuiz.quizCountriesAllSubtitle' => 'Welt',
			'learn.geoQuiz.quizGeographySeasTitle' => 'Meere',
			'learn.geoQuiz.quizGeographyMountainRangesTitle' => 'Gebirge',
			'learn.geoQuiz.quizGeographyLakesTitle' => 'Seen',
			'learn.geoQuiz.quizGeographyIslandsTitle' => 'Inseln',
			'learn.geoQuiz.quizGeographyOtherTitle' => 'Weitere',
			'learn.geoQuiz.quizGeographyOtherSubtitle' => 'Buchten, Meerengen, Golfe, Wüsten und mehr',
			'learn.geoQuiz.descriptionUnavailable' => 'Beschreibung ist noch nicht verfügbar.',
			'settings.title' => 'Einstellungen',
			'settings.loading' => 'Einstellungen werden geladen...',
			'settings.profile' => 'Profil',
			'settings.profileSubtitle' => 'Name, Fluggewohnheiten, Heimatflughafen und Interessen',
			'settings.profileSummaryNameHome' => ({required Object name, required Object code}) => '${name} · ${code}',
			'settings.profileSummaryHome' => ({required Object code}) => 'Heimatflughafen: ${code}',
			'settings.profileEditHint' => 'Tippe auf einen Eintrag, um deine Profildaten zu bearbeiten.',
			'settings.profileNotSet' => 'Nicht festgelegt',
			'settings.profileInterestsSelected' => ({required Object count}) => '${count} ausgewählt',
			'settings.historyTitle' => 'Verlauf',
			'settings.historySubtitle' => 'Alle Flüge und Statistiken',
			'settings.historyLoading' => 'Verlauf wird geladen...',
			'settings.historyLoadError' => 'Flugverlauf konnte nicht geladen werden.',
			'settings.historyFlightsLabel' => 'Flüge insgesamt',
			'settings.historyDistanceLabel' => 'Gesamtdistanz',
			'settings.historyAllFlights' => 'Alle Flüge',
			'settings.historyStatusUpcoming' => 'Bevorstehend',
			'settings.historyStatusInProgress' => 'Im Gange',
			'settings.historyStatusCompleted' => 'Abgeschlossen',
			'settings.historyMapChip' => ({required Object size}) => 'Karte ${size}',
			'settings.historyNoMapChip' => 'Keine Karte',
			'settings.historySortName' => 'Name',
			'settings.historySortDistance' => 'Distanz',
			'settings.historySortDate' => 'Datum',
			'settings.historyEmpty' => 'Noch keine Flüge.',
			'settings.historySearchHint' => 'Nach Flughafen oder Stadt suchen',
			'settings.historyNoResults' => 'Keine passenden Flüge gefunden.',
			'settings.historyDeleteOfflineData' => 'Nur Karte löschen',
			'settings.appearance' => 'Darstellung',
			'settings.language' => 'Sprache',
			'settings.languageSubtitle' => 'App-Sprache',
			'settings.languageSystem' => 'System',
			'settings.languageSystemFormat' => ({required Object language}) => '${language} (System)',
			'settings.languageEnglish' => 'English',
			'settings.languageSpanish' => 'Español',
			'settings.languageFrench' => 'Français',
			'settings.languageGerman' => 'Deutsch',
			'settings.theme' => 'Design',
			'settings.system' => 'System',
			'settings.dark' => 'Dunkel',
			'settings.light' => 'Hell',
			'settings.units' => 'Einheiten',
			'settings.storage' => 'Speicher',
			'settings.storageTitle' => 'Speicher',
			'settings.storageSubtitle' => 'Heruntergeladene Karten und Speicherverbrauch',
			'settings.storageLoading' => 'Speicher wird geladen...',
			'settings.storageLoadError' => 'Speicherdaten konnten nicht geladen werden.',
			'settings.storageMapsLabel' => 'Heruntergeladene Karten',
			'settings.storageTotalSizeLabel' => 'Gesamtgröße',
			'settings.storageDownloadedMaps' => 'Heruntergeladene Karten',
			'settings.storageSortName' => 'Name',
			'settings.storageSortSize' => 'Größe',
			'settings.storageMapSize' => ({required Object size}) => 'Größe: ${size}',
			'settings.storageEmpty' => 'Noch keine Karten heruntergeladen.',
			'settings.altitude' => 'Höhe',
			'settings.altitudeUnit' => 'Höheneinheit',
			'settings.speed' => 'Geschwindigkeit',
			'settings.speedUnit' => 'Geschwindigkeitseinheit',
			'settings.temperatureUnit' => 'Temperatureinheit',
			'settings.timeFormat' => 'Zeitformat',
			'settings.distanceUnit' => 'Distanzeinheit',
			'settings.dateFormat' => 'Datumsformat',
			'settings.support' => 'Support',
			'settings.about' => 'Über die App',
			'settings.aboutSubtitle' => 'Mehr über die App erfahren',
			'settings.privacyPolicy' => 'Datenschutzrichtlinie',
			'settings.privacyPolicySubtitle' => 'Unsere Datenschutzrichtlinie lesen',
			'settings.termsOfService' => 'Nutzungsbedingungen',
			'settings.termsOfServiceSubtitle' => 'Unsere Nutzungsbedingungen lesen',
			'settings.flymapProActivated' => 'Flymap Pro aktiviert.',
			'settings.upgradeCancelled' => 'Upgrade abgebrochen.',
			'settings.noPaywall' => 'Derzeit keine Bezahlschranke verfügbar.',
			'settings.failedOpenPaywall' => 'Paywall konnte nicht geöffnet werden.',
			'settings.couldNotOpenUrl' => ({required Object url}) => '${url} konnte nicht geöffnet werden',
			'settings.rateUs' => 'Bewerten',
			'settings.rateUsSubtitle' => 'Hinterlasse eine Bewertung im Store',
			'settings.leaveFeedback' => 'Feedback senden',
			'settings.leaveFeedbackSubtitle' => 'Teile deine Gedanken, damit wir uns verbessern können',
			'settings.couldNotOpenStorePage' => 'Store-Seite konnte nicht geöffnet werden',
			'settings.rateDialogTitle' => 'Gefällt dir die App?',
			'settings.rateDialogBody' => 'Wir arbeiten hart daran, jeden Flug angenehmer zu machen, und dein Feedback hilft uns wirklich weiter.',
			'settings.rateDialogYes' => 'Ja',
			'settings.rateDialogNo' => 'Nein',
			'settings.advocacyDialogTitle' => 'Schön, dass dir Flymap gefällt',
			'settings.advocacyDialogBody' => 'Hilf anderen Reisenden, Flymap zu entdecken.',
			'settings.advocacyDialogShare' => 'Mit Freunden teilen',
			'settings.advocacyDialogRate' => 'Flymap bewerten',
			'settings.advocacyDialogNotNow' => 'Nicht jetzt',
			'settings.feedbackTitle' => 'Feedback senden',
			'settings.feedbackBody' => 'Hilf uns, Flymap besser zu machen',
			'settings.feedbackCategoryTitle' => 'Feedback-Typ',
			'settings.feedbackCategoryGeneral' => 'Allgemein',
			'settings.feedbackCategoryFeatureRequest' => 'Funktionswunsch',
			'settings.feedbackCategoryBugReport' => 'Fehlerbericht',
			'settings.feedbackHint' => 'Teile dein Feedback...',
			'settings.feedbackEmailHint' => 'E-Mail (optional)',
			'settings.feedbackEmailInvalid' => 'Bitte gib eine gültige E-Mail ein oder lasse das Feld leer.',
			'settings.feedbackSend' => 'Senden',
			'settings.feedbackThanks' => 'Danke für dein Feedback!',
			'settings.feedbackSendFailed' => 'Feedback konnte nicht gesendet werden. Bitte versuche es erneut.',
			'settings.proBannerTitle' => 'Flymap Pro',
			'settings.proBannerTitleActive' => 'Flymap Pro aktiv',
			'settings.proBannerSubtitleActive' => 'Detaillierter Kartenmodus und vollständige Offline-Artikelpakete freigeschaltet.',
			'settings.proBannerSubtitleFree' => 'Schalte detaillierte Karten und vollständige Offline-Artikelpakete frei',
			'settings.proBannerBadgeActive' => 'PRO AKTIV',
			'subscription.screenTitle' => 'Abonnement',
			'subscription.contactSupport' => 'Support kontaktieren',
			'subscription.cardTitle' => 'Flymap Pro',
			'subscription.periodTitle' => 'Abonnementzeitraum',
			'subscription.renewsOrExpires' => 'Verlängert sich oder läuft ab',
			'subscription.noExpiration' => 'Kein Ablaufdatum',
			'subscription.lastChecked' => 'Zuletzt geprüft',
			'subscription.flightUnlockSheetTitle' => 'Pro-Funktionen freischalten',
			'subscription.flightUnlockOptionTitle' => 'Einmalkauf',
			'subscription.flightUnlockOptionBody' => 'Schalte Pro für einen einzelnen Flug frei',
			'subscription.flightUnlockAction' => 'Für einen Flug kaufen',
			'subscription.flightUnlockUseAction' => 'Für einen Flug verwenden',
			'subscription.flightUnlockPriceLoading' => 'Preis wird geladen...',
			'subscription.flightUnlockProOptionTitle' => 'Flymap Pro Abonnement',
			'subscription.flightUnlockAvailableCount' => ({required Object count}) => '${count} Flug-Freischaltungen verfügbar',
			'subscription.flightUnlockProOptionBody' => 'Schalte Pro für unbegrenzt viele Flüge frei',
			'subscription.flightUnlockProAction' => 'Pro-Tarife ansehen',
			'subscription.flightUnlockUnavailable' => 'Die Flug-Freischaltung ist derzeit nicht verfügbar.',
			'subscription.flightUnlockPurchaseCancelled' => 'Kauf der Flug-Freischaltung abgebrochen.',
			'subscription.flightUnlockPurchaseFailed' => 'Kauf der Flug-Freischaltung fehlgeschlagen. Bitte versuche es erneut.',
			'subscription.proFeaturesTitle' => 'Was Flymap Pro freischaltet',
			'subscription.proFeatureRoutesTitle' => 'Präzise Routenvorschauen',
			'subscription.proFeatureMapsTitle' => 'Detailliertere Offline-Karten',
			'subscription.proFeatureTimelineTitle' => 'Vollständige Routen-Timeline',
			'subscription.proFeaturePoiTitle' => '10-mal mehr Orte auf der Route',
			'subscription.proFeatureArticlesTitle' => 'Vollständige Offline-Artikelpakete',
			'subscription.checkingStatus' => 'Dein Abonnementstatus wird geprüft...',
			'subscription.freePlan' => 'Du nutzt den Gratis-Tarif.',
			'subscription.active' => 'Aktiv',
			'subscription.notActive' => 'Nicht aktiv',
			'subscription.unknown' => 'Unbekannt',
			'subscription.manageSubscription' => 'Abonnement verwalten',
			'subscription.restorePurchases' => 'Käufe wiederherstellen',
			'subscription.upgradeToPro' => 'Zu Pro upgraden',
			'subscription.restoreNoSubscription' => 'Kein aktives Abonnement gefunden.',
			'subscription.supportEmailSubject' => 'Flymap Abonnement-Support',
			'subscription.couldNotOpenEmailApp' => 'E-Mail-App konnte nicht geöffnet werden',
			'subscription.couldNotOpenSubscriptionSettings' => 'Abonnement-Einstellungen konnten nicht geöffnet werden',
			'subscription.proRestored' => 'Flymap Pro wiederhergestellt.',
			'subscription.failedOpenPaywall' => 'Paywall konnte nicht geöffnet werden.',
			'subscription.serviceUnavailable' => 'Der Abonnementdienst ist vorübergehend nicht verfügbar.',
			'createFlight.steps.departureTitle' => 'Abflughafen wählen',
			'createFlight.steps.arrivalTitle' => 'Zielflughafen wählen',
			'createFlight.steps.routeNotSupportedTitle' => 'Route wird nicht unterstützt',
			'createFlight.steps.mapPreviewTitle' => 'Kartenvorschau',
			'createFlight.steps.overviewTitle' => 'Routenübersicht',
			'createFlight.steps.wikipediaTitle' => 'Wikipedia-Artikel',
			'createFlight.steps.weatherTitle' => 'Flugwetter',
			'createFlight.weather.title' => 'Wirst du den Boden sehen?',
			'createFlight.weather.loading' => 'Wir prüfen den Himmel entlang deiner Route…',
			'createFlight.weather.loadFailed' => 'Die Vorhersage konnte gerade nicht geladen werden. Versuche es erneut oder fahre ohne sie fort.',
			'createFlight.weather.estimatedBadge' => 'Zeiten geschätzt',
			'createFlight.weather.departureLabel' => 'Abflug',
			'createFlight.weather.arrivalLabel' => 'Ankunft',
			'createFlight.weather.tomorrow' => 'morgen',
			'createFlight.weather.localTimesHint' => 'Zeiten sind Ortszeit des jeweiligen Flughafens.',
			'createFlight.weather.verdictClearTitle' => 'Klare Sicht',
			'createFlight.weather.verdictClearBody' => 'Der Fensterplatz lohnt sich — der Boden sollte fast den ganzen Flug sichtbar sein.',
			'createFlight.weather.verdictPatchyTitle' => 'Aufgelockerte Bewölkung',
			'createFlight.weather.verdictPatchyBody' => 'Die Sicht kommt und geht zwischen den Wolken.',
			'createFlight.weather.verdictCarpetTitle' => 'Wolkenteppich unter dir',
			'createFlight.weather.verdictCarpetBody' => 'Ein weißes Wolkenmeer unter dir — wunderschön, aber der Boden bleibt meist verborgen.',
			'createFlight.weather.verdictOvercastTitle' => 'Bedeckter Himmel',
			'createFlight.weather.verdictOvercastBody' => 'Die beste Sicht gibt es bei Start und Landung.',
			'createFlight.weather.expectClear' => '☀️ Klar',
			'createFlight.weather.expectPatchy' => '⛅ Aufgelockert',
			'createFlight.weather.expectCarpet' => '☁️ Wolkenteppich',
			'createFlight.weather.expectOvercast' => '🌫 Bedeckt',
			'createFlight.weather.segmentAfterTakeoff' => 'nach dem Start',
			'createFlight.weather.segmentMidFlight' => 'in der Flugmitte',
			'createFlight.weather.segmentBeforeLanding' => 'vor der Landung',
			'createFlight.weather.segmentOver' => ({required Object name}) => 'über ${name}',
			'createFlight.weather.proTeaserTitle' => 'Wolkenkarte entlang deiner Route',
			'createFlight.weather.proTeaserBody' => 'Sieh, wo die Wolken sein werden — und schau deinem Flugzeug zu, wie es die ganze Route darüber fliegt.',
			'createFlight.weather.attribution' => 'Wetterdaten: MET Norwegen',
			'createFlight.weather.hedge' => 'Vorhersagen werden näher am Abflug genauer.',
			'createFlight.weather.forecastFor' => ({required Object date}) => 'Vorhersage für ${date}',
			'createFlight.weather.updatedAt' => ({required Object time}) => 'Aktualisiert ${time}',
			'createFlight.routeTypeSelector.title' => 'Neuer Flug',
			'createFlight.routeTypeSelector.basicTitle' => 'Ungefähre Route',
			'createFlight.routeTypeSelector.basicSubtitle' => 'Von Flughäfen',
			'createFlight.routeTypeSelector.basicDescription' => 'Funktioniert gut für Kurz- und viele Mittelstreckenflüge.',
			'createFlight.routeTypeSelector.proTitle' => 'Echte Route',
			'createFlight.routeTypeSelector.proSubtitle' => 'Von jüngsten Flügen',
			'createFlight.routeTypeSelector.proDescription' => 'Basiert auf der zuletzt aufgezeichneten Route desselben Flugs.',
			'createFlight.routeTypeSelector.mostAccurate' => 'Am genauesten',
			'createFlight.proAccess.subscriber' => 'Flymap Pro',
			'createFlight.proAccess.subscriberBody' => 'Dieser Flug hat über dein Flymap Pro Abonnement vollen Pro-Zugriff.',
			'createFlight.proAccess.unlockedFlight' => 'Dieser Flug ist freigeschaltet',
			'createFlight.proAccess.unlockedFlightBody' => 'Alle Pro-Funktionen sind für diesen Flug aktiviert.',
			'createFlight.proAccess.tooltip' => 'Infos zum Pro-Zugriff',
			'createFlight.travelDate.inDays' => ({required Object count}) => 'In ${count} Tagen',
			'createFlight.travelDate.today' => 'Heute',
			'createFlight.travelDate.tomorrow' => 'Morgen',
			'createFlight.travelDate.stepTitle' => 'Wann fliegst du?',
			'createFlight.travelDate.customDate' => 'Anderes Datum wählen',
			'createFlight.travelDate.skipDate' => 'Ohne Datum fortfahren',
			'createFlight.flightNumberSearch.title' => 'Flugnummer',
			'createFlight.flightNumberSearch.subtitle' => 'Gib eine Flugnummer ein (zum Beispiel BA117).',
			'createFlight.flightNumberSearch.hint' => 'z. B. BA117',
			'createFlight.flightNumberSearch.loading' => 'Dein Flug wird gesucht',
			'createFlight.flightNumberSearch.loadingHint' => 'Das kann ein paar Sekunden dauern, während wir aktuelle Flüge prüfen.',
			'createFlight.flightNumberSearch.invalidFormatError' => 'Gib eine gültige Flugnummer wie BA117 ein.',
			'createFlight.flightNumberSearch.notFoundError' => 'Wir konnten diese Flugnummer nicht finden. Prüfe sie und versuche es erneut oder suche nach Flughäfen.',
			'createFlight.flightNumberSearch.rateLimitedError' => 'Im Moment gibt es zu viele Flugabfragen. Bitte versuche es gleich noch einmal oder suche nach Flughäfen.',
			'createFlight.flightNumberSearch.providerUnavailableError' => 'Flugdaten sind vorübergehend nicht verfügbar. Bitte versuche es gleich noch einmal oder suche nach Flughäfen.',
			'createFlight.flightNumberSearch.unexpectedError' => 'Beim Suchen dieses Flugs ist ein Fehler aufgetreten. Bitte versuche es erneut oder suche nach Flughäfen.',
			'createFlight.flightNumberSearch.findByAirports' => 'Nach Flughäfen suchen',
			'createFlight.flightNumberSearch.airportsFallbackButton' => 'Nach Flughäfen suchen',
			'createFlight.flightNumberSearch.confirmTitle' => 'Flug bestätigen',
			'createFlight.flightNumberSearch.foundTitle' => 'Wir haben deinen Flug gefunden',
			'createFlight.flightNumberSearch.beyondWindowHint' => 'Fliegst du später? Für die aktuellste und genaueste Flugkarte empfehlen wir den Download innerhalb von 7 Tagen vor deinem Flug.',
			'createFlight.flightNumberSearch.basedOnSameFlightOn' => '* Basierend auf der zuletzt aufgezeichneten Route für denselben Flug',
			'createFlight.realRouteAirportSearch.title' => 'Echte Flüge nach Flughäfen finden',
			'createFlight.realRouteAirportSearch.subtitle' => 'Wähle Abflug- und Zielflughafen, um aktuelle echte Flüge auf dieser Strecke zu finden.',
			'createFlight.realRouteAirportSearch.searchAction' => 'Aktuelle Flüge suchen',
			'createFlight.realRouteAirportSearch.loading' => 'Aktuelle echte Flüge werden gesucht',
			'createFlight.realRouteAirportSearch.loadingHint' => 'Das kann ein paar Sekunden dauern, während wir den jüngsten Streckenverlauf prüfen.',
			'createFlight.realRouteAirportSearch.sorryNoFlightFromTo' => ({required Object departure, required Object arrival}) => 'Entschuldigung, wir konnten keine Flüge von ${departure} nach ${arrival} finden.',
			'createFlight.realRouteAirportSearch.emptyTitle' => 'Wir konnten keine aktuellen Flüge zwischen diesen Flughäfen finden',
			'createFlight.realRouteAirportSearch.emptyResults' => 'Achte darauf, dass du dieselben Abflug- und Zielflughäfen wie auf deinem Flugticket ausgewählt hast.',
			'createFlight.realRouteAirportSearch.searchReverse' => 'Gegenrichtung versuchen',
			'createFlight.realRouteAirportSearch.rateLimitedError' => 'Im Moment gibt es zu viele Flugabfragen. Bitte versuche es gleich noch einmal.',
			'createFlight.realRouteAirportSearch.providerUnavailableError' => 'Echte Flugdaten sind vorübergehend nicht verfügbar. Bitte versuche es gleich noch einmal.',
			'createFlight.realRouteAirportSearch.unexpectedError' => 'Beim Suchen dieser Strecke ist ein Fehler aufgetreten. Bitte versuche es erneut.',
			'createFlight.realRouteAirportSearch.foundOneTitle' => '1 Flug gefunden',
			'createFlight.realRouteAirportSearch.foundManyTitle' => ({required Object count}) => '${count} Flüge gefunden',
			'createFlight.realRouteAirportSearch.ticketMatchHint' => 'Achte darauf, dass diese den Flughäfen auf deinem Flugticket entsprechen.',
			'createFlight.realRouteAirportSearch.findByFlightNumber' => 'Nach Flugnummer suchen',
			'createFlight.search.departureHint' => 'Abflughafen suchen',
			'createFlight.search.arrivalHint' => 'Zielflughafen suchen',
			'createFlight.search.removeFavorite' => 'Favorit entfernen',
			'createFlight.search.addFavorite' => 'Zu Favoriten hinzufügen',
			'createFlight.search.removeSelectedAirport' => 'Ausgewählten Flughafen entfernen',
			'createFlight.search.favorites' => 'Favoriten',
			'createFlight.search.recentAirports' => 'Kürzlich verwendete Flughäfen',
			'createFlight.search.popularAirports' => 'Beliebte Flughäfen',
			'createFlight.search.removeFromFavorites' => 'Aus Favoriten entfernen',
			'createFlight.search.noDepartureFound' => 'Keine Abflughäfen gefunden.',
			'createFlight.search.noArrivalFound' => 'Keine Zielflughäfen gefunden.',
			'createFlight.search.airportCodeCity' => ({required Object code, required Object city}) => '${code} · ${city}',
			'createFlight.search.airportNameCode' => ({required Object name, required Object code}) => '${name} (${code})',
			'createFlight.mapPreview.routeNotSupportedMsg' => 'Leider werden Antimeridian-Flüge noch nicht unterstützt.',
			'createFlight.mapPreview.basic' => 'Basis',
			'createFlight.mapPreview.pro' => 'Pro',
			'createFlight.mapPreview.mapDetailInfoTooltip' => 'Hinweis zur Route',
			'createFlight.mapPreview.legendButton' => 'Legende',
			'createFlight.mapPreview.legendTitle' => 'POI-Legende',
			'createFlight.mapPreview.estimatedMapSize' => ({required Object size}) => 'Geschätzte Kartengröße: ${size}',
			'createFlight.mapPreview.upgradeToPro' => 'Zu Pro upgraden',
			'createFlight.mapPreview.basicHint' => 'Einfache Kartendetails mit begrenzten Orten',
			'createFlight.mapPreview.proGateHint' => 'Upgrade auf Pro für eine detaillierte Karte mit allen Orten',
			'createFlight.mapPreview.proHint' => ({required Object count}) => 'Detaillierte Offline-Karte mit ${count} Orten',
			'createFlight.mapPreview.optionsTitle' => 'Ungefähre Route',
			'createFlight.mapPreview.optionsBody' => 'Die Route ist ungefähr — der tatsächliche Flugweg kann abweichen, besonders bei Langstreckenflügen.',
			'createFlight.overview.routeNotReady' => 'Die Route ist noch nicht bereit.',
			'createFlight.overview.proPoiUpsell' => 'Der Gratis-Tarif enthält eine einfache Karte und begrenzte Orte',
			'createFlight.overview.routeNoteTooltip' => 'Hinweis zur Route',
			'createFlight.overview.routeNoteTitle' => 'Ungefähre Route',
			'createFlight.overview.routeNoteBody' => 'Die Route ist ungefähr — der tatsächliche Flugweg kann abweichen, besonders bei Langstreckenflügen.',
			'createFlight.overview.realRouteNoteTitle' => 'Echte Route',
			'createFlight.overview.realRouteNoteBody' => 'Diese Route basiert auf der zuletzt aufgezeichneten Route für denselben Flug.\nDie tatsächliche Streckenführung kann wegen Wetter, Luftverkehr und betrieblicher Einschränkungen abweichen.',
			'createFlight.overview.approximateRouteLongHaulWarningTitle' => 'Dies ist eine ungefähre Route',
			'createFlight.overview.approximateRouteLongHaulWarningBody' => 'Ungefähre Routen können bei Langstreckenflügen ungenau sein. Verwende stattdessen eine echte Route mit einer Flugnummer.',
			'createFlight.overview.approximateRouteUltraLongHaulUnsupportedBody' => 'Ungefähre Routen werden für Ultra-Langstreckenflüge nicht unterstützt. Verwende stattdessen eine echte Route mit einer Flugnummer.',
			'createFlight.overview.startReview' => 'Überprüfung starten',
			'createFlight.overview.skipReview' => 'Überspringen',
			'createFlight.overview.premiumGateTitle' => 'Vollständige Routenübersicht freischalten',
			'createFlight.overview.premiumGateBody' => 'Der Gratis-Tarif enthält nur eine eingeschränkte Routenvorschau. Upgrade auf Pro, um jede Region auf dieser Route zu sehen.',
			'createFlight.overview.premiumGateBodyWithCount' => ({required Object count}) => 'Schalte alle ${count} Regionen dieser Route mit Pro frei.',
			'createFlight.overview.premiumGateCta' => 'Zu Pro upgraden',
			'createFlight.overview.buildingHint' => 'Bei längeren Strecken kann das ein paar Sekunden dauern…',
			'createFlight.overview.routeReviewedTitle' => 'Route geprüft',
			'createFlight.overview.routeReviewedSubtitle' => ({required Object regions, required Object departure, required Object arrival}) => 'Du wirst ${regions} von ${departure} nach ${arrival} überfliegen.',
			'createFlight.overview.fullSummary' => 'Vollständige Zusammenfassung',
			'createFlight.overview.routeSummaryTitle' => 'Routenzusammenfassung',
			'createFlight.overview.routeSummaryDistanceLabel' => 'Distanz',
			'createFlight.overview.routeSummaryDurationLabel' => 'Dauer',
			'createFlight.overview.routeSummaryRegionsLabel' => 'Regionen',
			'createFlight.overview.routeSummaryRegionsTitle' => 'Du fliegst über',
			'createFlight.overview.routeSummaryPlacesLabel' => 'Orte',
			'createFlight.overview.routeSummaryTimelineTitle' => 'Zeitachse',
			'createFlight.overview.routeSummaryPlacesTitle' => 'Orte entlang der Route',
			'createFlight.overview.routeSummaryPoiSearchHint' => 'Orte suchen',
			'createFlight.overview.routeSummaryPoiNoMatches' => 'Keine Orte passen zu deiner Suche.',
			'createFlight.overview.airportCard.departureDescription' => ({required Object airport}) => 'Du startest deine Reise von ${airport}.',
			'createFlight.overview.airportCard.arrivalDescription' => ({required Object airport}) => 'Du kommst in ${airport} an.',
			'createFlight.overview.regionInfo.descriptionUnavailable' => 'Beschreibung ist noch nicht verfügbar.',
			'createFlight.overview.regionInfo.wikipediaSectionTitle' => 'Wikipedia',
			'createFlight.overview.regionInfo.wikipediaUnavailable' => 'Der Wikipedia-Artikel ist momentan nicht verfügbar.',
			'createFlight.overview.regionInfo.openWikipedia' => 'Wikipedia öffnen',
			'createFlight.overview.timeline.takeOffTimeline' => 'Start',
			'createFlight.overview.timeline.land' => 'Landung',
			'createFlight.overview.timeline.alsoAroundThisTime' => 'Auch ungefähr zur gleichen Zeit:',
			'createFlight.overview.timeline.minuteUnit' => 'Min',
			'createFlight.overview.timeline.hourCompactUnit' => 'Std',
			'createFlight.overview.timeline.minuteCompactUnit' => 'Min',
			'createFlight.overview.timeline.regionType.country' => 'Land',
			'createFlight.overview.timeline.regionType.region' => 'Region',
			'createFlight.overview.timeline.regionType.state' => 'Bundesland',
			'createFlight.overview.timeline.regionType.province' => 'Provinz',
			'createFlight.overview.timeline.regionType.sea' => 'Meer',
			'createFlight.overview.timeline.regionType.ocean' => 'Ozean',
			'createFlight.overview.timeline.regionType.strait' => 'Meerenge',
			'createFlight.overview.timeline.regionType.channel' => 'Kanal',
			'createFlight.overview.timeline.regionType.gulf' => 'Golf',
			'createFlight.overview.timeline.regionType.bay' => 'Bucht',
			'createFlight.overview.timeline.regionType.lake' => 'See',
			'createFlight.overview.timeline.regionType.alkalineLake' => 'Salzsee',
			'createFlight.overview.timeline.regionType.island' => 'Insel',
			'createFlight.overview.timeline.regionType.archipelago' => 'Archipel',
			'createFlight.overview.timeline.regionType.peninsula' => 'Halbinsel',
			'createFlight.overview.timeline.regionType.coast' => 'Küste',
			'createFlight.overview.timeline.regionType.mountainRange' => 'Gebirge',
			'createFlight.overview.timeline.regionType.valley' => 'Tal',
			'createFlight.overview.timeline.regionType.plateau' => 'Hochebene',
			'createFlight.overview.timeline.regionType.plain' => 'Ebene',
			'createFlight.overview.timeline.regionType.basin' => 'Becken',
			'createFlight.overview.timeline.regionType.lowland' => 'Tiefland',
			'createFlight.overview.timeline.regionType.tundra' => 'Tundra',
			'createFlight.overview.timeline.regionType.wetlands' => 'Feuchtgebiet',
			'createFlight.overview.timeline.regionType.desert' => 'Wüste',
			'createFlight.overview.timeline.regionType.delta' => 'Delta',
			'createFlight.overview.timeline.regionType.reservoir' => 'Stausee',
			'createFlight.overview.timeline.regionType.continent' => 'Kontinent',
			'createFlight.overview.timeline.regionType.geoarea' => 'Geografisches Gebiet',
			'createFlight.overview.timeline.regionType.isthmus' => 'Isthmus',
			_ => null,
		} ?? switch (path) {
			'createFlight.overview.timeline.regionType.unknown' => 'Unbekannter Regionstyp',
			'createFlight.wikipedia.title' => 'Lade Artikel herunter und lies sie während des Flugs',
			'createFlight.wikipedia.loadingIntro' => 'Routenbezogene Artikel werden gesucht...',
			'createFlight.wikipedia.foundIntro' => ({required Object count}) => 'Basierend auf deiner Route haben wir ${count} relevante Artikel gefunden',
			'createFlight.wikipedia.emptyIntro' => 'Keine routenbezogenen Wikipedia-Artikel gefunden. Du kannst nur mit dem Kartendownload fortfahren.',
			'createFlight.wikipedia.selectedCount' => ({required Object count}) => '${count} ausgewählt',
			'createFlight.wikipedia.unselectAll' => 'Auswahl aufheben',
			'createFlight.wikipedia.selectAll' => 'Alle auswählen',
			'createFlight.wikipedia.basicHint' => ({required Object count}) => 'Ausgewählte Offline-Artikel: ${count}',
			'createFlight.wikipedia.proHint' => 'Karte und Offline-Datenpaket',
			'createFlight.wikipedia.proGateHint' => 'Upgrade für das vollständige Offline-Artikelpaket',
			'createFlight.wikipedia.proActiveTitle' => 'Pro aktiv',
			'createFlight.wikipedia.proActiveMessage' => 'Vollständiges Artikelpaket freigeschaltet.',
			'createFlight.wikipedia.freeLimitHint' => 'Der Gratis-Tarif enthält bis zu 3 Offline-Artikel',
			'createFlight.wikipedia.estimatedDownloadSize' => ({required Object size}) => 'Geschätzte Downloadgröße: ${size}',
			'createFlight.wikipedia.upgrade' => 'Zu Pro upgraden',
			'createFlight.wikipedia.loadingSuggestions' => 'Artikelsvorschläge werden geladen...',
			'createFlight.wikipedia.downloadMapOnly' => 'Karte herunterladen',
			'createFlight.wikipedia.downloadMapPlusOne' => 'Karte + 1 Artikel herunterladen',
			'createFlight.wikipedia.downloadMapPlusMany' => ({required Object count}) => 'Karte + ${count} Artikel herunterladen',
			'createFlight.wikipedia.couldNotOpenLink' => 'Link konnte nicht geöffnet werden',
			'createFlight.downloading.articlesTitle' => 'Ausgewählte Artikel werden heruntergeladen...',
			'createFlight.downloading.mapTitle' => 'Offline-Karte wird heruntergeladen...',
			'createFlight.downloading.mapSectionTitle' => 'Karte',
			'createFlight.downloading.poiSectionTitle' => 'Orte',
			'createFlight.downloading.articlesSectionTitle' => 'Artikel',
			'createFlight.downloading.cancelDownload' => 'Download abbrechen',
			'createFlight.downloading.doNotClose' => 'Schließe diesen Bildschirm nicht, bis der Download abgeschlossen ist',
			'createFlight.downloading.currentStep' => 'Aktuell',
			'createFlight.downloading.pending' => 'Ausstehend',
			'createFlight.downloading.inProgress' => 'In Bearbeitung',
			'createFlight.downloading.completed' => 'Abgeschlossen',
			'createFlight.downloading.completedWithIssues' => 'Mit Problemen abgeschlossen',
			'createFlight.downloading.failed' => 'Fehlgeschlagen',
			'createFlight.downloading.skipped' => 'Übersprungen',
			'createFlight.downloading.waitingForMap' => 'Warte auf Kartendownload...',
			'createFlight.downloading.mapFailed' => 'Kartendownload fehlgeschlagen.',
			'createFlight.downloading.noPoiSelected' => 'Keine Ortszusammenfassungen ausgewählt.',
			'createFlight.downloading.preparingPoi' => 'Ortszusammenfassungen werden vorbereitet...',
			'createFlight.downloading.poiProgress' => ({required Object completed, required Object total}) => 'Orte: ${completed}/${total}',
			'createFlight.downloading.poiProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Orte: ${completed}/${total} (${failed} fehlgeschlagen)',
			'createFlight.downloading.noArticlesSelected' => 'Keine Artikel ausgewählt.',
			'createFlight.downloading.preparingArticles' => 'Artikel-Downloads werden vorbereitet...',
			'createFlight.downloading.articlesProgress' => ({required Object completed, required Object total}) => 'Artikel: ${completed}/${total}',
			'createFlight.downloading.articlesProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Artikel: ${completed}/${total} (${failed} fehlgeschlagen)',
			'createFlight.downloading.preparingMap' => 'Kartendownload wird vorbereitet...',
			'createFlight.downloading.computingTiles' => 'Kartenkacheln werden berechnet...',
			'createFlight.downloading.computingTilesWithCount' => ({required Object count}) => 'Kartenkacheln werden berechnet (${count})...',
			'createFlight.downloading.preparingForDownload' => 'Download wird vorbereitet...',
			'createFlight.downloading.downloaded' => ({required Object size}) => 'Heruntergeladen: ${size}',
			'createFlight.downloading.finalizing' => 'Kartenpaket wird finalisiert...',
			'createFlight.downloading.verifying' => 'Kartenpaket wird überprüft...',
			'createFlight.errors.failedLoadAirports' => 'Flughäfen konnten nicht geladen werden. Bitte versuche es erneut.',
			'createFlight.errors.airportSearchFailed' => 'Flughafensuche fehlgeschlagen. Versuche eine andere Anfrage.',
			'createFlight.errors.someArticlesFailed' => 'Einige Artikel sind fehlgeschlagen. Kartendownload wird fortgesetzt.',
			'createFlight.errors.someOptionalDownloadsFailed' => 'Karte heruntergeladen. Einige optionale Inhalte konnten nicht heruntergeladen werden.',
			'createFlight.errors.failedBuildPreview' => 'Routenvorschau konnte nicht erstellt werden. Bitte versuche es erneut.',
			'createFlight.errors.overviewUnavailableContinue' => 'Routenübersicht konnte nicht geladen werden. Du kannst trotzdem fortfahren.',
			'createFlight.errors.noInternet' => 'Keine Internetverbindung. Bitte prüfe deine Verbindung und versuche es erneut.',
			'createFlight.errors.failedStartDownload' => ({required Object error}) => 'Download konnte nicht gestartet werden: ${error}',
			'createFlight.paywall.upgradeCancelled' => 'Upgrade abgebrochen.',
			'createFlight.paywall.noPaywall' => 'Derzeit keine Bezahlschranke verfügbar.',
			'createFlight.paywall.failedOpenPaywall' => 'Paywall konnte nicht geöffnet werden.',
			'createFlight.realRouteChoice.title' => 'Echte Flugroute holen?',
			'createFlight.realRouteChoice.body' => 'Auf diesem Flug ist jetzt alles freigeschaltet. Er nutzt aber noch eine ungefähre Route — gib deine Flugnummer ein und wir bauen ihn aus dem echten Flugverlauf neu auf.',
			'createFlight.realRouteChoice.ctaEnterFlightNumber' => 'Meine Flugnummer eingeben',
			'createFlight.realRouteChoice.ctaKeepRoute' => 'Ungefähre Route behalten',
			'preview.calculatingRoute' => 'Flugroute wird berechnet...',
			'preview.errorTitle' => 'Fehler',
			'preview.errorSomethingWrong' => 'Etwas ist schiefgelaufen',
			'preview.tryAgain' => 'Erneut versuchen',
			'preview.downloadCongratsTitle' => 'Glückwunsch! Alles ist bereit.',
			'preview.offlineSavedDetail' => 'Karte und ausgewählte Flugdaten wurden für die Offline-Nutzung während deines Flugs gespeichert.',
			'preview.downloadCompletedTitle' => 'Download abgeschlossen',
			'preview.shareFlightCard' => 'Zeig deinen großartigen Flug',
			'preview.shareVideo' => 'Flugvideo teilen',
			'preview.shareVideoNewBadge' => 'NEU',
			'preview.share' => 'Flugkarte teilen',
			'preview.home' => 'Start',
			'preview.navigatingHome' => 'Zur Startseite...',
			'preview.downloadingMapTitle' => 'Ressourcen werden heruntergeladen',
			'preview.cancelDownload' => 'Download abbrechen',
			'preview.download' => 'Herunterladen',
			'preview.flightRoute' => ({required Object distance}) => 'Flugroute (~ ${distance})',
			'flight.tabMap' => 'Karte',
			'flight.tabDashboard' => 'Dashboard',
			'flight.tabRoute' => 'Route',
			'flight.tabRead' => 'Lesen',
			'flight.tabCamera' => 'Kamera',
			'flight.tabInfo' => 'Info',
			'flight.completeDialogTitle' => 'Flug abschließen?',
			'flight.completeDialogBody' => 'Damit wird dein Flug als abgeschlossen markiert.',
			'flight.completeDialogDeleteOffline' => 'Karte und Offline-Artikel löschen',
			'flight.completeDialogConfirm' => 'Abschließen',
			'flight.deleteDialogTitle' => 'Bist du sicher?',
			'flight.deleteDialogMessage' => ({required Object size}) => 'Dadurch wird dieser Flug dauerhaft gelöscht, einschließlich Offline-Karte und gespeicherter Offline-Artikel.\n\nWiedergewonnener Speicherplatz: ${size}.',
			'flight.yes' => 'Ja',
			'flight.shareRoute' => 'Route teilen',
			'flight.copyRoute' => 'Route kopieren',
			'flight.deleteFlight' => 'Flug löschen',
			'flight.routeSummaryCopied' => 'Routenzusammenfassung kopiert',
			'flight.deleted' => 'Flug gelöscht',
			'flight.deleteError' => ({required Object error}) => 'Fehler beim Löschen des Flugs: ${error}',
			'flight.map.initializing' => 'Karte wird geladen',
			'flight.map.loadingStyle' => 'Karte wird geladen',
			'flight.map.offlineNotAvailable' => 'Offline-Karte ist für diesen Flug nicht verfügbar.',
			'flight.map.offlineMissing' => 'Offline-Kartendatei fehlt. Bitte lade diese Route erneut herunter.',
			'flight.map.validationFailed' => 'Validierung der Offline-Karte fehlgeschlagen. Bitte lade diese Route erneut herunter.',
			'flight.map.loadStyleFailed' => 'Offline-Kartenstil konnte nicht geladen werden.',
			'flight.map.sunriseInMinutes' => ({required Object minutes}) => 'Sonnenaufgang in ${minutes} Min',
			'flight.map.sunsetInMinutes' => ({required Object minutes}) => 'Sonnenuntergang in ${minutes} Min',
			'flight.map.switchTo2D' => 'Zu 2D wechseln',
			'flight.map.switchTo3D' => 'Zu 3D wechseln',
			'flight.map.switchToLightMapStyle' => 'Zum hellen Kartenstil wechseln',
			'flight.map.switchToDarkMapStyle' => 'Zum dunklen Kartenstil wechseln',
			'flight.map.uncenterMap' => 'Karte nicht zentrieren',
			'flight.map.centerOnMe' => 'Auf mich zentrieren',
			'flight.dashboard.gpsOffTitle' => 'Standortdienste sind deaktiviert',
			'flight.dashboard.gpsOffSubtitle' => 'Aktiviere die Standortdienste in den Systemeinstellungen, um Live-Flugverfolgung und Kartenverfolgung fortzusetzen.',
			'flight.dashboard.openLocationSettings' => 'Standorteinstellungen öffnen',
			'flight.dashboard.permissionTitle' => 'Standortberechtigung erforderlich',
			'flight.dashboard.permissionSubtitle' => 'Erlaube den Standortzugriff, damit das Dashboard Live-Kurs, Geschwindigkeit und Höhe anzeigen kann.',
			'flight.dashboard.grantPermissions' => 'Berechtigungen erteilen',
			'flight.dashboard.gpsAccuracy' => ({required Object label, required Object accuracy}) => 'GPS-Genauigkeit: ${label} (±${accuracy} m)',
			'flight.dashboard.accuracyExcellent' => 'Ausgezeichnet',
			'flight.dashboard.accuracyGood' => 'Gut',
			'flight.dashboard.accuracyPoor' => 'Schlecht',
			'flight.dashboard.gpsOff' => 'GPS aus',
			'flight.dashboard.gpsOffHint' => 'Aktiviere die Standortdienste, um die Verfolgung zu starten.',
			'flight.dashboard.gpsPermissionRequired' => 'GPS-Berechtigung erforderlich',
			'flight.dashboard.gpsPermissionHint' => 'Erteile die Berechtigung, um auf Live-Flugdaten zuzugreifen.',
			'flight.dashboard.gpsSearching' => 'GPS wird gesucht',
			'flight.dashboard.gpsSearchingHint' => 'Suche nach einem zuverlässigen Signal',
			'flight.dashboard.gpsSearchingHintWithAge' => ({required Object age}) => 'Suche nach GPS. Letzter Fix ${age}.',
			'flight.dashboard.gpsWeak' => 'Schwaches GPS-Signal',
			'flight.dashboard.gpsWeakHint' => 'Das Signal ist instabil. Halte das Gerät unter freiem Himmel.',
			'flight.dashboard.gpsWeakHintWithAge' => ({required Object age}) => 'Signal instabil. Letzter Fix ${age}.',
			'flight.dashboard.gpsActive' => 'GPS aktiv',
			'flight.dashboard.gpsActiveHint' => 'Live-Telemetrie wird empfangen.',
			'flight.dashboard.gpsActiveHintWithAge' => ({required Object age}) => 'Letztes GPS-Update ${age}.',
			'flight.dashboard.gpsShowingLastKnownData' => 'Letzte bekannte Daten werden angezeigt',
			'flight.dashboard.gpsHelpTooltip' => 'GPS-Fehlerbehebung',
			'flight.dashboard.gpsHelpTitle' => 'GPS-Fehlerbehebung',
			'flight.dashboard.gpsHelpBody' => 'Es sieht so aus, als sei das GPS-Signal auf deinem Telefon nicht zuverlässig.',
			'flight.dashboard.gpsHelpStepsTitle' => 'Versuche Folgendes',
			'flight.dashboard.gpsHelpTipLocation' => 'Stelle sicher, dass die Standortdienste aktiviert sind',
			'flight.dashboard.gpsHelpTipWindow' => 'Bewege dein Telefon näher ans Fenster',
			'flight.dashboard.gpsHelpTipCase' => 'Entferne dicke Hüllen oder Metallzubehör',
			'flight.dashboard.gpsHelpTipFlat' => 'Halte dein Telefon kurz ruhig',
			'flight.dashboard.gpsHelpFooter' => 'Die Live-Verfolgung wird automatisch fortgesetzt, sobald sich das Signal stabilisiert.',
			'flight.dashboard.ageJustNow' => 'gerade eben',
			'flight.dashboard.ageSeconds' => ({required Object seconds}) => 'vor ${seconds} s',
			'flight.dashboard.ageMinutes' => ({required Object minutes}) => 'vor ${minutes} Min',
			'flight.dashboard.signalGood' => 'Gut',
			'flight.dashboard.signalPoor' => 'Schlecht',
			'flight.dashboard.signalBad' => 'Sehr schlecht',
			'flight.dashboard.signalSearching' => 'Suche',
			'flight.dashboard.gpsQuality' => ({required Object quality}) => 'GPS ${quality}',
			'flight.dashboard.gpsSearchingLabel' => 'GPS-Suche',
			'flight.dashboard.gpsPermissionNeededLabel' => 'GPS-Berechtigung nötig',
			'flight.dashboard.gpsOffLabel' => 'GPS aus',
			'flight.dashboard.aircraftHeading' => 'Flugzeugkurs',
			'flight.dashboard.headingShort' => ({required Object heading}) => 'KURS ${heading}°',
			'flight.dashboard.liveInstruments' => 'Live-Instrumente',
			'flight.dashboard.groundSpeed' => 'Bodengeschwindigkeit',
			'flight.dashboard.altitudeMsl' => 'Höhe über Meer',
			'flight.dashboard.outsideAirApprox' => 'Außentemperatur',
			'flight.dashboard.temperatureAvailableAfter' => ({required Object threshold}) => 'Verfügbar nach ${threshold}',
			'flight.dashboard.temperatureApproxHint' => 'Grober Schätzwert basierend auf der Höhe',
			'flight.dashboard.headingPanel' => 'Kurs',
			'flight.dashboard.flightPhaseTaxi' => 'Rollen',
			'flight.dashboard.flightPhaseGroundRoll' => 'Bodenlauf',
			'flight.dashboard.flightPhaseTakeoffRoll' => 'Startlauf',
			'flight.dashboard.flightPhaseLandingRoll' => 'Landelauf',
			'flight.dashboard.flightPhaseAscending' => 'Steigend',
			'flight.dashboard.flightPhaseCruising' => 'Reiseflug',
			'flight.dashboard.flightPhaseDescending' => 'Sinkend',
			'flight.dashboard.acquiringGpsSignal' => 'GPS-Signal wird erfasst',
			'flight.dashboard.acquiringGpsHint' => 'Halte das Gerät ruhig und unter freiem Himmel für einen zuverlässigen Fix.',
			'flight.dashboard.weakSignalBanner' => 'Schwaches GPS-Signal. Werte können abweichen, bis sich die Genauigkeit verbessert.',
			'flight.dashboard.preparingDashboard' => 'Dashboard wird vorbereitet...',
			'flight.dashboard.navigation' => 'Navigation',
			'flight.dashboard.heading' => ({required Object heading}) => 'Kurs ${heading}',
			'flight.dashboard.routeProgress' => 'Routenfortschritt',
			'flight.dashboard.covered' => 'Zurückgelegt',
			'flight.dashboard.remaining' => 'Verbleibend',
			'flight.dashboard.total' => 'Gesamt',
			'flight.upcoming.mapTitle' => 'Starte deine Flugreise',
			'flight.upcoming.mapSubtitle' => 'Starte die Live-Verfolgung, sobald dein Flug beginnt',
			'flight.upcoming.dashboardTitle' => 'Starte deine Flugreise',
			'flight.upcoming.dashboardSubtitle' => 'Beginne, um dein Live-Dashboard zu sehen',
			'flight.upcoming.checkInButton' => 'Starten',
			'flight.upcoming.checkInSuccess' => 'Flug gestartet',
			'flight.upcoming.checkInError' => 'Konnte jetzt nicht gestartet werden. Bitte versuche es erneut',
			'flight.info.overviewTitle' => 'Übersicht',
			'flight.info.overviewLoading' => 'Routenübersicht wird erstellt...',
			'flight.info.overviewEmpty' => 'Für diese Route ist noch keine Übersicht verfügbar.',
			'flight.info.loadingRouteInformation' => 'Routeninformationen werden geladen...',
			'flight.info.flyOverTitle' => 'Highlights deiner Route',
			'flight.info.airportsTitle' => 'Flughäfen',
			'flight.info.departure' => 'Abflug',
			'flight.info.arrival' => 'Ankunft',
			'flight.info.showAll' => 'Alle anzeigen',
			'flight.info.showAllCount' => ({required Object count}) => 'Alle ${count} anzeigen',
			'flight.info.showLess' => 'Weniger anzeigen',
			'flight.info.sortByRank' => 'Nach Rang',
			'flight.info.sortByRouteProgress' => 'Nach Route',
			'flight.info.sortByType' => 'Nach Typ',
			'flight.info.routeTimelineTitle' => 'Routen-Zeitachse',
			'flight.info.plannedWaypoints' => ({required Object count}) => '${count} geplante Wegpunkte',
			'flight.info.pointsOfInterestTitle' => 'Sehenswürdigkeiten',
			'flight.info.noPoi' => 'Noch keine POIs verfügbar.',
			'flight.info.poiType' => ({required Object type}) => 'Typ: ${type}',
			'flight.info.poiFlyOver' => ({required Object view}) => 'Überflug: ${view}',
			'flight.info.offlineArticlesTitle' => 'Offline-Artikel',
			'flight.info.regionArticlesTitle' => 'Regionsartikel',
			'flight.info.otherArticlesTitle' => 'Andere Artikel',
			'flight.info.noOfflineArticles' => 'Keine Offline-Artikel heruntergeladen.',
			'flight.info.openSource' => 'Quelle öffnen',
			'flight.info.openSourcePage' => 'Quellseite öffnen',
			'flight.info.openSourcePageTooltip' => 'Quellseite öffnen',
			'flight.info.distanceKm' => ({required Object distance}) => '${distance} km',
			'flight.info.speed' => 'Geschwindigkeit',
			'flight.info.altitude' => 'Höhe',
			'flight.info.copyRouteTitle' => 'Flymap-Route',
			'flight.info.copyRouteCode' => ({required Object routeCode}) => 'Routencode: ${routeCode}',
			'flight.info.copyDistance' => ({required Object distance}) => 'Distanz: ${distance} km',
			'flight.info.copyFrom' => 'Von',
			'flight.info.copyTo' => 'Nach',
			'flight.info.copyCity' => ({required Object city, required Object countryCode}) => 'Stadt: ${city}, ${countryCode}',
			'flight.info.copyAirport' => ({required Object airport}) => 'Flughafen: ${airport}',
			'flight.info.copyCodes' => ({required Object iata, required Object icao}) => 'Codes: IATA ${iata} | ICAO ${icao}',
			'flight.route.loadingRouteTimeline' => 'Routen-Zeitachse wird geladen...',
			'flight.route.noSavedOfflineRegions' => 'Keine gespeicherten Offline-Regionen für diesen Flug.',
			'flight.route.currentProgress' => ({required Object percentage, required Object minute}) => 'Aktueller Fortschritt: ${percentage}% (etwa ${minute} nach dem Start)',
			'flight.route.nowLabel' => 'Jetzt',
			'flight.route.currentRegionLabel' => 'Aktuell',
			'flight.route.nextRegionLabel' => 'Nächste',
			'flight.route.arrivingLabel' => 'Anflug',
			'flight.route.arrivedLabel' => 'Angekommen',
			'flight.route.etaLabel' => ({required Object time}) => 'ETA: ${time}',
			'flight.route.etaInLabel' => ({required Object time}) => 'in ${time}',
			'flight.route.flyingOverLabel' => 'Du fliegst über:',
			'flight.route.premiumLockedChipLabel' => 'Freischalten',
			'flight.route.premiumGateTitle' => 'Vollständige Routen-Zeitachse freischalten',
			'flight.route.premiumGateBody' => 'Upgrade auf Pro, um alle Regionen entlang deiner Route und Details der Zeitachse zu sehen.',
			'flight.route.premiumGateBodyWithCount' => ({required Object count}) => 'Schalte alle ${count} Regionen dieser Route mit Premium frei.',
			'flight.route.premiumGateCta' => 'Zu Pro upgraden',
			'flight.route.premiumOfflineTitle' => 'Internet für Upgrade erforderlich',
			'flight.route.premiumOfflineBody' => 'Du bist gerade offline. Stelle eine Internetverbindung her, um upzugraden und die vollständige Routenansicht freizuschalten.',
			'flight.route.nextHintLabel' => ({required Object region, required Object eta}) => 'Als Nächstes: ${region} (${eta})',
			'flight.route.etaUnknownLabel' => 'wird geschätzt...',
			'shareFlight.title' => 'Flug teilen',
			'shareFlight.preparingMap' => 'Vorschaukarte wird vorbereitet...',
			'shareFlight.preparingScreenshot' => 'Screenshot wird vorbereitet...',
			'shareFlight.share' => 'Teilen',
			'shareFlight.route' => 'Route',
			'shareFlight.offlineMapMissing' => 'Offline-Karte fehlt. Online-Stil wird verwendet.',
			'shareFlight.offlineStyleFailed' => 'Offline-Stil konnte nicht geladen werden. Online-Stil wird verwendet.',
			'shareFlight.captureFailed' => 'Routen-Screenshot konnte nicht erstellt werden',
			'shareFlight.shareFailed' => 'Routen-Screenshot konnte nicht geteilt werden',
			'shareFlight.shareText' => ({required Object from, required Object to}) => 'Flugroute ${from}-${to}',
			'shareFlight.watermark' => 'Flymap',
			'shareFlight.flightDistance' => 'Flugdistanz',
			'shareFlight.distanceKm' => ({required Object distance}) => '${distance} km',
			'shareImage.title' => 'Flug teilen',
			'shareImage.generating' => 'Deine Flugkarte wird erstellt...',
			'shareImage.share' => 'Teilen',
			'shareImage.sharing' => 'Wird geteilt...',
			'shareImage.retry' => 'Erneut versuchen',
			'shareImage.error' => 'Flugkarte konnte nicht erstellt werden',
			'shareImage.tagline' => 'Jeder Flug ist eine Entdeckung',
			'shareImage.brand' => 'Flymap',
			'shareImage.exploreYourFlight' => 'Entdecke deinen Flug',
			'shareImage.countrySingle' => '1 Land',
			'shareImage.countries' => ({required Object count}) => '${count} Länder',
			'shareImage.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) auf Flymap ✈️',
			'shareImage.unknownCity' => 'Unbekannt',
			'shareImage.durationUnavailable' => '--',
			'shareImage.durationMinutes' => ({required Object minutes}) => '${minutes} Min',
			'shareImage.durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} Std ${minutes} Min',
			'flightVideo.title' => 'Flugvideo',
			'flightVideo.preparing' => 'Karte wird vorbereitet...',
			'flightVideo.rendering' => 'Dein Video wird erstellt...',
			'flightVideo.export' => 'Video speichern',
			'flightVideo.savedToGallery' => 'In deiner Galerie gespeichert',
			'flightVideo.saveSkipped' => 'Speichern in der Galerie nicht möglich — du kannst es trotzdem teilen',
			'flightVideo.share' => 'Teilen',
			'flightVideo.sharing' => 'Wird geteilt...',
			'flightVideo.retry' => 'Erneut versuchen',
			'flightVideo.errorNetwork' => 'Kartenbilder konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.',
			'flightVideo.errorGeneric' => 'Flugvideo konnte nicht erstellt werden',
			'flightVideo.errorOfflineTitle' => 'Du bist offline',
			'flightVideo.errorOffline' => 'Flugvideos laden aktuelle Kartenbilder und brauchen daher eine Internetverbindung. Deaktiviere den Flugmodus oder verbinde dich neu und versuche es erneut.',
			'flightVideo.offlineStyleChange' => 'Für einen Wechsel des Kartenstils ist eine Verbindung nötig.',
			'flightVideo.madeWith' => 'Erstellt mit Flymap',
			'flightVideo.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) auf Flymap ✈️',
			'flightVideo.removeWatermark' => 'Wasserzeichen entfernen',
			'flightVideo.styleSatellite' => 'Satellit',
			'flightVideo.styleDefault' => 'Standard',
			'flightVideo.videoSettings' => 'Video-Einstellungen',
			'flightVideo.mapStyle' => 'Kartenstil',
			'flightVideo.mysteryDestination' => 'Geheimes Ziel',
			'flightVideo.mysteryDestinationHint' => '"?" anzeigen, bis das Flugzeug landet',
			'flightVideo.showPins' => 'Länder-Pins',
			'flightVideo.showPinsHint' => 'Setzt eine Markierung, wenn das Flugzeug ein Land überquert',
			'flightVideo.showEndCard' => 'Übersichtskarte',
			'flightVideo.showEndCardHint' => 'Übersichtskarte am Ende anzeigen',
			'flightVideo.styleShine' => 'Lè Shine',
			'flightVideo.applySettings' => 'Änderungen anwenden',
			'flightVideo.applying' => 'Änderungen werden angewendet...',
			'flightVideo.avatarTitle' => 'Dein Avatar',
			'flightVideo.avatarHint' => 'Fliege deine Route mit deinem eigenen Foto',
			'flightVideo.avatarSetupTitle' => 'Dein Avatar',
			'flightVideo.avatarPick' => 'Foto wählen',
			'flightVideo.avatarChange' => 'Foto ändern',
			'flightVideo.avatarNameLabel' => 'Name oder @Handle',
			'flightVideo.avatarNameHint' => 'Optional – auf der Zusammenfassungskarte sichtbar',
			'flightVideo.avatarSave' => 'Avatar speichern',
			'flightVideo.mysteryTitle' => 'Rate, wohin ich fliege? ✈️',
			'flightVideo.avatarCardTagline' => 'Meine Flugkarte',
			'about.title' => 'Über Flymap',
			'about.tagline' => 'Mach aus jedem Flug ein Fenster zur Welt.',
			'about.chipCuriosity' => 'Neugier',
			'about.chipGeography' => 'Geografie',
			'about.chipAwareness' => 'Bewusstsein',
			'about.missionTitle' => 'Warum Flymap',
			'about.missionText' => 'Wir fliegen über Ozeane, Berge und ganze Länder, ohne es je zu wissen. Flymap holt das Staunen zurück.',
			'about.valuesTitle' => 'Wofür wir stehen',
			'about.valueCuriosityTitle' => 'Neugier',
			'about.valueCuriosityText' => 'Wisse immer, was unter dir liegt.',
			'about.valueGeographyTitle' => 'Geografie',
			'about.valueGeographyText' => 'Die Welt wird zum lebendigen Atlas.',
			'about.valueAwarenessTitle' => 'Bewusstsein',
			'about.valueAwarenessText' => 'Verbinde dich wieder mit der Reise.',
			'about.valueOfflineTitle' => 'Offline & privat',
			'about.valueOfflineText' => 'Auf deinem Gerät. Nichts wird getrackt.',
			'about.closingTitle' => 'Sieh die Welt mit neuen Augen',
			'about.closingText' => 'Danke, dass du sie mit uns erkundest.',
			'onboarding.skip' => 'Überspringen',
			'onboarding.letsStart' => 'Los geht’s',
			'onboarding.welcomeTitle' => 'Entdecke, was unter dir liegt',
			'onboarding.welcomeSubtitle' => 'zeigt dir Offline-Karten und interessante Orte entlang deines Flugs',
			'onboarding.nameTitle' => 'Wähle einen Benutzernamen',
			'onboarding.nameSubtitle' => 'Mache Entdeckungen persönlicher. Du kannst ihn jederzeit ändern.',
			'onboarding.nameHint' => 'Dein Name',
			'onboarding.nameExample' => 'Alex',
			'onboarding.frequencyTitle' => 'Wie oft fliegst du?',
			'onboarding.frequencySubtitle' => 'Flymap personalisiert dein Erlebnis und macht Vorschläge relevanter',
			'onboarding.frequencyFirstFlight' => 'Das ist mein erster Flug',
			'onboarding.frequencyFewPerYear' => 'Ein paar Mal pro Jahr',
			'onboarding.frequencyMonthly' => 'Ungefähr monatlich',
			'onboarding.frequencyFrequent' => 'Sehr oft',
			'onboarding.homeAirportTitle' => 'Lege deinen Heimatflughafen fest',
			'onboarding.homeAirportSubtitle' => 'Schnellere Flugplanung. Du kannst ihn jederzeit ändern.',
			'onboarding.homeAirportHint' => 'Heimatflughafen suchen',
			'onboarding.popularAirports' => 'Beliebte Flughäfen',
			'onboarding.removeHomeAirport' => 'Heimatflughafen entfernen',
			'onboarding.noHomeAirportFound' => 'Für diese Suche wurden keine Flughäfen gefunden.',
			'onboarding.interestsTitle' => 'Welche Orte möchtest du häufiger auf deiner Karte sehen?',
			'onboarding.interestsSubtitle' => 'Wähle bis zu 3 Themen, um relevantere Orte und Geschichten entlang deines Flugs zu sehen.',
			'onboarding.interestsHelper' => 'Wähle bis zu 3 Themen.',
			'onboarding.interestsSelected' => ({required Object count, required Object max}) => '${count} von ${max} ausgewählt',
			'onboarding.interestMountains' => 'Berge & Grate',
			'onboarding.interestVolcanoes' => 'Vulkane & Geologie',
			'onboarding.interestRegions' => 'Städte & Regionen',
			'onboarding.interestIslands' => 'Inseln & Küstenlinien',
			'onboarding.interestNationalParks' => 'Nationalparks & Reservate',
			'onboarding.interestRivers' => 'Flüsse & Seen',
			'onboarding.planFirstFlight' => 'Meinen ersten Flug planen',
			'onboarding.failedLoadProfile' => 'Dein Profil konnte nicht geladen werden.',
			'onboarding.payoff.title' => ({required Object airport}) => 'Orte rund um ${airport}, die du nicht verpassen solltest',
			'onboarding.payoff.subtitle' => 'Du fliegst jedes Mal direkt darüber hinweg — halte auf deinem nächsten Flug Ausschau:',
			'onboarding.payoff.scanning' => ({required Object airport}) => 'Wir scannen den Himmel rund um ${airport}…',
			'onboarding.payoff.moreNearby' => ({required Object count}) => '…und ${count}+ weitere Orte in der Nähe:',
			'onboarding.payoff.fallbackTitle' => 'Verpasse nie wieder, was unter dir liegt',
			'onboarding.payoff.fallbackSubtitle' => 'Jeder Flug führt über Vulkane, Berge, Inseln und Seen, die die meisten Reisenden nie bemerken. Flymap zeigt dir, was vor deinem Fenster liegt.',
			'countries.AE' => 'Vereinigte Arabische Emirate',
			'countries.AF' => 'Afghanistan',
			'countries.AG' => 'Antigua und Barbuda',
			'countries.AL' => 'Albanien',
			'countries.AM' => 'Armenien',
			'countries.AO' => 'Angola',
			'countries.AR' => 'Argentinien',
			'countries.AT' => 'Österreich',
			'countries.AU' => 'Australien',
			'countries.AZ' => 'Aserbaidschan',
			'countries.BA' => 'Bosnien und Herzegowina',
			'countries.BB' => 'Barbados',
			'countries.BD' => 'Bangladesch',
			'countries.BE' => 'Belgien',
			'countries.BF' => 'Burkina Faso',
			'countries.BG' => 'Bulgarien',
			'countries.BH' => 'Bahrain',
			'countries.BI' => 'Burundi',
			'countries.BJ' => 'Benin',
			'countries.BN' => 'Brunei Darussalam',
			'countries.BO' => 'Bolivien',
			'countries.BR' => 'Brasilien',
			'countries.BS' => 'Bahamas',
			'countries.BT' => 'Bhutan',
			'countries.BW' => 'Botswana',
			'countries.BY' => 'Belarus',
			'countries.BZ' => 'Belize',
			'countries.CA' => 'Kanada',
			'countries.CD' => 'Kongo, Demokratische Republik',
			'countries.CF' => 'Zentralafrikanische Republik',
			'countries.CG' => 'Kongo',
			'countries.CH' => 'Schweiz',
			'countries.CI' => 'Côte d\'Ivoire',
			'countries.CL' => 'Chile',
			'countries.CM' => 'Kamerun',
			'countries.CN' => 'China',
			'countries.CO' => 'Kolumbien',
			'countries.CR' => 'Costa Rica',
			'countries.CU' => 'Kuba',
			'countries.CV' => 'Kap Verde',
			'countries.CY' => 'Zypern',
			'countries.CZ' => 'Tschechien',
			'countries.DE' => 'Deutschland',
			'countries.DJ' => 'Dschibuti',
			'countries.DK' => 'Dänemark',
			'countries.DO' => 'Dominikanische Republik',
			'countries.DZ' => 'Algerien',
			'countries.EC' => 'Ecuador',
			'countries.EE' => 'Estland',
			'countries.EG' => 'Ägypten',
			'countries.EH' => 'Westsahara',
			'countries.ER' => 'Eritrea',
			'countries.ES' => 'Spanien',
			'countries.ET' => 'Äthiopien',
			'countries.FI' => 'Finnland',
			'countries.FJ' => 'Fidschi',
			'countries.FR' => 'Frankreich',
			'countries.GA' => 'Gabun',
			'countries.GB' => 'Vereinigtes Königreich',
			'countries.GE' => 'Georgien',
			'countries.GF' => 'Französisch-Guayana',
			'countries.GH' => 'Ghana',
			'countries.GM' => 'Gambia',
			'countries.GN' => 'Guinea',
			'countries.GP' => 'Guadeloupe',
			'countries.GQ' => 'Äquatorialguinea',
			'countries.GR' => 'Griechenland',
			'countries.GT' => 'Guatemala',
			'countries.GW' => 'Guinea-Bissau',
			'countries.GY' => 'Guyana',
			'countries.HK' => 'Hongkong, China',
			'countries.HN' => 'Honduras',
			'countries.HR' => 'Kroatien',
			'countries.HT' => 'Haiti',
			'countries.HU' => 'Ungarn',
			'countries.ID' => 'Indonesien',
			'countries.IE' => 'Irland',
			'countries.IL' => 'Israel',
			'countries.IN' => 'Indien',
			'countries.IQ' => 'Irak',
			'countries.IR' => 'Iran',
			'countries.IS' => 'Island',
			'countries.IT' => 'Italien',
			'countries.JM' => 'Jamaika',
			'countries.JO' => 'Jordanien',
			'countries.JP' => 'Japan',
			'countries.KE' => 'Kenia',
			'countries.KG' => 'Kirgisistan',
			'countries.KH' => 'Kambodscha',
			'countries.KM' => 'Komoren',
			'countries.KP' => 'Nordkorea',
			'countries.KR' => 'Südkorea',
			'countries.KW' => 'Kuwait',
			'countries.KZ' => 'Kasachstan',
			'countries.LA' => 'Laos',
			'countries.LB' => 'Libanon',
			'countries.LK' => 'Sri Lanka',
			'countries.LR' => 'Liberia',
			'countries.LS' => 'Lesotho',
			'countries.LT' => 'Litauen',
			'countries.LU' => 'Luxemburg',
			'countries.LV' => 'Lettland',
			'countries.LY' => 'Libyen',
			'countries.MA' => 'Marokko',
			'countries.MD' => 'Moldau',
			'countries.ME' => 'Montenegro',
			'countries.MG' => 'Madagaskar',
			'countries.MK' => 'Nordmazedonien',
			'countries.ML' => 'Mali',
			'countries.MM' => 'Myanmar',
			'countries.MN' => 'Mongolei',
			'countries.MO' => 'Macao, China',
			'countries.MQ' => 'Martinique',
			'countries.MR' => 'Mauretanien',
			'countries.MU' => 'Mauritius',
			'countries.MV' => 'Malediven',
			'countries.MW' => 'Malawi',
			'countries.MT' => 'Malta',
			'countries.MX' => 'Mexiko',
			'countries.MY' => 'Malaysia',
			'countries.MZ' => 'Mosambik',
			'countries.NA' => 'Namibia',
			'countries.NC' => 'Neukaledonien',
			'countries.NE' => 'Niger',
			'countries.NG' => 'Nigeria',
			'countries.NI' => 'Nicaragua',
			'countries.NL' => 'Niederlande',
			'countries.NO' => 'Norwegen',
			'countries.NP' => 'Nepal',
			'countries.NZ' => 'Neuseeland',
			'countries.OM' => 'Oman',
			'countries.PA' => 'Panama',
			'countries.PE' => 'Peru',
			'countries.PG' => 'Papua-Neuguinea',
			'countries.PH' => 'Philippinen',
			_ => null,
		} ?? switch (path) {
			'countries.PK' => 'Pakistan',
			'countries.PL' => 'Polen',
			'countries.PR' => 'Puerto Rico',
			'countries.PS' => 'Westjordanland und Gazastreifen',
			'countries.PT' => 'Portugal',
			'countries.PY' => 'Paraguay',
			'countries.QA' => 'Katar',
			'countries.RE' => 'Réunion',
			'countries.RO' => 'Rumänien',
			'countries.RS' => 'Serbien',
			'countries.RU' => 'Russische Föderation',
			'countries.RW' => 'Ruanda',
			'countries.SA' => 'Saudi-Arabien',
			'countries.SB' => 'Salomonen',
			'countries.SD' => 'Sudan',
			'countries.SE' => 'Schweden',
			'countries.SG' => 'Singapur',
			'countries.SI' => 'Slowenien',
			'countries.SK' => 'Slowakei',
			'countries.SL' => 'Sierra Leone',
			'countries.SN' => 'Senegal',
			'countries.SO' => 'Somalia',
			'countries.SR' => 'Suriname',
			'countries.SS' => 'Südsudan',
			'countries.ST' => 'São Tomé und Príncipe',
			'countries.SV' => 'El Salvador',
			'countries.SY' => 'Syrien',
			'countries.SZ' => 'Eswatini',
			'countries.TD' => 'Tschad',
			'countries.TG' => 'Togo',
			'countries.TH' => 'Thailand',
			'countries.TJ' => 'Tadschikistan',
			'countries.TL' => 'Timor-Leste',
			'countries.TM' => 'Turkmenistan',
			'countries.TN' => 'Tunesien',
			'countries.TR' => 'Türkei',
			'countries.TT' => 'Trinidad und Tobago',
			'countries.TW' => 'Taiwan, China',
			'countries.TZ' => 'Tansania',
			'countries.UA' => 'Ukraine',
			'countries.UG' => 'Uganda',
			'countries.US' => 'Vereinigte Staaten',
			'countries.UY' => 'Uruguay',
			'countries.UZ' => 'Usbekistan',
			'countries.VE' => 'Venezuela',
			'countries.VI' => 'Amerikanische Jungferninseln',
			'countries.VN' => 'Vietnam',
			'countries.YE' => 'Jemen',
			'countries.ZA' => 'Südafrika',
			'countries.ZM' => 'Sambia',
			'countries.ZW' => 'Simbabwe',
			_ => null,
		};
	}
}
