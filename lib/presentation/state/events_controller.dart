import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/services/notification_service.dart';
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

    // Уведомления не должны ломать сохранение события.
    try {
      await NotificationService.scheduleEventReminder(
        eventId: event.id,
        title: event.title,
        eventStartLocal: event.startDateTime,
        reminderBeforeMinutes: event.reminderBeforeMinutes,
      );
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Reminder scheduling failed: $e\n$st');
      }
    }

    await refresh();
  }

  Future<void> deleteById(String id) async {
    await _repo.deleteById(id);

    try {
      await NotificationService.cancelEventReminder(id);
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Reminder cancel failed: $e\n$st');
      }
    }

    await refresh();
  }

  Future<void> deleteAll() async {
    await _repo.deleteAll();

    try {
      await NotificationService.cancelAll();
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Cancel all reminders failed: $e\n$st');
      }
    }

    await refresh();
  }
}