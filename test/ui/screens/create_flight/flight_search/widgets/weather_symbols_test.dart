import 'package:flutter_test/flutter_test.dart';
import 'package:flymap/ui/screens/create_flight/flight_preview/steps/weather/weather_symbols.dart';

void main() {
  test('night variants never render daytime sun symbols', () {
    expect(weatherSymbolEmoji('clearsky_night', 0), '🌙');
    expect(weatherSymbolEmoji('fair_night', 20), '🌙');
    expect(weatherSymbolEmoji('partlycloudy_night', 60), '☁️');
  });

  test('day variants keep their daytime symbols', () {
    expect(weatherSymbolEmoji('clearsky_day', 0), '☀️');
    expect(weatherSymbolEmoji('fair_day', 20), '🌤️');
    expect(weatherSymbolEmoji('partlycloudy_day', 60), '⛅');
  });
}
