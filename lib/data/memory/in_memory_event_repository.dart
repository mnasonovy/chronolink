import '../../domain/event.dart';
import '../../domain/event_repository.dart';

/// Простая in-memory реализация репозитория.
/// Используется для тестов или быстрого запуска без Hive.
class InMemoryEventRepository implements EventRepository {
  final Map<String, Event> _storage = {};

  @override
  Future<List<Event>> getAll() async {
    final events = _storage.values.toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return events;
  }

  @override
  Future<Event?> getById(String id) async {
    return _storage[id];
  }

  @override
  Future<void> upsert(Event event) async {
    _storage[event.id] = event;
  }

  @override
  Future<void> deleteById(String id) async {
    _storage.remove(id);
  }

  @override
  Future<void> deleteAll() async {
    _storage.clear();
  }
}