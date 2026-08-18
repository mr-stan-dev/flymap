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
	late final TranslationsSkyCameraEn skyCamera = TranslationsSkyCameraEn.internal(_root);
	late final TranslationsMediaEn media = TranslationsMediaEn.internal(_root);
	late final TranslationsLearnEn learn = TranslationsLearnEn.internal(_root);
	late final TranslationsSettingsEn settings = TranslationsSettingsEn.internal(_root);
	late final TranslationsSubscriptionEn subscription = TranslationsSubscriptionEn.internal(_root);
	late final TranslationsCreateFlightEn createFlight = TranslationsCreateFlightEn.internal(_root);
	late final TranslationsPreviewEn preview = TranslationsPreviewEn.internal(_root);
	late final TranslationsFlightEn flight = TranslationsFlightEn.internal(_root);
	late final TranslationsShareFlightEn shareFlight = TranslationsShareFlightEn.internal(_root);
	late final TranslationsShareImageEn shareImage = TranslationsShareImageEn.internal(_root);
	late final TranslationsFlightVideoEn flightVideo = TranslationsFlightVideoEn.internal(_root);
	late final TranslationsAboutEn about = TranslationsAboutEn.internal(_root);
	late final TranslationsNotificationsEn notifications = TranslationsNotificationsEn.internal(_root);
	late final TranslationsOnboardingEn onboarding = TranslationsOnboardingEn.internal(_root);
	late final TranslationsCountriesEn countries = TranslationsCountriesEn.internal(_root);
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

	/// en: 'Manage'
	String get manage => 'Manage';

	/// en: 'Edit'
	String get edit => 'Edit';

	/// en: 'Upgrade to Pro'
	String get upgrade => 'Upgrade to Pro';

	/// en: 'Loading...'
	String get loading => 'Loading...';

	/// en: 'Read more'
	String get readMore => 'Read more';

	/// en: 'PRO'
	String get pro => 'PRO';

	/// en: 'Search'
	String get search => 'Search';

	/// en: 'Debug'
	String get debug => 'Debug';
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
	String get tabLearn => 'Learn';

	/// en: 'Media'
	String get tabMedia => 'Media';

	/// en: 'Open Sky Camera'
	String get openSkyCamera => 'Open Sky Camera';

	/// en: 'Loading flights...'
	String get loadingFlights => 'Loading flights...';

	/// en: 'Failed to load flights'
	String get failedToLoadFlights => 'Failed to load flights';

	/// en: 'New flight'
	String get newFlight => 'New flight';

	/// en: 'Add first flight'
	String get addFirstFlight => 'Add first flight';

	/// en: 'Add next flight'
	String get addNextFlight => 'Add next flight';

	/// en: 'Welcome to Flymap'
	String get welcomeTitle => 'Welcome to Flymap';

	/// en: 'Welcome to Flymap Pro'
	String get welcomeTitlePro => 'Welcome to Flymap Pro';

	/// en: 'Offline maps for flights'
	String get welcomeSubtitle => 'Offline maps for flights';

	/// en: 'Ready for the next flight?'
	String get greetingOnline => 'Ready for the next flight?';

	/// en: 'Hi $name, ready for the next flight?'
	String greetingOnlineWithName({required Object name}) => 'Hi ${name}, ready for the next flight?';

	/// en: 'Ready to explore your flight?'
	String get greetingOffline => 'Ready to explore your flight?';

	/// en: 'Hi $name, ready to explore your flight?'
	String greetingOfflineWithName({required Object name}) => 'Hi ${name}, ready to explore your flight?';

	/// en: 'Your flight is in progress'
	String get greetingInProgress => 'Your flight is in progress';

	/// en: 'Hi $name, your flight is in progress'
	String greetingInProgressWithName({required Object name}) => 'Hi ${name}, your flight is in progress';

	/// en: 'Total flights'
	String get totalFlights => 'Total flights';

	/// en: 'Storage used'
	String get storageUsed => 'Storage used';

	/// en: 'Total distance'
	String get totalDistance => 'Total distance';

	/// en: 'Upcoming flights ($count)'
	String upcomingFlightsCount({required Object count}) => 'Upcoming flights (${count})';

	/// en: 'Flight in progress'
	String get flightInProgressTitle => 'Flight in progress';

	/// en: 'Ready to explore the world from above?'
	String get noFlightsTitle => 'Ready to explore the world from above?';

	/// en: 'Add your first flight and start discovering your next journey.'
	String get noFlightsSubtitle => 'Add your first flight and start discovering your next journey.';

	/// en: 'Ready for your next trip?'
	String get noFlightsTitleNext => 'Ready for your next trip?';

	/// en: 'Your completed flights are in History. Add your next flight to keep going.'
	String get noFlightsSubtitleNext => 'Your completed flights are in History. Add your next flight to keep going.';

	/// en: 'Flight actions'
	String get flightActions => 'Flight actions';

	/// en: 'View all'
	String get viewAll => 'View all';

	/// en: 'Open'
	String get open => 'Open';

	/// en: 'Share route'
	String get shareRoute => 'Share route';

	/// en: 'Archive flight'
	String get completeFlight => 'Archive flight';

	/// en: 'Delete flight'
	String get deleteFlight => 'Delete flight';

	/// en: 'Failed to delete flight'
	String get failedDeleteFlight => 'Failed to delete flight';

	/// en: 'No offline map'
	String get noOfflineMap => 'No offline map';

	/// en: '$count places'
	String placesCount({required Object count}) => '${count} places';

	/// en: '$count regions'
	String regionsCount({required Object count}) => '${count} regions';

	/// en: '$count articles'
	String offlineArticlesCount({required Object count}) => '${count} articles';

	/// en: 'Saved $time'
	String savedTime({required Object time}) => 'Saved ${time}';

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

// Path: skyCamera
class TranslationsSkyCameraEn {
	TranslationsSkyCameraEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading camera...'
	String get loading => 'Loading camera...';

	/// en: 'Loading GPS data'
	String get loadingGpsData => 'Loading GPS data';

	/// en: 'Zoom'
	String get zoom => 'Zoom';

	/// en: 'Flash'
	String get flash => 'Flash';

	/// en: 'Camera is unavailable right now.'
	String get cameraUnavailable => 'Camera is unavailable right now.';

	/// en: 'Camera permission is required to take photos and record videos.'
	String get cameraPermissionDenied => 'Camera permission is required to take photos and record videos.';

	/// en: 'Could not save this capture right now.'
	String get captureFailed => 'Could not save this capture right now.';

	/// en: 'Photo saved'
	String get savedMessage => 'Photo saved';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'No active flight'
	String get noActiveFlightTitle => 'No active flight';

	/// en: 'Sky Camera works without a flight, but route details appear only during an active flight.'
	String get noActiveFlightMessage => 'Sky Camera works without a flight, but route details appear only during an active flight.';

	/// en: 'Speed'
	String get telemetrySpeed => 'Speed';

	/// en: 'Altitude'
	String get telemetryAltitude => 'Altitude';

	/// en: 'Heading'
	String get telemetryHeading => 'Heading';

	/// en: 'Time'
	String get telemetryTime => 'Time';

	/// en: 'Context'
	String get contextCaption => 'Context';

	/// en: 'Map'
	String get mapCaption => 'Map';

	/// en: 'Coordinates'
	String get coordinatesCaption => 'Coordinates';

	/// en: '--'
	String get noValuePlaceholder => '--';

	/// en: 'LHR -> BCN'
	String get placeholderRoute => 'LHR -> BCN';

	/// en: 'LHR'
	String get placeholderOriginCode => 'LHR';

	/// en: 'BCN'
	String get placeholderDestinationCode => 'BCN';

	/// en: 'Mediterranean Sea'
	String get placeholderContext => 'Mediterranean Sea';

	/// en: 'Route preview'
	String get placeholderMap => 'Route preview';

	/// en: 'Camera settings'
	String get settingsTitle => 'Camera settings';

	/// en: 'Record audio'
	String get recordAudio => 'Record audio';

	/// en: 'Videos capture microphone sound.'
	String get recordAudioHint => 'Videos capture microphone sound.';

	/// en: 'Microphone access is off — videos record without sound.'
	String get microphonePermissionDenied => 'Microphone access is off — videos record without sound.';

	/// en: 'Free up storage before recording a video.'
	String get lowStorageRecordingBlocked => 'Free up storage before recording a video.';

	/// en: 'Recording stopped and was saved because storage is almost full.'
	String get lowStorageRecordingStopped => 'Recording stopped and was saved because storage is almost full.';

	/// en: 'Free up storage before preparing this video.'
	String get lowStorageVideoExport => 'Free up storage before preparing this video.';

	/// en: 'Your device is too hot to record. Let it cool down and try again.'
	String get hotDeviceRecordingBlocked => 'Your device is too hot to record. Let it cool down and try again.';

	/// en: 'Recording stopped and was saved because your device is too hot.'
	String get hotDeviceRecordingStopped => 'Recording stopped and was saved because your device is too hot.';

	/// en: 'Preparing video…'
	String get preparingVideo => 'Preparing video…';
}

// Path: media
class TranslationsMediaEn {
	TranslationsMediaEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Window Seat Media'
	String get title => 'Window Seat Media';

	/// en: 'Loading media...'
	String get loading => 'Loading media...';

	/// en: 'Failed to load media'
	String get failedToLoad => 'Failed to load media';

	/// en: 'Files'
	String get filesTab => 'Files';

	/// en: 'Flights'
	String get flightsTab => 'Flights';

	/// en: 'Welcome to your window-seat Sky Camera'
	String get emptyTitle => 'Welcome to your window-seat Sky Camera';

	/// en: 'Capture and share beautiful views from your window seat with flight and GPS data overlays.'
	String get emptySubtitle => 'Capture and share beautiful views from your window seat with flight and GPS data overlays.';

	/// en: 'No flight folders yet'
	String get emptyFlightsTitle => 'No flight folders yet';

	/// en: 'Captures linked to saved flights will appear here.'
	String get emptyFlightsSubtitle => 'Captures linked to saved flights will appear here.';

	/// en: 'Delete'
	String get deleteAction => 'Delete';

	/// en: 'Share'
	String get share => 'Share';

	/// en: '$count selected'
	String selectedCount({required Object count}) => '${count} selected';

	/// en: 'No flight context'
	String get groupNoFlight => 'No flight context';

	/// en: 'Captures taken outside an active flight'
	String get groupNoFlightSubtitle => 'Captures taken outside an active flight';

	/// en: 'Flight capture'
	String get groupUnknownFlight => 'Flight capture';

	/// en: 'Capture'
	String get previewTitle => 'Capture';

	/// en: '$count captures'
	String captureCount({required Object count}) => '${count} captures';

	/// en: 'Delete folder'
	String get deleteFolder => 'Delete folder';

	/// en: 'Delete $count folders'
	String deleteFolders({required Object count}) => 'Delete ${count} folders';

	/// en: 'Delete file'
	String get deleteFile => 'Delete file';

	/// en: 'Delete $count files'
	String deleteFiles({required Object count}) => 'Delete ${count} files';

	/// en: 'Delete this folder and all $count files?'
	String deleteFolderConfirm({required Object count}) => 'Delete this folder and all ${count} files?';

	/// en: 'Delete $count folders and all files inside them?'
	String deleteFoldersConfirm({required Object count}) => 'Delete ${count} folders and all files inside them?';

	/// en: 'Delete this file?'
	String get deleteFileConfirm => 'Delete this file?';

	/// en: 'Delete $count files?'
	String deleteFilesConfirm({required Object count}) => 'Delete ${count} files?';
}

// Path: learn
class TranslationsLearnEn {
	TranslationsLearnEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading learning categories...'
	String get loadingCategories => 'Loading learning categories...';

	/// en: 'Failed to load categories'
	String get failedToLoadCategories => 'Failed to load categories';

	/// en: 'No categories yet'
	String get emptyCategoriesTitle => 'No categories yet';

	/// en: 'Learning categories will appear here soon.'
	String get emptyCategoriesSubtitle => 'Learning categories will appear here soon.';

	/// en: '$count articles'
	String articlesCount({required Object count}) => '${count} articles';

	/// en: 'Loading articles...'
	String get loadingArticles => 'Loading articles...';

	/// en: 'Failed to load articles'
	String get failedToLoadArticles => 'Failed to load articles';

	/// en: 'No articles yet'
	String get emptyArticlesTitle => 'No articles yet';

	/// en: 'Articles for this category will appear soon.'
	String get emptyArticlesSubtitle => 'Articles for this category will appear soon.';

	/// en: 'Premium content is available with Pro. Connect to the internet to upgrade.'
	String get upgradeRequiresInternet => 'Premium content is available with Pro. Connect to the internet to upgrade.';

	/// en: 'You can browse these article titles now. Unlock reading with Flymap Pro.'
	String get proListPreviewHint => 'You can browse these article titles now. Unlock reading with Flymap Pro.';

	/// en: 'Could not open this article right now.'
	String get failedToLoadArticle => 'Could not open this article right now.';

	/// en: 'Quizzes'
	String get quizzesTitle => 'Quizzes';

	/// en: 'Articles'
	String get articlesTitle => 'Articles';

	late final TranslationsLearnGeoQuizEn geoQuiz = TranslationsLearnGeoQuizEn.internal(_root);
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

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'Name, flying habits, home airport, and interests'
	String get profileSubtitle => 'Name, flying habits, home airport, and interests';

	/// en: '$name · $code'
	String profileSummaryNameHome({required Object name, required Object code}) => '${name} · ${code}';

	/// en: 'Home airport: $code'
	String profileSummaryHome({required Object code}) => 'Home airport: ${code}';

	/// en: 'Tap any item to edit your profile details.'
	String get profileEditHint => 'Tap any item to edit your profile details.';

	/// en: 'Not set'
	String get profileNotSet => 'Not set';

	/// en: '$count selected'
	String profileInterestsSelected({required Object count}) => '${count} selected';

	/// en: 'History'
	String get historyTitle => 'History';

	/// en: 'All flights and stats'
	String get historySubtitle => 'All flights and stats';

	/// en: 'Loading history...'
	String get historyLoading => 'Loading history...';

	/// en: 'Failed to load flight history.'
	String get historyLoadError => 'Failed to load flight history.';

	/// en: 'Total flights'
	String get historyFlightsLabel => 'Total flights';

	/// en: 'Total distance'
	String get historyDistanceLabel => 'Total distance';

	/// en: 'All flights'
	String get historyAllFlights => 'All flights';

	/// en: 'Upcoming'
	String get historyStatusUpcoming => 'Upcoming';

	/// en: 'In progress'
	String get historyStatusInProgress => 'In progress';

	/// en: 'Completed'
	String get historyStatusCompleted => 'Completed';

	/// en: 'Map $size'
	String historyMapChip({required Object size}) => 'Map ${size}';

	/// en: 'No map'
	String get historyNoMapChip => 'No map';

	/// en: 'Name'
	String get historySortName => 'Name';

	/// en: 'Distance'
	String get historySortDistance => 'Distance';

	/// en: 'Date'
	String get historySortDate => 'Date';

	/// en: 'No flights yet.'
	String get historyEmpty => 'No flights yet.';

	/// en: 'Search by airport or city'
	String get historySearchHint => 'Search by airport or city';

	/// en: 'No matching flights found.'
	String get historyNoResults => 'No matching flights found.';

	/// en: 'Delete map only'
	String get historyDeleteOfflineData => 'Delete map only';

	/// en: 'Appearance'
	String get appearance => 'Appearance';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'App language'
	String get languageSubtitle => 'App language';

	/// en: 'System'
	String get languageSystem => 'System';

	/// en: '${language} (System)'
	String languageSystemFormat({required Object language}) => '${language} (System)';

	/// en: 'English'
	String get languageEnglish => 'English';

	/// en: 'Español'
	String get languageSpanish => 'Español';

	/// en: 'Français'
	String get languageFrench => 'Français';

	/// en: 'Deutsch'
	String get languageGerman => 'Deutsch';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'System'
	String get system => 'System';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'Units'
	String get units => 'Units';

	late final TranslationsSettingsNotificationsEn notifications = TranslationsSettingsNotificationsEn.internal(_root);

	/// en: 'Storage'
	String get storage => 'Storage';

	/// en: 'Storage'
	String get storageTitle => 'Storage';

	/// en: 'Downloaded maps and disk usage'
	String get storageSubtitle => 'Downloaded maps and disk usage';

	/// en: 'Loading storage...'
	String get storageLoading => 'Loading storage...';

	/// en: 'Failed to load storage data.'
	String get storageLoadError => 'Failed to load storage data.';

	/// en: 'Downloaded maps'
	String get storageMapsLabel => 'Downloaded maps';

	/// en: 'Total size'
	String get storageTotalSizeLabel => 'Total size';

	/// en: 'Downloaded maps'
	String get storageDownloadedMaps => 'Downloaded maps';

	/// en: 'Name'
	String get storageSortName => 'Name';

	/// en: 'Size'
	String get storageSortSize => 'Size';

	/// en: 'Size: $size'
	String storageMapSize({required Object size}) => 'Size: ${size}';

	/// en: 'No downloaded maps yet.'
	String get storageEmpty => 'No downloaded maps yet.';

	/// en: 'Altitude'
	String get altitude => 'Altitude';

	/// en: 'Altitude unit'
	String get altitudeUnit => 'Altitude unit';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Speed unit'
	String get speedUnit => 'Speed unit';

	/// en: 'Temperature unit'
	String get temperatureUnit => 'Temperature unit';

	/// en: 'Time format'
	String get timeFormat => 'Time format';

	/// en: 'Distance unit'
	String get distanceUnit => 'Distance unit';

	/// en: 'Date format'
	String get dateFormat => 'Date format';

	/// en: 'Support'
	String get support => 'Support';

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

	/// en: 'Glad you're enjoying Flymap'
	String get advocacyDialogTitle => 'Glad you\'re enjoying Flymap';

	/// en: 'Help other travellers discover Flymap.'
	String get advocacyDialogBody => 'Help other travellers discover Flymap.';

	/// en: 'Share with friends'
	String get advocacyDialogShare => 'Share with friends';

	/// en: 'Rate Flymap'
	String get advocacyDialogRate => 'Rate Flymap';

	/// en: 'Not now'
	String get advocacyDialogNotNow => 'Not now';

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

	/// en: 'Real routes, offline maps, weather, places and stories unlocked.'
	String get proBannerSubtitleActive => 'Real routes, offline maps, weather, places and stories unlocked.';

	/// en: 'Unlock real routes, offline maps, weather, places and stories'
	String get proBannerSubtitleFree => 'Unlock real routes, offline maps, weather, places and stories';

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

	/// en: 'Contact support'
	String get contactSupport => 'Contact support';

	/// en: 'Flymap Pro'
	String get cardTitle => 'Flymap Pro';

	/// en: 'Subscription period'
	String get periodTitle => 'Subscription period';

	/// en: 'Renews or expires'
	String get renewsOrExpires => 'Renews or expires';

	/// en: 'No expiration'
	String get noExpiration => 'No expiration';

	/// en: 'Last checked'
	String get lastChecked => 'Last checked';

	/// en: 'Unlock Pro features'
	String get flightUnlockSheetTitle => 'Unlock Pro features';

	/// en: 'One-time purchase'
	String get flightUnlockOptionTitle => 'One-time purchase';

	/// en: 'Unlock Pro for a single flight'
	String get flightUnlockOptionBody => 'Unlock Pro for a single flight';

	/// en: 'Buy for one Flight'
	String get flightUnlockAction => 'Buy for one Flight';

	/// en: 'Use for one Flight'
	String get flightUnlockUseAction => 'Use for one Flight';

	/// en: 'Loading price...'
	String get flightUnlockPriceLoading => 'Loading price...';

	/// en: 'Flymap Pro subscription'
	String get flightUnlockProOptionTitle => 'Flymap Pro subscription';

	/// en: '$count flight unlocks available'
	String flightUnlockAvailableCount({required Object count}) => '${count} flight unlocks available';

	/// en: 'Unlock Pro for unlimited flights'
	String get flightUnlockProOptionBody => 'Unlock Pro for unlimited flights';

	/// en: 'View Pro Plans'
	String get flightUnlockProAction => 'View Pro Plans';

	/// en: 'Flight unlock is not available right now.'
	String get flightUnlockUnavailable => 'Flight unlock is not available right now.';

	/// en: 'Flight unlock purchase cancelled.'
	String get flightUnlockPurchaseCancelled => 'Flight unlock purchase cancelled.';

	/// en: 'Flight unlock purchase failed. Please try again.'
	String get flightUnlockPurchaseFailed => 'Flight unlock purchase failed. Please try again.';

	/// en: 'What Flymap Pro unlocks'
	String get proFeaturesTitle => 'What Flymap Pro unlocks';

	/// en: 'Included with your Pro plan'
	String get proFeaturesIncludedTitle => 'Included with your Pro plan';

	/// en: 'Your window seat, fully unlocked.'
	String get proHeroSubtitle => 'Your window seat, fully unlocked.';

	/// en: 'Recent real-world flight routes'
	String get proFeatureRoutesTitle => 'Recent real-world flight routes';

	/// en: 'Follow a recent recorded path instead of an approximate arc.'
	String get proFeatureRoutesBody => 'Follow a recent recorded path instead of an approximate arc.';

	/// en: 'Higher-detail maps, available offline'
	String get proFeatureMapsTitle => 'Higher-detail maps, available offline';

