enum RatePromptTrigger { flightMapDownloadSuccess }

extension RatePromptTriggerStorageKey on RatePromptTrigger {
  String get storageKey {
    return switch (this) {
      RatePromptTrigger.flightMapDownloadSuccess =>
        'flight_map_download_success',
    };
  }
}
