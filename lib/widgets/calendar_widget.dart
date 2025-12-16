/// CalendarWidget — простой календарь, который показывает дни месяца
/// Можно нажимать на дни, чтобы выбрать дату

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart' as du;

class CalendarWidget extends StatefulWidget {
  /// Функция, которая вызывается при выборе дня
  final Function(DateTime) onDaySelected;

  /// День, который изначально выбран
  final DateTime? selectedDay;

  const CalendarWidget({
    Key? key,
    required this.onDaySelected,
    this.selectedDay,
  }) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  /// Текущий месяц и год, который показываем
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = widget.selectedDay ?? DateTime.now();
  }

  /// Предыдущий месяц
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  /// Следующий месяц
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Информация о месяце
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = du.DateUtils.getDaysInMonth(year, month);
    final firstDayOfWeek = du.DateUtils.getFirstDayOfMonth(year, month) - 1; // 0 = пн, 6 = вс

    // Названия месяцев
    final monthNames = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];

    // Названия дней недели
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Card(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
              // Заголовок (месяц и год)
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Кнопка "Предыдущий месяц"
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),

                // Название месяца
                Text(
                  '${monthNames[month - 1]} $year',
                  style: AppTextStyles.headline2,
                ),

                // Кнопка "Следующий месяц"
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Строка с названиями дней недели
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: dayNames.map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Сетка дней месяца
            GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1.2,
                ),
                itemCount: firstDayOfWeek + daysInMonth,
                itemBuilder: (context, index) {
                  // Если это пустая ячейка (до первого дня месяца)
                  if (index < firstDayOfWeek) {
                    return Container();
                  }

                  // Номер дня
                  final day = index - firstDayOfWeek + 1;
                  final date = DateTime(year, month, day);


                  // Проверяем, выбран ли этот день
                  final isSelected = widget.selectedDay != null &&
                      du.DateUtils.isSameDay(date, widget.selectedDay!);

                  // Проверяем, это ли сегодня
                  final isToday = du.DateUtils.isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: () => widget.onDaySelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday ? AppColors.primaryLight.withOpacity(0.3) : Colors.transparent),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primaryLight, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  );
                },
            ),
              ],
            ),
        ),
    );
  }
}
