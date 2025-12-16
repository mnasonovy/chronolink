/// HomeScreen — главный экран приложения
/// Показывает список событий и кнопку добавления нового события

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/event_provider.dart';
import '../widgets/event_card.dart';
import '../widgets/calendar_widget.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import 'add_event_screen.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Выбранный день в календаре
  DateTime? _selectedDay;

  /// Режим отображения: 'month', 'week', 'day'
  String _viewMode = 'day';

  @override
  void initState() {
    super.initState();

    // При первом запуске добавляем тестовые события
    Future.microtask(() {
      context.read<EventProvider>().addSampleEvents();
    });
  }

  /// Перейти на экран добавления события
  void _navigateToAddEvent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddEventScreen(),
      ),
    );
  }

  /// Перейти на экран деталей события
  void _navigateToEventDetails(String eventId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EventDetailsScreen(eventId: eventId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.homeTitle),
          elevation: 0,
        ),
        body: Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Календарь
                      CalendarWidget(
                      selectedDay: _selectedDay,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Кнопки выбора режима просмотра
                    Row(
                      children: [
                        _buildViewModeButton('День', 'day'),
                        const SizedBox(width: AppSpacing.md),
                        _buildViewModeButton('Неделя', 'week'),
                        const SizedBox(width: AppSpacing.md),
                        _buildViewModeButton('Месяц', 'month'),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Список событий
                    if (_selectedDay != null)
                Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'События на ${DateUtils.formatDate(_selectedDay!)}',
                    style: AppTextStyles.headline2,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),

              // Список карточек событий
              Builder(
              builder: (context) {
              final eventsForDay = _selectedDay != null
              ? eventProvider.getEventsForDay(_selectedDay!)
                  : eventProvider.getUpcomingEvents();


              if (eventsForDay.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Нет событий',
                          style: AppTextStyles.headline3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Нажмите кнопку + чтобы добавить новое событие',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: eventsForDay.length,
                itemBuilder: (context, index) {
                  final event = eventsForDay[index];
                  return EventCard(
                    event: event,
                    onTap: () => _navigateToEventDetails(event.id),
                    onDelete: () {
                      eventProvider.deleteEvent(event.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.eventDeleted),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  );
                },
              );
              },
              ),
                      ],
                    ),
                ),
              );
            },
        ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddEvent,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Кнопка для выбора режима просмотра
  Widget _buildViewModeButton(String label, String mode) {
    final isActive = _viewMode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          setState(() {
            _viewMode = mode;
          });
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isActive ? AppColors.primary : Colors.transparent,
          side: BorderSide(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }
}
