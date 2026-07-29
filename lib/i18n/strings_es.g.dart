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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override String get appName => 'Flymap';
	@override late final _TranslationsCommonEs common = _TranslationsCommonEs._(_root);
	@override late final _TranslationsHomeEs home = _TranslationsHomeEs._(_root);
	@override late final _TranslationsSkyCameraEs skyCamera = _TranslationsSkyCameraEs._(_root);
	@override late final _TranslationsMediaEs media = _TranslationsMediaEs._(_root);
	@override late final _TranslationsLearnEs learn = _TranslationsLearnEs._(_root);
	@override late final _TranslationsSettingsEs settings = _TranslationsSettingsEs._(_root);
	@override late final _TranslationsSubscriptionEs subscription = _TranslationsSubscriptionEs._(_root);
	@override late final _TranslationsCreateFlightEs createFlight = _TranslationsCreateFlightEs._(_root);
	@override late final _TranslationsPreviewEs preview = _TranslationsPreviewEs._(_root);
	@override late final _TranslationsFlightEs flight = _TranslationsFlightEs._(_root);
	@override late final _TranslationsShareFlightEs shareFlight = _TranslationsShareFlightEs._(_root);
	@override late final _TranslationsShareImageEs shareImage = _TranslationsShareImageEs._(_root);
	@override late final _TranslationsFlightVideoEs flightVideo = _TranslationsFlightVideoEs._(_root);
	@override late final _TranslationsAboutEs about = _TranslationsAboutEs._(_root);
	@override late final _TranslationsOnboardingEs onboarding = _TranslationsOnboardingEs._(_root);
	@override late final _TranslationsCountriesEs countries = _TranslationsCountriesEs._(_root);
}

// Path: common
class _TranslationsCommonEs extends TranslationsCommonEn {
	_TranslationsCommonEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get kContinue => 'Continuar';
	@override String get back => 'Atrás';
	@override String get cancel => 'Cancelar';
	@override String get ok => 'OK';
	@override String get retry => 'Reintentar';
	@override String get manage => 'Gestionar';
	@override String get edit => 'Editar';
	@override String get upgrade => 'Pasar a Pro';
	@override String get loading => 'Cargando...';
	@override String get readMore => 'Leer más';
	@override String get pro => 'PRO';
	@override String get search => 'Buscar';
	@override String get debug => 'Debug';
}

// Path: home
class _TranslationsHomeEs extends TranslationsHomeEn {
	_TranslationsHomeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Inicio';
	@override String get aboutTooltip => 'Acerca de';
	@override String get settingsTooltip => 'Ajustes';
	@override String get tabFlights => 'Vuelos';
	@override String get tabLearn => 'Aprender';
	@override String get tabMedia => 'Media';
	@override String get openSkyCamera => 'Abrir Sky Camera';
	@override String get loadingFlights => 'Cargando vuelos...';
	@override String get failedToLoadFlights => 'No se pudieron cargar los vuelos';
	@override String get newFlight => 'Nuevo vuelo';
	@override String get addFirstFlight => 'Añadir primer vuelo';
	@override String get addNextFlight => 'Añadir siguiente vuelo';
	@override String get welcomeTitle => 'Bienvenido a Flymap';
	@override String get welcomeTitlePro => 'Bienvenido a Flymap Pro';
	@override String get welcomeSubtitle => 'Mapas offline para vuelos';
	@override String get greetingOnline => '¿Listo para el próximo vuelo?';
	@override String greetingOnlineWithName({required Object name}) => 'Hola ${name}, ¿listo para el próximo vuelo?';
	@override String get greetingOffline => '¿Listo para explorar tu vuelo?';
	@override String greetingOfflineWithName({required Object name}) => 'Hola ${name}, ¿listo para explorar tu vuelo?';
	@override String get greetingInProgress => 'Tu vuelo está en curso';
	@override String greetingInProgressWithName({required Object name}) => 'Hola ${name}, tu vuelo está en curso';
	@override String get totalFlights => 'Vuelos totales';
	@override String get storageUsed => 'Almacenamiento usado';
	@override String get totalDistance => 'Distancia total';
	@override String upcomingFlightsCount({required Object count}) => 'Próximos vuelos (${count})';
	@override String get flightInProgressTitle => 'Vuelo en curso';
	@override String get noFlightsTitle => '¿Listo para explorar el mundo desde arriba?';
	@override String get noFlightsSubtitle => 'Añade tu primer vuelo y empieza a descubrir tu próximo viaje.';
	@override String get noFlightsTitleNext => '¿Listo para tu próximo viaje?';
	@override String get noFlightsSubtitleNext => 'Tus vuelos completados están en Historial. Añade tu próximo vuelo para seguir.';
	@override String get flightActions => 'Acciones del vuelo';
	@override String get viewAll => 'Ver todo';
	@override String get open => 'Abrir';
	@override String get shareRoute => 'Compartir ruta';
	@override String get completeFlight => 'Archivar vuelo';
	@override String get deleteFlight => 'Eliminar vuelo';
	@override String get failedDeleteFlight => 'No se pudo eliminar el vuelo';
	@override String get noOfflineMap => 'Sin mapa offline';
	@override String placesCount({required Object count}) => '${count} lugares';
	@override String regionsCount({required Object count}) => '${count} regiones';
	@override String offlineArticlesCount({required Object count}) => '${count} artículos';
	@override String savedTime({required Object time}) => 'Guardado ${time}';
	@override String get justNow => 'Ahora mismo';
	@override String daysAgo({required Object days}) => 'Hace ${days} d';
	@override String hoursAgo({required Object hours}) => 'Hace ${hours} h';
	@override String minutesAgo({required Object minutes}) => 'Hace ${minutes} min';
	@override late final _TranslationsHomeSortEs sort = _TranslationsHomeSortEs._(_root);
}

// Path: skyCamera
class _TranslationsSkyCameraEs extends TranslationsSkyCameraEn {
	_TranslationsSkyCameraEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Cargando cámara...';
	@override String get loadingGpsData => 'Cargando datos GPS';
	@override String get zoom => 'Zoom';
	@override String get flash => 'Flash';
	@override String get cameraUnavailable => 'La cámara no está disponible ahora mismo.';
	@override String get cameraPermissionDenied => 'Se necesita permiso de cámara para hacer fotos.';
	@override String get captureFailed => 'No se pudo capturar la foto ahora mismo.';
	@override String get savedMessage => 'Foto guardada';
	@override String get share => 'Compartir';
	@override String get noActiveFlightTitle => 'No hay un vuelo activo';
	@override String get noActiveFlightMessage => 'Sky Camera funciona sin vuelo, pero los detalles de ruta solo aparecen durante un vuelo activo.';
	@override String get telemetrySpeed => 'Velocidad';
	@override String get telemetryAltitude => 'Altitud';
	@override String get telemetryHeading => 'Rumbo';
	@override String get telemetryTime => 'Hora';
	@override String get contextCaption => 'Contexto';
	@override String get mapCaption => 'Mapa';
	@override String get coordinatesCaption => 'Coordenadas';
	@override String get noValuePlaceholder => '--';
	@override String get placeholderRoute => 'LHR -> BCN';
	@override String get placeholderOriginCode => 'LHR';
	@override String get placeholderDestinationCode => 'BCN';
	@override String get placeholderContext => 'Mar Mediterráneo';
	@override String get placeholderMap => 'Vista previa de la ruta';
	@override String get settingsTitle => 'Ajustes de cámara';
	@override String get recordAudio => 'Grabar audio';
	@override String get recordAudioHint => 'Los vídeos capturan el sonido del micrófono.';
	@override String get microphonePermissionDenied => 'El acceso al micrófono está desactivado: los vídeos se graban sin sonido.';
	@override String get preparingVideo => 'Preparando el vídeo…';
}

// Path: media
class _TranslationsMediaEs extends TranslationsMediaEn {
	_TranslationsMediaEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Contenido desde la ventanilla';
	@override String get loading => 'Cargando media...';
	@override String get failedToLoad => 'No se pudo cargar la media';
	@override String get filesTab => 'Archivos';
	@override String get flightsTab => 'Vuelos';
	@override String get emptyTitle => 'Te damos la bienvenida a tu Sky Camera de ventanilla';
	@override String get emptySubtitle => 'Captura y comparte vistas increíbles desde tu asiento de ventanilla con superposiciones de datos de vuelo y GPS.';
	@override String get emptyFlightsTitle => 'Aún no hay carpetas de vuelos';
	@override String get emptyFlightsSubtitle => 'Las capturas vinculadas a vuelos guardados aparecerán aquí.';
	@override String get deleteAction => 'Eliminar';
	@override String get share => 'Compartir';
	@override String selectedCount({required Object count}) => '${count} seleccionado(s)';
	@override String get groupNoFlight => 'Sin contexto de vuelo';
	@override String get groupNoFlightSubtitle => 'Capturas tomadas fuera de un vuelo activo';
	@override String get groupUnknownFlight => 'Captura de vuelo';
	@override String get previewTitle => 'Captura';
	@override String captureCount({required Object count}) => '${count} capturas';
	@override String get deleteFolder => 'Eliminar carpeta';
	@override String deleteFolders({required Object count}) => 'Eliminar ${count} carpetas';
	@override String get deleteFile => 'Eliminar archivo';
	@override String deleteFiles({required Object count}) => 'Eliminar ${count} archivos';
	@override String deleteFolderConfirm({required Object count}) => '¿Eliminar esta carpeta y sus ${count} archivos?';
	@override String deleteFoldersConfirm({required Object count}) => '¿Eliminar ${count} carpetas y todos los archivos dentro?';
	@override String get deleteFileConfirm => '¿Eliminar este archivo?';
	@override String deleteFilesConfirm({required Object count}) => '¿Eliminar ${count} archivos?';
}

// Path: learn
class _TranslationsLearnEs extends TranslationsLearnEn {
	_TranslationsLearnEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get loadingCategories => 'Cargando categorías de aprendizaje...';
	@override String get failedToLoadCategories => 'No se pudieron cargar las categorías';
	@override String get emptyCategoriesTitle => 'Aún no hay categorías';
	@override String get emptyCategoriesSubtitle => 'Las categorías de aprendizaje aparecerán aquí pronto.';
	@override String articlesCount({required Object count}) => '${count} artículos';
	@override String get loadingArticles => 'Cargando artículos...';
	@override String get failedToLoadArticles => 'No se pudieron cargar los artículos';
	@override String get emptyArticlesTitle => 'Aún no hay artículos';
	@override String get emptyArticlesSubtitle => 'Los artículos de esta categoría aparecerán pronto.';
	@override String get upgradeRequiresInternet => 'El contenido premium está disponible con Pro. Conéctate a internet para mejorar.';
	@override String get proListPreviewHint => 'Puedes explorar estos títulos ahora. Desbloquea la lectura con Flymap Pro.';
	@override String get failedToLoadArticle => 'No se pudo abrir este artículo ahora mismo.';
	@override String get quizzesTitle => 'Cuestionarios';
	@override String get articlesTitle => 'Artículos';
	@override late final _TranslationsLearnGeoQuizEs geoQuiz = _TranslationsLearnGeoQuizEs._(_root);
}

// Path: settings
class _TranslationsSettingsEs extends TranslationsSettingsEn {
	_TranslationsSettingsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ajustes';
	@override String get loading => 'Cargando ajustes...';
	@override String get profile => 'Perfil';
	@override String get profileSubtitle => 'Nombre, hábitos de vuelo, aeropuerto base e intereses';
	@override String profileSummaryNameHome({required Object name, required Object code}) => '${name} · ${code}';
	@override String profileSummaryHome({required Object code}) => 'Aeropuerto base: ${code}';
	@override String get profileEditHint => 'Toca cualquier elemento para editar los datos de tu perfil.';
	@override String get profileNotSet => 'Sin definir';
	@override String profileInterestsSelected({required Object count}) => '${count} seleccionados';
	@override String get historyTitle => 'Historial';
	@override String get historySubtitle => 'Todos los vuelos y estadísticas';
	@override String get historyLoading => 'Cargando historial...';
	@override String get historyLoadError => 'No se pudo cargar el historial de vuelos.';
	@override String get historyFlightsLabel => 'Vuelos totales';
	@override String get historyDistanceLabel => 'Distancia total';
	@override String get historyAllFlights => 'Todos los vuelos';
	@override String get historyStatusUpcoming => 'Próximo';
	@override String get historyStatusInProgress => 'En curso';
	@override String get historyStatusCompleted => 'Completado';
	@override String historyMapChip({required Object size}) => 'Mapa ${size}';
	@override String get historyNoMapChip => 'Sin mapa';
	@override String get historySortName => 'Nombre';
	@override String get historySortDistance => 'Distancia';
	@override String get historySortDate => 'Fecha';
	@override String get historyEmpty => 'Aún no hay vuelos.';
	@override String get historySearchHint => 'Buscar por aeropuerto o ciudad';
	@override String get historyNoResults => 'No se encontraron vuelos coincidentes.';
	@override String get historyDeleteOfflineData => 'Eliminar solo el mapa';
	@override String get appearance => 'Apariencia';
	@override String get language => 'Idioma';
	@override String get languageSubtitle => 'Idioma de la app';
	@override String get languageSystem => 'Sistema';
	@override String languageSystemFormat({required Object language}) => '${language} (Sistema)';
	@override String get languageEnglish => 'English';
	@override String get languageSpanish => 'Español';
	@override String get languageFrench => 'Français';
	@override String get languageGerman => 'Deutsch';
	@override String get theme => 'Tema';
	@override String get system => 'Sistema';
	@override String get dark => 'Oscuro';
	@override String get light => 'Claro';
	@override String get units => 'Unidades';
	@override String get storage => 'Almacenamiento';
	@override String get storageTitle => 'Almacenamiento';
	@override String get storageSubtitle => 'Mapas descargados y uso del disco';
	@override String get storageLoading => 'Cargando almacenamiento...';
	@override String get storageLoadError => 'No se pudieron cargar los datos de almacenamiento.';
	@override String get storageMapsLabel => 'Mapas descargados';
	@override String get storageTotalSizeLabel => 'Tamaño total';
	@override String get storageDownloadedMaps => 'Mapas descargados';
	@override String get storageSortName => 'Nombre';
	@override String get storageSortSize => 'Tamaño';
	@override String storageMapSize({required Object size}) => 'Tamaño: ${size}';
	@override String get storageEmpty => 'Aún no hay mapas descargados.';
	@override String get altitude => 'Altitud';
	@override String get altitudeUnit => 'Unidad de altitud';
	@override String get speed => 'Velocidad';
	@override String get speedUnit => 'Unidad de velocidad';
	@override String get temperatureUnit => 'Unidad de temperatura';
	@override String get timeFormat => 'Formato de hora';
	@override String get distanceUnit => 'Unidad de distancia';
	@override String get dateFormat => 'Formato de fecha';
	@override String get support => 'Soporte';
	@override String get about => 'Acerca de';
	@override String get aboutSubtitle => 'Más información sobre la app';
	@override String get privacyPolicy => 'Política de privacidad';
	@override String get privacyPolicySubtitle => 'Lee nuestra política de privacidad';
	@override String get termsOfService => 'Términos del servicio';
	@override String get termsOfServiceSubtitle => 'Lee nuestros términos del servicio';
	@override String get flymapProActivated => 'Flymap Pro activado.';
	@override String get upgradeCancelled => 'Actualización cancelada.';
	@override String get noPaywall => 'No hay pantalla de pago disponible en este momento.';
	@override String get failedOpenPaywall => 'No se pudo abrir la pantalla de pago.';
	@override String couldNotOpenUrl({required Object url}) => 'No se pudo abrir ${url}';
	@override String get rateUs => 'Valóranos';
	@override String get rateUsSubtitle => 'Deja una reseña en la tienda';
	@override String get leaveFeedback => 'Dejar comentarios';
	@override String get leaveFeedbackSubtitle => 'Comparte tu opinión para ayudarnos a mejorar';
	@override String get couldNotOpenStorePage => 'No se pudo abrir la página de la tienda';
	@override String get rateDialogTitle => '¿Te gusta la app?';
	@override String get rateDialogBody => 'Trabajamos duro para que cada vuelo sea más agradable, y tus comentarios realmente nos ayudan a mejorar.';
	@override String get rateDialogYes => 'Sí';
	@override String get rateDialogNo => 'No';
	@override String get advocacyDialogTitle => 'Nos alegra que disfrutes Flymap';
	@override String get advocacyDialogBody => 'Ayuda a otros viajeros a descubrir Flymap.';
	@override String get advocacyDialogShare => 'Compartir con amigos';
	@override String get advocacyDialogRate => 'Valorar Flymap';
	@override String get advocacyDialogNotNow => 'Ahora no';
	@override String get feedbackTitle => 'Dejar comentarios';
	@override String get feedbackBody => 'Ayúdanos a mejorar Flymap';
	@override String get feedbackCategoryTitle => 'Tipo de comentario';
	@override String get feedbackCategoryGeneral => 'General';
	@override String get feedbackCategoryFeatureRequest => 'Solicitud de función';
	@override String get feedbackCategoryBugReport => 'Error';
	@override String get feedbackHint => 'Comparte tus comentarios...';
	@override String get feedbackEmailHint => 'Correo electrónico (opcional)';
	@override String get feedbackEmailInvalid => 'Introduce un correo válido o déjalo vacío.';
	@override String get feedbackSend => 'Enviar';
	@override String get feedbackThanks => '¡Gracias por compartir tus comentarios!';
	@override String get feedbackSendFailed => 'No se pudieron enviar los comentarios. Inténtalo de nuevo.';
	@override String get proBannerTitle => 'Flymap Pro';
	@override String get proBannerTitleActive => 'Flymap Pro activo';
	@override String get proBannerSubtitleActive => 'Modo de mapa detallado y paquetes completos de artículos offline desbloqueados.';
	@override String get proBannerSubtitleFree => 'Desbloquea mapas detallados y paquetes completos de artículos offline';
	@override String get proBannerBadgeActive => 'PRO ACTIVO';
}

// Path: subscription
class _TranslationsSubscriptionEs extends TranslationsSubscriptionEn {
	_TranslationsSubscriptionEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Suscripción';
	@override String get contactSupport => 'Contactar con soporte';
	@override String get cardTitle => 'Flymap Pro';
	@override String get periodTitle => 'Periodo de suscripción';
	@override String get renewsOrExpires => 'Renueva o caduca';
	@override String get noExpiration => 'Sin caducidad';
	@override String get lastChecked => 'Última comprobación';
	@override String get flightUnlockSheetTitle => 'Desbloquear funciones Pro';
	@override String get flightUnlockOptionTitle => 'Compra única';
	@override String get flightUnlockOptionBody => 'Desbloquea Pro para un solo vuelo';
	@override String get flightUnlockAction => 'Comprar para 1 vuelo';
	@override String get flightUnlockUseAction => 'Usar para 1 vuelo';
	@override String get flightUnlockPriceLoading => 'Cargando precio...';
	@override String get flightUnlockProOptionTitle => 'Suscripción Flymap Pro';
	@override String flightUnlockAvailableCount({required Object count}) => '${count} desbloqueos de vuelo disponibles';
	@override String get flightUnlockProOptionBody => 'Desbloquea Pro para vuelos ilimitados';
	@override String get flightUnlockProAction => 'Ver planes Pro';
	@override String get flightUnlockUnavailable => 'El desbloqueo de vuelo no está disponible ahora mismo.';
	@override String get flightUnlockPurchaseCancelled => 'Compra del desbloqueo de vuelo cancelada.';
	@override String get flightUnlockPurchaseFailed => 'La compra del desbloqueo de vuelo falló. Inténtalo de nuevo.';
	@override String get proFeaturesTitle => 'Lo que desbloquea Flymap Pro';
	@override String get proFeatureRoutesTitle => 'Vistas previas de ruta precisas';
	@override String get proFeatureMapsTitle => 'Mapas offline con más detalle';
	@override String get proFeatureTimelineTitle => 'Línea de tiempo completa';
	@override String get proFeaturePoiTitle => '10 veces más lugares en la ruta';
	@override String get proFeatureArticlesTitle => 'Paquetes completos de artículos offline';
	@override String get checkingStatus => 'Comprobando el estado de tu suscripción...';
	@override String get freePlan => 'Estás en el plan Free.';
	@override String get active => 'Activo';
	@override String get notActive => 'No activo';
	@override String get unknown => 'Desconocido';
	@override String get manageSubscription => 'Gestionar suscripción';
	@override String get restorePurchases => 'Restaurar compras';
	@override String get upgradeToPro => 'Pasar a Pro';
	@override String get restoreNoSubscription => 'No se encontró ninguna suscripción activa.';
	@override String get supportEmailSubject => 'Soporte de suscripción de Flymap';
	@override String get couldNotOpenEmailApp => 'No se pudo abrir la app de correo';
	@override String get couldNotOpenSubscriptionSettings => 'No se pudieron abrir los ajustes de suscripción';
	@override String get proRestored => 'Flymap Pro restaurado.';
	@override String get failedOpenPaywall => 'No se pudo abrir la pantalla de pago.';
	@override String get serviceUnavailable => 'El servicio de suscripción no está disponible temporalmente.';
}

