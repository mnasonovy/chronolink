/// Утилиты для работы с датами и временем
/// Функции для форматирования дат, сравнения и т.д.

class DateUtils {
  /// Форматирует время в строку (например, "14:30")
  static String formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Форматирует дату в строку (например, "15 Декабря, Понедельник")
  static String formatDate(DateTime dateTime) {
    final months = [
      '', 'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];

    final days = ['', 'понедельник', 'вторник', 'среда', 'четверг', 'пятница', 'суббота', 'воскресенье'];

    final day = dateTime.day;
    final month = months[dateTime.month];
    final dayName = days[dateTime.weekday];

    return '$day $month, ${dayName[0].toUpperCase() + dayName.substring(1)}';
  }

  /// Форматирует дату и время вместе (например, "15 Декабря, 14:30")
  static String formatDateTime(DateTime dateTime) {
    return '${formatDate(dateTime)} ${formatTime(dateTime)}';
  }

  /// Проверяет, одна ли это дата (два DateTime в один и тот же день)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Возвращает количество дней в месяце
  static int getDaysInMonth(int year, int month) {
    if (month == 12) {
      return DateTime(year + 1, 1, 0).day;
    }
    return DateTime(year, month + 1, 0).day;
  }

  /// Возвращает первый день недели в месяце (1 = пн, 7 = вс)
  static int getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1).weekday;
  }

  /// Проверяет, прошло ли событие (дата окончания в прошлом)
  static bool isPastEvent(DateTime endTime) {
    return endTime.isBefore(DateTime.now());
  }

  /// Проверяет, идёт ли событие прямо сейчас
  static bool isCurrentEvent(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }
}