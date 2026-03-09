import 'package:hive/hive.dart';

import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'hive_event.dart';

class HiveEventRepository implements EventRepository {
  static const String _boxName = 'events';
  static const int _adapterTypeId = 1;

  Future<Box<HiveEvent>> _openBox() async {
    if (!Hive.isAdapterRegistered(_adapterTypeId)) {
      Hive.registerAdapter(HiveEventAdapter());
    }

    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<HiveEvent>(_boxName);
    }

    return Hive.openBox<HiveEvent>(_boxName);
  }

  @override
  Future<List<Event>> getAll() async {
    final box = await _openBox();

    final events = box.values
        .map(_toDomain)
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return events;
  }

  @override
  Future<Event?> getById(String id) async {
    final box = await _openBox();
    final key = _findKeyByEventId(box, id);

    if (key == null) return null;

    final hiveEvent = box.get(key);
    if (hiveEvent == null) return null;

    return _toDomain(hiveEvent);
  }

  @override
  Future<void> upsert(Event event) async {
    final box = await _openBox();
    final key = _findKeyByEventId(box, event.id);
    final hiveEvent = _fromDomain(event);

    if (key == null) {
      await box.add(hiveEvent);
      return;
    }

    await box.put(key, hiveEvent);
  }

  @override
  Future<void> deleteById(String id) async {
    final box = await _openBox();
    final key = _findKeyByEventId(box, id);

    if (key == null) return;

    await box.delete(key);
  }

  @override
  Future<void> deleteAll() async {
    final box = await _openBox();
    await box.clear();
  }

  dynamic _findKeyByEventId(Box<HiveEvent> box, String eventId) {
    for (final key in box.keys) {
      final item = box.get(key);
      if (item?.id == eventId) {
        return key;
      }
    }
    return null;
  }

  Event _toDomain(HiveEvent event) {
    return Event(
      id: event.id,
      title: event.title,
      description: event.description,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      allDay: event.allDay,
      reminderBeforeMinutes: event.reminderBeforeMinutes,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  HiveEvent _fromDomain(Event event) {
    return HiveEvent(
      id: event.id,
      title: event.title,
      description: event.description,
      startDateTime: event.startDateTime,
      endDateTime: event.endDateTime,
      allDay: event.allDay,
      reminderBeforeMinutes: event.reminderBeforeMinutes,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }
}