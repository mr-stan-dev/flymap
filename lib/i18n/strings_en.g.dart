///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations

	/// en: 'Flymap'
	String get appName => 'Flymap';

	late final TranslationsCommonEn common = TranslationsCommonEn.internal(_root);
	late final TranslationsHomeEn home = TranslationsHomeEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsSubscriptionEn subscription = TranslationsSubscriptionEn.internal(_root);
	late final TranslationsCreateFlightEn createFlight = TranslationsCreateFlightEn.internal(_root);
	late final TranslationsPreviewEn preview = TranslationsPreviewEn.internal(_root);
	late final TranslationsFlightEn flight = TranslationsFlightEn.internal(_root);
	late final TranslationsShareFlightEn shareFlight = TranslationsShareFlightEn.internal(_root);
	late final TranslationsAboutEn about = TranslationsAboutEn.internal(_root);
	late final TranslationsOnboardingEn onboarding = TranslationsOnboardingEn.internal(_root);
}

// Path: common
class TranslationsCommonEn {
	TranslationsCommonEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Continue'
	String get kContinue => 'Continue';

	/// en: 'Back'
	String get back => 'Back';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'OK'
	String get ok => 'OK';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Upgrade'
	String get upgrade => 'Upgrade';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Read more'
	String get readMore => 'Read more';
}

// Path: home
class TranslationsHomeEn {
	TranslationsHomeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Home'
	String get title => 'Home';

	/// en: 'About'
	String get aboutTooltip => 'About';

	/// en: 'Settings'
	String get settingsTooltip => 'Settings';

	/// en: 'Flights'
	String get tabFlights => 'Flights';

	/// en: 'Learn'
	String get tabLibrary => 'Learn';

	/// en: 'Loading flights...'
	String get loadingFlights => 'Loading flights...';

	/// en: 'Failed to load flights'
	String get failedToLoadFlights => 'Failed to load flights';

	/// en: 'New flight'
	String get newFlight => 'New flight';

	/// en: 'Add first flight'
	String get addFirstFlight => 'Add first flight';

	/// en: 'Welcome to Flymap'
	String get welcomeTitle => 'Welcome to Flymap';

	/// en: 'Welcome to Flymap Pro'
	String get welcomeTitlePro => 'Welcome to Flymap Pro';

	/// en: 'Offline maps for flights'
	String get welcomeSubtitle => 'Offline maps for flights';

	/// en: 'Flights saved'
	String get flightsSaved => 'Flights saved';

	/// en: 'Storage used'
	String get storageUsed => 'Storage used';

	/// en: 'Flights ($count)'
	String flightsCount({required Object count}) => 'Flights (${count})';

	/// en: 'Ready to explore the world from above?'
	String get noFlightsTitle => 'Ready to explore the world from above?';

	/// en: 'Add your first flight and start discovering your next journey.'
	String get noFlightsSubtitle => 'Add your first flight and start discovering your next journey.';

	/// en: 'Saved offline'
	String get statusSavedOffline => 'Saved offline';

	/// en: 'Needs map'
	String get statusNeedsMap => 'Needs map';

	/// en: 'Flight actions'
	String get flightActions => 'Flight actions';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Share route'
	String get shareRoute => 'Share route';

	/// en: 'Delete flight'
	String get deleteFlight => 'Delete flight';

	/// en: 'Failed to delete flight'
	String get failedDeleteFlight => 'Failed to delete flight';

	/// en: 'No offline map'
	String get noOfflineMap => 'No offline map';

	/// en: 'Just now'
	String get justNow => 'Just now';

	/// en: '$days d ago'
	String daysAgo({required Object days}) => '${days} d ago';

	/// en: '$hours h ago'
	String hoursAgo({required Object hours}) => '${hours} h ago';

	/// en: '$minutes m ago'
	String minutesAgo({required Object minutes}) => '${minutes} m ago';

	late final TranslationsHomeSortEn sort = TranslationsHomeSortEn.internal(_root);
}

// Path: settings
class TranslationsSettingsEn {
	TranslationsSettingsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Loading settings...'
	String get loading => 'Loading settings...';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'Units'
	String get units => 'Units';

	/// en: 'Altitude'
	String get altitude => 'Altitude';

	/// en: 'Altitude unit'
	String get altitudeUnit => 'Altitude unit';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Speed unit'
	String get speedUnit => 'Speed unit';

	/// en: 'Time format'
	String get timeFormat => 'Time format';

	/// en: 'About'
	String get about => 'About';

	/// en: 'Learn more about the app'
	String get aboutSubtitle => 'Learn more about the app';

	/// en: 'Privacy Policy'
	String get privacyPolicy => 'Privacy Policy';

	/// en: 'Read our privacy policy'
	String get privacyPolicySubtitle => 'Read our privacy policy';

	/// en: 'Terms of Service'
	String get termsOfService => 'Terms of Service';

	/// en: 'Read our terms of service'
	String get termsOfServiceSubtitle => 'Read our terms of service';

	/// en: 'Flymap Pro activated.'
	String get flymapProActivated => 'Flymap Pro activated.';

	/// en: 'Upgrade cancelled.'
	String get upgradeCancelled => 'Upgrade cancelled.';

	/// en: 'No paywall available right now.'
	String get noPaywall => 'No paywall available right now.';

	/// en: 'Failed to open paywall.'
	String get failedOpenPaywall => 'Failed to open paywall.';

	/// en: 'Could not open $url'
	String couldNotOpenUrl({required Object url}) => 'Could not open ${url}';

	/// en: 'Rate us'
	String get rateUs => 'Rate us';

	/// en: 'Leave a review on the store'
	String get rateUsSubtitle => 'Leave a review on the store';

	/// en: 'Leave a Feedback'
	String get leaveFeedback => 'Leave a Feedback';

	/// en: 'Share your thoughts to help us improve'
	String get leaveFeedbackSubtitle => 'Share your thoughts to help us improve';

	/// en: 'Could not open store page'
	String get couldNotOpenStorePage => 'Could not open store page';

	/// en: 'Do you like the app?'
	String get rateDialogTitle => 'Do you like the app?';

	/// en: 'We work hard to make every flight more enjoyable, and your feedback really helps us improve.'
	String get rateDialogBody => 'We work hard to make every flight more enjoyable, and your feedback really helps us improve.';

	/// en: 'Yes'
	String get rateDialogYes => 'Yes';

	/// en: 'No'
	String get rateDialogNo => 'No';

	/// en: 'Leave a Feedback'
	String get feedbackTitle => 'Leave a Feedback';

	/// en: 'Help us to make Flymap better'
	String get feedbackBody => 'Help us to make Flymap better';

	/// en: 'Feedback type'
	String get feedbackCategoryTitle => 'Feedback type';

	/// en: 'General'
	String get feedbackCategoryGeneral => 'General';

	/// en: 'Feature request'
	String get feedbackCategoryFeatureRequest => 'Feature request';

	/// en: 'Bug report'
	String get feedbackCategoryBugReport => 'Bug report';

	/// en: 'Share your feedback...'
	String get feedbackHint => 'Share your feedback...';

	/// en: 'Email (optional)'
	String get feedbackEmailHint => 'Email (optional)';

	/// en: 'Please enter a valid email or leave it empty.'
	String get feedbackEmailInvalid => 'Please enter a valid email or leave it empty.';

	/// en: 'Send'
	String get feedbackSend => 'Send';

	/// en: 'Thanks for sharing your feedback!'
	String get feedbackThanks => 'Thanks for sharing your feedback!';

	/// en: 'Couldn't send feedback. Please try again.'
	String get feedbackSendFailed => 'Couldn\'t send feedback. Please try again.';

	/// en: 'Flymap Pro'
	String get proBannerTitle => 'Flymap Pro';

	/// en: 'Flymap Pro Active'
	String get proBannerTitleActive => 'Flymap Pro Active';

	/// en: 'Detailed map mode and full offline article bundles unlocked.'
	String get proBannerSubtitleActive => 'Detailed map mode and full offline article bundles unlocked.';

	/// en: 'Unlock detailed maps and full offline article bundles'
	String get proBannerSubtitleFree => 'Unlock detailed maps and full offline article bundles';

