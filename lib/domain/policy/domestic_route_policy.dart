class DomesticRoutePolicy {
  const DomesticRoutePolicy._();

  static bool isDomestic({
    required String originCountryCode,
    required String destinationCountryCode,
  }) {
    final origin = originCountryCode.trim().toUpperCase();
    final destination = destinationCountryCode.trim().toUpperCase();
    return origin.isNotEmpty && origin == destination;
  }
}