	/// en: 'Keep richer maps ready in the air without internet.'
	String get proFeatureMapsBody => 'Keep richer maps ready in the air without internet.';

	/// en: 'Full timeline and 10× more places'
	String get proFeatureTimelineTitle => 'Full timeline and 10× more places';

	/// en: 'See every region and more landmarks along your route.'
	String get proFeatureTimelineBody => 'See every region and more landmarks along your route.';

	/// en: 'Cloud cover and airport forecasts'
	String get proFeatureWeatherTitle => 'Cloud cover and airport forecasts';

	/// en: 'Know what you may see before takeoff.'
	String get proFeatureWeatherBody => 'Know what you may see before takeoff.';

	/// en: '10x more places on route'
	String get proFeaturePoiTitle => '10x more places on route';

	/// en: 'Complete offline article packs'
	String get proFeatureArticlesTitle => 'Complete offline article packs';

	/// en: 'Full Learn and Geo Quiz access'
	String get proFeatureLearnTitle => 'Full Learn and Geo Quiz access';

	/// en: 'Explore every story and geography challenge.'
	String get proFeatureLearnBody => 'Explore every story and geography challenge.';

	/// en: 'Plan & billing'
	String get planAndBillingTitle => 'Plan & billing';

	/// en: 'Plan'
	String get planLabel => 'Plan';

	/// en: 'Active subscription'
	String get activeSubscription => 'Active subscription';

	/// en: 'Current period ends $date'
	String currentPeriodEnds({required Object date}) => 'Current period ends ${date}';

	/// en: 'Manage plan & billing'
	String get managePlanAndBilling => 'Manage plan & billing';

	/// en: 'Cancel subscription'
	String get cancelSubscription => 'Cancel subscription';

	/// en: 'Before you cancel, the App Store or Google Play will show when your Pro access ends.'
	String get cancellationHelper => 'Before you cancel, the App Store or Google Play will show when your Pro access ends.';

	/// en: 'Flight passes'
	String get flightPassesTitle => 'Flight passes';

	/// en: 'These one-flight unlocks stay available for future flights.'
	String get flightPassesBody => 'These one-flight unlocks stay available for future flights.';

	/// en: 'Purchase help'
	String get purchaseHelpTitle => 'Purchase help';

	/// en: 'Checking your subscription status...'
	String get checkingStatus => 'Checking your subscription status...';

	/// en: 'You are on Free plan.'
	String get freePlan => 'You are on Free plan.';

	/// en: 'Active'
	String get active => 'Active';

	/// en: 'Not active'
	String get notActive => 'Not active';

	/// en: 'Unknown'
	String get unknown => 'Unknown';

	/// en: 'Manage subscription'
	String get manageSubscription => 'Manage subscription';

	/// en: 'Restore purchases'
	String get restorePurchases => 'Restore purchases';

	/// en: 'Upgrade to Pro'
	String get upgradeToPro => 'Upgrade to Pro';

	/// en: 'No active subscription found.'
	String get restoreNoSubscription => 'No active subscription found.';

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
	late final TranslationsCreateFlightWeatherEn weather = TranslationsCreateFlightWeatherEn.internal(_root);
	late final TranslationsCreateFlightRouteTypeSelectorEn routeTypeSelector = TranslationsCreateFlightRouteTypeSelectorEn.internal(_root);
	late final TranslationsCreateFlightProAccessEn proAccess = TranslationsCreateFlightProAccessEn.internal(_root);
	late final TranslationsCreateFlightTravelDateEn travelDate = TranslationsCreateFlightTravelDateEn.internal(_root);
	late final TranslationsCreateFlightFlightNumberSearchEn flightNumberSearch = TranslationsCreateFlightFlightNumberSearchEn.internal(_root);
	late final TranslationsCreateFlightRealRouteAirportSearchEn realRouteAirportSearch = TranslationsCreateFlightRealRouteAirportSearchEn.internal(_root);
	late final TranslationsCreateFlightSearchEn search = TranslationsCreateFlightSearchEn.internal(_root);
	late final TranslationsCreateFlightMapPreviewEn mapPreview = TranslationsCreateFlightMapPreviewEn.internal(_root);
	late final TranslationsCreateFlightOverviewEn overview = TranslationsCreateFlightOverviewEn.internal(_root);
	late final TranslationsCreateFlightWikipediaEn wikipedia = TranslationsCreateFlightWikipediaEn.internal(_root);
	late final TranslationsCreateFlightDownloadingEn downloading = TranslationsCreateFlightDownloadingEn.internal(_root);
	late final TranslationsCreateFlightErrorsEn errors = TranslationsCreateFlightErrorsEn.internal(_root);
	late final TranslationsCreateFlightPaywallEn paywall = TranslationsCreateFlightPaywallEn.internal(_root);
	late final TranslationsCreateFlightRealRouteChoiceEn realRouteChoice = TranslationsCreateFlightRealRouteChoiceEn.internal(_root);
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

	/// en: 'Congrats! You are all set.'
	String get downloadCongratsTitle => 'Congrats! You are all set.';

	/// en: 'Map and selected flight data are saved for offline use during your flight.'
	String get offlineSavedDetail => 'Map and selected flight data are saved for offline use during your flight.';

	/// en: 'Download completed'
	String get downloadCompletedTitle => 'Download completed';

	/// en: 'Show off your awesome flight'
	String get shareFlightCard => 'Show off your awesome flight';

	/// en: 'Share flight video'
	String get shareVideo => 'Share flight video';

	/// en: 'Share flight card'
	String get share => 'Share flight card';

	/// en: 'Home'
	String get home => 'Home';

	/// en: 'Navigating to home...'
	String get navigatingHome => 'Navigating to home...';

	/// en: 'Downloading assets'
	String get downloadingMapTitle => 'Downloading assets';

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

	/// en: 'Camera'
	String get tabCamera => 'Camera';

	/// en: 'Info'
	String get tabInfo => 'Info';

	late final TranslationsFlightHubEn hub = TranslationsFlightHubEn.internal(_root);

	/// en: 'Complete flight?'
	String get completeDialogTitle => 'Complete flight?';

	/// en: 'This marks your flight as completed.'
	String get completeDialogBody => 'This marks your flight as completed.';

	/// en: 'Delete map and offline articles'
	String get completeDialogDeleteOffline => 'Delete map and offline articles';

	/// en: 'Complete'
	String get completeDialogConfirm => 'Complete';

	/// en: 'Are you sure?'
	String get deleteDialogTitle => 'Are you sure?';

	/// en: 'This permanently deletes this flight, including offline map and saved offline articles. Space to be regained: $size.'
	String deleteDialogMessage({required Object size}) => 'This permanently deletes this flight, including offline map and saved offline articles.\n\nSpace to be regained: ${size}.';

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
	late final TranslationsFlightUpcomingEn upcoming = TranslationsFlightUpcomingEn.internal(_root);
	late final TranslationsFlightInfoEn info = TranslationsFlightInfoEn.internal(_root);
	late final TranslationsFlightRouteEn route = TranslationsFlightRouteEn.internal(_root);
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

	/// en: 'Route'
	String get route => 'Route';

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

// Path: shareImage
class TranslationsShareImageEn {
	TranslationsShareImageEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Share flight'
	String get title => 'Share flight';

	/// en: 'Creating your flight card...'
	String get generating => 'Creating your flight card...';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Sharing...'
	String get sharing => 'Sharing...';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Could not generate flight card'
	String get error => 'Could not generate flight card';

	/// en: 'Every flight is a discovery'
	String get tagline => 'Every flight is a discovery';

	/// en: 'Flymap'
	String get brand => 'Flymap';

	/// en: 'Explore your flight'
	String get exploreYourFlight => 'Explore your flight';

	/// en: '1 country'
	String get countrySingle => '1 country';

	/// en: '$count countries'
	String countries({required Object count}) => '${count} countries';

	/// en: '$fromCity ($fromCode) → $toCity ($toCode) on Flymap ✈️'
	String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) on Flymap ✈️';

	/// en: 'Unknown'
	String get unknownCity => 'Unknown';

	/// en: '--'
	String get durationUnavailable => '--';

	/// en: '$minutes m'
	String durationMinutes({required Object minutes}) => '${minutes} m';

	/// en: '$hours h $minutes m'
	String durationHoursMinutes({required Object hours, required Object minutes}) => '${hours} h ${minutes} m';
}

// Path: flightVideo
class TranslationsFlightVideoEn {
	TranslationsFlightVideoEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flight video'
	String get title => 'Flight video';

	/// en: 'Preparing your map...'
	String get preparing => 'Preparing your map...';

	/// en: 'Creating your video...'
	String get rendering => 'Creating your video...';

	/// en: 'Save video'
	String get export => 'Save video';

	/// en: 'Saved to your camera roll'
	String get savedToGallery => 'Saved to your camera roll';

	/// en: 'Couldn't save to camera roll — you can still share it'
	String get saveSkipped => 'Couldn\'t save to camera roll — you can still share it';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Sharing...'
	String get sharing => 'Sharing...';

	/// en: 'Retry'
	String get retry => 'Retry';

	/// en: 'Couldn't load map imagery. Check your connection and try again.'
	String get errorNetwork => 'Couldn\'t load map imagery. Check your connection and try again.';

	/// en: 'Could not create flight video'
	String get errorGeneric => 'Could not create flight video';

	/// en: 'You're offline'
	String get errorOfflineTitle => 'You\'re offline';

	/// en: 'Flight videos load live map imagery, so they need an internet connection. Turn off Flight Mode or reconnect, then try again.'
	String get errorOffline => 'Flight videos load live map imagery, so they need an internet connection. Turn off Flight Mode or reconnect, then try again.';

	/// en: 'Changing the map style needs a connection.'
	String get offlineStyleChange => 'Changing the map style needs a connection.';

	/// en: 'Made with Flymap'
	String get madeWith => 'Made with Flymap';

	/// en: '$fromCity ($fromCode) → $toCity ($toCode) on Flymap ✈️'
	String shareText({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) on Flymap ✈️';

	/// en: 'Remove watermark'
	String get removeWatermark => 'Remove watermark';

	/// en: 'Satellite'
	String get styleSatellite => 'Satellite';

	/// en: 'Default'
	String get styleDefault => 'Default';

	/// en: 'Video settings'
	String get videoSettings => 'Video settings';

	/// en: 'Map style'
	String get mapStyle => 'Map style';

	/// en: 'Mystery destination'
	String get mysteryDestination => 'Mystery destination';

	/// en: 'Show "?" until the plane lands'
	String get mysteryDestinationHint => 'Show "?" until the plane lands';

	/// en: 'Country pins'
	String get showPins => 'Country pins';

	/// en: 'Drop a pin as the plane crosses each country'
	String get showPinsHint => 'Drop a pin as the plane crosses each country';

	/// en: 'Summary card'
	String get showEndCard => 'Summary card';

	/// en: 'Show the summary card at the end'
	String get showEndCardHint => 'Show the summary card at the end';

	/// en: 'Lè Shine'
	String get styleShine => 'Lè Shine';

	/// en: 'Apply changes'
	String get applySettings => 'Apply changes';

	/// en: 'Applying changes...'
	String get applying => 'Applying changes...';

	/// en: 'Your avatar'
	String get avatarTitle => 'Your avatar';

	/// en: 'Ride your route with your own photo'
	String get avatarHint => 'Ride your route with your own photo';

	/// en: 'Your avatar'
	String get avatarSetupTitle => 'Your avatar';

	/// en: 'Choose photo'
	String get avatarPick => 'Choose photo';

	/// en: 'Change photo'
	String get avatarChange => 'Change photo';

	/// en: 'Name or @handle'
	String get avatarNameLabel => 'Name or @handle';

	/// en: 'Optional — shown on the summary card'
	String get avatarNameHint => 'Optional — shown on the summary card';

	/// en: 'Save avatar'
	String get avatarSave => 'Save avatar';

	/// en: 'Guess where I'm flying? ✈️'
	String get mysteryTitle => 'Guess where I\'m flying? ✈️';

	/// en: 'My flight map'
	String get avatarCardTagline => 'My flight map';
}

// Path: about
class TranslationsAboutEn {
	TranslationsAboutEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'About Flymap'
	String get title => 'About Flymap';

	/// en: 'Turn every flight into a window on the world.'
	String get tagline => 'Turn every flight into a window on the world.';

	/// en: 'Curiosity'
	String get chipCuriosity => 'Curiosity';

	/// en: 'Geography'
	String get chipGeography => 'Geography';

	/// en: 'Awareness'
	String get chipAwareness => 'Awareness';

	/// en: 'Why Flymap'
	String get missionTitle => 'Why Flymap';

	/// en: 'We fly over oceans, mountains and whole countries without ever knowing. Flymap brings back the wonder.'
	String get missionText => 'We fly over oceans, mountains and whole countries without ever knowing. Flymap brings back the wonder.';

	/// en: 'What we stand for'
	String get valuesTitle => 'What we stand for';

	/// en: 'Curiosity'
	String get valueCuriosityTitle => 'Curiosity';

	/// en: 'Always know what's below you.'
	String get valueCuriosityText => 'Always know what\'s below you.';

	/// en: 'Geography'
	String get valueGeographyTitle => 'Geography';

	/// en: 'The world becomes a living atlas.'
	String get valueGeographyText => 'The world becomes a living atlas.';

	/// en: 'Awareness'
	String get valueAwarenessTitle => 'Awareness';

	/// en: 'Reconnect with the journey itself.'
	String get valueAwarenessText => 'Reconnect with the journey itself.';

	/// en: 'Offline & private'
	String get valueOfflineTitle => 'Offline & private';

	/// en: 'On your device. Nothing tracked.'
	String get valueOfflineText => 'On your device. Nothing tracked.';

	/// en: 'See the world differently'
	String get closingTitle => 'See the world differently';

	/// en: 'Thank you for exploring it with us.'
	String get closingText => 'Thank you for exploring it with us.';
}

// Path: notifications
class TranslationsNotificationsEn {
	TranslationsNotificationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Your flight forecast is ready'
	String get forecastReadyTitle => 'Your flight forecast is ready';

	/// en: 'Sun or rain at takeoff? Clear views on the way? Your first $route forecast is in.'
	String forecastReadyBody({required Object route}) => 'Sun or rain at takeoff? Clear views on the way? Your first ${route} forecast is in.';

	/// en: 'Your flight is tomorrow'
	String get forecastUpdatedTitle => 'Your flight is tomorrow';

	/// en: '$route — open Flymap for the latest forecast.'
	String forecastUpdatedBody({required Object route}) => '${route} — open Flymap for the latest forecast.';

	/// en: 'Your flight is coming up'
	String get reminderEarlyTitle => 'Your flight is coming up';

	/// en: '$route is just a few days away — open the app to explore what you'll fly over.'
	String reminderEarlyBody({required Object route}) => '${route} is just a few days away — open the app to explore what you\'ll fly over.';

	/// en: 'Your flight is tomorrow'
	String get reminderTomorrowTitle => 'Your flight is tomorrow';

	/// en: '$route tomorrow — don't forget to open the app in the air and explore everything you fly over.'
	String reminderTomorrowBody({required Object route}) => '${route} tomorrow — don\'t forget to open the app in the air and explore everything you fly over.';
}

// Path: onboarding
class TranslationsOnboardingEn {
	TranslationsOnboardingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Skip'
	String get skip => 'Skip';

	/// en: 'Let's start'
	String get letsStart => 'Let\'s start';

	/// en: 'Discover what’s below'
	String get welcomeTitle => 'Discover what’s below';

	/// en: 'shows you offline maps and interesting places along your flight'
	String get welcomeSubtitle => 'shows you offline maps and interesting places along your flight';

	/// en: 'Pick a username'
	String get nameTitle => 'Pick a username';

	/// en: 'Make discovery personal. You can change it anytime.'
	String get nameSubtitle => 'Make discovery personal. You can change it anytime.';

	/// en: 'Your name'
	String get nameHint => 'Your name';

	/// en: 'Alex'
	String get nameExample => 'Alex';

	/// en: 'How often do you fly?'
	String get frequencyTitle => 'How often do you fly?';

	/// en: 'Flymap will personalize your experience and make suggestions more relevant'
	String get frequencySubtitle => 'Flymap will personalize your experience and make suggestions more relevant';

	/// en: 'This is my first flight'
	String get frequencyFirstFlight => 'This is my first flight';

	/// en: 'A few times a year'
	String get frequencyFewPerYear => 'A few times a year';

	/// en: 'About monthly'
	String get frequencyMonthly => 'About monthly';

	/// en: 'Very often'
	String get frequencyFrequent => 'Very often';

	/// en: 'Set your home airport'
	String get homeAirportTitle => 'Set your home airport';

	/// en: 'Get faster flight setup. You can change it anytime.'
	String get homeAirportSubtitle => 'Get faster flight setup. You can change it anytime.';

	/// en: 'Search home airport'
	String get homeAirportHint => 'Search home airport';

	/// en: 'Popular airports'
	String get popularAirports => 'Popular airports';

	/// en: 'Remove home airport'
	String get removeHomeAirport => 'Remove home airport';

	/// en: 'No airports found for that search.'
	String get noHomeAirportFound => 'No airports found for that search.';

	/// en: 'Which places do you want to see more of on your map?'
	String get interestsTitle => 'Which places do you want to see more of on your map?';

	/// en: 'Choose up to 3 topics to see more relevant places and stories along your flight.'
	String get interestsSubtitle => 'Choose up to 3 topics to see more relevant places and stories along your flight.';

	/// en: 'Pick up to 3 topics.'
	String get interestsHelper => 'Pick up to 3 topics.';

	/// en: '$count of $max selected'
	String interestsSelected({required Object count, required Object max}) => '${count} of ${max} selected';

	/// en: 'Mountains & ridges'
	String get interestMountains => 'Mountains & ridges';

	/// en: 'Volcanoes & geology'
	String get interestVolcanoes => 'Volcanoes & geology';

	/// en: 'Cities & regions'
	String get interestRegions => 'Cities & regions';

	/// en: 'Islands & coastlines'
	String get interestIslands => 'Islands & coastlines';

	/// en: 'National parks & reserves'
	String get interestNationalParks => 'National parks & reserves';

	/// en: 'Rivers & lakes'
	String get interestRivers => 'Rivers & lakes';

	/// en: 'Start my first flight'
	String get planFirstFlight => 'Start my first flight';

	/// en: 'Failed to load your profile.'
	String get failedLoadProfile => 'Failed to load your profile.';

	late final TranslationsOnboardingPayoffEn payoff = TranslationsOnboardingPayoffEn.internal(_root);
	late final TranslationsOnboardingWeatherPayoffEn weatherPayoff = TranslationsOnboardingWeatherPayoffEn.internal(_root);
}

// Path: countries
class TranslationsCountriesEn {
	TranslationsCountriesEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'United Arab Emirates'
	String get AE => 'United Arab Emirates';

	/// en: 'Afghanistan'
	String get AF => 'Afghanistan';

	/// en: 'Antigua and Barbuda'
	String get AG => 'Antigua and Barbuda';

	/// en: 'Albania'
	String get AL => 'Albania';

	/// en: 'Armenia'
	String get AM => 'Armenia';

	/// en: 'Angola'
	String get AO => 'Angola';

	/// en: 'Argentina'
	String get AR => 'Argentina';

	/// en: 'Austria'
	String get AT => 'Austria';

	/// en: 'Australia'
	String get AU => 'Australia';

	/// en: 'Azerbaijan'
	String get AZ => 'Azerbaijan';

	/// en: 'Bosnia and Herzegovina'
	String get BA => 'Bosnia and Herzegovina';

	/// en: 'Barbados'
	String get BB => 'Barbados';

	/// en: 'Bangladesh'
	String get BD => 'Bangladesh';

	/// en: 'Belgium'
	String get BE => 'Belgium';

	/// en: 'Burkina Faso'
	String get BF => 'Burkina Faso';

	/// en: 'Bulgaria'
	String get BG => 'Bulgaria';

	/// en: 'Bahrain'
	String get BH => 'Bahrain';

	/// en: 'Burundi'
	String get BI => 'Burundi';

	/// en: 'Benin'
	String get BJ => 'Benin';

	/// en: 'Brunei Darussalam'
	String get BN => 'Brunei Darussalam';

	/// en: 'Bolivia'
	String get BO => 'Bolivia';

	/// en: 'Brazil'
	String get BR => 'Brazil';

	/// en: 'Bahamas'
	String get BS => 'Bahamas';

	/// en: 'Bhutan'
	String get BT => 'Bhutan';

	/// en: 'Botswana'
	String get BW => 'Botswana';

	/// en: 'Belarus'
	String get BY => 'Belarus';

	/// en: 'Belize'
	String get BZ => 'Belize';

	/// en: 'Canada'
	String get CA => 'Canada';

	/// en: 'Congo, Democratic Republic of the'
	String get CD => 'Congo, Democratic Republic of the';

	/// en: 'Central African Republic'
	String get CF => 'Central African Republic';

	/// en: 'Congo'
	String get CG => 'Congo';

	/// en: 'Switzerland'
	String get CH => 'Switzerland';

	/// en: 'Côte d'Ivoire'
	String get CI => 'Côte d\'Ivoire';

	/// en: 'Chile'
	String get CL => 'Chile';

	/// en: 'Cameroon'
	String get CM => 'Cameroon';

	/// en: 'China'
	String get CN => 'China';

	/// en: 'Colombia'
	String get CO => 'Colombia';

	/// en: 'Costa Rica'
	String get CR => 'Costa Rica';

	/// en: 'Cuba'
	String get CU => 'Cuba';

