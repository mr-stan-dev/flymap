import 'package:flymap/i18n/strings.g.dart';
import 'package:flymap/ui/screens/home/tabs/home/viewmodel/home_tab_state.dart';

extension HomeFlightsSortLabel on HomeFlightsSort {
  String get label {
    switch (this) {
      case HomeFlightsSort.mostRecent:
        return t.home.sort.mostRecent;
      case HomeFlightsSort.longestDistance:
        return t.home.sort.longest;
      case HomeFlightsSort.alphabetical:
        return t.home.sort.alphabetical;
    }
  }
}
