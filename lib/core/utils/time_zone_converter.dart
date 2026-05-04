import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class TimeZoneConverter {
  static Map<String, DateTime> convert(DateTime base, String baseZone) {
    final zones = <String, tz.Location>{
      'WIB': tz.getLocation('Asia/Jakarta'),
      'WITA': tz.getLocation('Asia/Makassar'),
      'WIT': tz.getLocation('Asia/Jayapura'),
      'London': tz.getLocation('Europe/London'),
      'New York': tz.getLocation('America/New_York'),
      'Tokyo': tz.getLocation('Asia/Tokyo'),
    };

    final baseLocation = zones[baseZone] ?? tz.local;
    final zoned = tz.TZDateTime.from(base, baseLocation);

    return zones.map((key, location) {
      final converted = tz.TZDateTime.from(zoned, location);
      return MapEntry(key, converted);
    });
  }

  static String format(DateTime value, {bool is24Hour = true}) {
    final pattern = is24Hour ? 'HH:mm' : 'hh:mm a';
    return DateFormat(pattern).format(value);
  }
}
