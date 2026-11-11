import 'package:intl/intl.dart';

class AppFormatters {
  static final DateFormat _dateTimeFormat =
      DateFormat('dd MMM yyyy, HH:mm');
  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime.toLocal());
  }

  static String formatDate(DateTime dateTime) {
    return _dateFormat.format(dateTime.toLocal());
  }

  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  static String formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  static String formatShortId(String fullUuid) {
    if (fullUuid.length > 8) {
      return fullUuid.substring(0, 8).toUpperCase();
    }
    return fullUuid.toUpperCase();
  }
}
