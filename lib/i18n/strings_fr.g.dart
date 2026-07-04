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
class TranslationsFr extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Flymap';
	@override late final _TranslationsCommonFr common = _TranslationsCommonFr._(_root);
	@override late final _TranslationsHomeFr home = _TranslationsHomeFr._(_root);
	@override late final _TranslationsSkyCameraFr skyCamera = _TranslationsSkyCameraFr._(_root);
	@override late final _TranslationsMediaFr media = _TranslationsMediaFr._(_root);
	@override late final _TranslationsLearnFr learn = _TranslationsLearnFr._(_root);
	@override late final _TranslationsSettingsFr settings = _TranslationsSettingsFr._(_root);
	@override late final _TranslationsSubscriptionFr subscription = _TranslationsSubscriptionFr._(_root);
	@override late final _TranslationsCreateFlightFr createFlight = _TranslationsCreateFlightFr._(_root);
	@override late final _TranslationsPreviewFr preview = _TranslationsPreviewFr._(_root);
	@override late final _TranslationsFlightFr flight = _TranslationsFlightFr._(_root);
	@override late final _TranslationsShareFlightFr shareFlight = _TranslationsShareFlightFr._(_root);
	@override late final _TranslationsShareImageFr shareImage = _TranslationsShareImageFr._(_root);
	@override late final _TranslationsAboutFr about = _TranslationsAboutFr._(_root);
	@override late final _TranslationsOnboardingFr onboarding = _TranslationsOnboardingFr._(_root);
	@override late final _TranslationsCountriesFr countries = _TranslationsCountriesFr._(_root);
}

// Path: common
class _TranslationsCommonFr extends TranslationsCommonEn {
	_TranslationsCommonFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get kContinue => 'Continuer';
	@override String get back => 'Retour';
	@override String get cancel => 'Annuler';
	@override String get ok => 'OK';
	@override String get retry => 'Réessayer';
	@override String get manage => 'Gérer';
	@override String get edit => 'Modifier';
	@override String get upgrade => 'Passer à Pro';
	@override String get loading => 'Chargement...';
	@override String get readMore => 'Lire la suite';
	@override String get pro => 'PRO';
	@override String get search => 'Rechercher';
	@override String get debug => 'Debug';
}

// Path: home
class _TranslationsHomeFr extends TranslationsHomeEn {
	_TranslationsHomeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Accueil';
	@override String get aboutTooltip => 'À propos';
	@override String get settingsTooltip => 'Réglages';
	@override String get tabFlights => 'Vols';
	@override String get tabLearn => 'Apprendre';
	@override String get tabMedia => 'Médias';
	@override String get openSkyCamera => 'Ouvrir Sky Camera';
	@override String get loadingFlights => 'Chargement des vols...';
	@override String get failedToLoadFlights => 'Échec du chargement des vols';
	@override String get newFlight => 'Nouveau vol';
	@override String get addFirstFlight => 'Ajouter le premier vol';
	@override String get addNextFlight => 'Ajouter le vol suivant';
	@override String get welcomeTitle => 'Bienvenue sur Flymap';
	@override String get welcomeTitlePro => 'Bienvenue sur Flymap Pro';
	@override String get welcomeSubtitle => 'Cartes hors ligne pour les vols';
	@override String get greetingOnline => 'Prêt pour le prochain vol ?';
	@override String greetingOnlineWithName({required Object name}) => 'Salut ${name}, prêt pour le prochain vol ?';
	@override String get greetingOffline => 'Prêt à explorer votre vol ?';
	@override String greetingOfflineWithName({required Object name}) => 'Salut ${name}, prêt à explorer votre vol ?';
	@override String get greetingInProgress => 'Votre vol est en cours';
	@override String greetingInProgressWithName({required Object name}) => 'Salut ${name}, votre vol est en cours';
	@override String get totalFlights => 'Vols totaux';
	@override String get storageUsed => 'Stockage utilisé';
	@override String get totalDistance => 'Distance totale';
	@override String upcomingFlightsCount({required Object count}) => 'Vols à venir (${count})';
	@override String get flightInProgressTitle => 'Vol en cours';
	@override String get noFlightsTitle => 'Prêt à explorer le monde depuis le ciel ?';
	@override String get noFlightsSubtitle => 'Ajoutez votre premier vol et commencez à découvrir votre prochain voyage.';
	@override String get noFlightsTitleNext => 'Prêt pour votre prochain voyage ?';
	@override String get noFlightsSubtitleNext => 'Vos vols terminés sont dans l’historique. Ajoutez votre prochain vol pour continuer.';
	@override String get flightActions => 'Actions du vol';
	@override String get viewAll => 'Voir tout';
	@override String get open => 'Ouvrir';
	@override String get shareRoute => 'Partager l’itinéraire';
	@override String get completeFlight => 'Archiver le vol';
	@override String get deleteFlight => 'Supprimer le vol';
	@override String get failedDeleteFlight => 'Échec de la suppression du vol';
	@override String get noOfflineMap => 'Aucune carte hors ligne';
	@override String placesCount({required Object count}) => '${count} lieux';
	@override String offlineArticlesCount({required Object count}) => '${count} articles';
	@override String savedTime({required Object time}) => 'Enregistré ${time}';
	@override String get justNow => 'À l’instant';
	@override String daysAgo({required Object days}) => 'Il y a ${days} j';
	@override String hoursAgo({required Object hours}) => 'Il y a ${hours} h';
	@override String minutesAgo({required Object minutes}) => 'Il y a ${minutes} min';
	@override late final _TranslationsHomeSortFr sort = _TranslationsHomeSortFr._(_root);
}

// Path: skyCamera
class _TranslationsSkyCameraFr extends TranslationsSkyCameraEn {
	_TranslationsSkyCameraFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Chargement de l’appareil photo...';
	@override String get loadingGpsData => 'Chargement des données GPS';
	@override String get zoom => 'Zoom';
	@override String get flash => 'Flash';
	@override String get cameraUnavailable => 'L’appareil photo n’est pas disponible pour le moment.';
	@override String get cameraPermissionDenied => 'L’accès à l’appareil photo est requis pour prendre des photos.';
	@override String get captureFailed => 'Impossible de prendre la photo pour le moment.';
	@override String get savedMessage => 'Photo enregistrée';
	@override String get share => 'Partager';
	@override String get noActiveFlightTitle => 'Aucun vol actif';
	@override String get noActiveFlightMessage => 'Sky Camera fonctionne sans vol, mais les détails d’itinéraire n’apparaissent que pendant un vol actif.';
	@override String get telemetrySpeed => 'Vitesse';
	@override String get telemetryAltitude => 'Altitude';
	@override String get telemetryHeading => 'Cap';
	@override String get telemetryTime => 'Heure';
	@override String get contextCaption => 'Contexte';
	@override String get mapCaption => 'Carte';
	@override String get coordinatesCaption => 'Coordonnées';
	@override String get noValuePlaceholder => '--';
	@override String get placeholderRoute => 'LHR -> BCN';
	@override String get placeholderOriginCode => 'LHR';
	@override String get placeholderDestinationCode => 'BCN';
	@override String get placeholderContext => 'Mer Méditerranée';
	@override String get placeholderMap => 'Aperçu de l’itinéraire';
}

// Path: media
class _TranslationsMediaFr extends TranslationsMediaEn {
	_TranslationsMediaFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Médias côté hublot';
	@override String get loading => 'Chargement des médias...';
	@override String get failedToLoad => 'Impossible de charger les médias';
	@override String get filesTab => 'Fichiers';
	@override String get flightsTab => 'Vols';
	@override String get emptyTitle => 'Bienvenue dans votre Sky Camera côté hublot';
	@override String get emptySubtitle => 'Capturez et partagez de magnifiques vues depuis votre siège côté hublot avec des données de vol et GPS en surimpression.';
	@override String get emptyFlightsTitle => 'Aucun dossier de vol pour l’instant';
	@override String get emptyFlightsSubtitle => 'Les captures liées aux vols enregistrés apparaîtront ici.';
	@override String get deleteAction => 'Supprimer';
	@override String get share => 'Partager';
	@override String selectedCount({required Object count}) => '${count} sélectionné(s)';
	@override String get groupNoFlight => 'Aucun contexte de vol';
	@override String get groupNoFlightSubtitle => 'Captures prises hors d’un vol actif';
	@override String get groupUnknownFlight => 'Capture de vol';
	@override String get previewTitle => 'Capture';
	@override String captureCount({required Object count}) => '${count} captures';
	@override String get deleteFolder => 'Supprimer le dossier';
	@override String deleteFolders({required Object count}) => 'Supprimer ${count} dossiers';
	@override String get deleteFile => 'Supprimer le fichier';
	@override String deleteFiles({required Object count}) => 'Supprimer ${count} fichiers';
	@override String deleteFolderConfirm({required Object count}) => 'Supprimer ce dossier et ses ${count} fichiers ?';
	@override String deleteFoldersConfirm({required Object count}) => 'Supprimer ${count} dossiers et tous les fichiers qu’ils contiennent ?';
	@override String get deleteFileConfirm => 'Supprimer ce fichier ?';
	@override String deleteFilesConfirm({required Object count}) => 'Supprimer ${count} fichiers ?';
}

// Path: learn
class _TranslationsLearnFr extends TranslationsLearnEn {
	_TranslationsLearnFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get loadingCategories => 'Chargement des catégories...';
	@override String get failedToLoadCategories => 'Échec du chargement des catégories';
	@override String get emptyCategoriesTitle => 'Aucune catégorie pour l’instant';
	@override String get emptyCategoriesSubtitle => 'Les catégories apparaîtront bientôt ici.';
	@override String articlesCount({required Object count}) => '${count} articles';
	@override String get loadingArticles => 'Chargement des articles...';
	@override String get failedToLoadArticles => 'Échec du chargement des articles';
	@override String get emptyArticlesTitle => 'Aucun article pour l’instant';
	@override String get emptyArticlesSubtitle => 'Les articles de cette catégorie apparaîtront bientôt.';
	@override String get upgradeRequiresInternet => 'Le contenu premium est disponible avec Pro. Connectez-vous à Internet pour mettre à niveau.';
	@override String get proListPreviewHint => 'Vous pouvez déjà parcourir ces titres. Débloquez la lecture avec Flymap Pro.';
	@override String get failedToLoadArticle => 'Impossible d’ouvrir cet article pour le moment.';
	@override String get quizzesTitle => 'Quiz';
	@override String get articlesTitle => 'Articles';
	@override late final _TranslationsLearnGeoQuizFr geoQuiz = _TranslationsLearnGeoQuizFr._(_root);
}

// Path: settings
class _TranslationsSettingsFr extends TranslationsSettingsEn {
	_TranslationsSettingsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Réglages';
	@override String get loading => 'Chargement des réglages...';
	@override String get profile => 'Profil';
	@override String get profileSubtitle => 'Nom, habitudes de vol, aéroport de référence et centres d’intérêt';
	@override String profileSummaryNameHome({required Object name, required Object code}) => '${name} · ${code}';
	@override String profileSummaryHome({required Object code}) => 'Aéroport de référence : ${code}';
	@override String get profileEditHint => 'Touchez un élément pour modifier les détails de votre profil.';
	@override String get profileNotSet => 'Non défini';
	@override String profileInterestsSelected({required Object count}) => '${count} sélectionnés';
	@override String get historyTitle => 'Historique';
	@override String get historySubtitle => 'Tous les vols et statistiques';
	@override String get historyLoading => 'Chargement de l’historique...';
	@override String get historyLoadError => 'Échec du chargement de l’historique des vols.';
	@override String get historyFlightsLabel => 'Vols totaux';
	@override String get historyDistanceLabel => 'Distance totale';
	@override String get historyAllFlights => 'Tous les vols';
	@override String get historyStatusUpcoming => 'À venir';
	@override String get historyStatusInProgress => 'En cours';
	@override String get historyStatusCompleted => 'Terminé';
	@override String historyMapChip({required Object size}) => 'Carte ${size}';
	@override String get historyNoMapChip => 'Pas de carte';
	@override String get historySortName => 'Nom';
	@override String get historySortDistance => 'Distance';
	@override String get historySortDate => 'Date';
	@override String get historyEmpty => 'Aucun vol pour l’instant.';
	@override String get historySearchHint => 'Rechercher par aéroport ou ville';
	@override String get historyNoResults => 'Aucun vol correspondant trouvé.';
	@override String get historyDeleteOfflineData => 'Supprimer uniquement la carte';
	@override String get appearance => 'Apparence';
	@override String get language => 'Langue';
	@override String get languageSubtitle => 'Langue de l’application';
	@override String get languageSystem => 'Système';
	@override String languageSystemFormat({required Object language}) => '${language} (Système)';
	@override String get languageEnglish => 'English';
	@override String get languageSpanish => 'Español';
	@override String get languageFrench => 'Français';
	@override String get languageGerman => 'Deutsch';
	@override String get theme => 'Thème';
	@override String get system => 'Système';
	@override String get dark => 'Sombre';
	@override String get light => 'Clair';
	@override String get units => 'Unités';
	@override String get storage => 'Stockage';
	@override String get storageTitle => 'Stockage';
	@override String get storageSubtitle => 'Cartes téléchargées et espace disque';
	@override String get storageLoading => 'Chargement du stockage...';
	@override String get storageLoadError => 'Échec du chargement des données de stockage.';
	@override String get storageMapsLabel => 'Cartes téléchargées';
	@override String get storageTotalSizeLabel => 'Taille totale';
	@override String get storageDownloadedMaps => 'Cartes téléchargées';
	@override String get storageSortName => 'Nom';
	@override String get storageSortSize => 'Taille';
	@override String storageMapSize({required Object size}) => 'Taille : ${size}';
	@override String get storageEmpty => 'Aucune carte téléchargée pour l’instant.';
	@override String get altitude => 'Altitude';
	@override String get altitudeUnit => 'Unité d’altitude';
	@override String get speed => 'Vitesse';
	@override String get speedUnit => 'Unité de vitesse';
	@override String get temperatureUnit => 'Unité de température';
	@override String get timeFormat => 'Format de l’heure';
	@override String get distanceUnit => 'Unité de distance';
	@override String get dateFormat => 'Format de date';
	@override String get support => 'Assistance';
	@override String get about => 'À propos';
	@override String get aboutSubtitle => 'En savoir plus sur l’application';
	@override String get privacyPolicy => 'Politique de confidentialité';
	@override String get privacyPolicySubtitle => 'Lire notre politique de confidentialité';
	@override String get termsOfService => 'Conditions d’utilisation';
	@override String get termsOfServiceSubtitle => 'Lire nos conditions d’utilisation';
	@override String get flymapProActivated => 'Flymap Pro activé.';
	@override String get upgradeCancelled => 'Mise à niveau annulée.';
	@override String get noPaywall => 'Aucun écran de paiement disponible pour le moment.';
	@override String get failedOpenPaywall => 'Impossible d’ouvrir l’écran de paiement.';
	@override String couldNotOpenUrl({required Object url}) => 'Impossible d’ouvrir ${url}';
	@override String get rateUs => 'Noter l’application';
	@override String get rateUsSubtitle => 'Laissez un avis sur la boutique';
	@override String get leaveFeedback => 'Laisser un avis';
	@override String get leaveFeedbackSubtitle => 'Partagez votre avis pour nous aider à nous améliorer';
	@override String get couldNotOpenStorePage => 'Impossible d’ouvrir la page de la boutique';
	@override String get rateDialogTitle => 'Aimez-vous l’application ?';
	@override String get rateDialogBody => 'Nous travaillons dur pour rendre chaque vol plus agréable, et votre retour nous aide vraiment à progresser.';
	@override String get rateDialogYes => 'Oui';
	@override String get rateDialogNo => 'Non';
	@override String get feedbackTitle => 'Laisser un avis';
	@override String get feedbackBody => 'Aidez-nous à rendre Flymap meilleur';
	@override String get feedbackCategoryTitle => 'Type de retour';
	@override String get feedbackCategoryGeneral => 'Général';
	@override String get feedbackCategoryFeatureRequest => 'Demande de fonctionnalité';
	@override String get feedbackCategoryBugReport => 'Rapport de bug';
	@override String get feedbackHint => 'Partagez votre avis...';
	@override String get feedbackEmailHint => 'E-mail (facultatif)';
	@override String get feedbackEmailInvalid => 'Veuillez saisir un e-mail valide ou laisser ce champ vide.';
	@override String get feedbackSend => 'Envoyer';
	@override String get feedbackThanks => 'Merci pour votre retour !';
	@override String get feedbackSendFailed => 'Impossible d’envoyer le message. Veuillez réessayer.';
	@override String get proBannerTitle => 'Flymap Pro';
	@override String get proBannerTitleActive => 'Flymap Pro actif';
	@override String get proBannerSubtitleActive => 'Mode carte détaillé et packs d’articles hors ligne complets débloqués.';
	@override String get proBannerSubtitleFree => 'Débloquez les cartes détaillées et les packs d’articles hors ligne complets';
	@override String get proBannerBadgeActive => 'PRO ACTIF';
}

// Path: subscription
class _TranslationsSubscriptionFr extends TranslationsSubscriptionEn {
	_TranslationsSubscriptionFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Abonnement';
	@override String get contactSupport => 'Contacter l’assistance';
	@override String get cardTitle => 'Flymap Pro';
	@override String get periodTitle => 'Période d’abonnement';
	@override String get renewsOrExpires => 'Renouvelle ou expire';
	@override String get noExpiration => 'Pas d’expiration';
	@override String get lastChecked => 'Dernière vérification';
	@override String get flightUnlockSheetTitle => 'Débloquer les fonctionnalités Pro';
	@override String get flightUnlockOptionTitle => 'Achat unique';
	@override String get flightUnlockOptionBody => 'Débloquez Pro pour un seul vol';
	@override String get flightUnlockAction => 'Acheter pour un vol';
	@override String get flightUnlockUseAction => 'Utiliser pour un vol';
	@override String get flightUnlockPriceLoading => 'Chargement du prix...';
	@override String get flightUnlockProOptionTitle => 'Abonnement Flymap Pro';
	@override String flightUnlockAvailableCount({required Object count}) => '${count} déblocages de vol disponibles';
	@override String get flightUnlockProOptionBody => 'Débloquez Pro pour un nombre illimité de vols';
	@override String get flightUnlockProAction => 'Voir les offres Pro';
	@override String get flightUnlockUnavailable => 'Le déblocage de vol n’est pas disponible pour le moment.';
	@override String get flightUnlockPurchaseCancelled => 'Achat du déblocage annulé.';
	@override String get flightUnlockPurchaseFailed => 'Échec de l’achat du déblocage. Veuillez réessayer.';
	@override String get proFeaturesTitle => 'Ce que débloque Flymap Pro';
	@override String get proFeatureRoutesTitle => 'Aperçus d’itinéraire précis';
	@override String get proFeatureMapsTitle => 'Cartes hors ligne plus détaillées';
	@override String get proFeatureTimelineTitle => 'Timeline complète du trajet';
	@override String get proFeaturePoiTitle => '10 fois plus de lieux sur l’itinéraire';
	@override String get proFeatureArticlesTitle => 'Packs d’articles hors ligne complets';
	@override String get checkingStatus => 'Vérification de l’état de votre abonnement...';
	@override String get freePlan => 'Vous êtes sur le forfait Gratuit.';
	@override String get active => 'Actif';
	@override String get notActive => 'Inactif';
	@override String get unknown => 'Inconnu';
	@override String get manageSubscription => 'Gérer l’abonnement';
	@override String get restorePurchases => 'Restaurer les achats';
	@override String get upgradeToPro => 'Passer à Pro';
	@override String get restoreNoSubscription => 'Aucun abonnement actif trouvé.';
	@override String get supportEmailSubject => 'Assistance abonnement Flymap';
	@override String get couldNotOpenEmailApp => 'Impossible d’ouvrir l’application e-mail';
	@override String get couldNotOpenSubscriptionSettings => 'Impossible d’ouvrir les réglages d’abonnement';
	@override String get proRestored => 'Flymap Pro restauré.';
	@override String get failedOpenPaywall => 'Impossible d’ouvrir l’écran de paiement.';
	@override String get serviceUnavailable => 'Le service d’abonnement est temporairement indisponible.';
}

