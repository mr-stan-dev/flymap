class SizeUtils {
  const SizeUtils._();

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';

    const kb = 1024.0;
    const mb = kb * 1024;
    const gb = mb * 1024;

    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} GB';
    }
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    return '${(bytes / kb).toStringAsFixed(0)} KB';
  }
}
