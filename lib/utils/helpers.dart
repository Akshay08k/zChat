import 'package:intl/intl.dart';

class Helpers {
  static String formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      return DateFormat.Hm().format(dt); // Only time if today
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}
