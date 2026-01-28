import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/event.dart';
import '../../domain/event_repository.dart';

final eventsControllerProvider =
AsyncNotifierProvider<EventsController, List<Event>>(EventsController.new);

class EventsController extends AsyncNotifier<List<Event>> {
  late final EventRepository _repo;

  @override
  Future<List<Event>> build() async {
    _repo = ref.read(eventRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.getAll());
  }

  Future<void> upsert(Event event) async {
    await _repo.upsert(event);
    await refresh();
  }

  Future<void> deleteById(String id) async {
    await _repo.deleteById(id);
    await refresh();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();
    await refresh();
  }
}