	/// en: 'PRO ACTIVE'
	String get proBannerBadgeActive => 'PRO ACTIVE';
}

// Path: subscription
class TranslationsSubscriptionEn {
	TranslationsSubscriptionEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Subscription'
	String get screenTitle => 'Subscription';

	/// en: 'Pull down to refresh your subscription status.'
	String get pullToRefresh => 'Pull down to refresh your subscription status.';

	/// en: 'Need help?'
	String get needHelp => 'Need help?';

	/// en: 'Contact support'
	String get contactSupport => 'Contact support';

	/// en: 'Flymap Pro'
	String get cardTitle => 'Flymap Pro';

	/// en: 'Checking your subscription status...'
	String get checkingStatus => 'Checking your subscription status...';

	/// en: 'Flymap Pro is active.'
	String get proActive => 'Flymap Pro is active.';

	/// en: 'You are on Free plan.'
	String get freePlan => 'You are on Free plan.';

	/// en: 'Status'
	String get status => 'Status';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Not active'
	String get notActive => 'Not active';

	/// en: 'Entitlement'
	String get entitlement => 'Entitlement';

	/// en: 'Expires'
	String get expires => 'Expires';

	/// en: 'No expiration'
	String get noExpiration => 'No expiration';

	/// en: 'Last update'
	String get lastUpdate => 'Last update';

	/// en: 'Unknown'
	String get unknown => 'Unknown';

	/// en: 'Manage subscription'
	String get manageSubscription => 'Manage subscription';

	/// en: 'Upgrade to Pro'
	String get upgradeToPro => 'Upgrade to Pro';

	/// en: 'You can cancel or change billing in your App Store or Google Play subscription settings.'
	String get proManageHint => 'You can cancel or change billing in your App Store or Google Play subscription settings.';

	/// en: 'Free users can upgrade to Pro to unlock premium features.'
	String get freeUpgradeHint => 'Free users can upgrade to Pro to unlock premium features.';

	/// en: 'Flymap subscription support'
	String get supportEmailSubject => 'Flymap subscription support';

	/// en: 'Could not open email app'
	String get couldNotOpenEmailApp => 'Could not open email app';

	/// en: 'Could not open subscription settings'
	String get couldNotOpenSubscriptionSettings => 'Could not open subscription settings';

	/// en: 'Flymap Pro restored.'
	String get proRestored => 'Flymap Pro restored.';

	/// en: 'Failed to open paywall.'
	String get failedOpenPaywall => 'Failed to open paywall.';

	/// en: 'Subscription service is temporarily unavailable.'
	String get serviceUnavailable => 'Subscription service is temporarily unavailable.';
}

// Path: createFlight
class TranslationsCreateFlightEn {
	TranslationsCreateFlightEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final TranslationsCreateFlightStepsEn steps = TranslationsCreateFlightStepsEn.internal(_root);
	late final TranslationsCreateFlightSearchEn search = TranslationsCreateFlightSearchEn.internal(_root);
	late final TranslationsCreateFlightMapPreviewEn mapPreview = TranslationsCreateFlightMapPreviewEn.internal(_root);
	late final TranslationsCreateFlightOverviewEn overview = TranslationsCreateFlightOverviewEn.internal(_root);
	late final TranslationsCreateFlightWikipediaEn wikipedia = TranslationsCreateFlightWikipediaEn.internal(_root);
	late final TranslationsCreateFlightDownloadingEn downloading = TranslationsCreateFlightDownloadingEn.internal(_root);
	late final TranslationsCreateFlightErrorsEn errors = TranslationsCreateFlightErrorsEn.internal(_root);
	late final TranslationsCreateFlightPaywallEn paywall = TranslationsCreateFlightPaywallEn.internal(_root);
}

// Path: preview
class TranslationsPreviewEn {
	TranslationsPreviewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Calculating flight route...'
	String get calculatingRoute => 'Calculating flight route...';

	/// en: 'Error'
	String get errorTitle => 'Error';

	/// en: 'Something went wrong'
	String get errorSomethingWrong => 'Something went wrong';

	/// en: 'Try Again'
	String get tryAgain => 'Try Again';

	/// en: 'Download Complete!'
	String get downloadComplete => 'Download Complete!';

	/// en: 'Flight has been saved'
	String get flightSaved => 'Flight has been saved';

	/// en: 'Navigating to home...'
	String get navigatingHome => 'Navigating to home...';

	/// en: 'Downloading Flight Map'
	String get downloadingMapTitle => 'Downloading Flight Map';

	/// en: 'Cancel download'
	String get cancelDownload => 'Cancel download';

	/// en: 'Download'
	String get download => 'Download';

	/// en: 'Flight route (~ $distance)'
	String flightRoute({required Object distance}) => 'Flight route (~ ${distance})';
}

// Path: flight
class TranslationsFlightEn {
	TranslationsFlightEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Map'
	String get tabMap => 'Map';

	/// en: 'Dashboard'
	String get tabDashboard => 'Dashboard';

	/// en: 'Info'
	String get tabInfo => 'Info';

	/// en: 'Are you sure?'
	String get deleteDialogTitle => 'Are you sure?';

	/// en: 'This will permanently delete this flight. Space to be regained: $size.'
	String deleteDialogMessage({required Object size}) => 'This will permanently delete this flight.\n\nSpace to be regained: ${size}.';

	/// en: 'Yes'
	String get yes => 'Yes';

	/// en: 'Share route'
	String get shareRoute => 'Share route';

	/// en: 'Copy route'
	String get copyRoute => 'Copy route';

	/// en: 'Delete flight'
	String get deleteFlight => 'Delete flight';

	/// en: 'Route summary copied'
	String get routeSummaryCopied => 'Route summary copied';

	/// en: 'Flight deleted'
	String get deleted => 'Flight deleted';

	/// en: 'Error deleting flight: $error'
	String deleteError({required Object error}) => 'Error deleting flight: ${error}';

	late final TranslationsFlightMapEn map = TranslationsFlightMapEn.internal(_root);
	late final TranslationsFlightDashboardEn dashboard = TranslationsFlightDashboardEn.internal(_root);
	late final TranslationsFlightInfoEn info = TranslationsFlightInfoEn.internal(_root);
}

// Path: shareFlight
class TranslationsShareFlightEn {
	TranslationsShareFlightEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Share flight'
	String get title => 'Share flight';

	/// en: 'Preparing share preview map...'
	String get preparingMap => 'Preparing share preview map...';

	/// en: 'Preparing screenshot...'
	String get preparingScreenshot => 'Preparing screenshot...';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Offline map missing. Using online style.'
	String get offlineMapMissing => 'Offline map missing. Using online style.';

	/// en: 'Failed to load offline style. Using online style.'
	String get offlineStyleFailed => 'Failed to load offline style. Using online style.';

	/// en: 'Could not capture route screenshot'
	String get captureFailed => 'Could not capture route screenshot';

	/// en: 'Failed to share route screenshot'
	String get shareFailed => 'Failed to share route screenshot';

	/// en: 'Flight route $from-$to'
	String shareText({required Object from, required Object to}) => 'Flight route ${from}-${to}';

	/// en: 'Flymap'
	String get watermark => 'Flymap';

	/// en: 'Flight distance'
	String get flightDistance => 'Flight distance';

	/// en: '$distance km'
	String distanceKm({required Object distance}) => '${distance} km';
}

// Path: about
class TranslationsAboutEn {
	TranslationsAboutEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About Flymap'
	String get title => 'About Flymap';

	/// en: 'Welcome to Flymap'
	String get welcome => 'Welcome to Flymap';

	/// en: 'Flymap keeps your route visible in the air. Plan the trip, download your map on the ground, and track your flight offline with confidence.'
	String get intro => 'Flymap keeps your route visible in the air. Plan the trip, download your map on the ground, and track your flight offline with confidence.';

	/// en: 'Offline map'
	String get chipOffline => 'Offline map';

	/// en: 'Live dashboard'
	String get chipDashboard => 'Live dashboard';

	/// en: 'Route sharing'
	String get chipSharing => 'Route sharing';