// Path: createFlight
class _TranslationsCreateFlightEs extends TranslationsCreateFlightEn {
	_TranslationsCreateFlightEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _TranslationsCreateFlightStepsEs steps = _TranslationsCreateFlightStepsEs._(_root);
	@override late final _TranslationsCreateFlightWeatherEs weather = _TranslationsCreateFlightWeatherEs._(_root);
	@override late final _TranslationsCreateFlightRouteTypeSelectorEs routeTypeSelector = _TranslationsCreateFlightRouteTypeSelectorEs._(_root);
	@override late final _TranslationsCreateFlightProAccessEs proAccess = _TranslationsCreateFlightProAccessEs._(_root);
	@override late final _TranslationsCreateFlightTravelDateEs travelDate = _TranslationsCreateFlightTravelDateEs._(_root);
	@override late final _TranslationsCreateFlightFlightNumberSearchEs flightNumberSearch = _TranslationsCreateFlightFlightNumberSearchEs._(_root);
	@override late final _TranslationsCreateFlightRealRouteAirportSearchEs realRouteAirportSearch = _TranslationsCreateFlightRealRouteAirportSearchEs._(_root);
	@override late final _TranslationsCreateFlightSearchEs search = _TranslationsCreateFlightSearchEs._(_root);
	@override late final _TranslationsCreateFlightMapPreviewEs mapPreview = _TranslationsCreateFlightMapPreviewEs._(_root);
	@override late final _TranslationsCreateFlightOverviewEs overview = _TranslationsCreateFlightOverviewEs._(_root);
	@override late final _TranslationsCreateFlightWikipediaEs wikipedia = _TranslationsCreateFlightWikipediaEs._(_root);
	@override late final _TranslationsCreateFlightDownloadingEs downloading = _TranslationsCreateFlightDownloadingEs._(_root);
	@override late final _TranslationsCreateFlightErrorsEs errors = _TranslationsCreateFlightErrorsEs._(_root);
	@override late final _TranslationsCreateFlightPaywallEs paywall = _TranslationsCreateFlightPaywallEs._(_root);
	@override late final _TranslationsCreateFlightRealRouteChoiceEs realRouteChoice = _TranslationsCreateFlightRealRouteChoiceEs._(_root);
}

// Path: preview
class _TranslationsPreviewEs extends TranslationsPreviewEn {
	_TranslationsPreviewEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get calculatingRoute => 'Calculando la ruta del vuelo...';
	@override String get errorTitle => 'Error';
	@override String get errorSomethingWrong => 'Algo salió mal';
	@override String get tryAgain => 'Intentar de nuevo';
	@override String get downloadCongratsTitle => '¡Perfecto! Ya está todo listo.';
	@override String get offlineSavedDetail => 'El mapa y los datos de vuelo seleccionados se guardaron para usarlos offline durante tu vuelo.';
	@override String get downloadCompletedTitle => 'Descarga completada';
	@override String get shareFlightCard => 'Presume de tu increíble vuelo';
	@override String get shareVideo => 'Compartir vídeo del vuelo';
	@override String get shareVideoNewBadge => 'NUEVO';
	@override String get share => 'Compartir tarjeta de vuelo';
	@override String get home => 'Inicio';
	@override String get navigatingHome => 'Volviendo al inicio...';
	@override String get downloadingMapTitle => 'Descargando recursos';
	@override String get cancelDownload => 'Cancelar descarga';
	@override String get download => 'Descargar';
	@override String flightRoute({required Object distance}) => 'Ruta del vuelo (~ ${distance})';
}

// Path: flight
class _TranslationsFlightEs extends TranslationsFlightEn {
	_TranslationsFlightEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tabMap => 'Mapa';
	@override String get tabDashboard => 'Panel';
	@override String get tabRoute => 'Ruta';
	@override String get tabRead => 'Leer';
	@override String get tabCamera => 'Cámara';
	@override String get tabInfo => 'Info';
	@override String get completeDialogTitle => '¿Completar vuelo?';
	@override String get completeDialogBody => 'Esto marcará tu vuelo como completado.';
	@override String get completeDialogDeleteOffline => 'Eliminar mapa y artículos offline';
	@override String get completeDialogConfirm => 'Completar';
	@override String get deleteDialogTitle => '¿Estás seguro?';
	@override String deleteDialogMessage({required Object size}) => 'Esto elimina permanentemente este vuelo, incluido el mapa offline y los artículos offline guardados.\n\nEspacio que se recuperará: ${size}.';
	@override String get yes => 'Sí';
	@override String get shareRoute => 'Compartir ruta';
	@override String get copyRoute => 'Copiar ruta';
	@override String get deleteFlight => 'Eliminar vuelo';
	@override String get routeSummaryCopied => 'Resumen de la ruta copiado';
	@override String get deleted => 'Vuelo eliminado';
	@override String deleteError({required Object error}) => 'Error al eliminar el vuelo: ${error}';
	@override late final _TranslationsFlightMapEs map = _TranslationsFlightMapEs._(_root);
	@override late final _TranslationsFlightDashboardEs dashboard = _TranslationsFlightDashboardEs._(_root);
	@override late final _TranslationsFlightUpcomingEs upcoming = _TranslationsFlightUpcomingEs._(_root);
	@override late final _TranslationsFlightInfoEs info = _TranslationsFlightInfoEs._(_root);
	@override late final _TranslationsFlightRouteEs route = _TranslationsFlightRouteEs._(_root);
}

// Path: shareFlight
class _TranslationsShareFlightEs extends TranslationsShareFlightEn {
	_TranslationsShareFlightEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Compartir vuelo';
	@override String get preparingMap => 'Preparando mapa de vista previa para compartir...';
	@override String get preparingScreenshot => 'Preparando captura...';
	@override String get share => 'Compartir';
	@override String get route => 'Ruta';
	@override String get offlineMapMissing => 'Falta el mapa offline. Se usará el estilo online.';
	@override String get offlineStyleFailed => 'No se pudo cargar el estilo offline. Se usará el estilo online.';
	@override String get captureFailed => 'No se pudo capturar la imagen de la ruta';
	@override String get shareFailed => 'No se pudo compartir la imagen de la ruta';
	@override String shareText({required Object from, required Object to}) => 'Ruta del vuelo ${from}-${to}';
	@override String get watermark => 'Flymap';
	@override String get flightDistance => 'Distancia del vuelo';
	@override String distanceKm({required Object distance}) => '${distance} km';
}

// Path: shareImage
class _TranslationsShareImageEs extends TranslationsShareImageEn {
	_TranslationsShareImageEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Compartir vuelo';
	@override String get generating => 'Creando tu tarjeta de vuelo...';
	@override String get share => 'Compartir';
	@override String get sharing => 'Compartiendo...';
	@override String get retry => 'Reintentar';
	@override String get error => 'No se pudo generar la tarjeta de vuelo';
	@override String get tagline => 'Cada vuelo es un descubrimiento';
	@override String get brand => 'Flymap';
	@override String get exploreYourFlight => 'Explora tu vuelo';
	@override String get countrySingle => '1 país';
	@override String countries({required Object count}) => '${count} países';
	@override String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) en Flymap ✈️';
	@override String get unknownCity => 'Desconocida';
	@override String get durationUnavailable => '--';
	@override String durationMinutes({required Object minutes}) => '${minutes} min';
	@override String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} h ${minutes} min';
}

// Path: flightVideo
class _TranslationsFlightVideoEs extends TranslationsFlightVideoEn {
	_TranslationsFlightVideoEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vídeo del vuelo';
	@override String get preparing => 'Preparando tu mapa...';
	@override String get rendering => 'Creando tu vídeo...';
	@override String get export => 'Guardar vídeo';
	@override String get savedToGallery => 'Guardado en tu galería';
	@override String get saveSkipped => 'No se pudo guardar en la galería — aún puedes compartirlo';
	@override String get share => 'Compartir';
	@override String get sharing => 'Compartiendo...';
	@override String get retry => 'Reintentar';
	@override String get errorNetwork => 'No se pudieron cargar las imágenes del mapa. Comprueba tu conexión e inténtalo de nuevo.';
	@override String get errorGeneric => 'No se pudo crear el vídeo del vuelo';
	@override String get errorOfflineTitle => 'Estás sin conexión';
	@override String get errorOffline => 'Los vídeos de vuelo cargan imágenes de mapa en tiempo real, así que necesitan conexión a internet. Desactiva el modo avión o vuelve a conectarte e inténtalo de nuevo.';
	@override String get offlineStyleChange => 'Cambiar el estilo del mapa necesita conexión.';
	@override String get madeWith => 'Hecho con Flymap';
	@override String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) en Flymap ✈️';
	@override String get removeWatermark => 'Quitar marca de agua';
	@override String get styleSatellite => 'Satélite';
	@override String get styleDefault => 'Predeterminado';
	@override String get videoSettings => 'Ajustes de video';
	@override String get mapStyle => 'Estilo de mapa';
	@override String get mysteryDestination => 'Destino misterioso';
	@override String get mysteryDestinationHint => 'Mostrar "?" hasta que aterrice el avión';
	@override String get showPins => 'Pines de países';
	@override String get showPinsHint => 'Coloca un pin cuando el avión cruza cada país';
	@override String get showEndCard => 'Tarjeta resumen';
	@override String get showEndCardHint => 'Mostrar la tarjeta resumen al final';
	@override String get styleShine => 'Lè Shine';
	@override String get applySettings => 'Aplicar cambios';
	@override String get applying => 'Aplicando cambios...';
	@override String get avatarTitle => 'Tu avatar';
	@override String get avatarHint => 'Vuela tu ruta con tu propia foto';
	@override String get avatarSetupTitle => 'Tu avatar';
	@override String get avatarPick => 'Elegir foto';
	@override String get avatarChange => 'Cambiar foto';
	@override String get avatarNameLabel => 'Nombre o @usuario';
	@override String get avatarNameHint => 'Opcional: se muestra en la tarjeta de resumen';
	@override String get avatarSave => 'Guardar avatar';
	@override String get mysteryTitle => '¿Adivinas adónde vuelo? ✈️';
	@override String get avatarCardTagline => 'Mi mapa de vuelo';
}

// Path: about
class _TranslationsAboutEs extends TranslationsAboutEn {
	_TranslationsAboutEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Acerca de Flymap';
	@override String get tagline => 'Convierte cada vuelo en una ventana al mundo.';
	@override String get chipCuriosity => 'Curiosidad';
	@override String get chipGeography => 'Geografía';
	@override String get chipAwareness => 'Conciencia';
	@override String get missionTitle => 'Por qué Flymap';
	@override String get missionText => 'Sobrevolamos océanos, montañas y países enteros sin llegar a saberlo. Flymap devuelve el asombro.';
	@override String get valuesTitle => 'Lo que defendemos';
	@override String get valueCuriosityTitle => 'Curiosidad';
	@override String get valueCuriosityText => 'Sé siempre consciente de lo que sobrevuelas.';
	@override String get valueGeographyTitle => 'Geografía';
	@override String get valueGeographyText => 'El mundo se vuelve un atlas vivo.';
	@override String get valueAwarenessTitle => 'Conciencia';
	@override String get valueAwarenessText => 'Reconecta con el viaje en sí.';
	@override String get valueOfflineTitle => 'Offline y privado';
	@override String get valueOfflineText => 'En tu dispositivo. Sin rastreo.';
	@override String get closingTitle => 'Mira el mundo de otra manera';
	@override String get closingText => 'Gracias por explorarlo con nosotros.';
}

// Path: onboarding
class _TranslationsOnboardingEs extends TranslationsOnboardingEn {
	_TranslationsOnboardingEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Omitir';
	@override String get letsStart => 'Empecemos';
	@override String get welcomeTitle => 'Descubre lo que hay debajo';
	@override String get welcomeSubtitle => 'te muestra mapas offline y lugares interesantes a lo largo de tu vuelo';
	@override String get nameTitle => 'Elige un nombre de usuario';
	@override String get nameSubtitle => 'Haz que el descubrimiento sea personal. Puedes cambiarlo en cualquier momento.';
	@override String get nameHint => 'Tu nombre';
	@override String get nameExample => 'Alex';
	@override String get frequencyTitle => '¿Con qué frecuencia vuelas?';
	@override String get frequencySubtitle => 'Flymap personalizará tu experiencia y hará las sugerencias más relevantes';
	@override String get frequencyFirstFlight => 'Este es mi primer vuelo';
	@override String get frequencyFewPerYear => 'Unas pocas veces al año';
	@override String get frequencyMonthly => 'Más o menos cada mes';
	@override String get frequencyFrequent => 'Muy a menudo';
	@override String get homeAirportTitle => 'Configura tu aeropuerto base';
	@override String get homeAirportSubtitle => 'Acelera la creación de vuelos. Puedes cambiarlo en cualquier momento.';
	@override String get homeAirportHint => 'Buscar aeropuerto base';
	@override String get popularAirports => 'Aeropuertos populares';
	@override String get removeHomeAirport => 'Eliminar aeropuerto base';
	@override String get noHomeAirportFound => 'No se encontraron aeropuertos para esa búsqueda.';
	@override String get interestsTitle => '¿Qué lugares quieres ver más en tu mapa?';
	@override String get interestsSubtitle => 'Elige hasta 3 temas para ver lugares e historias más relevantes a lo largo de tu vuelo.';
	@override String get interestsHelper => 'Elige hasta 3 temas.';
	@override String interestsSelected({required Object count, required Object max}) => '${count} de ${max} seleccionados';
	@override String get interestMountains => 'Montañas y cordilleras';
	@override String get interestVolcanoes => 'Volcanes y geología';
	@override String get interestRegions => 'Ciudades y regiones';
	@override String get interestIslands => 'Islas y costas';
	@override String get interestNationalParks => 'Parques nacionales y reservas';
	@override String get interestRivers => 'Ríos y lagos';
	@override String get planFirstFlight => 'Empezar mi primer vuelo';
	@override String get failedLoadProfile => 'No se pudo cargar tu perfil.';
	@override late final _TranslationsOnboardingPayoffEs payoff = _TranslationsOnboardingPayoffEs._(_root);
}

// Path: countries
class _TranslationsCountriesEs extends TranslationsCountriesEn {
	_TranslationsCountriesEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get AE => 'Emiratos Arabes Unidos';
	@override String get AF => 'Afganistan';
	@override String get AG => 'Antigua y Barbuda';
	@override String get AL => 'Albania';
	@override String get AM => 'Armenia';
	@override String get AO => 'Angola';
	@override String get AR => 'Argentina';
	@override String get AT => 'Austria';
	@override String get AU => 'Australia';
	@override String get AZ => 'Azerbaiyan';
	@override String get BA => 'Bosnia y Herzegovina';
	@override String get BB => 'Barbados';
	@override String get BD => 'Banglades';
	@override String get BE => 'Belgica';
	@override String get BF => 'Burkina Faso';
	@override String get BG => 'Bulgaria';
	@override String get BH => 'Barein';
	@override String get BI => 'Burundi';
	@override String get BJ => 'Benin';
	@override String get BN => 'Brunei';
	@override String get BO => 'Bolivia';
	@override String get BR => 'Brasil';
	@override String get BS => 'Bahamas';
	@override String get BT => 'Butan';
	@override String get BW => 'Botsuana';
	@override String get BY => 'Bielorrusia';
	@override String get BZ => 'Belice';
	@override String get CA => 'Canada';
	@override String get CD => 'Republica Democratica del Congo';
	@override String get CF => 'Republica Centroafricana';
	@override String get CG => 'Congo';
	@override String get CH => 'Suiza';
	@override String get CI => 'Costa de Marfil';
	@override String get CL => 'Chile';
	@override String get CM => 'Camerun';
	@override String get CN => 'China';
	@override String get CO => 'Colombia';
	@override String get CR => 'Costa Rica';
	@override String get CU => 'Cuba';
	@override String get CV => 'Cabo Verde';
	@override String get CY => 'Chipre';
	@override String get CZ => 'Republica Checa';
	@override String get DE => 'Alemania';
	@override String get DJ => 'Yibuti';
	@override String get DK => 'Dinamarca';
	@override String get DO => 'Republica Dominicana';
	@override String get DZ => 'Argelia';
	@override String get EC => 'Ecuador';
	@override String get EE => 'Estonia';
	@override String get EG => 'Egipto';
	@override String get EH => 'Sahara Occidental';
	@override String get ER => 'Eritrea';
	@override String get ES => 'Espana';
	@override String get ET => 'Etiopia';
	@override String get FI => 'Finlandia';
	@override String get FJ => 'Fiyi';
	@override String get FR => 'Francia';
	@override String get GA => 'Gabon';
	@override String get GB => 'Reino Unido';
	@override String get GE => 'Georgia';
	@override String get GF => 'Guayana Francesa';
	@override String get GH => 'Ghana';
	@override String get GM => 'Gambia';
	@override String get GN => 'Guinea';
	@override String get GP => 'Guadalupe';
	@override String get GQ => 'Guinea Ecuatorial';
	@override String get GR => 'Grecia';
	@override String get GT => 'Guatemala';
	@override String get GW => 'Guinea-Bisau';
	@override String get GY => 'Guyana';
	@override String get HK => 'Hong Kong, China';
	@override String get HN => 'Honduras';
	@override String get HR => 'Croacia';
	@override String get HT => 'Haiti';
	@override String get HU => 'Hungria';
	@override String get ID => 'Indonesia';
	@override String get IE => 'Irlanda';
	@override String get IL => 'Israel';
	@override String get IN => 'India';
	@override String get IQ => 'Irak';
	@override String get IR => 'Iran';
	@override String get IS => 'Islandia';
	@override String get IT => 'Italia';
	@override String get JM => 'Jamaica';
	@override String get JO => 'Jordania';
	@override String get JP => 'Japon';
	@override String get KE => 'Kenia';
	@override String get KG => 'Kirguistan';
	@override String get KH => 'Camboya';
	@override String get KM => 'Comoras';
	@override String get KP => 'Corea del Norte';
	@override String get KR => 'Corea del Sur';
	@override String get KW => 'Kuwait';
	@override String get KZ => 'Kazajistan';
	@override String get LA => 'Laos';
	@override String get LB => 'Libano';
	@override String get LK => 'Sri Lanka';
	@override String get LR => 'Liberia';
	@override String get LS => 'Lesoto';
	@override String get LT => 'Lituania';
	@override String get LU => 'Luxemburgo';
	@override String get LV => 'Letonia';
	@override String get LY => 'Libia';
	@override String get MA => 'Marruecos';
	@override String get MD => 'Moldavia';
	@override String get ME => 'Montenegro';
	@override String get MG => 'Madagascar';
	@override String get MK => 'Macedonia del Norte';
	@override String get ML => 'Mali';
	@override String get MM => 'Myanmar';
	@override String get MN => 'Mongolia';
	@override String get MO => 'Macao, China';
	@override String get MQ => 'Martinica';
	@override String get MR => 'Mauritania';
	@override String get MU => 'Mauricio';
	@override String get MV => 'Maldivas';
	@override String get MW => 'Malaui';
	@override String get MT => 'Malta';
	@override String get MX => 'Mexico';
	@override String get MY => 'Malasia';
	@override String get MZ => 'Mozambique';
	@override String get NA => 'Namibia';
	@override String get NC => 'Nueva Caledonia';
	@override String get NE => 'Niger';
	@override String get NG => 'Nigeria';
	@override String get NI => 'Nicaragua';
	@override String get NL => 'Paises Bajos';
	@override String get NO => 'Noruega';
	@override String get NP => 'Nepal';
	@override String get NZ => 'Nueva Zelanda';
	@override String get OM => 'Oman';
	@override String get PA => 'Panama';
	@override String get PE => 'Peru';
	@override String get PG => 'Papua Nueva Guinea';
	@override String get PH => 'Filipinas';
	@override String get PK => 'Pakistan';
	@override String get PL => 'Polonia';
	@override String get PR => 'Puerto Rico';
	@override String get PS => 'Cisjordania y Franja de Gaza';
	@override String get PT => 'Portugal';
	@override String get PY => 'Paraguay';
	@override String get QA => 'Catar';
	@override String get RE => 'La Reunion';
	@override String get RO => 'Rumania';
	@override String get RS => 'Serbia';
	@override String get RU => 'Rusia';
	@override String get RW => 'Ruanda';
	@override String get SA => 'Arabia Saudita';
	@override String get SB => 'Islas Salomon';
	@override String get SD => 'Sudan';
	@override String get SE => 'Suecia';
	@override String get SG => 'Singapur';
	@override String get SI => 'Eslovenia';
	@override String get SK => 'Eslovaquia';
	@override String get SL => 'Sierra Leona';
	@override String get SN => 'Senegal';
	@override String get SO => 'Somalia';
	@override String get SR => 'Surinam';
	@override String get SS => 'Sudan del Sur';
	@override String get ST => 'Santo Tome y Principe';
	@override String get SV => 'El Salvador';
	@override String get SY => 'Siria';
	@override String get SZ => 'Esuatini';
	@override String get TD => 'Chad';
	@override String get TG => 'Togo';
	@override String get TH => 'Tailandia';
	@override String get TJ => 'Tayikistan';
	@override String get TL => 'Timor Oriental';
	@override String get TM => 'Turkmenistan';
	@override String get TN => 'Tunez';
	@override String get TR => 'Turquia';
	@override String get TT => 'Trinidad y Tobago';
	@override String get TW => 'Taiwan, China';
	@override String get TZ => 'Tanzania';
	@override String get UA => 'Ucrania';
	@override String get UG => 'Uganda';
	@override String get US => 'Estados Unidos';
	@override String get UY => 'Uruguay';
	@override String get UZ => 'Uzbekistan';
	@override String get VE => 'Venezuela';
	@override String get VI => 'Islas Virgenes de EE. UU.';
	@override String get VN => 'Vietnam';
	@override String get YE => 'Yemen';
	@override String get ZA => 'Sudafrica';
	@override String get ZM => 'Zambia';
	@override String get ZW => 'Zimbabue';
}