	/// en: 'Cape Verde'
	String get CV => 'Cape Verde';

	/// en: 'Cyprus'
	String get CY => 'Cyprus';

	/// en: 'Czech Republic'
	String get CZ => 'Czech Republic';

	/// en: 'Germany'
	String get DE => 'Germany';

	/// en: 'Djibouti'
	String get DJ => 'Djibouti';

	/// en: 'Denmark'
	String get DK => 'Denmark';

	/// en: 'Dominican Republic'
	String get DO => 'Dominican Republic';

	/// en: 'Algeria'
	String get DZ => 'Algeria';

	/// en: 'Ecuador'
	String get EC => 'Ecuador';

	/// en: 'Estonia'
	String get EE => 'Estonia';

	/// en: 'Egypt'
	String get EG => 'Egypt';

	/// en: 'Western Sahara'
	String get EH => 'Western Sahara';

	/// en: 'Eritrea'
	String get ER => 'Eritrea';

	/// en: 'Spain'
	String get ES => 'Spain';

	/// en: 'Ethiopia'
	String get ET => 'Ethiopia';

	/// en: 'Finland'
	String get FI => 'Finland';

	/// en: 'Fiji'
	String get FJ => 'Fiji';

	/// en: 'France'
	String get FR => 'France';

	/// en: 'Gabon'
	String get GA => 'Gabon';

	/// en: 'United Kingdom'
	String get GB => 'United Kingdom';

	/// en: 'Georgia'
	String get GE => 'Georgia';

	/// en: 'French Guiana'
	String get GF => 'French Guiana';

	/// en: 'Ghana'
	String get GH => 'Ghana';

	/// en: 'Gambia'
	String get GM => 'Gambia';

	/// en: 'Guinea'
	String get GN => 'Guinea';

	/// en: 'Guadeloupe'
	String get GP => 'Guadeloupe';

	/// en: 'Equatorial Guinea'
	String get GQ => 'Equatorial Guinea';

	/// en: 'Greece'
	String get GR => 'Greece';

	/// en: 'Guatemala'
	String get GT => 'Guatemala';

	/// en: 'Guinea-Bissau'
	String get GW => 'Guinea-Bissau';

	/// en: 'Guyana'
	String get GY => 'Guyana';

	/// en: 'Hong Kong, China'
	String get HK => 'Hong Kong, China';

	/// en: 'Honduras'
	String get HN => 'Honduras';

	/// en: 'Croatia'
	String get HR => 'Croatia';

	/// en: 'Haiti'
	String get HT => 'Haiti';

	/// en: 'Hungary'
	String get HU => 'Hungary';

	/// en: 'Indonesia'
	String get ID => 'Indonesia';

	/// en: 'Ireland'
	String get IE => 'Ireland';

	/// en: 'Israel'
	String get IL => 'Israel';

	/// en: 'India'
	String get IN => 'India';

	/// en: 'Iraq'
	String get IQ => 'Iraq';

	/// en: 'Iran, Islamic Rep. of'
	String get IR => 'Iran, Islamic Rep. of';

	/// en: 'Iceland'
	String get IS => 'Iceland';

	/// en: 'Italy'
	String get IT => 'Italy';

	/// en: 'Jamaica'
	String get JM => 'Jamaica';

	/// en: 'Jordan'
	String get JO => 'Jordan';

	/// en: 'Japan'
	String get JP => 'Japan';

	/// en: 'Kenya'
	String get KE => 'Kenya';

	/// en: 'Kyrgyzstan'
	String get KG => 'Kyrgyzstan';

	/// en: 'Cambodia'
	String get KH => 'Cambodia';

	/// en: 'Comoros'
	String get KM => 'Comoros';

	/// en: 'Korea, Dem. People's Rep. of'
	String get KP => 'Korea, Dem. People\'s Rep. of';

	/// en: 'Korea, Republic of'
	String get KR => 'Korea, Republic of';

	/// en: 'Kuwait'
	String get KW => 'Kuwait';

	/// en: 'Kazakhstan'
	String get KZ => 'Kazakhstan';

	/// en: 'Lao People's Dem. Rep.'
	String get LA => 'Lao People\'s Dem. Rep.';

	/// en: 'Lebanon'
	String get LB => 'Lebanon';

	/// en: 'Sri Lanka'
	String get LK => 'Sri Lanka';

	/// en: 'Liberia'
	String get LR => 'Liberia';

	/// en: 'Lesotho'
	String get LS => 'Lesotho';

	/// en: 'Lithuania'
	String get LT => 'Lithuania';

	/// en: 'Luxembourg'
	String get LU => 'Luxembourg';

	/// en: 'Latvia'
	String get LV => 'Latvia';

	/// en: 'Libyan Arab Jamahiriya'
	String get LY => 'Libyan Arab Jamahiriya';

	/// en: 'Morocco'
	String get MA => 'Morocco';

	/// en: 'Moldova, Republic of'
	String get MD => 'Moldova, Republic of';

	/// en: 'Montenegro'
	String get ME => 'Montenegro';

	/// en: 'Madagascar'
	String get MG => 'Madagascar';

	/// en: 'Macedonia, The former Yugoslav Rep. of'
	String get MK => 'Macedonia, The former Yugoslav Rep. of';

	/// en: 'Mali'
	String get ML => 'Mali';

	/// en: 'Myanmar'
	String get MM => 'Myanmar';

	/// en: 'Mongolia'
	String get MN => 'Mongolia';

	/// en: 'Macau, China'
	String get MO => 'Macau, China';

	/// en: 'Martinique'
	String get MQ => 'Martinique';

	/// en: 'Mauritania'
	String get MR => 'Mauritania';

	/// en: 'Mauritius'
	String get MU => 'Mauritius';

	/// en: 'Maldives'
	String get MV => 'Maldives';

	/// en: 'Malawi'
	String get MW => 'Malawi';

	/// en: 'Malta'
	String get MT => 'Malta';

	/// en: 'Mexico'
	String get MX => 'Mexico';

	/// en: 'Malaysia'
	String get MY => 'Malaysia';

	/// en: 'Mozambique'
	String get MZ => 'Mozambique';

	/// en: 'Namibia'
	String get NA => 'Namibia';

	/// en: 'New Caledonia'
	String get NC => 'New Caledonia';

	/// en: 'Niger'
	String get NE => 'Niger';

	/// en: 'Nigeria'
	String get NG => 'Nigeria';

	/// en: 'Nicaragua'
	String get NI => 'Nicaragua';

	/// en: 'Netherlands'
	String get NL => 'Netherlands';

	/// en: 'Norway'
	String get NO => 'Norway';

	/// en: 'Nepal'
	String get NP => 'Nepal';

	/// en: 'New Zealand'
	String get NZ => 'New Zealand';

	/// en: 'Oman'
	String get OM => 'Oman';

	/// en: 'Panama'
	String get PA => 'Panama';

	/// en: 'Peru'
	String get PE => 'Peru';

	/// en: 'Papua New Guinea'
	String get PG => 'Papua New Guinea';

	/// en: 'Philippines'
	String get PH => 'Philippines';

	/// en: 'Pakistan'
	String get PK => 'Pakistan';

	/// en: 'Poland'
	String get PL => 'Poland';

	/// en: 'Puerto Rico'
	String get PR => 'Puerto Rico';

	/// en: 'West Bank and Gaza Strip'
	String get PS => 'West Bank and Gaza Strip';

	/// en: 'Portugal'
	String get PT => 'Portugal';

	/// en: 'Paraguay'
	String get PY => 'Paraguay';

	/// en: 'Qatar'
	String get QA => 'Qatar';

	/// en: 'Réunion'
	String get RE => 'Réunion';

	/// en: 'Romania'
	String get RO => 'Romania';

	/// en: 'Serbia'
	String get RS => 'Serbia';

	/// en: 'Russian Federation'
	String get RU => 'Russian Federation';

	/// en: 'Rwanda'
	String get RW => 'Rwanda';

	/// en: 'Saudi Arabia'
	String get SA => 'Saudi Arabia';

	/// en: 'Solomon Islands'
	String get SB => 'Solomon Islands';

	/// en: 'Sudan, The Republic of'
	String get SD => 'Sudan, The Republic of';

	/// en: 'Sweden'
	String get SE => 'Sweden';

	/// en: 'Singapore'
	String get SG => 'Singapore';

	/// en: 'Slovenia'
	String get SI => 'Slovenia';

	/// en: 'Slovakia'
	String get SK => 'Slovakia';

	/// en: 'Sierra Leone'
	String get SL => 'Sierra Leone';

	/// en: 'Senegal'
	String get SN => 'Senegal';

	/// en: 'Somalia'
	String get SO => 'Somalia';

	/// en: 'Suriname'
	String get SR => 'Suriname';

	/// en: 'South Sudan, The Republic of'
	String get SS => 'South Sudan, The Republic of';

	/// en: 'Sao Tome and Principe'
	String get ST => 'Sao Tome and Principe';

	/// en: 'El Salvador'
	String get SV => 'El Salvador';

	/// en: 'Syrian Arab Republic'
	String get SY => 'Syrian Arab Republic';

	/// en: 'Swaziland'
	String get SZ => 'Swaziland';

	/// en: 'Chad'
	String get TD => 'Chad';

	/// en: 'Togo'
	String get TG => 'Togo';

	/// en: 'Thailand'
	String get TH => 'Thailand';

	/// en: 'Tajikistan'
	String get TJ => 'Tajikistan';

	/// en: 'Timor-Leste'
	String get TL => 'Timor-Leste';

	/// en: 'Turkmenistan'
	String get TM => 'Turkmenistan';

	/// en: 'Tunisia'
	String get TN => 'Tunisia';

	/// en: 'Turkey'
	String get TR => 'Turkey';

	/// en: 'Trinidad and Tobago'
	String get TT => 'Trinidad and Tobago';

	/// en: 'Taiwan, China'
	String get TW => 'Taiwan, China';

	/// en: 'Tanzania, United Republic of'
	String get TZ => 'Tanzania, United Republic of';

	/// en: 'Ukraine'
	String get UA => 'Ukraine';

	/// en: 'Uganda'
	String get UG => 'Uganda';

	/// en: 'United States'
	String get US => 'United States';

	/// en: 'Uruguay'
	String get UY => 'Uruguay';

	/// en: 'Uzbekistan'
	String get UZ => 'Uzbekistan';

	/// en: 'Venezuela, Bolivarian Rep. of'
	String get VE => 'Venezuela, Bolivarian Rep. of';

	/// en: 'Virgin Islands (US)'
	String get VI => 'Virgin Islands (US)';

	/// en: 'Viet Nam'
	String get VN => 'Viet Nam';

	/// en: 'Yemen'
	String get YE => 'Yemen';

	/// en: 'South Africa'
	String get ZA => 'South Africa';

	/// en: 'Zambia'
	String get ZM => 'Zambia';

	/// en: 'Zimbabwe'
	String get ZW => 'Zimbabwe';
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

// Path: learn.geoQuiz
class TranslationsLearnGeoQuizEn {
	TranslationsLearnGeoQuizEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Geo Quiz'
	String get title => 'Geo Quiz';

	/// en: 'Geography'
	String get geographyTitle => 'Geography';

	/// en: 'Seas, mountain ranges, lakes, islands, and more'
	String get geographySubtitle => 'Seas, mountain ranges, lakes, islands, and more';

	/// en: 'Countries on map'
	String get countriesTitle => 'Countries on map';

	/// en: 'Guess the country from its outline'
	String get subtitle => 'Guess the country from its outline';

	/// en: 'Loading Geo Quiz...'
	String get loading => 'Loading Geo Quiz...';

	/// en: 'Failed to load quizzes'
	String get failedToLoad => 'Failed to load quizzes';

	/// en: 'Failed to load quiz'
	String get failedToLoadQuiz => 'Failed to load quiz';

	/// en: 'No quizzes yet'
	String get emptyTitle => 'No quizzes yet';

	/// en: 'Geo quizzes will appear here soon.'
	String get emptySubtitle => 'Geo quizzes will appear here soon.';

	/// en: 'Region name...'
	String get countryHint => 'Region name...';

	/// en: '$solved / $total'
	String progressCount({required Object solved, required Object total}) => '${solved} / ${total}';

	/// en: '$next of $total'
	String nextCount({required Object next, required Object total}) => '${next} of ${total}';

	/// en: '$count correct'
	String correctCount({required Object count}) => '${count} correct';

	/// en: 'Reset progress'
	String get reset => 'Reset progress';

	/// en: 'Map data will be added next'
	String get mapPlaceholder => 'Map data will be added next';

	/// en: 'NEW'
	String get newBadge => 'NEW';

	/// en: 'Correct'
	String get correct => 'Correct';

	/// en: 'Wrong'
	String get wrong => 'Wrong';

	/// en: 'Hint'
	String get hintTitle => 'Hint';

	/// en: 'Tap on a letter to reveal'
	String get hintSubtitle => 'Tap on a letter to reveal';

	/// en: 'Next'
	String get next => 'Next';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Resume'
	String get resume => 'Resume';

	/// en: 'Finish'
	String get finish => 'Finish';

	/// en: 'Quiz complete'
	String get completeTitle => 'Quiz complete';

	/// en: 'You found all $total countries in $quiz.'
	String completeMessage({required Object total, required Object quiz}) => 'You found all ${total} countries in ${quiz}.';

	/// en: 'Back to quizzes'
	String get backToQuizzes => 'Back to quizzes';

	/// en: 'Play again'
	String get playAgain => 'Play again';

	/// en: 'Ready to play'
	String get progressReady => 'Ready to play';

	/// en: '$count finished'
	String progressFinished({required Object count}) => '${count} finished';

	/// en: '$count in progress'
	String progressInProgress({required Object count}) => '${count} in progress';

	/// en: 'All completed'
	String get progressAllCompleted => 'All completed';

	/// en: 'Africa'
	String get quizCountriesAfricaTitle => 'Africa';

	/// en: 'Europe'
	String get quizCountriesEuropeTitle => 'Europe';

	/// en: 'Asia'
	String get quizCountriesAsiaTitle => 'Asia';

	/// en: 'North America'
	String get quizCountriesNorthAmericaTitle => 'North America';

	/// en: 'South America'
	String get quizCountriesSouthAmericaTitle => 'South America';

	/// en: 'Oceania'
	String get quizCountriesOceaniaTitle => 'Oceania';

	/// en: 'All Countries'
	String get quizCountriesAllTitle => 'All Countries';

	/// en: 'Countries'
	String get quizCountriesSubtitle => 'Countries';

	/// en: 'World'
	String get quizCountriesAllSubtitle => 'World';

	/// en: 'Seas'
	String get quizGeographySeasTitle => 'Seas';

	/// en: 'Mountain ranges'
	String get quizGeographyMountainRangesTitle => 'Mountain ranges';

	/// en: 'Lakes'
	String get quizGeographyLakesTitle => 'Lakes';

	/// en: 'Islands'
	String get quizGeographyIslandsTitle => 'Islands';

	/// en: 'Other'
	String get quizGeographyOtherTitle => 'Other';

	/// en: 'Bays, straits, gulfs, deserts, and more'
	String get quizGeographyOtherSubtitle => 'Bays, straits, gulfs, deserts, and more';

	/// en: 'Description is not available yet.'
	String get descriptionUnavailable => 'Description is not available yet.';
}

// Path: settings.notifications
class TranslationsSettingsNotificationsEn {
	TranslationsSettingsNotificationsEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Notifications'
	String get title => 'Notifications';

	/// en: 'Notifications are off. Enable them to get reminders and forecast alerts for your flights.'
	String get permissionOff => 'Notifications are off. Enable them to get reminders and forecast alerts for your flights.';

	/// en: 'Early reminder'
	String get readyTitle => 'Early reminder';

	/// en: '6 days before the flight'
	String get readySubtitle => '6 days before the flight';

	/// en: 'Day-before reminder'
	String get updatedTitle => 'Day-before reminder';

	/// en: 'The evening before the flight'
	String get updatedSubtitle => 'The evening before the flight';

	/// en: 'On'
	String get summaryOn => 'On';

	/// en: 'Off'
	String get summaryOff => 'Off';
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

	/// en: 'Flight weather'
	String get weatherTitle => 'Flight weather';
}

// Path: createFlight.weather
class TranslationsCreateFlightWeatherEn {
	TranslationsCreateFlightWeatherEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Will you see the ground?'
	String get title => 'Will you see the ground?';

	/// en: 'Checking the skies along your route…'
	String get loading => 'Checking the skies along your route…';

	/// en: 'Loading clouds…'
	String get cloudsLoading => 'Loading clouds…';

	/// en: 'Couldn't load the forecast right now. You can retry or continue without it.'
	String get loadFailed => 'Couldn\'t load the forecast right now. You can retry or continue without it.';

	/// en: 'No forecast was downloaded for this flight. It needs an internet connection before you fly.'
	String get notDownloadedBody => 'No forecast was downloaded for this flight. It needs an internet connection before you fly.';

	/// en: 'Departure'
	String get departureLabel => 'Departure';

	/// en: 'Arrival'
	String get arrivalLabel => 'Arrival';

	/// en: 'tomorrow'
	String get tomorrow => 'tomorrow';

	/// en: 'Continue without weather'
	String get continueWithoutWeather => 'Continue without weather';

	/// en: 'Add your flight date & time'
	String get noDateTitle => 'Add your flight date & time';

	/// en: 'A weather forecast needs both your flight date and departure time.'
	String get noDatePickBody => 'A weather forecast needs both your flight date and departure time.';

	/// en: 'Pick date & time'
	String get noDatePickButton => 'Pick date & time';

	/// en: 'A weather forecast isn't possible without your flight date. Choose a date when you select this flight to see the weather.'
	String get noDateRealBody => 'A weather forecast isn\'t possible without your flight date. Choose a date when you select this flight to see the weather.';

	/// en: 'Go back to pick a date'
	String get noDateBackButton => 'Go back to pick a date';

	/// en: 'It's too early for a reliable forecast'
	String get forecastTooFarTitle => 'It\'s too early for a reliable forecast';

	/// en: 'Weather forecasts are only dependable up to $days days ahead. We'll notify you before your flight once a reliable forecast is available.'
	String forecastTooFarBody({required Object days}) => 'Weather forecasts are only dependable up to ${days} days ahead. We\'ll notify you before your flight once a reliable forecast is available.';

	/// en: 'This flight date has passed'
	String get pastForecastTitle => 'This flight date has passed';

	/// en: 'Forecasts aren't available for past flights.'
	String get pastForecastBody => 'Forecasts aren\'t available for past flights.';

	/// en: 'Notifications are off. Enable them so the forecast alert can reach you.'
	String get notificationPermissionHint => 'Notifications are off. Enable them so the forecast alert can reach you.';

	/// en: 'Clear views'
	String get verdictClearTitle => 'Clear views';

	/// en: 'Window seat worth it — the ground should be visible for most of the flight.'
	String get verdictClearBody => 'Window seat worth it — the ground should be visible for most of the flight.';

	/// en: 'Patchy clouds'
	String get verdictPatchyTitle => 'Patchy clouds';

	/// en: 'Views will come and go between the clouds.'
	String get verdictPatchyBody => 'Views will come and go between the clouds.';

	/// en: 'Cloud carpet'
	String get verdictCarpetTitle => 'Cloud carpet';

	/// en: 'A white sea of clouds beneath you — beautiful, but the ground will mostly stay hidden.'
	String get verdictCarpetBody => 'A white sea of clouds beneath you — beautiful, but the ground will mostly stay hidden.';

	/// en: 'Overcast skies'
	String get verdictOvercastTitle => 'Overcast skies';

	/// en: 'Best views at takeoff and landing.'
	String get verdictOvercastBody => 'Best views at takeoff and landing.';

	/// en: 'estimated'
	String get estimatedShort => 'estimated';

	/// en: 'Calm'
	String get windCalm => 'Calm';

	/// en: 'Light wind'
	String get windLight => 'Light wind';

	/// en: 'Breezy'
	String get windBreezy => 'Breezy';

	/// en: 'Windy'
	String get windWindy => 'Windy';

	/// en: 'Strong wind'
	String get windStrong => 'Strong wind';

	/// en: 'Unlock airport weather and clouds along your route'
	String get proTeaserTitle => 'Unlock airport weather and clouds along your route';

	/// en: 'Based on data from $provider · Visualization by Flymap · $license'
	String attribution({required Object provider, required Object license}) => 'Based on data from ${provider} · Visualization by Flymap · ${license}';

	/// en: '$provider data · Flymap visualization · $license'
	String attributionShare({required Object provider, required Object license}) => '${provider} data · Flymap visualization · ${license}';

	/// en: 'Forecasts firm up closer to departure.'
	String get hedge => 'Forecasts firm up closer to departure.';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Share as image'
	String get shareAsImage => 'Share as image';

	/// en: 'Share as video'
	String get shareAsVideo => 'Share as video';

	/// en: 'Preparing your share…'
	String get preparingShare => 'Preparing your share…';

	/// en: 'Couldn't prepare the share — try again.'
	String get shareFailed => 'Couldn\'t prepare the share — try again.';

	/// en: 'Updated $relative'
	String updatedRelative({required Object relative}) => 'Updated ${relative}';

	/// en: 'Updated $date, $time'
	String updatedExact({required Object date, required Object time}) => 'Updated ${date}, ${time}';

	/// en: 'just now'
	String get updatedJustNow => 'just now';

	/// en: '$minutes min ago'
	String updatedMinutesAgo({required Object minutes}) => '${minutes} min ago';