	/// en: 'Before takeoff, download your route map. In flight mode, internet access may be limited or unavailable.'
	String get infoBanner => 'Before takeoff, download your route map. In flight mode, internet access may be limited or unavailable.';

	/// en: 'What You Can Do'
	String get whatYouCanDo => 'What You Can Do';

	/// en: 'Plan your route'
	String get featurePlanTitle => 'Plan your route';

	/// en: 'Choose departure and arrival airports, then preview the path before downloading.'
	String get featurePlanText => 'Choose departure and arrival airports, then preview the path before downloading.';

	/// en: 'Track flight data'
	String get featureTrackTitle => 'Track flight data';

	/// en: 'Use Dashboard to monitor heading, speed, altitude, and route progress.'
	String get featureTrackText => 'Use Dashboard to monitor heading, speed, altitude, and route progress.';

	/// en: 'Check route details'
	String get featureDetailsTitle => 'Check route details';

	/// en: 'Open the Info tab for airport details and a clean route overview.'
	String get featureDetailsText => 'Open the Info tab for airport details and a clean route overview.';

	/// en: 'Share your journey'
	String get featureShareTitle => 'Share your journey';

	/// en: 'Generate and share a flight map screenshot with route highlights.'
	String get featureShareText => 'Generate and share a flight map screenshot with route highlights.';

	/// en: 'Quick Start'
	String get quickStart => 'Quick Start';

	/// en: 'Tap New flight on Home.'
	String get step1 => 'Tap New flight on Home.';

	/// en: 'Choose departure and arrival airports.'
	String get step2 => 'Choose departure and arrival airports.';

	/// en: 'Open Map preview and download the map before the flight.'
	String get step3 => 'Open Map preview and download the map before the flight.';

	/// en: 'Open your flight and use Map, Dashboard, and Info in the air.'
	String get step4 => 'Open your flight and use Map, Dashboard, and Info in the air.';

	/// en: 'Tips For Better GPS'
	String get tips => 'Tips For Better GPS';

	/// en: 'For stronger GPS signal, sit closer to a window.'
	String get tip1 => 'For stronger GPS signal, sit closer to a window.';

	/// en: 'Signal can drop in the middle of the aircraft. Flymap keeps the last known route view while searching.'
	String get tip2 => 'Signal can drop in the middle of the aircraft. Flymap keeps the last known route view while searching.';
}

// Path: onboarding
class TranslationsOnboardingEn {
	TranslationsOnboardingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Start exploring'
	String get startExploring => 'Start exploring';

	/// en: 'Explore the world from above'
	String get page1Title => 'Explore the world from above';

	/// en: 'From coastlines to mountain ranges, every route feels like a new adventure.'
	String get page1Subtitle => 'From coastlines to mountain ranges, every route feels like a new adventure.';

	/// en: 'Turn every flight into a story'
	String get page2Title => 'Turn every flight into a story';

	/// en: 'Follow your path in real time and enjoy the journey, not just the destination.'
	String get page2Subtitle => 'Follow your path in real time and enjoy the journey, not just the destination.';

	/// en: 'Download maps before takeoff'
	String get page3Title => 'Download maps before takeoff';

	/// en: 'To enjoy your offline in-flight experience, download your map before switching to flight mode.'
	String get page3Subtitle => 'To enjoy your offline in-flight experience, download your map before switching to flight mode.';

	/// en: 'Privacy by design'
	String get page4Title => 'Privacy by design';

	/// en: 'Your location stays on your device. We don’t collect or share it.'
	String get page4Subtitle => 'Your location stays on your device. We don’t collect or share it.';
}

// Path: home.sort
class TranslationsHomeSortEn {
	TranslationsHomeSortEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Most recent'
	String get mostRecent => 'Most recent';

	/// en: 'Longest'
	String get longest => 'Longest';

	/// en: 'A-Z'
	String get alphabetical => 'A-Z';
}

// Path: createFlight.steps
class TranslationsCreateFlightStepsEn {
	TranslationsCreateFlightStepsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Choose departure airport'
	String get departureTitle => 'Choose departure airport';

	/// en: 'Choose arrival airport'
	String get arrivalTitle => 'Choose arrival airport';

	/// en: 'Route not supported'
	String get routeNotSupportedTitle => 'Route not supported';

	/// en: 'Map preview'
	String get mapPreviewTitle => 'Map preview';

	/// en: 'Route overview'
	String get overviewTitle => 'Route overview';

	/// en: 'Wikipedia articles'
	String get wikipediaTitle => 'Wikipedia articles';
}

// Path: createFlight.search
class TranslationsCreateFlightSearchEn {
	TranslationsCreateFlightSearchEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Search departure airport'
	String get departureHint => 'Search departure airport';

	/// en: 'Search arrival airport'
	String get arrivalHint => 'Search arrival airport';

	/// en: 'Remove favorite'
	String get removeFavorite => 'Remove favorite';

	/// en: 'Add to favorite'
	String get addFavorite => 'Add to favorite';

	/// en: 'Remove selected airport'
	String get removeSelectedAirport => 'Remove selected airport';

	/// en: 'Favorites'
	String get favorites => 'Favorites';

	/// en: 'Popular airports'
	String get popularAirports => 'Popular airports';

	/// en: 'Remove from favorites'
	String get removeFromFavorites => 'Remove from favorites';

	/// en: 'No departure airports found.'
	String get noDepartureFound => 'No departure airports found.';

	/// en: 'No arrival airports found.'
	String get noArrivalFound => 'No arrival airports found.';

	/// en: '$code · $city'
	String airportCodeCity({required Object code, required Object city}) => '${code} · ${city}';

	/// en: '$name ($code)'
	String airportNameCode({required Object name, required Object code}) => '${name} (${code})';
}

// Path: createFlight.mapPreview
class TranslationsCreateFlightMapPreviewEn {
	TranslationsCreateFlightMapPreviewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sorry, antimeridian flights are not supported yet.'
	String get routeNotSupportedMsg => 'Sorry, antimeridian flights are not supported yet.';

	/// en: 'Basic'
	String get basic => 'Basic';

	/// en: 'Pro'
	String get pro => 'Pro';

	/// en: 'Map detail info'
	String get mapDetailInfoTooltip => 'Map detail info';

	/// en: 'Legend'
	String get legendButton => 'Legend';

	/// en: 'POI legend'
	String get legendTitle => 'POI legend';

	/// en: 'Estimated map size: $size'
	String estimatedMapSize({required Object size}) => 'Estimated map size: ${size}';

	/// en: 'Upgrade to Pro'
	String get upgradeToPro => 'Upgrade to Pro';

	/// en: 'Map options'
	String get optionsTitle => 'Map options';

	/// en: 'Basic: lower zoom, faster download, less storage Pro: higher zoom, more detail, larger download Route is approximate — actual path may vary (especially long-haul)'
	String get optionsBody => 'Basic: lower zoom, faster download, less storage\n\nPro: higher zoom, more detail, larger download\n\nRoute is approximate — actual path may vary (especially long-haul)';
}

// Path: createFlight.overview
class TranslationsCreateFlightOverviewEn {
	TranslationsCreateFlightOverviewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Route is not ready yet.'
	String get routeNotReady => 'Route is not ready yet.';

	/// en: 'With Flymap Pro, discover more interesting places along your route.'
	String get proPoiUpsell => 'With Flymap Pro, discover more interesting places along your route.';
}

// Path: createFlight.wikipedia
class TranslationsCreateFlightWikipediaEn {
	TranslationsCreateFlightWikipediaEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Download articles to read during the flight'
	String get title => 'Download articles to read during the flight';

	/// en: 'Finding route-related articles...'
	String get loadingIntro => 'Finding route-related articles...';

	/// en: 'Based on your route we found $count articles which may be interesting for you. Select to download them for offline reading'
	String foundIntro({required Object count}) => 'Based on your route we found ${count} articles which may be interesting for you. Select to download them for offline reading';

	/// en: 'No route-related Wikipedia articles found. You can continue with map download only.'
	String get emptyIntro => 'No route-related Wikipedia articles found. You can continue with map download only.';

	/// en: '$count selected'
	String selectedCount({required Object count}) => '${count} selected';