// Path: createFlight
class _TranslationsCreateFlightFr extends TranslationsCreateFlightEn {
	_TranslationsCreateFlightFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsCreateFlightStepsFr steps = _TranslationsCreateFlightStepsFr._(_root);
	@override late final _TranslationsCreateFlightRouteTypeSelectorFr routeTypeSelector = _TranslationsCreateFlightRouteTypeSelectorFr._(_root);
	@override late final _TranslationsCreateFlightProAccessFr proAccess = _TranslationsCreateFlightProAccessFr._(_root);
	@override late final _TranslationsCreateFlightFlightNumberSearchFr flightNumberSearch = _TranslationsCreateFlightFlightNumberSearchFr._(_root);
	@override late final _TranslationsCreateFlightRealRouteAirportSearchFr realRouteAirportSearch = _TranslationsCreateFlightRealRouteAirportSearchFr._(_root);
	@override late final _TranslationsCreateFlightSearchFr search = _TranslationsCreateFlightSearchFr._(_root);
	@override late final _TranslationsCreateFlightMapPreviewFr mapPreview = _TranslationsCreateFlightMapPreviewFr._(_root);
	@override late final _TranslationsCreateFlightOverviewFr overview = _TranslationsCreateFlightOverviewFr._(_root);
	@override late final _TranslationsCreateFlightWikipediaFr wikipedia = _TranslationsCreateFlightWikipediaFr._(_root);
	@override late final _TranslationsCreateFlightDownloadingFr downloading = _TranslationsCreateFlightDownloadingFr._(_root);
	@override late final _TranslationsCreateFlightErrorsFr errors = _TranslationsCreateFlightErrorsFr._(_root);
	@override late final _TranslationsCreateFlightPaywallFr paywall = _TranslationsCreateFlightPaywallFr._(_root);
}

// Path: preview
class _TranslationsPreviewFr extends TranslationsPreviewEn {
	_TranslationsPreviewFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get calculatingRoute => 'Calcul de l’itinéraire du vol...';
	@override String get errorTitle => 'Erreur';
	@override String get errorSomethingWrong => 'Un problème est survenu';
	@override String get tryAgain => 'Réessayer';
	@override String get downloadCongratsTitle => 'Bravo ! Tout est prêt.';
	@override String get offlineSavedDetail => 'La carte et les données de vol sélectionnées sont enregistrées pour une utilisation hors ligne pendant votre vol.';
	@override String get downloadCompletedTitle => 'Téléchargement terminé';
	@override String get shareFlightCard => 'Partagez votre superbe carte de vol';
	@override String get share => 'Partager la carte de vol';
	@override String get home => 'Accueil';
	@override String get navigatingHome => 'Retour à l’accueil...';
	@override String get downloadingMapTitle => 'Téléchargement des ressources';
	@override String get cancelDownload => 'Annuler le téléchargement';
	@override String get download => 'Télécharger';
	@override String flightRoute({required Object distance}) => 'Itinéraire du vol (~ ${distance})';
}

// Path: flight
class _TranslationsFlightFr extends TranslationsFlightEn {
	_TranslationsFlightFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tabMap => 'Carte';
	@override String get tabDashboard => 'Tableau de bord';
	@override String get tabRoute => 'Itinéraire';
	@override String get tabRead => 'Lire';
	@override String get tabInfo => 'Infos';
	@override String get completeDialogTitle => 'Terminer le vol ?';
	@override String get completeDialogBody => 'Cela marquera votre vol comme terminé.';
	@override String get completeDialogDeleteOffline => 'Supprimer la carte et les articles hors ligne';
	@override String get completeDialogConfirm => 'Terminer';
	@override String get deleteDialogTitle => 'Êtes-vous sûr ?';
	@override String deleteDialogMessage({required Object size}) => 'Cela supprime définitivement ce vol, y compris la carte hors ligne et les articles hors ligne enregistrés.\n\nEspace récupéré : ${size}.';
	@override String get yes => 'Oui';
	@override String get shareRoute => 'Partager l’itinéraire';
	@override String get copyRoute => 'Copier l’itinéraire';
	@override String get deleteFlight => 'Supprimer le vol';
	@override String get routeSummaryCopied => 'Résumé de l’itinéraire copié';
	@override String get deleted => 'Vol supprimé';
	@override String deleteError({required Object error}) => 'Erreur lors de la suppression du vol : ${error}';
	@override late final _TranslationsFlightMapFr map = _TranslationsFlightMapFr._(_root);
	@override late final _TranslationsFlightDashboardFr dashboard = _TranslationsFlightDashboardFr._(_root);
	@override late final _TranslationsFlightUpcomingFr upcoming = _TranslationsFlightUpcomingFr._(_root);
	@override late final _TranslationsFlightInfoFr info = _TranslationsFlightInfoFr._(_root);
	@override late final _TranslationsFlightRouteFr route = _TranslationsFlightRouteFr._(_root);
}

// Path: shareFlight
class _TranslationsShareFlightFr extends TranslationsShareFlightEn {
	_TranslationsShareFlightFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Partager le vol';
	@override String get preparingMap => 'Préparation de la carte de partage...';
	@override String get preparingScreenshot => 'Préparation de la capture d’écran...';
	@override String get share => 'Partager';
	@override String get route => 'Itinéraire';
	@override String get offlineMapMissing => 'Carte hors ligne manquante. Utilisation du style en ligne.';
	@override String get offlineStyleFailed => 'Échec du chargement du style hors ligne. Utilisation du style en ligne.';
	@override String get captureFailed => 'Impossible de capturer la capture d’écran de l’itinéraire';
	@override String get shareFailed => 'Échec du partage de la capture de l’itinéraire';
	@override String shareText({required Object from, required Object to}) => 'Itinéraire du vol ${from}-${to}';
	@override String get watermark => 'Flymap';
	@override String get flightDistance => 'Distance du vol';
	@override String distanceKm({required Object distance}) => '${distance} km';
}

// Path: shareImage
class _TranslationsShareImageFr extends TranslationsShareImageEn {
	_TranslationsShareImageFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Partager le vol';
	@override String get generating => 'Création de votre carte de vol...';
	@override String get share => 'Partager';
	@override String get sharing => 'Partage...';
	@override String get retry => 'Réessayer';
	@override String get error => 'Impossible de générer la carte de vol';
	@override String get tagline => 'Chaque vol est une découverte';
	@override String get brand => 'Flymap';
	@override String get exploreYourFlight => 'Explorez votre vol';
	@override String get countrySingle => '1 pays';
	@override String countries({required Object count}) => '${count} pays';
	@override String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) sur Flymap ✈️';
	@override String get unknownCity => 'Inconnu';
	@override String get durationUnavailable => '--';
	@override String durationMinutes({required Object minutes}) => '${minutes} min';
	@override String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} h ${minutes} min';
}

// Path: about
class _TranslationsAboutFr extends TranslationsAboutEn {
	_TranslationsAboutFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'À propos de Flymap';
	@override String get welcome => 'Bienvenue sur Flymap';
	@override String get intro => 'Flymap garde votre itinéraire visible dans les airs. Planifiez le voyage, téléchargez votre carte au sol et suivez votre vol hors ligne en toute confiance.';
	@override String get chipOffline => 'Carte hors ligne';
	@override String get chipDashboard => 'Tableau de bord en direct';
	@override String get chipSharing => 'Partage d’itinéraire';
	@override String get infoBanner => 'Avant le décollage, téléchargez la carte de votre itinéraire. En mode avion, l’accès Internet peut être limité ou indisponible.';
	@override String get whatYouCanDo => 'Ce que vous pouvez faire';
	@override String get featurePlanTitle => 'Planifiez votre itinéraire';
	@override String get featurePlanText => 'Choisissez les aéroports de départ et d’arrivée, puis prévisualisez le trajet avant le téléchargement.';
	@override String get featureTrackTitle => 'Suivez les données du vol';
	@override String get featureTrackText => 'Utilisez le tableau de bord pour surveiller le cap, la vitesse, l’altitude et la progression de l’itinéraire.';
	@override String get featureDetailsTitle => 'Consultez les détails de l’itinéraire';
	@override String get featureDetailsText => 'Ouvrez l’onglet Infos pour voir les détails des aéroports et un aperçu clair de l’itinéraire.';
	@override String get featureShareTitle => 'Partagez votre voyage';
	@override String get featureShareText => 'Générez et partagez une capture d’écran de la carte de vol avec les points forts du trajet.';
	@override String get quickStart => 'Démarrage rapide';
	@override String get step1 => 'Touchez Nouveau vol sur l’accueil.';
	@override String get step2 => 'Choisissez les aéroports de départ et d’arrivée.';
	@override String get step3 => 'Ouvrez l’aperçu de la carte et téléchargez-la avant le vol.';
	@override String get step4 => 'Ouvrez votre vol et utilisez Carte, Tableau de bord et Infos en l’air.';
	@override String get tips => 'Conseils pour un meilleur GPS';
	@override String get tip1 => 'Pour un meilleur signal GPS, asseyez-vous près d’un hublot.';
	@override String get tip2 => 'Le signal peut chuter au milieu de l’avion. Flymap conserve la dernière vue connue de l’itinéraire pendant la recherche.';
}

// Path: onboarding
class _TranslationsOnboardingFr extends TranslationsOnboardingEn {
	_TranslationsOnboardingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Passer';
	@override String get letsStart => 'Commençons';
	@override String get welcomeTitle => 'Découvrez ce qu’il y a en dessous';
	@override String get welcomeSubtitle => 'vous montre des cartes hors ligne et des lieux intéressants tout au long de votre vol';
	@override String get nameTitle => 'Choisissez un nom d’utilisateur';
	@override String get nameSubtitle => 'Rendez la découverte personnelle. Vous pourrez le changer à tout moment.';
	@override String get nameHint => 'Votre nom';
	@override String get nameExample => 'Alex';
	@override String get frequencyTitle => 'À quelle fréquence prenez-vous l’avion ?';
	@override String get frequencySubtitle => 'Flymap personnalisera votre expérience et rendra les suggestions plus pertinentes';
	@override String get frequencyFirstFlight => 'C’est mon premier vol';
	@override String get frequencyFewPerYear => 'Quelques fois par an';
	@override String get frequencyMonthly => 'Environ chaque mois';
	@override String get frequencyFrequent => 'Très souvent';
	@override String get homeAirportTitle => 'Définissez votre aéroport de référence';
	@override String get homeAirportSubtitle => 'Obtenez une configuration plus rapide des vols. Vous pouvez le modifier à tout moment.';
	@override String get homeAirportHint => 'Rechercher l’aéroport de référence';
	@override String get popularAirports => 'Aéroports populaires';
	@override String get removeHomeAirport => 'Retirer l’aéroport de référence';
	@override String get noHomeAirportFound => 'Aucun aéroport trouvé pour cette recherche.';
	@override String get interestsTitle => 'Quels lieux voulez-vous voir davantage sur une carte ?';
	@override String get interestsSubtitle => 'Choisissez jusqu’à 3 thèmes pour voir des lieux et histoires plus pertinents pendant votre vol.';
	@override String get interestsHelper => 'Choisissez jusqu’à 3 thèmes.';
	@override String interestsSelected({required Object count, required Object max}) => '${count} sur ${max} sélectionnés';
	@override String get interestMountains => 'Montagnes et crêtes';
	@override String get interestVolcanoes => 'Volcans et géologie';
	@override String get interestRegions => 'Villes et régions';
	@override String get interestIslands => 'Îles et côtes';
	@override String get interestNationalParks => 'Parcs nationaux et réserves';
	@override String get interestRivers => 'Rivières et lacs';
	@override String get proTitle => 'Tirez plus de chaque vol';
	@override String get proStepSubtitle => 'Débloquez des cartes détaillées, des lieux et des articles — même hors ligne.';
	@override String get proFeatureMaps => 'Cartes détaillées pour votre vol';
	@override String get proFeatureRoutes => 'Itinéraires de vol les plus précis';
	@override String get proFeaturePlaces => '10x plus de lieux le long de l’itinéraire';
	@override String get proFeatureTimeline => 'Une chronologie détaillée de tout votre vol';
	@override String get proFeatureArticles => 'Pack complet d’articles hors ligne';
	@override String get unlockPro => 'Passer à Pro';
	@override String get continueFree => 'Continuer gratuitement';
	@override String get proActiveTitle => 'Félicitations !';
	@override String get proActiveSubtitle => 'Vous avez maintenant un accès complet aux cartes détaillées, à tous les lieux et aux packs d’articles.';
	@override String get planFirstFlight => 'Planifier mon premier vol';
	@override String get planFirstFlightPro => 'Planifier mon premier vol détaillé';
	@override String get failedLoadProfile => 'Échec du chargement de votre profil.';
}

// Path: countries
class _TranslationsCountriesFr extends TranslationsCountriesEn {
	_TranslationsCountriesFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get AE => 'Émirats arabes unis';
	@override String get AF => 'Afghanistan';
	@override String get AG => 'Antigua-et-Barbuda';
	@override String get AL => 'Albanie';
	@override String get AM => 'Arménie';
	@override String get AO => 'Angola';
	@override String get AR => 'Argentine';
	@override String get AT => 'Autriche';
	@override String get AU => 'Australie';
	@override String get AZ => 'Azerbaïdjan';
	@override String get BA => 'Bosnie-Herzégovine';
	@override String get BB => 'Barbade';
	@override String get BD => 'Bangladesh';
	@override String get BE => 'Belgique';
	@override String get BF => 'Burkina Faso';
	@override String get BG => 'Bulgarie';
	@override String get BH => 'Bahreïn';
	@override String get BI => 'Burundi';
	@override String get BJ => 'Bénin';
	@override String get BN => 'Brunei Darussalam';
	@override String get BO => 'Bolivie';
	@override String get BR => 'Brésil';
	@override String get BS => 'Bahamas';
	@override String get BT => 'Bhoutan';
	@override String get BW => 'Botswana';
	@override String get BY => 'Biélorussie';
	@override String get BZ => 'Belize';
	@override String get CA => 'Canada';
	@override String get CD => 'Congo, République démocratique du';
	@override String get CF => 'République centrafricaine';
	@override String get CG => 'Congo';
	@override String get CH => 'Suisse';
	@override String get CI => 'Côte d\'Ivoire';
	@override String get CL => 'Chili';
	@override String get CM => 'Cameroun';
	@override String get CN => 'Chine';
	@override String get CO => 'Colombie';
	@override String get CR => 'Costa Rica';
	@override String get CU => 'Cuba';
	@override String get CV => 'Cap-Vert';
	@override String get CY => 'Chypre';
	@override String get CZ => 'République tchèque';
	@override String get DE => 'Allemagne';
	@override String get DJ => 'Djibouti';
	@override String get DK => 'Danemark';
	@override String get DO => 'République dominicaine';
	@override String get DZ => 'Algérie';
	@override String get EC => 'Équateur';
	@override String get EE => 'Estonie';
	@override String get EG => 'Égypte';
	@override String get EH => 'Sahara occidental';
	@override String get ER => 'Érythrée';
	@override String get ES => 'Espagne';
	@override String get ET => 'Éthiopie';
	@override String get FI => 'Finlande';
	@override String get FJ => 'Fidji';
	@override String get FR => 'France';
	@override String get GA => 'Gabon';
	@override String get GB => 'Royaume-Uni';
	@override String get GE => 'Géorgie';
	@override String get GF => 'Guyane française';
	@override String get GH => 'Ghana';
	@override String get GM => 'Gambie';
	@override String get GN => 'Guinée';
	@override String get GP => 'Guadeloupe';
	@override String get GQ => 'Guinée équatoriale';
	@override String get GR => 'Grèce';
	@override String get GT => 'Guatemala';
	@override String get GW => 'Guinée-Bissau';
	@override String get GY => 'Guyana';
	@override String get HK => 'Hong Kong, Chine';
	@override String get HN => 'Honduras';
	@override String get HR => 'Croatie';
	@override String get HT => 'Haïti';
	@override String get HU => 'Hongrie';
	@override String get ID => 'Indonésie';
	@override String get IE => 'Irlande';
	@override String get IL => 'Israël';
	@override String get IN => 'Inde';
	@override String get IQ => 'Irak';
	@override String get IR => 'Iran';
	@override String get IS => 'Islande';
	@override String get IT => 'Italie';
	@override String get JM => 'Jamaïque';
	@override String get JO => 'Jordanie';
	@override String get JP => 'Japon';
	@override String get KE => 'Kenya';
	@override String get KG => 'Kirghizistan';
	@override String get KH => 'Cambodge';
	@override String get KM => 'Comores';
	@override String get KP => 'Corée du Nord';
	@override String get KR => 'Corée du Sud';
	@override String get KW => 'Koweït';
	@override String get KZ => 'Kazakhstan';
	@override String get LA => 'Laos';
	@override String get LB => 'Liban';
	@override String get LK => 'Sri Lanka';
	@override String get LR => 'Libéria';
	@override String get LS => 'Lesotho';
	@override String get LT => 'Lituanie';
	@override String get LU => 'Luxembourg';
	@override String get LV => 'Lettonie';
	@override String get LY => 'Libye';
	@override String get MA => 'Maroc';
	@override String get MD => 'Moldavie';
	@override String get ME => 'Monténégro';
	@override String get MG => 'Madagascar';
	@override String get MK => 'Macédoine du Nord';
	@override String get ML => 'Mali';
	@override String get MM => 'Myanmar';
	@override String get MN => 'Mongolie';
	@override String get MO => 'Macao, Chine';
	@override String get MQ => 'Martinique';
	@override String get MR => 'Mauritanie';
	@override String get MU => 'Maurice';
	@override String get MV => 'Maldives';
	@override String get MW => 'Malawi';
	@override String get MT => 'Malte';
	@override String get MX => 'Mexique';
	@override String get MY => 'Malaisie';
	@override String get MZ => 'Mozambique';
	@override String get NA => 'Namibie';
	@override String get NC => 'Nouvelle-Calédonie';
	@override String get NE => 'Niger';
	@override String get NG => 'Nigeria';
	@override String get NI => 'Nicaragua';
	@override String get NL => 'Pays-Bas';
	@override String get NO => 'Norvège';
	@override String get NP => 'Népal';
	@override String get NZ => 'Nouvelle-Zélande';
	@override String get OM => 'Oman';
	@override String get PA => 'Panama';
	@override String get PE => 'Pérou';
	@override String get PG => 'Papouasie-Nouvelle-Guinée';
	@override String get PH => 'Philippines';
	@override String get PK => 'Pakistan';
	@override String get PL => 'Pologne';
	@override String get PR => 'Porto Rico';
	@override String get PS => 'Cisjordanie et bande de Gaza';
	@override String get PT => 'Portugal';
	@override String get PY => 'Paraguay';
	@override String get QA => 'Qatar';
	@override String get RE => 'La Réunion';
	@override String get RO => 'Roumanie';
	@override String get RS => 'Serbie';
	@override String get RU => 'Russie';
	@override String get RW => 'Rwanda';
	@override String get SA => 'Arabie saoudite';
	@override String get SB => 'Îles Salomon';
	@override String get SD => 'Soudan';
	@override String get SE => 'Suède';
	@override String get SG => 'Singapour';
	@override String get SI => 'Slovénie';
	@override String get SK => 'Slovaquie';
	@override String get SL => 'Sierra Leone';
	@override String get SN => 'Sénégal';
	@override String get SO => 'Somalie';
	@override String get SR => 'Suriname';
	@override String get SS => 'Soudan du Sud';
	@override String get ST => 'Sao Tomé-et-Principe';
	@override String get SV => 'Salvador';
	@override String get SY => 'Syrie';
	@override String get SZ => 'Eswatini';
	@override String get TD => 'Tchad';
	@override String get TG => 'Togo';
	@override String get TH => 'Thaïlande';
	@override String get TJ => 'Tadjikistan';
	@override String get TL => 'Timor oriental';
	@override String get TM => 'Turkménistan';
	@override String get TN => 'Tunisie';
	@override String get TR => 'Turquie';
	@override String get TT => 'Trinité-et-Tobago';
	@override String get TW => 'Taïwan, Chine';
	@override String get TZ => 'Tanzanie';
	@override String get UA => 'Ukraine';
	@override String get UG => 'Ouganda';
	@override String get US => 'États-Unis';
	@override String get UY => 'Uruguay';
	@override String get UZ => 'Ouzbékistan';
	@override String get VE => 'Venezuela';
	@override String get VI => 'Îles Vierges américaines';
	@override String get VN => 'Viêt Nam';
	@override String get YE => 'Yémen';
	@override String get ZA => 'Afrique du Sud';
	@override String get ZM => 'Zambie';
	@override String get ZW => 'Zimbabwe';
}