	/// en: '$hours h ago'
	String updatedHoursAgo({required Object hours}) => '${hours} h ago';
}

// Path: createFlight.routeTypeSelector
class TranslationsCreateFlightRouteTypeSelectorEn {
	TranslationsCreateFlightRouteTypeSelectorEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'New flight'
	String get title => 'New flight';

	/// en: 'Approximate route'
	String get basicTitle => 'Approximate route';

	/// en: 'From airports'
	String get basicSubtitle => 'From airports';

	/// en: 'Works well for short and many mid-haul flights.'
	String get basicDescription => 'Works well for short and many mid-haul flights.';

	/// en: 'Real route'
	String get proTitle => 'Real route';

	/// en: 'From recent flights'
	String get proSubtitle => 'From recent flights';

	/// en: 'Built from the most recently recorded route for the same flight.'
	String get proDescription => 'Built from the most recently recorded route for the same flight.';

	/// en: 'Most accurate'
	String get mostAccurate => 'Most accurate';
}

// Path: createFlight.proAccess
class TranslationsCreateFlightProAccessEn {
	TranslationsCreateFlightProAccessEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flymap Pro'
	String get subscriber => 'Flymap Pro';

	/// en: 'This flight has full Pro access through your Flymap Pro subscription.'
	String get subscriberBody => 'This flight has full Pro access through your Flymap Pro subscription.';

	/// en: 'This flight is unlocked'
	String get unlockedFlight => 'This flight is unlocked';

	/// en: 'All Pro features are enabled for this flight.'
	String get unlockedFlightBody => 'All Pro features are enabled for this flight.';

	/// en: 'Pro access info'
	String get tooltip => 'Pro access info';
}

// Path: createFlight.travelDate
class TranslationsCreateFlightTravelDateEn {
	TranslationsCreateFlightTravelDateEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'In $count days'
	String inDays({required Object count}) => 'In ${count} days';

	/// en: 'Today'
	String get today => 'Today';

	/// en: 'Tomorrow'
	String get tomorrow => 'Tomorrow';

	/// en: 'When are you flying?'
	String get stepTitle => 'When are you flying?';

	/// en: 'Pick another date'
	String get customDate => 'Pick another date';

	/// en: 'Pick your travel date'
	String get pickDate => 'Pick your travel date';

	/// en: 'Your flight on this date'
	String get yourFlightOnDate => 'Your flight on this date';

	/// en: 'Change date'
	String get changeDate => 'Change date';

	/// en: 'Checking the flight schedule…'
	String get checkingSchedule => 'Checking the flight schedule…';

	/// en: 'No date yet'
	String get noDateYet => 'No date yet';

	/// en: 'Continue without a date'
	String get skipDate => 'Continue without a date';

	/// en: 'Skip date & time'
	String get skipDateTimeScreen => 'Skip date & time';

	/// en: 'Add departure time'
	String get addDepartureTime => 'Add departure time';

	/// en: 'Departure time · $time'
	String departureTimeAt({required Object time}) => 'Departure time · ${time}';

	/// en: 'Departure time'
	String get departureTimeTitle => 'Departure time';

	/// en: 'Set the local departure time to continue.'
	String get departureTimeHint => 'Set the local departure time to continue.';

	/// en: 'Pick a date first, then set the departure time.'
	String get departureTimePickDateFirst => 'Pick a date first, then set the departure time.';

	/// en: 'Set departure time'
	String get setDepartureTime => 'Set departure time';

	/// en: 'Departure · $time'
	String departureTimeSelected({required Object time}) => 'Departure · ${time}';

	/// en: 'Get flight reminders'
	String get notificationPermissionTitle => 'Get flight reminders';

	/// en: 'Allow notifications so Flymap can remind you to check the latest weather before your flight.'
	String get notificationPermissionBody => 'Allow notifications so Flymap can remind you to check the latest weather before your flight.';

	/// en: 'Not now'
	String get notificationPermissionNotNow => 'Not now';

	/// en: 'Allow notifications'
	String get notificationPermissionAllow => 'Allow notifications';

	/// en: 'We couldn't find this flight on this date'
	String get noDepartureOnDateTitle => 'We couldn\'t find this flight on this date';

	/// en: 'Check the date, or set the departure time manually to continue.'
	String get noDepartureOnDateBody => 'Check the date, or set the departure time manually to continue.';

	/// en: 'Couldn't check this date. Set the departure time manually to continue.'
	String get dateCheckFailed => 'Couldn\'t check this date. Set the departure time manually to continue.';
}

// Path: createFlight.flightNumberSearch
class TranslationsCreateFlightFlightNumberSearchEn {
	TranslationsCreateFlightFlightNumberSearchEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flight number'
	String get title => 'Flight number';

	/// en: 'Enter a flight number (for example BA117).'
	String get subtitle => 'Enter a flight number (for example BA117).';

	/// en: 'e.g. BA117'
	String get hint => 'e.g. BA117';

	/// en: 'Searching your flight'
	String get loading => 'Searching your flight';

	/// en: 'This can take a few seconds while we check recent flights.'
	String get loadingHint => 'This can take a few seconds while we check recent flights.';

	/// en: 'Enter a valid flight number like BA117.'
	String get invalidFormatError => 'Enter a valid flight number like BA117.';

	/// en: 'We couldn't find that flight number. Make sure it is the same as on your tickets and try again, or find by airports.'
	String get notFoundError => 'We couldn\'t find that flight number. Make sure it is the same as on your tickets and try again, or find by airports.';

	/// en: 'Too many flight lookups right now. Please try again in a moment, or find by airports.'
	String get rateLimitedError => 'Too many flight lookups right now. Please try again in a moment, or find by airports.';

	/// en: 'Flight data is temporarily unavailable. Please try again in a moment, or find by airports.'
	String get providerUnavailableError => 'Flight data is temporarily unavailable. Please try again in a moment, or find by airports.';

	/// en: 'Something went wrong while looking up this flight. Please try again, or find by airports.'
	String get unexpectedError => 'Something went wrong while looking up this flight. Please try again, or find by airports.';

	/// en: 'Or enter Airports'
	String get findByAirports => 'Or enter Airports';

	/// en: 'Find by airports'
	String get airportsFallbackButton => 'Find by airports';

	/// en: 'Confirm flight'
	String get confirmTitle => 'Confirm flight';

	/// en: 'We found your flight'
	String get foundTitle => 'We found your flight';

	/// en: 'Edit flight number'
	String get editFlightNumber => 'Edit flight number';

	/// en: 'Flying later? For the freshest and most accurate flight map, we recommend downloading within 7 days of your flight.'
	String get beyondWindowHint => 'Flying later? For the freshest and most accurate flight map, we recommend downloading within 7 days of your flight.';

	/// en: '* Based on the most recent recorded route for the same flight'
	String get basedOnSameFlightOn => '* Based on the most recent recorded route for the same flight';
}

// Path: createFlight.realRouteAirportSearch
class TranslationsCreateFlightRealRouteAirportSearchEn {
	TranslationsCreateFlightRealRouteAirportSearchEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Flight by airports'
	String get title => 'Flight by airports';

	/// en: 'Choose departure and arrival airports to look up recent real flights on this route.'
	String get subtitle => 'Choose departure and arrival airports to look up recent real flights on this route.';

	/// en: 'Search recent flights'
	String get searchAction => 'Search recent flights';

	/// en: 'Looking up recent real flights'
	String get loading => 'Looking up recent real flights';

	/// en: 'This can take a few seconds while we check recent route history.'
	String get loadingHint => 'This can take a few seconds while we check recent route history.';

	/// en: 'Sorry, we couldn't find any flights from $departure to $arrival.'
	String sorryNoFlightFromTo({required Object departure, required Object arrival}) => 'Sorry, we couldn\'t find any flights from ${departure} to ${arrival}.';

	/// en: 'We couldn't find recent flights between these airports'
	String get emptyTitle => 'We couldn\'t find recent flights between these airports';

	/// en: 'Make sure you selected the same departure and arrival airports as on your flight ticket.'
	String get emptyResults => 'Make sure you selected the same departure and arrival airports as on your flight ticket.';

	/// en: 'Try the reverse direction'
	String get searchReverse => 'Try the reverse direction';

	/// en: 'Too many flight searches right now. Please try again in a moment.'
	String get rateLimitedError => 'Too many flight searches right now. Please try again in a moment.';

	/// en: 'Real-flight data is temporarily unavailable. Please try again in a moment.'
	String get providerUnavailableError => 'Real-flight data is temporarily unavailable. Please try again in a moment.';

	/// en: 'Something went wrong while searching this route. Please try again.'
	String get unexpectedError => 'Something went wrong while searching this route. Please try again.';

	/// en: 'Found 1 flight · $route'
	String foundOneTitle({required Object route}) => 'Found 1 flight · ${route}';

	/// en: 'Found $count flights · $route'
	String foundManyTitle({required Object count, required Object route}) => 'Found ${count} flights · ${route}';

	/// en: 'Make sure these match the airports on your flight ticket.'
	String get ticketMatchHint => 'Make sure these match the airports on your flight ticket.';

	/// en: 'Find by flight number'
	String get findByFlightNumber => 'Find by flight number';
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

	/// en: 'Recent airports'
	String get recentAirports => 'Recent airports';

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

	/// en: 'Route note'
	String get mapDetailInfoTooltip => 'Route note';

	/// en: 'Legend'
	String get legendButton => 'Legend';

	/// en: 'POI legend'
	String get legendTitle => 'POI legend';

	/// en: 'Estimated map size: $size'
	String estimatedMapSize({required Object size}) => 'Estimated map size: ${size}';

	/// en: 'Upgrade to Pro'
	String get upgradeToPro => 'Upgrade to Pro';

	/// en: 'Basic map detail with limited places'
	String get basicHint => 'Basic map detail with limited places';

	/// en: 'Upgrade for a detailed map with all places'
	String get proGateHint => 'Upgrade for a detailed map with all places';

	/// en: 'Detailed offline map with $count places'
	String proHint({required Object count}) => 'Detailed offline map with ${count} places';

	/// en: 'Approximate route'
	String get optionsTitle => 'Approximate route';

	/// en: 'Route is approximate — actual path may vary, especially on long-haul flights.'
	String get optionsBody => 'Route is approximate — actual path may vary, especially on long-haul flights.';
}

// Path: createFlight.overview
class TranslationsCreateFlightOverviewEn {
	TranslationsCreateFlightOverviewEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Route is not ready yet.'
	String get routeNotReady => 'Route is not ready yet.';

	/// en: 'Free plan includes basic map and limited places'
	String get proPoiUpsell => 'Free plan includes basic map and limited places';

	/// en: 'Route note'
	String get routeNoteTooltip => 'Route note';

	/// en: 'Approximate route'
	String get routeNoteTitle => 'Approximate route';

	/// en: 'Route is approximate — actual path may vary, especially on long-haul flights.'
	String get routeNoteBody => 'Route is approximate — actual path may vary, especially on long-haul flights.';

	/// en: 'Real route'
	String get realRouteNoteTitle => 'Real route';

	/// en: 'This route is based on the most recent recorded route for the same flight. Actual routing may vary due to weather, air traffic, and operational constraints.'
	String get realRouteNoteBody => 'This route is based on the most recent recorded route for the same flight.\nActual routing may vary due to weather, air traffic, and operational constraints.';

	/// en: 'This is approximate route'
	String get approximateRouteLongHaulWarningTitle => 'This is approximate route';

	/// en: 'Approximate routes may be inaccurate for long-haul flights. Use a real route with a flight number instead.'
	String get approximateRouteLongHaulWarningBody => 'Approximate routes may be inaccurate for long-haul flights. Use a real route with a flight number instead.';

	/// en: 'Approximate routes are not supported for ultra long-haul flights. Use a real route with a flight number instead.'
	String get approximateRouteUltraLongHaulUnsupportedBody => 'Approximate routes are not supported for ultra long-haul flights. Use a real route with a flight number instead.';

	/// en: 'Start review'
	String get startReview => 'Start review';

	/// en: 'Skip review'
	String get skipReview => 'Skip review';

	/// en: 'Unlock full route overview'
	String get premiumGateTitle => 'Unlock full route overview';

	/// en: 'Free plan includes a limited route preview. Upgrade to Pro to view every region on this route.'
	String get premiumGateBody => 'Free plan includes a limited route preview. Upgrade to Pro to view every region on this route.';

	/// en: 'Unlock all $count regions on this route with Pro.'
	String premiumGateBodyWithCount({required Object count}) => 'Unlock all ${count} regions on this route with Pro.';

	/// en: 'Upgrade to Pro'
	String get premiumGateCta => 'Upgrade to Pro';

	/// en: 'This can take a few seconds on longer routes…'
	String get buildingHint => 'This can take a few seconds on longer routes…';

	/// en: 'Route reviewed'
	String get routeReviewedTitle => 'Route reviewed';

	/// en: 'You will fly over $regions from $departure to $arrival.'
	String routeReviewedSubtitle({required Object regions, required Object departure, required Object arrival}) => 'You will fly over ${regions} from ${departure} to ${arrival}.';

	/// en: 'Full summary'
	String get fullSummary => 'Full summary';

	/// en: 'Route Summary'
	String get routeSummaryTitle => 'Route Summary';

	/// en: 'Distance'
	String get routeSummaryDistanceLabel => 'Distance';

	/// en: 'Duration'
	String get routeSummaryDurationLabel => 'Duration';

	/// en: 'Regions'
	String get routeSummaryRegionsLabel => 'Regions';

	/// en: 'You'll fly over'
	String get routeSummaryRegionsTitle => 'You\'ll fly over';

	/// en: 'Places'
	String get routeSummaryPlacesLabel => 'Places';

	/// en: 'Timeline'
	String get routeSummaryTimelineTitle => 'Timeline';

	/// en: 'Places along the route'
	String get routeSummaryPlacesTitle => 'Places along the route';

	/// en: 'Search places'
	String get routeSummaryPoiSearchHint => 'Search places';

	/// en: 'No places match your search.'
	String get routeSummaryPoiNoMatches => 'No places match your search.';

	late final TranslationsCreateFlightOverviewAirportCardEn airportCard = TranslationsCreateFlightOverviewAirportCardEn.internal(_root);
	late final TranslationsCreateFlightOverviewRegionInfoEn regionInfo = TranslationsCreateFlightOverviewRegionInfoEn.internal(_root);
	late final TranslationsCreateFlightOverviewTimelineEn timeline = TranslationsCreateFlightOverviewTimelineEn.internal(_root);
}

// Path: createFlight.wikipedia
class TranslationsCreateFlightWikipediaEn {
	TranslationsCreateFlightWikipediaEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Download articles and read while you’re in the air'
	String get title => 'Download articles and read while you’re in the air';

	/// en: 'Finding route-related articles...'
	String get loadingIntro => 'Finding route-related articles...';

	/// en: 'Based on your route we found $count relevant articles'
	String foundIntro({required Object count}) => 'Based on your route we found ${count} relevant articles';

	/// en: 'No route-related Wikipedia articles found. You can continue with map download only.'
	String get emptyIntro => 'No route-related Wikipedia articles found. You can continue with map download only.';

	/// en: '$count selected'
	String selectedCount({required Object count}) => '${count} selected';

	/// en: 'Unselect all'
	String get unselectAll => 'Unselect all';

	/// en: 'Select all'
	String get selectAll => 'Select all';

	/// en: 'Offline articles selected: $count'
	String basicHint({required Object count}) => 'Offline articles selected: ${count}';

	/// en: 'Map and offline data pack'
	String get proHint => 'Map and offline data pack';

	/// en: 'Upgrade for the full offline article pack'
	String get proGateHint => 'Upgrade for the full offline article pack';

	/// en: 'Pro active'
	String get proActiveTitle => 'Pro active';

	/// en: 'Full articles pack unlocked.'
	String get proActiveMessage => 'Full articles pack unlocked.';

	/// en: 'Free plan includes up to 3 offline articles'
	String get freeLimitHint => 'Free plan includes up to 3 offline articles';

	/// en: 'Estimated download size: $size'
	String estimatedDownloadSize({required Object size}) => 'Estimated download size: ${size}';

	/// en: 'Upgrade to Pro'
	String get upgrade => 'Upgrade to Pro';

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

// Path: createFlight.realRouteChoice
class TranslationsCreateFlightRealRouteChoiceEn {
	TranslationsCreateFlightRealRouteChoiceEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Get the real flight route?'
	String get title => 'Get the real flight route?';

	/// en: 'Everything on this flight is unlocked. It still uses an approximate route — enter your flight number and we'll rebuild it from the real flight track.'
	String get body => 'Everything on this flight is unlocked. It still uses an approximate route — enter your flight number and we\'ll rebuild it from the real flight track.';

	/// en: 'Enter my flight number'
	String get ctaEnterFlightNumber => 'Enter my flight number';

	/// en: 'Keep approximate route'
	String get ctaKeepRoute => 'Keep approximate route';
}

// Path: flight.hub
class TranslationsFlightHubEn {
	TranslationsFlightHubEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Timeline'
	String get timelineTitle => 'Timeline';

	/// en: '$count regions along your route'
	String timelineSubtitle({required Object count}) => '${count} regions along your route';

	/// en: 'Places'
	String get placesTitle => 'Places';

	/// en: '$count places to spot from your window'
	String placesSubtitle({required Object count}) => '${count} places to spot from your window';

	/// en: 'All'
	String get filterAll => 'All';

	/// en: 'No places saved for this flight.'
	String get noPlaces => 'No places saved for this flight.';

	/// en: 'Weather'
	String get weatherTitle => 'Weather';

	/// en: 'Check your forecast'
	String get weatherCheck => 'Check your forecast';

	/// en: 'Too early for a reliable forecast — we'll notify you'
	String get weatherTooEarly => 'Too early for a reliable forecast — we\'ll notify you';

	/// en: 'Cloud map and airport forecasts — Pro'
	String get weatherLocked => 'Cloud map and airport forecasts — Pro';

	/// en: 'Articles'
	String get articlesTitle => 'Articles';

	/// en: '$count articles saved for offline reading'
	String articlesSubtitle({required Object count}) => '${count} articles saved for offline reading';
}

// Path: flight.map
class TranslationsFlightMapEn {
	TranslationsFlightMapEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading map'
	String get initializing => 'Loading map';

	/// en: 'Loading map'
	String get loadingStyle => 'Loading map';

	/// en: 'Offline map is not available for this flight.'
	String get offlineNotAvailable => 'Offline map is not available for this flight.';

	/// en: 'Offline map file is missing. Please re-download this route.'
	String get offlineMissing => 'Offline map file is missing. Please re-download this route.';

	/// en: 'Offline map validation failed. Please re-download this route.'
	String get validationFailed => 'Offline map validation failed. Please re-download this route.';

	/// en: 'Could not load offline map style.'
	String get loadStyleFailed => 'Could not load offline map style.';

	/// en: 'Sunrise in $minutes min'
	String sunriseInMinutes({required Object minutes}) => 'Sunrise in ${minutes} min';

	/// en: 'Sunset in $minutes min'
	String sunsetInMinutes({required Object minutes}) => 'Sunset in ${minutes} min';

	/// en: 'Switch to 2D'
	String get switchTo2D => 'Switch to 2D';

	/// en: 'Switch to 3D'
	String get switchTo3D => 'Switch to 3D';

	/// en: 'Switch to light map style'
	String get switchToLightMapStyle => 'Switch to light map style';

	/// en: 'Switch to dark map style'
	String get switchToDarkMapStyle => 'Switch to dark map style';

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

	/// en: 'Looking for GPS. Last fix $age.'
	String gpsSearchingHintWithAge({required Object age}) => 'Looking for GPS. Last fix ${age}.';

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

	/// en: 'Showing last known data'
	String get gpsShowingLastKnownData => 'Showing last known data';

	/// en: 'GPS troubleshooting'
	String get gpsHelpTooltip => 'GPS troubleshooting';

	/// en: 'GPS troubleshooting'
	String get gpsHelpTitle => 'GPS troubleshooting';

	/// en: 'Looks like GPS signal is not reliable on your phone.'
	String get gpsHelpBody => 'Looks like GPS signal is not reliable on your phone.';

	/// en: 'Try this'
	String get gpsHelpStepsTitle => 'Try this';

	/// en: 'Make sure Location Services are on'
	String get gpsHelpTipLocation => 'Make sure Location Services are on';

	/// en: 'Move your phone closer to the window'
	String get gpsHelpTipWindow => 'Move your phone closer to the window';

	/// en: 'Remove thick cases or metal accessories'
	String get gpsHelpTipCase => 'Remove thick cases or metal accessories';

	/// en: 'Hold your phone still for a few moments'
	String get gpsHelpTipFlat => 'Hold your phone still for a few moments';

	/// en: 'Live tracking resumes automatically once the signal stabilizes.'
	String get gpsHelpFooter => 'Live tracking resumes automatically once the signal stabilizes.';

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

	/// en: 'Ground speed'
	String get groundSpeed => 'Ground speed';

	/// en: 'Altitude MSL'
	String get altitudeMsl => 'Altitude MSL';

	/// en: 'Outside air temperature'
	String get outsideAirApprox => 'Outside air temperature';

	/// en: 'Available after $threshold'
	String temperatureAvailableAfter({required Object threshold}) => 'Available after ${threshold}';

	/// en: 'Rough estimate based on altitude'
	String get temperatureApproxHint => 'Rough estimate based on altitude';

