/// Модель события для приложения ChronoLink
/// Описывает структуру одного события (встреча, задача, занятие и т.д.)
class Event {
  /// Уникальный идентификатор события
  final String id;

  /// Название события (например, "Математика")
  final String title;

  /// Описание события (например, "Кабинет 304")
  final String description;

  /// Дата и время начала события
  final DateTime startTime;

  /// Дата и время окончания события
  final DateTime endTime;

  /// За сколько минут до события показать напоминание
  final int reminderBefore; // в минутах

  /// Событие весь день или в определённое время?
  final bool isAllDay;

  /// Конструктор (способ создать новое событие)
  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.reminderBefore,
    required this.isAllDay,
  });

  /// Метод для преобразования события в словарь (для сохранения)
  /// Нужен для будущей работы с базой данных
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'reminderBefore': reminderBefore,
      'isAllDay': isAllDay,
    };
  }

  /// Метод для создания события из словаря (для загрузки из БД)
  /// Нужен для будущей работы с базой данных
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      reminderBefore: json['reminderBefore'] as int,
      isAllDay: json['isAllDay'] as bool,
    );
  }

  /// Метод для создания копии события с изменениями
  /// Полезен когда нужно отредактировать событие
  Event copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    int? reminderBefore,
    bool? isAllDay,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reminderBefore: reminderBefore ?? this.reminderBefore,
      isAllDay: isAllDay ?? this.isAllDay,
    );
  }
}