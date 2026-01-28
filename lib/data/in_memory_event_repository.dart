import '../domain/event.dart';
import '../domain/event_repository.dart';

class InMemoryEventRepository implements EventRepository {
  final Map<String, Event> _storage = <String, Event>{};

  @override
  Future<List<Event>> getAll() async {
    final list = _storage.values.toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
    return list;
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
