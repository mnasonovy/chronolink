import 'package:uuid/uuid.dart';

import 'event.dart';

class EventFactory {
  EventFactory({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;

  Event create({
    required String title,
    required DateTime startDateTime,
    required DateTime endDateTime,
    String? description,
    bool allDay = false,
    int? reminderBeforeMinutes,
  }) {
    final now = DateTime.now();
    return Event(
      id: _uuid.v4(),
      title: title.trim(),
      description: (description == null || description.trim().isEmpty)
          ? null
          : description.trim(),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      allDay: allDay,
      reminderBeforeMinutes: reminderBeforeMinutes,
      createdAt: now,
      updatedAt: now,
    );
  }
}
