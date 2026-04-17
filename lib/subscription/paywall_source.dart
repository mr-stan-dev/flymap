enum PaywallSource {
  /// User hit paywall because both wiki limit and Pro map detail were gated.
  wikiAndMapPro,

  /// User hit paywall after selecting too many wiki articles.
  wikiLimit,

  /// User hit paywall after choosing Pro map detail.
  mapPro,

  /// User hit paywall from the POI section upsell.
  poiSection,

  /// User opened paywall from the settings subscription banner.
  settingsBanner,

  /// User opened paywall from subscription management screen.
  subscriptionManagement,

  /// User attempted to open locked Learn content.
  learnLockedContent,

  /// User opened paywall from onboarding soft Pro step.
  onboarding,
}

extension PaywallSourceAnalyticsValue on PaywallSource {
  String get analyticsValue {
    return switch (this) {
      PaywallSource.wikiAndMapPro => 'wiki_and_map_pro',
      PaywallSource.wikiLimit => 'wiki_limit',
      PaywallSource.mapPro => 'map_pro',
      PaywallSource.poiSection => 'poi_section',
      PaywallSource.settingsBanner => 'settings_banner',
      PaywallSource.subscriptionManagement => 'subscription_management',
      PaywallSource.learnLockedContent => 'learn_locked_content',
      PaywallSource.onboarding => 'onboarding',
    };
  }
}