// Path: home.sort
class _TranslationsHomeSortEs extends TranslationsHomeSortEn {
	_TranslationsHomeSortEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mostRecent => 'Más reciente';
	@override String get longest => 'Más largo';
	@override String get alphabetical => 'A-Z';
}

// Path: learn.geoQuiz
class _TranslationsLearnGeoQuizEs extends TranslationsLearnGeoQuizEn {
	_TranslationsLearnGeoQuizEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Geo Quiz';
	@override String get geographyTitle => 'Geografía';
	@override String get geographySubtitle => 'Mares, cordilleras, lagos, islas y más';
	@override String get countriesTitle => 'Países en el mapa';
	@override String get subtitle => 'Adivina el país por su contorno';
	@override String get loading => 'Cargando Geo Quiz...';
	@override String get failedToLoad => 'No se pudieron cargar los cuestionarios';
	@override String get failedToLoadQuiz => 'No se pudo cargar el cuestionario';
	@override String get emptyTitle => 'Aún no hay cuestionarios';
	@override String get emptySubtitle => 'Los geo quizzes aparecerán aquí pronto.';
	@override String get countryHint => 'Nombre de la región...';
	@override String progressCount({required Object solved, required Object total}) => '${solved} / ${total}';
	@override String nextCount({required Object next, required Object total}) => '${next} de ${total}';
	@override String correctCount({required Object count}) => '${count} correctos';
	@override String get reset => 'Restablecer progreso';
	@override String get mapPlaceholder => 'Los datos del mapa se agregarán después';
	@override String get newBadge => 'NUEVO';
	@override String get correct => 'Correcto';
	@override String get wrong => 'Incorrecto';
	@override String get hintTitle => 'Pista';
	@override String get hintSubtitle => 'Toca una letra para revelarla';
	@override String get next => 'Siguiente';
	@override String get pause => 'Pausar';
	@override String get resume => 'Reanudar';
	@override String get finish => 'Finalizar';
	@override String get completeTitle => 'Cuestionario completado';
	@override String completeMessage({required Object total, required Object quiz}) => 'Encontraste los ${total} países de ${quiz}.';
	@override String get backToQuizzes => 'Volver a los cuestionarios';
	@override String get playAgain => 'Jugar de nuevo';
	@override String get progressReady => 'Listo para jugar';
	@override String progressFinished({required Object count}) => '${count} terminados';
	@override String progressInProgress({required Object count}) => '${count} en curso';
	@override String get progressAllCompleted => 'Todos completados';
	@override String get quizCountriesAfricaTitle => 'África';
	@override String get quizCountriesEuropeTitle => 'Europa';
	@override String get quizCountriesAsiaTitle => 'Asia';
	@override String get quizCountriesNorthAmericaTitle => 'Norteamérica';
	@override String get quizCountriesSouthAmericaTitle => 'Sudamérica';
	@override String get quizCountriesOceaniaTitle => 'Oceanía';
	@override String get quizCountriesAllTitle => 'Todos los países';
	@override String get quizCountriesSubtitle => 'Países';
	@override String get quizCountriesAllSubtitle => 'Mundo';
	@override String get quizGeographySeasTitle => 'Mares';
	@override String get quizGeographyMountainRangesTitle => 'Cordilleras';
	@override String get quizGeographyLakesTitle => 'Lagos';
	@override String get quizGeographyIslandsTitle => 'Islas';
	@override String get quizGeographyOtherTitle => 'Otros';
	@override String get quizGeographyOtherSubtitle => 'Bahías, estrechos, golfos, desiertos y más';
	@override String get descriptionUnavailable => 'La descripción aún no está disponible.';
}

// Path: createFlight.steps
class _TranslationsCreateFlightStepsEs extends TranslationsCreateFlightStepsEn {
	_TranslationsCreateFlightStepsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get departureTitle => 'Elegir aeropuerto de salida';
	@override String get arrivalTitle => 'Elegir aeropuerto de llegada';
	@override String get routeNotSupportedTitle => 'Ruta no compatible';
	@override String get mapPreviewTitle => 'Vista previa del mapa';
	@override String get overviewTitle => 'Resumen de la ruta';
	@override String get wikipediaTitle => 'Artículos de Wikipedia';
	@override String get weatherTitle => 'Clima del vuelo';
}

// Path: createFlight.weather
class _TranslationsCreateFlightWeatherEs extends TranslationsCreateFlightWeatherEn {
	_TranslationsCreateFlightWeatherEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => '¿Verás el suelo?';
	@override String get loading => 'Comprobando el cielo a lo largo de tu ruta…';
	@override String get loadFailed => 'No se pudo cargar el pronóstico ahora mismo. Reintenta o continúa sin él.';
	@override String get departureLabel => 'Salida';
	@override String get arrivalLabel => 'Llegada';
	@override String get tomorrow => 'mañana';
	@override String get verdictClearTitle => 'Vistas despejadas';
	@override String get verdictClearBody => 'El asiento de ventanilla merece la pena: el suelo debería verse casi todo el vuelo.';
	@override String get verdictPatchyTitle => 'Nubes dispersas';
	@override String get verdictPatchyBody => 'Las vistas irán y vendrán entre las nubes.';
	@override String get verdictCarpetTitle => 'Manto de nubes debajo';
	@override String get verdictCarpetBody => 'Un mar blanco de nubes bajo el avión: precioso, pero el suelo quedará casi siempre oculto.';
	@override String get verdictOvercastTitle => 'Cielo cubierto';
	@override String get verdictOvercastBody => 'Las mejores vistas serán en el despegue y el aterrizaje.';
	@override String get windCalm => 'Calma';
	@override String get windLight => 'Viento suave';
	@override String get windBreezy => 'Brisa';
	@override String get windWindy => 'Ventoso';
	@override String get windStrong => 'Viento fuerte';
	@override String windTakeoff({required Object city, required Object speed}) => 'Despegue con viento en ${city} (${speed} m/s): puede haber baches';
	@override String windLanding({required Object city, required Object speed}) => 'Aterrizaje con viento en ${city} (${speed} m/s): puede haber baches';
	@override String get proTeaserTitle => 'Mapa de nubes de tu ruta';
	@override String get proTeaserBody => 'Mira dónde estarán las nubes y observa tu avión volar toda la ruta por encima de ellas.';
	@override String get attribution => 'Datos meteorológicos: MET Norway';
	@override String get hedge => 'Los pronósticos se afinan cuanto más cerca está la salida.';
	@override String get share => 'Compartir';
	@override String get shareAsImage => 'Compartir como imagen';
	@override String get shareAsVideo => 'Compartir como vídeo';
	@override String get preparingShare => 'Preparando para compartir…';
	@override String get shareFailed => 'No se pudo preparar — inténtalo de nuevo.';
	@override String updatedAt({required Object time}) => 'Actualizado ${time}';
}

// Path: createFlight.routeTypeSelector
class _TranslationsCreateFlightRouteTypeSelectorEs extends TranslationsCreateFlightRouteTypeSelectorEn {
	_TranslationsCreateFlightRouteTypeSelectorEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nuevo vuelo';
	@override String get basicTitle => 'Ruta aproximada';
	@override String get basicSubtitle => 'Desde aeropuertos';
	@override String get basicDescription => 'Funciona bien para vuelos cortos y muchos de media distancia.';
	@override String get proTitle => 'Ruta real';
	@override String get proSubtitle => 'Desde vuelos recientes';
	@override String get proDescription => 'Construida a partir de la ruta registrada más reciente del mismo vuelo.';
	@override String get mostAccurate => 'Más precisa';
}

// Path: createFlight.proAccess
class _TranslationsCreateFlightProAccessEs extends TranslationsCreateFlightProAccessEn {
	_TranslationsCreateFlightProAccessEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get subscriber => 'Flymap Pro';
	@override String get subscriberBody => 'Este vuelo tiene acceso Pro completo mediante tu suscripción de Flymap Pro.';
	@override String get unlockedFlight => 'Este vuelo está desbloqueado';
	@override String get unlockedFlightBody => 'Todas las funciones Pro están activadas para este vuelo.';
	@override String get tooltip => 'Información de acceso Pro';
}

// Path: createFlight.travelDate
class _TranslationsCreateFlightTravelDateEs extends TranslationsCreateFlightTravelDateEn {
	_TranslationsCreateFlightTravelDateEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String inDays({required Object count}) => 'En ${count} días';
	@override String get today => 'Hoy';
	@override String get tomorrow => 'Mañana';
	@override String get stepTitle => '¿Cuándo vuelas?';
	@override String get customDate => 'Elegir otra fecha';
	@override String get pickDate => 'Elige tu fecha de viaje';
	@override String get yourFlightOnDate => 'Tu vuelo en esta fecha';
	@override String get changeDate => 'Cambiar fecha';
	@override String get checkingSchedule => 'Comprobando el horario del vuelo…';
	@override String get noDateYet => 'Sin fecha aún';
	@override String get skipDate => 'Continuar sin fecha';
	@override String get addDepartureTime => 'Añadir hora de salida (opcional)';
	@override String departureTimeAt({required Object time}) => 'Hora de salida · ${time}';
	@override String get noDepartureOnDateTitle => 'No encontramos este vuelo en esta fecha';
	@override String get noDepartureOnDateBody => 'Revisa la fecha — tócala para cambiarla. O continúa igualmente y guardaremos solo la fecha.';
	@override String get dateCheckFailed => 'No se pudo comprobar esta fecha — se guarda solo la fecha.';
}

// Path: createFlight.flightNumberSearch
class _TranslationsCreateFlightFlightNumberSearchEs extends TranslationsCreateFlightFlightNumberSearchEn {
	_TranslationsCreateFlightFlightNumberSearchEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Número de vuelo';
	@override String get subtitle => 'Introduce un número de vuelo (por ejemplo BA117).';
	@override String get hint => 'p. ej. BA117';
	@override String get loading => 'Buscando tu vuelo';
	@override String get loadingHint => 'Esto puede tardar unos segundos mientras comprobamos vuelos recientes.';
	@override String get invalidFormatError => 'Introduce un número de vuelo válido, como BA117.';
	@override String get notFoundError => 'No pudimos encontrar ese número de vuelo. Revísalo e inténtalo de nuevo o búscalo por aeropuertos.';
	@override String get rateLimitedError => 'Hay demasiadas búsquedas de vuelos en este momento. Inténtalo de nuevo en un momento o búscalo por aeropuertos.';
	@override String get providerUnavailableError => 'Los datos del vuelo no están disponibles temporalmente. Inténtalo de nuevo en un momento o búscalo por aeropuertos.';
	@override String get unexpectedError => 'Se produjo un error al buscar este vuelo. Inténtalo de nuevo o búscalo por aeropuertos.';
	@override String get findByAirports => 'Buscar por aeropuertos';
	@override String get airportsFallbackButton => 'Buscar por aeropuertos';
	@override String get confirmTitle => 'Confirmar vuelo';
	@override String get foundTitle => 'Hemos encontrado tu vuelo';
	@override String get editFlightNumber => 'Editar número de vuelo';
	@override String get beyondWindowHint => '¿Vuelas más adelante? Para obtener el mapa de vuelo más actualizado y preciso, te recomendamos descargarlo dentro de los 7 días previos a tu vuelo.';
	@override String get basedOnSameFlightOn => '* Basado en la ruta registrada más reciente para el mismo vuelo';
}

// Path: createFlight.realRouteAirportSearch
class _TranslationsCreateFlightRealRouteAirportSearchEs extends TranslationsCreateFlightRealRouteAirportSearchEn {
	_TranslationsCreateFlightRealRouteAirportSearchEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Buscar vuelos reales por aeropuertos';
	@override String get subtitle => 'Elige los aeropuertos de salida y llegada para buscar vuelos reales recientes en esta ruta.';
	@override String get searchAction => 'Buscar vuelos recientes';
	@override String get loading => 'Buscando vuelos reales recientes';
	@override String get loadingHint => 'Esto puede tardar unos segundos mientras revisamos el historial reciente de la ruta.';
	@override String sorryNoFlightFromTo({required Object departure, required Object arrival}) => 'Lo sentimos, no pudimos encontrar vuelos de ${departure} a ${arrival}.';
	@override String get emptyTitle => 'No pudimos encontrar vuelos recientes entre estos aeropuertos';
	@override String get emptyResults => 'Asegúrate de haber seleccionado los mismos aeropuertos de salida y llegada que aparecen en tu billete de vuelo.';
	@override String get searchReverse => 'Probar la dirección inversa';
	@override String get rateLimitedError => 'Hay demasiadas búsquedas de vuelos en este momento. Inténtalo de nuevo en un momento.';
	@override String get providerUnavailableError => 'Los datos de vuelos reales no están disponibles temporalmente. Inténtalo de nuevo en un momento.';
	@override String get unexpectedError => 'Se produjo un error al buscar esta ruta. Inténtalo de nuevo.';
	@override String foundOneTitle({required Object route}) => 'Se encontró 1 vuelo · ${route}';
	@override String foundManyTitle({required Object count, required Object route}) => 'Se encontraron ${count} vuelos · ${route}';
	@override String get ticketMatchHint => 'Asegúrate de que coincidan con los aeropuertos de tu billete de vuelo.';
	@override String get findByFlightNumber => 'Buscar por número de vuelo';
}

// Path: createFlight.search
class _TranslationsCreateFlightSearchEs extends TranslationsCreateFlightSearchEn {
	_TranslationsCreateFlightSearchEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get departureHint => 'Buscar aeropuerto de salida';
	@override String get arrivalHint => 'Buscar aeropuerto de llegada';
	@override String get removeFavorite => 'Eliminar favorito';
	@override String get addFavorite => 'Añadir a favoritos';
	@override String get removeSelectedAirport => 'Eliminar aeropuerto seleccionado';
	@override String get favorites => 'Favoritos';
	@override String get recentAirports => 'Aeropuertos recientes';
	@override String get popularAirports => 'Aeropuertos populares';
	@override String get removeFromFavorites => 'Eliminar de favoritos';
	@override String get noDepartureFound => 'No se encontraron aeropuertos de salida.';
	@override String get noArrivalFound => 'No se encontraron aeropuertos de llegada.';
	@override String airportCodeCity({required Object code, required Object city}) => '${code} · ${city}';
	@override String airportNameCode({required Object name, required Object code}) => '${name} (${code})';
}

// Path: createFlight.mapPreview
class _TranslationsCreateFlightMapPreviewEs extends TranslationsCreateFlightMapPreviewEn {
	_TranslationsCreateFlightMapPreviewEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get routeNotSupportedMsg => 'Lo sentimos, los vuelos que cruzan el antimeridiano aún no son compatibles.';
	@override String get basic => 'Básico';
	@override String get pro => 'Pro';
	@override String get mapDetailInfoTooltip => 'Nota sobre la ruta';
	@override String get legendButton => 'Leyenda';
	@override String get legendTitle => 'Leyenda de PDI';
	@override String estimatedMapSize({required Object size}) => 'Tamaño estimado del mapa: ${size}';
	@override String get upgradeToPro => 'Pasar a Pro';
	@override String get basicHint => 'Detalle básico del mapa con lugares limitados';
	@override String get proGateHint => 'Mejora para obtener un mapa detallado con todos los lugares';
	@override String proHint({required Object count}) => 'Mapa offline detallado con ${count} lugares';
	@override String get optionsTitle => 'Ruta aproximada';
	@override String get optionsBody => 'La ruta es aproximada; el trayecto real puede variar, especialmente en vuelos de larga distancia.';
}

// Path: createFlight.overview
class _TranslationsCreateFlightOverviewEs extends TranslationsCreateFlightOverviewEn {
	_TranslationsCreateFlightOverviewEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get routeNotReady => 'La ruta aún no está lista.';
	@override String get proPoiUpsell => 'El plan Free incluye mapa básico y lugares limitados';
	@override String get routeNoteTooltip => 'Nota sobre la ruta';
	@override String get routeNoteTitle => 'Ruta aproximada';
	@override String get routeNoteBody => 'La ruta es aproximada; el trayecto real puede variar, especialmente en vuelos de larga distancia.';
	@override String get realRouteNoteTitle => 'Ruta real';
	@override String get realRouteNoteBody => 'Esta ruta se basa en la ruta registrada más reciente para el mismo vuelo.\nLa ruta real puede variar debido al clima, al tráfico aéreo y a restricciones operativas.';
	@override String get approximateRouteLongHaulWarningTitle => 'Esta es una ruta aproximada';
	@override String get approximateRouteLongHaulWarningBody => 'Las rutas aproximadas pueden ser inexactas para vuelos de larga distancia. Usa una ruta real con un número de vuelo.';
	@override String get approximateRouteUltraLongHaulUnsupportedBody => 'Las rutas aproximadas no son compatibles con vuelos ultralargos. Usa una ruta real con un número de vuelo.';
	@override String get startReview => 'Empezar revisión';
	@override String get skipReview => 'Omitir revisión';
	@override String get premiumGateTitle => 'Desbloquear resumen completo de la ruta';
	@override String get premiumGateBody => 'El plan Free incluye una vista previa limitada de la ruta. Mejora a Pro para ver todas las regiones de esta ruta.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Desbloquea las ${count} regiones de esta ruta con Pro.';
	@override String get premiumGateCta => 'Pasar a Pro';
	@override String get buildingHint => 'En rutas largas esto puede tardar unos segundos…';
	@override String get routeReviewedTitle => 'Ruta revisada';
	@override String routeReviewedSubtitle({required Object regions, required Object departure, required Object arrival}) => 'Volarás sobre ${regions} desde ${departure} hasta ${arrival}.';
	@override String get fullSummary => 'Resumen completo';
	@override String get routeSummaryTitle => 'Resumen de la ruta';
	@override String get routeSummaryDistanceLabel => 'Distancia';
	@override String get routeSummaryDurationLabel => 'Duración';
	@override String get routeSummaryRegionsLabel => 'Regiones';
	@override String get routeSummaryRegionsTitle => 'Sobrevolarás';
	@override String get routeSummaryPlacesLabel => 'Lugares';
	@override String get routeSummaryTimelineTitle => 'Cronología';
	@override String get routeSummaryPlacesTitle => 'Lugares a lo largo de la ruta';
	@override String get routeSummaryPoiSearchHint => 'Buscar lugares';
	@override String get routeSummaryPoiNoMatches => 'Ningún lugar coincide con tu búsqueda.';
	@override late final _TranslationsCreateFlightOverviewAirportCardEs airportCard = _TranslationsCreateFlightOverviewAirportCardEs._(_root);
	@override late final _TranslationsCreateFlightOverviewRegionInfoEs regionInfo = _TranslationsCreateFlightOverviewRegionInfoEs._(_root);
	@override late final _TranslationsCreateFlightOverviewTimelineEs timeline = _TranslationsCreateFlightOverviewTimelineEs._(_root);
}

// Path: createFlight.wikipedia
class _TranslationsCreateFlightWikipediaEs extends TranslationsCreateFlightWikipediaEn {
	_TranslationsCreateFlightWikipediaEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Descarga artículos y lee mientras estás en el aire';
	@override String get loadingIntro => 'Buscando artículos relacionados con la ruta...';
	@override String foundIntro({required Object count}) => 'Según tu ruta, encontramos ${count} artículos relevantes';
	@override String get emptyIntro => 'No se encontraron artículos de Wikipedia relacionados con la ruta. Puedes continuar descargando solo el mapa.';
	@override String selectedCount({required Object count}) => '${count} seleccionados';
	@override String get unselectAll => 'Deseleccionar todo';
	@override String get selectAll => 'Seleccionar todo';
	@override String basicHint({required Object count}) => 'Artículos offline seleccionados: ${count}';
	@override String get proHint => 'Mapa y paquete de datos offline';
	@override String get proGateHint => 'Mejora para obtener el paquete completo de artículos offline';
	@override String get proActiveTitle => 'Pro activo';
	@override String get proActiveMessage => 'Paquete completo de artículos desbloqueado.';
	@override String get freeLimitHint => 'El plan Free incluye hasta 3 artículos offline';
	@override String estimatedDownloadSize({required Object size}) => 'Tamaño estimado de descarga: ${size}';
	@override String get upgrade => 'Pasar a Pro';
	@override String get loadingSuggestions => 'Cargando sugerencias de artículos...';
	@override String get downloadMapOnly => 'Descargar mapa';
	@override String get downloadMapPlusOne => 'Descargar mapa + 1 artículo';
	@override String downloadMapPlusMany({required Object count}) => 'Descargar mapa + ${count} artículos';
	@override String get couldNotOpenLink => 'No se pudo abrir el enlace';
}

