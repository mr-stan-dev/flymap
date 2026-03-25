import 'package:flutter/animation.dart';

class DsMotion {
  const DsMotion._();

  static const fast = Duration(milliseconds: 160);
  static const normal = Duration(milliseconds: 260);
  static const emphasis = Duration(milliseconds: 360);

  static const fastInOut = Curves.easeInOutCubic;
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}
