class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool allDay;
  final int? reminderBeforeMinutes; // null = без напоминания
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    this.allDay = false,
    this.reminderBeforeMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  static const Object _unset = Object();

  Event copyWith({
    String? id,
    String? title,
    Object? description = _unset,
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? allDay,
    Object? reminderBeforeMinutes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _unset)
          ? this.description
          : description as String?,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      allDay: allDay ?? this.allDay,
      reminderBeforeMinutes: identical(reminderBeforeMinutes, _unset)
          ? this.reminderBeforeMinutes
          : reminderBeforeMinutes as int?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}