// Path: createFlight.downloading
class _TranslationsCreateFlightDownloadingEs extends TranslationsCreateFlightDownloadingEn {
	_TranslationsCreateFlightDownloadingEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get articlesTitle => 'Descargando artículos seleccionados...';
	@override String get mapTitle => 'Descargando mapa offline...';
	@override String get mapSectionTitle => 'Mapa';
	@override String get poiSectionTitle => 'Lugares';
	@override String get articlesSectionTitle => 'Artículos';
	@override String get cancelDownload => 'Cancelar descarga';
	@override String get doNotClose => 'No cierres esta pantalla hasta que se complete la descarga';
	@override String get currentStep => 'Actual';
	@override String get pending => 'Pendiente';
	@override String get inProgress => 'En curso';
	@override String get completed => 'Completado';
	@override String get completedWithIssues => 'Completado con incidencias';
	@override String get failed => 'Fallido';
	@override String get skipped => 'Omitido';
	@override String get waitingForMap => 'Esperando la descarga del mapa...';
	@override String get mapFailed => 'La descarga del mapa falló.';
	@override String get noPoiSelected => 'No se seleccionaron resúmenes de lugares.';
	@override String get preparingPoi => 'Preparando resúmenes de lugares...';
	@override String poiProgress({required Object completed, required Object total}) => 'Lugares: ${completed}/${total}';
	@override String poiProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Lugares: ${completed}/${total} (${failed} fallidos)';
	@override String get noArticlesSelected => 'No se seleccionaron artículos.';
	@override String get preparingArticles => 'Preparando descargas de artículos...';
	@override String articlesProgress({required Object completed, required Object total}) => 'Artículos: ${completed}/${total}';
	@override String articlesProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Artículos: ${completed}/${total} (${failed} fallidos)';
	@override String get preparingMap => 'Preparando descarga del mapa...';
	@override String get computingTiles => 'Calculando teselas del mapa...';
	@override String computingTilesWithCount({required Object count}) => 'Calculando teselas del mapa (${count})...';
	@override String get preparingForDownload => 'Preparando la descarga...';
	@override String downloaded({required Object size}) => 'Descargado: ${size}';
	@override String get finalizing => 'Finalizando el paquete del mapa...';
	@override String get verifying => 'Verificando el paquete del mapa...';
}

// Path: createFlight.errors
class _TranslationsCreateFlightErrorsEs extends TranslationsCreateFlightErrorsEn {
	_TranslationsCreateFlightErrorsEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get failedLoadAirports => 'No se pudieron cargar los aeropuertos. Inténtalo de nuevo.';
	@override String get airportSearchFailed => 'La búsqueda de aeropuertos falló. Prueba otra consulta.';
	@override String get someArticlesFailed => 'Algunos artículos fallaron. Continuando con la descarga del mapa.';
	@override String get someOptionalDownloadsFailed => 'Mapa descargado. No se pudo descargar parte del contenido opcional.';
	@override String get failedBuildPreview => 'No se pudo generar la vista previa de la ruta. Inténtalo de nuevo.';
	@override String get overviewUnavailableContinue => 'No se pudo cargar el resumen de la ruta. Aun así puedes continuar.';
	@override String get noInternet => 'Sin conexión a internet. Comprueba tu conexión e inténtalo de nuevo.';
	@override String failedStartDownload({required Object error}) => 'No se pudo iniciar la descarga: ${error}';
}

// Path: createFlight.paywall
class _TranslationsCreateFlightPaywallEs extends TranslationsCreateFlightPaywallEn {
	_TranslationsCreateFlightPaywallEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get upgradeCancelled => 'Actualización cancelada.';
	@override String get noPaywall => 'No hay pantalla de pago disponible en este momento.';
	@override String get failedOpenPaywall => 'No se pudo abrir la pantalla de pago.';
}

// Path: createFlight.realRouteChoice
class _TranslationsCreateFlightRealRouteChoiceEs extends TranslationsCreateFlightRealRouteChoiceEn {
	_TranslationsCreateFlightRealRouteChoiceEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => '¿Obtener la ruta real del vuelo?';
	@override String get body => 'Todo en este vuelo está desbloqueado. Aún usa una ruta aproximada — introduce tu número de vuelo y lo reconstruiremos con la trayectoria real.';
	@override String get ctaEnterFlightNumber => 'Introducir mi número de vuelo';
	@override String get ctaKeepRoute => 'Mantener ruta aproximada';
}

// Path: flight.map
class _TranslationsFlightMapEs extends TranslationsFlightMapEn {
	_TranslationsFlightMapEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get initializing => 'Cargando mapa';
	@override String get loadingStyle => 'Cargando mapa';
	@override String get offlineNotAvailable => 'El mapa offline no está disponible para este vuelo.';
	@override String get offlineMissing => 'Falta el archivo del mapa offline. Vuelve a descargar esta ruta.';
	@override String get validationFailed => 'La validación del mapa offline falló. Vuelve a descargar esta ruta.';
	@override String get loadStyleFailed => 'No se pudo cargar el estilo del mapa offline.';
	@override String sunriseInMinutes({required Object minutes}) => 'Amanecer en ${minutes} min';
	@override String sunsetInMinutes({required Object minutes}) => 'Atardecer en ${minutes} min';
	@override String get switchTo2D => 'Cambiar a 2D';
	@override String get switchTo3D => 'Cambiar a 3D';
	@override String get switchToLightMapStyle => 'Cambiar al estilo de mapa claro';
	@override String get switchToDarkMapStyle => 'Cambiar al estilo de mapa oscuro';
	@override String get uncenterMap => 'Descentrar mapa';
	@override String get centerOnMe => 'Centrar en mí';
}

// Path: flight.dashboard
class _TranslationsFlightDashboardEs extends TranslationsFlightDashboardEn {
	_TranslationsFlightDashboardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get gpsOffTitle => 'Los servicios de ubicación están desactivados';
	@override String get gpsOffSubtitle => 'Activa los servicios de ubicación en los ajustes del sistema para reanudar el seguimiento del vuelo en vivo y el seguimiento del mapa.';
	@override String get openLocationSettings => 'Abrir ajustes de ubicación';
	@override String get permissionTitle => 'Permiso de ubicación requerido';
	@override String get permissionSubtitle => 'Permite el acceso a la ubicación para que el panel pueda mostrar rumbo, velocidad y altitud en vivo.';
	@override String get grantPermissions => 'Conceder permisos';
	@override String gpsAccuracy({required Object label, required Object accuracy}) => 'Precisión GPS: ${label} (±${accuracy} m)';
	@override String get accuracyExcellent => 'Excelente';
	@override String get accuracyGood => 'Buena';
	@override String get accuracyPoor => 'Baja';
	@override String get gpsOff => 'GPS apagado';
	@override String get gpsOffHint => 'Activa los servicios de ubicación para empezar el seguimiento.';
	@override String get gpsPermissionRequired => 'Permiso de GPS requerido';
	@override String get gpsPermissionHint => 'Concede permiso para acceder a la telemetría en vivo del vuelo.';
	@override String get gpsSearching => 'Buscando GPS';
	@override String get gpsSearchingHint => 'Buscando una señal fiable';
	@override String gpsSearchingHintWithAge({required Object age}) => 'Buscando GPS. Última posición ${age}.';
	@override String get gpsWeak => 'Señal GPS débil';
	@override String get gpsWeakHint => 'La señal es inestable. Mantén el dispositivo con cielo abierto.';
	@override String gpsWeakHintWithAge({required Object age}) => 'Señal inestable. Última posición ${age}.';
	@override String get gpsActive => 'GPS activo';
	@override String get gpsActiveHint => 'Recibiendo telemetría en vivo.';
	@override String gpsActiveHintWithAge({required Object age}) => 'Última actualización GPS ${age}.';
	@override String get gpsShowingLastKnownData => 'Mostrando los últimos datos conocidos';
	@override String get gpsHelpTooltip => 'Solución de problemas de GPS';
	@override String get gpsHelpTitle => 'Solución de problemas de GPS';
	@override String get gpsHelpBody => 'Parece que la señal GPS no es fiable en tu teléfono.';
	@override String get gpsHelpStepsTitle => 'Prueba esto';
	@override String get gpsHelpTipLocation => 'Asegúrate de que los servicios de ubicación estén activados';
	@override String get gpsHelpTipWindow => 'Acerca el teléfono a la ventana';
	@override String get gpsHelpTipCase => 'Quita fundas gruesas o accesorios metálicos';
	@override String get gpsHelpTipFlat => 'Mantén el teléfono quieto unos momentos';
	@override String get gpsHelpFooter => 'El seguimiento en vivo se reanudará automáticamente cuando la señal se estabilice.';
	@override String get ageJustNow => 'ahora mismo';
	@override String ageSeconds({required Object seconds}) => 'hace ${seconds} s';
	@override String ageMinutes({required Object minutes}) => 'hace ${minutes} min';
	@override String get signalGood => 'Buena';
	@override String get signalPoor => 'Baja';
	@override String get signalBad => 'Mala';
	@override String get signalSearching => 'Buscando';
	@override String gpsQuality({required Object quality}) => 'GPS ${quality}';
	@override String get gpsSearchingLabel => 'Buscando GPS';
	@override String get gpsPermissionNeededLabel => 'Permiso de GPS necesario';
	@override String get gpsOffLabel => 'GPS apagado';
	@override String get aircraftHeading => 'Rumbo de la aeronave';
	@override String headingShort({required Object heading}) => 'HDG ${heading}°';
	@override String get liveInstruments => 'Instrumentos en vivo';
	@override String get groundSpeed => 'Velocidad sobre el suelo';
	@override String get altitudeMsl => 'Altitud AMSL';
	@override String get outsideAirApprox => 'Temperatura exterior';
	@override String temperatureAvailableAfter({required Object threshold}) => 'Disponible después de ${threshold}';
	@override String get temperatureApproxHint => 'Estimación aproximada según la altitud';
	@override String get headingPanel => 'Rumbo';
	@override String get flightPhaseTaxi => 'Rodaje';
	@override String get flightPhaseGroundRoll => 'Carrera en tierra';
	@override String get flightPhaseTakeoffRoll => 'Carrera de despegue';
	@override String get flightPhaseLandingRoll => 'Carrera de aterrizaje';
	@override String get flightPhaseAscending => 'Ascendiendo';
	@override String get flightPhaseCruising => 'Crucero';
	@override String get flightPhaseDescending => 'Descendiendo';
	@override String get acquiringGpsSignal => 'Adquiriendo señal GPS';
	@override String get acquiringGpsHint => 'Mantén el dispositivo estable y con cielo abierto para obtener una posición fiable.';
	@override String get weakSignalBanner => 'Señal GPS débil. Los valores pueden desviarse hasta que mejore la precisión.';
	@override String get preparingDashboard => 'Preparando panel...';
	@override String get navigation => 'Navegación';
	@override String heading({required Object heading}) => 'Rumbo ${heading}';
	@override String get routeProgress => 'Progreso de la ruta';
	@override String get covered => 'Recorrido';
	@override String get remaining => 'Restante';
	@override String get total => 'Total';
}

// Path: flight.upcoming
class _TranslationsFlightUpcomingEs extends TranslationsFlightUpcomingEn {
	_TranslationsFlightUpcomingEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mapTitle => 'Empieza tu viaje en vuelo';
	@override String get mapSubtitle => 'Inicia el seguimiento en vivo cuando comience tu vuelo';
	@override String get dashboardTitle => 'Empieza tu viaje en vuelo';
	@override String get dashboardSubtitle => 'Empieza a ver tu panel en vivo';
	@override String get checkInButton => 'Iniciar';
	@override String get checkInSuccess => 'Vuelo iniciado';
	@override String get checkInError => 'No se pudo iniciar ahora. Inténtalo de nuevo';
}

// Path: flight.info
class _TranslationsFlightInfoEs extends TranslationsFlightInfoEn {
	_TranslationsFlightInfoEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get overviewTitle => 'Resumen';
	@override String get overviewLoading => 'Creando resumen de la ruta...';
	@override String get overviewEmpty => 'El resumen aún no está disponible para esta ruta.';
	@override String get loadingRouteInformation => 'Cargando información de la ruta...';
	@override String get flyOverTitle => 'Lo más destacado de tu ruta';
	@override String get airportsTitle => 'Aeropuertos';
	@override String get departure => 'Salida';
	@override String get arrival => 'Llegada';
	@override String get showAll => 'Mostrar todo';
	@override String showAllCount({required Object count}) => 'Mostrar todo (${count})';
	@override String get showLess => 'Mostrar menos';
	@override String get sortByRank => 'Por relevancia';
	@override String get sortByRouteProgress => 'Por ruta';
	@override String get sortByType => 'Por tipo';
	@override String get routeTimelineTitle => 'Cronología de la ruta';
	@override String plannedWaypoints({required Object count}) => '${count} puntos de ruta planificados';
	@override String get pointsOfInterestTitle => 'Puntos de interés';
	@override String get noPoi => 'Aún no hay PDI disponibles.';
	@override String poiType({required Object type}) => 'Tipo: ${type}';
	@override String poiFlyOver({required Object view}) => 'Sobrevuelo: ${view}';
	@override String get offlineArticlesTitle => 'Artículos offline';
	@override String get regionArticlesTitle => 'Artículos de la región';
	@override String get otherArticlesTitle => 'Otros artículos';
	@override String get noOfflineArticles => 'No se han descargado artículos offline.';
	@override String get openSource => 'Abrir fuente';
	@override String get openSourcePage => 'Abrir página de origen';
	@override String get openSourcePageTooltip => 'Abrir página de origen';
	@override String distanceKm({required Object distance}) => '${distance} km';
	@override String get speed => 'Velocidad';
	@override String get altitude => 'Altitud';
	@override String get copyRouteTitle => 'Ruta de Flymap';
	@override String copyRouteCode({required Object routeCode}) => 'Código de ruta: ${routeCode}';
	@override String copyDistance({required Object distance}) => 'Distancia: ${distance} km';
	@override String get copyFrom => 'Desde';
	@override String get copyTo => 'Hasta';
	@override String copyCity({required Object city, required Object countryCode}) => 'Ciudad: ${city}, ${countryCode}';
	@override String copyAirport({required Object airport}) => 'Aeropuerto: ${airport}';
	@override String copyCodes({required Object iata, required Object icao}) => 'Códigos: IATA ${iata} | ICAO ${icao}';
}

// Path: flight.route
class _TranslationsFlightRouteEs extends TranslationsFlightRouteEn {
	_TranslationsFlightRouteEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get loadingRouteTimeline => 'Cargando cronología de la ruta...';
	@override String get noSavedOfflineRegions => 'No hay regiones offline guardadas para este vuelo.';
	@override String currentProgress({required Object percentage, required Object minute}) => 'Progreso actual: ${percentage}% (aprox. ${minute} desde el despegue)';
	@override String get nowLabel => 'Ahora';
	@override String get currentRegionLabel => 'Actual';
	@override String get nextRegionLabel => 'Siguiente';
	@override String get arrivingLabel => 'Llegando';
	@override String get arrivedLabel => 'Llegado';
	@override String etaLabel({required Object time}) => 'ETA: ${time}';
	@override String etaInLabel({required Object time}) => 'en ${time}';
	@override String get flyingOverLabel => 'Estás volando sobre:';
	@override String get premiumLockedChipLabel => 'Desbloquear';
	@override String get premiumGateTitle => 'Desbloquear cronología completa de la ruta';
	@override String get premiumGateBody => 'Pásate a Pro para ver todas las regiones de tu ruta y los detalles de la cronología.';
	@override String premiumGateBodyWithCount({required Object count}) => 'Desbloquea las ${count} regiones de esta ruta con Premium.';
	@override String get premiumGateCta => 'Pasar a Pro';
	@override String get premiumOfflineTitle => 'Se necesita internet para mejorar';
	@override String get premiumOfflineBody => 'Ahora mismo estás offline. Conéctate a internet para mejorar y desbloquear la vista completa de la ruta.';
	@override String nextHintLabel({required Object region, required Object eta}) => 'Siguiente: ${region} (${eta})';
	@override String get etaUnknownLabel => 'calculando...';
}

// Path: onboarding.payoff
class _TranslationsOnboardingPayoffEs extends TranslationsOnboardingPayoffEn {
	_TranslationsOnboardingPayoffEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String title({required Object airport}) => 'Lugares alrededor de ${airport} que no deberías perderte';
	@override String get subtitle => 'Llevas años sobrevolando todo esto — búscalos en tu próximo vuelo:';
	@override String scanning({required Object airport}) => 'Explorando el cielo alrededor de ${airport}…';
	@override String moreNearby({required Object count}) => '…y ${count}+ lugares más por descubrir cerca:';
	@override String get fallbackTitle => 'Deja de perderte lo que hay debajo';
	@override String get fallbackSubtitle => 'Cada vuelo sobrevuela volcanes, montañas, islas y lagos que la mayoría de los viajeros nunca nota. Flymap te muestra lo que hay tras tu ventanilla.';
}

// Path: createFlight.overview.airportCard
class _TranslationsCreateFlightOverviewAirportCardEs extends TranslationsCreateFlightOverviewAirportCardEn {
	_TranslationsCreateFlightOverviewAirportCardEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String departureDescription({required Object airport}) => 'Empezarás tu viaje desde ${airport}.';
	@override String arrivalDescription({required Object airport}) => 'Llegarás a ${airport}.';
}

// Path: createFlight.overview.regionInfo
class _TranslationsCreateFlightOverviewRegionInfoEs extends TranslationsCreateFlightOverviewRegionInfoEn {
	_TranslationsCreateFlightOverviewRegionInfoEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get descriptionUnavailable => 'La descripción aún no está disponible.';
	@override String get wikipediaSectionTitle => 'Wikipedia';
	@override String get wikipediaUnavailable => 'El artículo de Wikipedia no está disponible ahora mismo.';
	@override String get openWikipedia => 'Abrir Wikipedia';
}

// Path: createFlight.overview.timeline
class _TranslationsCreateFlightOverviewTimelineEs extends TranslationsCreateFlightOverviewTimelineEn {
	_TranslationsCreateFlightOverviewTimelineEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get takeOffTimeline => 'Despe-\ngue';
	@override String get land => 'Aterrizar';
	@override String get alsoAroundThisTime => 'También por este momento:';
	@override String get minuteUnit => 'min';
	@override String get hourCompactUnit => 'h';
	@override String get minuteCompactUnit => 'm';
	@override late final _TranslationsCreateFlightOverviewTimelineRegionTypeEs regionType = _TranslationsCreateFlightOverviewTimelineRegionTypeEs._(_root);
}

