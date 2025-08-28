import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'logger.dart';

class CubitStateObserver extends BlocObserver {
  CubitStateObserver._();

  static final _instance = CubitStateObserver._();
  static final _logger = Logger('Bloc');

  factory CubitStateObserver.create() {
    return _instance;
  }

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      _logger.log('OnCreate: [${bloc.runtimeType.toString()}]');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    if (kDebugMode) {
      _logger.log('[${bloc.runtimeType.toString()}] nextState: ${change.nextState}');
    }
    super.onChange(bloc, change);
  }
}
