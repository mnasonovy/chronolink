import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/utils/date_format.dart';
import '../../domain/event.dart';
import '../state/events_controller.dart';
import '../state/selected_day_provider.dart';
import 'event_editor_screen.dart';

class DayScreen extends ConsumerWidget {
  const DayScreen({super.key});

  static const int _defaultStartOffsetMinutes = 10;
  static const int _defaultDurationMinutes = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final selectedDayNotifier = ref.read(selectedDayProvider.notifier);

    final dayLabel = formatDate(selectedDay);
    final weekdayLabel = _formatWeekday(selectedDay);

    Future<void> openCreateEvent() async {
      final base = DateTime.now().add(
        const Duration(minutes: _defaultStartOffsetMinutes),
      );

      final initialStart = DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        base.hour,
        base.minute,
      );

      final initialEnd = initialStart.add(
        const Duration(minutes: _defaultDurationMinutes),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventEditorScreen(
            initialStart: initialStart,
            initialEnd: initialEnd,
          ),
        ),
      );
    }

    Future<void> openEditEvent(Event event) async {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EventEditorScreen(initialEvent: event),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('День'),
        actions: [
          IconButton(
            tooltip: 'Главный экран',
            onPressed: () => context.go(AppRoute.home),
            icon: const Icon(Icons.home_outlined),
          ),
          IconButton(
            tooltip: 'Месяц',
            onPressed: () => context.go(AppRoute.month),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
          IconButton(
            tooltip: 'Неделя',
            onPressed: () => context.go(AppRoute.week),
            icon: const Icon(Icons.view_week_outlined),
          ),
          IconButton(
            tooltip: 'Сегодня',
            onPressed: selectedDayNotifier.today,
            icon: const Icon(Icons.my_location_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Добавить событие',
        onPressed: openCreateEvent,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            children: [
              _TopBar(
                dayLabel: dayLabel,
                weekdayLabel: weekdayLabel,
                onPrev: selectedDayNotifier.prevDay,
                onNext: selectedDayNotifier.nextDay,
                onPick: () => _pickDate(context, ref, selectedDay),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: eventsAsync.when(
                  data: (events) {
                    final filteredEvents = events
                        .where(
                          (event) => dateOnly(event.startDateTime) == selectedDay,
                    )
                        .toList()
                      ..sort(
                            (a, b) => a.startDateTime.compareTo(b.startDateTime),
                      );

                    return _EventsList(
                      selectedDay: selectedDay,
                      events: filteredEvents,
                      onDelete: (id) async {
                        await ref
                            .read(eventsControllerProvider.notifier)
                            .deleteById(id);
                      },
                      onTap: openEditEvent,
                      onAdd: openCreateEvent,
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => _ErrorState(
                    message: 'Ошибка загрузки событий: $error',
                    onRetry: () => ref.invalidate(eventsControllerProvider),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _pickDate(
      BuildContext context,
      WidgetRef ref,
      DateTime selectedDay,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDay,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Выбери дату',
    );

    if (picked == null) return;

    ref.read(selectedDayProvider.notifier).setDay(dateOnly(picked));
  }

  static String _formatWeekday(DateTime dt) {
    const names = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return names[dt.weekday - 1];
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.dayLabel,
    required this.weekdayLabel,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
  });

  final String dayLabel;
  final String weekdayLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Предыдущий день',
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: onPick,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  children: [
                    Text(
                      dayLabel,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.todayBadge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        weekdayLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Следующий день',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class _EventsList extends StatelessWidget {
  const _EventsList({
    required this.selectedDay,
    required this.events,
    required this.onDelete,
    required this.onTap,
    required this.onAdd,
  });

  final DateTime selectedDay;
  final List<Event> events;
  final Future<void> Function(String id) onDelete;
  final Future<void> Function(Event event) onTap;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _EmptyState(
        dayLabel: formatDate(selectedDay),
        onAdd: onAdd,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          onTap: () => onTap(event),
          onDelete: () => onDelete(event.id),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timeText = event.allDay
        ? 'Весь день'
        : '${formatTime(event.startDateTime)} — ${formatTime(event.endDateTime)}';

    final reminderText = _buildReminderText(event.reminderBeforeMinutes);
    final description = event.description?.trim();

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                constraints: const BoxConstraints(minHeight: 72),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (reminderText != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Напоминание: $reminderText',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Удалить',
                onPressed: onDelete,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _buildReminderText(int? reminderMinutes) {
    if (reminderMinutes == null) return null;
    if (reminderMinutes == 0) return 'В момент начала';
    if (reminderMinutes == 1) return 'За 1 минуту';
    if (reminderMinutes >= 2 && reminderMinutes <= 4) {
      return 'За $reminderMinutes минуты';
    }
    return 'За $reminderMinutes минут';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.dayLabel,
    required this.onAdd,
  });

  final String dayLabel;
  final Future<void> Function() onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'На $dayLabel событий нет',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Нажми на “+”, чтобы добавить первое событие.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Добавить событие'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}