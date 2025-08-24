extension MapperUtils on Map<String, dynamic> {
  T? getAs<T>(String key) {
    final val = this[key];
    return val is T ? val : null;
  }

  String getString(String key, {String defVal = ''}) {
    final val = this[key];
    if (val == null) return defVal;
    return val.toString();
  }

  num? getNum(String key, {double defVal = 0.0}) {
    final val = this[key];
    if (val is num) return val;
    if (val is String) return num.tryParse(val);
    return null;
  }

  double getDouble(String key, {double defVal = 0.0}) {
    final n = getNum(key);
    return n?.toDouble() ?? defVal;
  }

  int getInt(String key, {int defVal = 0}) {
    final n = getNum(key);
    return n?.toInt() ?? defVal;
  }

  bool getBool(String key, {bool defVal = false}) {
    final val = this[key];
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.toLowerCase().trim();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    return defVal;
  }

  Map<String, dynamic>? getMap(String key) {
    final val = this[key];
    if (val is Map) return val.cast<String, dynamic>();
    return null;
  }

  List<dynamic> getList(String key) {
    final val = this[key];
    if (val is List) return val;
    return const [];
  }

  List<Map<String, dynamic>> getListOfMaps(String key) {
    return getList(
      key,
    ).whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
  }
}