// Path: home.sort
class _TranslationsHomeSortFr extends TranslationsHomeSortEn {
	_TranslationsHomeSortFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get mostRecent => 'Le plus récent';
	@override String get longest => 'Le plus long';
	@override String get alphabetical => 'A-Z';
}

// Path: learn.geoQuiz
class _TranslationsLearnGeoQuizFr extends TranslationsLearnGeoQuizEn {
	_TranslationsLearnGeoQuizFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Geo Quiz';
	@override String get geographyTitle => 'Géographie';
	@override String get geographySubtitle => 'Mers, chaînes de montagnes, lacs, îles et plus';
	@override String get countriesTitle => 'Pays sur la carte';
	@override String get subtitle => 'Devinez le pays d’après sa silhouette';
	@override String get loading => 'Chargement de Geo Quiz...';
	@override String get failedToLoad => 'Échec du chargement des quiz';
	@override String get failedToLoadQuiz => 'Échec du chargement du quiz';
	@override String get emptyTitle => 'Aucun quiz pour l’instant';
	@override String get emptySubtitle => 'Les geo quiz apparaîtront bientôt ici.';
	@override String get countryHint => 'Nom de la région...';
	@override String progressCount({required Object solved, required Object total}) => '${solved} / ${total}';
	@override String nextCount({required Object next, required Object total}) => '${next} sur ${total}';
	@override String correctCount({required Object count}) => '${count} corrects';
	@override String get reset => 'Réinitialiser la progression';
	@override String get mapPlaceholder => 'Les données de carte seront ajoutées ensuite';
	@override String get newBadge => 'NOUVEAU';
	@override String get correct => 'Correct';
	@override String get wrong => 'Incorrect';
	@override String get hintTitle => 'Indice';
	@override String get hintSubtitle => 'Touchez une lettre pour la révéler';
	@override String get next => 'Suivant';
	@override String get pause => 'Pause';
	@override String get resume => 'Reprendre';
	@override String get finish => 'Terminer';
	@override String get completeTitle => 'Quiz terminé';
	@override String completeMessage({required Object total, required Object quiz}) => 'Vous avez trouvé les ${total} pays de ${quiz}.';
	@override String get backToQuizzes => 'Retour aux quiz';
	@override String get playAgain => 'Rejouer';
	@override String get progressReady => 'Prêt à jouer';
	@override String progressFinished({required Object count}) => '${count} terminés';
	@override String progressInProgress({required Object count}) => '${count} en cours';
	@override String get progressAllCompleted => 'Tous terminés';
	@override String get quizCountriesAfricaTitle => 'Afrique';
	@override String get quizCountriesEuropeTitle => 'Europe';
	@override String get quizCountriesAsiaTitle => 'Asie';
	@override String get quizCountriesNorthAmericaTitle => 'Amérique du Nord';
	@override String get quizCountriesSouthAmericaTitle => 'Amérique du Sud';
	@override String get quizCountriesOceaniaTitle => 'Océanie';
	@override String get quizCountriesAllTitle => 'Tous les pays';
	@override String get quizCountriesSubtitle => 'Pays';
	@override String get quizCountriesAllSubtitle => 'Monde';
	@override String get quizGeographySeasTitle => 'Mers';
	@override String get quizGeographyMountainRangesTitle => 'Chaînes de montagnes';
	@override String get quizGeographyLakesTitle => 'Lacs';
	@override String get quizGeographyIslandsTitle => 'Îles';
	@override String get quizGeographyOtherTitle => 'Autres';
	@override String get quizGeographyOtherSubtitle => 'Baies, détroits, golfes, déserts et plus';
	@override String get descriptionUnavailable => 'La description n’est pas encore disponible.';
}

// Path: createFlight.steps
class _TranslationsCreateFlightStepsFr extends TranslationsCreateFlightStepsEn {
	_TranslationsCreateFlightStepsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get departureTitle => 'Choisir l’aéroport de départ';
	@override String get arrivalTitle => 'Choisir l’aéroport d’arrivée';
	@override String get routeNotSupportedTitle => 'Itinéraire non pris en charge';
	@override String get mapPreviewTitle => 'Aperçu de la carte';
	@override String get overviewTitle => 'Aperçu de l’itinéraire';
	@override String get wikipediaTitle => 'Articles Wikipédia';
}

// Path: createFlight.routeTypeSelector
class _TranslationsCreateFlightRouteTypeSelectorFr extends TranslationsCreateFlightRouteTypeSelectorEn {
	_TranslationsCreateFlightRouteTypeSelectorFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nouveau vol';
	@override String get basicTitle => 'Itinéraire approximatif';
	@override String get basicSubtitle => 'Depuis les aéroports';
	@override String get basicDescription => 'Fonctionne bien pour les vols courts et de nombreux moyen-courriers.';
	@override String get proTitle => 'Itinéraire réel';
	@override String get proSubtitle => 'Depuis des vols récents';
	@override String get proDescription => 'Construit à partir de l’itinéraire le plus récemment enregistré pour ce même vol.';
	@override String get mostAccurate => 'Le plus précis';
}

// Path: createFlight.proAccess
class _TranslationsCreateFlightProAccessFr extends TranslationsCreateFlightProAccessEn {
	_TranslationsCreateFlightProAccessFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get subscriber => 'Flymap Pro';
	@override String get subscriberBody => 'Ce vol bénéficie d’un accès Pro complet grâce à votre abonnement Flymap Pro.';
	@override String get unlockedFlight => 'Ce vol est débloqué';
	@override String get unlockedFlightBody => 'Toutes les fonctionnalités Pro sont activées pour ce vol.';
	@override String get tooltip => 'Infos d’accès Pro';
}

// Path: createFlight.flightNumberSearch
class _TranslationsCreateFlightFlightNumberSearchFr extends TranslationsCreateFlightFlightNumberSearchEn {
	_TranslationsCreateFlightFlightNumberSearchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Numéro de vol';
	@override String get subtitle => 'Saisissez un numéro de vol (par exemple BA117).';
	@override String get hint => 'ex. BA117';
	@override String get loading => 'Recherche de votre vol';
	@override String get invalidFormatError => 'Saisissez un numéro de vol valide, comme BA117.';
	@override String get notFoundError => 'Nous n’avons pas trouvé ce numéro de vol. Vérifiez-le et réessayez, ou recherchez par aéroports.';
	@override String get rateLimitedError => 'Il y a trop de recherches de vols en ce moment. Réessayez dans un instant, ou recherchez par aéroports.';
	@override String get providerUnavailableError => 'Les données de vol sont temporairement indisponibles. Réessayez dans un instant, ou recherchez par aéroports.';
	@override String get unexpectedError => 'Une erreur s’est produite lors de la recherche de ce vol. Réessayez, ou recherchez par aéroports.';
	@override String get findByAirports => 'Trouver par aéroports';
	@override String get airportsFallbackButton => 'Trouver par aéroports';
	@override String get confirmTitle => 'Confirmer le vol';
	@override String get foundTitle => 'Nous avons trouvé votre vol';
	@override String get basedOnSameFlightOn => '* Basé sur l’itinéraire enregistré le plus récent pour ce même vol';
}

// Path: createFlight.realRouteAirportSearch
class _TranslationsCreateFlightRealRouteAirportSearchFr extends TranslationsCreateFlightRealRouteAirportSearchEn {
	_TranslationsCreateFlightRealRouteAirportSearchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trouver des vols réels par aéroports';
	@override String get subtitle => 'Choisissez les aéroports de départ et d’arrivée pour rechercher des vols réels récents sur cet itinéraire.';
	@override String get searchAction => 'Rechercher des vols récents';
	@override String get loading => 'Recherche de vols réels récents';
	@override String get loadingHint => 'Cela peut prendre quelques secondes pendant que nous vérifions l’historique récent de l’itinéraire.';
	@override String sorryNoFlightFromTo({required Object departure, required Object arrival}) => 'Désolé, nous n’avons trouvé aucun vol de ${departure} à ${arrival}.';
	@override String get emptyTitle => 'Nous n’avons trouvé aucun vol récent entre ces aéroports';
	@override String get emptyResults => 'Assurez-vous d’avoir sélectionné les mêmes aéroports de départ et d’arrivée que sur votre billet d’avion.';
	@override String get rateLimitedError => 'Il y a trop de recherches de vols en ce moment. Réessayez dans un instant.';
	@override String get providerUnavailableError => 'Les données de vols réels sont temporairement indisponibles. Réessayez dans un instant.';
	@override String get unexpectedError => 'Une erreur s’est produite lors de la recherche de cet itinéraire. Réessayez.';
	@override String get foundOneTitle => '1 vol trouvé';
	@override String foundManyTitle({required Object count}) => '${count} vols trouvés';
	@override String get ticketMatchHint => 'Assurez-vous qu’ils correspondent aux aéroports indiqués sur votre billet d’avion.';
	@override String get findByFlightNumber => 'Trouver par numéro de vol';
}

// Path: createFlight.search
class _TranslationsCreateFlightSearchFr extends TranslationsCreateFlightSearchEn {
	_TranslationsCreateFlightSearchFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get departureHint => 'Rechercher l\'aéroport de départ';
	@override String get arrivalHint => 'Rechercher l\'aéroport d\'arrivée';
	@override String get removeFavorite => 'Retirer des favoris';
	@override String get addFavorite => 'Ajouter aux favoris';
	@override String get removeSelectedAirport => 'Retirer l’aéroport sélectionné';
	@override String get favorites => 'Favoris';
	@override String get recentAirports => 'Aéroports récents';
	@override String get popularAirports => 'Aéroports populaires';
	@override String get removeFromFavorites => 'Retirer des favoris';
	@override String get noDepartureFound => 'Aucun aéroport de départ trouvé.';
	@override String get noArrivalFound => 'Aucun aéroport d’arrivée trouvé.';
	@override String airportCodeCity({required Object code, required Object city}) => '${code} · ${city}';
	@override String airportNameCode({required Object name, required Object code}) => '${name} (${code})';
}

// Path: createFlight.mapPreview
class _TranslationsCreateFlightMapPreviewFr extends TranslationsCreateFlightMapPreviewEn {
	_TranslationsCreateFlightMapPreviewFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get routeNotSupportedMsg => 'Désolé, les vols traversant l’antiméridien ne sont pas encore pris en charge.';
	@override String get basic => 'Basique';
	@override String get pro => 'Pro';
	@override String get mapDetailInfoTooltip => 'Note sur l’itinéraire';
	@override String get legendButton => 'Légende';
	@override String get legendTitle => 'Légende des points d’intérêt';
	@override String estimatedMapSize({required Object size}) => 'Taille estimée de la carte : ${size}';
	@override String get upgradeToPro => 'Passer à Pro';
	@override String get basicHint => 'Détail de carte basique avec des lieux limités';
	@override String get proGateHint => 'Passez à Pro pour une carte détaillée avec tous les lieux';
	@override String proHint({required Object count}) => 'Carte hors ligne détaillée avec ${count} lieux';
	@override String get optionsTitle => 'Itinéraire approximatif';
	@override String get optionsBody => 'L’itinéraire est approximatif — le trajet réel peut varier, surtout sur les vols long-courriers.';
}

// Path: createFlight.overview
class _TranslationsCreateFlightOverviewFr extends TranslationsCreateFlightOverviewEn {
	_TranslationsCreateFlightOverviewFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get routeNotReady => 'L’itinéraire n’est pas encore prêt.';
	@override String get proPoiUpsell => 'Le forfait Gratuit comprend une carte basique et un nombre limité de lieux';
	@override String get routeNoteTooltip => 'Note sur l’itinéraire';
	@override String get routeNoteTitle => 'Itinéraire approximatif';
	@override String get routeNoteBody => 'L’itinéraire est approximatif — le trajet réel peut varier, surtout sur les vols long-courriers.';
	@override String get realRouteNoteTitle => 'Itinéraire réel';
	@override String get realRouteNoteBody => 'Cet itinéraire est basé sur l’itinéraire enregistré le plus récent pour ce même vol.\nLe routage réel peut varier en fonction de la météo, du trafic aérien et des contraintes opérationnelles.';
	@override String get approximateRouteLongHaulWarningTitle => 'Cet itinéraire est approximatif';
	@override String get approximateRouteLongHaulWarningBody => 'Les itinéraires approximatifs peuvent être inexacts pour les vols long-courriers. Utilisez plutôt un itinéraire réel avec un numéro de vol.';
	@override String get approximateRouteUltraLongHaulUnsupportedBody => 'Les itinéraires approximatifs ne sont pas pris en charge pour les vols ultra long-courriers. Utilisez plutôt un itinéraire réel avec un numéro de vol.';
	@override String get startReview => 'Commencer la revue';
	@override String get skipReview => 'Passer';
	@override String get premiumGateTitle => 'Débloquez l’aperçu complet de l’itinéraire';
	@override String get premiumGateBody => 'Le forfait Gratuit inclut un aperçu limité de l’itinéraire. Passez à Pro pour voir chaque région de cet itinéraire.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Débloquez les ${count} régions de cet itinéraire avec Pro.';
	@override String get premiumGateCta => 'Passer à Pro';
	@override String get routeReviewedTitle => 'Itinéraire revu';
	@override String routeReviewedSubtitle({required Object regions, required Object departure, required Object arrival}) => 'Vous survolerez ${regions} de ${departure} à ${arrival}.';
	@override String get fullSummary => 'Résumé complet';
	@override String get routeSummaryTitle => 'Résumé de l’itinéraire';
	@override String get routeSummaryDistanceLabel => 'Distance';
	@override String get routeSummaryDurationLabel => 'Durée';
	@override String get routeSummaryRegionsLabel => 'Régions';
	@override String get routeSummaryRegionsTitle => 'Vous survolerez';
	@override String get routeSummaryPlacesLabel => 'Lieux';
	@override String get routeSummaryTimelineTitle => 'Chronologie';
	@override String get routeSummaryPlacesTitle => 'Lieux le long de l’itinéraire';
	@override String get routeSummaryPoiSearchHint => 'Rechercher des lieux';
	@override String get routeSummaryPoiNoMatches => 'Aucun lieu ne correspond à votre recherche.';
	@override late final _TranslationsCreateFlightOverviewAirportCardFr airportCard = _TranslationsCreateFlightOverviewAirportCardFr._(_root);
	@override late final _TranslationsCreateFlightOverviewRegionInfoFr regionInfo = _TranslationsCreateFlightOverviewRegionInfoFr._(_root);
	@override late final _TranslationsCreateFlightOverviewTimelineFr timeline = _TranslationsCreateFlightOverviewTimelineFr._(_root);
}

// Path: createFlight.wikipedia
class _TranslationsCreateFlightWikipediaFr extends TranslationsCreateFlightWikipediaEn {
	_TranslationsCreateFlightWikipediaFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Téléchargez des articles et lisez-les pendant que vous êtes en l’air';
	@override String get loadingIntro => 'Recherche d’articles liés à l’itinéraire...';
	@override String foundIntro({required Object count}) => 'D’après votre itinéraire, nous avons trouvé ${count} articles pertinents';
	@override String get emptyIntro => 'Aucun article Wikipédia lié à l’itinéraire n’a été trouvé. Vous pouvez continuer avec le téléchargement de la carte uniquement.';
	@override String selectedCount({required Object count}) => '${count} sélectionnés';
	@override String get unselectAll => 'Tout désélectionner';
	@override String get selectAll => 'Tout sélectionner';
	@override String basicHint({required Object count}) => 'Articles hors ligne sélectionnés : ${count}';
	@override String get proHint => 'Carte et pack de données hors ligne';
	@override String get proGateHint => 'Passez à Pro pour le pack complet d’articles hors ligne';
	@override String get proActiveTitle => 'Pro actif';
	@override String get proActiveMessage => 'Pack complet d’articles débloqué.';
	@override String get freeLimitHint => 'Le forfait Gratuit inclut jusqu’à 3 articles hors ligne';
	@override String estimatedDownloadSize({required Object size}) => 'Taille estimée du téléchargement : ${size}';
	@override String get upgrade => 'Passer à Pro';
	@override String get loadingSuggestions => 'Chargement des suggestions d’articles...';
	@override String get downloadMapOnly => 'Télécharger la carte';
	@override String get downloadMapPlusOne => 'Télécharger la carte + 1 article';
	@override String downloadMapPlusMany({required Object count}) => 'Télécharger la carte + ${count} articles';
	@override String get couldNotOpenLink => 'Impossible d’ouvrir le lien';
}

