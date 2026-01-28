import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/event.dart';
import '../../presentation/state/events_controller.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronolink • Day'),
        actions: [
          IconButton(
            tooltip: 'Delete all',
            onPressed: () => ref.read(eventsControllerProvider.notifier).deleteAll(),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final factory = ref.read(eventFactoryProvider);
          final now = DateTime.now();
          final event = factory.create(
            title: 'Demo event',
            description: 'Created from Day screen',
            startDateTime: now.add(const Duration(minutes: 5)),
            endDateTime: now.add(const Duration(minutes: 35)),
            reminderBeforeMinutes: 10,
          );

          await ref.read(eventsControllerProvider.notifier).upsert(event);
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => context.go('/month'),
                  child: const Text('Month'),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/week'),
                  child: const Text('Week'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: eventsAsync.when(
                data: (events) => _EventsList(
                  events: events,
                  onDelete: (id) =>
                      ref.read(eventsControllerProvider.notifier).deleteById(id),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(
                  child: Text('Error: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({
    required this.events,
    required this.onDelete,
  });

  final List<Event> events;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No events yet. Tap + to add one.'));
    }

    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final e = events[index];
        return ListTile(
          title: Text(e.title),
          subtitle: Text(
            '${e.startDateTime} → ${e.endDateTime}'
                '${e.reminderBeforeMinutes == null ? '' : ' • remind ${e.reminderBeforeMinutes}m'}',
          ),
          trailing: IconButton(
            tooltip: 'Delete',
            onPressed: () => onDelete(e.id),
            icon: const Icon(Icons.close),
          ),
        );
      },
    );
  }
}
