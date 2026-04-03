enum PaywallSource {
  wikiAndMapPro,
  wikiLimit,
  mapPro,
  settingsBanner,
  subscriptionManagement,
}

extension PaywallSourceAnalyticsValue on PaywallSource {
  String get analyticsValue {
    return switch (this) {
      PaywallSource.wikiAndMapPro => 'wiki_and_map_pro',
      PaywallSource.wikiLimit => 'wiki_limit',
      PaywallSource.mapPro => 'map_pro',
      PaywallSource.settingsBanner => 'settings_banner',
      PaywallSource.subscriptionManagement => 'subscription_management',
    };
  }
}
