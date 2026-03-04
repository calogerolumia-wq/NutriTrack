class AppDateUtils {
  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime startOfWeekMonday(DateTime date) {
    final day = startOfDay(date);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static DateTime endOfWeekSunday(DateTime date) {
    final monday = startOfWeekMonday(date);
    return monday.add(const Duration(days: 6));
  }

  static String ymdKey(DateTime date) {
    final d = startOfDay(date);
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static const List<String> shortWeekdaysIt = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  static const List<String> longWeekdaysIt = [
    'Lunedi',
    'Martedi',
    'Mercoledi',
    'Giovedi',
    'Venerdi',
    'Sabato',
    'Domenica',
  ];

  static String weekdayShortIt(DateTime date) => shortWeekdaysIt[date.weekday - 1];

  static String weekdayLongIt(DateTime date) => longWeekdaysIt[date.weekday - 1];
}