// Path: createFlight.downloading
class _TranslationsCreateFlightDownloadingFr extends TranslationsCreateFlightDownloadingEn {
	_TranslationsCreateFlightDownloadingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get articlesTitle => 'Téléchargement des articles sélectionnés...';
	@override String get mapTitle => 'Téléchargement de la carte hors ligne...';
	@override String get mapSectionTitle => 'Carte';
	@override String get poiSectionTitle => 'Lieux';
	@override String get articlesSectionTitle => 'Articles';
	@override String get cancelDownload => 'Annuler le téléchargement';
	@override String get doNotClose => 'Ne fermez pas cet écran avant la fin du téléchargement';
	@override String get currentStep => 'En cours';
	@override String get pending => 'En attente';
	@override String get inProgress => 'En cours';
	@override String get completed => 'Terminé';
	@override String get completedWithIssues => 'Terminé avec des problèmes';
	@override String get failed => 'Échec';
	@override String get skipped => 'Ignoré';
	@override String get waitingForMap => 'En attente du téléchargement de la carte...';
	@override String get mapFailed => 'Le téléchargement de la carte a échoué.';
	@override String get noPoiSelected => 'Aucun résumé de lieu sélectionné.';
	@override String get preparingPoi => 'Préparation des résumés de lieux...';
	@override String poiProgress({required Object completed, required Object total}) => 'Lieux : ${completed}/${total}';
	@override String poiProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Lieux : ${completed}/${total} (${failed} échecs)';
	@override String get noArticlesSelected => 'Aucun article sélectionné.';
	@override String get preparingArticles => 'Préparation des téléchargements d’articles...';
	@override String articlesProgress({required Object completed, required Object total}) => 'Articles : ${completed}/${total}';
	@override String articlesProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Articles : ${completed}/${total} (${failed} échecs)';
	@override String get preparingMap => 'Préparation du téléchargement de la carte...';
	@override String get computingTiles => 'Calcul des tuiles de carte...';
	@override String computingTilesWithCount({required Object count}) => 'Calcul des tuiles de carte (${count})...';
	@override String get preparingForDownload => 'Préparation du téléchargement...';
	@override String downloaded({required Object size}) => 'Téléchargé : ${size}';
	@override String get finalizing => 'Finalisation du pack de cartes...';
	@override String get verifying => 'Vérification du pack de cartes...';
}

// Path: createFlight.errors
class _TranslationsCreateFlightErrorsFr extends TranslationsCreateFlightErrorsEn {
	_TranslationsCreateFlightErrorsFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get failedLoadAirports => 'Échec du chargement des aéroports. Veuillez réessayer.';
	@override String get airportSearchFailed => 'La recherche d’aéroport a échoué. Essayez une autre requête.';
	@override String get someArticlesFailed => 'Certains articles ont échoué. Le téléchargement de la carte continue.';
	@override String get someOptionalDownloadsFailed => 'Carte téléchargée. Certains contenus facultatifs n’ont pas pu être téléchargés.';
	@override String get failedBuildPreview => 'Échec de la création de l’aperçu de l’itinéraire. Veuillez réessayer.';
	@override String get overviewUnavailableContinue => 'Impossible de charger l’aperçu de l’itinéraire. Vous pouvez quand même continuer.';
	@override String get noInternet => 'Aucune connexion Internet. Vérifiez votre connexion et réessayez.';
	@override String failedStartDownload({required Object error}) => 'Échec du démarrage du téléchargement : ${error}';
}

// Path: createFlight.paywall
class _TranslationsCreateFlightPaywallFr extends TranslationsCreateFlightPaywallEn {
	_TranslationsCreateFlightPaywallFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get upgradeCancelled => 'Mise à niveau annulée.';
	@override String get noPaywall => 'Aucun écran de paiement disponible pour le moment.';
	@override String get failedOpenPaywall => 'Impossible d’ouvrir l’écran de paiement.';
}

// Path: flight.map
class _TranslationsFlightMapFr extends TranslationsFlightMapEn {
	_TranslationsFlightMapFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get initializing => 'Chargement de la carte';
	@override String get loadingStyle => 'Chargement de la carte';
	@override String get offlineNotAvailable => 'La carte hors ligne n’est pas disponible pour ce vol.';
	@override String get offlineMissing => 'Le fichier de carte hors ligne est manquant. Veuillez retélécharger cet itinéraire.';
	@override String get validationFailed => 'La validation de la carte hors ligne a échoué. Veuillez retélécharger cet itinéraire.';
	@override String get loadStyleFailed => 'Impossible de charger le style de la carte hors ligne.';
	@override String sunriseInMinutes({required Object minutes}) => 'Lever du soleil dans ${minutes} min';
	@override String sunsetInMinutes({required Object minutes}) => 'Coucher du soleil dans ${minutes} min';
	@override String get switchTo2D => 'Passer en 2D';
	@override String get switchTo3D => 'Passer en 3D';
	@override String get switchToLightMapStyle => 'Passer au style de carte clair';
	@override String get switchToDarkMapStyle => 'Passer au style de carte sombre';
	@override String get uncenterMap => 'Décentrer la carte';
	@override String get centerOnMe => 'Me centrer';
}

// Path: flight.dashboard
class _TranslationsFlightDashboardFr extends TranslationsFlightDashboardEn {
	_TranslationsFlightDashboardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get gpsOffTitle => 'Les services de localisation sont désactivés';
	@override String get gpsOffSubtitle => 'Activez les services de localisation dans les réglages système pour reprendre le suivi du vol en direct et le suivi de la carte.';
	@override String get openLocationSettings => 'Ouvrir les réglages de localisation';
	@override String get permissionTitle => 'Autorisation de localisation requise';
	@override String get permissionSubtitle => 'Autorisez l’accès à la localisation pour que le tableau de bord puisse afficher le cap, la vitesse et l’altitude en direct.';
	@override String get grantPermissions => 'Accorder les autorisations';
	@override String gpsAccuracy({required Object label, required Object accuracy}) => 'Précision GPS : ${label} (±${accuracy} m)';
	@override String get accuracyExcellent => 'Excellente';
	@override String get accuracyGood => 'Bonne';
	@override String get accuracyPoor => 'Faible';
	@override String get gpsOff => 'GPS désactivé';
	@override String get gpsOffHint => 'Activez les services de localisation pour commencer le suivi.';
	@override String get gpsPermissionRequired => 'Autorisation GPS requise';
	@override String get gpsPermissionHint => 'Accordez l’autorisation pour accéder à la télémétrie du vol en direct.';
	@override String get gpsSearching => 'Recherche du GPS';
	@override String get gpsSearchingHint => 'Recherche d’un signal fiable';
	@override String gpsSearchingHintWithAge({required Object age}) => 'Recherche du GPS. Dernier point ${age}.';
	@override String get gpsWeak => 'Signal GPS faible';
	@override String get gpsWeakHint => 'Le signal est instable. Gardez l’appareil sous un ciel dégagé.';
	@override String gpsWeakHintWithAge({required Object age}) => 'Signal instable. Dernier point ${age}.';
	@override String get gpsActive => 'GPS actif';
	@override String get gpsActiveHint => 'Réception de la télémétrie en direct.';
	@override String gpsActiveHintWithAge({required Object age}) => 'Dernière mise à jour GPS ${age}.';
	@override String get gpsShowingLastKnownData => 'Affichage des dernières données connues';
	@override String get gpsHelpTooltip => 'Dépannage GPS';
	@override String get gpsHelpTitle => 'Dépannage GPS';
	@override String get gpsHelpBody => 'Il semble que le signal GPS ne soit pas fiable sur votre téléphone.';
	@override String get gpsHelpStepsTitle => 'Essayez ceci';
	@override String get gpsHelpTipLocation => 'Assurez-vous que les services de localisation sont activés';
	@override String get gpsHelpTipWindow => 'Approchez votre téléphone d’une fenêtre';
	@override String get gpsHelpTipCase => 'Retirez les coques épaisses ou accessoires métalliques';
	@override String get gpsHelpTipFlat => 'Tenez votre téléphone immobile pendant quelques instants';
	@override String get gpsHelpFooter => 'Le suivi en direct reprend automatiquement une fois le signal stabilisé.';
	@override String get ageJustNow => 'à l’instant';
	@override String ageSeconds({required Object seconds}) => 'il y a ${seconds} s';
	@override String ageMinutes({required Object minutes}) => 'il y a ${minutes} min';
	@override String get signalGood => 'Bon';
	@override String get signalPoor => 'Faible';
	@override String get signalBad => 'Mauvais';
	@override String get signalSearching => 'Recherche';
	@override String gpsQuality({required Object quality}) => 'GPS ${quality}';
	@override String get gpsSearchingLabel => 'Recherche GPS';
	@override String get gpsPermissionNeededLabel => 'Autorisation GPS nécessaire';
	@override String get gpsOffLabel => 'GPS désactivé';
	@override String get aircraftHeading => 'Cap de l’avion';
	@override String headingShort({required Object heading}) => 'CAP ${heading}°';
	@override String get liveInstruments => 'Instruments en direct';
	@override String get groundSpeed => 'Vitesse au sol';
	@override String get altitudeMsl => 'Altitude AMSL';
	@override String get outsideAirApprox => 'Température extérieure';
	@override String temperatureAvailableAfter({required Object threshold}) => 'Disponible après ${threshold}';
	@override String get temperatureApproxHint => 'Estimation approximative basée sur l’altitude';
	@override String get headingPanel => 'Cap';
	@override String get flightPhaseTaxi => 'Roulage';
	@override String get flightPhaseGroundRoll => 'Course au sol';
	@override String get flightPhaseTakeoffRoll => 'Course de décollage';
	@override String get flightPhaseLandingRoll => 'Course d’atterrissage';
	@override String get flightPhaseAscending => 'Montée';
	@override String get flightPhaseCruising => 'Croisière';
	@override String get flightPhaseDescending => 'Descente';
	@override String get acquiringGpsSignal => 'Acquisition du signal GPS';
	@override String get acquiringGpsHint => 'Gardez l’appareil stable et sous un ciel dégagé pour obtenir un point fiable.';
	@override String get weakSignalBanner => 'Signal GPS faible. Les valeurs peuvent dériver jusqu’à l’amélioration de la précision.';
	@override String get preparingDashboard => 'Préparation du tableau de bord...';
	@override String get navigation => 'Navigation';
	@override String heading({required Object heading}) => 'Cap ${heading}';
	@override String get routeProgress => 'Progression sur l’itinéraire';
	@override String get covered => 'Parcouru';
	@override String get remaining => 'Restant';
	@override String get total => 'Total';
}

// Path: flight.upcoming
class _TranslationsFlightUpcomingFr extends TranslationsFlightUpcomingEn {
	_TranslationsFlightUpcomingFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get mapTitle => 'Commencez votre voyage';
	@override String get mapSubtitle => 'Lancez le suivi en direct quand votre vol commence';
	@override String get dashboardTitle => 'Commencez votre voyage';
	@override String get dashboardSubtitle => 'Commencez pour voir votre tableau de bord en direct';
	@override String get checkInButton => 'Démarrer';
	@override String get checkInSuccess => 'Vol démarré';
	@override String get checkInError => 'Impossible de démarrer maintenant. Veuillez réessayer';
}

// Path: flight.info
class _TranslationsFlightInfoFr extends TranslationsFlightInfoEn {
	_TranslationsFlightInfoFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get overviewTitle => 'Aperçu';
	@override String get overviewLoading => 'Création de l’aperçu de l’itinéraire...';
	@override String get overviewEmpty => 'L’aperçu n’est pas encore disponible pour cet itinéraire.';
	@override String get loadingRouteInformation => 'Chargement des informations sur l’itinéraire...';
	@override String get flyOverTitle => 'Points forts de votre itinéraire';
	@override String get airportsTitle => 'Aéroports';
	@override String get departure => 'Départ';
	@override String get arrival => 'Arrivée';
	@override String get showAll => 'Afficher tout';
	@override String showAllCount({required Object count}) => 'Afficher les ${count}';
	@override String get showLess => 'Afficher moins';
	@override String get sortByRank => 'Par rang';
	@override String get sortByRouteProgress => 'Par itinéraire';
	@override String get sortByType => 'Par type';
	@override String get routeTimelineTitle => 'Chronologie de l’itinéraire';
	@override String plannedWaypoints({required Object count}) => '${count} points de passage prévus';
	@override String get pointsOfInterestTitle => 'Points d’intérêt';
	@override String get noPoi => 'Aucun point d’intérêt disponible pour le moment.';
	@override String poiType({required Object type}) => 'Type : ${type}';
	@override String poiFlyOver({required Object view}) => 'Survol : ${view}';
	@override String get offlineArticlesTitle => 'Articles hors ligne';
	@override String get regionArticlesTitle => 'Articles de région';
	@override String get otherArticlesTitle => 'Autres articles';
	@override String get noOfflineArticles => 'Aucun article hors ligne téléchargé.';
	@override String get openSource => 'Ouvrir la source';
	@override String get openSourcePage => 'Ouvrir la page source';
	@override String get openSourcePageTooltip => 'Ouvrir la page source';
	@override String distanceKm({required Object distance}) => '${distance} km';
	@override String get speed => 'Vitesse';
	@override String get altitude => 'Altitude';
	@override String get copyRouteTitle => 'Itinéraire Flymap';
	@override String copyRouteCode({required Object routeCode}) => 'Code d’itinéraire : ${routeCode}';
	@override String copyDistance({required Object distance}) => 'Distance : ${distance} km';
	@override String get copyFrom => 'De';
	@override String get copyTo => 'À';
	@override String copyCity({required Object city, required Object countryCode}) => 'Ville : ${city}, ${countryCode}';
	@override String copyAirport({required Object airport}) => 'Aéroport : ${airport}';
	@override String copyCodes({required Object iata, required Object icao}) => 'Codes : IATA ${iata} | ICAO ${icao}';
}

// Path: flight.route
class _TranslationsFlightRouteFr extends TranslationsFlightRouteEn {
	_TranslationsFlightRouteFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get loadingRouteTimeline => 'Chargement de la chronologie de l’itinéraire...';
	@override String get noSavedOfflineRegions => 'Aucune région hors ligne enregistrée pour ce vol.';
	@override String currentProgress({required Object percentage, required Object minute}) => 'Progression actuelle : ${percentage}% (environ ${minute} après le décollage)';
	@override String get nowLabel => 'Maintenant';
	@override String get currentRegionLabel => 'Actuel';
	@override String get nextRegionLabel => 'Suivant';
	@override String get arrivingLabel => 'Approche';
	@override String get arrivedLabel => 'Arrivé';
	@override String etaLabel({required Object time}) => 'ETA : ${time}';
	@override String etaInLabel({required Object time}) => 'dans ${time}';
	@override String get flyingOverLabel => 'Vous survolez :';
	@override String get premiumLockedChipLabel => 'Débloquer';
	@override String get premiumGateTitle => 'Débloquez la chronologie complète de l’itinéraire';
	@override String get premiumGateBody => 'Passez à Pro pour voir toutes les régions le long de votre itinéraire et les détails de la chronologie.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Débloquez les ${count} régions de cet itinéraire avec Premium.';
	@override String get premiumGateCta => 'Passer à Pro';
	@override String get premiumOfflineTitle => 'Internet requis pour la mise à niveau';
	@override String get premiumOfflineBody => 'Vous êtes actuellement hors ligne. Connectez-vous à Internet pour passer à la version supérieure et débloquer la vue complète de l’itinéraire.';
	@override String nextHintLabel({required Object region, required Object eta}) => 'Suivant : ${region} (${eta})';
	@override String get etaUnknownLabel => 'estimation...';
}

// Path: createFlight.overview.airportCard
class _TranslationsCreateFlightOverviewAirportCardFr extends TranslationsCreateFlightOverviewAirportCardEn {
	_TranslationsCreateFlightOverviewAirportCardFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String departureDescription({required Object airport}) => 'Vous commencerez votre voyage depuis ${airport}.';
	@override String arrivalDescription({required Object airport}) => 'Vous arriverez à ${airport}.';
}

// Path: createFlight.overview.regionInfo
class _TranslationsCreateFlightOverviewRegionInfoFr extends TranslationsCreateFlightOverviewRegionInfoEn {
	_TranslationsCreateFlightOverviewRegionInfoFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get descriptionUnavailable => 'La description n’est pas encore disponible.';
	@override String get wikipediaSectionTitle => 'Wikipédia';
	@override String get wikipediaUnavailable => 'L’article Wikipédia n’est pas disponible pour le moment.';
	@override String get openWikipedia => 'Ouvrir Wikipédia';
}

// Path: createFlight.overview.timeline
class _TranslationsCreateFlightOverviewTimelineFr extends TranslationsCreateFlightOverviewTimelineEn {
	_TranslationsCreateFlightOverviewTimelineFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get takeOffTimeline => 'Décollage';
	@override String get land => 'Atterrissage';
	@override String get alsoAroundThisTime => 'Aussi à peu près au même moment :';
	@override String get minuteUnit => 'min';
	@override String get hourCompactUnit => 'h';
	@override String get minuteCompactUnit => 'm';
	@override late final _TranslationsCreateFlightOverviewTimelineRegionTypeFr regionType = _TranslationsCreateFlightOverviewTimelineRegionTypeFr._(_root);
}

