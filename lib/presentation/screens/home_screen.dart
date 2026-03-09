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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const int _defaultStartOffsetMinutes = 10;
  static const int _defaultDurationMinutes = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsControllerProvider);
    final selectedDayNotifier = ref.read(selectedDayProvider.notifier);

    Future<void> openCreateEvent() async {
      final now = DateTime.now().add(
        const Duration(minutes: _defaultStartOffsetMinutes),
      );

      final initialStart = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute,
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

    void openTodayDay() {
      selectedDayNotifier.today();
      context.go(AppRoute.day);
    }

    void openTodayWeek() {
      selectedDayNotifier.today();
      context.go(AppRoute.week);
    }

    void openTodayMonth() {
      selectedDayNotifier.today();
      context.go(AppRoute.month);
    }

    return eventsAsync.when(
      loading: () => const Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Chronolink'),
          actions: [
            IconButton(
              tooltip: 'Подсказка',
              onPressed: () => _showHelpSheet(context),
              icon: const Icon(Icons.help_outline_rounded),
            ),
          ],
        ),
        body: _HomeErrorState(
          message: 'Ошибка загрузки: $error',
          onRetry: () => ref.invalidate(eventsControllerProvider),
        ),
      ),
      data: (events) {
        final upcoming = _upcomingEvents(events);
        final hasEvents = upcoming.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chronolink'),
            actions: [
              IconButton(
                tooltip: 'Подсказка',
                onPressed: () => _showHelpSheet(context),
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ],
          ),
          floatingActionButton: hasEvents
              ? FloatingActionButton(
            tooltip: 'Добавить событие',
            onPressed: openCreateEvent,
            child: const Icon(Icons.add),
          )
              : null,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HomeHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: _NavigationCard(
                          title: 'День',
                          subtitle: 'Сегодня',
                          icon: Icons.calendar_view_day_outlined,
                          onTap: openTodayDay,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NavigationCard(
                          title: 'Неделя',
                          subtitle: 'План',
                          icon: Icons.view_week_outlined,
                          onTap: openTodayWeek,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NavigationCard(
                          title: 'Месяц',
                          subtitle: 'Обзор',
                          icon: Icons.calendar_month_outlined,
                          onTap: openTodayMonth,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ближайшие события',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (hasEvents)
                        Text(
                          '${upcoming.length}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: hasEvents
                        ? ListView.separated(
                      padding: const EdgeInsets.only(bottom: 110),
                      itemCount: upcoming.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final event = upcoming[index];
                        return _UpcomingEventCard(
                          event: event,
                          onTap: () {
                            selectedDayNotifier.setDay(
                              dateOnly(event.startDateTime),
                            );
                            context.go(AppRoute.day);
                          },
                        );
                      },
                    )
                        : _HomeEmptyState(
                      onAdd: openCreateEvent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static List<Event> _upcomingEvents(List<Event> events) {
    final now = DateTime.now();

    final filtered = events
        .where(
          (event) =>
      event.endDateTime.isAfter(now) ||
          dateOnly(event.startDateTime) == dateOnly(now),
    )
        .toList()
      ..sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return filtered.take(6).toList();
  }

  static Future<void> _showHelpSheet(BuildContext context) {
    final theme = Theme.of(context);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xl + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Подсказка',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Кратко о том, что делает каждый экран и каждая важная кнопка.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const _HelpTile(
                  icon: Icons.add_circle_outline,
                  title: 'Добавить событие',
                  subtitle:
                  'Нажми на кнопку “+”. Если список пуст, большая кнопка добавления появится прямо на главном экране.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpTile(
                  icon: Icons.my_location_outlined,
                  title: 'Переход на текущий день',
                  subtitle:
                  'Значок прицела открывает или выбирает сегодняшнюю дату на экранах дня, недели и месяца.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpTile(
                  icon: Icons.calendar_view_day_outlined,
                  title: 'Экран дня',
                  subtitle:
                  'Показывает события на выбранную дату и позволяет их редактировать.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpTile(
                  icon: Icons.view_week_outlined,
                  title: 'Экран недели',
                  subtitle:
                  'Помогает быстро оценить загрузку по дням на ближайшую неделю.',
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Экран месяца',
                  subtitle:
                  'Даёт общий обзор месяца и помогает быстро перейти в нужный день.',
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Понятно'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            'Привет!',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Твой календарь всегда под рукой',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 28),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final timeText = event.allDay
        ? '${formatDate(event.startDateTime)} • Весь день'
        : '${formatDate(event.startDateTime)} • ${formatTime(event.startDateTime)}'
        ' – ${formatTime(event.endDateTime)}';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      timeText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
    required this.onAdd,
  });

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
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.surfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Событий пока нет',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Добавь первое событие, чтобы оно появилось в списке.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Добавить событие'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({
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
              size: 46,
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

class _HelpTile extends StatelessWidget {
  const _HelpTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}