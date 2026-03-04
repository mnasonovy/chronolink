import 'package:hive/hive.dart';

import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'hive_event.dart';

class HiveEventRepository implements EventRepository {
  static const _boxName = 'events';

  Future<Box<HiveEvent>> _openBox() async {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HiveEventAdapter());
    }
    return Hive.openBox<HiveEvent>(_boxName);
  }

  @override
  Future<List<Event>> getAll() async {
    final box = await _openBox();
    final list = box.values.map(_toDomain).toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
  }

  @override
  Future<Event?> getById(String id) async {
    final box = await _openBox();
    for (final hiveEvent in box.values) {
      if (hiveEvent.id == id) return _toDomain(hiveEvent);
    }
    return null;
  }

  @override
  Future<void> upsert(Event event) async {
    final box = await _openBox();

    dynamic existingKey;
    for (final k in box.keys) {
      final item = box.get(k);
      if (item?.id == event.id) {
        existingKey = k;
        break;
      }
    }

    final hiveEvent = _fromDomain(event);

    if (existingKey == null) {
      await box.add(hiveEvent);
    } else {
      await box.put(existingKey, hiveEvent);
    }
  }

  @override
  Future<void> deleteById(String id) async {
    final box = await _openBox();

    dynamic keyToDelete;
    for (final k in box.keys) {
      final item = box.get(k);
      if (item?.id == id) {
        keyToDelete = k;
        break;
      }
    }

    if (keyToDelete != null) {
      await box.delete(keyToDelete);
    }
  }

  @override
  Future<void> deleteAll() async {
    final box = await _openBox();
    await box.clear();
  }

  // mappers
  Event _toDomain(HiveEvent e) => Event(
    id: e.id,
    title: e.title,
    description: e.description,
    startDateTime: e.startDateTime,
    endDateTime: e.endDateTime,
    allDay: e.allDay,
    reminderBeforeMinutes: e.reminderBeforeMinutes,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );

  HiveEvent _fromDomain(Event e) => HiveEvent(
    id: e.id,
    title: e.title,
    description: e.description,
    startDateTime: e.startDateTime,
    endDateTime: e.endDateTime,
    allDay: e.allDay,
    reminderBeforeMinutes: e.reminderBeforeMinutes,
    createdAt: e.createdAt,
    updatedAt: e.updatedAt,
  );
}
