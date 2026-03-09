import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/hive_event_repository.dart';
import '../domain/event_factory.dart';
import '../domain/event_repository.dart';

/// Repository for working with events (Hive storage)
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return HiveEventRepository();
});

/// Factory used to create new Event instances
final eventFactoryProvider = Provider<EventFactory>((ref) {
  return EventFactory();
});