// Path: createFlight.overview.timeline.regionType
class _TranslationsCreateFlightOverviewTimelineRegionTypeEs extends TranslationsCreateFlightOverviewTimelineRegionTypeEn {
	_TranslationsCreateFlightOverviewTimelineRegionTypeEs._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get country => 'País';
	@override String get region => 'Región';
	@override String get state => 'Estado';
	@override String get province => 'Provincia';
	@override String get sea => 'Mar';
	@override String get ocean => 'Océano';
	@override String get strait => 'Estrecho';
	@override String get channel => 'Canal';
	@override String get gulf => 'Golfo';
	@override String get bay => 'Bahía';
	@override String get lake => 'Lago';
	@override String get alkalineLake => 'Lago alcalino';
	@override String get island => 'Isla';
	@override String get archipelago => 'Archipiélago';
	@override String get peninsula => 'Península';
	@override String get coast => 'Costa';
	@override String get mountainRange => 'Cordillera';
	@override String get valley => 'Valle';
	@override String get plateau => 'Meseta';
	@override String get plain => 'Llanura';
	@override String get basin => 'Cuenca';
	@override String get lowland => 'Tierras bajas';
	@override String get tundra => 'Tundra';
	@override String get wetlands => 'Humedales';
	@override String get desert => 'Desierto';
	@override String get delta => 'Delta';
	@override String get reservoir => 'Embalse';
	@override String get continent => 'Continente';
	@override String get geoarea => 'Área geográfica';
	@override String get isthmus => 'Istmo';
	@override String get unknown => 'Tipo de región desconocido';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Flymap',
			'common.kContinue' => 'Continuar',
			'common.back' => 'Atrás',
			'common.cancel' => 'Cancelar',
			'common.ok' => 'OK',
			'common.retry' => 'Reintentar',
			'common.manage' => 'Gestionar',
			'common.edit' => 'Editar',
			'common.upgrade' => 'Pasar a Pro',
			'common.loading' => 'Cargando...',
			'common.readMore' => 'Leer más',
			'common.pro' => 'PRO',
			'common.search' => 'Buscar',
			'common.debug' => 'Debug',
			'home.title' => 'Inicio',
			'home.aboutTooltip' => 'Acerca de',
			'home.settingsTooltip' => 'Ajustes',
			'home.tabFlights' => 'Vuelos',
			'home.tabLearn' => 'Aprender',
			'home.tabMedia' => 'Media',
			'home.openSkyCamera' => 'Abrir Sky Camera',
			'home.loadingFlights' => 'Cargando vuelos...',
			'home.failedToLoadFlights' => 'No se pudieron cargar los vuelos',
			'home.newFlight' => 'Nuevo vuelo',
			'home.addFirstFlight' => 'Añadir primer vuelo',
			'home.addNextFlight' => 'Añadir siguiente vuelo',
			'home.welcomeTitle' => 'Bienvenido a Flymap',
			'home.welcomeTitlePro' => 'Bienvenido a Flymap Pro',
			'home.welcomeSubtitle' => 'Mapas offline para vuelos',
			'home.greetingOnline' => '¿Listo para el próximo vuelo?',
			'home.greetingOnlineWithName' => ({required Object name}) => 'Hola ${name}, ¿listo para el próximo vuelo?',
			'home.greetingOffline' => '¿Listo para explorar tu vuelo?',
			'home.greetingOfflineWithName' => ({required Object name}) => 'Hola ${name}, ¿listo para explorar tu vuelo?',
			'home.greetingInProgress' => 'Tu vuelo está en curso',
			'home.greetingInProgressWithName' => ({required Object name}) => 'Hola ${name}, tu vuelo está en curso',
			'home.totalFlights' => 'Vuelos totales',
			'home.storageUsed' => 'Almacenamiento usado',
			'home.totalDistance' => 'Distancia total',
			'home.upcomingFlightsCount' => ({required Object count}) => 'Próximos vuelos (${count})',
			'home.flightInProgressTitle' => 'Vuelo en curso',
			'home.noFlightsTitle' => '¿Listo para explorar el mundo desde arriba?',
			'home.noFlightsSubtitle' => 'Añade tu primer vuelo y empieza a descubrir tu próximo viaje.',
			'home.noFlightsTitleNext' => '¿Listo para tu próximo viaje?',
			'home.noFlightsSubtitleNext' => 'Tus vuelos completados están en Historial. Añade tu próximo vuelo para seguir.',
			'home.flightActions' => 'Acciones del vuelo',
			'home.viewAll' => 'Ver todo',
			'home.open' => 'Abrir',
			'home.shareRoute' => 'Compartir ruta',
			'home.completeFlight' => 'Archivar vuelo',
			'home.deleteFlight' => 'Eliminar vuelo',
			'home.failedDeleteFlight' => 'No se pudo eliminar el vuelo',
			'home.noOfflineMap' => 'Sin mapa offline',
			'home.placesCount' => ({required Object count}) => '${count} lugares',
			'home.regionsCount' => ({required Object count}) => '${count} regiones',
			'home.offlineArticlesCount' => ({required Object count}) => '${count} artículos',
			'home.savedTime' => ({required Object time}) => 'Guardado ${time}',
			'home.justNow' => 'Ahora mismo',
			'home.daysAgo' => ({required Object days}) => 'Hace ${days} d',
			'home.hoursAgo' => ({required Object hours}) => 'Hace ${hours} h',
			'home.minutesAgo' => ({required Object minutes}) => 'Hace ${minutes} min',
			'home.sort.mostRecent' => 'Más reciente',
			'home.sort.longest' => 'Más largo',
			'home.sort.alphabetical' => 'A-Z',
			'skyCamera.loading' => 'Cargando cámara...',
			'skyCamera.loadingGpsData' => 'Cargando datos GPS',
			'skyCamera.zoom' => 'Zoom',
			'skyCamera.flash' => 'Flash',
			'skyCamera.cameraUnavailable' => 'La cámara no está disponible ahora mismo.',
			'skyCamera.cameraPermissionDenied' => 'Se necesita permiso de cámara para hacer fotos.',
			'skyCamera.captureFailed' => 'No se pudo capturar la foto ahora mismo.',
			'skyCamera.savedMessage' => 'Foto guardada',
			'skyCamera.share' => 'Compartir',
			'skyCamera.noActiveFlightTitle' => 'No hay un vuelo activo',
			'skyCamera.noActiveFlightMessage' => 'Sky Camera funciona sin vuelo, pero los detalles de ruta solo aparecen durante un vuelo activo.',
			'skyCamera.telemetrySpeed' => 'Velocidad',
			'skyCamera.telemetryAltitude' => 'Altitud',
			'skyCamera.telemetryHeading' => 'Rumbo',
			'skyCamera.telemetryTime' => 'Hora',
			'skyCamera.contextCaption' => 'Contexto',
			'skyCamera.mapCaption' => 'Mapa',
			'skyCamera.coordinatesCaption' => 'Coordenadas',
			'skyCamera.noValuePlaceholder' => '--',
			'skyCamera.placeholderRoute' => 'LHR -> BCN',
			'skyCamera.placeholderOriginCode' => 'LHR',
			'skyCamera.placeholderDestinationCode' => 'BCN',
			'skyCamera.placeholderContext' => 'Mar Mediterráneo',
			'skyCamera.placeholderMap' => 'Vista previa de la ruta',
			'skyCamera.settingsTitle' => 'Ajustes de cámara',
			'skyCamera.recordAudio' => 'Grabar audio',
			'skyCamera.recordAudioHint' => 'Los vídeos capturan el sonido del micrófono.',
			'skyCamera.microphonePermissionDenied' => 'El acceso al micrófono está desactivado: los vídeos se graban sin sonido.',
			'skyCamera.preparingVideo' => 'Preparando el vídeo…',
			'media.title' => 'Contenido desde la ventanilla',
			'media.loading' => 'Cargando media...',
			'media.failedToLoad' => 'No se pudo cargar la media',
			'media.filesTab' => 'Archivos',
			'media.flightsTab' => 'Vuelos',
			'media.emptyTitle' => 'Te damos la bienvenida a tu Sky Camera de ventanilla',
			'media.emptySubtitle' => 'Captura y comparte vistas increíbles desde tu asiento de ventanilla con superposiciones de datos de vuelo y GPS.',
			'media.emptyFlightsTitle' => 'Aún no hay carpetas de vuelos',
			'media.emptyFlightsSubtitle' => 'Las capturas vinculadas a vuelos guardados aparecerán aquí.',
			'media.deleteAction' => 'Eliminar',
			'media.share' => 'Compartir',
			'media.selectedCount' => ({required Object count}) => '${count} seleccionado(s)',
			'media.groupNoFlight' => 'Sin contexto de vuelo',
			'media.groupNoFlightSubtitle' => 'Capturas tomadas fuera de un vuelo activo',
			'media.groupUnknownFlight' => 'Captura de vuelo',
			'media.previewTitle' => 'Captura',
			'media.captureCount' => ({required Object count}) => '${count} capturas',
			'media.deleteFolder' => 'Eliminar carpeta',
			'media.deleteFolders' => ({required Object count}) => 'Eliminar ${count} carpetas',
			'media.deleteFile' => 'Eliminar archivo',
			'media.deleteFiles' => ({required Object count}) => 'Eliminar ${count} archivos',
			'media.deleteFolderConfirm' => ({required Object count}) => '¿Eliminar esta carpeta y sus ${count} archivos?',
			'media.deleteFoldersConfirm' => ({required Object count}) => '¿Eliminar ${count} carpetas y todos los archivos dentro?',
			'media.deleteFileConfirm' => '¿Eliminar este archivo?',
			'media.deleteFilesConfirm' => ({required Object count}) => '¿Eliminar ${count} archivos?',
			'learn.loadingCategories' => 'Cargando categorías de aprendizaje...',
			'learn.failedToLoadCategories' => 'No se pudieron cargar las categorías',
			'learn.emptyCategoriesTitle' => 'Aún no hay categorías',
			'learn.emptyCategoriesSubtitle' => 'Las categorías de aprendizaje aparecerán aquí pronto.',
			'learn.articlesCount' => ({required Object count}) => '${count} artículos',
			'learn.loadingArticles' => 'Cargando artículos...',
			'learn.failedToLoadArticles' => 'No se pudieron cargar los artículos',
			'learn.emptyArticlesTitle' => 'Aún no hay artículos',
			'learn.emptyArticlesSubtitle' => 'Los artículos de esta categoría aparecerán pronto.',
			'learn.upgradeRequiresInternet' => 'El contenido premium está disponible con Pro. Conéctate a internet para mejorar.',
			'learn.proListPreviewHint' => 'Puedes explorar estos títulos ahora. Desbloquea la lectura con Flymap Pro.',
			'learn.failedToLoadArticle' => 'No se pudo abrir este artículo ahora mismo.',
			'learn.quizzesTitle' => 'Cuestionarios',
			'learn.articlesTitle' => 'Artículos',
			'learn.geoQuiz.title' => 'Geo Quiz',
			'learn.geoQuiz.geographyTitle' => 'Geografía',
			'learn.geoQuiz.geographySubtitle' => 'Mares, cordilleras, lagos, islas y más',
			'learn.geoQuiz.countriesTitle' => 'Países en el mapa',
			'learn.geoQuiz.subtitle' => 'Adivina el país por su contorno',
			'learn.geoQuiz.loading' => 'Cargando Geo Quiz...',
			'learn.geoQuiz.failedToLoad' => 'No se pudieron cargar los cuestionarios',
			'learn.geoQuiz.failedToLoadQuiz' => 'No se pudo cargar el cuestionario',
			'learn.geoQuiz.emptyTitle' => 'Aún no hay cuestionarios',
			'learn.geoQuiz.emptySubtitle' => 'Los geo quizzes aparecerán aquí pronto.',
			'learn.geoQuiz.countryHint' => 'Nombre de la región...',
			'learn.geoQuiz.progressCount' => ({required Object solved, required Object total}) => '${solved} / ${total}',
			'learn.geoQuiz.nextCount' => ({required Object next, required Object total}) => '${next} de ${total}',
			'learn.geoQuiz.correctCount' => ({required Object count}) => '${count} correctos',
			'learn.geoQuiz.reset' => 'Restablecer progreso',
			'learn.geoQuiz.mapPlaceholder' => 'Los datos del mapa se agregarán después',
			'learn.geoQuiz.newBadge' => 'NUEVO',
			'learn.geoQuiz.correct' => 'Correcto',
			'learn.geoQuiz.wrong' => 'Incorrecto',
			'learn.geoQuiz.hintTitle' => 'Pista',
			'learn.geoQuiz.hintSubtitle' => 'Toca una letra para revelarla',
			'learn.geoQuiz.next' => 'Siguiente',
			'learn.geoQuiz.pause' => 'Pausar',
			'learn.geoQuiz.resume' => 'Reanudar',
			'learn.geoQuiz.finish' => 'Finalizar',
			'learn.geoQuiz.completeTitle' => 'Cuestionario completado',
			'learn.geoQuiz.completeMessage' => ({required Object total, required Object quiz}) => 'Encontraste los ${total} países de ${quiz}.',
			'learn.geoQuiz.backToQuizzes' => 'Volver a los cuestionarios',
			'learn.geoQuiz.playAgain' => 'Jugar de nuevo',
			'learn.geoQuiz.progressReady' => 'Listo para jugar',
			'learn.geoQuiz.progressFinished' => ({required Object count}) => '${count} terminados',
			'learn.geoQuiz.progressInProgress' => ({required Object count}) => '${count} en curso',
			'learn.geoQuiz.progressAllCompleted' => 'Todos completados',
			'learn.geoQuiz.quizCountriesAfricaTitle' => 'África',
			'learn.geoQuiz.quizCountriesEuropeTitle' => 'Europa',
			'learn.geoQuiz.quizCountriesAsiaTitle' => 'Asia',
			'learn.geoQuiz.quizCountriesNorthAmericaTitle' => 'Norteamérica',
			'learn.geoQuiz.quizCountriesSouthAmericaTitle' => 'Sudamérica',
			'learn.geoQuiz.quizCountriesOceaniaTitle' => 'Oceanía',
			'learn.geoQuiz.quizCountriesAllTitle' => 'Todos los países',
			'learn.geoQuiz.quizCountriesSubtitle' => 'Países',
			'learn.geoQuiz.quizCountriesAllSubtitle' => 'Mundo',
			'learn.geoQuiz.quizGeographySeasTitle' => 'Mares',
			'learn.geoQuiz.quizGeographyMountainRangesTitle' => 'Cordilleras',
			'learn.geoQuiz.quizGeographyLakesTitle' => 'Lagos',
			'learn.geoQuiz.quizGeographyIslandsTitle' => 'Islas',
			'learn.geoQuiz.quizGeographyOtherTitle' => 'Otros',
			'learn.geoQuiz.quizGeographyOtherSubtitle' => 'Bahías, estrechos, golfos, desiertos y más',
			'learn.geoQuiz.descriptionUnavailable' => 'La descripción aún no está disponible.',
			'settings.title' => 'Ajustes',
			'settings.loading' => 'Cargando ajustes...',
			'settings.profile' => 'Perfil',
			'settings.profileSubtitle' => 'Nombre, hábitos de vuelo, aeropuerto base e intereses',
			'settings.profileSummaryNameHome' => ({required Object name, required Object code}) => '${name} · ${code}',
			'settings.profileSummaryHome' => ({required Object code}) => 'Aeropuerto base: ${code}',
			'settings.profileEditHint' => 'Toca cualquier elemento para editar los datos de tu perfil.',
			'settings.profileNotSet' => 'Sin definir',
			'settings.profileInterestsSelected' => ({required Object count}) => '${count} seleccionados',
			'settings.historyTitle' => 'Historial',
			'settings.historySubtitle' => 'Todos los vuelos y estadísticas',
			'settings.historyLoading' => 'Cargando historial...',
			'settings.historyLoadError' => 'No se pudo cargar el historial de vuelos.',
			'settings.historyFlightsLabel' => 'Vuelos totales',
			'settings.historyDistanceLabel' => 'Distancia total',
			'settings.historyAllFlights' => 'Todos los vuelos',
			'settings.historyStatusUpcoming' => 'Próximo',
			'settings.historyStatusInProgress' => 'En curso',
			'settings.historyStatusCompleted' => 'Completado',
			'settings.historyMapChip' => ({required Object size}) => 'Mapa ${size}',
			'settings.historyNoMapChip' => 'Sin mapa',
			'settings.historySortName' => 'Nombre',
			'settings.historySortDistance' => 'Distancia',
			'settings.historySortDate' => 'Fecha',
			'settings.historyEmpty' => 'Aún no hay vuelos.',
			'settings.historySearchHint' => 'Buscar por aeropuerto o ciudad',
			'settings.historyNoResults' => 'No se encontraron vuelos coincidentes.',
			'settings.historyDeleteOfflineData' => 'Eliminar solo el mapa',
			'settings.appearance' => 'Apariencia',
			'settings.language' => 'Idioma',
			'settings.languageSubtitle' => 'Idioma de la app',
			'settings.languageSystem' => 'Sistema',
			'settings.languageSystemFormat' => ({required Object language}) => '${language} (Sistema)',
			'settings.languageEnglish' => 'English',
			'settings.languageSpanish' => 'Español',
			'settings.languageFrench' => 'Français',
			'settings.languageGerman' => 'Deutsch',
			'settings.theme' => 'Tema',
			'settings.system' => 'Sistema',
			'settings.dark' => 'Oscuro',
			'settings.light' => 'Claro',
			'settings.units' => 'Unidades',
			'settings.storage' => 'Almacenamiento',
			'settings.storageTitle' => 'Almacenamiento',
			'settings.storageSubtitle' => 'Mapas descargados y uso del disco',
			'settings.storageLoading' => 'Cargando almacenamiento...',
			'settings.storageLoadError' => 'No se pudieron cargar los datos de almacenamiento.',
			'settings.storageMapsLabel' => 'Mapas descargados',
			'settings.storageTotalSizeLabel' => 'Tamaño total',
			'settings.storageDownloadedMaps' => 'Mapas descargados',
			'settings.storageSortName' => 'Nombre',
			'settings.storageSortSize' => 'Tamaño',
			'settings.storageMapSize' => ({required Object size}) => 'Tamaño: ${size}',
			'settings.storageEmpty' => 'Aún no hay mapas descargados.',
			'settings.altitude' => 'Altitud',
			'settings.altitudeUnit' => 'Unidad de altitud',
			'settings.speed' => 'Velocidad',
			'settings.speedUnit' => 'Unidad de velocidad',
			'settings.temperatureUnit' => 'Unidad de temperatura',
			'settings.timeFormat' => 'Formato de hora',
			'settings.distanceUnit' => 'Unidad de distancia',
			'settings.dateFormat' => 'Formato de fecha',
			'settings.support' => 'Soporte',
			'settings.about' => 'Acerca de',
			'settings.aboutSubtitle' => 'Más información sobre la app',
			'settings.privacyPolicy' => 'Política de privacidad',
			'settings.privacyPolicySubtitle' => 'Lee nuestra política de privacidad',
			'settings.termsOfService' => 'Términos del servicio',
			'settings.termsOfServiceSubtitle' => 'Lee nuestros términos del servicio',
			'settings.flymapProActivated' => 'Flymap Pro activado.',
			'settings.upgradeCancelled' => 'Actualización cancelada.',
			'settings.noPaywall' => 'No hay pantalla de pago disponible en este momento.',
			'settings.failedOpenPaywall' => 'No se pudo abrir la pantalla de pago.',
			'settings.couldNotOpenUrl' => ({required Object url}) => 'No se pudo abrir ${url}',
			'settings.rateUs' => 'Valóranos',
			'settings.rateUsSubtitle' => 'Deja una reseña en la tienda',
			'settings.leaveFeedback' => 'Dejar comentarios',
			'settings.leaveFeedbackSubtitle' => 'Comparte tu opinión para ayudarnos a mejorar',
			'settings.couldNotOpenStorePage' => 'No se pudo abrir la página de la tienda',
			'settings.rateDialogTitle' => '¿Te gusta la app?',
			'settings.rateDialogBody' => 'Trabajamos duro para que cada vuelo sea más agradable, y tus comentarios realmente nos ayudan a mejorar.',
			'settings.rateDialogYes' => 'Sí',
			'settings.rateDialogNo' => 'No',
			'settings.advocacyDialogTitle' => 'Nos alegra que disfrutes Flymap',
			'settings.advocacyDialogBody' => 'Ayuda a otros viajeros a descubrir Flymap.',
			'settings.advocacyDialogShare' => 'Compartir con amigos',
			'settings.advocacyDialogRate' => 'Valorar Flymap',
			'settings.advocacyDialogNotNow' => 'Ahora no',
			'settings.feedbackTitle' => 'Dejar comentarios',
			'settings.feedbackBody' => 'Ayúdanos a mejorar Flymap',
			'settings.feedbackCategoryTitle' => 'Tipo de comentario',
			'settings.feedbackCategoryGeneral' => 'General',
			'settings.feedbackCategoryFeatureRequest' => 'Solicitud de función',
			'settings.feedbackCategoryBugReport' => 'Error',
			'settings.feedbackHint' => 'Comparte tus comentarios...',
			'settings.feedbackEmailHint' => 'Correo electrónico (opcional)',
			'settings.feedbackEmailInvalid' => 'Introduce un correo válido o déjalo vacío.',
			'settings.feedbackSend' => 'Enviar',
			'settings.feedbackThanks' => '¡Gracias por compartir tus comentarios!',
			'settings.feedbackSendFailed' => 'No se pudieron enviar los comentarios. Inténtalo de nuevo.',
			'settings.proBannerTitle' => 'Flymap Pro',
			'settings.proBannerTitleActive' => 'Flymap Pro activo',
			'settings.proBannerSubtitleActive' => 'Modo de mapa detallado y paquetes completos de artículos offline desbloqueados.',
			'settings.proBannerSubtitleFree' => 'Desbloquea mapas detallados y paquetes completos de artículos offline',
			'settings.proBannerBadgeActive' => 'PRO ACTIVO',
			'subscription.screenTitle' => 'Suscripción',
			'subscription.contactSupport' => 'Contactar con soporte',
			'subscription.cardTitle' => 'Flymap Pro',
			'subscription.periodTitle' => 'Periodo de suscripción',
			'subscription.renewsOrExpires' => 'Renueva o caduca',
			'subscription.noExpiration' => 'Sin caducidad',
			'subscription.lastChecked' => 'Última comprobación',
			'subscription.flightUnlockSheetTitle' => 'Desbloquear funciones Pro',
			'subscription.flightUnlockOptionTitle' => 'Compra única',
			'subscription.flightUnlockOptionBody' => 'Desbloquea Pro para un solo vuelo',
			'subscription.flightUnlockAction' => 'Comprar para 1 vuelo',
			'subscription.flightUnlockUseAction' => 'Usar para 1 vuelo',
			'subscription.flightUnlockPriceLoading' => 'Cargando precio...',
			'subscription.flightUnlockProOptionTitle' => 'Suscripción Flymap Pro',
			'subscription.flightUnlockAvailableCount' => ({required Object count}) => '${count} desbloqueos de vuelo disponibles',
			'subscription.flightUnlockProOptionBody' => 'Desbloquea Pro para vuelos ilimitados',
			'subscription.flightUnlockProAction' => 'Ver planes Pro',
			'subscription.flightUnlockUnavailable' => 'El desbloqueo de vuelo no está disponible ahora mismo.',
			'subscription.flightUnlockPurchaseCancelled' => 'Compra del desbloqueo de vuelo cancelada.',
			'subscription.flightUnlockPurchaseFailed' => 'La compra del desbloqueo de vuelo falló. Inténtalo de nuevo.',
			'subscription.proFeaturesTitle' => 'Lo que desbloquea Flymap Pro',
			'subscription.proFeatureRoutesTitle' => 'Vistas previas de ruta precisas',
			'subscription.proFeatureMapsTitle' => 'Mapas offline con más detalle',
			'subscription.proFeatureTimelineTitle' => 'Línea de tiempo completa',
			'subscription.proFeaturePoiTitle' => '10 veces más lugares en la ruta',
			'subscription.proFeatureArticlesTitle' => 'Paquetes completos de artículos offline',
			'subscription.checkingStatus' => 'Comprobando el estado de tu suscripción...',
			'subscription.freePlan' => 'Estás en el plan Free.',
			'subscription.active' => 'Activo',
			'subscription.notActive' => 'No activo',
			'subscription.unknown' => 'Desconocido',
			'subscription.manageSubscription' => 'Gestionar suscripción',
			'subscription.restorePurchases' => 'Restaurar compras',
			'subscription.upgradeToPro' => 'Pasar a Pro',
			'subscription.restoreNoSubscription' => 'No se encontró ninguna suscripción activa.',
			'subscription.supportEmailSubject' => 'Soporte de suscripción de Flymap',
			'subscription.couldNotOpenEmailApp' => 'No se pudo abrir la app de correo',
			'subscription.couldNotOpenSubscriptionSettings' => 'No se pudieron abrir los ajustes de suscripción',
			'subscription.proRestored' => 'Flymap Pro restaurado.',
			'subscription.failedOpenPaywall' => 'No se pudo abrir la pantalla de pago.',
			'subscription.serviceUnavailable' => 'El servicio de suscripción no está disponible temporalmente.',
			'createFlight.steps.departureTitle' => 'Elegir aeropuerto de salida',
			'createFlight.steps.arrivalTitle' => 'Elegir aeropuerto de llegada',
			'createFlight.steps.routeNotSupportedTitle' => 'Ruta no compatible',
			'createFlight.steps.mapPreviewTitle' => 'Vista previa del mapa',
			'createFlight.steps.overviewTitle' => 'Resumen de la ruta',
			'createFlight.steps.wikipediaTitle' => 'Artículos de Wikipedia',
			'createFlight.steps.weatherTitle' => 'Clima del vuelo',
			'createFlight.weather.title' => '¿Verás el suelo?',
			'createFlight.weather.loading' => 'Comprobando el cielo a lo largo de tu ruta…',
			'createFlight.weather.loadFailed' => 'No se pudo cargar el pronóstico ahora mismo. Reintenta o continúa sin él.',
			'createFlight.weather.departureLabel' => 'Salida',
			'createFlight.weather.arrivalLabel' => 'Llegada',
			'createFlight.weather.tomorrow' => 'mañana',
			'createFlight.weather.verdictClearTitle' => 'Vistas despejadas',
			'createFlight.weather.verdictClearBody' => 'El asiento de ventanilla merece la pena: el suelo debería verse casi todo el vuelo.',
			'createFlight.weather.verdictPatchyTitle' => 'Nubes dispersas',
			'createFlight.weather.verdictPatchyBody' => 'Las vistas irán y vendrán entre las nubes.',
			'createFlight.weather.verdictCarpetTitle' => 'Manto de nubes debajo',
			'createFlight.weather.verdictCarpetBody' => 'Un mar blanco de nubes bajo el avión: precioso, pero el suelo quedará casi siempre oculto.',
			'createFlight.weather.verdictOvercastTitle' => 'Cielo cubierto',
			'createFlight.weather.verdictOvercastBody' => 'Las mejores vistas serán en el despegue y el aterrizaje.',
			'createFlight.weather.windCalm' => 'Calma',
			'createFlight.weather.windLight' => 'Viento suave',
			'createFlight.weather.windBreezy' => 'Brisa',
			'createFlight.weather.windWindy' => 'Ventoso',
			'createFlight.weather.windStrong' => 'Viento fuerte',
			'createFlight.weather.windTakeoff' => ({required Object city, required Object speed}) => 'Despegue con viento en ${city} (${speed} m/s): puede haber baches',
			'createFlight.weather.windLanding' => ({required Object city, required Object speed}) => 'Aterrizaje con viento en ${city} (${speed} m/s): puede haber baches',
			'createFlight.weather.proTeaserTitle' => 'Mapa de nubes de tu ruta',
			'createFlight.weather.proTeaserBody' => 'Mira dónde estarán las nubes y observa tu avión volar toda la ruta por encima de ellas.',
			'createFlight.weather.attribution' => 'Datos meteorológicos: MET Norway',
			'createFlight.weather.hedge' => 'Los pronósticos se afinan cuanto más cerca está la salida.',
			'createFlight.weather.share' => 'Compartir',
			'createFlight.weather.shareAsImage' => 'Compartir como imagen',
			'createFlight.weather.shareAsVideo' => 'Compartir como vídeo',
			'createFlight.weather.preparingShare' => 'Preparando para compartir…',
			'createFlight.weather.shareFailed' => 'No se pudo preparar — inténtalo de nuevo.',
			'createFlight.weather.updatedAt' => ({required Object time}) => 'Actualizado ${time}',
			'createFlight.routeTypeSelector.title' => 'Nuevo vuelo',
			'createFlight.routeTypeSelector.basicTitle' => 'Ruta aproximada',
			'createFlight.routeTypeSelector.basicSubtitle' => 'Desde aeropuertos',
			'createFlight.routeTypeSelector.basicDescription' => 'Funciona bien para vuelos cortos y muchos de media distancia.',
			'createFlight.routeTypeSelector.proTitle' => 'Ruta real',
			'createFlight.routeTypeSelector.proSubtitle' => 'Desde vuelos recientes',
			'createFlight.routeTypeSelector.proDescription' => 'Construida a partir de la ruta registrada más reciente del mismo vuelo.',
			'createFlight.routeTypeSelector.mostAccurate' => 'Más precisa',
			'createFlight.proAccess.subscriber' => 'Flymap Pro',
			'createFlight.proAccess.subscriberBody' => 'Este vuelo tiene acceso Pro completo mediante tu suscripción de Flymap Pro.',
			'createFlight.proAccess.unlockedFlight' => 'Este vuelo está desbloqueado',
			'createFlight.proAccess.unlockedFlightBody' => 'Todas las funciones Pro están activadas para este vuelo.',
			'createFlight.proAccess.tooltip' => 'Información de acceso Pro',
			'createFlight.travelDate.inDays' => ({required Object count}) => 'En ${count} días',
			'createFlight.travelDate.today' => 'Hoy',
			'createFlight.travelDate.tomorrow' => 'Mañana',
			'createFlight.travelDate.stepTitle' => '¿Cuándo vuelas?',
			'createFlight.travelDate.customDate' => 'Elegir otra fecha',
			'createFlight.travelDate.pickDate' => 'Elige tu fecha de viaje',
			'createFlight.travelDate.yourFlightOnDate' => 'Tu vuelo en esta fecha',
			'createFlight.travelDate.changeDate' => 'Cambiar fecha',
			'createFlight.travelDate.checkingSchedule' => 'Comprobando el horario del vuelo…',
			'createFlight.travelDate.noDateYet' => 'Sin fecha aún',
			'createFlight.travelDate.skipDate' => 'Continuar sin fecha',
			'createFlight.travelDate.addDepartureTime' => 'Añadir hora de salida (opcional)',
			'createFlight.travelDate.departureTimeAt' => ({required Object time}) => 'Hora de salida · ${time}',
			'createFlight.travelDate.noDepartureOnDateTitle' => 'No encontramos este vuelo en esta fecha',
			'createFlight.travelDate.noDepartureOnDateBody' => 'Revisa la fecha — tócala para cambiarla. O continúa igualmente y guardaremos solo la fecha.',
			'createFlight.travelDate.dateCheckFailed' => 'No se pudo comprobar esta fecha — se guarda solo la fecha.',
			'createFlight.flightNumberSearch.title' => 'Número de vuelo',
			'createFlight.flightNumberSearch.subtitle' => 'Introduce un número de vuelo (por ejemplo BA117).',
			'createFlight.flightNumberSearch.hint' => 'p. ej. BA117',
			'createFlight.flightNumberSearch.loading' => 'Buscando tu vuelo',
			'createFlight.flightNumberSearch.loadingHint' => 'Esto puede tardar unos segundos mientras comprobamos vuelos recientes.',
			'createFlight.flightNumberSearch.invalidFormatError' => 'Introduce un número de vuelo válido, como BA117.',
			'createFlight.flightNumberSearch.notFoundError' => 'No pudimos encontrar ese número de vuelo. Revísalo e inténtalo de nuevo o búscalo por aeropuertos.',
			'createFlight.flightNumberSearch.rateLimitedError' => 'Hay demasiadas búsquedas de vuelos en este momento. Inténtalo de nuevo en un momento o búscalo por aeropuertos.',
			'createFlight.flightNumberSearch.providerUnavailableError' => 'Los datos del vuelo no están disponibles temporalmente. Inténtalo de nuevo en un momento o búscalo por aeropuertos.',
			'createFlight.flightNumberSearch.unexpectedError' => 'Se produjo un error al buscar este vuelo. Inténtalo de nuevo o búscalo por aeropuertos.',
			'createFlight.flightNumberSearch.findByAirports' => 'Buscar por aeropuertos',
			'createFlight.flightNumberSearch.airportsFallbackButton' => 'Buscar por aeropuertos',
			'createFlight.flightNumberSearch.confirmTitle' => 'Confirmar vuelo',
			'createFlight.flightNumberSearch.foundTitle' => 'Hemos encontrado tu vuelo',
			'createFlight.flightNumberSearch.editFlightNumber' => 'Editar número de vuelo',
			'createFlight.flightNumberSearch.beyondWindowHint' => '¿Vuelas más adelante? Para obtener el mapa de vuelo más actualizado y preciso, te recomendamos descargarlo dentro de los 7 días previos a tu vuelo.',
			'createFlight.flightNumberSearch.basedOnSameFlightOn' => '* Basado en la ruta registrada más reciente para el mismo vuelo',
			'createFlight.realRouteAirportSearch.title' => 'Buscar vuelos reales por aeropuertos',
			'createFlight.realRouteAirportSearch.subtitle' => 'Elige los aeropuertos de salida y llegada para buscar vuelos reales recientes en esta ruta.',
			'createFlight.realRouteAirportSearch.searchAction' => 'Buscar vuelos recientes',
			'createFlight.realRouteAirportSearch.loading' => 'Buscando vuelos reales recientes',
			'createFlight.realRouteAirportSearch.loadingHint' => 'Esto puede tardar unos segundos mientras revisamos el historial reciente de la ruta.',
			'createFlight.realRouteAirportSearch.sorryNoFlightFromTo' => ({required Object departure, required Object arrival}) => 'Lo sentimos, no pudimos encontrar vuelos de ${departure} a ${arrival}.',
			'createFlight.realRouteAirportSearch.emptyTitle' => 'No pudimos encontrar vuelos recientes entre estos aeropuertos',
			'createFlight.realRouteAirportSearch.emptyResults' => 'Asegúrate de haber seleccionado los mismos aeropuertos de salida y llegada que aparecen en tu billete de vuelo.',
			'createFlight.realRouteAirportSearch.searchReverse' => 'Probar la dirección inversa',
			'createFlight.realRouteAirportSearch.rateLimitedError' => 'Hay demasiadas búsquedas de vuelos en este momento. Inténtalo de nuevo en un momento.',
			'createFlight.realRouteAirportSearch.providerUnavailableError' => 'Los datos de vuelos reales no están disponibles temporalmente. Inténtalo de nuevo en un momento.',
			'createFlight.realRouteAirportSearch.unexpectedError' => 'Se produjo un error al buscar esta ruta. Inténtalo de nuevo.',
			'createFlight.realRouteAirportSearch.foundOneTitle' => ({required Object route}) => 'Se encontró 1 vuelo · ${route}',
			'createFlight.realRouteAirportSearch.foundManyTitle' => ({required Object count, required Object route}) => 'Se encontraron ${count} vuelos · ${route}',
			'createFlight.realRouteAirportSearch.ticketMatchHint' => 'Asegúrate de que coincidan con los aeropuertos de tu billete de vuelo.',
			'createFlight.realRouteAirportSearch.findByFlightNumber' => 'Buscar por número de vuelo',
			'createFlight.search.departureHint' => 'Buscar aeropuerto de salida',
			'createFlight.search.arrivalHint' => 'Buscar aeropuerto de llegada',
			'createFlight.search.removeFavorite' => 'Eliminar favorito',
			'createFlight.search.addFavorite' => 'Añadir a favoritos',
			'createFlight.search.removeSelectedAirport' => 'Eliminar aeropuerto seleccionado',
			'createFlight.search.favorites' => 'Favoritos',
			'createFlight.search.recentAirports' => 'Aeropuertos recientes',
			'createFlight.search.popularAirports' => 'Aeropuertos populares',
			'createFlight.search.removeFromFavorites' => 'Eliminar de favoritos',
			'createFlight.search.noDepartureFound' => 'No se encontraron aeropuertos de salida.',
			'createFlight.search.noArrivalFound' => 'No se encontraron aeropuertos de llegada.',
			'createFlight.search.airportCodeCity' => ({required Object code, required Object city}) => '${code} · ${city}',
			'createFlight.search.airportNameCode' => ({required Object name, required Object code}) => '${name} (${code})',
			'createFlight.mapPreview.routeNotSupportedMsg' => 'Lo sentimos, los vuelos que cruzan el antimeridiano aún no son compatibles.',
			'createFlight.mapPreview.basic' => 'Básico',
			'createFlight.mapPreview.pro' => 'Pro',
			'createFlight.mapPreview.mapDetailInfoTooltip' => 'Nota sobre la ruta',
			'createFlight.mapPreview.legendButton' => 'Leyenda',
			'createFlight.mapPreview.legendTitle' => 'Leyenda de PDI',
			'createFlight.mapPreview.estimatedMapSize' => ({required Object size}) => 'Tamaño estimado del mapa: ${size}',
			'createFlight.mapPreview.upgradeToPro' => 'Pasar a Pro',
			'createFlight.mapPreview.basicHint' => 'Detalle básico del mapa con lugares limitados',
			'createFlight.mapPreview.proGateHint' => 'Mejora para obtener un mapa detallado con todos los lugares',
			'createFlight.mapPreview.proHint' => ({required Object count}) => 'Mapa offline detallado con ${count} lugares',
			'createFlight.mapPreview.optionsTitle' => 'Ruta aproximada',
			'createFlight.mapPreview.optionsBody' => 'La ruta es aproximada; el trayecto real puede variar, especialmente en vuelos de larga distancia.',
			'createFlight.overview.routeNotReady' => 'La ruta aún no está lista.',
			'createFlight.overview.proPoiUpsell' => 'El plan Free incluye mapa básico y lugares limitados',
			'createFlight.overview.routeNoteTooltip' => 'Nota sobre la ruta',
			'createFlight.overview.routeNoteTitle' => 'Ruta aproximada',
			'createFlight.overview.routeNoteBody' => 'La ruta es aproximada; el trayecto real puede variar, especialmente en vuelos de larga distancia.',
			'createFlight.overview.realRouteNoteTitle' => 'Ruta real',
			'createFlight.overview.realRouteNoteBody' => 'Esta ruta se basa en la ruta registrada más reciente para el mismo vuelo.\nLa ruta real puede variar debido al clima, al tráfico aéreo y a restricciones operativas.',
			'createFlight.overview.approximateRouteLongHaulWarningTitle' => 'Esta es una ruta aproximada',
			'createFlight.overview.approximateRouteLongHaulWarningBody' => 'Las rutas aproximadas pueden ser inexactas para vuelos de larga distancia. Usa una ruta real con un número de vuelo.',
			'createFlight.overview.approximateRouteUltraLongHaulUnsupportedBody' => 'Las rutas aproximadas no son compatibles con vuelos ultralargos. Usa una ruta real con un número de vuelo.',
			'createFlight.overview.startReview' => 'Empezar revisión',
			'createFlight.overview.skipReview' => 'Omitir revisión',
			'createFlight.overview.premiumGateTitle' => 'Desbloquear resumen completo de la ruta',
			'createFlight.overview.premiumGateBody' => 'El plan Free incluye una vista previa limitada de la ruta. Mejora a Pro para ver todas las regiones de esta ruta.',
			'createFlight.overview.premiumGateBodyWithCount' => ({required Object count}) => 'Desbloquea las ${count} regiones de esta ruta con Pro.',
			'createFlight.overview.premiumGateCta' => 'Pasar a Pro',
			'createFlight.overview.buildingHint' => 'En rutas largas esto puede tardar unos segundos…',
			'createFlight.overview.routeReviewedTitle' => 'Ruta revisada',
			'createFlight.overview.routeReviewedSubtitle' => ({required Object regions, required Object departure, required Object arrival}) => 'Volarás sobre ${regions} desde ${departure} hasta ${arrival}.',
			'createFlight.overview.fullSummary' => 'Resumen completo',
			'createFlight.overview.routeSummaryTitle' => 'Resumen de la ruta',
			'createFlight.overview.routeSummaryDistanceLabel' => 'Distancia',
			'createFlight.overview.routeSummaryDurationLabel' => 'Duración',
			'createFlight.overview.routeSummaryRegionsLabel' => 'Regiones',
			'createFlight.overview.routeSummaryRegionsTitle' => 'Sobrevolarás',
			'createFlight.overview.routeSummaryPlacesLabel' => 'Lugares',
			'createFlight.overview.routeSummaryTimelineTitle' => 'Cronología',
			'createFlight.overview.routeSummaryPlacesTitle' => 'Lugares a lo largo de la ruta',
			'createFlight.overview.routeSummaryPoiSearchHint' => 'Buscar lugares',
			'createFlight.overview.routeSummaryPoiNoMatches' => 'Ningún lugar coincide con tu búsqueda.',
			'createFlight.overview.airportCard.departureDescription' => ({required Object airport}) => 'Empezarás tu viaje desde ${airport}.',
			'createFlight.overview.airportCard.arrivalDescription' => ({required Object airport}) => 'Llegarás a ${airport}.',
			'createFlight.overview.regionInfo.descriptionUnavailable' => 'La descripción aún no está disponible.',
			'createFlight.overview.regionInfo.wikipediaSectionTitle' => 'Wikipedia',
			'createFlight.overview.regionInfo.wikipediaUnavailable' => 'El artículo de Wikipedia no está disponible ahora mismo.',
			'createFlight.overview.regionInfo.openWikipedia' => 'Abrir Wikipedia',
			'createFlight.overview.timeline.takeOffTimeline' => 'Despe-\ngue',
			'createFlight.overview.timeline.land' => 'Aterrizar',
			'createFlight.overview.timeline.alsoAroundThisTime' => 'También por este momento:',
			'createFlight.overview.timeline.minuteUnit' => 'min',
			'createFlight.overview.timeline.hourCompactUnit' => 'h',
			'createFlight.overview.timeline.minuteCompactUnit' => 'm',
			'createFlight.overview.timeline.regionType.country' => 'País',
			'createFlight.overview.timeline.regionType.region' => 'Región',
			'createFlight.overview.timeline.regionType.state' => 'Estado',
			'createFlight.overview.timeline.regionType.province' => 'Provincia',
			'createFlight.overview.timeline.regionType.sea' => 'Mar',
			'createFlight.overview.timeline.regionType.ocean' => 'Océano',
			'createFlight.overview.timeline.regionType.strait' => 'Estrecho',
			'createFlight.overview.timeline.regionType.channel' => 'Canal',
			'createFlight.overview.timeline.regionType.gulf' => 'Golfo',
			'createFlight.overview.timeline.regionType.bay' => 'Bahía',
			'createFlight.overview.timeline.regionType.lake' => 'Lago',
			'createFlight.overview.timeline.regionType.alkalineLake' => 'Lago alcalino',
			'createFlight.overview.timeline.regionType.island' => 'Isla',
			'createFlight.overview.timeline.regionType.archipelago' => 'Archipiélago',
			'createFlight.overview.timeline.regionType.peninsula' => 'Península',
			'createFlight.overview.timeline.regionType.coast' => 'Costa',
			'createFlight.overview.timeline.regionType.mountainRange' => 'Cordillera',
			'createFlight.overview.timeline.regionType.valley' => 'Valle',
			_ => null,
		} ?? switch (path) {
			'createFlight.overview.timeline.regionType.plateau' => 'Meseta',
			'createFlight.overview.timeline.regionType.plain' => 'Llanura',
			'createFlight.overview.timeline.regionType.basin' => 'Cuenca',
			'createFlight.overview.timeline.regionType.lowland' => 'Tierras bajas',
			'createFlight.overview.timeline.regionType.tundra' => 'Tundra',
			'createFlight.overview.timeline.regionType.wetlands' => 'Humedales',
			'createFlight.overview.timeline.regionType.desert' => 'Desierto',
			'createFlight.overview.timeline.regionType.delta' => 'Delta',
			'createFlight.overview.timeline.regionType.reservoir' => 'Embalse',
			'createFlight.overview.timeline.regionType.continent' => 'Continente',
			'createFlight.overview.timeline.regionType.geoarea' => 'Área geográfica',
			'createFlight.overview.timeline.regionType.isthmus' => 'Istmo',
			'createFlight.overview.timeline.regionType.unknown' => 'Tipo de región desconocido',
			'createFlight.wikipedia.title' => 'Descarga artículos y lee mientras estás en el aire',
			'createFlight.wikipedia.loadingIntro' => 'Buscando artículos relacionados con la ruta...',
			'createFlight.wikipedia.foundIntro' => ({required Object count}) => 'Según tu ruta, encontramos ${count} artículos relevantes',
			'createFlight.wikipedia.emptyIntro' => 'No se encontraron artículos de Wikipedia relacionados con la ruta. Puedes continuar descargando solo el mapa.',
			'createFlight.wikipedia.selectedCount' => ({required Object count}) => '${count} seleccionados',
			'createFlight.wikipedia.unselectAll' => 'Deseleccionar todo',
			'createFlight.wikipedia.selectAll' => 'Seleccionar todo',
			'createFlight.wikipedia.basicHint' => ({required Object count}) => 'Artículos offline seleccionados: ${count}',
			'createFlight.wikipedia.proHint' => 'Mapa y paquete de datos offline',
			'createFlight.wikipedia.proGateHint' => 'Mejora para obtener el paquete completo de artículos offline',
			'createFlight.wikipedia.proActiveTitle' => 'Pro activo',
			'createFlight.wikipedia.proActiveMessage' => 'Paquete completo de artículos desbloqueado.',
			'createFlight.wikipedia.freeLimitHint' => 'El plan Free incluye hasta 3 artículos offline',
			'createFlight.wikipedia.estimatedDownloadSize' => ({required Object size}) => 'Tamaño estimado de descarga: ${size}',
			'createFlight.wikipedia.upgrade' => 'Pasar a Pro',
			'createFlight.wikipedia.loadingSuggestions' => 'Cargando sugerencias de artículos...',
			'createFlight.wikipedia.downloadMapOnly' => 'Descargar mapa',
			'createFlight.wikipedia.downloadMapPlusOne' => 'Descargar mapa + 1 artículo',
			'createFlight.wikipedia.downloadMapPlusMany' => ({required Object count}) => 'Descargar mapa + ${count} artículos',
			'createFlight.wikipedia.couldNotOpenLink' => 'No se pudo abrir el enlace',
			'createFlight.downloading.articlesTitle' => 'Descargando artículos seleccionados...',
			'createFlight.downloading.mapTitle' => 'Descargando mapa offline...',
			'createFlight.downloading.mapSectionTitle' => 'Mapa',
			'createFlight.downloading.poiSectionTitle' => 'Lugares',
			'createFlight.downloading.articlesSectionTitle' => 'Artículos',
			'createFlight.downloading.cancelDownload' => 'Cancelar descarga',
			'createFlight.downloading.doNotClose' => 'No cierres esta pantalla hasta que se complete la descarga',
			'createFlight.downloading.currentStep' => 'Actual',
			'createFlight.downloading.pending' => 'Pendiente',
			'createFlight.downloading.inProgress' => 'En curso',
			'createFlight.downloading.completed' => 'Completado',
			'createFlight.downloading.completedWithIssues' => 'Completado con incidencias',
			'createFlight.downloading.failed' => 'Fallido',
			'createFlight.downloading.skipped' => 'Omitido',
			'createFlight.downloading.waitingForMap' => 'Esperando la descarga del mapa...',
			'createFlight.downloading.mapFailed' => 'La descarga del mapa falló.',
			'createFlight.downloading.noPoiSelected' => 'No se seleccionaron resúmenes de lugares.',
			'createFlight.downloading.preparingPoi' => 'Preparando resúmenes de lugares...',
			'createFlight.downloading.poiProgress' => ({required Object completed, required Object total}) => 'Lugares: ${completed}/${total}',
			'createFlight.downloading.poiProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Lugares: ${completed}/${total} (${failed} fallidos)',
			'createFlight.downloading.noArticlesSelected' => 'No se seleccionaron artículos.',
			'createFlight.downloading.preparingArticles' => 'Preparando descargas de artículos...',
			'createFlight.downloading.articlesProgress' => ({required Object completed, required Object total}) => 'Artículos: ${completed}/${total}',
			'createFlight.downloading.articlesProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Artículos: ${completed}/${total} (${failed} fallidos)',
			'createFlight.downloading.preparingMap' => 'Preparando descarga del mapa...',
			'createFlight.downloading.computingTiles' => 'Calculando teselas del mapa...',
			'createFlight.downloading.computingTilesWithCount' => ({required Object count}) => 'Calculando teselas del mapa (${count})...',
			'createFlight.downloading.preparingForDownload' => 'Preparando la descarga...',
			'createFlight.downloading.downloaded' => ({required Object size}) => 'Descargado: ${size}',
			'createFlight.downloading.finalizing' => 'Finalizando el paquete del mapa...',
			'createFlight.downloading.verifying' => 'Verificando el paquete del mapa...',
			'createFlight.errors.failedLoadAirports' => 'No se pudieron cargar los aeropuertos. Inténtalo de nuevo.',
			'createFlight.errors.airportSearchFailed' => 'La búsqueda de aeropuertos falló. Prueba otra consulta.',
			'createFlight.errors.someArticlesFailed' => 'Algunos artículos fallaron. Continuando con la descarga del mapa.',
			'createFlight.errors.someOptionalDownloadsFailed' => 'Mapa descargado. No se pudo descargar parte del contenido opcional.',
			'createFlight.errors.failedBuildPreview' => 'No se pudo generar la vista previa de la ruta. Inténtalo de nuevo.',
			'createFlight.errors.overviewUnavailableContinue' => 'No se pudo cargar el resumen de la ruta. Aun así puedes continuar.',
			'createFlight.errors.noInternet' => 'Sin conexión a internet. Comprueba tu conexión e inténtalo de nuevo.',
			'createFlight.errors.failedStartDownload' => ({required Object error}) => 'No se pudo iniciar la descarga: ${error}',
			'createFlight.paywall.upgradeCancelled' => 'Actualización cancelada.',
			'createFlight.paywall.noPaywall' => 'No hay pantalla de pago disponible en este momento.',
			'createFlight.paywall.failedOpenPaywall' => 'No se pudo abrir la pantalla de pago.',
			'createFlight.realRouteChoice.title' => '¿Obtener la ruta real del vuelo?',
			'createFlight.realRouteChoice.body' => 'Todo en este vuelo está desbloqueado. Aún usa una ruta aproximada — introduce tu número de vuelo y lo reconstruiremos con la trayectoria real.',
			'createFlight.realRouteChoice.ctaEnterFlightNumber' => 'Introducir mi número de vuelo',
			'createFlight.realRouteChoice.ctaKeepRoute' => 'Mantener ruta aproximada',
			'preview.calculatingRoute' => 'Calculando la ruta del vuelo...',
			'preview.errorTitle' => 'Error',
			'preview.errorSomethingWrong' => 'Algo salió mal',
			'preview.tryAgain' => 'Intentar de nuevo',
			'preview.downloadCongratsTitle' => '¡Perfecto! Ya está todo listo.',
			'preview.offlineSavedDetail' => 'El mapa y los datos de vuelo seleccionados se guardaron para usarlos offline durante tu vuelo.',
			'preview.downloadCompletedTitle' => 'Descarga completada',
			'preview.shareFlightCard' => 'Presume de tu increíble vuelo',
			'preview.shareVideo' => 'Compartir vídeo del vuelo',
			'preview.shareVideoNewBadge' => 'NUEVO',
			'preview.share' => 'Compartir tarjeta de vuelo',
			'preview.home' => 'Inicio',
			'preview.navigatingHome' => 'Volviendo al inicio...',
			'preview.downloadingMapTitle' => 'Descargando recursos',
			'preview.cancelDownload' => 'Cancelar descarga',
			'preview.download' => 'Descargar',
			'preview.flightRoute' => ({required Object distance}) => 'Ruta del vuelo (~ ${distance})',
			'flight.tabMap' => 'Mapa',
			'flight.tabDashboard' => 'Panel',
			'flight.tabRoute' => 'Ruta',
			'flight.tabRead' => 'Leer',
			'flight.tabCamera' => 'Cámara',
			'flight.tabInfo' => 'Info',
			'flight.completeDialogTitle' => '¿Completar vuelo?',
			'flight.completeDialogBody' => 'Esto marcará tu vuelo como completado.',
			'flight.completeDialogDeleteOffline' => 'Eliminar mapa y artículos offline',
			'flight.completeDialogConfirm' => 'Completar',
			'flight.deleteDialogTitle' => '¿Estás seguro?',
			'flight.deleteDialogMessage' => ({required Object size}) => 'Esto elimina permanentemente este vuelo, incluido el mapa offline y los artículos offline guardados.\n\nEspacio que se recuperará: ${size}.',
			'flight.yes' => 'Sí',
			'flight.shareRoute' => 'Compartir ruta',
			'flight.copyRoute' => 'Copiar ruta',
			'flight.deleteFlight' => 'Eliminar vuelo',
			'flight.routeSummaryCopied' => 'Resumen de la ruta copiado',
			'flight.deleted' => 'Vuelo eliminado',
			'flight.deleteError' => ({required Object error}) => 'Error al eliminar el vuelo: ${error}',
			'flight.map.initializing' => 'Cargando mapa',
			'flight.map.loadingStyle' => 'Cargando mapa',
			'flight.map.offlineNotAvailable' => 'El mapa offline no está disponible para este vuelo.',
			'flight.map.offlineMissing' => 'Falta el archivo del mapa offline. Vuelve a descargar esta ruta.',
			'flight.map.validationFailed' => 'La validación del mapa offline falló. Vuelve a descargar esta ruta.',
			'flight.map.loadStyleFailed' => 'No se pudo cargar el estilo del mapa offline.',
			'flight.map.sunriseInMinutes' => ({required Object minutes}) => 'Amanecer en ${minutes} min',
			'flight.map.sunsetInMinutes' => ({required Object minutes}) => 'Atardecer en ${minutes} min',
			'flight.map.switchTo2D' => 'Cambiar a 2D',
			'flight.map.switchTo3D' => 'Cambiar a 3D',
			'flight.map.switchToLightMapStyle' => 'Cambiar al estilo de mapa claro',
			'flight.map.switchToDarkMapStyle' => 'Cambiar al estilo de mapa oscuro',
			'flight.map.uncenterMap' => 'Descentrar mapa',
			'flight.map.centerOnMe' => 'Centrar en mí',
			'flight.dashboard.gpsOffTitle' => 'Los servicios de ubicación están desactivados',
			'flight.dashboard.gpsOffSubtitle' => 'Activa los servicios de ubicación en los ajustes del sistema para reanudar el seguimiento del vuelo en vivo y el seguimiento del mapa.',
			'flight.dashboard.openLocationSettings' => 'Abrir ajustes de ubicación',
			'flight.dashboard.permissionTitle' => 'Permiso de ubicación requerido',
			'flight.dashboard.permissionSubtitle' => 'Permite el acceso a la ubicación para que el panel pueda mostrar rumbo, velocidad y altitud en vivo.',
			'flight.dashboard.grantPermissions' => 'Conceder permisos',
			'flight.dashboard.gpsAccuracy' => ({required Object label, required Object accuracy}) => 'Precisión GPS: ${label} (±${accuracy} m)',
			'flight.dashboard.accuracyExcellent' => 'Excelente',
			'flight.dashboard.accuracyGood' => 'Buena',
			'flight.dashboard.accuracyPoor' => 'Baja',
			'flight.dashboard.gpsOff' => 'GPS apagado',
			'flight.dashboard.gpsOffHint' => 'Activa los servicios de ubicación para empezar el seguimiento.',
			'flight.dashboard.gpsPermissionRequired' => 'Permiso de GPS requerido',
			'flight.dashboard.gpsPermissionHint' => 'Concede permiso para acceder a la telemetría en vivo del vuelo.',
			'flight.dashboard.gpsSearching' => 'Buscando GPS',
			'flight.dashboard.gpsSearchingHint' => 'Buscando una señal fiable',
			'flight.dashboard.gpsSearchingHintWithAge' => ({required Object age}) => 'Buscando GPS. Última posición ${age}.',
			'flight.dashboard.gpsWeak' => 'Señal GPS débil',
			'flight.dashboard.gpsWeakHint' => 'La señal es inestable. Mantén el dispositivo con cielo abierto.',
			'flight.dashboard.gpsWeakHintWithAge' => ({required Object age}) => 'Señal inestable. Última posición ${age}.',
			'flight.dashboard.gpsActive' => 'GPS activo',
			'flight.dashboard.gpsActiveHint' => 'Recibiendo telemetría en vivo.',
			'flight.dashboard.gpsActiveHintWithAge' => ({required Object age}) => 'Última actualización GPS ${age}.',
			'flight.dashboard.gpsShowingLastKnownData' => 'Mostrando los últimos datos conocidos',
			'flight.dashboard.gpsHelpTooltip' => 'Solución de problemas de GPS',
			'flight.dashboard.gpsHelpTitle' => 'Solución de problemas de GPS',
			'flight.dashboard.gpsHelpBody' => 'Parece que la señal GPS no es fiable en tu teléfono.',
			'flight.dashboard.gpsHelpStepsTitle' => 'Prueba esto',
			'flight.dashboard.gpsHelpTipLocation' => 'Asegúrate de que los servicios de ubicación estén activados',
			'flight.dashboard.gpsHelpTipWindow' => 'Acerca el teléfono a la ventana',
			'flight.dashboard.gpsHelpTipCase' => 'Quita fundas gruesas o accesorios metálicos',
			'flight.dashboard.gpsHelpTipFlat' => 'Mantén el teléfono quieto unos momentos',
			'flight.dashboard.gpsHelpFooter' => 'El seguimiento en vivo se reanudará automáticamente cuando la señal se estabilice.',
			'flight.dashboard.ageJustNow' => 'ahora mismo',
			'flight.dashboard.ageSeconds' => ({required Object seconds}) => 'hace ${seconds} s',
			'flight.dashboard.ageMinutes' => ({required Object minutes}) => 'hace ${minutes} min',
			'flight.dashboard.signalGood' => 'Buena',
			'flight.dashboard.signalPoor' => 'Baja',
			'flight.dashboard.signalBad' => 'Mala',
			'flight.dashboard.signalSearching' => 'Buscando',
			'flight.dashboard.gpsQuality' => ({required Object quality}) => 'GPS ${quality}',
			'flight.dashboard.gpsSearchingLabel' => 'Buscando GPS',
			'flight.dashboard.gpsPermissionNeededLabel' => 'Permiso de GPS necesario',
			'flight.dashboard.gpsOffLabel' => 'GPS apagado',
			'flight.dashboard.aircraftHeading' => 'Rumbo de la aeronave',
			'flight.dashboard.headingShort' => ({required Object heading}) => 'HDG ${heading}°',
			'flight.dashboard.liveInstruments' => 'Instrumentos en vivo',
			'flight.dashboard.groundSpeed' => 'Velocidad sobre el suelo',
			'flight.dashboard.altitudeMsl' => 'Altitud AMSL',
			'flight.dashboard.outsideAirApprox' => 'Temperatura exterior',
			'flight.dashboard.temperatureAvailableAfter' => ({required Object threshold}) => 'Disponible después de ${threshold}',
			'flight.dashboard.temperatureApproxHint' => 'Estimación aproximada según la altitud',
			'flight.dashboard.headingPanel' => 'Rumbo',
			'flight.dashboard.flightPhaseTaxi' => 'Rodaje',
			'flight.dashboard.flightPhaseGroundRoll' => 'Carrera en tierra',
			'flight.dashboard.flightPhaseTakeoffRoll' => 'Carrera de despegue',
			'flight.dashboard.flightPhaseLandingRoll' => 'Carrera de aterrizaje',
			'flight.dashboard.flightPhaseAscending' => 'Ascendiendo',
			'flight.dashboard.flightPhaseCruising' => 'Crucero',
			'flight.dashboard.flightPhaseDescending' => 'Descendiendo',
			'flight.dashboard.acquiringGpsSignal' => 'Adquiriendo señal GPS',
			'flight.dashboard.acquiringGpsHint' => 'Mantén el dispositivo estable y con cielo abierto para obtener una posición fiable.',
			'flight.dashboard.weakSignalBanner' => 'Señal GPS débil. Los valores pueden desviarse hasta que mejore la precisión.',
			'flight.dashboard.preparingDashboard' => 'Preparando panel...',
			'flight.dashboard.navigation' => 'Navegación',
			'flight.dashboard.heading' => ({required Object heading}) => 'Rumbo ${heading}',
			'flight.dashboard.routeProgress' => 'Progreso de la ruta',
			'flight.dashboard.covered' => 'Recorrido',
			'flight.dashboard.remaining' => 'Restante',
			'flight.dashboard.total' => 'Total',
			'flight.upcoming.mapTitle' => 'Empieza tu viaje en vuelo',
			'flight.upcoming.mapSubtitle' => 'Inicia el seguimiento en vivo cuando comience tu vuelo',
			'flight.upcoming.dashboardTitle' => 'Empieza tu viaje en vuelo',
			'flight.upcoming.dashboardSubtitle' => 'Empieza a ver tu panel en vivo',
			'flight.upcoming.checkInButton' => 'Iniciar',
			'flight.upcoming.checkInSuccess' => 'Vuelo iniciado',
			'flight.upcoming.checkInError' => 'No se pudo iniciar ahora. Inténtalo de nuevo',
			'flight.info.overviewTitle' => 'Resumen',
			'flight.info.overviewLoading' => 'Creando resumen de la ruta...',
			'flight.info.overviewEmpty' => 'El resumen aún no está disponible para esta ruta.',
			'flight.info.loadingRouteInformation' => 'Cargando información de la ruta...',
			'flight.info.flyOverTitle' => 'Lo más destacado de tu ruta',
			'flight.info.airportsTitle' => 'Aeropuertos',
			'flight.info.departure' => 'Salida',
			'flight.info.arrival' => 'Llegada',
			'flight.info.showAll' => 'Mostrar todo',
			'flight.info.showAllCount' => ({required Object count}) => 'Mostrar todo (${count})',
			'flight.info.showLess' => 'Mostrar menos',
			'flight.info.sortByRank' => 'Por relevancia',
			'flight.info.sortByRouteProgress' => 'Por ruta',
			'flight.info.sortByType' => 'Por tipo',
			'flight.info.routeTimelineTitle' => 'Cronología de la ruta',
			'flight.info.plannedWaypoints' => ({required Object count}) => '${count} puntos de ruta planificados',
			'flight.info.pointsOfInterestTitle' => 'Puntos de interés',
			'flight.info.noPoi' => 'Aún no hay PDI disponibles.',
			'flight.info.poiType' => ({required Object type}) => 'Tipo: ${type}',
			'flight.info.poiFlyOver' => ({required Object view}) => 'Sobrevuelo: ${view}',
			'flight.info.offlineArticlesTitle' => 'Artículos offline',
			'flight.info.regionArticlesTitle' => 'Artículos de la región',
			'flight.info.otherArticlesTitle' => 'Otros artículos',
			'flight.info.noOfflineArticles' => 'No se han descargado artículos offline.',
			'flight.info.openSource' => 'Abrir fuente',
			'flight.info.openSourcePage' => 'Abrir página de origen',
			'flight.info.openSourcePageTooltip' => 'Abrir página de origen',
			'flight.info.distanceKm' => ({required Object distance}) => '${distance} km',
			'flight.info.speed' => 'Velocidad',
			'flight.info.altitude' => 'Altitud',
			'flight.info.copyRouteTitle' => 'Ruta de Flymap',
			'flight.info.copyRouteCode' => ({required Object routeCode}) => 'Código de ruta: ${routeCode}',
			'flight.info.copyDistance' => ({required Object distance}) => 'Distancia: ${distance} km',
			'flight.info.copyFrom' => 'Desde',
			'flight.info.copyTo' => 'Hasta',
			'flight.info.copyCity' => ({required Object city, required Object countryCode}) => 'Ciudad: ${city}, ${countryCode}',
			'flight.info.copyAirport' => ({required Object airport}) => 'Aeropuerto: ${airport}',
			'flight.info.copyCodes' => ({required Object iata, required Object icao}) => 'Códigos: IATA ${iata} | ICAO ${icao}',
			'flight.route.loadingRouteTimeline' => 'Cargando cronología de la ruta...',
			'flight.route.noSavedOfflineRegions' => 'No hay regiones offline guardadas para este vuelo.',
			'flight.route.currentProgress' => ({required Object percentage, required Object minute}) => 'Progreso actual: ${percentage}% (aprox. ${minute} desde el despegue)',
			'flight.route.nowLabel' => 'Ahora',
			'flight.route.currentRegionLabel' => 'Actual',
			'flight.route.nextRegionLabel' => 'Siguiente',
			'flight.route.arrivingLabel' => 'Llegando',
			'flight.route.arrivedLabel' => 'Llegado',
			'flight.route.etaLabel' => ({required Object time}) => 'ETA: ${time}',
			'flight.route.etaInLabel' => ({required Object time}) => 'en ${time}',
			'flight.route.flyingOverLabel' => 'Estás volando sobre:',
			'flight.route.premiumLockedChipLabel' => 'Desbloquear',
			'flight.route.premiumGateTitle' => 'Desbloquear cronología completa de la ruta',
			'flight.route.premiumGateBody' => 'Pásate a Pro para ver todas las regiones de tu ruta y los detalles de la cronología.',
			'flight.route.premiumGateBodyWithCount' => ({required Object count}) => 'Desbloquea las ${count} regiones de esta ruta con Premium.',
			'flight.route.premiumGateCta' => 'Pasar a Pro',
			'flight.route.premiumOfflineTitle' => 'Se necesita internet para mejorar',
			'flight.route.premiumOfflineBody' => 'Ahora mismo estás offline. Conéctate a internet para mejorar y desbloquear la vista completa de la ruta.',
			'flight.route.nextHintLabel' => ({required Object region, required Object eta}) => 'Siguiente: ${region} (${eta})',
			'flight.route.etaUnknownLabel' => 'calculando...',
			'shareFlight.title' => 'Compartir vuelo',
			'shareFlight.preparingMap' => 'Preparando mapa de vista previa para compartir...',
			'shareFlight.preparingScreenshot' => 'Preparando captura...',
			'shareFlight.share' => 'Compartir',
			'shareFlight.route' => 'Ruta',
			'shareFlight.offlineMapMissing' => 'Falta el mapa offline. Se usará el estilo online.',
			'shareFlight.offlineStyleFailed' => 'No se pudo cargar el estilo offline. Se usará el estilo online.',
			'shareFlight.captureFailed' => 'No se pudo capturar la imagen de la ruta',
			'shareFlight.shareFailed' => 'No se pudo compartir la imagen de la ruta',
			'shareFlight.shareText' => ({required Object from, required Object to}) => 'Ruta del vuelo ${from}-${to}',
			'shareFlight.watermark' => 'Flymap',
			'shareFlight.flightDistance' => 'Distancia del vuelo',
			'shareFlight.distanceKm' => ({required Object distance}) => '${distance} km',
			'shareImage.title' => 'Compartir vuelo',
			'shareImage.generating' => 'Creando tu tarjeta de vuelo...',
			'shareImage.share' => 'Compartir',
			'shareImage.sharing' => 'Compartiendo...',
			'shareImage.retry' => 'Reintentar',
			'shareImage.error' => 'No se pudo generar la tarjeta de vuelo',
			'shareImage.tagline' => 'Cada vuelo es un descubrimiento',
			'shareImage.brand' => 'Flymap',
			'shareImage.exploreYourFlight' => 'Explora tu vuelo',
			'shareImage.countrySingle' => '1 país',
			'shareImage.countries' => ({required Object count}) => '${count} países',
			'shareImage.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) en Flymap ✈️',
			'shareImage.unknownCity' => 'Desconocida',
			'shareImage.durationUnavailable' => '--',
			'shareImage.durationMinutes' => ({required Object minutes}) => '${minutes} min',
			'shareImage.durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} h ${minutes} min',
			'flightVideo.title' => 'Vídeo del vuelo',
			'flightVideo.preparing' => 'Preparando tu mapa...',
			'flightVideo.rendering' => 'Creando tu vídeo...',
			'flightVideo.export' => 'Guardar vídeo',
			'flightVideo.savedToGallery' => 'Guardado en tu galería',
			'flightVideo.saveSkipped' => 'No se pudo guardar en la galería — aún puedes compartirlo',
			'flightVideo.share' => 'Compartir',
			'flightVideo.sharing' => 'Compartiendo...',
			'flightVideo.retry' => 'Reintentar',
			'flightVideo.errorNetwork' => 'No se pudieron cargar las imágenes del mapa. Comprueba tu conexión e inténtalo de nuevo.',
			'flightVideo.errorGeneric' => 'No se pudo crear el vídeo del vuelo',
			'flightVideo.errorOfflineTitle' => 'Estás sin conexión',
			'flightVideo.errorOffline' => 'Los vídeos de vuelo cargan imágenes de mapa en tiempo real, así que necesitan conexión a internet. Desactiva el modo avión o vuelve a conectarte e inténtalo de nuevo.',
			'flightVideo.offlineStyleChange' => 'Cambiar el estilo del mapa necesita conexión.',
			'flightVideo.madeWith' => 'Hecho con Flymap',
			'flightVideo.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) en Flymap ✈️',
			'flightVideo.removeWatermark' => 'Quitar marca de agua',
			'flightVideo.styleSatellite' => 'Satélite',
			'flightVideo.styleDefault' => 'Predeterminado',
			'flightVideo.videoSettings' => 'Ajustes de video',
			'flightVideo.mapStyle' => 'Estilo de mapa',
			'flightVideo.mysteryDestination' => 'Destino misterioso',
			'flightVideo.mysteryDestinationHint' => 'Mostrar "?" hasta que aterrice el avión',
			'flightVideo.showPins' => 'Pines de países',
			'flightVideo.showPinsHint' => 'Coloca un pin cuando el avión cruza cada país',
			'flightVideo.showEndCard' => 'Tarjeta resumen',
			'flightVideo.showEndCardHint' => 'Mostrar la tarjeta resumen al final',
			'flightVideo.styleShine' => 'Lè Shine',
			'flightVideo.applySettings' => 'Aplicar cambios',
			'flightVideo.applying' => 'Aplicando cambios...',
			'flightVideo.avatarTitle' => 'Tu avatar',
			'flightVideo.avatarHint' => 'Vuela tu ruta con tu propia foto',
			'flightVideo.avatarSetupTitle' => 'Tu avatar',
			'flightVideo.avatarPick' => 'Elegir foto',
			'flightVideo.avatarChange' => 'Cambiar foto',
			'flightVideo.avatarNameLabel' => 'Nombre o @usuario',
			'flightVideo.avatarNameHint' => 'Opcional: se muestra en la tarjeta de resumen',
			'flightVideo.avatarSave' => 'Guardar avatar',
			'flightVideo.mysteryTitle' => '¿Adivinas adónde vuelo? ✈️',
			'flightVideo.avatarCardTagline' => 'Mi mapa de vuelo',
			'about.title' => 'Acerca de Flymap',
			'about.tagline' => 'Convierte cada vuelo en una ventana al mundo.',
			'about.chipCuriosity' => 'Curiosidad',
			'about.chipGeography' => 'Geografía',
			'about.chipAwareness' => 'Conciencia',
			'about.missionTitle' => 'Por qué Flymap',
			'about.missionText' => 'Sobrevolamos océanos, montañas y países enteros sin llegar a saberlo. Flymap devuelve el asombro.',
			'about.valuesTitle' => 'Lo que defendemos',
			'about.valueCuriosityTitle' => 'Curiosidad',
			'about.valueCuriosityText' => 'Sé siempre consciente de lo que sobrevuelas.',
			'about.valueGeographyTitle' => 'Geografía',
			'about.valueGeographyText' => 'El mundo se vuelve un atlas vivo.',
			'about.valueAwarenessTitle' => 'Conciencia',
			'about.valueAwarenessText' => 'Reconecta con el viaje en sí.',
			'about.valueOfflineTitle' => 'Offline y privado',
			'about.valueOfflineText' => 'En tu dispositivo. Sin rastreo.',
			'about.closingTitle' => 'Mira el mundo de otra manera',
			'about.closingText' => 'Gracias por explorarlo con nosotros.',
			'onboarding.skip' => 'Omitir',
			'onboarding.letsStart' => 'Empecemos',
			'onboarding.welcomeTitle' => 'Descubre lo que hay debajo',
			'onboarding.welcomeSubtitle' => 'te muestra mapas offline y lugares interesantes a lo largo de tu vuelo',
			'onboarding.nameTitle' => 'Elige un nombre de usuario',
			'onboarding.nameSubtitle' => 'Haz que el descubrimiento sea personal. Puedes cambiarlo en cualquier momento.',
			'onboarding.nameHint' => 'Tu nombre',
			'onboarding.nameExample' => 'Alex',
			'onboarding.frequencyTitle' => '¿Con qué frecuencia vuelas?',
			'onboarding.frequencySubtitle' => 'Flymap personalizará tu experiencia y hará las sugerencias más relevantes',
			'onboarding.frequencyFirstFlight' => 'Este es mi primer vuelo',
			'onboarding.frequencyFewPerYear' => 'Unas pocas veces al año',
			'onboarding.frequencyMonthly' => 'Más o menos cada mes',
			'onboarding.frequencyFrequent' => 'Muy a menudo',
			'onboarding.homeAirportTitle' => 'Configura tu aeropuerto base',
			'onboarding.homeAirportSubtitle' => 'Acelera la creación de vuelos. Puedes cambiarlo en cualquier momento.',
			'onboarding.homeAirportHint' => 'Buscar aeropuerto base',
			'onboarding.popularAirports' => 'Aeropuertos populares',
			'onboarding.removeHomeAirport' => 'Eliminar aeropuerto base',
			'onboarding.noHomeAirportFound' => 'No se encontraron aeropuertos para esa búsqueda.',
			'onboarding.interestsTitle' => '¿Qué lugares quieres ver más en tu mapa?',
			'onboarding.interestsSubtitle' => 'Elige hasta 3 temas para ver lugares e historias más relevantes a lo largo de tu vuelo.',
			'onboarding.interestsHelper' => 'Elige hasta 3 temas.',
			'onboarding.interestsSelected' => ({required Object count, required Object max}) => '${count} de ${max} seleccionados',
			'onboarding.interestMountains' => 'Montañas y cordilleras',
			'onboarding.interestVolcanoes' => 'Volcanes y geología',
			'onboarding.interestRegions' => 'Ciudades y regiones',
			'onboarding.interestIslands' => 'Islas y costas',
			'onboarding.interestNationalParks' => 'Parques nacionales y reservas',
			'onboarding.interestRivers' => 'Ríos y lagos',
			'onboarding.planFirstFlight' => 'Empezar mi primer vuelo',
			'onboarding.failedLoadProfile' => 'No se pudo cargar tu perfil.',
			'onboarding.payoff.title' => ({required Object airport}) => 'Lugares alrededor de ${airport} que no deberías perderte',
			'onboarding.payoff.subtitle' => 'Llevas años sobrevolando todo esto — búscalos en tu próximo vuelo:',
			'onboarding.payoff.scanning' => ({required Object airport}) => 'Explorando el cielo alrededor de ${airport}…',
			'onboarding.payoff.moreNearby' => ({required Object count}) => '…y ${count}+ lugares más por descubrir cerca:',
			'onboarding.payoff.fallbackTitle' => 'Deja de perderte lo que hay debajo',
			'onboarding.payoff.fallbackSubtitle' => 'Cada vuelo sobrevuela volcanes, montañas, islas y lagos que la mayoría de los viajeros nunca nota. Flymap te muestra lo que hay tras tu ventanilla.',
			'countries.AE' => 'Emiratos Arabes Unidos',
			'countries.AF' => 'Afganistan',
			'countries.AG' => 'Antigua y Barbuda',
			'countries.AL' => 'Albania',
			'countries.AM' => 'Armenia',
			'countries.AO' => 'Angola',
			'countries.AR' => 'Argentina',
			'countries.AT' => 'Austria',
			'countries.AU' => 'Australia',
			'countries.AZ' => 'Azerbaiyan',
			'countries.BA' => 'Bosnia y Herzegovina',
			'countries.BB' => 'Barbados',
			'countries.BD' => 'Banglades',
			'countries.BE' => 'Belgica',
			'countries.BF' => 'Burkina Faso',
			'countries.BG' => 'Bulgaria',
			'countries.BH' => 'Barein',
			'countries.BI' => 'Burundi',
			'countries.BJ' => 'Benin',
			'countries.BN' => 'Brunei',
			'countries.BO' => 'Bolivia',
			'countries.BR' => 'Brasil',
			'countries.BS' => 'Bahamas',
			'countries.BT' => 'Butan',
			'countries.BW' => 'Botsuana',
			'countries.BY' => 'Bielorrusia',
			'countries.BZ' => 'Belice',
			'countries.CA' => 'Canada',
			'countries.CD' => 'Republica Democratica del Congo',
			'countries.CF' => 'Republica Centroafricana',
			'countries.CG' => 'Congo',
			'countries.CH' => 'Suiza',
			'countries.CI' => 'Costa de Marfil',
			'countries.CL' => 'Chile',
			'countries.CM' => 'Camerun',
			'countries.CN' => 'China',
			'countries.CO' => 'Colombia',
			'countries.CR' => 'Costa Rica',
			'countries.CU' => 'Cuba',
			'countries.CV' => 'Cabo Verde',
			'countries.CY' => 'Chipre',
			'countries.CZ' => 'Republica Checa',
			'countries.DE' => 'Alemania',
			'countries.DJ' => 'Yibuti',
			'countries.DK' => 'Dinamarca',
			'countries.DO' => 'Republica Dominicana',
			'countries.DZ' => 'Argelia',
			'countries.EC' => 'Ecuador',
			'countries.EE' => 'Estonia',
			'countries.EG' => 'Egipto',
			'countries.EH' => 'Sahara Occidental',
			'countries.ER' => 'Eritrea',
			'countries.ES' => 'Espana',
			'countries.ET' => 'Etiopia',
			'countries.FI' => 'Finlandia',
			'countries.FJ' => 'Fiyi',
			'countries.FR' => 'Francia',
			'countries.GA' => 'Gabon',
			'countries.GB' => 'Reino Unido',
			'countries.GE' => 'Georgia',
			'countries.GF' => 'Guayana Francesa',
			'countries.GH' => 'Ghana',
			'countries.GM' => 'Gambia',
			'countries.GN' => 'Guinea',
			'countries.GP' => 'Guadalupe',
			'countries.GQ' => 'Guinea Ecuatorial',
			'countries.GR' => 'Grecia',
			'countries.GT' => 'Guatemala',
			'countries.GW' => 'Guinea-Bisau',
			'countries.GY' => 'Guyana',
			'countries.HK' => 'Hong Kong, China',
			'countries.HN' => 'Honduras',
			'countries.HR' => 'Croacia',
			'countries.HT' => 'Haiti',
			'countries.HU' => 'Hungria',
			'countries.ID' => 'Indonesia',
			'countries.IE' => 'Irlanda',
			'countries.IL' => 'Israel',
			'countries.IN' => 'India',
			'countries.IQ' => 'Irak',
			'countries.IR' => 'Iran',
			'countries.IS' => 'Islandia',
			'countries.IT' => 'Italia',
			'countries.JM' => 'Jamaica',
			'countries.JO' => 'Jordania',
			'countries.JP' => 'Japon',
			'countries.KE' => 'Kenia',
			'countries.KG' => 'Kirguistan',
			'countries.KH' => 'Camboya',
			'countries.KM' => 'Comoras',
			'countries.KP' => 'Corea del Norte',
			'countries.KR' => 'Corea del Sur',
			'countries.KW' => 'Kuwait',
			'countries.KZ' => 'Kazajistan',
			'countries.LA' => 'Laos',
			'countries.LB' => 'Libano',
			'countries.LK' => 'Sri Lanka',
			'countries.LR' => 'Liberia',
			'countries.LS' => 'Lesoto',
			'countries.LT' => 'Lituania',
			'countries.LU' => 'Luxemburgo',
			'countries.LV' => 'Letonia',
			'countries.LY' => 'Libia',
			'countries.MA' => 'Marruecos',
			'countries.MD' => 'Moldavia',
			'countries.ME' => 'Montenegro',
			'countries.MG' => 'Madagascar',
			'countries.MK' => 'Macedonia del Norte',
			'countries.ML' => 'Mali',
			'countries.MM' => 'Myanmar',
			'countries.MN' => 'Mongolia',
			'countries.MO' => 'Macao, China',
			'countries.MQ' => 'Martinica',
			'countries.MR' => 'Mauritania',
			'countries.MU' => 'Mauricio',
			'countries.MV' => 'Maldivas',
			'countries.MW' => 'Malaui',
			'countries.MT' => 'Malta',
			'countries.MX' => 'Mexico',
			'countries.MY' => 'Malasia',
			'countries.MZ' => 'Mozambique',
			'countries.NA' => 'Namibia',
			'countries.NC' => 'Nueva Caledonia',
			_ => null,
		} ?? switch (path) {
			'countries.NE' => 'Niger',
			'countries.NG' => 'Nigeria',
			'countries.NI' => 'Nicaragua',
			'countries.NL' => 'Paises Bajos',
			'countries.NO' => 'Noruega',
			'countries.NP' => 'Nepal',
			'countries.NZ' => 'Nueva Zelanda',
			'countries.OM' => 'Oman',
			'countries.PA' => 'Panama',
			'countries.PE' => 'Peru',
			'countries.PG' => 'Papua Nueva Guinea',
			'countries.PH' => 'Filipinas',
			'countries.PK' => 'Pakistan',
			'countries.PL' => 'Polonia',
			'countries.PR' => 'Puerto Rico',
			'countries.PS' => 'Cisjordania y Franja de Gaza',
			'countries.PT' => 'Portugal',
			'countries.PY' => 'Paraguay',
			'countries.QA' => 'Catar',
			'countries.RE' => 'La Reunion',
			'countries.RO' => 'Rumania',
			'countries.RS' => 'Serbia',
			'countries.RU' => 'Rusia',
			'countries.RW' => 'Ruanda',
			'countries.SA' => 'Arabia Saudita',
			'countries.SB' => 'Islas Salomon',
			'countries.SD' => 'Sudan',
			'countries.SE' => 'Suecia',
			'countries.SG' => 'Singapur',
			'countries.SI' => 'Eslovenia',
			'countries.SK' => 'Eslovaquia',
			'countries.SL' => 'Sierra Leona',
			'countries.SN' => 'Senegal',
			'countries.SO' => 'Somalia',
			'countries.SR' => 'Surinam',
			'countries.SS' => 'Sudan del Sur',
			'countries.ST' => 'Santo Tome y Principe',
			'countries.SV' => 'El Salvador',
			'countries.SY' => 'Siria',
			'countries.SZ' => 'Esuatini',
			'countries.TD' => 'Chad',
			'countries.TG' => 'Togo',
			'countries.TH' => 'Tailandia',
			'countries.TJ' => 'Tayikistan',
			'countries.TL' => 'Timor Oriental',
			'countries.TM' => 'Turkmenistan',
			'countries.TN' => 'Tunez',
			'countries.TR' => 'Turquia',
			'countries.TT' => 'Trinidad y Tobago',
			'countries.TW' => 'Taiwan, China',
			'countries.TZ' => 'Tanzania',
			'countries.UA' => 'Ucrania',
			'countries.UG' => 'Uganda',
			'countries.US' => 'Estados Unidos',
			'countries.UY' => 'Uruguay',
			'countries.UZ' => 'Uzbekistan',
			'countries.VE' => 'Venezuela',
			'countries.VI' => 'Islas Virgenes de EE. UU.',
			'countries.VN' => 'Vietnam',
			'countries.YE' => 'Yemen',
			'countries.ZA' => 'Sudafrica',
			'countries.ZM' => 'Zambia',
			'countries.ZW' => 'Zimbabue',
			_ => null,
		};
	}
}
