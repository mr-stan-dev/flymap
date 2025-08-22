extension StringUtils on String? {
  bool get isNullOrEmpty => this == null || this?.trim().isEmpty == true;

  bool get isNotNullOrEmpty => !isNullOrEmpty;
}
