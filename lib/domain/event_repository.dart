import 'event.dart';

abstract class EventRepository {
  Future<List<Event>> getAll();

  Future<Event?> getById(String id);

  Future<void> upsert(Event event);

  Future<void> deleteById(String id);

  Future<void> deleteAll();
}