// Path: createFlight.overview.timeline.regionType
class _TranslationsCreateFlightOverviewTimelineRegionTypeFr extends TranslationsCreateFlightOverviewTimelineRegionTypeEn {
	_TranslationsCreateFlightOverviewTimelineRegionTypeFr._(TranslationsFr root) : this._root = root, super.internal(root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get country => 'Pays';
	@override String get region => 'Région';
	@override String get state => 'État';
	@override String get province => 'Province';
	@override String get sea => 'Mer';
	@override String get ocean => 'Océan';
	@override String get strait => 'Détroit';
	@override String get channel => 'Canal';
	@override String get gulf => 'Golfe';
	@override String get bay => 'Baie';
	@override String get lake => 'Lac';
	@override String get alkalineLake => 'Lac alcalin';
	@override String get island => 'Île';
	@override String get archipelago => 'Archipel';
	@override String get peninsula => 'Péninsule';
	@override String get coast => 'Côte';
	@override String get mountainRange => 'Chaîne de montagnes';
	@override String get valley => 'Vallée';
	@override String get plateau => 'Plateau';
	@override String get plain => 'Plaine';
	@override String get basin => 'Bassin';
	@override String get lowland => 'Basses terres';
	@override String get tundra => 'Toundra';
	@override String get wetlands => 'Zones humides';
	@override String get desert => 'Désert';
	@override String get delta => 'Delta';
	@override String get reservoir => 'Réservoir';
	@override String get continent => 'Continent';
	@override String get geoarea => 'Zone géographique';
	@override String get isthmus => 'Isthme';
	@override String get unknown => 'Type de région inconnu';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Flymap',
			'common.kContinue' => 'Continuer',
			'common.back' => 'Retour',
			'common.cancel' => 'Annuler',
			'common.ok' => 'OK',
			'common.retry' => 'Réessayer',
			'common.manage' => 'Gérer',
			'common.edit' => 'Modifier',
			'common.upgrade' => 'Passer à Pro',
			'common.loading' => 'Chargement...',
			'common.readMore' => 'Lire la suite',
			'common.pro' => 'PRO',
			'common.search' => 'Rechercher',
			'common.debug' => 'Debug',
			'home.title' => 'Accueil',
			'home.aboutTooltip' => 'À propos',
			'home.settingsTooltip' => 'Réglages',
			'home.tabFlights' => 'Vols',
			'home.tabLearn' => 'Apprendre',
			'home.tabMedia' => 'Médias',
			'home.openSkyCamera' => 'Ouvrir Sky Camera',
			'home.loadingFlights' => 'Chargement des vols...',
			'home.failedToLoadFlights' => 'Échec du chargement des vols',
			'home.newFlight' => 'Nouveau vol',
			'home.addFirstFlight' => 'Ajouter le premier vol',
			'home.addNextFlight' => 'Ajouter le vol suivant',
			'home.welcomeTitle' => 'Bienvenue sur Flymap',
			'home.welcomeTitlePro' => 'Bienvenue sur Flymap Pro',
			'home.welcomeSubtitle' => 'Cartes hors ligne pour les vols',
			'home.greetingOnline' => 'Prêt pour le prochain vol ?',
			'home.greetingOnlineWithName' => ({required Object name}) => 'Salut ${name}, prêt pour le prochain vol ?',
			'home.greetingOffline' => 'Prêt à explorer votre vol ?',
			'home.greetingOfflineWithName' => ({required Object name}) => 'Salut ${name}, prêt à explorer votre vol ?',
			'home.greetingInProgress' => 'Votre vol est en cours',
			'home.greetingInProgressWithName' => ({required Object name}) => 'Salut ${name}, votre vol est en cours',
			'home.totalFlights' => 'Vols totaux',
			'home.storageUsed' => 'Stockage utilisé',
			'home.totalDistance' => 'Distance totale',
			'home.upcomingFlightsCount' => ({required Object count}) => 'Vols à venir (${count})',
			'home.flightInProgressTitle' => 'Vol en cours',
			'home.noFlightsTitle' => 'Prêt à explorer le monde depuis le ciel ?',
			'home.noFlightsSubtitle' => 'Ajoutez votre premier vol et commencez à découvrir votre prochain voyage.',
			'home.noFlightsTitleNext' => 'Prêt pour votre prochain voyage ?',
			'home.noFlightsSubtitleNext' => 'Vos vols terminés sont dans l’historique. Ajoutez votre prochain vol pour continuer.',
			'home.flightActions' => 'Actions du vol',
			'home.viewAll' => 'Voir tout',
			'home.open' => 'Ouvrir',
			'home.shareRoute' => 'Partager l’itinéraire',
			'home.completeFlight' => 'Archiver le vol',
			'home.deleteFlight' => 'Supprimer le vol',
			'home.failedDeleteFlight' => 'Échec de la suppression du vol',
			'home.noOfflineMap' => 'Aucune carte hors ligne',
			'home.placesCount' => ({required Object count}) => '${count} lieux',
			'home.offlineArticlesCount' => ({required Object count}) => '${count} articles',
			'home.savedTime' => ({required Object time}) => 'Enregistré ${time}',
			'home.justNow' => 'À l’instant',
			'home.daysAgo' => ({required Object days}) => 'Il y a ${days} j',
			'home.hoursAgo' => ({required Object hours}) => 'Il y a ${hours} h',
			'home.minutesAgo' => ({required Object minutes}) => 'Il y a ${minutes} min',
			'home.sort.mostRecent' => 'Le plus récent',
			'home.sort.longest' => 'Le plus long',
			'home.sort.alphabetical' => 'A-Z',
			'skyCamera.loading' => 'Chargement de l’appareil photo...',
			'skyCamera.loadingGpsData' => 'Chargement des données GPS',
			'skyCamera.zoom' => 'Zoom',
			'skyCamera.flash' => 'Flash',
			'skyCamera.cameraUnavailable' => 'L’appareil photo n’est pas disponible pour le moment.',
			'skyCamera.cameraPermissionDenied' => 'L’accès à l’appareil photo est requis pour prendre des photos.',
			'skyCamera.captureFailed' => 'Impossible de prendre la photo pour le moment.',
			'skyCamera.savedMessage' => 'Photo enregistrée',
			'skyCamera.share' => 'Partager',
			'skyCamera.noActiveFlightTitle' => 'Aucun vol actif',
			'skyCamera.noActiveFlightMessage' => 'Sky Camera fonctionne sans vol, mais les détails d’itinéraire n’apparaissent que pendant un vol actif.',
			'skyCamera.telemetrySpeed' => 'Vitesse',
			'skyCamera.telemetryAltitude' => 'Altitude',
			'skyCamera.telemetryHeading' => 'Cap',
			'skyCamera.telemetryTime' => 'Heure',
			'skyCamera.contextCaption' => 'Contexte',
			'skyCamera.mapCaption' => 'Carte',
			'skyCamera.coordinatesCaption' => 'Coordonnées',
			'skyCamera.noValuePlaceholder' => '--',
			'skyCamera.placeholderRoute' => 'LHR -> BCN',
			'skyCamera.placeholderOriginCode' => 'LHR',
			'skyCamera.placeholderDestinationCode' => 'BCN',
			'skyCamera.placeholderContext' => 'Mer Méditerranée',
			'skyCamera.placeholderMap' => 'Aperçu de l’itinéraire',
			'media.title' => 'Médias côté hublot',
			'media.loading' => 'Chargement des médias...',
			'media.failedToLoad' => 'Impossible de charger les médias',
			'media.filesTab' => 'Fichiers',
			'media.flightsTab' => 'Vols',
			'media.emptyTitle' => 'Bienvenue dans votre Sky Camera côté hublot',
			'media.emptySubtitle' => 'Capturez et partagez de magnifiques vues depuis votre siège côté hublot avec des données de vol et GPS en surimpression.',
			'media.emptyFlightsTitle' => 'Aucun dossier de vol pour l’instant',
			'media.emptyFlightsSubtitle' => 'Les captures liées aux vols enregistrés apparaîtront ici.',
			'media.deleteAction' => 'Supprimer',
			'media.share' => 'Partager',
			'media.selectedCount' => ({required Object count}) => '${count} sélectionné(s)',
			'media.groupNoFlight' => 'Aucun contexte de vol',
			'media.groupNoFlightSubtitle' => 'Captures prises hors d’un vol actif',
			'media.groupUnknownFlight' => 'Capture de vol',
			'media.previewTitle' => 'Capture',
			'media.captureCount' => ({required Object count}) => '${count} captures',
			'media.deleteFolder' => 'Supprimer le dossier',
			'media.deleteFolders' => ({required Object count}) => 'Supprimer ${count} dossiers',
			'media.deleteFile' => 'Supprimer le fichier',
			'media.deleteFiles' => ({required Object count}) => 'Supprimer ${count} fichiers',
			'media.deleteFolderConfirm' => ({required Object count}) => 'Supprimer ce dossier et ses ${count} fichiers ?',
			'media.deleteFoldersConfirm' => ({required Object count}) => 'Supprimer ${count} dossiers et tous les fichiers qu’ils contiennent ?',
			'media.deleteFileConfirm' => 'Supprimer ce fichier ?',
			'media.deleteFilesConfirm' => ({required Object count}) => 'Supprimer ${count} fichiers ?',
			'learn.loadingCategories' => 'Chargement des catégories...',
			'learn.failedToLoadCategories' => 'Échec du chargement des catégories',
			'learn.emptyCategoriesTitle' => 'Aucune catégorie pour l’instant',
			'learn.emptyCategoriesSubtitle' => 'Les catégories apparaîtront bientôt ici.',
			'learn.articlesCount' => ({required Object count}) => '${count} articles',
			'learn.loadingArticles' => 'Chargement des articles...',
			'learn.failedToLoadArticles' => 'Échec du chargement des articles',
			'learn.emptyArticlesTitle' => 'Aucun article pour l’instant',
			'learn.emptyArticlesSubtitle' => 'Les articles de cette catégorie apparaîtront bientôt.',
			'learn.upgradeRequiresInternet' => 'Le contenu premium est disponible avec Pro. Connectez-vous à Internet pour mettre à niveau.',
			'learn.proListPreviewHint' => 'Vous pouvez déjà parcourir ces titres. Débloquez la lecture avec Flymap Pro.',
			'learn.failedToLoadArticle' => 'Impossible d’ouvrir cet article pour le moment.',
			'learn.quizzesTitle' => 'Quiz',
			'learn.articlesTitle' => 'Articles',
			'learn.geoQuiz.title' => 'Geo Quiz',
			'learn.geoQuiz.geographyTitle' => 'Géographie',
			'learn.geoQuiz.geographySubtitle' => 'Mers, chaînes de montagnes, lacs, îles et plus',
			'learn.geoQuiz.countriesTitle' => 'Pays sur la carte',
			'learn.geoQuiz.subtitle' => 'Devinez le pays d’après sa silhouette',
			'learn.geoQuiz.loading' => 'Chargement de Geo Quiz...',
			'learn.geoQuiz.failedToLoad' => 'Échec du chargement des quiz',
			'learn.geoQuiz.failedToLoadQuiz' => 'Échec du chargement du quiz',
			'learn.geoQuiz.emptyTitle' => 'Aucun quiz pour l’instant',
			'learn.geoQuiz.emptySubtitle' => 'Les geo quiz apparaîtront bientôt ici.',
			'learn.geoQuiz.countryHint' => 'Nom de la région...',
			'learn.geoQuiz.progressCount' => ({required Object solved, required Object total}) => '${solved} / ${total}',
			'learn.geoQuiz.nextCount' => ({required Object next, required Object total}) => '${next} sur ${total}',
			'learn.geoQuiz.correctCount' => ({required Object count}) => '${count} corrects',
			'learn.geoQuiz.reset' => 'Réinitialiser la progression',
			'learn.geoQuiz.mapPlaceholder' => 'Les données de carte seront ajoutées ensuite',
			'learn.geoQuiz.newBadge' => 'NOUVEAU',
			'learn.geoQuiz.correct' => 'Correct',
			'learn.geoQuiz.wrong' => 'Incorrect',
			'learn.geoQuiz.hintTitle' => 'Indice',
			'learn.geoQuiz.hintSubtitle' => 'Touchez une lettre pour la révéler',
			'learn.geoQuiz.next' => 'Suivant',
			'learn.geoQuiz.pause' => 'Pause',
			'learn.geoQuiz.resume' => 'Reprendre',
			'learn.geoQuiz.finish' => 'Terminer',
			'learn.geoQuiz.completeTitle' => 'Quiz terminé',
			'learn.geoQuiz.completeMessage' => ({required Object total, required Object quiz}) => 'Vous avez trouvé les ${total} pays de ${quiz}.',
			'learn.geoQuiz.backToQuizzes' => 'Retour aux quiz',
			'learn.geoQuiz.playAgain' => 'Rejouer',
			'learn.geoQuiz.progressReady' => 'Prêt à jouer',
			'learn.geoQuiz.progressFinished' => ({required Object count}) => '${count} terminés',
			'learn.geoQuiz.progressInProgress' => ({required Object count}) => '${count} en cours',
			'learn.geoQuiz.progressAllCompleted' => 'Tous terminés',
			'learn.geoQuiz.quizCountriesAfricaTitle' => 'Afrique',
			'learn.geoQuiz.quizCountriesEuropeTitle' => 'Europe',
			'learn.geoQuiz.quizCountriesAsiaTitle' => 'Asie',
			'learn.geoQuiz.quizCountriesNorthAmericaTitle' => 'Amérique du Nord',
			'learn.geoQuiz.quizCountriesSouthAmericaTitle' => 'Amérique du Sud',
			'learn.geoQuiz.quizCountriesOceaniaTitle' => 'Océanie',
			'learn.geoQuiz.quizCountriesAllTitle' => 'Tous les pays',
			'learn.geoQuiz.quizCountriesSubtitle' => 'Pays',
			'learn.geoQuiz.quizCountriesAllSubtitle' => 'Monde',
			'learn.geoQuiz.quizGeographySeasTitle' => 'Mers',
			'learn.geoQuiz.quizGeographyMountainRangesTitle' => 'Chaînes de montagnes',
			'learn.geoQuiz.quizGeographyLakesTitle' => 'Lacs',
			'learn.geoQuiz.quizGeographyIslandsTitle' => 'Îles',
			'learn.geoQuiz.quizGeographyOtherTitle' => 'Autres',
			'learn.geoQuiz.quizGeographyOtherSubtitle' => 'Baies, détroits, golfes, déserts et plus',
			'learn.geoQuiz.descriptionUnavailable' => 'La description n’est pas encore disponible.',
			'settings.title' => 'Réglages',
			'settings.loading' => 'Chargement des réglages...',
			'settings.profile' => 'Profil',
			'settings.profileSubtitle' => 'Nom, habitudes de vol, aéroport de référence et centres d’intérêt',
			'settings.profileSummaryNameHome' => ({required Object name, required Object code}) => '${name} · ${code}',
			'settings.profileSummaryHome' => ({required Object code}) => 'Aéroport de référence : ${code}',
			'settings.profileEditHint' => 'Touchez un élément pour modifier les détails de votre profil.',
			'settings.profileNotSet' => 'Non défini',
			'settings.profileInterestsSelected' => ({required Object count}) => '${count} sélectionnés',
			'settings.historyTitle' => 'Historique',
			'settings.historySubtitle' => 'Tous les vols et statistiques',
			'settings.historyLoading' => 'Chargement de l’historique...',
			'settings.historyLoadError' => 'Échec du chargement de l’historique des vols.',
			'settings.historyFlightsLabel' => 'Vols totaux',
			'settings.historyDistanceLabel' => 'Distance totale',
			'settings.historyAllFlights' => 'Tous les vols',
			'settings.historyStatusUpcoming' => 'À venir',
			'settings.historyStatusInProgress' => 'En cours',
			'settings.historyStatusCompleted' => 'Terminé',
			'settings.historyMapChip' => ({required Object size}) => 'Carte ${size}',
			'settings.historyNoMapChip' => 'Pas de carte',
			'settings.historySortName' => 'Nom',
			'settings.historySortDistance' => 'Distance',
			'settings.historySortDate' => 'Date',
			'settings.historyEmpty' => 'Aucun vol pour l’instant.',
			'settings.historySearchHint' => 'Rechercher par aéroport ou ville',
			'settings.historyNoResults' => 'Aucun vol correspondant trouvé.',
			'settings.historyDeleteOfflineData' => 'Supprimer uniquement la carte',
			'settings.appearance' => 'Apparence',
			'settings.language' => 'Langue',
			'settings.languageSubtitle' => 'Langue de l’application',
			'settings.languageSystem' => 'Système',
			'settings.languageSystemFormat' => ({required Object language}) => '${language} (Système)',
			'settings.languageEnglish' => 'English',
			'settings.languageSpanish' => 'Español',
			'settings.languageFrench' => 'Français',
			'settings.languageGerman' => 'Deutsch',
			'settings.theme' => 'Thème',
			'settings.system' => 'Système',
			'settings.dark' => 'Sombre',
			'settings.light' => 'Clair',
			'settings.units' => 'Unités',
			'settings.storage' => 'Stockage',
			'settings.storageTitle' => 'Stockage',
			'settings.storageSubtitle' => 'Cartes téléchargées et espace disque',
			'settings.storageLoading' => 'Chargement du stockage...',
			'settings.storageLoadError' => 'Échec du chargement des données de stockage.',
			'settings.storageMapsLabel' => 'Cartes téléchargées',
			'settings.storageTotalSizeLabel' => 'Taille totale',
			'settings.storageDownloadedMaps' => 'Cartes téléchargées',
			'settings.storageSortName' => 'Nom',
			'settings.storageSortSize' => 'Taille',
			'settings.storageMapSize' => ({required Object size}) => 'Taille : ${size}',
			'settings.storageEmpty' => 'Aucune carte téléchargée pour l’instant.',
			'settings.altitude' => 'Altitude',
			'settings.altitudeUnit' => 'Unité d’altitude',
			'settings.speed' => 'Vitesse',
			'settings.speedUnit' => 'Unité de vitesse',
			'settings.temperatureUnit' => 'Unité de température',
			'settings.timeFormat' => 'Format de l’heure',
			'settings.distanceUnit' => 'Unité de distance',
			'settings.dateFormat' => 'Format de date',
			'settings.support' => 'Assistance',
			'settings.about' => 'À propos',
			'settings.aboutSubtitle' => 'En savoir plus sur l’application',
			'settings.privacyPolicy' => 'Politique de confidentialité',
			'settings.privacyPolicySubtitle' => 'Lire notre politique de confidentialité',
			'settings.termsOfService' => 'Conditions d’utilisation',
			'settings.termsOfServiceSubtitle' => 'Lire nos conditions d’utilisation',
			'settings.flymapProActivated' => 'Flymap Pro activé.',
			'settings.upgradeCancelled' => 'Mise à niveau annulée.',
			'settings.noPaywall' => 'Aucun écran de paiement disponible pour le moment.',
			'settings.failedOpenPaywall' => 'Impossible d’ouvrir l’écran de paiement.',
			'settings.couldNotOpenUrl' => ({required Object url}) => 'Impossible d’ouvrir ${url}',
			'settings.rateUs' => 'Noter l’application',
			'settings.rateUsSubtitle' => 'Laissez un avis sur la boutique',
			'settings.leaveFeedback' => 'Laisser un avis',
			'settings.leaveFeedbackSubtitle' => 'Partagez votre avis pour nous aider à nous améliorer',
			'settings.couldNotOpenStorePage' => 'Impossible d’ouvrir la page de la boutique',
			'settings.rateDialogTitle' => 'Aimez-vous l’application ?',
			'settings.rateDialogBody' => 'Nous travaillons dur pour rendre chaque vol plus agréable, et votre retour nous aide vraiment à progresser.',
			'settings.rateDialogYes' => 'Oui',
			'settings.rateDialogNo' => 'Non',
			'settings.feedbackTitle' => 'Laisser un avis',
			'settings.feedbackBody' => 'Aidez-nous à rendre Flymap meilleur',
			'settings.feedbackCategoryTitle' => 'Type de retour',
			'settings.feedbackCategoryGeneral' => 'Général',
			'settings.feedbackCategoryFeatureRequest' => 'Demande de fonctionnalité',
			'settings.feedbackCategoryBugReport' => 'Rapport de bug',
			'settings.feedbackHint' => 'Partagez votre avis...',
			'settings.feedbackEmailHint' => 'E-mail (facultatif)',
			'settings.feedbackEmailInvalid' => 'Veuillez saisir un e-mail valide ou laisser ce champ vide.',
			'settings.feedbackSend' => 'Envoyer',
			'settings.feedbackThanks' => 'Merci pour votre retour !',
			'settings.feedbackSendFailed' => 'Impossible d’envoyer le message. Veuillez réessayer.',
			'settings.proBannerTitle' => 'Flymap Pro',
			'settings.proBannerTitleActive' => 'Flymap Pro actif',
			'settings.proBannerSubtitleActive' => 'Mode carte détaillé et packs d’articles hors ligne complets débloqués.',
			'settings.proBannerSubtitleFree' => 'Débloquez les cartes détaillées et les packs d’articles hors ligne complets',
			'settings.proBannerBadgeActive' => 'PRO ACTIF',
			'subscription.screenTitle' => 'Abonnement',
			'subscription.contactSupport' => 'Contacter l’assistance',
			'subscription.cardTitle' => 'Flymap Pro',
			'subscription.periodTitle' => 'Période d’abonnement',
			'subscription.renewsOrExpires' => 'Renouvelle ou expire',
			'subscription.noExpiration' => 'Pas d’expiration',
			'subscription.lastChecked' => 'Dernière vérification',
			'subscription.flightUnlockSheetTitle' => 'Débloquer les fonctionnalités Pro',
			'subscription.flightUnlockOptionTitle' => 'Achat unique',
			'subscription.flightUnlockOptionBody' => 'Débloquez Pro pour un seul vol',
			'subscription.flightUnlockAction' => 'Acheter pour un vol',
			'subscription.flightUnlockUseAction' => 'Utiliser pour un vol',
			'subscription.flightUnlockPriceLoading' => 'Chargement du prix...',
			'subscription.flightUnlockProOptionTitle' => 'Abonnement Flymap Pro',
			'subscription.flightUnlockAvailableCount' => ({required Object count}) => '${count} déblocages de vol disponibles',
			'subscription.flightUnlockProOptionBody' => 'Débloquez Pro pour un nombre illimité de vols',
			'subscription.flightUnlockProAction' => 'Voir les offres Pro',
			'subscription.flightUnlockUnavailable' => 'Le déblocage de vol n’est pas disponible pour le moment.',
			'subscription.flightUnlockPurchaseCancelled' => 'Achat du déblocage annulé.',
			'subscription.flightUnlockPurchaseFailed' => 'Échec de l’achat du déblocage. Veuillez réessayer.',
			'subscription.proFeaturesTitle' => 'Ce que débloque Flymap Pro',
			'subscription.proFeatureRoutesTitle' => 'Aperçus d’itinéraire précis',
			'subscription.proFeatureMapsTitle' => 'Cartes hors ligne plus détaillées',
			'subscription.proFeatureTimelineTitle' => 'Timeline complète du trajet',
			'subscription.proFeaturePoiTitle' => '10 fois plus de lieux sur l’itinéraire',
			'subscription.proFeatureArticlesTitle' => 'Packs d’articles hors ligne complets',
			'subscription.checkingStatus' => 'Vérification de l’état de votre abonnement...',
			'subscription.freePlan' => 'Vous êtes sur le forfait Gratuit.',
			'subscription.active' => 'Actif',
			'subscription.notActive' => 'Inactif',
			'subscription.unknown' => 'Inconnu',
			'subscription.manageSubscription' => 'Gérer l’abonnement',
			'subscription.restorePurchases' => 'Restaurer les achats',
			'subscription.upgradeToPro' => 'Passer à Pro',
			'subscription.restoreNoSubscription' => 'Aucun abonnement actif trouvé.',
			'subscription.supportEmailSubject' => 'Assistance abonnement Flymap',
			'subscription.couldNotOpenEmailApp' => 'Impossible d’ouvrir l’application e-mail',
			'subscription.couldNotOpenSubscriptionSettings' => 'Impossible d’ouvrir les réglages d’abonnement',
			'subscription.proRestored' => 'Flymap Pro restauré.',
			'subscription.failedOpenPaywall' => 'Impossible d’ouvrir l’écran de paiement.',
			'subscription.serviceUnavailable' => 'Le service d’abonnement est temporairement indisponible.',
			'createFlight.steps.departureTitle' => 'Choisir l’aéroport de départ',
			'createFlight.steps.arrivalTitle' => 'Choisir l’aéroport d’arrivée',
			'createFlight.steps.routeNotSupportedTitle' => 'Itinéraire non pris en charge',
			'createFlight.steps.mapPreviewTitle' => 'Aperçu de la carte',
			'createFlight.steps.overviewTitle' => 'Aperçu de l’itinéraire',
			'createFlight.steps.wikipediaTitle' => 'Articles Wikipédia',
			'createFlight.routeTypeSelector.title' => 'Nouveau vol',
			'createFlight.routeTypeSelector.basicTitle' => 'Itinéraire approximatif',
			'createFlight.routeTypeSelector.basicSubtitle' => 'Depuis les aéroports',
			'createFlight.routeTypeSelector.basicDescription' => 'Fonctionne bien pour les vols courts et de nombreux moyen-courriers.',
			'createFlight.routeTypeSelector.proTitle' => 'Itinéraire réel',
			'createFlight.routeTypeSelector.proSubtitle' => 'Depuis des vols récents',
			'createFlight.routeTypeSelector.proDescription' => 'Construit à partir de l’itinéraire le plus récemment enregistré pour ce même vol.',
			'createFlight.routeTypeSelector.mostAccurate' => 'Le plus précis',
			'createFlight.proAccess.subscriber' => 'Flymap Pro',
			'createFlight.proAccess.subscriberBody' => 'Ce vol bénéficie d’un accès Pro complet grâce à votre abonnement Flymap Pro.',
			'createFlight.proAccess.unlockedFlight' => 'Ce vol est débloqué',
			'createFlight.proAccess.unlockedFlightBody' => 'Toutes les fonctionnalités Pro sont activées pour ce vol.',
			'createFlight.proAccess.tooltip' => 'Infos d’accès Pro',
			'createFlight.flightNumberSearch.title' => 'Numéro de vol',
			'createFlight.flightNumberSearch.subtitle' => 'Saisissez un numéro de vol (par exemple BA117).',
			'createFlight.flightNumberSearch.hint' => 'ex. BA117',
			'createFlight.flightNumberSearch.loading' => 'Recherche de votre vol',
			'createFlight.flightNumberSearch.invalidFormatError' => 'Saisissez un numéro de vol valide, comme BA117.',
			'createFlight.flightNumberSearch.notFoundError' => 'Nous n’avons pas trouvé ce numéro de vol. Vérifiez-le et réessayez, ou recherchez par aéroports.',
			'createFlight.flightNumberSearch.rateLimitedError' => 'Il y a trop de recherches de vols en ce moment. Réessayez dans un instant, ou recherchez par aéroports.',
			'createFlight.flightNumberSearch.providerUnavailableError' => 'Les données de vol sont temporairement indisponibles. Réessayez dans un instant, ou recherchez par aéroports.',
			'createFlight.flightNumberSearch.unexpectedError' => 'Une erreur s’est produite lors de la recherche de ce vol. Réessayez, ou recherchez par aéroports.',
			'createFlight.flightNumberSearch.findByAirports' => 'Trouver par aéroports',
			'createFlight.flightNumberSearch.airportsFallbackButton' => 'Trouver par aéroports',
			'createFlight.flightNumberSearch.confirmTitle' => 'Confirmer le vol',
			'createFlight.flightNumberSearch.foundTitle' => 'Nous avons trouvé votre vol',
			'createFlight.flightNumberSearch.basedOnSameFlightOn' => '* Basé sur l’itinéraire enregistré le plus récent pour ce même vol',
			'createFlight.realRouteAirportSearch.title' => 'Trouver des vols réels par aéroports',
			'createFlight.realRouteAirportSearch.subtitle' => 'Choisissez les aéroports de départ et d’arrivée pour rechercher des vols réels récents sur cet itinéraire.',
			'createFlight.realRouteAirportSearch.searchAction' => 'Rechercher des vols récents',
			'createFlight.realRouteAirportSearch.loading' => 'Recherche de vols réels récents',
			'createFlight.realRouteAirportSearch.loadingHint' => 'Cela peut prendre quelques secondes pendant que nous vérifions l’historique récent de l’itinéraire.',
			'createFlight.realRouteAirportSearch.sorryNoFlightFromTo' => ({required Object departure, required Object arrival}) => 'Désolé, nous n’avons trouvé aucun vol de ${departure} à ${arrival}.',
			'createFlight.realRouteAirportSearch.emptyTitle' => 'Nous n’avons trouvé aucun vol récent entre ces aéroports',
			'createFlight.realRouteAirportSearch.emptyResults' => 'Assurez-vous d’avoir sélectionné les mêmes aéroports de départ et d’arrivée que sur votre billet d’avion.',
			'createFlight.realRouteAirportSearch.rateLimitedError' => 'Il y a trop de recherches de vols en ce moment. Réessayez dans un instant.',
			'createFlight.realRouteAirportSearch.providerUnavailableError' => 'Les données de vols réels sont temporairement indisponibles. Réessayez dans un instant.',
			'createFlight.realRouteAirportSearch.unexpectedError' => 'Une erreur s’est produite lors de la recherche de cet itinéraire. Réessayez.',
			'createFlight.realRouteAirportSearch.foundOneTitle' => '1 vol trouvé',
			'createFlight.realRouteAirportSearch.foundManyTitle' => ({required Object count}) => '${count} vols trouvés',
			'createFlight.realRouteAirportSearch.ticketMatchHint' => 'Assurez-vous qu’ils correspondent aux aéroports indiqués sur votre billet d’avion.',
			'createFlight.realRouteAirportSearch.findByFlightNumber' => 'Trouver par numéro de vol',
			'createFlight.search.departureHint' => 'Rechercher l\'aéroport de départ',
			'createFlight.search.arrivalHint' => 'Rechercher l\'aéroport d\'arrivée',
			'createFlight.search.removeFavorite' => 'Retirer des favoris',
			'createFlight.search.addFavorite' => 'Ajouter aux favoris',
			'createFlight.search.removeSelectedAirport' => 'Retirer l’aéroport sélectionné',
			'createFlight.search.favorites' => 'Favoris',
			'createFlight.search.recentAirports' => 'Aéroports récents',
			'createFlight.search.popularAirports' => 'Aéroports populaires',
			'createFlight.search.removeFromFavorites' => 'Retirer des favoris',
			'createFlight.search.noDepartureFound' => 'Aucun aéroport de départ trouvé.',
			'createFlight.search.noArrivalFound' => 'Aucun aéroport d’arrivée trouvé.',
			'createFlight.search.airportCodeCity' => ({required Object code, required Object city}) => '${code} · ${city}',
			'createFlight.search.airportNameCode' => ({required Object name, required Object code}) => '${name} (${code})',
			'createFlight.mapPreview.routeNotSupportedMsg' => 'Désolé, les vols traversant l’antiméridien ne sont pas encore pris en charge.',
			'createFlight.mapPreview.basic' => 'Basique',
			'createFlight.mapPreview.pro' => 'Pro',
			'createFlight.mapPreview.mapDetailInfoTooltip' => 'Note sur l’itinéraire',
			'createFlight.mapPreview.legendButton' => 'Légende',
			'createFlight.mapPreview.legendTitle' => 'Légende des points d’intérêt',
			'createFlight.mapPreview.estimatedMapSize' => ({required Object size}) => 'Taille estimée de la carte : ${size}',
			'createFlight.mapPreview.upgradeToPro' => 'Passer à Pro',
			'createFlight.mapPreview.basicHint' => 'Détail de carte basique avec des lieux limités',
			'createFlight.mapPreview.proGateHint' => 'Passez à Pro pour une carte détaillée avec tous les lieux',
			'createFlight.mapPreview.proHint' => ({required Object count}) => 'Carte hors ligne détaillée avec ${count} lieux',
			'createFlight.mapPreview.optionsTitle' => 'Itinéraire approximatif',
			'createFlight.mapPreview.optionsBody' => 'L’itinéraire est approximatif — le trajet réel peut varier, surtout sur les vols long-courriers.',
			'createFlight.overview.routeNotReady' => 'L’itinéraire n’est pas encore prêt.',
			'createFlight.overview.proPoiUpsell' => 'Le forfait Gratuit comprend une carte basique et un nombre limité de lieux',
			'createFlight.overview.routeNoteTooltip' => 'Note sur l’itinéraire',
			'createFlight.overview.routeNoteTitle' => 'Itinéraire approximatif',
			'createFlight.overview.routeNoteBody' => 'L’itinéraire est approximatif — le trajet réel peut varier, surtout sur les vols long-courriers.',
			'createFlight.overview.realRouteNoteTitle' => 'Itinéraire réel',
			'createFlight.overview.realRouteNoteBody' => 'Cet itinéraire est basé sur l’itinéraire enregistré le plus récent pour ce même vol.\nLe routage réel peut varier en fonction de la météo, du trafic aérien et des contraintes opérationnelles.',
			'createFlight.overview.approximateRouteLongHaulWarningTitle' => 'Cet itinéraire est approximatif',
			'createFlight.overview.approximateRouteLongHaulWarningBody' => 'Les itinéraires approximatifs peuvent être inexacts pour les vols long-courriers. Utilisez plutôt un itinéraire réel avec un numéro de vol.',
			'createFlight.overview.approximateRouteUltraLongHaulUnsupportedBody' => 'Les itinéraires approximatifs ne sont pas pris en charge pour les vols ultra long-courriers. Utilisez plutôt un itinéraire réel avec un numéro de vol.',
			'createFlight.overview.startReview' => 'Commencer la revue',
			'createFlight.overview.skipReview' => 'Passer',
			'createFlight.overview.premiumGateTitle' => 'Débloquez l’aperçu complet de l’itinéraire',
			'createFlight.overview.premiumGateBody' => 'Le forfait Gratuit inclut un aperçu limité de l’itinéraire. Passez à Pro pour voir chaque région de cet itinéraire.',
			'createFlight.overview.premiumGateBodyWithCount' => ({required Object count}) => 'Débloquez les ${count} régions de cet itinéraire avec Pro.',
			'createFlight.overview.premiumGateCta' => 'Passer à Pro',
			'createFlight.overview.routeReviewedTitle' => 'Itinéraire revu',
			'createFlight.overview.routeReviewedSubtitle' => ({required Object regions, required Object departure, required Object arrival}) => 'Vous survolerez ${regions} de ${departure} à ${arrival}.',
			'createFlight.overview.fullSummary' => 'Résumé complet',
			'createFlight.overview.routeSummaryTitle' => 'Résumé de l’itinéraire',
			'createFlight.overview.routeSummaryDistanceLabel' => 'Distance',
			'createFlight.overview.routeSummaryDurationLabel' => 'Durée',
			'createFlight.overview.routeSummaryRegionsLabel' => 'Régions',
			'createFlight.overview.routeSummaryRegionsTitle' => 'Vous survolerez',
			'createFlight.overview.routeSummaryPlacesLabel' => 'Lieux',
			'createFlight.overview.routeSummaryTimelineTitle' => 'Chronologie',
			'createFlight.overview.routeSummaryPlacesTitle' => 'Lieux le long de l’itinéraire',
			'createFlight.overview.routeSummaryPoiSearchHint' => 'Rechercher des lieux',
			'createFlight.overview.routeSummaryPoiNoMatches' => 'Aucun lieu ne correspond à votre recherche.',
			'createFlight.overview.airportCard.departureDescription' => ({required Object airport}) => 'Vous commencerez votre voyage depuis ${airport}.',
			'createFlight.overview.airportCard.arrivalDescription' => ({required Object airport}) => 'Vous arriverez à ${airport}.',
			'createFlight.overview.regionInfo.descriptionUnavailable' => 'La description n’est pas encore disponible.',
			'createFlight.overview.regionInfo.wikipediaSectionTitle' => 'Wikipédia',
			'createFlight.overview.regionInfo.wikipediaUnavailable' => 'L’article Wikipédia n’est pas disponible pour le moment.',
			'createFlight.overview.regionInfo.openWikipedia' => 'Ouvrir Wikipédia',
			'createFlight.overview.timeline.takeOffTimeline' => 'Décollage',
			'createFlight.overview.timeline.land' => 'Atterrissage',
			'createFlight.overview.timeline.alsoAroundThisTime' => 'Aussi à peu près au même moment :',
			'createFlight.overview.timeline.minuteUnit' => 'min',
			'createFlight.overview.timeline.hourCompactUnit' => 'h',
			'createFlight.overview.timeline.minuteCompactUnit' => 'm',
			'createFlight.overview.timeline.regionType.country' => 'Pays',
			'createFlight.overview.timeline.regionType.region' => 'Région',
			'createFlight.overview.timeline.regionType.state' => 'État',
			'createFlight.overview.timeline.regionType.province' => 'Province',
			'createFlight.overview.timeline.regionType.sea' => 'Mer',
			'createFlight.overview.timeline.regionType.ocean' => 'Océan',
			'createFlight.overview.timeline.regionType.strait' => 'Détroit',
			'createFlight.overview.timeline.regionType.channel' => 'Canal',
			'createFlight.overview.timeline.regionType.gulf' => 'Golfe',
			'createFlight.overview.timeline.regionType.bay' => 'Baie',
			'createFlight.overview.timeline.regionType.lake' => 'Lac',
			'createFlight.overview.timeline.regionType.alkalineLake' => 'Lac alcalin',
			'createFlight.overview.timeline.regionType.island' => 'Île',
			'createFlight.overview.timeline.regionType.archipelago' => 'Archipel',
			'createFlight.overview.timeline.regionType.peninsula' => 'Péninsule',
			'createFlight.overview.timeline.regionType.coast' => 'Côte',
			'createFlight.overview.timeline.regionType.mountainRange' => 'Chaîne de montagnes',
			'createFlight.overview.timeline.regionType.valley' => 'Vallée',
			'createFlight.overview.timeline.regionType.plateau' => 'Plateau',
			'createFlight.overview.timeline.regionType.plain' => 'Plaine',
			'createFlight.overview.timeline.regionType.basin' => 'Bassin',
			'createFlight.overview.timeline.regionType.lowland' => 'Basses terres',
			'createFlight.overview.timeline.regionType.tundra' => 'Toundra',
			'createFlight.overview.timeline.regionType.wetlands' => 'Zones humides',
			'createFlight.overview.timeline.regionType.desert' => 'Désert',
			'createFlight.overview.timeline.regionType.delta' => 'Delta',
			'createFlight.overview.timeline.regionType.reservoir' => 'Réservoir',
			'createFlight.overview.timeline.regionType.continent' => 'Continent',
			'createFlight.overview.timeline.regionType.geoarea' => 'Zone géographique',
			'createFlight.overview.timeline.regionType.isthmus' => 'Isthme',
			'createFlight.overview.timeline.regionType.unknown' => 'Type de région inconnu',
			'createFlight.wikipedia.title' => 'Téléchargez des articles et lisez-les pendant que vous êtes en l’air',
			'createFlight.wikipedia.loadingIntro' => 'Recherche d’articles liés à l’itinéraire...',
			'createFlight.wikipedia.foundIntro' => ({required Object count}) => 'D’après votre itinéraire, nous avons trouvé ${count} articles pertinents',
			'createFlight.wikipedia.emptyIntro' => 'Aucun article Wikipédia lié à l’itinéraire n’a été trouvé. Vous pouvez continuer avec le téléchargement de la carte uniquement.',
			'createFlight.wikipedia.selectedCount' => ({required Object count}) => '${count} sélectionnés',
			'createFlight.wikipedia.unselectAll' => 'Tout désélectionner',
			'createFlight.wikipedia.selectAll' => 'Tout sélectionner',
			'createFlight.wikipedia.basicHint' => ({required Object count}) => 'Articles hors ligne sélectionnés : ${count}',
			'createFlight.wikipedia.proHint' => 'Carte et pack de données hors ligne',
			'createFlight.wikipedia.proGateHint' => 'Passez à Pro pour le pack complet d’articles hors ligne',
			'createFlight.wikipedia.proActiveTitle' => 'Pro actif',
			'createFlight.wikipedia.proActiveMessage' => 'Pack complet d’articles débloqué.',
			'createFlight.wikipedia.freeLimitHint' => 'Le forfait Gratuit inclut jusqu’à 3 articles hors ligne',
			'createFlight.wikipedia.estimatedDownloadSize' => ({required Object size}) => 'Taille estimée du téléchargement : ${size}',
			'createFlight.wikipedia.upgrade' => 'Passer à Pro',
			'createFlight.wikipedia.loadingSuggestions' => 'Chargement des suggestions d’articles...',
			'createFlight.wikipedia.downloadMapOnly' => 'Télécharger la carte',
			'createFlight.wikipedia.downloadMapPlusOne' => 'Télécharger la carte + 1 article',
			'createFlight.wikipedia.downloadMapPlusMany' => ({required Object count}) => 'Télécharger la carte + ${count} articles',
			'createFlight.wikipedia.couldNotOpenLink' => 'Impossible d’ouvrir le lien',
			'createFlight.downloading.articlesTitle' => 'Téléchargement des articles sélectionnés...',
			'createFlight.downloading.mapTitle' => 'Téléchargement de la carte hors ligne...',
			'createFlight.downloading.mapSectionTitle' => 'Carte',
			'createFlight.downloading.poiSectionTitle' => 'Lieux',
			'createFlight.downloading.articlesSectionTitle' => 'Articles',
			'createFlight.downloading.cancelDownload' => 'Annuler le téléchargement',
			'createFlight.downloading.doNotClose' => 'Ne fermez pas cet écran avant la fin du téléchargement',
			'createFlight.downloading.currentStep' => 'En cours',
			'createFlight.downloading.pending' => 'En attente',
			'createFlight.downloading.inProgress' => 'En cours',
			'createFlight.downloading.completed' => 'Terminé',
			'createFlight.downloading.completedWithIssues' => 'Terminé avec des problèmes',
			'createFlight.downloading.failed' => 'Échec',
			'createFlight.downloading.skipped' => 'Ignoré',
			'createFlight.downloading.waitingForMap' => 'En attente du téléchargement de la carte...',
			'createFlight.downloading.mapFailed' => 'Le téléchargement de la carte a échoué.',
			'createFlight.downloading.noPoiSelected' => 'Aucun résumé de lieu sélectionné.',
			'createFlight.downloading.preparingPoi' => 'Préparation des résumés de lieux...',
			'createFlight.downloading.poiProgress' => ({required Object completed, required Object total}) => 'Lieux : ${completed}/${total}',
			'createFlight.downloading.poiProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Lieux : ${completed}/${total} (${failed} échecs)',
			'createFlight.downloading.noArticlesSelected' => 'Aucun article sélectionné.',
			'createFlight.downloading.preparingArticles' => 'Préparation des téléchargements d’articles...',
			'createFlight.downloading.articlesProgress' => ({required Object completed, required Object total}) => 'Articles : ${completed}/${total}',
			'createFlight.downloading.articlesProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Articles : ${completed}/${total} (${failed} échecs)',
			'createFlight.downloading.preparingMap' => 'Préparation du téléchargement de la carte...',
			'createFlight.downloading.computingTiles' => 'Calcul des tuiles de carte...',
			'createFlight.downloading.computingTilesWithCount' => ({required Object count}) => 'Calcul des tuiles de carte (${count})...',
			'createFlight.downloading.preparingForDownload' => 'Préparation du téléchargement...',
			'createFlight.downloading.downloaded' => ({required Object size}) => 'Téléchargé : ${size}',
			'createFlight.downloading.finalizing' => 'Finalisation du pack de cartes...',
			'createFlight.downloading.verifying' => 'Vérification du pack de cartes...',
			_ => null,
		} ?? switch (path) {
			'createFlight.errors.failedLoadAirports' => 'Échec du chargement des aéroports. Veuillez réessayer.',
			'createFlight.errors.airportSearchFailed' => 'La recherche d’aéroport a échoué. Essayez une autre requête.',
			'createFlight.errors.someArticlesFailed' => 'Certains articles ont échoué. Le téléchargement de la carte continue.',
			'createFlight.errors.someOptionalDownloadsFailed' => 'Carte téléchargée. Certains contenus facultatifs n’ont pas pu être téléchargés.',
			'createFlight.errors.failedBuildPreview' => 'Échec de la création de l’aperçu de l’itinéraire. Veuillez réessayer.',
			'createFlight.errors.overviewUnavailableContinue' => 'Impossible de charger l’aperçu de l’itinéraire. Vous pouvez quand même continuer.',
			'createFlight.errors.noInternet' => 'Aucune connexion Internet. Vérifiez votre connexion et réessayez.',
			'createFlight.errors.failedStartDownload' => ({required Object error}) => 'Échec du démarrage du téléchargement : ${error}',
			'createFlight.paywall.upgradeCancelled' => 'Mise à niveau annulée.',
			'createFlight.paywall.noPaywall' => 'Aucun écran de paiement disponible pour le moment.',
			'createFlight.paywall.failedOpenPaywall' => 'Impossible d’ouvrir l’écran de paiement.',
			'preview.calculatingRoute' => 'Calcul de l’itinéraire du vol...',
			'preview.errorTitle' => 'Erreur',
			'preview.errorSomethingWrong' => 'Un problème est survenu',
			'preview.tryAgain' => 'Réessayer',
			'preview.downloadCongratsTitle' => 'Bravo ! Tout est prêt.',
			'preview.offlineSavedDetail' => 'La carte et les données de vol sélectionnées sont enregistrées pour une utilisation hors ligne pendant votre vol.',
			'preview.downloadCompletedTitle' => 'Téléchargement terminé',
			'preview.shareFlightCard' => 'Partagez votre superbe carte de vol',
			'preview.share' => 'Partager la carte de vol',
			'preview.home' => 'Accueil',
			'preview.navigatingHome' => 'Retour à l’accueil...',
			'preview.downloadingMapTitle' => 'Téléchargement des ressources',
			'preview.cancelDownload' => 'Annuler le téléchargement',
			'preview.download' => 'Télécharger',
			'preview.flightRoute' => ({required Object distance}) => 'Itinéraire du vol (~ ${distance})',
			'flight.tabMap' => 'Carte',
			'flight.tabDashboard' => 'Tableau de bord',
			'flight.tabRoute' => 'Itinéraire',
			'flight.tabRead' => 'Lire',
			'flight.tabInfo' => 'Infos',
			'flight.completeDialogTitle' => 'Terminer le vol ?',
			'flight.completeDialogBody' => 'Cela marquera votre vol comme terminé.',
			'flight.completeDialogDeleteOffline' => 'Supprimer la carte et les articles hors ligne',
			'flight.completeDialogConfirm' => 'Terminer',
			'flight.deleteDialogTitle' => 'Êtes-vous sûr ?',
			'flight.deleteDialogMessage' => ({required Object size}) => 'Cela supprime définitivement ce vol, y compris la carte hors ligne et les articles hors ligne enregistrés.\n\nEspace récupéré : ${size}.',
			'flight.yes' => 'Oui',
			'flight.shareRoute' => 'Partager l’itinéraire',
			'flight.copyRoute' => 'Copier l’itinéraire',
			'flight.deleteFlight' => 'Supprimer le vol',
			'flight.routeSummaryCopied' => 'Résumé de l’itinéraire copié',
			'flight.deleted' => 'Vol supprimé',
			'flight.deleteError' => ({required Object error}) => 'Erreur lors de la suppression du vol : ${error}',
			'flight.map.initializing' => 'Chargement de la carte',
			'flight.map.loadingStyle' => 'Chargement de la carte',
			'flight.map.offlineNotAvailable' => 'La carte hors ligne n’est pas disponible pour ce vol.',
			'flight.map.offlineMissing' => 'Le fichier de carte hors ligne est manquant. Veuillez retélécharger cet itinéraire.',
			'flight.map.validationFailed' => 'La validation de la carte hors ligne a échoué. Veuillez retélécharger cet itinéraire.',
			'flight.map.loadStyleFailed' => 'Impossible de charger le style de la carte hors ligne.',
			'flight.map.sunriseInMinutes' => ({required Object minutes}) => 'Lever du soleil dans ${minutes} min',
			'flight.map.sunsetInMinutes' => ({required Object minutes}) => 'Coucher du soleil dans ${minutes} min',
			'flight.map.switchTo2D' => 'Passer en 2D',
			'flight.map.switchTo3D' => 'Passer en 3D',
			'flight.map.switchToLightMapStyle' => 'Passer au style de carte clair',
			'flight.map.switchToDarkMapStyle' => 'Passer au style de carte sombre',
			'flight.map.uncenterMap' => 'Décentrer la carte',
			'flight.map.centerOnMe' => 'Me centrer',
			'flight.dashboard.gpsOffTitle' => 'Les services de localisation sont désactivés',
			'flight.dashboard.gpsOffSubtitle' => 'Activez les services de localisation dans les réglages système pour reprendre le suivi du vol en direct et le suivi de la carte.',
			'flight.dashboard.openLocationSettings' => 'Ouvrir les réglages de localisation',
			'flight.dashboard.permissionTitle' => 'Autorisation de localisation requise',
			'flight.dashboard.permissionSubtitle' => 'Autorisez l’accès à la localisation pour que le tableau de bord puisse afficher le cap, la vitesse et l’altitude en direct.',
			'flight.dashboard.grantPermissions' => 'Accorder les autorisations',
			'flight.dashboard.gpsAccuracy' => ({required Object label, required Object accuracy}) => 'Précision GPS : ${label} (±${accuracy} m)',
			'flight.dashboard.accuracyExcellent' => 'Excellente',
			'flight.dashboard.accuracyGood' => 'Bonne',
			'flight.dashboard.accuracyPoor' => 'Faible',
			'flight.dashboard.gpsOff' => 'GPS désactivé',
			'flight.dashboard.gpsOffHint' => 'Activez les services de localisation pour commencer le suivi.',
			'flight.dashboard.gpsPermissionRequired' => 'Autorisation GPS requise',
			'flight.dashboard.gpsPermissionHint' => 'Accordez l’autorisation pour accéder à la télémétrie du vol en direct.',
			'flight.dashboard.gpsSearching' => 'Recherche du GPS',
			'flight.dashboard.gpsSearchingHint' => 'Recherche d’un signal fiable',
			'flight.dashboard.gpsSearchingHintWithAge' => ({required Object age}) => 'Recherche du GPS. Dernier point ${age}.',
			'flight.dashboard.gpsWeak' => 'Signal GPS faible',
			'flight.dashboard.gpsWeakHint' => 'Le signal est instable. Gardez l’appareil sous un ciel dégagé.',
			'flight.dashboard.gpsWeakHintWithAge' => ({required Object age}) => 'Signal instable. Dernier point ${age}.',
			'flight.dashboard.gpsActive' => 'GPS actif',
			'flight.dashboard.gpsActiveHint' => 'Réception de la télémétrie en direct.',
			'flight.dashboard.gpsActiveHintWithAge' => ({required Object age}) => 'Dernière mise à jour GPS ${age}.',
			'flight.dashboard.gpsShowingLastKnownData' => 'Affichage des dernières données connues',
			'flight.dashboard.gpsHelpTooltip' => 'Dépannage GPS',
			'flight.dashboard.gpsHelpTitle' => 'Dépannage GPS',
			'flight.dashboard.gpsHelpBody' => 'Il semble que le signal GPS ne soit pas fiable sur votre téléphone.',
			'flight.dashboard.gpsHelpStepsTitle' => 'Essayez ceci',
			'flight.dashboard.gpsHelpTipLocation' => 'Assurez-vous que les services de localisation sont activés',
			'flight.dashboard.gpsHelpTipWindow' => 'Approchez votre téléphone d’une fenêtre',
			'flight.dashboard.gpsHelpTipCase' => 'Retirez les coques épaisses ou accessoires métalliques',
			'flight.dashboard.gpsHelpTipFlat' => 'Tenez votre téléphone immobile pendant quelques instants',
			'flight.dashboard.gpsHelpFooter' => 'Le suivi en direct reprend automatiquement une fois le signal stabilisé.',
			'flight.dashboard.ageJustNow' => 'à l’instant',
			'flight.dashboard.ageSeconds' => ({required Object seconds}) => 'il y a ${seconds} s',
			'flight.dashboard.ageMinutes' => ({required Object minutes}) => 'il y a ${minutes} min',
			'flight.dashboard.signalGood' => 'Bon',
			'flight.dashboard.signalPoor' => 'Faible',
			'flight.dashboard.signalBad' => 'Mauvais',
			'flight.dashboard.signalSearching' => 'Recherche',
			'flight.dashboard.gpsQuality' => ({required Object quality}) => 'GPS ${quality}',
			'flight.dashboard.gpsSearchingLabel' => 'Recherche GPS',
			'flight.dashboard.gpsPermissionNeededLabel' => 'Autorisation GPS nécessaire',
			'flight.dashboard.gpsOffLabel' => 'GPS désactivé',
			'flight.dashboard.aircraftHeading' => 'Cap de l’avion',
			'flight.dashboard.headingShort' => ({required Object heading}) => 'CAP ${heading}°',
			'flight.dashboard.liveInstruments' => 'Instruments en direct',
			'flight.dashboard.groundSpeed' => 'Vitesse au sol',
			'flight.dashboard.altitudeMsl' => 'Altitude AMSL',
			'flight.dashboard.outsideAirApprox' => 'Température extérieure',
			'flight.dashboard.temperatureAvailableAfter' => ({required Object threshold}) => 'Disponible après ${threshold}',
			'flight.dashboard.temperatureApproxHint' => 'Estimation approximative basée sur l’altitude',
			'flight.dashboard.headingPanel' => 'Cap',
			'flight.dashboard.flightPhaseTaxi' => 'Roulage',
			'flight.dashboard.flightPhaseGroundRoll' => 'Course au sol',
			'flight.dashboard.flightPhaseTakeoffRoll' => 'Course de décollage',
			'flight.dashboard.flightPhaseLandingRoll' => 'Course d’atterrissage',
			'flight.dashboard.flightPhaseAscending' => 'Montée',
			'flight.dashboard.flightPhaseCruising' => 'Croisière',
			'flight.dashboard.flightPhaseDescending' => 'Descente',
			'flight.dashboard.acquiringGpsSignal' => 'Acquisition du signal GPS',
			'flight.dashboard.acquiringGpsHint' => 'Gardez l’appareil stable et sous un ciel dégagé pour obtenir un point fiable.',
			'flight.dashboard.weakSignalBanner' => 'Signal GPS faible. Les valeurs peuvent dériver jusqu’à l’amélioration de la précision.',
			'flight.dashboard.preparingDashboard' => 'Préparation du tableau de bord...',
			'flight.dashboard.navigation' => 'Navigation',
			'flight.dashboard.heading' => ({required Object heading}) => 'Cap ${heading}',
			'flight.dashboard.routeProgress' => 'Progression sur l’itinéraire',
			'flight.dashboard.covered' => 'Parcouru',
			'flight.dashboard.remaining' => 'Restant',
			'flight.dashboard.total' => 'Total',
			'flight.upcoming.mapTitle' => 'Commencez votre voyage',
			'flight.upcoming.mapSubtitle' => 'Lancez le suivi en direct quand votre vol commence',
			'flight.upcoming.dashboardTitle' => 'Commencez votre voyage',
			'flight.upcoming.dashboardSubtitle' => 'Commencez pour voir votre tableau de bord en direct',
			'flight.upcoming.checkInButton' => 'Démarrer',
			'flight.upcoming.checkInSuccess' => 'Vol démarré',
			'flight.upcoming.checkInError' => 'Impossible de démarrer maintenant. Veuillez réessayer',
			'flight.info.overviewTitle' => 'Aperçu',
			'flight.info.overviewLoading' => 'Création de l’aperçu de l’itinéraire...',
			'flight.info.overviewEmpty' => 'L’aperçu n’est pas encore disponible pour cet itinéraire.',
			'flight.info.loadingRouteInformation' => 'Chargement des informations sur l’itinéraire...',
			'flight.info.flyOverTitle' => 'Points forts de votre itinéraire',
			'flight.info.airportsTitle' => 'Aéroports',
			'flight.info.departure' => 'Départ',
			'flight.info.arrival' => 'Arrivée',
			'flight.info.showAll' => 'Afficher tout',
			'flight.info.showAllCount' => ({required Object count}) => 'Afficher les ${count}',
			'flight.info.showLess' => 'Afficher moins',
			'flight.info.sortByRank' => 'Par rang',
			'flight.info.sortByRouteProgress' => 'Par itinéraire',
			'flight.info.sortByType' => 'Par type',
			'flight.info.routeTimelineTitle' => 'Chronologie de l’itinéraire',
			'flight.info.plannedWaypoints' => ({required Object count}) => '${count} points de passage prévus',
			'flight.info.pointsOfInterestTitle' => 'Points d’intérêt',
			'flight.info.noPoi' => 'Aucun point d’intérêt disponible pour le moment.',
			'flight.info.poiType' => ({required Object type}) => 'Type : ${type}',
			'flight.info.poiFlyOver' => ({required Object view}) => 'Survol : ${view}',
			'flight.info.offlineArticlesTitle' => 'Articles hors ligne',
			'flight.info.regionArticlesTitle' => 'Articles de région',
			'flight.info.otherArticlesTitle' => 'Autres articles',
			'flight.info.noOfflineArticles' => 'Aucun article hors ligne téléchargé.',
			'flight.info.openSource' => 'Ouvrir la source',
			'flight.info.openSourcePage' => 'Ouvrir la page source',
			'flight.info.openSourcePageTooltip' => 'Ouvrir la page source',
			'flight.info.distanceKm' => ({required Object distance}) => '${distance} km',
			'flight.info.speed' => 'Vitesse',
			'flight.info.altitude' => 'Altitude',
			'flight.info.copyRouteTitle' => 'Itinéraire Flymap',
			'flight.info.copyRouteCode' => ({required Object routeCode}) => 'Code d’itinéraire : ${routeCode}',
			'flight.info.copyDistance' => ({required Object distance}) => 'Distance : ${distance} km',
			'flight.info.copyFrom' => 'De',
			'flight.info.copyTo' => 'À',
			'flight.info.copyCity' => ({required Object city, required Object countryCode}) => 'Ville : ${city}, ${countryCode}',
			'flight.info.copyAirport' => ({required Object airport}) => 'Aéroport : ${airport}',
			'flight.info.copyCodes' => ({required Object iata, required Object icao}) => 'Codes : IATA ${iata} | ICAO ${icao}',
			'flight.route.loadingRouteTimeline' => 'Chargement de la chronologie de l’itinéraire...',
			'flight.route.noSavedOfflineRegions' => 'Aucune région hors ligne enregistrée pour ce vol.',
			'flight.route.currentProgress' => ({required Object percentage, required Object minute}) => 'Progression actuelle : ${percentage}% (environ ${minute} après le décollage)',
			'flight.route.nowLabel' => 'Maintenant',
			'flight.route.currentRegionLabel' => 'Actuel',
			'flight.route.nextRegionLabel' => 'Suivant',
			'flight.route.arrivingLabel' => 'Approche',
			'flight.route.arrivedLabel' => 'Arrivé',
			'flight.route.etaLabel' => ({required Object time}) => 'ETA : ${time}',
			'flight.route.etaInLabel' => ({required Object time}) => 'dans ${time}',
			'flight.route.flyingOverLabel' => 'Vous survolez :',
			'flight.route.premiumLockedChipLabel' => 'Débloquer',
			'flight.route.premiumGateTitle' => 'Débloquez la chronologie complète de l’itinéraire',
			'flight.route.premiumGateBody' => 'Passez à Pro pour voir toutes les régions le long de votre itinéraire et les détails de la chronologie.',
			'flight.route.premiumGateBodyWithCount' => ({required Object count}) => 'Débloquez les ${count} régions de cet itinéraire avec Premium.',
			'flight.route.premiumGateCta' => 'Passer à Pro',
			'flight.route.premiumOfflineTitle' => 'Internet requis pour la mise à niveau',
			'flight.route.premiumOfflineBody' => 'Vous êtes actuellement hors ligne. Connectez-vous à Internet pour passer à la version supérieure et débloquer la vue complète de l’itinéraire.',
			'flight.route.nextHintLabel' => ({required Object region, required Object eta}) => 'Suivant : ${region} (${eta})',
			'flight.route.etaUnknownLabel' => 'estimation...',
			'shareFlight.title' => 'Partager le vol',
			'shareFlight.preparingMap' => 'Préparation de la carte de partage...',
			'shareFlight.preparingScreenshot' => 'Préparation de la capture d’écran...',
			'shareFlight.share' => 'Partager',
			'shareFlight.route' => 'Itinéraire',
			'shareFlight.offlineMapMissing' => 'Carte hors ligne manquante. Utilisation du style en ligne.',
			'shareFlight.offlineStyleFailed' => 'Échec du chargement du style hors ligne. Utilisation du style en ligne.',
			'shareFlight.captureFailed' => 'Impossible de capturer la capture d’écran de l’itinéraire',
			'shareFlight.shareFailed' => 'Échec du partage de la capture de l’itinéraire',
			'shareFlight.shareText' => ({required Object from, required Object to}) => 'Itinéraire du vol ${from}-${to}',
			'shareFlight.watermark' => 'Flymap',
			'shareFlight.flightDistance' => 'Distance du vol',
			'shareFlight.distanceKm' => ({required Object distance}) => '${distance} km',
			'shareImage.title' => 'Partager le vol',
			'shareImage.generating' => 'Création de votre carte de vol...',
			'shareImage.share' => 'Partager',
			'shareImage.sharing' => 'Partage...',
			'shareImage.retry' => 'Réessayer',
			'shareImage.error' => 'Impossible de générer la carte de vol',
			'shareImage.tagline' => 'Chaque vol est une découverte',
			'shareImage.brand' => 'Flymap',
			'shareImage.exploreYourFlight' => 'Explorez votre vol',
			'shareImage.countrySingle' => '1 pays',
			'shareImage.countries' => ({required Object count}) => '${count} pays',
			'shareImage.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) sur Flymap ✈️',
			'shareImage.unknownCity' => 'Inconnu',
			'shareImage.durationUnavailable' => '--',
			'shareImage.durationMinutes' => ({required Object minutes}) => '${minutes} min',
			'shareImage.durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} h ${minutes} min',
			'about.title' => 'À propos de Flymap',
			'about.welcome' => 'Bienvenue sur Flymap',
			'about.intro' => 'Flymap garde votre itinéraire visible dans les airs. Planifiez le voyage, téléchargez votre carte au sol et suivez votre vol hors ligne en toute confiance.',
			'about.chipOffline' => 'Carte hors ligne',
			'about.chipDashboard' => 'Tableau de bord en direct',
			'about.chipSharing' => 'Partage d’itinéraire',
			'about.infoBanner' => 'Avant le décollage, téléchargez la carte de votre itinéraire. En mode avion, l’accès Internet peut être limité ou indisponible.',
			'about.whatYouCanDo' => 'Ce que vous pouvez faire',
			'about.featurePlanTitle' => 'Planifiez votre itinéraire',
			'about.featurePlanText' => 'Choisissez les aéroports de départ et d’arrivée, puis prévisualisez le trajet avant le téléchargement.',
			'about.featureTrackTitle' => 'Suivez les données du vol',
			'about.featureTrackText' => 'Utilisez le tableau de bord pour surveiller le cap, la vitesse, l’altitude et la progression de l’itinéraire.',
			'about.featureDetailsTitle' => 'Consultez les détails de l’itinéraire',
			'about.featureDetailsText' => 'Ouvrez l’onglet Infos pour voir les détails des aéroports et un aperçu clair de l’itinéraire.',
			'about.featureShareTitle' => 'Partagez votre voyage',
			'about.featureShareText' => 'Générez et partagez une capture d’écran de la carte de vol avec les points forts du trajet.',
			'about.quickStart' => 'Démarrage rapide',
			'about.step1' => 'Touchez Nouveau vol sur l’accueil.',
			'about.step2' => 'Choisissez les aéroports de départ et d’arrivée.',
			'about.step3' => 'Ouvrez l’aperçu de la carte et téléchargez-la avant le vol.',
			'about.step4' => 'Ouvrez votre vol et utilisez Carte, Tableau de bord et Infos en l’air.',
			'about.tips' => 'Conseils pour un meilleur GPS',
			'about.tip1' => 'Pour un meilleur signal GPS, asseyez-vous près d’un hublot.',
			'about.tip2' => 'Le signal peut chuter au milieu de l’avion. Flymap conserve la dernière vue connue de l’itinéraire pendant la recherche.',
			'onboarding.skip' => 'Passer',
			'onboarding.letsStart' => 'Commençons',
			'onboarding.welcomeTitle' => 'Découvrez ce qu’il y a en dessous',
			'onboarding.welcomeSubtitle' => 'vous montre des cartes hors ligne et des lieux intéressants tout au long de votre vol',
			'onboarding.nameTitle' => 'Choisissez un nom d’utilisateur',
			'onboarding.nameSubtitle' => 'Rendez la découverte personnelle. Vous pourrez le changer à tout moment.',
			'onboarding.nameHint' => 'Votre nom',
			'onboarding.nameExample' => 'Alex',
			'onboarding.frequencyTitle' => 'À quelle fréquence prenez-vous l’avion ?',
			'onboarding.frequencySubtitle' => 'Flymap personnalisera votre expérience et rendra les suggestions plus pertinentes',
			'onboarding.frequencyFirstFlight' => 'C’est mon premier vol',
			'onboarding.frequencyFewPerYear' => 'Quelques fois par an',
			'onboarding.frequencyMonthly' => 'Environ chaque mois',
			'onboarding.frequencyFrequent' => 'Très souvent',
			'onboarding.homeAirportTitle' => 'Définissez votre aéroport de référence',
			'onboarding.homeAirportSubtitle' => 'Obtenez une configuration plus rapide des vols. Vous pouvez le modifier à tout moment.',
			'onboarding.homeAirportHint' => 'Rechercher l’aéroport de référence',
			'onboarding.popularAirports' => 'Aéroports populaires',
			'onboarding.removeHomeAirport' => 'Retirer l’aéroport de référence',
			'onboarding.noHomeAirportFound' => 'Aucun aéroport trouvé pour cette recherche.',
			'onboarding.interestsTitle' => 'Quels lieux voulez-vous voir davantage sur une carte ?',
			'onboarding.interestsSubtitle' => 'Choisissez jusqu’à 3 thèmes pour voir des lieux et histoires plus pertinents pendant votre vol.',
			'onboarding.interestsHelper' => 'Choisissez jusqu’à 3 thèmes.',
			'onboarding.interestsSelected' => ({required Object count, required Object max}) => '${count} sur ${max} sélectionnés',
			'onboarding.interestMountains' => 'Montagnes et crêtes',
			'onboarding.interestVolcanoes' => 'Volcans et géologie',
			'onboarding.interestRegions' => 'Villes et régions',
			'onboarding.interestIslands' => 'Îles et côtes',
			'onboarding.interestNationalParks' => 'Parcs nationaux et réserves',
			'onboarding.interestRivers' => 'Rivières et lacs',
			'onboarding.proTitle' => 'Tirez plus de chaque vol',
			'onboarding.proStepSubtitle' => 'Débloquez des cartes détaillées, des lieux et des articles — même hors ligne.',
			'onboarding.proFeatureMaps' => 'Cartes détaillées pour votre vol',
			'onboarding.proFeatureRoutes' => 'Itinéraires de vol les plus précis',
			'onboarding.proFeaturePlaces' => '10x plus de lieux le long de l’itinéraire',
			'onboarding.proFeatureTimeline' => 'Une chronologie détaillée de tout votre vol',
			'onboarding.proFeatureArticles' => 'Pack complet d’articles hors ligne',
			'onboarding.unlockPro' => 'Passer à Pro',
			'onboarding.continueFree' => 'Continuer gratuitement',
			'onboarding.proActiveTitle' => 'Félicitations !',
			'onboarding.proActiveSubtitle' => 'Vous avez maintenant un accès complet aux cartes détaillées, à tous les lieux et aux packs d’articles.',
			'onboarding.planFirstFlight' => 'Planifier mon premier vol',
			'onboarding.planFirstFlightPro' => 'Planifier mon premier vol détaillé',
			'onboarding.failedLoadProfile' => 'Échec du chargement de votre profil.',
			'countries.AE' => 'Émirats arabes unis',
			'countries.AF' => 'Afghanistan',
			'countries.AG' => 'Antigua-et-Barbuda',
			'countries.AL' => 'Albanie',
			'countries.AM' => 'Arménie',
			'countries.AO' => 'Angola',
			'countries.AR' => 'Argentine',
			'countries.AT' => 'Autriche',
			'countries.AU' => 'Australie',
			'countries.AZ' => 'Azerbaïdjan',
			'countries.BA' => 'Bosnie-Herzégovine',
			'countries.BB' => 'Barbade',
			'countries.BD' => 'Bangladesh',
			'countries.BE' => 'Belgique',
			'countries.BF' => 'Burkina Faso',
			'countries.BG' => 'Bulgarie',
			'countries.BH' => 'Bahreïn',
			'countries.BI' => 'Burundi',
			'countries.BJ' => 'Bénin',
			'countries.BN' => 'Brunei Darussalam',
			'countries.BO' => 'Bolivie',
			'countries.BR' => 'Brésil',
			'countries.BS' => 'Bahamas',
			'countries.BT' => 'Bhoutan',
			'countries.BW' => 'Botswana',
			'countries.BY' => 'Biélorussie',
			'countries.BZ' => 'Belize',
			'countries.CA' => 'Canada',
			'countries.CD' => 'Congo, République démocratique du',
			'countries.CF' => 'République centrafricaine',
			'countries.CG' => 'Congo',
			'countries.CH' => 'Suisse',
			'countries.CI' => 'Côte d\'Ivoire',
			'countries.CL' => 'Chili',
			'countries.CM' => 'Cameroun',
			'countries.CN' => 'Chine',
			'countries.CO' => 'Colombie',
			'countries.CR' => 'Costa Rica',
			'countries.CU' => 'Cuba',
			'countries.CV' => 'Cap-Vert',
			'countries.CY' => 'Chypre',
			'countries.CZ' => 'République tchèque',
			'countries.DE' => 'Allemagne',
			'countries.DJ' => 'Djibouti',
			'countries.DK' => 'Danemark',
			'countries.DO' => 'République dominicaine',
			'countries.DZ' => 'Algérie',
			'countries.EC' => 'Équateur',
			'countries.EE' => 'Estonie',
			'countries.EG' => 'Égypte',
			'countries.EH' => 'Sahara occidental',
			'countries.ER' => 'Érythrée',
			'countries.ES' => 'Espagne',
			'countries.ET' => 'Éthiopie',
			'countries.FI' => 'Finlande',
			'countries.FJ' => 'Fidji',
			'countries.FR' => 'France',
			'countries.GA' => 'Gabon',
			'countries.GB' => 'Royaume-Uni',
			'countries.GE' => 'Géorgie',
			'countries.GF' => 'Guyane française',
			'countries.GH' => 'Ghana',
			'countries.GM' => 'Gambie',
			'countries.GN' => 'Guinée',
			'countries.GP' => 'Guadeloupe',
			'countries.GQ' => 'Guinée équatoriale',
			'countries.GR' => 'Grèce',
			'countries.GT' => 'Guatemala',
			'countries.GW' => 'Guinée-Bissau',
			'countries.GY' => 'Guyana',
			'countries.HK' => 'Hong Kong, Chine',
			'countries.HN' => 'Honduras',
			'countries.HR' => 'Croatie',
			'countries.HT' => 'Haïti',
			'countries.HU' => 'Hongrie',
			'countries.ID' => 'Indonésie',
			'countries.IE' => 'Irlande',
			'countries.IL' => 'Israël',
			'countries.IN' => 'Inde',
			'countries.IQ' => 'Irak',
			'countries.IR' => 'Iran',
			'countries.IS' => 'Islande',
			'countries.IT' => 'Italie',
			'countries.JM' => 'Jamaïque',
			'countries.JO' => 'Jordanie',
			'countries.JP' => 'Japon',
			'countries.KE' => 'Kenya',
			'countries.KG' => 'Kirghizistan',
			'countries.KH' => 'Cambodge',
			'countries.KM' => 'Comores',
			'countries.KP' => 'Corée du Nord',
			'countries.KR' => 'Corée du Sud',
			'countries.KW' => 'Koweït',
			'countries.KZ' => 'Kazakhstan',
			'countries.LA' => 'Laos',
			'countries.LB' => 'Liban',
			'countries.LK' => 'Sri Lanka',
			'countries.LR' => 'Libéria',
			'countries.LS' => 'Lesotho',
			'countries.LT' => 'Lituanie',
			'countries.LU' => 'Luxembourg',
			'countries.LV' => 'Lettonie',
			'countries.LY' => 'Libye',
			'countries.MA' => 'Maroc',
			'countries.MD' => 'Moldavie',
			'countries.ME' => 'Monténégro',
			'countries.MG' => 'Madagascar',
			'countries.MK' => 'Macédoine du Nord',
			'countries.ML' => 'Mali',
			'countries.MM' => 'Myanmar',
			'countries.MN' => 'Mongolie',
			'countries.MO' => 'Macao, Chine',
			'countries.MQ' => 'Martinique',
			'countries.MR' => 'Mauritanie',
			'countries.MU' => 'Maurice',
			'countries.MV' => 'Maldives',
			'countries.MW' => 'Malawi',
			'countries.MT' => 'Malte',
			'countries.MX' => 'Mexique',
			'countries.MY' => 'Malaisie',
			'countries.MZ' => 'Mozambique',
			'countries.NA' => 'Namibie',
			'countries.NC' => 'Nouvelle-Calédonie',
			'countries.NE' => 'Niger',
			'countries.NG' => 'Nigeria',
			'countries.NI' => 'Nicaragua',
			'countries.NL' => 'Pays-Bas',
			'countries.NO' => 'Norvège',
			'countries.NP' => 'Népal',
			'countries.NZ' => 'Nouvelle-Zélande',
			'countries.OM' => 'Oman',
			'countries.PA' => 'Panama',
			'countries.PE' => 'Pérou',
			'countries.PG' => 'Papouasie-Nouvelle-Guinée',
			'countries.PH' => 'Philippines',
			'countries.PK' => 'Pakistan',
			'countries.PL' => 'Pologne',
			'countries.PR' => 'Porto Rico',
			'countries.PS' => 'Cisjordanie et bande de Gaza',
			'countries.PT' => 'Portugal',
			'countries.PY' => 'Paraguay',
			'countries.QA' => 'Qatar',
			'countries.RE' => 'La Réunion',
			'countries.RO' => 'Roumanie',
			'countries.RS' => 'Serbie',
			'countries.RU' => 'Russie',
			'countries.RW' => 'Rwanda',
			'countries.SA' => 'Arabie saoudite',
			'countries.SB' => 'Îles Salomon',
			'countries.SD' => 'Soudan',
			'countries.SE' => 'Suède',
			'countries.SG' => 'Singapour',
			'countries.SI' => 'Slovénie',
			'countries.SK' => 'Slovaquie',
			'countries.SL' => 'Sierra Leone',
			'countries.SN' => 'Sénégal',
			'countries.SO' => 'Somalie',
			'countries.SR' => 'Suriname',
			'countries.SS' => 'Soudan du Sud',
			'countries.ST' => 'Sao Tomé-et-Principe',
			'countries.SV' => 'Salvador',
			'countries.SY' => 'Syrie',
			'countries.SZ' => 'Eswatini',
			'countries.TD' => 'Tchad',
			'countries.TG' => 'Togo',
			'countries.TH' => 'Thaïlande',
			'countries.TJ' => 'Tadjikistan',
			'countries.TL' => 'Timor oriental',
			'countries.TM' => 'Turkménistan',
			'countries.TN' => 'Tunisie',
			'countries.TR' => 'Turquie',
			'countries.TT' => 'Trinité-et-Tobago',
			'countries.TW' => 'Taïwan, Chine',
			'countries.TZ' => 'Tanzanie',
			'countries.UA' => 'Ukraine',
			'countries.UG' => 'Ouganda',
			'countries.US' => 'États-Unis',
			'countries.UY' => 'Uruguay',
			'countries.UZ' => 'Ouzbékistan',
			'countries.VE' => 'Venezuela',
			'countries.VI' => 'Îles Vierges américaines',
			'countries.VN' => 'Viêt Nam',
			'countries.YE' => 'Yémen',
			'countries.ZA' => 'Afrique du Sud',
			'countries.ZM' => 'Zambie',
			'countries.ZW' => 'Zimbabwe',
			_ => null,
		};
	}
}