	/// en: 'Heading'
	String get headingPanel => 'Heading';

	/// en: 'Taxi'
	String get flightPhaseTaxi => 'Taxi';

	/// en: 'Ground roll'
	String get flightPhaseGroundRoll => 'Ground roll';

	/// en: 'Takeoff roll'
	String get flightPhaseTakeoffRoll => 'Takeoff roll';

	/// en: 'Landing roll'
	String get flightPhaseLandingRoll => 'Landing roll';

	/// en: 'Ascending'
	String get flightPhaseAscending => 'Ascending';

	/// en: 'Cruising'
	String get flightPhaseCruising => 'Cruising';

	/// en: 'Descending'
	String get flightPhaseDescending => 'Descending';

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

	/// en: 'G-force'
	String get gForce => 'G-force';

	/// en: 'PEAK'
	String get gForcePeakLabel => 'PEAK';

	/// en: 'Cabin pressure'
	String get cabinPressure => 'Cabin pressure';

	/// en: 'Feels like $altitude'
	String cabinPressureLikeAltitude({required Object altitude}) => 'Feels like ${altitude}';

	/// en: 'Cruise'
	String get cabinPressureCruise => 'Cruise';

	/// en: 'Sea level'
	String get cabinPressureSeaLevel => 'Sea level';

	/// en: 'Got it'
	String get metricInfoGotIt => 'Got it';

	/// en: 'How heavy you feel right now, measured by your phone. 1.0 g is normal weight; it rises above 1 g when the plane pulls up or touches down, and dips below when you float over a bump.'
	String get gForceInfoBody => 'How heavy you feel right now, measured by your phone. 1.0 g is normal weight; it rises above 1 g when the plane pulls up or touches down, and dips below when you float over a bump.';

	/// en: 'The air pressure inside the cabin. Airliners keep it comfortable but thinner than at sea level — about what you'd feel on a mountain — which is why your ears pop as it changes.'
	String get cabinPressureInfoBody => 'The air pressure inside the cabin. Airliners keep it comfortable but thinner than at sea level — about what you\'d feel on a mountain — which is why your ears pop as it changes.';

	/// en: 'How fast the plane moves over the ground, from GPS. It differs from the airspeed pilots watch, because tailwinds and headwinds push the plane along faster or slower.'
	String get groundSpeedInfoBody => 'How fast the plane moves over the ground, from GPS. It differs from the airspeed pilots watch, because tailwinds and headwinds push the plane along faster or slower.';

	/// en: 'The plane's height above sea level, from GPS. Airliners usually cruise near 10–12 km, above most clouds and weather.'
	String get altitudeInfoBody => 'The plane\'s height above sea level, from GPS. Airliners usually cruise near 10–12 km, above most clouds and weather.';

	/// en: 'The compass direction the plane is pointing, from your GPS course. 0° is north, 90° east, 180° south and 270° west.'
	String get headingInfoBody => 'The compass direction the plane is pointing, from your GPS course. 0° is north, 90° east, 180° south and 270° west.';

	/// en: 'An estimate of the outside air temperature from your altitude. It falls steeply with height — often around -50 °C at cruise, even over a warm country.'
	String get temperatureInfoBody => 'An estimate of the outside air temperature from your altitude. It falls steeply with height — often around -50 °C at cruise, even over a warm country.';

	/// en: 'Allow motion access to see the air pressure inside the cabin.'
	String get cabinPressureEnableBody => 'Allow motion access to see the air pressure inside the cabin.';

	/// en: 'Enable'
	String get cabinPressureEnableButton => 'Enable';

	/// en: 'Feel pain in ears?'
	String get cabinPressureEarPainArticle => 'Feel pain in ears?';
}

// Path: flight.upcoming
class TranslationsFlightUpcomingEn {
	TranslationsFlightUpcomingEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Begin your flight journey'
	String get mapTitle => 'Begin your flight journey';

	/// en: 'Start live tracking once your flight begins'
	String get mapSubtitle => 'Start live tracking once your flight begins';

	/// en: 'Begin your flight journey'
	String get dashboardTitle => 'Begin your flight journey';

	/// en: 'Start to see your live dashboard'
	String get dashboardSubtitle => 'Start to see your live dashboard';

	/// en: 'Start'
	String get checkInButton => 'Start';

	/// en: 'Flight started'
	String get checkInSuccess => 'Flight started';

	/// en: 'Could not start now. Please try again'
	String get checkInError => 'Could not start now. Please try again';
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

	/// en: 'Highlights of your route'
	String get flyOverTitle => 'Highlights of your route';

	/// en: 'Airports'
	String get airportsTitle => 'Airports';

	/// en: 'Departure'
	String get departure => 'Departure';

	/// en: 'Arrival'
	String get arrival => 'Arrival';

	/// en: 'Show all'
	String get showAll => 'Show all';

	/// en: 'Show all $count'
	String showAllCount({required Object count}) => 'Show all ${count}';

	/// en: 'Show less'
	String get showLess => 'Show less';

	/// en: 'By rank'
	String get sortByRank => 'By rank';

	/// en: 'By route'
	String get sortByRouteProgress => 'By route';

	/// en: 'By type'
	String get sortByType => 'By type';

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

	/// en: 'Region articles'
	String get regionArticlesTitle => 'Region articles';

	/// en: 'Other articles'
	String get otherArticlesTitle => 'Other articles';

	/// en: 'No offline articles downloaded.'
	String get noOfflineArticles => 'No offline articles downloaded.';

	/// en: 'Open Source'
	String get openSource => 'Open Source';

	/// en: 'Open source page'
	String get openSourcePage => 'Open source page';

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

// Path: flight.route
class TranslationsFlightRouteEn {
	TranslationsFlightRouteEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Loading route timeline...'
	String get loadingRouteTimeline => 'Loading route timeline...';

	/// en: 'No saved offline regions for this flight.'
	String get noSavedOfflineRegions => 'No saved offline regions for this flight.';

	/// en: 'Current progress: $percentage% (around $minute from takeoff)'
	String currentProgress({required Object percentage, required Object minute}) => 'Current progress: ${percentage}% (around ${minute} from takeoff)';

	/// en: 'Now'
	String get nowLabel => 'Now';

	/// en: 'Current'
	String get currentRegionLabel => 'Current';

	/// en: 'Next'
	String get nextRegionLabel => 'Next';

	/// en: 'Arriving'
	String get arrivingLabel => 'Arriving';

	/// en: 'Arrived'
	String get arrivedLabel => 'Arrived';

	/// en: 'ETA: $time'
	String etaLabel({required Object time}) => 'ETA: ${time}';

	/// en: 'in $time'
	String etaInLabel({required Object time}) => 'in ${time}';

	/// en: 'You are flying over:'
	String get flyingOverLabel => 'You are flying over:';

	/// en: 'Unlock'
	String get premiumLockedChipLabel => 'Unlock';

	/// en: 'Unlock full route timeline'
	String get premiumGateTitle => 'Unlock full route timeline';

	/// en: 'Upgrade to Pro to see all regions along your route and timeline details.'
	String get premiumGateBody => 'Upgrade to Pro to see all regions along your route and timeline details.';

	/// en: 'Unlock all $count regions on this route with Premium.'
	String premiumGateBodyWithCount({required Object count}) => 'Unlock all ${count} regions on this route with Premium.';

	/// en: 'Upgrade to Pro'
	String get premiumGateCta => 'Upgrade to Pro';

	/// en: 'Internet needed to upgrade'
	String get premiumOfflineTitle => 'Internet needed to upgrade';

	/// en: 'You are offline right now. Connect to the internet to upgrade and unlock the full route view.'
	String get premiumOfflineBody => 'You are offline right now. Connect to the internet to upgrade and unlock the full route view.';

	/// en: 'Next: $region ($eta)'
	String nextHintLabel({required Object region, required Object eta}) => 'Next: ${region} (${eta})';

	/// en: 'estimating...'
	String get etaUnknownLabel => 'estimating...';
}

// Path: onboarding.payoff
class TranslationsOnboardingPayoffEn {
	TranslationsOnboardingPayoffEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Places around $airport you shouldn't miss'
	String title({required Object airport}) => 'Places around ${airport} you shouldn\'t miss';

	/// en: 'You've been flying right over all this — spot them on your next flight:'
	String get subtitle => 'You\'ve been flying right over all this — spot them on your next flight:';

	/// en: 'Scanning the skies around $airport…'
	String scanning({required Object airport}) => 'Scanning the skies around ${airport}…';

	/// en: '…and $count+ more to discover nearby:'
	String moreNearby({required Object count}) => '…and ${count}+ more to discover nearby:';

	/// en: 'Stop missing what's below'
	String get fallbackTitle => 'Stop missing what\'s below';

	/// en: 'Every flight soars over volcanoes, mountains, islands and lakes most travelers never notice. Flymap shows you what's out your window.'
	String get fallbackSubtitle => 'Every flight soars over volcanoes, mountains, islands and lakes most travelers never notice. Flymap shows you what\'s out your window.';
}

// Path: onboarding.weatherPayoff
class TranslationsOnboardingWeatherPayoffEn {
	TranslationsOnboardingWeatherPayoffEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Check the weather for your flight'
	String get title => 'Check the weather for your flight';

	/// en: 'Every flight you plan comes with airport weather and a window-seat cloud forecast.'
	String get subtitle => 'Every flight you plan comes with airport weather and a window-seat cloud forecast.';

	/// en: 'Example'
	String get exampleBadge => 'Example';
}

// Path: createFlight.overview.airportCard
class TranslationsCreateFlightOverviewAirportCardEn {
	TranslationsCreateFlightOverviewAirportCardEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'You'll start your journey from $airport.'
	String departureDescription({required Object airport}) => 'You\'ll start your journey from ${airport}.';

	/// en: 'You'll arrive at $airport.'
	String arrivalDescription({required Object airport}) => 'You\'ll arrive at ${airport}.';
}

// Path: createFlight.overview.regionInfo
class TranslationsCreateFlightOverviewRegionInfoEn {
	TranslationsCreateFlightOverviewRegionInfoEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Description is not available yet.'
	String get descriptionUnavailable => 'Description is not available yet.';

	/// en: 'Wikipedia'
	String get wikipediaSectionTitle => 'Wikipedia';

	/// en: 'Wikipedia article is not available right now.'
	String get wikipediaUnavailable => 'Wikipedia article is not available right now.';

	/// en: 'Open Wikipedia'
	String get openWikipedia => 'Open Wikipedia';
}

// Path: createFlight.overview.timeline
class TranslationsCreateFlightOverviewTimelineEn {
	TranslationsCreateFlightOverviewTimelineEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Take off'
	String get takeOffTimeline => 'Take\noff';

	/// en: 'Land'
	String get land => 'Land';

	/// en: 'Also around same time:'
	String get alsoAroundThisTime => 'Also around same time:';

	/// en: 'min'
	String get minuteUnit => 'min';

	/// en: 'h'
	String get hourCompactUnit => 'h';

	/// en: 'm'
	String get minuteCompactUnit => 'm';

	late final TranslationsCreateFlightOverviewTimelineRegionTypeEn regionType = TranslationsCreateFlightOverviewTimelineRegionTypeEn.internal(_root);
}

// Path: createFlight.overview.timeline.regionType
class TranslationsCreateFlightOverviewTimelineRegionTypeEn {
	TranslationsCreateFlightOverviewTimelineRegionTypeEn.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Country'
	String get country => 'Country';

	/// en: 'Region'
	String get region => 'Region';

	/// en: 'State'
	String get state => 'State';

	/// en: 'Province'
	String get province => 'Province';

	/// en: 'Sea'
	String get sea => 'Sea';

	/// en: 'Ocean'
	String get ocean => 'Ocean';

	/// en: 'Strait'
	String get strait => 'Strait';

	/// en: 'Channel'
	String get channel => 'Channel';

	/// en: 'Gulf'
	String get gulf => 'Gulf';

	/// en: 'Bay'
	String get bay => 'Bay';

	/// en: 'Lake'
	String get lake => 'Lake';

	/// en: 'Alkaline lake'
	String get alkalineLake => 'Alkaline lake';

	/// en: 'Island'
	String get island => 'Island';

	/// en: 'Archipelago'
	String get archipelago => 'Archipelago';

	/// en: 'Peninsula'
	String get peninsula => 'Peninsula';

	/// en: 'Coast'
	String get coast => 'Coast';

	/// en: 'Mountain range'
	String get mountainRange => 'Mountain range';

	/// en: 'Valley'
	String get valley => 'Valley';

	/// en: 'Plateau'
	String get plateau => 'Plateau';

	/// en: 'Plain'
	String get plain => 'Plain';

	/// en: 'Basin'
	String get basin => 'Basin';

	/// en: 'Lowland'
	String get lowland => 'Lowland';

	/// en: 'Tundra'
	String get tundra => 'Tundra';

	/// en: 'Wetlands'
	String get wetlands => 'Wetlands';

	/// en: 'Desert'
	String get desert => 'Desert';

	/// en: 'Delta'
	String get delta => 'Delta';

	/// en: 'Reservoir'
	String get reservoir => 'Reservoir';

	/// en: 'Continent'
	String get continent => 'Continent';

	/// en: 'Geographic area'
	String get geoarea => 'Geographic area';

	/// en: 'Isthmus'
	String get isthmus => 'Isthmus';

