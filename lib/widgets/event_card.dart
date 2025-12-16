/// EventCard — карточка события, которая показывает информацию об одном событии
/// Используется в списках событий

import 'package:flutter/material.dart';
import '../models/event.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class EventCard extends StatelessWidget {
  /// Событие, которое нужно показать
  final Event event;

  /// Функция, которая вызывается при клике на карточку
  final VoidCallback? onTap;

  /// Функция для удаления события
  final VoidCallback? onDelete;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Левая полоса (цветная)
              Container(
                width: 4,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название события
                    Text(
                      event.title,
                      style: AppTextStyles.headline3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    // Описание события
                    if (event.description.isNotEmpty)
                      Text(
                        event.description,
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: AppSpacing.sm),

                    // Время события
                    Text(
                      event.isAllDay
                          ? 'Весь день'
                          : '${DateUtils.formatTime(event.startTime)} - ${DateUtils.formatTime(event.endTime)}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),

              // Кнопка удаления
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
