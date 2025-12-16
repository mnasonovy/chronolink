/// AddEventScreen — экран для добавления нового события
/// Пользователь вводит название, описание, время и т.д.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({Key? key}) : super(key: key);

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  // Контроллеры для текстовых полей (хранят то, что вводит пользователь)
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _reminderController;

  // Выбранная дата и время
  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: 0);

  // Событие весь день или нет?
  bool _isAllDay = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _reminderController = TextEditingController(text: '15');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  /// Выбор даты начала события
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  /// Выбор времени начала события
  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  /// Выбор даты окончания события
  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  /// Выбор времени окончания события
  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  /// Сохранить новое событие
  void _saveEvent() {
    // Проверяем, что все поля заполнены
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.fillAllFields),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Создаём DateTime объекты для начала и конца события
    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _isAllDay ? 0 : _startTime.hour,
      _isAllDay ? 0 : _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _isAllDay ? 23 : _endTime.hour,
      _isAllDay ? 59 : _endTime.minute,
    );

    // Проверяем, что конец события позже начала
    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.invalidTimeRange),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }


    // Создаём новое событие
    final newEvent = Event(
      id: const Uuid().v4(), // Генерируем уникальный ID
      title: _titleController.text,
      description: _descriptionController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      reminderBefore: int.tryParse(_reminderController.text) ?? 15,
      isAllDay: _isAllDay,
    );

    // Добавляем событие в провайдер (в список событий)
    context.read<EventProvider>().addEvent(newEvent);

    // Показываем сообщение об успехе
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(AppStrings.eventAdded),
        backgroundColor: AppColors.success,
      ),
    );

    // Закрываем этот экран и возвращаемся на главный
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.addEventTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Название события
              Text(
              AppStrings.eventTitle,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Например: Математика',
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Описание события
            Text(
              AppStrings.eventDescription,
              style: AppTextStyles.label,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Например: Кабинет 304',
              ),
              maxLines: 3,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Событие весь день?
            CheckboxListTile(
              value: _isAllDay,
              onChanged: (value) {
                setState(() {
                  _isAllDay = value ?? false;
                });
              },
              title: const Text(AppStrings.allDayEvent),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Дата и время начала
            if (!_isAllDay) ...[
        Text(
        AppStrings.eventStartTime,
        style: AppTextStyles.label,
      ),
      const SizedBox(height: AppSpacing.sm),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _selectStartDate,
              child: Text(DateUtils.formatDate(_startDate)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: OutlinedButton(
              onPressed: _selectStartTime,
              child: Text(_startTime.format(context)),
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      ],


                // Дата и время окончания
                if (!_isAllDay) ...[
                  Text(
                    AppStrings.eventEndTime,
                    style: AppTextStyles.label,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectEndDate,
                          child: Text(DateUtils.formatDate(_endDate)),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectEndTime,
                          child: Text(_endTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Напоминание
                Text(
                  AppStrings.eventReminder,
                  style: AppTextStyles.label,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _reminderController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '15',
                    suffix: Text('мин'),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Кнопки сохранения и отмены
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(AppStrings.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveEvent,
                        child: const Text(AppStrings.save),
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
      ),
    );
  }
}