	/// en: 'Unknown region type'
	String get unknown => 'Unknown region type';
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
			'common.manage' => 'Manage',
			'common.edit' => 'Edit',
			'common.upgrade' => 'Upgrade to Pro',
			'common.loading' => 'Loading...',
			'common.readMore' => 'Read more',
			'common.pro' => 'PRO',
			'common.search' => 'Search',
			'common.debug' => 'Debug',
			'home.title' => 'Home',
			'home.aboutTooltip' => 'About',
			'home.settingsTooltip' => 'Settings',
			'home.tabFlights' => 'Flights',
			'home.tabLearn' => 'Learn',
			'home.tabMedia' => 'Media',
			'home.openSkyCamera' => 'Open Sky Camera',
			'home.loadingFlights' => 'Loading flights...',
			'home.failedToLoadFlights' => 'Failed to load flights',
			'home.newFlight' => 'New flight',
			'home.addFirstFlight' => 'Add first flight',
			'home.addNextFlight' => 'Add next flight',
			'home.welcomeTitle' => 'Welcome to Flymap',
			'home.welcomeTitlePro' => 'Welcome to Flymap Pro',
			'home.welcomeSubtitle' => 'Offline maps for flights',
			'home.greetingOnline' => 'Ready for the next flight?',
			'home.greetingOnlineWithName' => ({required Object name}) => 'Hi ${name}, ready for the next flight?',
			'home.greetingOffline' => 'Ready to explore your flight?',
			'home.greetingOfflineWithName' => ({required Object name}) => 'Hi ${name}, ready to explore your flight?',
			'home.greetingInProgress' => 'Your flight is in progress',
			'home.greetingInProgressWithName' => ({required Object name}) => 'Hi ${name}, your flight is in progress',
			'home.totalFlights' => 'Total flights',
			'home.storageUsed' => 'Storage used',
			'home.totalDistance' => 'Total distance',
			'home.upcomingFlightsCount' => ({required Object count}) => 'Upcoming flights (${count})',
			'home.flightInProgressTitle' => 'Flight in progress',
			'home.noFlightsTitle' => 'Ready to explore the world from above?',
			'home.noFlightsSubtitle' => 'Add your first flight and start discovering your next journey.',
			'home.noFlightsTitleNext' => 'Ready for your next trip?',
			'home.noFlightsSubtitleNext' => 'Your completed flights are in History. Add your next flight to keep going.',
			'home.flightActions' => 'Flight actions',
			'home.viewAll' => 'View all',
			'home.open' => 'Open',
			'home.shareRoute' => 'Share route',
			'home.completeFlight' => 'Archive flight',
			'home.deleteFlight' => 'Delete flight',
			'home.failedDeleteFlight' => 'Failed to delete flight',
			'home.noOfflineMap' => 'No offline map',
			'home.placesCount' => ({required Object count}) => '${count} places',
			'home.regionsCount' => ({required Object count}) => '${count} regions',
			'home.offlineArticlesCount' => ({required Object count}) => '${count} articles',
			'home.savedTime' => ({required Object time}) => 'Saved ${time}',
			'home.justNow' => 'Just now',
			'home.daysAgo' => ({required Object days}) => '${days} d ago',
			'home.hoursAgo' => ({required Object hours}) => '${hours} h ago',
			'home.minutesAgo' => ({required Object minutes}) => '${minutes} m ago',
			'home.sort.mostRecent' => 'Most recent',
			'home.sort.longest' => 'Longest',
			'home.sort.alphabetical' => 'A-Z',
			'skyCamera.loading' => 'Loading camera...',
			'skyCamera.loadingGpsData' => 'Loading GPS data',
			'skyCamera.zoom' => 'Zoom',
			'skyCamera.flash' => 'Flash',
			'skyCamera.cameraUnavailable' => 'Camera is unavailable right now.',
			'skyCamera.cameraPermissionDenied' => 'Camera permission is required to take photos and record videos.',
			'skyCamera.captureFailed' => 'Could not save this capture right now.',
			'skyCamera.savedMessage' => 'Photo saved',
			'skyCamera.share' => 'Share',
			'skyCamera.noActiveFlightTitle' => 'No active flight',
			'skyCamera.noActiveFlightMessage' => 'Sky Camera works without a flight, but route details appear only during an active flight.',
			'skyCamera.telemetrySpeed' => 'Speed',
			'skyCamera.telemetryAltitude' => 'Altitude',
			'skyCamera.telemetryHeading' => 'Heading',
			'skyCamera.telemetryTime' => 'Time',
			'skyCamera.contextCaption' => 'Context',
			'skyCamera.mapCaption' => 'Map',
			'skyCamera.coordinatesCaption' => 'Coordinates',
			'skyCamera.noValuePlaceholder' => '--',
			'skyCamera.placeholderRoute' => 'LHR -> BCN',
			'skyCamera.placeholderOriginCode' => 'LHR',
			'skyCamera.placeholderDestinationCode' => 'BCN',
			'skyCamera.placeholderContext' => 'Mediterranean Sea',
			'skyCamera.placeholderMap' => 'Route preview',
			'skyCamera.settingsTitle' => 'Camera settings',
			'skyCamera.recordAudio' => 'Record audio',
			'skyCamera.recordAudioHint' => 'Videos capture microphone sound.',
			'skyCamera.microphonePermissionDenied' => 'Microphone access is off — videos record without sound.',
			'skyCamera.lowStorageRecordingBlocked' => 'Free up storage before recording a video.',
			'skyCamera.lowStorageRecordingStopped' => 'Recording stopped and was saved because storage is almost full.',
			'skyCamera.lowStorageVideoExport' => 'Free up storage before preparing this video.',
			'skyCamera.hotDeviceRecordingBlocked' => 'Your device is too hot to record. Let it cool down and try again.',
			'skyCamera.hotDeviceRecordingStopped' => 'Recording stopped and was saved because your device is too hot.',
			'skyCamera.preparingVideo' => 'Preparing video…',
			'media.title' => 'Window Seat Media',
			'media.loading' => 'Loading media...',
			'media.failedToLoad' => 'Failed to load media',
			'media.filesTab' => 'Files',
			'media.flightsTab' => 'Flights',
			'media.emptyTitle' => 'Welcome to your window-seat Sky Camera',
			'media.emptySubtitle' => 'Capture and share beautiful views from your window seat with flight and GPS data overlays.',
			'media.emptyFlightsTitle' => 'No flight folders yet',
			'media.emptyFlightsSubtitle' => 'Captures linked to saved flights will appear here.',
			'media.deleteAction' => 'Delete',
			'media.share' => 'Share',
			'media.selectedCount' => ({required Object count}) => '${count} selected',
			'media.groupNoFlight' => 'No flight context',
			'media.groupNoFlightSubtitle' => 'Captures taken outside an active flight',
			'media.groupUnknownFlight' => 'Flight capture',
			'media.previewTitle' => 'Capture',
			'media.captureCount' => ({required Object count}) => '${count} captures',
			'media.deleteFolder' => 'Delete folder',
			'media.deleteFolders' => ({required Object count}) => 'Delete ${count} folders',
			'media.deleteFile' => 'Delete file',
			'media.deleteFiles' => ({required Object count}) => 'Delete ${count} files',
			'media.deleteFolderConfirm' => ({required Object count}) => 'Delete this folder and all ${count} files?',
			'media.deleteFoldersConfirm' => ({required Object count}) => 'Delete ${count} folders and all files inside them?',
			'media.deleteFileConfirm' => 'Delete this file?',
			'media.deleteFilesConfirm' => ({required Object count}) => 'Delete ${count} files?',
			'learn.loadingCategories' => 'Loading learning categories...',
			'learn.failedToLoadCategories' => 'Failed to load categories',
			'learn.emptyCategoriesTitle' => 'No categories yet',
			'learn.emptyCategoriesSubtitle' => 'Learning categories will appear here soon.',
			'learn.articlesCount' => ({required Object count}) => '${count} articles',
			'learn.loadingArticles' => 'Loading articles...',
			'learn.failedToLoadArticles' => 'Failed to load articles',
			'learn.emptyArticlesTitle' => 'No articles yet',
			'learn.emptyArticlesSubtitle' => 'Articles for this category will appear soon.',
			'learn.upgradeRequiresInternet' => 'Premium content is available with Pro. Connect to the internet to upgrade.',
			'learn.proListPreviewHint' => 'You can browse these article titles now. Unlock reading with Flymap Pro.',
			'learn.failedToLoadArticle' => 'Could not open this article right now.',
			'learn.quizzesTitle' => 'Quizzes',
			'learn.articlesTitle' => 'Articles',
			'learn.geoQuiz.title' => 'Geo Quiz',
			'learn.geoQuiz.geographyTitle' => 'Geography',
			'learn.geoQuiz.geographySubtitle' => 'Seas, mountain ranges, lakes, islands, and more',
			'learn.geoQuiz.countriesTitle' => 'Countries on map',
			'learn.geoQuiz.subtitle' => 'Guess the country from its outline',
			'learn.geoQuiz.loading' => 'Loading Geo Quiz...',
			'learn.geoQuiz.failedToLoad' => 'Failed to load quizzes',
			'learn.geoQuiz.failedToLoadQuiz' => 'Failed to load quiz',
			'learn.geoQuiz.emptyTitle' => 'No quizzes yet',
			'learn.geoQuiz.emptySubtitle' => 'Geo quizzes will appear here soon.',
			'learn.geoQuiz.countryHint' => 'Region name...',
			'learn.geoQuiz.progressCount' => ({required Object solved, required Object total}) => '${solved} / ${total}',
			'learn.geoQuiz.nextCount' => ({required Object next, required Object total}) => '${next} of ${total}',
			'learn.geoQuiz.correctCount' => ({required Object count}) => '${count} correct',
			'learn.geoQuiz.reset' => 'Reset progress',
			'learn.geoQuiz.mapPlaceholder' => 'Map data will be added next',
			'learn.geoQuiz.newBadge' => 'NEW',
			'learn.geoQuiz.correct' => 'Correct',
			'learn.geoQuiz.wrong' => 'Wrong',
			'learn.geoQuiz.hintTitle' => 'Hint',
			'learn.geoQuiz.hintSubtitle' => 'Tap on a letter to reveal',
			'learn.geoQuiz.next' => 'Next',
			'learn.geoQuiz.pause' => 'Pause',
			'learn.geoQuiz.resume' => 'Resume',
			'learn.geoQuiz.finish' => 'Finish',
			'learn.geoQuiz.completeTitle' => 'Quiz complete',
			'learn.geoQuiz.completeMessage' => ({required Object total, required Object quiz}) => 'You found all ${total} countries in ${quiz}.',
			'learn.geoQuiz.backToQuizzes' => 'Back to quizzes',
			'learn.geoQuiz.playAgain' => 'Play again',
			'learn.geoQuiz.progressReady' => 'Ready to play',
			'learn.geoQuiz.progressFinished' => ({required Object count}) => '${count} finished',
			'learn.geoQuiz.progressInProgress' => ({required Object count}) => '${count} in progress',
			'learn.geoQuiz.progressAllCompleted' => 'All completed',
			'learn.geoQuiz.quizCountriesAfricaTitle' => 'Africa',
			'learn.geoQuiz.quizCountriesEuropeTitle' => 'Europe',
			'learn.geoQuiz.quizCountriesAsiaTitle' => 'Asia',
			'learn.geoQuiz.quizCountriesNorthAmericaTitle' => 'North America',
			'learn.geoQuiz.quizCountriesSouthAmericaTitle' => 'South America',
			'learn.geoQuiz.quizCountriesOceaniaTitle' => 'Oceania',
			'learn.geoQuiz.quizCountriesAllTitle' => 'All Countries',
			'learn.geoQuiz.quizCountriesSubtitle' => 'Countries',
			'learn.geoQuiz.quizCountriesAllSubtitle' => 'World',
			'learn.geoQuiz.quizGeographySeasTitle' => 'Seas',
			'learn.geoQuiz.quizGeographyMountainRangesTitle' => 'Mountain ranges',
			'learn.geoQuiz.quizGeographyLakesTitle' => 'Lakes',
			'learn.geoQuiz.quizGeographyIslandsTitle' => 'Islands',
			'learn.geoQuiz.quizGeographyOtherTitle' => 'Other',
			'learn.geoQuiz.quizGeographyOtherSubtitle' => 'Bays, straits, gulfs, deserts, and more',
			'learn.geoQuiz.descriptionUnavailable' => 'Description is not available yet.',
			'settings.title' => 'Settings',
			'settings.loading' => 'Loading settings...',
			'settings.profile' => 'Profile',
			'settings.profileSubtitle' => 'Name, flying habits, home airport, and interests',
			'settings.profileSummaryNameHome' => ({required Object name, required Object code}) => '${name} · ${code}',
			'settings.profileSummaryHome' => ({required Object code}) => 'Home airport: ${code}',
			'settings.profileEditHint' => 'Tap any item to edit your profile details.',
			'settings.profileNotSet' => 'Not set',
			'settings.profileInterestsSelected' => ({required Object count}) => '${count} selected',
			'settings.historyTitle' => 'History',
			'settings.historySubtitle' => 'All flights and stats',
			'settings.historyLoading' => 'Loading history...',
			'settings.historyLoadError' => 'Failed to load flight history.',
			'settings.historyFlightsLabel' => 'Total flights',
			'settings.historyDistanceLabel' => 'Total distance',
			'settings.historyAllFlights' => 'All flights',
			'settings.historyStatusUpcoming' => 'Upcoming',
			'settings.historyStatusInProgress' => 'In progress',
			'settings.historyStatusCompleted' => 'Completed',
			'settings.historyMapChip' => ({required Object size}) => 'Map ${size}',
			'settings.historyNoMapChip' => 'No map',
			'settings.historySortName' => 'Name',
			'settings.historySortDistance' => 'Distance',
			'settings.historySortDate' => 'Date',
			'settings.historyEmpty' => 'No flights yet.',
			'settings.historySearchHint' => 'Search by airport or city',
			'settings.historyNoResults' => 'No matching flights found.',
			'settings.historyDeleteOfflineData' => 'Delete map only',
			'settings.appearance' => 'Appearance',
			'settings.language' => 'Language',
			'settings.languageSubtitle' => 'App language',
			'settings.languageSystem' => 'System',
			'settings.languageSystemFormat' => ({required Object language}) => '${language} (System)',
			'settings.languageEnglish' => 'English',
			'settings.languageSpanish' => 'Español',
			'settings.languageFrench' => 'Français',
			'settings.languageGerman' => 'Deutsch',
			'settings.theme' => 'Theme',
			'settings.system' => 'System',
			'settings.dark' => 'Dark',
			'settings.light' => 'Light',
			'settings.units' => 'Units',
			'settings.notifications.title' => 'Notifications',
			'settings.notifications.permissionOff' => 'Notifications are off. Enable them to get reminders and forecast alerts for your flights.',
			'settings.notifications.readyTitle' => 'Early reminder',
			'settings.notifications.readySubtitle' => '6 days before the flight',
			'settings.notifications.updatedTitle' => 'Day-before reminder',
			'settings.notifications.updatedSubtitle' => 'The evening before the flight',
			'settings.notifications.summaryOn' => 'On',
			'settings.notifications.summaryOff' => 'Off',
			'settings.storage' => 'Storage',
			'settings.storageTitle' => 'Storage',
			'settings.storageSubtitle' => 'Downloaded maps and disk usage',
			'settings.storageLoading' => 'Loading storage...',
			'settings.storageLoadError' => 'Failed to load storage data.',
			'settings.storageMapsLabel' => 'Downloaded maps',
			'settings.storageTotalSizeLabel' => 'Total size',
			'settings.storageDownloadedMaps' => 'Downloaded maps',
			'settings.storageSortName' => 'Name',
			'settings.storageSortSize' => 'Size',
			'settings.storageMapSize' => ({required Object size}) => 'Size: ${size}',
			'settings.storageEmpty' => 'No downloaded maps yet.',
			'settings.altitude' => 'Altitude',
			'settings.altitudeUnit' => 'Altitude unit',
			'settings.speed' => 'Speed',
			'settings.speedUnit' => 'Speed unit',
			'settings.temperatureUnit' => 'Temperature unit',
			'settings.timeFormat' => 'Time format',
			'settings.distanceUnit' => 'Distance unit',
			'settings.dateFormat' => 'Date format',
			'settings.support' => 'Support',
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
			'settings.advocacyDialogTitle' => 'Glad you\'re enjoying Flymap',
			'settings.advocacyDialogBody' => 'Help other travellers discover Flymap.',
			'settings.advocacyDialogShare' => 'Share with friends',
			'settings.advocacyDialogRate' => 'Rate Flymap',
			'settings.advocacyDialogNotNow' => 'Not now',
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
			'settings.proBannerSubtitleActive' => 'Real routes, offline maps, weather, places and stories unlocked.',
			'settings.proBannerSubtitleFree' => 'Unlock real routes, offline maps, weather, places and stories',
			'settings.proBannerBadgeActive' => 'PRO ACTIVE',
			'subscription.screenTitle' => 'Subscription',
			'subscription.contactSupport' => 'Contact support',
			'subscription.cardTitle' => 'Flymap Pro',
			'subscription.periodTitle' => 'Subscription period',
			'subscription.renewsOrExpires' => 'Renews or expires',
			'subscription.noExpiration' => 'No expiration',
			'subscription.lastChecked' => 'Last checked',
			'subscription.flightUnlockSheetTitle' => 'Unlock Pro features',
			'subscription.flightUnlockOptionTitle' => 'One-time purchase',
			'subscription.flightUnlockOptionBody' => 'Unlock Pro for a single flight',
			'subscription.flightUnlockAction' => 'Buy for one Flight',
			'subscription.flightUnlockUseAction' => 'Use for one Flight',
			'subscription.flightUnlockPriceLoading' => 'Loading price...',
			'subscription.flightUnlockProOptionTitle' => 'Flymap Pro subscription',
			'subscription.flightUnlockAvailableCount' => ({required Object count}) => '${count} flight unlocks available',
			'subscription.flightUnlockProOptionBody' => 'Unlock Pro for unlimited flights',
			'subscription.flightUnlockProAction' => 'View Pro Plans',
			'subscription.flightUnlockUnavailable' => 'Flight unlock is not available right now.',
			'subscription.flightUnlockPurchaseCancelled' => 'Flight unlock purchase cancelled.',
			'subscription.flightUnlockPurchaseFailed' => 'Flight unlock purchase failed. Please try again.',
			'subscription.proFeaturesTitle' => 'What Flymap Pro unlocks',
			'subscription.proFeaturesIncludedTitle' => 'Included with your Pro plan',
			'subscription.proHeroSubtitle' => 'Your window seat, fully unlocked.',
			'subscription.proFeatureRoutesTitle' => 'Recent real-world flight routes',
			'subscription.proFeatureRoutesBody' => 'Follow a recent recorded path instead of an approximate arc.',
			'subscription.proFeatureMapsTitle' => 'Higher-detail maps, available offline',
			'subscription.proFeatureMapsBody' => 'Keep richer maps ready in the air without internet.',
			'subscription.proFeatureTimelineTitle' => 'Full timeline and 10× more places',
			'subscription.proFeatureTimelineBody' => 'See every region and more landmarks along your route.',
			'subscription.proFeatureWeatherTitle' => 'Cloud cover and airport forecasts',
			'subscription.proFeatureWeatherBody' => 'Know what you may see before takeoff.',
			'subscription.proFeaturePoiTitle' => '10x more places on route',
			'subscription.proFeatureArticlesTitle' => 'Complete offline article packs',
			'subscription.proFeatureLearnTitle' => 'Full Learn and Geo Quiz access',
			'subscription.proFeatureLearnBody' => 'Explore every story and geography challenge.',
			'subscription.planAndBillingTitle' => 'Plan & billing',
			'subscription.planLabel' => 'Plan',
			'subscription.activeSubscription' => 'Active subscription',
			'subscription.currentPeriodEnds' => ({required Object date}) => 'Current period ends ${date}',
			'subscription.managePlanAndBilling' => 'Manage plan & billing',
			'subscription.cancelSubscription' => 'Cancel subscription',
			'subscription.cancellationHelper' => 'Before you cancel, the App Store or Google Play will show when your Pro access ends.',
			'subscription.flightPassesTitle' => 'Flight passes',
			'subscription.flightPassesBody' => 'These one-flight unlocks stay available for future flights.',
			'subscription.purchaseHelpTitle' => 'Purchase help',
			'subscription.checkingStatus' => 'Checking your subscription status...',
			'subscription.freePlan' => 'You are on Free plan.',
			'subscription.active' => 'Active',
			'subscription.notActive' => 'Not active',
			'subscription.unknown' => 'Unknown',
			'subscription.manageSubscription' => 'Manage subscription',
			'subscription.restorePurchases' => 'Restore purchases',
			'subscription.upgradeToPro' => 'Upgrade to Pro',
			'subscription.restoreNoSubscription' => 'No active subscription found.',
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
			'createFlight.steps.weatherTitle' => 'Flight weather',
			'createFlight.weather.title' => 'Will you see the ground?',
			'createFlight.weather.loading' => 'Checking the skies along your route…',
			'createFlight.weather.cloudsLoading' => 'Loading clouds…',
			'createFlight.weather.loadFailed' => 'Couldn\'t load the forecast right now. You can retry or continue without it.',
			'createFlight.weather.notDownloadedBody' => 'No forecast was downloaded for this flight. It needs an internet connection before you fly.',
			'createFlight.weather.departureLabel' => 'Departure',
			'createFlight.weather.arrivalLabel' => 'Arrival',
			'createFlight.weather.tomorrow' => 'tomorrow',
			'createFlight.weather.continueWithoutWeather' => 'Continue without weather',
			'createFlight.weather.noDateTitle' => 'Add your flight date & time',
			'createFlight.weather.noDatePickBody' => 'A weather forecast needs both your flight date and departure time.',
			'createFlight.weather.noDatePickButton' => 'Pick date & time',
			'createFlight.weather.noDateRealBody' => 'A weather forecast isn\'t possible without your flight date. Choose a date when you select this flight to see the weather.',
			'createFlight.weather.noDateBackButton' => 'Go back to pick a date',
			'createFlight.weather.forecastTooFarTitle' => 'It\'s too early for a reliable forecast',
			'createFlight.weather.forecastTooFarBody' => ({required Object days}) => 'Weather forecasts are only dependable up to ${days} days ahead. We\'ll notify you before your flight once a reliable forecast is available.',
			'createFlight.weather.pastForecastTitle' => 'This flight date has passed',
			'createFlight.weather.pastForecastBody' => 'Forecasts aren\'t available for past flights.',
			'createFlight.weather.notificationPermissionHint' => 'Notifications are off. Enable them so the forecast alert can reach you.',
			'createFlight.weather.verdictClearTitle' => 'Clear views',
			'createFlight.weather.verdictClearBody' => 'Window seat worth it — the ground should be visible for most of the flight.',
			'createFlight.weather.verdictPatchyTitle' => 'Patchy clouds',
			'createFlight.weather.verdictPatchyBody' => 'Views will come and go between the clouds.',
			'createFlight.weather.verdictCarpetTitle' => 'Cloud carpet',
			'createFlight.weather.verdictCarpetBody' => 'A white sea of clouds beneath you — beautiful, but the ground will mostly stay hidden.',
			'createFlight.weather.verdictOvercastTitle' => 'Overcast skies',
			'createFlight.weather.verdictOvercastBody' => 'Best views at takeoff and landing.',
			'createFlight.weather.estimatedShort' => 'estimated',
			'createFlight.weather.windCalm' => 'Calm',
			'createFlight.weather.windLight' => 'Light wind',
			'createFlight.weather.windBreezy' => 'Breezy',
			'createFlight.weather.windWindy' => 'Windy',
			'createFlight.weather.windStrong' => 'Strong wind',
			'createFlight.weather.proTeaserTitle' => 'Unlock airport weather and clouds along your route',
			'createFlight.weather.attribution' => ({required Object provider, required Object license}) => 'Based on data from ${provider} · Visualization by Flymap · ${license}',
			'createFlight.weather.attributionShare' => ({required Object provider, required Object license}) => '${provider} data · Flymap visualization · ${license}',
			'createFlight.weather.hedge' => 'Forecasts firm up closer to departure.',
			'createFlight.weather.share' => 'Share',
			'createFlight.weather.shareAsImage' => 'Share as image',
			'createFlight.weather.shareAsVideo' => 'Share as video',
			'createFlight.weather.preparingShare' => 'Preparing your share…',
			'createFlight.weather.shareFailed' => 'Couldn\'t prepare the share — try again.',
			'createFlight.weather.updatedRelative' => ({required Object relative}) => 'Updated ${relative}',
			'createFlight.weather.updatedExact' => ({required Object date, required Object time}) => 'Updated ${date}, ${time}',
			'createFlight.weather.updatedJustNow' => 'just now',
			'createFlight.weather.updatedMinutesAgo' => ({required Object minutes}) => '${minutes} min ago',
			'createFlight.weather.updatedHoursAgo' => ({required Object hours}) => '${hours} h ago',
			'createFlight.routeTypeSelector.title' => 'New flight',
			'createFlight.routeTypeSelector.basicTitle' => 'Approximate route',
			'createFlight.routeTypeSelector.basicSubtitle' => 'From airports',
			'createFlight.routeTypeSelector.basicDescription' => 'Works well for short and many mid-haul flights.',
			'createFlight.routeTypeSelector.proTitle' => 'Real route',
			'createFlight.routeTypeSelector.proSubtitle' => 'From recent flights',
			'createFlight.routeTypeSelector.proDescription' => 'Built from the most recently recorded route for the same flight.',
			'createFlight.routeTypeSelector.mostAccurate' => 'Most accurate',
			'createFlight.proAccess.subscriber' => 'Flymap Pro',
			'createFlight.proAccess.subscriberBody' => 'This flight has full Pro access through your Flymap Pro subscription.',
			'createFlight.proAccess.unlockedFlight' => 'This flight is unlocked',
			'createFlight.proAccess.unlockedFlightBody' => 'All Pro features are enabled for this flight.',
			'createFlight.proAccess.tooltip' => 'Pro access info',
			'createFlight.travelDate.inDays' => ({required Object count}) => 'In ${count} days',
			'createFlight.travelDate.today' => 'Today',
			'createFlight.travelDate.tomorrow' => 'Tomorrow',
			'createFlight.travelDate.stepTitle' => 'When are you flying?',
			'createFlight.travelDate.customDate' => 'Pick another date',
			'createFlight.travelDate.pickDate' => 'Pick your travel date',
			'createFlight.travelDate.yourFlightOnDate' => 'Your flight on this date',
			'createFlight.travelDate.changeDate' => 'Change date',
			'createFlight.travelDate.checkingSchedule' => 'Checking the flight schedule…',
			'createFlight.travelDate.noDateYet' => 'No date yet',
			'createFlight.travelDate.skipDate' => 'Continue without a date',
			'createFlight.travelDate.skipDateTimeScreen' => 'Skip date & time',
			'createFlight.travelDate.addDepartureTime' => 'Add departure time',
			'createFlight.travelDate.departureTimeAt' => ({required Object time}) => 'Departure time · ${time}',
			'createFlight.travelDate.departureTimeTitle' => 'Departure time',
			'createFlight.travelDate.departureTimeHint' => 'Set the local departure time to continue.',
			'createFlight.travelDate.departureTimePickDateFirst' => 'Pick a date first, then set the departure time.',
			'createFlight.travelDate.setDepartureTime' => 'Set departure time',
			'createFlight.travelDate.departureTimeSelected' => ({required Object time}) => 'Departure · ${time}',
			'createFlight.travelDate.notificationPermissionTitle' => 'Get flight reminders',
			'createFlight.travelDate.notificationPermissionBody' => 'Allow notifications so Flymap can remind you to check the latest weather before your flight.',
			'createFlight.travelDate.notificationPermissionNotNow' => 'Not now',
			'createFlight.travelDate.notificationPermissionAllow' => 'Allow notifications',
			'createFlight.travelDate.noDepartureOnDateTitle' => 'We couldn\'t find this flight on this date',
			'createFlight.travelDate.noDepartureOnDateBody' => 'Check the date, or set the departure time manually to continue.',
			'createFlight.travelDate.dateCheckFailed' => 'Couldn\'t check this date. Set the departure time manually to continue.',
			'createFlight.flightNumberSearch.title' => 'Flight number',
			'createFlight.flightNumberSearch.subtitle' => 'Enter a flight number (for example BA117).',
			'createFlight.flightNumberSearch.hint' => 'e.g. BA117',
			'createFlight.flightNumberSearch.loading' => 'Searching your flight',
			'createFlight.flightNumberSearch.loadingHint' => 'This can take a few seconds while we check recent flights.',
			'createFlight.flightNumberSearch.invalidFormatError' => 'Enter a valid flight number like BA117.',
			'createFlight.flightNumberSearch.notFoundError' => 'We couldn\'t find that flight number. Make sure it is the same as on your tickets and try again, or find by airports.',
			'createFlight.flightNumberSearch.rateLimitedError' => 'Too many flight lookups right now. Please try again in a moment, or find by airports.',
			'createFlight.flightNumberSearch.providerUnavailableError' => 'Flight data is temporarily unavailable. Please try again in a moment, or find by airports.',
			'createFlight.flightNumberSearch.unexpectedError' => 'Something went wrong while looking up this flight. Please try again, or find by airports.',
			'createFlight.flightNumberSearch.findByAirports' => 'Or enter Airports',
			'createFlight.flightNumberSearch.airportsFallbackButton' => 'Find by airports',
			'createFlight.flightNumberSearch.confirmTitle' => 'Confirm flight',
			'createFlight.flightNumberSearch.foundTitle' => 'We found your flight',
			'createFlight.flightNumberSearch.editFlightNumber' => 'Edit flight number',
			'createFlight.flightNumberSearch.beyondWindowHint' => 'Flying later? For the freshest and most accurate flight map, we recommend downloading within 7 days of your flight.',
			'createFlight.flightNumberSearch.basedOnSameFlightOn' => '* Based on the most recent recorded route for the same flight',
			'createFlight.realRouteAirportSearch.title' => 'Flight by airports',
			'createFlight.realRouteAirportSearch.subtitle' => 'Choose departure and arrival airports to look up recent real flights on this route.',
			'createFlight.realRouteAirportSearch.searchAction' => 'Search recent flights',
			'createFlight.realRouteAirportSearch.loading' => 'Looking up recent real flights',
			'createFlight.realRouteAirportSearch.loadingHint' => 'This can take a few seconds while we check recent route history.',
			'createFlight.realRouteAirportSearch.sorryNoFlightFromTo' => ({required Object departure, required Object arrival}) => 'Sorry, we couldn\'t find any flights from ${departure} to ${arrival}.',
			'createFlight.realRouteAirportSearch.emptyTitle' => 'We couldn\'t find recent flights between these airports',
			'createFlight.realRouteAirportSearch.emptyResults' => 'Make sure you selected the same departure and arrival airports as on your flight ticket.',
			'createFlight.realRouteAirportSearch.searchReverse' => 'Try the reverse direction',
			'createFlight.realRouteAirportSearch.rateLimitedError' => 'Too many flight searches right now. Please try again in a moment.',
			'createFlight.realRouteAirportSearch.providerUnavailableError' => 'Real-flight data is temporarily unavailable. Please try again in a moment.',
			'createFlight.realRouteAirportSearch.unexpectedError' => 'Something went wrong while searching this route. Please try again.',
			'createFlight.realRouteAirportSearch.foundOneTitle' => ({required Object route}) => 'Found 1 flight · ${route}',
			'createFlight.realRouteAirportSearch.foundManyTitle' => ({required Object count, required Object route}) => 'Found ${count} flights · ${route}',
			'createFlight.realRouteAirportSearch.ticketMatchHint' => 'Make sure these match the airports on your flight ticket.',
			'createFlight.realRouteAirportSearch.findByFlightNumber' => 'Find by flight number',
			'createFlight.search.departureHint' => 'Search departure airport',
			'createFlight.search.arrivalHint' => 'Search arrival airport',
			'createFlight.search.removeFavorite' => 'Remove favorite',
			'createFlight.search.addFavorite' => 'Add to favorite',
			'createFlight.search.removeSelectedAirport' => 'Remove selected airport',
			'createFlight.search.favorites' => 'Favorites',
			'createFlight.search.recentAirports' => 'Recent airports',
			'createFlight.search.popularAirports' => 'Popular airports',
			'createFlight.search.removeFromFavorites' => 'Remove from favorites',
			'createFlight.search.noDepartureFound' => 'No departure airports found.',
			'createFlight.search.noArrivalFound' => 'No arrival airports found.',
			'createFlight.search.airportCodeCity' => ({required Object code, required Object city}) => '${code} · ${city}',
			'createFlight.search.airportNameCode' => ({required Object name, required Object code}) => '${name} (${code})',
			'createFlight.mapPreview.routeNotSupportedMsg' => 'Sorry, antimeridian flights are not supported yet.',
			'createFlight.mapPreview.basic' => 'Basic',
			'createFlight.mapPreview.pro' => 'Pro',
			'createFlight.mapPreview.mapDetailInfoTooltip' => 'Route note',
			'createFlight.mapPreview.legendButton' => 'Legend',
			'createFlight.mapPreview.legendTitle' => 'POI legend',
			'createFlight.mapPreview.estimatedMapSize' => ({required Object size}) => 'Estimated map size: ${size}',
			'createFlight.mapPreview.upgradeToPro' => 'Upgrade to Pro',
			'createFlight.mapPreview.basicHint' => 'Basic map detail with limited places',
			'createFlight.mapPreview.proGateHint' => 'Upgrade for a detailed map with all places',
			'createFlight.mapPreview.proHint' => ({required Object count}) => 'Detailed offline map with ${count} places',
			'createFlight.mapPreview.optionsTitle' => 'Approximate route',
			'createFlight.mapPreview.optionsBody' => 'Route is approximate — actual path may vary, especially on long-haul flights.',
			'createFlight.overview.routeNotReady' => 'Route is not ready yet.',
			'createFlight.overview.proPoiUpsell' => 'Free plan includes basic map and limited places',
			_ => null,
		} ?? switch (path) {
			'createFlight.overview.routeNoteTooltip' => 'Route note',
			'createFlight.overview.routeNoteTitle' => 'Approximate route',
			'createFlight.overview.routeNoteBody' => 'Route is approximate — actual path may vary, especially on long-haul flights.',
			'createFlight.overview.realRouteNoteTitle' => 'Real route',
			'createFlight.overview.realRouteNoteBody' => 'This route is based on the most recent recorded route for the same flight.\nActual routing may vary due to weather, air traffic, and operational constraints.',
			'createFlight.overview.approximateRouteLongHaulWarningTitle' => 'This is approximate route',
			'createFlight.overview.approximateRouteLongHaulWarningBody' => 'Approximate routes may be inaccurate for long-haul flights. Use a real route with a flight number instead.',
			'createFlight.overview.approximateRouteUltraLongHaulUnsupportedBody' => 'Approximate routes are not supported for ultra long-haul flights. Use a real route with a flight number instead.',
			'createFlight.overview.startReview' => 'Start review',
			'createFlight.overview.skipReview' => 'Skip review',
			'createFlight.overview.premiumGateTitle' => 'Unlock full route overview',
			'createFlight.overview.premiumGateBody' => 'Free plan includes a limited route preview. Upgrade to Pro to view every region on this route.',
			'createFlight.overview.premiumGateBodyWithCount' => ({required Object count}) => 'Unlock all ${count} regions on this route with Pro.',
			'createFlight.overview.premiumGateCta' => 'Upgrade to Pro',
			'createFlight.overview.buildingHint' => 'This can take a few seconds on longer routes…',
			'createFlight.overview.routeReviewedTitle' => 'Route reviewed',
			'createFlight.overview.routeReviewedSubtitle' => ({required Object regions, required Object departure, required Object arrival}) => 'You will fly over ${regions} from ${departure} to ${arrival}.',
			'createFlight.overview.fullSummary' => 'Full summary',
			'createFlight.overview.routeSummaryTitle' => 'Route Summary',
			'createFlight.overview.routeSummaryDistanceLabel' => 'Distance',
			'createFlight.overview.routeSummaryDurationLabel' => 'Duration',
			'createFlight.overview.routeSummaryRegionsLabel' => 'Regions',
			'createFlight.overview.routeSummaryRegionsTitle' => 'You\'ll fly over',
			'createFlight.overview.routeSummaryPlacesLabel' => 'Places',
			'createFlight.overview.routeSummaryTimelineTitle' => 'Timeline',
			'createFlight.overview.routeSummaryPlacesTitle' => 'Places along the route',
			'createFlight.overview.routeSummaryPoiSearchHint' => 'Search places',
			'createFlight.overview.routeSummaryPoiNoMatches' => 'No places match your search.',
			'createFlight.overview.airportCard.departureDescription' => ({required Object airport}) => 'You\'ll start your journey from ${airport}.',
			'createFlight.overview.airportCard.arrivalDescription' => ({required Object airport}) => 'You\'ll arrive at ${airport}.',
			'createFlight.overview.regionInfo.descriptionUnavailable' => 'Description is not available yet.',
			'createFlight.overview.regionInfo.wikipediaSectionTitle' => 'Wikipedia',
			'createFlight.overview.regionInfo.wikipediaUnavailable' => 'Wikipedia article is not available right now.',
			'createFlight.overview.regionInfo.openWikipedia' => 'Open Wikipedia',
			'createFlight.overview.timeline.takeOffTimeline' => 'Take\noff',
			'createFlight.overview.timeline.land' => 'Land',
			'createFlight.overview.timeline.alsoAroundThisTime' => 'Also around same time:',
			'createFlight.overview.timeline.minuteUnit' => 'min',
			'createFlight.overview.timeline.hourCompactUnit' => 'h',
			'createFlight.overview.timeline.minuteCompactUnit' => 'm',
			'createFlight.overview.timeline.regionType.country' => 'Country',
			'createFlight.overview.timeline.regionType.region' => 'Region',
			'createFlight.overview.timeline.regionType.state' => 'State',
			'createFlight.overview.timeline.regionType.province' => 'Province',
			'createFlight.overview.timeline.regionType.sea' => 'Sea',
			'createFlight.overview.timeline.regionType.ocean' => 'Ocean',
			'createFlight.overview.timeline.regionType.strait' => 'Strait',
			'createFlight.overview.timeline.regionType.channel' => 'Channel',
			'createFlight.overview.timeline.regionType.gulf' => 'Gulf',
			'createFlight.overview.timeline.regionType.bay' => 'Bay',
			'createFlight.overview.timeline.regionType.lake' => 'Lake',
			'createFlight.overview.timeline.regionType.alkalineLake' => 'Alkaline lake',
			'createFlight.overview.timeline.regionType.island' => 'Island',
			'createFlight.overview.timeline.regionType.archipelago' => 'Archipelago',
			'createFlight.overview.timeline.regionType.peninsula' => 'Peninsula',
			'createFlight.overview.timeline.regionType.coast' => 'Coast',
			'createFlight.overview.timeline.regionType.mountainRange' => 'Mountain range',
			'createFlight.overview.timeline.regionType.valley' => 'Valley',
			'createFlight.overview.timeline.regionType.plateau' => 'Plateau',
			'createFlight.overview.timeline.regionType.plain' => 'Plain',
			'createFlight.overview.timeline.regionType.basin' => 'Basin',
			'createFlight.overview.timeline.regionType.lowland' => 'Lowland',
			'createFlight.overview.timeline.regionType.tundra' => 'Tundra',
			'createFlight.overview.timeline.regionType.wetlands' => 'Wetlands',
			'createFlight.overview.timeline.regionType.desert' => 'Desert',
			'createFlight.overview.timeline.regionType.delta' => 'Delta',
			'createFlight.overview.timeline.regionType.reservoir' => 'Reservoir',
			'createFlight.overview.timeline.regionType.continent' => 'Continent',
			'createFlight.overview.timeline.regionType.geoarea' => 'Geographic area',
			'createFlight.overview.timeline.regionType.isthmus' => 'Isthmus',
			'createFlight.overview.timeline.regionType.unknown' => 'Unknown region type',
			'createFlight.wikipedia.title' => 'Download articles and read while you’re in the air',
			'createFlight.wikipedia.loadingIntro' => 'Finding route-related articles...',
			'createFlight.wikipedia.foundIntro' => ({required Object count}) => 'Based on your route we found ${count} relevant articles',
			'createFlight.wikipedia.emptyIntro' => 'No route-related Wikipedia articles found. You can continue with map download only.',
			'createFlight.wikipedia.selectedCount' => ({required Object count}) => '${count} selected',
			'createFlight.wikipedia.unselectAll' => 'Unselect all',
			'createFlight.wikipedia.selectAll' => 'Select all',
			'createFlight.wikipedia.basicHint' => ({required Object count}) => 'Offline articles selected: ${count}',
			'createFlight.wikipedia.proHint' => 'Map and offline data pack',
			'createFlight.wikipedia.proGateHint' => 'Upgrade for the full offline article pack',
			'createFlight.wikipedia.proActiveTitle' => 'Pro active',
			'createFlight.wikipedia.proActiveMessage' => 'Full articles pack unlocked.',
			'createFlight.wikipedia.freeLimitHint' => 'Free plan includes up to 3 offline articles',
			'createFlight.wikipedia.estimatedDownloadSize' => ({required Object size}) => 'Estimated download size: ${size}',
			'createFlight.wikipedia.upgrade' => 'Upgrade to Pro',
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
			'createFlight.realRouteChoice.title' => 'Get the real flight route?',
			'createFlight.realRouteChoice.body' => 'Everything on this flight is unlocked. It still uses an approximate route — enter your flight number and we\'ll rebuild it from the real flight track.',
			'createFlight.realRouteChoice.ctaEnterFlightNumber' => 'Enter my flight number',
			'createFlight.realRouteChoice.ctaKeepRoute' => 'Keep approximate route',
			'preview.calculatingRoute' => 'Calculating flight route...',
			'preview.errorTitle' => 'Error',
			'preview.errorSomethingWrong' => 'Something went wrong',
			'preview.tryAgain' => 'Try Again',
			'preview.downloadCongratsTitle' => 'Congrats! You are all set.',
			'preview.offlineSavedDetail' => 'Map and selected flight data are saved for offline use during your flight.',
			'preview.downloadCompletedTitle' => 'Download completed',
			'preview.shareFlightCard' => 'Show off your awesome flight',
			'preview.shareVideo' => 'Share flight video',
			'preview.share' => 'Share flight card',
			'preview.home' => 'Home',
			'preview.navigatingHome' => 'Navigating to home...',
			'preview.downloadingMapTitle' => 'Downloading assets',
			'preview.cancelDownload' => 'Cancel download',
			'preview.download' => 'Download',
			'preview.flightRoute' => ({required Object distance}) => 'Flight route (~ ${distance})',
			'flight.tabMap' => 'Map',
			'flight.tabDashboard' => 'Dashboard',
			'flight.tabCamera' => 'Camera',
			'flight.tabInfo' => 'Info',
			'flight.hub.timelineTitle' => 'Timeline',
			'flight.hub.timelineSubtitle' => ({required Object count}) => '${count} regions along your route',
			'flight.hub.placesTitle' => 'Places',
			'flight.hub.placesSubtitle' => ({required Object count}) => '${count} places to spot from your window',
			'flight.hub.filterAll' => 'All',
			'flight.hub.noPlaces' => 'No places saved for this flight.',
			'flight.hub.weatherTitle' => 'Weather',
			'flight.hub.weatherCheck' => 'Check your forecast',
			'flight.hub.weatherTooEarly' => 'Too early for a reliable forecast — we\'ll notify you',
			'flight.hub.weatherLocked' => 'Cloud map and airport forecasts — Pro',
			'flight.hub.articlesTitle' => 'Articles',
			'flight.hub.articlesSubtitle' => ({required Object count}) => '${count} articles saved for offline reading',
			'flight.completeDialogTitle' => 'Complete flight?',
			'flight.completeDialogBody' => 'This marks your flight as completed.',
			'flight.completeDialogDeleteOffline' => 'Delete map and offline articles',
			'flight.completeDialogConfirm' => 'Complete',
			'flight.deleteDialogTitle' => 'Are you sure?',
			'flight.deleteDialogMessage' => ({required Object size}) => 'This permanently deletes this flight, including offline map and saved offline articles.\n\nSpace to be regained: ${size}.',
			'flight.yes' => 'Yes',
			'flight.shareRoute' => 'Share route',
			'flight.copyRoute' => 'Copy route',
			'flight.deleteFlight' => 'Delete flight',
			'flight.routeSummaryCopied' => 'Route summary copied',
			'flight.deleted' => 'Flight deleted',
			'flight.deleteError' => ({required Object error}) => 'Error deleting flight: ${error}',
			'flight.map.initializing' => 'Loading map',
			'flight.map.loadingStyle' => 'Loading map',
			'flight.map.offlineNotAvailable' => 'Offline map is not available for this flight.',
			'flight.map.offlineMissing' => 'Offline map file is missing. Please re-download this route.',
			'flight.map.validationFailed' => 'Offline map validation failed. Please re-download this route.',
			'flight.map.loadStyleFailed' => 'Could not load offline map style.',
			'flight.map.sunriseInMinutes' => ({required Object minutes}) => 'Sunrise in ${minutes} min',
			'flight.map.sunsetInMinutes' => ({required Object minutes}) => 'Sunset in ${minutes} min',
			'flight.map.switchTo2D' => 'Switch to 2D',
			'flight.map.switchTo3D' => 'Switch to 3D',
			'flight.map.switchToLightMapStyle' => 'Switch to light map style',
			'flight.map.switchToDarkMapStyle' => 'Switch to dark map style',
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
			'flight.dashboard.gpsSearchingHintWithAge' => ({required Object age}) => 'Looking for GPS. Last fix ${age}.',
			'flight.dashboard.gpsWeak' => 'Weak GPS signal',
			'flight.dashboard.gpsWeakHint' => 'Signal is unstable. Keep device in open sky.',
			'flight.dashboard.gpsWeakHintWithAge' => ({required Object age}) => 'Signal unstable. Last fix ${age}.',
			'flight.dashboard.gpsActive' => 'GPS active',
			'flight.dashboard.gpsActiveHint' => 'Receiving live telemetry.',
			'flight.dashboard.gpsActiveHintWithAge' => ({required Object age}) => 'Last GPS update ${age}.',
			'flight.dashboard.gpsShowingLastKnownData' => 'Showing last known data',
			'flight.dashboard.gpsHelpTooltip' => 'GPS troubleshooting',
			'flight.dashboard.gpsHelpTitle' => 'GPS troubleshooting',
			'flight.dashboard.gpsHelpBody' => 'Looks like GPS signal is not reliable on your phone.',
			'flight.dashboard.gpsHelpStepsTitle' => 'Try this',
			'flight.dashboard.gpsHelpTipLocation' => 'Make sure Location Services are on',
			'flight.dashboard.gpsHelpTipWindow' => 'Move your phone closer to the window',
			'flight.dashboard.gpsHelpTipCase' => 'Remove thick cases or metal accessories',
			'flight.dashboard.gpsHelpTipFlat' => 'Hold your phone still for a few moments',
			'flight.dashboard.gpsHelpFooter' => 'Live tracking resumes automatically once the signal stabilizes.',
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
			'flight.dashboard.groundSpeed' => 'Ground speed',
			'flight.dashboard.altitudeMsl' => 'Altitude MSL',
			'flight.dashboard.outsideAirApprox' => 'Outside air temperature',
			'flight.dashboard.temperatureAvailableAfter' => ({required Object threshold}) => 'Available after ${threshold}',
			'flight.dashboard.temperatureApproxHint' => 'Rough estimate based on altitude',
			'flight.dashboard.headingPanel' => 'Heading',
			'flight.dashboard.flightPhaseTaxi' => 'Taxi',
			'flight.dashboard.flightPhaseGroundRoll' => 'Ground roll',
			'flight.dashboard.flightPhaseTakeoffRoll' => 'Takeoff roll',
			'flight.dashboard.flightPhaseLandingRoll' => 'Landing roll',
			'flight.dashboard.flightPhaseAscending' => 'Ascending',
			'flight.dashboard.flightPhaseCruising' => 'Cruising',
			'flight.dashboard.flightPhaseDescending' => 'Descending',
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
			'flight.dashboard.gForce' => 'G-force',
			'flight.dashboard.gForcePeakLabel' => 'PEAK',
			'flight.dashboard.cabinPressure' => 'Cabin pressure',
			'flight.dashboard.cabinPressureLikeAltitude' => ({required Object altitude}) => 'Feels like ${altitude}',
			'flight.dashboard.cabinPressureCruise' => 'Cruise',
			'flight.dashboard.cabinPressureSeaLevel' => 'Sea level',
			'flight.dashboard.metricInfoGotIt' => 'Got it',
			'flight.dashboard.gForceInfoBody' => 'How heavy you feel right now, measured by your phone. 1.0 g is normal weight; it rises above 1 g when the plane pulls up or touches down, and dips below when you float over a bump.',
			'flight.dashboard.cabinPressureInfoBody' => 'The air pressure inside the cabin. Airliners keep it comfortable but thinner than at sea level — about what you\'d feel on a mountain — which is why your ears pop as it changes.',
			'flight.dashboard.groundSpeedInfoBody' => 'How fast the plane moves over the ground, from GPS. It differs from the airspeed pilots watch, because tailwinds and headwinds push the plane along faster or slower.',
			'flight.dashboard.altitudeInfoBody' => 'The plane\'s height above sea level, from GPS. Airliners usually cruise near 10–12 km, above most clouds and weather.',
			'flight.dashboard.headingInfoBody' => 'The compass direction the plane is pointing, from your GPS course. 0° is north, 90° east, 180° south and 270° west.',
			'flight.dashboard.temperatureInfoBody' => 'An estimate of the outside air temperature from your altitude. It falls steeply with height — often around -50 °C at cruise, even over a warm country.',
			'flight.dashboard.cabinPressureEnableBody' => 'Allow motion access to see the air pressure inside the cabin.',
			'flight.dashboard.cabinPressureEnableButton' => 'Enable',
			'flight.dashboard.cabinPressureEarPainArticle' => 'Feel pain in ears?',
			'flight.upcoming.mapTitle' => 'Begin your flight journey',
			'flight.upcoming.mapSubtitle' => 'Start live tracking once your flight begins',
			'flight.upcoming.dashboardTitle' => 'Begin your flight journey',
			'flight.upcoming.dashboardSubtitle' => 'Start to see your live dashboard',
			'flight.upcoming.checkInButton' => 'Start',
			'flight.upcoming.checkInSuccess' => 'Flight started',
			'flight.upcoming.checkInError' => 'Could not start now. Please try again',
			'flight.info.overviewTitle' => 'Overview',
			'flight.info.overviewLoading' => 'Building route overview...',
			'flight.info.overviewEmpty' => 'Overview is not available yet for this route.',
			'flight.info.loadingRouteInformation' => 'Loading route information...',
			'flight.info.flyOverTitle' => 'Highlights of your route',
			'flight.info.airportsTitle' => 'Airports',
			'flight.info.departure' => 'Departure',
			'flight.info.arrival' => 'Arrival',
			'flight.info.showAll' => 'Show all',
			'flight.info.showAllCount' => ({required Object count}) => 'Show all ${count}',
			'flight.info.showLess' => 'Show less',
			'flight.info.sortByRank' => 'By rank',
			'flight.info.sortByRouteProgress' => 'By route',
			'flight.info.sortByType' => 'By type',
			'flight.info.routeTimelineTitle' => 'Route timeline',
			'flight.info.plannedWaypoints' => ({required Object count}) => '${count} planned waypoints',
			'flight.info.pointsOfInterestTitle' => 'Points of Interest',
			'flight.info.noPoi' => 'No POIs available yet.',
			'flight.info.poiType' => ({required Object type}) => 'Type: ${type}',
			'flight.info.poiFlyOver' => ({required Object view}) => 'Fly-over: ${view}',
			'flight.info.offlineArticlesTitle' => 'Offline Articles',
			'flight.info.regionArticlesTitle' => 'Region articles',
			'flight.info.otherArticlesTitle' => 'Other articles',
			'flight.info.noOfflineArticles' => 'No offline articles downloaded.',
			'flight.info.openSource' => 'Open Source',
			'flight.info.openSourcePage' => 'Open source page',
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
			'flight.route.loadingRouteTimeline' => 'Loading route timeline...',
			'flight.route.noSavedOfflineRegions' => 'No saved offline regions for this flight.',
			'flight.route.currentProgress' => ({required Object percentage, required Object minute}) => 'Current progress: ${percentage}% (around ${minute} from takeoff)',
			'flight.route.nowLabel' => 'Now',
			'flight.route.currentRegionLabel' => 'Current',
			'flight.route.nextRegionLabel' => 'Next',
			'flight.route.arrivingLabel' => 'Arriving',
			'flight.route.arrivedLabel' => 'Arrived',
			'flight.route.etaLabel' => ({required Object time}) => 'ETA: ${time}',
			'flight.route.etaInLabel' => ({required Object time}) => 'in ${time}',
			'flight.route.flyingOverLabel' => 'You are flying over:',
			'flight.route.premiumLockedChipLabel' => 'Unlock',
			'flight.route.premiumGateTitle' => 'Unlock full route timeline',
			'flight.route.premiumGateBody' => 'Upgrade to Pro to see all regions along your route and timeline details.',
			'flight.route.premiumGateBodyWithCount' => ({required Object count}) => 'Unlock all ${count} regions on this route with Premium.',
			'flight.route.premiumGateCta' => 'Upgrade to Pro',
			'flight.route.premiumOfflineTitle' => 'Internet needed to upgrade',
			'flight.route.premiumOfflineBody' => 'You are offline right now. Connect to the internet to upgrade and unlock the full route view.',
			'flight.route.nextHintLabel' => ({required Object region, required Object eta}) => 'Next: ${region} (${eta})',
			'flight.route.etaUnknownLabel' => 'estimating...',
			'shareFlight.title' => 'Share flight',
			'shareFlight.preparingMap' => 'Preparing share preview map...',
			'shareFlight.preparingScreenshot' => 'Preparing screenshot...',
			'shareFlight.share' => 'Share',
			'shareFlight.route' => 'Route',
			'shareFlight.offlineMapMissing' => 'Offline map missing. Using online style.',
			'shareFlight.offlineStyleFailed' => 'Failed to load offline style. Using online style.',
			'shareFlight.captureFailed' => 'Could not capture route screenshot',
			'shareFlight.shareFailed' => 'Failed to share route screenshot',
			'shareFlight.shareText' => ({required Object from, required Object to}) => 'Flight route ${from}-${to}',
			'shareFlight.watermark' => 'Flymap',
			'shareFlight.flightDistance' => 'Flight distance',
			'shareFlight.distanceKm' => ({required Object distance}) => '${distance} km',
			'shareImage.title' => 'Share flight',
			'shareImage.generating' => 'Creating your flight card...',
			'shareImage.share' => 'Share',
			'shareImage.sharing' => 'Sharing...',
			'shareImage.retry' => 'Retry',
			'shareImage.error' => 'Could not generate flight card',
			'shareImage.tagline' => 'Every flight is a discovery',
			'shareImage.brand' => 'Flymap',
			'shareImage.exploreYourFlight' => 'Explore your flight',
			'shareImage.countrySingle' => '1 country',
			'shareImage.countries' => ({required Object count}) => '${count} countries',
			'shareImage.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) on Flymap ✈️',
			'shareImage.unknownCity' => 'Unknown',
			'shareImage.durationUnavailable' => '--',
			'shareImage.durationMinutes' => ({required Object minutes}) => '${minutes} m',
			'shareImage.durationHoursMinutes' => ({required Object hours, required Object minutes}) => '${hours} h ${minutes} m',
			'flightVideo.title' => 'Flight video',
			'flightVideo.preparing' => 'Preparing your map...',
			'flightVideo.rendering' => 'Creating your video...',
			'flightVideo.export' => 'Save video',
			'flightVideo.savedToGallery' => 'Saved to your camera roll',
			'flightVideo.saveSkipped' => 'Couldn\'t save to camera roll — you can still share it',
			'flightVideo.share' => 'Share',
			'flightVideo.sharing' => 'Sharing...',
			'flightVideo.retry' => 'Retry',
			'flightVideo.errorNetwork' => 'Couldn\'t load map imagery. Check your connection and try again.',
			'flightVideo.errorGeneric' => 'Could not create flight video',
			'flightVideo.errorOfflineTitle' => 'You\'re offline',
			'flightVideo.errorOffline' => 'Flight videos load live map imagery, so they need an internet connection. Turn off Flight Mode or reconnect, then try again.',
			'flightVideo.offlineStyleChange' => 'Changing the map style needs a connection.',
			'flightVideo.madeWith' => 'Made with Flymap',
			'flightVideo.shareText' => ({required Object fromCity, required Object fromCode, required Object toCity, required Object toCode}) => '${fromCity} (${fromCode}) → ${toCity} (${toCode}) on Flymap ✈️',
			'flightVideo.removeWatermark' => 'Remove watermark',
			'flightVideo.styleSatellite' => 'Satellite',
			'flightVideo.styleDefault' => 'Default',
			'flightVideo.videoSettings' => 'Video settings',
			'flightVideo.mapStyle' => 'Map style',
			'flightVideo.mysteryDestination' => 'Mystery destination',
			'flightVideo.mysteryDestinationHint' => 'Show "?" until the plane lands',
			'flightVideo.showPins' => 'Country pins',
			'flightVideo.showPinsHint' => 'Drop a pin as the plane crosses each country',
			'flightVideo.showEndCard' => 'Summary card',
			'flightVideo.showEndCardHint' => 'Show the summary card at the end',
			'flightVideo.styleShine' => 'Lè Shine',
			'flightVideo.applySettings' => 'Apply changes',
			'flightVideo.applying' => 'Applying changes...',
			'flightVideo.avatarTitle' => 'Your avatar',
			'flightVideo.avatarHint' => 'Ride your route with your own photo',
			'flightVideo.avatarSetupTitle' => 'Your avatar',
			'flightVideo.avatarPick' => 'Choose photo',
			'flightVideo.avatarChange' => 'Change photo',
			'flightVideo.avatarNameLabel' => 'Name or @handle',
			'flightVideo.avatarNameHint' => 'Optional — shown on the summary card',
			'flightVideo.avatarSave' => 'Save avatar',
			'flightVideo.mysteryTitle' => 'Guess where I\'m flying? ✈️',
			'flightVideo.avatarCardTagline' => 'My flight map',
			'about.title' => 'About Flymap',
			'about.tagline' => 'Turn every flight into a window on the world.',
			'about.chipCuriosity' => 'Curiosity',
			'about.chipGeography' => 'Geography',
			'about.chipAwareness' => 'Awareness',
			'about.missionTitle' => 'Why Flymap',
			'about.missionText' => 'We fly over oceans, mountains and whole countries without ever knowing. Flymap brings back the wonder.',
			'about.valuesTitle' => 'What we stand for',
			'about.valueCuriosityTitle' => 'Curiosity',
			'about.valueCuriosityText' => 'Always know what\'s below you.',
			'about.valueGeographyTitle' => 'Geography',
			'about.valueGeographyText' => 'The world becomes a living atlas.',
			'about.valueAwarenessTitle' => 'Awareness',
			'about.valueAwarenessText' => 'Reconnect with the journey itself.',
			'about.valueOfflineTitle' => 'Offline & private',
			'about.valueOfflineText' => 'On your device. Nothing tracked.',
			'about.closingTitle' => 'See the world differently',
			'about.closingText' => 'Thank you for exploring it with us.',
			'notifications.forecastReadyTitle' => 'Your flight forecast is ready',
			'notifications.forecastReadyBody' => ({required Object route}) => 'Sun or rain at takeoff? Clear views on the way? Your first ${route} forecast is in.',
			'notifications.forecastUpdatedTitle' => 'Your flight is tomorrow',
			'notifications.forecastUpdatedBody' => ({required Object route}) => '${route} — open Flymap for the latest forecast.',
			'notifications.reminderEarlyTitle' => 'Your flight is coming up',
			'notifications.reminderEarlyBody' => ({required Object route}) => '${route} is just a few days away — open the app to explore what you\'ll fly over.',
			'notifications.reminderTomorrowTitle' => 'Your flight is tomorrow',
			'notifications.reminderTomorrowBody' => ({required Object route}) => '${route} tomorrow — don\'t forget to open the app in the air and explore everything you fly over.',
			'onboarding.skip' => 'Skip',
			'onboarding.letsStart' => 'Let\'s start',
			'onboarding.welcomeTitle' => 'Discover what’s below',
			'onboarding.welcomeSubtitle' => 'shows you offline maps and interesting places along your flight',
			'onboarding.nameTitle' => 'Pick a username',
			'onboarding.nameSubtitle' => 'Make discovery personal. You can change it anytime.',
			'onboarding.nameHint' => 'Your name',
			'onboarding.nameExample' => 'Alex',
			'onboarding.frequencyTitle' => 'How often do you fly?',
			'onboarding.frequencySubtitle' => 'Flymap will personalize your experience and make suggestions more relevant',
			'onboarding.frequencyFirstFlight' => 'This is my first flight',
			'onboarding.frequencyFewPerYear' => 'A few times a year',
			'onboarding.frequencyMonthly' => 'About monthly',
			'onboarding.frequencyFrequent' => 'Very often',
			'onboarding.homeAirportTitle' => 'Set your home airport',
			'onboarding.homeAirportSubtitle' => 'Get faster flight setup. You can change it anytime.',
			'onboarding.homeAirportHint' => 'Search home airport',
			'onboarding.popularAirports' => 'Popular airports',
			'onboarding.removeHomeAirport' => 'Remove home airport',
			'onboarding.noHomeAirportFound' => 'No airports found for that search.',
			'onboarding.interestsTitle' => 'Which places do you want to see more of on your map?',
			'onboarding.interestsSubtitle' => 'Choose up to 3 topics to see more relevant places and stories along your flight.',
			'onboarding.interestsHelper' => 'Pick up to 3 topics.',
			'onboarding.interestsSelected' => ({required Object count, required Object max}) => '${count} of ${max} selected',
			'onboarding.interestMountains' => 'Mountains & ridges',
			'onboarding.interestVolcanoes' => 'Volcanoes & geology',
			'onboarding.interestRegions' => 'Cities & regions',
			'onboarding.interestIslands' => 'Islands & coastlines',
			'onboarding.interestNationalParks' => 'National parks & reserves',
			'onboarding.interestRivers' => 'Rivers & lakes',
			'onboarding.planFirstFlight' => 'Start my first flight',
			'onboarding.failedLoadProfile' => 'Failed to load your profile.',
			'onboarding.payoff.title' => ({required Object airport}) => 'Places around ${airport} you shouldn\'t miss',
			'onboarding.payoff.subtitle' => 'You\'ve been flying right over all this — spot them on your next flight:',
			'onboarding.payoff.scanning' => ({required Object airport}) => 'Scanning the skies around ${airport}…',
			'onboarding.payoff.moreNearby' => ({required Object count}) => '…and ${count}+ more to discover nearby:',
			'onboarding.payoff.fallbackTitle' => 'Stop missing what\'s below',
			'onboarding.payoff.fallbackSubtitle' => 'Every flight soars over volcanoes, mountains, islands and lakes most travelers never notice. Flymap shows you what\'s out your window.',
			'onboarding.weatherPayoff.title' => 'Check the weather for your flight',
			'onboarding.weatherPayoff.subtitle' => 'Every flight you plan comes with airport weather and a window-seat cloud forecast.',
			'onboarding.weatherPayoff.exampleBadge' => 'Example',
			'countries.AE' => 'United Arab Emirates',
			'countries.AF' => 'Afghanistan',
			'countries.AG' => 'Antigua and Barbuda',
			'countries.AL' => 'Albania',
			'countries.AM' => 'Armenia',
			'countries.AO' => 'Angola',
			'countries.AR' => 'Argentina',
			'countries.AT' => 'Austria',
			'countries.AU' => 'Australia',
			'countries.AZ' => 'Azerbaijan',
			'countries.BA' => 'Bosnia and Herzegovina',
			'countries.BB' => 'Barbados',
			'countries.BD' => 'Bangladesh',
			'countries.BE' => 'Belgium',
			'countries.BF' => 'Burkina Faso',
			'countries.BG' => 'Bulgaria',
			'countries.BH' => 'Bahrain',
			'countries.BI' => 'Burundi',
			'countries.BJ' => 'Benin',
			'countries.BN' => 'Brunei Darussalam',
			'countries.BO' => 'Bolivia',
			'countries.BR' => 'Brazil',
			'countries.BS' => 'Bahamas',
			'countries.BT' => 'Bhutan',
			'countries.BW' => 'Botswana',
			'countries.BY' => 'Belarus',
			'countries.BZ' => 'Belize',
			'countries.CA' => 'Canada',
			'countries.CD' => 'Congo, Democratic Republic of the',
			_ => null,
		} ?? switch (path) {
			'countries.CF' => 'Central African Republic',
			'countries.CG' => 'Congo',
			'countries.CH' => 'Switzerland',
			'countries.CI' => 'Côte d\'Ivoire',
			'countries.CL' => 'Chile',
			'countries.CM' => 'Cameroon',
			'countries.CN' => 'China',
			'countries.CO' => 'Colombia',
			'countries.CR' => 'Costa Rica',
			'countries.CU' => 'Cuba',
			'countries.CV' => 'Cape Verde',
			'countries.CY' => 'Cyprus',
			'countries.CZ' => 'Czech Republic',
			'countries.DE' => 'Germany',
			'countries.DJ' => 'Djibouti',
			'countries.DK' => 'Denmark',
			'countries.DO' => 'Dominican Republic',
			'countries.DZ' => 'Algeria',
			'countries.EC' => 'Ecuador',
			'countries.EE' => 'Estonia',
			'countries.EG' => 'Egypt',
			'countries.EH' => 'Western Sahara',
			'countries.ER' => 'Eritrea',
			'countries.ES' => 'Spain',
			'countries.ET' => 'Ethiopia',
			'countries.FI' => 'Finland',
			'countries.FJ' => 'Fiji',
			'countries.FR' => 'France',
			'countries.GA' => 'Gabon',
			'countries.GB' => 'United Kingdom',
			'countries.GE' => 'Georgia',
			'countries.GF' => 'French Guiana',
			'countries.GH' => 'Ghana',
			'countries.GM' => 'Gambia',
			'countries.GN' => 'Guinea',
			'countries.GP' => 'Guadeloupe',
			'countries.GQ' => 'Equatorial Guinea',
			'countries.GR' => 'Greece',
			'countries.GT' => 'Guatemala',
			'countries.GW' => 'Guinea-Bissau',
			'countries.GY' => 'Guyana',
			'countries.HK' => 'Hong Kong, China',
			'countries.HN' => 'Honduras',
			'countries.HR' => 'Croatia',
			'countries.HT' => 'Haiti',
			'countries.HU' => 'Hungary',
			'countries.ID' => 'Indonesia',
			'countries.IE' => 'Ireland',
			'countries.IL' => 'Israel',
			'countries.IN' => 'India',
			'countries.IQ' => 'Iraq',
			'countries.IR' => 'Iran, Islamic Rep. of',
			'countries.IS' => 'Iceland',
			'countries.IT' => 'Italy',
			'countries.JM' => 'Jamaica',
			'countries.JO' => 'Jordan',
			'countries.JP' => 'Japan',
			'countries.KE' => 'Kenya',
			'countries.KG' => 'Kyrgyzstan',
			'countries.KH' => 'Cambodia',
			'countries.KM' => 'Comoros',
			'countries.KP' => 'Korea, Dem. People\'s Rep. of',
			'countries.KR' => 'Korea, Republic of',
			'countries.KW' => 'Kuwait',
			'countries.KZ' => 'Kazakhstan',
			'countries.LA' => 'Lao People\'s Dem. Rep.',
			'countries.LB' => 'Lebanon',
			'countries.LK' => 'Sri Lanka',
			'countries.LR' => 'Liberia',
			'countries.LS' => 'Lesotho',
			'countries.LT' => 'Lithuania',
			'countries.LU' => 'Luxembourg',
			'countries.LV' => 'Latvia',
			'countries.LY' => 'Libyan Arab Jamahiriya',
			'countries.MA' => 'Morocco',
			'countries.MD' => 'Moldova, Republic of',
			'countries.ME' => 'Montenegro',
			'countries.MG' => 'Madagascar',
			'countries.MK' => 'Macedonia, The former Yugoslav Rep. of',
			'countries.ML' => 'Mali',
			'countries.MM' => 'Myanmar',
			'countries.MN' => 'Mongolia',
			'countries.MO' => 'Macau, China',
			'countries.MQ' => 'Martinique',
			'countries.MR' => 'Mauritania',
			'countries.MU' => 'Mauritius',
			'countries.MV' => 'Maldives',
			'countries.MW' => 'Malawi',
			'countries.MT' => 'Malta',
			'countries.MX' => 'Mexico',
			'countries.MY' => 'Malaysia',
			'countries.MZ' => 'Mozambique',
			'countries.NA' => 'Namibia',
			'countries.NC' => 'New Caledonia',
			'countries.NE' => 'Niger',
			'countries.NG' => 'Nigeria',
			'countries.NI' => 'Nicaragua',
			'countries.NL' => 'Netherlands',
			'countries.NO' => 'Norway',
			'countries.NP' => 'Nepal',
			'countries.NZ' => 'New Zealand',
			'countries.OM' => 'Oman',
			'countries.PA' => 'Panama',
			'countries.PE' => 'Peru',
			'countries.PG' => 'Papua New Guinea',
			'countries.PH' => 'Philippines',
			'countries.PK' => 'Pakistan',
			'countries.PL' => 'Poland',
			'countries.PR' => 'Puerto Rico',
			'countries.PS' => 'West Bank and Gaza Strip',
			'countries.PT' => 'Portugal',
			'countries.PY' => 'Paraguay',
			'countries.QA' => 'Qatar',
			'countries.RE' => 'Réunion',
			'countries.RO' => 'Romania',
			'countries.RS' => 'Serbia',
			'countries.RU' => 'Russian Federation',
			'countries.RW' => 'Rwanda',
			'countries.SA' => 'Saudi Arabia',
			'countries.SB' => 'Solomon Islands',
			'countries.SD' => 'Sudan, The Republic of',
			'countries.SE' => 'Sweden',
			'countries.SG' => 'Singapore',
			'countries.SI' => 'Slovenia',
			'countries.SK' => 'Slovakia',
			'countries.SL' => 'Sierra Leone',
			'countries.SN' => 'Senegal',
			'countries.SO' => 'Somalia',
			'countries.SR' => 'Suriname',
			'countries.SS' => 'South Sudan, The Republic of',
			'countries.ST' => 'Sao Tome and Principe',
			'countries.SV' => 'El Salvador',
			'countries.SY' => 'Syrian Arab Republic',
			'countries.SZ' => 'Swaziland',
			'countries.TD' => 'Chad',
			'countries.TG' => 'Togo',
			'countries.TH' => 'Thailand',
			'countries.TJ' => 'Tajikistan',
			'countries.TL' => 'Timor-Leste',
			'countries.TM' => 'Turkmenistan',
			'countries.TN' => 'Tunisia',
			'countries.TR' => 'Turkey',
			'countries.TT' => 'Trinidad and Tobago',
			'countries.TW' => 'Taiwan, China',
			'countries.TZ' => 'Tanzania, United Republic of',
			'countries.UA' => 'Ukraine',
			'countries.UG' => 'Uganda',
			'countries.US' => 'United States',
			'countries.UY' => 'Uruguay',
			'countries.UZ' => 'Uzbekistan',
			'countries.VE' => 'Venezuela, Bolivarian Rep. of',
			'countries.VI' => 'Virgin Islands (US)',
			'countries.VN' => 'Viet Nam',
			'countries.YE' => 'Yemen',
			'countries.ZA' => 'South Africa',
			'countries.ZM' => 'Zambia',
			'countries.ZW' => 'Zimbabwe',
			_ => null,
		};
	}
}