	/// en: 'Unselect all'
	String get unselectAll => 'Unselect all';

	/// en: 'Select all'
	String get selectAll => 'Select all';

	/// en: 'Pro active'
	String get proActiveTitle => 'Pro active';

	/// en: 'Full articles pack unlocked.'
	String get proActiveMessage => 'Full articles pack unlocked.';

	/// en: 'Free plan includes up to 3 offline articles. Upgrade to Pro for unlimited articles.'
	String get freeLimitHint => 'Free plan includes up to 3 offline articles. Upgrade to Pro for unlimited articles.';

	/// en: 'Estimated download size: $size'
	String estimatedDownloadSize({required Object size}) => 'Estimated download size: ${size}';

	/// en: 'Upgrade'
	String get upgrade => 'Upgrade';

	/// en: 'Loading article suggestions...'
	String get loadingSuggestions => 'Loading article suggestions...';

	/// en: 'Download map'
	String get downloadMapOnly => 'Download map';

	/// en: 'Download map + 1 article'
	String get downloadMapPlusOne => 'Download map + 1 article';

	/// en: 'Download map + $count articles'
	String downloadMapPlusMany({required Object count}) => 'Download map + ${count} articles';

	/// en: 'Could not open link'
	String get couldNotOpenLink => 'Could not open link';
}

// Path: createFlight.downloading
class TranslationsCreateFlightDownloadingEn {
	TranslationsCreateFlightDownloadingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Downloading selected articles...'
	String get articlesTitle => 'Downloading selected articles...';

	/// en: 'Downloading offline map...'
	String get mapTitle => 'Downloading offline map...';

	/// en: 'Map'
	String get mapSectionTitle => 'Map';

	/// en: 'Places'
	String get poiSectionTitle => 'Places';

	/// en: 'Articles'
	String get articlesSectionTitle => 'Articles';

	/// en: 'Cancel download'
	String get cancelDownload => 'Cancel download';

	/// en: 'Do not close this screen until download completes'
	String get doNotClose => 'Do not close this screen until download completes';

	/// en: 'Current'
	String get currentStep => 'Current';

	/// en: 'Pending'
	String get pending => 'Pending';

	/// en: 'In progress'
	String get inProgress => 'In progress';

	/// en: 'Completed'
	String get completed => 'Completed';

	/// en: 'Completed with issues'
	String get completedWithIssues => 'Completed with issues';

	/// en: 'Failed'
	String get failed => 'Failed';

	/// en: 'Skipped'
	String get skipped => 'Skipped';

	/// en: 'Waiting for map download...'
	String get waitingForMap => 'Waiting for map download...';

	/// en: 'Map download failed.'
	String get mapFailed => 'Map download failed.';

	/// en: 'No place summaries selected.'
	String get noPoiSelected => 'No place summaries selected.';

	/// en: 'Preparing place summaries...'
	String get preparingPoi => 'Preparing place summaries...';

	/// en: 'Places: $completed/$total'
	String poiProgress({required Object completed, required Object total}) => 'Places: ${completed}/${total}';

	/// en: 'Places: $completed/$total ($failed failed)'
	String poiProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Places: ${completed}/${total} (${failed} failed)';

	/// en: 'No articles selected.'
	String get noArticlesSelected => 'No articles selected.';

	/// en: 'Preparing article downloads...'
	String get preparingArticles => 'Preparing article downloads...';

	/// en: 'Articles: $completed/$total'
	String articlesProgress({required Object completed, required Object total}) => 'Articles: ${completed}/${total}';

	/// en: 'Articles: $completed/$total ($failed failed)'
	String articlesProgressWithFailed({required Object completed, required Object total, required Object failed}) => 'Articles: ${completed}/${total} (${failed} failed)';

	/// en: 'Preparing map download...'
	String get preparingMap => 'Preparing map download...';

	/// en: 'Computing map tiles...'
	String get computingTiles => 'Computing map tiles...';

	/// en: 'Computing map tiles ($count)...'
	String computingTilesWithCount({required Object count}) => 'Computing map tiles (${count})...';

	/// en: 'Preparing for download...'
	String get preparingForDownload => 'Preparing for download...';

	/// en: 'Downloaded: $size'
	String downloaded({required Object size}) => 'Downloaded: ${size}';

	/// en: 'Finalizing map package...'
	String get finalizing => 'Finalizing map package...';

	/// en: 'Verifying map package...'
	String get verifying => 'Verifying map package...';
}

// Path: createFlight.errors
class TranslationsCreateFlightErrorsEn {
	TranslationsCreateFlightErrorsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Failed to load airports. Please try again.'
	String get failedLoadAirports => 'Failed to load airports. Please try again.';

	/// en: 'Airport search failed. Try another query.'
	String get airportSearchFailed => 'Airport search failed. Try another query.';

	/// en: 'Some articles failed. Continuing with map download.'
	String get someArticlesFailed => 'Some articles failed. Continuing with map download.';

	/// en: 'Map downloaded. Some optional content could not be downloaded.'
	String get someOptionalDownloadsFailed => 'Map downloaded. Some optional content could not be downloaded.';

	/// en: 'Failed to build route preview. Please try again.'
	String get failedBuildPreview => 'Failed to build route preview. Please try again.';

	/// en: 'Could not load route overview. You can still continue.'
	String get overviewUnavailableContinue => 'Could not load route overview. You can still continue.';

	/// en: 'No internet connection. Please check your connection and try again.'
	String get noInternet => 'No internet connection. Please check your connection and try again.';

	/// en: 'Failed to start download: $error'
	String failedStartDownload({required Object error}) => 'Failed to start download: ${error}';
}

// Path: createFlight.paywall
class TranslationsCreateFlightPaywallEn {
	TranslationsCreateFlightPaywallEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Upgrade cancelled.'
	String get upgradeCancelled => 'Upgrade cancelled.';

	/// en: 'No paywall available right now.'
	String get noPaywall => 'No paywall available right now.';

	/// en: 'Failed to open paywall.'
	String get failedOpenPaywall => 'Failed to open paywall.';
}

// Path: flight.map
class TranslationsFlightMapEn {
	TranslationsFlightMapEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Initializing map...'
	String get initializing => 'Initializing map...';

	/// en: 'Loading map style...'
	String get loadingStyle => 'Loading map style...';

	/// en: 'Offline map is not available for this flight.'
	String get offlineNotAvailable => 'Offline map is not available for this flight.';

	/// en: 'Offline map file is missing. Please re-download this route.'
	String get offlineMissing => 'Offline map file is missing. Please re-download this route.';

	/// en: 'Offline map validation failed. Please re-download this route.'
	String get validationFailed => 'Offline map validation failed. Please re-download this route.';

	/// en: 'Could not load offline map style.'
	String get loadStyleFailed => 'Could not load offline map style.';

	/// en: 'Switch to 2D'
	String get switchTo2D => 'Switch to 2D';

	/// en: 'Switch to 3D'
	String get switchTo3D => 'Switch to 3D';

	/// en: 'Uncenter map'
	String get uncenterMap => 'Uncenter map';

	/// en: 'Center on me'
	String get centerOnMe => 'Center on me';
}

// Path: flight.dashboard
class TranslationsFlightDashboardEn {
	TranslationsFlightDashboardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Location services are off'
	String get gpsOffTitle => 'Location services are off';

	/// en: 'Turn on location services in system settings to resume live flight tracking and map following.'
	String get gpsOffSubtitle => 'Turn on location services in system settings to resume live flight tracking and map following.';

	/// en: 'Open location settings'
	String get openLocationSettings => 'Open location settings';

	/// en: 'Location permission required'
	String get permissionTitle => 'Location permission required';

	/// en: 'Allow location access so the dashboard can show live heading, speed, and altitude.'
	String get permissionSubtitle => 'Allow location access so the dashboard can show live heading, speed, and altitude.';

	/// en: 'Grant permissions'
	String get grantPermissions => 'Grant permissions';

	/// en: 'GPS Accuracy: $label (±$accuracy m)'
	String gpsAccuracy({required Object label, required Object accuracy}) => 'GPS Accuracy: ${label} (±${accuracy} m)';

