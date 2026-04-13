enum LearnAccess { free, pro }

extension LearnAccessParser on LearnAccess {
  static LearnAccess fromRaw(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'free':
        return LearnAccess.free;
      case 'pro':
        return LearnAccess.pro;
      default:
        throw FormatException('Unsupported learn access value: "$raw"');
    }
  }
}
