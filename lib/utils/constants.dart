/// Файл с константами приложения
/// Все важные значения (цвета, тексты, временные значения) в одном месте

import 'package:flutter/material.dart';

/// Цвета приложения
class AppColors {
  static const Color primary = Color(0xFF00897B); // Тёмный циан (основной цвет)
  static const Color primaryLight = Color(0xFF4DB6AC); // Светлый циан
  static const Color primaryDark = Color(0xFF00695C); // Ещё темнее циан

  static const Color background = Color(0xFFFAFAFA); // Светло-серый (фон)
  static const Color surface = Colors.white; // Белый (поверхность карточек)

  static const Color text = Color(0xFF212121); // Почти чёрный (основной текст)
  static const Color textSecondary = Color(0xFF757575); // Серый (вспомогательный текст)

  static const Color success = Color(0xFF4CAF50); // Зелёный (успех)
  static const Color error = Color(0xFFFF5252); // Красный (ошибка)
  static const Color warning = Color(0xFFFFC107); // Оранжевый (предупреждение)

  static const Color divider = Color(0xFFBDBDBD); // Серый (разделитель)
}

/// Текстовые стили
class AppTextStyles {
  // Заголовки
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  // Основной текст
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.text,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Кнопки
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Лейблы (подписи к полям)
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );
}

/// Отступы и размеры
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Радиусы скругления углов
class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double circle = 999; // Для полностью круглых элементов
}

/// Тексты и строки приложения
class AppStrings {
  // Основные
  static const String appName = 'ChronoLink';
  static const String appSubtitle = 'Ваш персональный трекер расписания';

  // Кнопки
  static const String addEvent = 'Добавить событие';
  static const String editEvent = 'Редактировать событие';
  static const String deleteEvent = 'Удалить событие';
  static const String save = 'Сохранить';
  static const String cancel = 'Отмена';
  static const String delete = 'Удалить';
  static const String back = 'Назад';

  // Экран добавления события
  static const String eventTitle = 'Название события';
  static const String eventDescription = 'Описание';
  static const String eventStartTime = 'Время начала';
  static const String eventEndTime = 'Время окончания';
  static const String eventReminder = 'Напоминание за (мин.)';
  static const String allDayEvent = 'Событие весь день';

  // Сообщения
  static const String eventAdded = 'Событие добавлено!';
  static const String eventDeleted = 'Событие удалено';
  static const String fillAllFields = 'Пожалуйста, заполните все поля';
  static const String invalidTimeRange = 'Время окончания должно быть позже времени начала';

  // Экраны
  static const String homeTitle = 'ChronoLink';
  static const String addEventTitle = 'Новое событие';
  static const String eventDetailsTitle = 'Детали события';


  // Календарь
  static const List<String> monthNames = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];

  static const List<String> dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  static const List<String> dayNamesLong = ['Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница', 'Суббота', 'Воскресенье'];
}

/// Длительности анимаций
class AppDurations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
}