	/// en: 'Excellent'
	String get accuracyExcellent => 'Excellent';

	/// en: 'Good'
	String get accuracyGood => 'Good';

	/// en: 'Poor'
	String get accuracyPoor => 'Poor';

	/// en: 'GPS off'
	String get gpsOff => 'GPS off';

	/// en: 'Enable location services to start tracking.'
	String get gpsOffHint => 'Enable location services to start tracking.';

	/// en: 'Location permission required'
	String get gpsPermissionRequired => 'Location permission required';

	/// en: 'Grant permission to access live flight telemetry.'
	String get gpsPermissionHint => 'Grant permission to access live flight telemetry.';

	/// en: 'Searching for GPS'
	String get gpsSearching => 'Searching for GPS';

	/// en: 'Looking for a reliable signal'
	String get gpsSearchingHint => 'Looking for a reliable signal';

	/// en: 'Weak GPS signal'
	String get gpsWeak => 'Weak GPS signal';

	/// en: 'Signal is unstable. Keep device in open sky.'
	String get gpsWeakHint => 'Signal is unstable. Keep device in open sky.';

	/// en: 'Signal unstable. Last fix $age.'
	String gpsWeakHintWithAge({required Object age}) => 'Signal unstable. Last fix ${age}.';

	/// en: 'GPS active'
	String get gpsActive => 'GPS active';

	/// en: 'Receiving live telemetry.'
	String get gpsActiveHint => 'Receiving live telemetry.';

	/// en: 'Last GPS update $age.'
	String gpsActiveHintWithAge({required Object age}) => 'Last GPS update ${age}.';

	/// en: 'just now'
	String get ageJustNow => 'just now';

	/// en: '$seconds s ago'
	String ageSeconds({required Object seconds}) => '${seconds} s ago';

	/// en: '$minutes m ago'
	String ageMinutes({required Object minutes}) => '${minutes} m ago';

	/// en: 'Good'
	String get signalGood => 'Good';

	/// en: 'Poor'
	String get signalPoor => 'Poor';

	/// en: 'Bad'
	String get signalBad => 'Bad';

	/// en: 'Searching'
	String get signalSearching => 'Searching';

	/// en: 'GPS $quality'
	String gpsQuality({required Object quality}) => 'GPS ${quality}';

	/// en: 'GPS searching'
	String get gpsSearchingLabel => 'GPS searching';

	/// en: 'GPS permission needed'
	String get gpsPermissionNeededLabel => 'GPS permission needed';

	/// en: 'GPS off'
	String get gpsOffLabel => 'GPS off';

	/// en: 'Aircraft heading'
	String get aircraftHeading => 'Aircraft heading';

	/// en: 'HDG $heading°'
	String headingShort({required Object heading}) => 'HDG ${heading}°';

	/// en: 'Live instruments'
	String get liveInstruments => 'Live instruments';

	/// en: 'Acquiring GPS signal'
	String get acquiringGpsSignal => 'Acquiring GPS signal';

	/// en: 'Keep the device steady and in open sky for a reliable fix.'
	String get acquiringGpsHint => 'Keep the device steady and in open sky for a reliable fix.';

	/// en: 'Weak GPS signal. Values may drift until accuracy improves.'
	String get weakSignalBanner => 'Weak GPS signal. Values may drift until accuracy improves.';

	/// en: 'Preparing dashboard...'
	String get preparingDashboard => 'Preparing dashboard...';

	/// en: 'Navigation'
	String get navigation => 'Navigation';

	/// en: 'Heading $heading'
	String heading({required Object heading}) => 'Heading ${heading}';

	/// en: 'Route progress'
	String get routeProgress => 'Route progress';

	/// en: 'Covered'
	String get covered => 'Covered';

	/// en: 'Remaining'
	String get remaining => 'Remaining';

	/// en: 'Total'
	String get total => 'Total';
}

// Path: flight.info
class TranslationsFlightInfoEn {
	TranslationsFlightInfoEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Overview'
	String get overviewTitle => 'Overview';

	/// en: 'Building route overview...'
	String get overviewLoading => 'Building route overview...';

	/// en: 'Overview is not available yet for this route.'
	String get overviewEmpty => 'Overview is not available yet for this route.';

	/// en: 'Loading route information...'
	String get loadingRouteInformation => 'Loading route information...';

	/// en: 'Highlights along you route'
	String get flyOverTitle => 'Highlights along you route';

	/// en: 'Airports'
	String get airportsTitle => 'Airports';

	/// en: 'Departure'
	String get departure => 'Departure';

	/// en: 'Arrival'
	String get arrival => 'Arrival';

	/// en: 'Route timeline'
	String get routeTimelineTitle => 'Route timeline';

	/// en: '$count planned waypoints'
	String plannedWaypoints({required Object count}) => '${count} planned waypoints';

	/// en: 'Points of Interest'
	String get pointsOfInterestTitle => 'Points of Interest';

	/// en: 'No POIs available yet.'
	String get noPoi => 'No POIs available yet.';

	/// en: 'Type: $type'
	String poiType({required Object type}) => 'Type: ${type}';

	/// en: 'Fly-over: $view'
	String poiFlyOver({required Object view}) => 'Fly-over: ${view}';

	/// en: 'Offline Articles'
	String get offlineArticlesTitle => 'Offline Articles';

	/// en: 'No offline articles downloaded.'
	String get noOfflineArticles => 'No offline articles downloaded.';

	/// en: 'Open Source'
	String get openSource => 'Open Source';

	/// en: 'Open source page'
	String get openSourcePageTooltip => 'Open source page';

	/// en: '$distance km'
	String distanceKm({required Object distance}) => '${distance} km';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Altitude'
	String get altitude => 'Altitude';

	/// en: 'Flymap Route'
	String get copyRouteTitle => 'Flymap Route';

	/// en: 'Route code: $routeCode'
	String copyRouteCode({required Object routeCode}) => 'Route code: ${routeCode}';

	/// en: 'Distance: $distance km'
	String copyDistance({required Object distance}) => 'Distance: ${distance} km';

	/// en: 'From'
	String get copyFrom => 'From';

	/// en: 'To'
	String get copyTo => 'To';

	/// en: 'City: $city, $countryCode'
	String copyCity({required Object city, required Object countryCode}) => 'City: ${city}, ${countryCode}';

	/// en: 'Airport: $airport'
	String copyAirport({required Object airport}) => 'Airport: ${airport}';

