import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_event_repository.dart';
import '../domain/event_factory.dart';
import '../domain/event_repository.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return InMemoryEventRepository();
});

final eventFactoryProvider = Provider<EventFactory>((ref) {
  return EventFactory();
});
