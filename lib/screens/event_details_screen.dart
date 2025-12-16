/// EventDetailsScreen — экран для просмотра деталей события
/// Показывает полную информацию о событии

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class EventDetailsScreen extends StatelessWidget {
  /// ID события, которое нужно показать
  final String eventId;

  const EventDetailsScreen({
    Key? key,
    required this.eventId,
  }) : super(key: key);

  /// Удалить событие
  void _deleteEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие?'),
        content: const Text('Это действие нельзя отменить'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.read<EventProvider>().deleteEvent(eventId);
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.eventDeleted),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.eventDetailsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteEvent(context),
            ),
          ],
        ),
        body: Consumer<EventProvider>(
            builder: (context, eventProvider, child) {
              final event = eventProvider.getEventById(eventId);

              if (event == null) {
                return const Center(
                  child: Text('Событие не найдено'),
                );
              }

              return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Название события
                      Text(
                      event.title,
                      style: AppTextStyles.headline1,
                    ),

                    const SizedBox(height: AppSpacing.lg),


                        // Карточка с основной информацией
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Дата начала',
                                  value: DateUtils.formatDate(event.startTime),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (!event.isAllDay)
                                  _buildInfoRow(
                                    icon: Icons.access_time,
                                    label: 'Время начала',
                                    value: DateUtils.formatTime(event.startTime),
                                  ),
                                if (!event.isAllDay)
                                  const SizedBox(height: AppSpacing.md),
                                _buildInfoRow(
                                  icon: Icons.calendar_today,
                                  label: 'Дата окончания',
                                  value: DateUtils.formatDate(event.endTime),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (!event.isAllDay)
                                  _buildInfoRow(
                                    icon: Icons.access_time,
                                    label: 'Время окончания',
                                    value: DateUtils.formatTime(event.endTime),
                                  ),
                                if (!event.isAllDay)
                                  const SizedBox(height: AppSpacing.md),
                                if (event.isAllDay)
                                  _buildInfoRow(
                                    icon: Icons.done_all,
                                    label: 'Тип события',
                                    value: 'Весь день',
                                  ),
                                if (event.isAllDay)
                                  const SizedBox(height: AppSpacing.md),
                                _buildInfoRow(
                                  icon: Icons.notifications,
                                  label: 'Напоминание',
                                  value: '${event.reminderBefore} минут',
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // Описание события
                        if (event.description.isNotEmpty) ...[
                          Text(
                            'Описание',
                            style: AppTextStyles.headline3,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Text(
                                event.description,
                                style: AppTextStyles.bodyLarge,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppSpacing.xl),

                        // Кнопка возврата
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Вернуться'),
                          ),
                        ),
                      ],
                    ),
                  ),
              );
            },
        ),
    );
  }


  /// Строка с информацией (иконка + название + значение)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: AppTextStyles.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