	/// en: 'Codes: IATA $iata | ICAO $icao'
	String copyCodes({required Object iata, required Object icao}) => 'Codes: IATA ${iata} | ICAO ${icao}';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'appName' => 'Flymap',
			'common.kContinue' => 'Continue',
			'common.back' => 'Back',
			'common.cancel' => 'Cancel',
			'common.ok' => 'OK',
			'common.retry' => 'Retry',
			'common.upgrade' => 'Upgrade',
			'common.loading' => 'Loading...',
			'common.readMore' => 'Read more',
			'home.title' => 'Home',
			'home.aboutTooltip' => 'About',
			'home.settingsTooltip' => 'Settings',
			'home.tabFlights' => 'Flights',
			'home.tabLibrary' => 'Learn',
			'home.loadingFlights' => 'Loading flights...',
			'home.failedToLoadFlights' => 'Failed to load flights',
			'home.newFlight' => 'New flight',
			'home.addFirstFlight' => 'Add first flight',
			'home.welcomeTitle' => 'Welcome to Flymap',
			'home.welcomeTitlePro' => 'Welcome to Flymap Pro',
			'home.welcomeSubtitle' => 'Offline maps for flights',
			'home.flightsSaved' => 'Flights saved',
			'home.storageUsed' => 'Storage used',
			'home.flightsCount' => ({required Object count}) => 'Flights (${count})',
			'home.noFlightsTitle' => 'Ready to explore the world from above?',
			'home.noFlightsSubtitle' => 'Add your first flight and start discovering your next journey.',
			'home.statusSavedOffline' => 'Saved offline',
			'home.statusNeedsMap' => 'Needs map',
			'home.flightActions' => 'Flight actions',
			'home.open' => 'Open',
			'home.shareRoute' => 'Share route',
			'home.deleteFlight' => 'Delete flight',
			'home.failedDeleteFlight' => 'Failed to delete flight',
			'home.noOfflineMap' => 'No offline map',
			'home.justNow' => 'Just now',
			'home.daysAgo' => ({required Object days}) => '${days} d ago',
			'home.hoursAgo' => ({required Object hours}) => '${hours} h ago',
			'home.minutesAgo' => ({required Object minutes}) => '${minutes} m ago',
			'home.sort.mostRecent' => 'Most recent',
			'home.sort.longest' => 'Longest',
			'home.sort.alphabetical' => 'A-Z',
			'settings.title' => 'Settings',
			'settings.loading' => 'Loading settings...',
			'settings.appearance' => 'Appearance',
			'settings.theme' => 'Theme',
			'settings.dark' => 'Dark',
			'settings.light' => 'Light',
			'settings.units' => 'Units',
			'settings.altitude' => 'Altitude',
			'settings.altitudeUnit' => 'Altitude unit',
			'settings.speed' => 'Speed',
			'settings.speedUnit' => 'Speed unit',
			'settings.timeFormat' => 'Time format',
			'settings.about' => 'About',
			'settings.aboutSubtitle' => 'Learn more about the app',
			'settings.privacyPolicy' => 'Privacy Policy',
			'settings.privacyPolicySubtitle' => 'Read our privacy policy',
			'settings.termsOfService' => 'Terms of Service',
			'settings.termsOfServiceSubtitle' => 'Read our terms of service',
			'settings.flymapProActivated' => 'Flymap Pro activated.',
			'settings.upgradeCancelled' => 'Upgrade cancelled.',
			'settings.noPaywall' => 'No paywall available right now.',
			'settings.failedOpenPaywall' => 'Failed to open paywall.',
			'settings.couldNotOpenUrl' => ({required Object url}) => 'Could not open ${url}',
			'settings.rateUs' => 'Rate us',
			'settings.rateUsSubtitle' => 'Leave a review on the store',
			'settings.leaveFeedback' => 'Leave a Feedback',
			'settings.leaveFeedbackSubtitle' => 'Share your thoughts to help us improve',
			'settings.couldNotOpenStorePage' => 'Could not open store page',
			'settings.rateDialogTitle' => 'Do you like the app?',
			'settings.rateDialogBody' => 'We work hard to make every flight more enjoyable, and your feedback really helps us improve.',
			'settings.rateDialogYes' => 'Yes',
			'settings.rateDialogNo' => 'No',
			'settings.feedbackTitle' => 'Leave a Feedback',
			'settings.feedbackBody' => 'Help us to make Flymap better',
			'settings.feedbackCategoryTitle' => 'Feedback type',
			'settings.feedbackCategoryGeneral' => 'General',
			'settings.feedbackCategoryFeatureRequest' => 'Feature request',
			'settings.feedbackCategoryBugReport' => 'Bug report',
			'settings.feedbackHint' => 'Share your feedback...',
			'settings.feedbackEmailHint' => 'Email (optional)',
			'settings.feedbackEmailInvalid' => 'Please enter a valid email or leave it empty.',
			'settings.feedbackSend' => 'Send',
			'settings.feedbackThanks' => 'Thanks for sharing your feedback!',
			'settings.feedbackSendFailed' => 'Couldn\'t send feedback. Please try again.',
			'settings.proBannerTitle' => 'Flymap Pro',
			'settings.proBannerTitleActive' => 'Flymap Pro Active',
			'settings.proBannerSubtitleActive' => 'Detailed map mode and full offline article bundles unlocked.',
			'settings.proBannerSubtitleFree' => 'Unlock detailed maps and full offline article bundles',
			'settings.proBannerBadgeActive' => 'PRO ACTIVE',
			'subscription.screenTitle' => 'Subscription',
			'subscription.pullToRefresh' => 'Pull down to refresh your subscription status.',
			'subscription.needHelp' => 'Need help?',
			'subscription.contactSupport' => 'Contact support',
			'subscription.cardTitle' => 'Flymap Pro',
			'subscription.checkingStatus' => 'Checking your subscription status...',
			'subscription.proActive' => 'Flymap Pro is active.',
			'subscription.freePlan' => 'You are on Free plan.',
			'subscription.status' => 'Status',
			'subscription.active' => 'Active',
			'subscription.notActive' => 'Not active',
			'subscription.entitlement' => 'Entitlement',
			'subscription.expires' => 'Expires',
			'subscription.noExpiration' => 'No expiration',
			'subscription.lastUpdate' => 'Last update',
			'subscription.unknown' => 'Unknown',
			'subscription.manageSubscription' => 'Manage subscription',
			'subscription.upgradeToPro' => 'Upgrade to Pro',
			'subscription.proManageHint' => 'You can cancel or change billing in your App Store or Google Play subscription settings.',
			'subscription.freeUpgradeHint' => 'Free users can upgrade to Pro to unlock premium features.',
			'subscription.supportEmailSubject' => 'Flymap subscription support',
			'subscription.couldNotOpenEmailApp' => 'Could not open email app',
			'subscription.couldNotOpenSubscriptionSettings' => 'Could not open subscription settings',
			'subscription.proRestored' => 'Flymap Pro restored.',
			'subscription.failedOpenPaywall' => 'Failed to open paywall.',
			'subscription.serviceUnavailable' => 'Subscription service is temporarily unavailable.',
			'createFlight.steps.departureTitle' => 'Choose departure airport',
			'createFlight.steps.arrivalTitle' => 'Choose arrival airport',
			'createFlight.steps.routeNotSupportedTitle' => 'Route not supported',
			'createFlight.steps.mapPreviewTitle' => 'Map preview',
			'createFlight.steps.overviewTitle' => 'Route overview',
			'createFlight.steps.wikipediaTitle' => 'Wikipedia articles',
			'createFlight.search.departureHint' => 'Search departure airport',
			'createFlight.search.arrivalHint' => 'Search arrival airport',
			'createFlight.search.removeFavorite' => 'Remove favorite',
			'createFlight.search.addFavorite' => 'Add to favorite',
			'createFlight.search.removeSelectedAirport' => 'Remove selected airport',
			'createFlight.search.favorites' => 'Favorites',
			'createFlight.search.popularAirports' => 'Popular airports',
			'createFlight.search.removeFromFavorites' => 'Remove from favorites',
			'createFlight.search.noDepartureFound' => 'No departure airports found.',
			'createFlight.search.noArrivalFound' => 'No arrival airports found.',
			'createFlight.search.airportCodeCity' => ({required Object code, required Object city}) => '${code} · ${city}',
			'createFlight.search.airportNameCode' => ({required Object name, required Object code}) => '${name} (${code})',
			'createFlight.mapPreview.routeNotSupportedMsg' => 'Sorry, antimeridian flights are not supported yet.',
			'createFlight.mapPreview.basic' => 'Basic',
			'createFlight.mapPreview.pro' => 'Pro',
			'createFlight.mapPreview.mapDetailInfoTooltip' => 'Map detail info',
			'createFlight.mapPreview.legendButton' => 'Legend',
			'createFlight.mapPreview.legendTitle' => 'POI legend',
			'createFlight.mapPreview.estimatedMapSize' => ({required Object size}) => 'Estimated map size: ${size}',
			'createFlight.mapPreview.upgradeToPro' => 'Upgrade to Pro',
			'createFlight.mapPreview.optionsTitle' => 'Map options',
			'createFlight.mapPreview.optionsBody' => 'Basic: lower zoom, faster download, less storage\n\nPro: higher zoom, more detail, larger download\n\nRoute is approximate — actual path may vary (especially long-haul)',
			'createFlight.overview.routeNotReady' => 'Route is not ready yet.',
			'createFlight.overview.proPoiUpsell' => 'With Flymap Pro, discover more interesting places along your route.',
			'createFlight.wikipedia.title' => 'Download articles to read during the flight',
			'createFlight.wikipedia.loadingIntro' => 'Finding route-related articles...',
			'createFlight.wikipedia.foundIntro' => ({required Object count}) => 'Based on your route we found ${count} articles which may be interesting for you. Select to download them for offline reading',
			'createFlight.wikipedia.emptyIntro' => 'No route-related Wikipedia articles found. You can continue with map download only.',
			'createFlight.wikipedia.selectedCount' => ({required Object count}) => '${count} selected',
			'createFlight.wikipedia.unselectAll' => 'Unselect all',
			'createFlight.wikipedia.selectAll' => 'Select all',
			'createFlight.wikipedia.proActiveTitle' => 'Pro active',
			'createFlight.wikipedia.proActiveMessage' => 'Full articles pack unlocked.',
			'createFlight.wikipedia.freeLimitHint' => 'Free plan includes up to 3 offline articles. Upgrade to Pro for unlimited articles.',
			'createFlight.wikipedia.estimatedDownloadSize' => ({required Object size}) => 'Estimated download size: ${size}',
			'createFlight.wikipedia.upgrade' => 'Upgrade',
			'createFlight.wikipedia.loadingSuggestions' => 'Loading article suggestions...',
			'createFlight.wikipedia.downloadMapOnly' => 'Download map',
			'createFlight.wikipedia.downloadMapPlusOne' => 'Download map + 1 article',
			'createFlight.wikipedia.downloadMapPlusMany' => ({required Object count}) => 'Download map + ${count} articles',
			'createFlight.wikipedia.couldNotOpenLink' => 'Could not open link',
			'createFlight.downloading.articlesTitle' => 'Downloading selected articles...',
			'createFlight.downloading.mapTitle' => 'Downloading offline map...',
			'createFlight.downloading.mapSectionTitle' => 'Map',
			'createFlight.downloading.poiSectionTitle' => 'Places',
			'createFlight.downloading.articlesSectionTitle' => 'Articles',
			'createFlight.downloading.cancelDownload' => 'Cancel download',
			'createFlight.downloading.doNotClose' => 'Do not close this screen until download completes',
			'createFlight.downloading.currentStep' => 'Current',
			'createFlight.downloading.pending' => 'Pending',
			'createFlight.downloading.inProgress' => 'In progress',
			'createFlight.downloading.completed' => 'Completed',
			'createFlight.downloading.completedWithIssues' => 'Completed with issues',
			'createFlight.downloading.failed' => 'Failed',
			'createFlight.downloading.skipped' => 'Skipped',
			'createFlight.downloading.waitingForMap' => 'Waiting for map download...',
			'createFlight.downloading.mapFailed' => 'Map download failed.',
			'createFlight.downloading.noPoiSelected' => 'No place summaries selected.',
			'createFlight.downloading.preparingPoi' => 'Preparing place summaries...',
			'createFlight.downloading.poiProgress' => ({required Object completed, required Object total}) => 'Places: ${completed}/${total}',
			'createFlight.downloading.poiProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Places: ${completed}/${total} (${failed} failed)',
			'createFlight.downloading.noArticlesSelected' => 'No articles selected.',
			'createFlight.downloading.preparingArticles' => 'Preparing article downloads...',
			'createFlight.downloading.articlesProgress' => ({required Object completed, required Object total}) => 'Articles: ${completed}/${total}',
			'createFlight.downloading.articlesProgressWithFailed' => ({required Object completed, required Object total, required Object failed}) => 'Articles: ${completed}/${total} (${failed} failed)',
			'createFlight.downloading.preparingMap' => 'Preparing map download...',
			'createFlight.downloading.computingTiles' => 'Computing map tiles...',
			'createFlight.downloading.computingTilesWithCount' => ({required Object count}) => 'Computing map tiles (${count})...',
			'createFlight.downloading.preparingForDownload' => 'Preparing for download...',
			'createFlight.downloading.downloaded' => ({required Object size}) => 'Downloaded: ${size}',
			'createFlight.downloading.finalizing' => 'Finalizing map package...',
			'createFlight.downloading.verifying' => 'Verifying map package...',
			'createFlight.errors.failedLoadAirports' => 'Failed to load airports. Please try again.',
			'createFlight.errors.airportSearchFailed' => 'Airport search failed. Try another query.',
			'createFlight.errors.someArticlesFailed' => 'Some articles failed. Continuing with map download.',
			'createFlight.errors.someOptionalDownloadsFailed' => 'Map downloaded. Some optional content could not be downloaded.',
			'createFlight.errors.failedBuildPreview' => 'Failed to build route preview. Please try again.',
			'createFlight.errors.overviewUnavailableContinue' => 'Could not load route overview. You can still continue.',
			'createFlight.errors.noInternet' => 'No internet connection. Please check your connection and try again.',
			'createFlight.errors.failedStartDownload' => ({required Object error}) => 'Failed to start download: ${error}',
			'createFlight.paywall.upgradeCancelled' => 'Upgrade cancelled.',
			'createFlight.paywall.noPaywall' => 'No paywall available right now.',
			'createFlight.paywall.failedOpenPaywall' => 'Failed to open paywall.',
			'preview.calculatingRoute' => 'Calculating flight route...',
			'preview.errorTitle' => 'Error',
			'preview.errorSomethingWrong' => 'Something went wrong',
			'preview.tryAgain' => 'Try Again',
			'preview.downloadComplete' => 'Download Complete!',
			'preview.flightSaved' => 'Flight has been saved',
			'preview.navigatingHome' => 'Navigating to home...',
			'preview.downloadingMapTitle' => 'Downloading Flight Map',
			'preview.cancelDownload' => 'Cancel download',
			'preview.download' => 'Download',
			'preview.flightRoute' => ({required Object distance}) => 'Flight route (~ ${distance})',
			'flight.tabMap' => 'Map',
			'flight.tabDashboard' => 'Dashboard',
			'flight.tabInfo' => 'Info',
			'flight.deleteDialogTitle' => 'Are you sure?',
			'flight.deleteDialogMessage' => ({required Object size}) => 'This will permanently delete this flight.\n\nSpace to be regained: ${size}.',
			'flight.yes' => 'Yes',
			'flight.shareRoute' => 'Share route',
			'flight.copyRoute' => 'Copy route',
			'flight.deleteFlight' => 'Delete flight',
			'flight.routeSummaryCopied' => 'Route summary copied',
			'flight.deleted' => 'Flight deleted',
			'flight.deleteError' => ({required Object error}) => 'Error deleting flight: ${error}',
			'flight.map.initializing' => 'Initializing map...',
			'flight.map.loadingStyle' => 'Loading map style...',
			'flight.map.offlineNotAvailable' => 'Offline map is not available for this flight.',
			'flight.map.offlineMissing' => 'Offline map file is missing. Please re-download this route.',
			'flight.map.validationFailed' => 'Offline map validation failed. Please re-download this route.',
			'flight.map.loadStyleFailed' => 'Could not load offline map style.',
			'flight.map.switchTo2D' => 'Switch to 2D',
			'flight.map.switchTo3D' => 'Switch to 3D',
			'flight.map.uncenterMap' => 'Uncenter map',
			'flight.map.centerOnMe' => 'Center on me',
			'flight.dashboard.gpsOffTitle' => 'Location services are off',
			'flight.dashboard.gpsOffSubtitle' => 'Turn on location services in system settings to resume live flight tracking and map following.',
			'flight.dashboard.openLocationSettings' => 'Open location settings',
			'flight.dashboard.permissionTitle' => 'Location permission required',
			'flight.dashboard.permissionSubtitle' => 'Allow location access so the dashboard can show live heading, speed, and altitude.',
			'flight.dashboard.grantPermissions' => 'Grant permissions',
			'flight.dashboard.gpsAccuracy' => ({required Object label, required Object accuracy}) => 'GPS Accuracy: ${label} (±${accuracy} m)',
			'flight.dashboard.accuracyExcellent' => 'Excellent',
			'flight.dashboard.accuracyGood' => 'Good',
			'flight.dashboard.accuracyPoor' => 'Poor',
			'flight.dashboard.gpsOff' => 'GPS off',
			'flight.dashboard.gpsOffHint' => 'Enable location services to start tracking.',
			'flight.dashboard.gpsPermissionRequired' => 'Location permission required',
			'flight.dashboard.gpsPermissionHint' => 'Grant permission to access live flight telemetry.',
			'flight.dashboard.gpsSearching' => 'Searching for GPS',
			'flight.dashboard.gpsSearchingHint' => 'Looking for a reliable signal',
			'flight.dashboard.gpsWeak' => 'Weak GPS signal',
			'flight.dashboard.gpsWeakHint' => 'Signal is unstable. Keep device in open sky.',
			'flight.dashboard.gpsWeakHintWithAge' => ({required Object age}) => 'Signal unstable. Last fix ${age}.',
			'flight.dashboard.gpsActive' => 'GPS active',
			'flight.dashboard.gpsActiveHint' => 'Receiving live telemetry.',
			'flight.dashboard.gpsActiveHintWithAge' => ({required Object age}) => 'Last GPS update ${age}.',
			'flight.dashboard.ageJustNow' => 'just now',
			'flight.dashboard.ageSeconds' => ({required Object seconds}) => '${seconds} s ago',
			'flight.dashboard.ageMinutes' => ({required Object minutes}) => '${minutes} m ago',
			'flight.dashboard.signalGood' => 'Good',
			'flight.dashboard.signalPoor' => 'Poor',
			'flight.dashboard.signalBad' => 'Bad',
			'flight.dashboard.signalSearching' => 'Searching',
			'flight.dashboard.gpsQuality' => ({required Object quality}) => 'GPS ${quality}',
			'flight.dashboard.gpsSearchingLabel' => 'GPS searching',
			'flight.dashboard.gpsPermissionNeededLabel' => 'GPS permission needed',
			'flight.dashboard.gpsOffLabel' => 'GPS off',
			'flight.dashboard.aircraftHeading' => 'Aircraft heading',
			'flight.dashboard.headingShort' => ({required Object heading}) => 'HDG ${heading}°',
			'flight.dashboard.liveInstruments' => 'Live instruments',
			'flight.dashboard.acquiringGpsSignal' => 'Acquiring GPS signal',
			'flight.dashboard.acquiringGpsHint' => 'Keep the device steady and in open sky for a reliable fix.',
			'flight.dashboard.weakSignalBanner' => 'Weak GPS signal. Values may drift until accuracy improves.',
			'flight.dashboard.preparingDashboard' => 'Preparing dashboard...',
			'flight.dashboard.navigation' => 'Navigation',
			'flight.dashboard.heading' => ({required Object heading}) => 'Heading ${heading}',
			'flight.dashboard.routeProgress' => 'Route progress',
			'flight.dashboard.covered' => 'Covered',
			'flight.dashboard.remaining' => 'Remaining',
			'flight.dashboard.total' => 'Total',
			'flight.info.overviewTitle' => 'Overview',
			'flight.info.overviewLoading' => 'Building route overview...',
			'flight.info.overviewEmpty' => 'Overview is not available yet for this route.',
			'flight.info.loadingRouteInformation' => 'Loading route information...',
			'flight.info.flyOverTitle' => 'Highlights along you route',
			'flight.info.airportsTitle' => 'Airports',
			'flight.info.departure' => 'Departure',
			'flight.info.arrival' => 'Arrival',
			'flight.info.routeTimelineTitle' => 'Route timeline',
			'flight.info.plannedWaypoints' => ({required Object count}) => '${count} planned waypoints',
			'flight.info.pointsOfInterestTitle' => 'Points of Interest',
			'flight.info.noPoi' => 'No POIs available yet.',
			'flight.info.poiType' => ({required Object type}) => 'Type: ${type}',
			'flight.info.poiFlyOver' => ({required Object view}) => 'Fly-over: ${view}',
			'flight.info.offlineArticlesTitle' => 'Offline Articles',
			'flight.info.noOfflineArticles' => 'No offline articles downloaded.',
			'flight.info.openSource' => 'Open Source',
			'flight.info.openSourcePageTooltip' => 'Open source page',
			'flight.info.distanceKm' => ({required Object distance}) => '${distance} km',
			'flight.info.speed' => 'Speed',
			'flight.info.altitude' => 'Altitude',
			'flight.info.copyRouteTitle' => 'Flymap Route',
			'flight.info.copyRouteCode' => ({required Object routeCode}) => 'Route code: ${routeCode}',
			'flight.info.copyDistance' => ({required Object distance}) => 'Distance: ${distance} km',
			'flight.info.copyFrom' => 'From',
			'flight.info.copyTo' => 'To',
			'flight.info.copyCity' => ({required Object city, required Object countryCode}) => 'City: ${city}, ${countryCode}',
			'flight.info.copyAirport' => ({required Object airport}) => 'Airport: ${airport}',
			'flight.info.copyCodes' => ({required Object iata, required Object icao}) => 'Codes: IATA ${iata} | ICAO ${icao}',
			'shareFlight.title' => 'Share flight',
			'shareFlight.preparingMap' => 'Preparing share preview map...',
			'shareFlight.preparingScreenshot' => 'Preparing screenshot...',
			'shareFlight.share' => 'Share',
			'shareFlight.offlineMapMissing' => 'Offline map missing. Using online style.',
			'shareFlight.offlineStyleFailed' => 'Failed to load offline style. Using online style.',
			'shareFlight.captureFailed' => 'Could not capture route screenshot',
			'shareFlight.shareFailed' => 'Failed to share route screenshot',
			'shareFlight.shareText' => ({required Object from, required Object to}) => 'Flight route ${from}-${to}',
			'shareFlight.watermark' => 'Flymap',
			'shareFlight.flightDistance' => 'Flight distance',
			'shareFlight.distanceKm' => ({required Object distance}) => '${distance} km',
			'about.title' => 'About Flymap',
			'about.welcome' => 'Welcome to Flymap',
			'about.intro' => 'Flymap keeps your route visible in the air. Plan the trip, download your map on the ground, and track your flight offline with confidence.',
			'about.chipOffline' => 'Offline map',
			'about.chipDashboard' => 'Live dashboard',
			'about.chipSharing' => 'Route sharing',
			'about.infoBanner' => 'Before takeoff, download your route map. In flight mode, internet access may be limited or unavailable.',
			'about.whatYouCanDo' => 'What You Can Do',
			'about.featurePlanTitle' => 'Plan your route',
			'about.featurePlanText' => 'Choose departure and arrival airports, then preview the path before downloading.',
			'about.featureTrackTitle' => 'Track flight data',
			'about.featureTrackText' => 'Use Dashboard to monitor heading, speed, altitude, and route progress.',
			'about.featureDetailsTitle' => 'Check route details',
			'about.featureDetailsText' => 'Open the Info tab for airport details and a clean route overview.',
			'about.featureShareTitle' => 'Share your journey',
			'about.featureShareText' => 'Generate and share a flight map screenshot with route highlights.',
			'about.quickStart' => 'Quick Start',
			'about.step1' => 'Tap New flight on Home.',
			'about.step2' => 'Choose departure and arrival airports.',
			'about.step3' => 'Open Map preview and download the map before the flight.',
			'about.step4' => 'Open your flight and use Map, Dashboard, and Info in the air.',
			'about.tips' => 'Tips For Better GPS',
			'about.tip1' => 'For stronger GPS signal, sit closer to a window.',
			'about.tip2' => 'Signal can drop in the middle of the aircraft. Flymap keeps the last known route view while searching.',
			'onboarding.skip' => 'Skip',
			'onboarding.next' => 'Next',
			'onboarding.startExploring' => 'Start exploring',
			'onboarding.page1Title' => 'Explore the world from above',
			'onboarding.page1Subtitle' => 'From coastlines to mountain ranges, every route feels like a new adventure.',
			'onboarding.page2Title' => 'Turn every flight into a story',
			'onboarding.page2Subtitle' => 'Follow your path in real time and enjoy the journey, not just the destination.',
			'onboarding.page3Title' => 'Download maps before takeoff',
			'onboarding.page3Subtitle' => 'To enjoy your offline in-flight experience, download your map before switching to flight mode.',
			'onboarding.page4Title' => 'Privacy by design',
			'onboarding.page4Subtitle' => 'Your location stays on your device. We don’t collect or share it.',
			_ => null,
		};
	}
}
