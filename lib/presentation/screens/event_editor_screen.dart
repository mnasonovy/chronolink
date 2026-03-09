import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/utils/date_format.dart';
import '../../domain/event.dart';
import '../state/events_controller.dart';

class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({
    super.key,
    this.initialEvent,
    this.initialStart,
    this.initialEnd,
  });

  final Event? initialEvent;
  final DateTime? initialStart;
  final DateTime? initialEnd;

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  static const List<int> _presetReminderMinutes = <int>[0, 5, 10, 15, 30, 60];
  static const int _defaultDurationMinutes = 30;
  static const int _defaultStartOffsetMinutes = 10;
  static const int _maxCustomReminderMinutes = 180;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _start;
  late DateTime _end;
  late bool _allDay;

  int? _reminderMinutes;
  bool _isSaving = false;

  bool get _isEdit => widget.initialEvent != null;

  @override
  void initState() {
    super.initState();

    final event = widget.initialEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );

    _allDay = event?.allDay ?? false;

    if (event != null) {
      _initFromEvent(event);
      return;
    }

    _initForCreate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initFromEvent(Event event) {
    if (_allDay) {
      _start = DateTime(
        event.startDateTime.year,
        event.startDateTime.month,
        event.startDateTime.day,
      );
      _end = _start.add(const Duration(hours: 23, minutes: 59));
    } else {
      _start = event.startDateTime;
      _end = event.endDateTime;
    }

    _reminderMinutes = event.reminderBeforeMinutes;
  }

  void _initForCreate() {
    final roundedNow = _ceilToNext5Minutes(DateTime.now());
    final fallbackStart = roundedNow.add(
      const Duration(minutes: _defaultStartOffsetMinutes),
    );
    final fallbackEnd = fallbackStart.add(
      const Duration(minutes: _defaultDurationMinutes),
    );

    _start = widget.initialStart ?? fallbackStart;
    _end = widget.initialEnd ?? fallbackEnd;

    if (_end.isBefore(_start)) {
      _end = _start.add(const Duration(minutes: _defaultDurationMinutes));
    }

    _reminderMinutes = 10;
  }

  DateTime _ceilToNext5Minutes(DateTime dt) {
    final local = dt.toLocal();
    final base = DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
    final addMinutes = (5 - (base.minute % 5)) % 5;
    return base.add(Duration(minutes: addMinutes));
  }

  int _minutesUntilStart() {
    final diff = _start.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 0;
    return (diff.inSeconds / 60).ceil();
  }

  bool get _startIsFuture => _start.isAfter(DateTime.now());

  String _untilStartText() {
    if (!_startIsFuture) {
      return 'Время начала уже не в будущем — напоминание не сработает.';
    }

    final minutes = _minutesUntilStart();

    if (minutes <= 0) {
      return 'Начало уже наступает.';
    }
    if (minutes == 1) {
      return 'До начала примерно 1 минута.';
    }
    return 'До начала примерно $minutes минут.';
  }

  String _reminderLabel(int? minutes) {
    if (minutes == null) return 'Нет';
    if (minutes == 0) return 'В момент начала';
    if (minutes == 1) return 'За 1 минуту';
    if (minutes >= 2 && minutes <= 4) return 'За $minutes минуты';
    return 'За $minutes минут';
  }

  bool _reminderFits(int minutes) {
    if (minutes < 0) return false;
    if (!_startIsFuture) return minutes == 0;
    if (minutes == 0) return true;
    return _minutesUntilStart() >= minutes;
  }

  List<int> _allowedPresets() {
    final until = _minutesUntilStart();
    final allowed = <int>[];

    for (final minutes in _presetReminderMinutes) {
      if (minutes == 0) {
        if (_startIsFuture) {
          allowed.add(minutes);
        }
        continue;
      }

      if (until >= minutes) {
        allowed.add(minutes);
      }
    }

    return allowed;
  }

  Future<void> _pickStart() async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _start,
      helpText: 'Дата начала',
    );
    if (pickedDate == null) return;

    if (_allDay) {
      setState(() {
        _start = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
        );
        _end = _start.add(const Duration(hours: 23, minutes: 59));
      });
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      helpText: 'Время начала',
    );
    if (pickedTime == null) return;

    setState(() {
      _start = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(minutes: _defaultDurationMinutes));
      }

      final until = _minutesUntilStart();
      if (_reminderMinutes != null &&
          _reminderMinutes! > 0 &&
          until < _reminderMinutes!) {
        _reminderMinutes = 0;
      }
    });
  }

  Future<void> _pickEnd() async {
    if (_allDay) return;

    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _end,
      helpText: 'Дата окончания',
    );
    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
      helpText: 'Время окончания',
    );
    if (pickedTime == null) return;

    final newEnd = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (newEnd.isBefore(_start)) {
      _showSnackBar('Окончание не может быть раньше начала');
      return;
    }

    setState(() {
      _end = newEnd;
    });
  }

  void _toggleAllDay(bool value) {
    setState(() {
      _allDay = value;

      if (_allDay) {
        final date = _start;
        _start = DateTime(date.year, date.month, date.day);
        _end = _start.add(const Duration(hours: 23, minutes: 59));
      }
    });
  }

  Future<int?> _pickCustomReminderMinutes({
    required int minutesUntilStart,
    required bool startIsFuture,
  }) async {
    final theme = Theme.of(context);
    int value = (_reminderMinutes ?? min(10, minutesUntilStart)).clamp(
      0,
      _maxCustomReminderMinutes,
    );

    return showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            String helperText() {
              if (!startIsFuture) {
                return 'Сначала выбери будущее время начала.';
              }
              if (value == 0) {
                return 'Напоминание придёт в момент начала.';
              }
              if (minutesUntilStart < value) {
                return 'До события меньше $value минут — такое напоминание поставить нельзя.';
              }
              return 'Напоминание придёт за $value мин до начала.';
            }

            final canSave =
                startIsFuture && (value == 0 || minutesUntilStart >= value);

            Widget quickChip(int minutes) {
              return ChoiceChip(
                label: Text(
                  minutes == 0 ? 'В момент начала' : '$minutes мин',
                ),
                selected: value == minutes,
                onSelected: (_) => setLocal(() => value = minutes),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.sm,
                  bottom: AppSpacing.lg + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Другое напоминание',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        quickChip(0),
                        quickChip(5),
                        quickChip(10),
                        quickChip(15),
                        quickChip(30),
                        quickChip(60),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Минус 1',
                          onPressed: () => setLocal(
                                () => value = max(0, value - 1),
                          ),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Expanded(
                          child: Slider(
                            value: value.toDouble(),
                            min: 0,
                            max: _maxCustomReminderMinutes.toDouble(),
                            divisions: _maxCustomReminderMinutes,
                            label: value == 0
                                ? 'В момент начала'
                                : '$value мин',
                            onChanged: (v) => setLocal(
                                  () => value = v.round(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Плюс 1',
                          onPressed: () => setLocal(
                                () => value = min(
                              _maxCustomReminderMinutes,
                              value + 1,
                            ),
                          ),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    Text(
                      helperText(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: canSave
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(null),
                            child: const Text('Отмена'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: canSave
                                ? () => Navigator.of(ctx).pop(value)
                                : null,
                            child: const Text('Сохранить'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _validateReminderFits() async {
    final reminder = _reminderMinutes;
    if (reminder == null) return true;

    if (!_startIsFuture) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Напоминание не получится'),
          content: const Text(
            'Время начала события уже наступило или прошло.\n'
                'Напоминание можно ставить только для будущих событий.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ок'),
            ),
          ],
        ),
      );
      return false;
    }

    if (reminder == 0) return true;

    final minutesUntilStart = _minutesUntilStart();
    if (minutesUntilStart >= reminder) return true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Напоминание не получится'),
        content: Text(
          'До события менее $reminder минут.\n'
              'Такое напоминание поставить нельзя.\n\n'
              'Выберите меньшее значение или "В момент начала".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Понял'),
          ),
        ],
      ),
    );
    return false;
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final reminderIsValid = await _validateReminderFits();
    if (!reminderIsValid) return;

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(eventsControllerProvider.notifier);

      if (_isEdit) {
        final updated = widget.initialEvent!.copyWith(
          title: _titleController.text.trim(),
          description: _normalizedDescription(),
          startDateTime: _start,
          endDateTime: _end,
          allDay: _allDay,
          reminderBeforeMinutes: _reminderMinutes,
          updatedAt: DateTime.now(),
        );
        await controller.upsert(updated);
      } else {
        final factory = ref.read(eventFactoryProvider);
        final created = factory.create(
          title: _titleController.text.trim(),
          description: _normalizedDescription(),
          startDateTime: _start,
          endDateTime: _end,
          allDay: _allDay,
          reminderBeforeMinutes: _reminderMinutes,
        );
        await controller.upsert(created);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      _showSnackBar('Ошибка сохранения: $error');
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _normalizedDescription() {
    final trimmed = _descriptionController.text.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _onPickCustomReminder() async {
    final picked = await _pickCustomReminderMinutes(
      minutesUntilStart: _minutesUntilStart(),
      startIsFuture: _startIsFuture,
    );

    if (!mounted || picked == null) return;

    if (!_reminderFits(picked)) {
      _showSnackBar(
        picked == 0
            ? 'Сначала выбери будущее время начала'
            : 'До события менее $picked минут — такое напоминание поставить нельзя.',
      );
      return;
    }

    setState(() {
      _reminderMinutes = picked;
    });
  }

  String _dateOnlyLabel(DateTime dt) => formatDate(dt);

  String _timeOnlyLabel(DateTime dt) => formatTime(dt);

  @override
  Widget build(BuildContext context) {
    final allowedPresets = _allowedPresets();
    final startIsFuture = _startIsFuture;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Редактирование' : 'Новое событие'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text('Сохранить'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text(
                'Событие',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _titleController,
                enabled: !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Название',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Введите название';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSaving,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Время',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                value: _allDay,
                onChanged: _isSaving ? null : _toggleAllDay,
                title: const Text('Весь день'),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (!_allDay) ...[
                Card(
                  child: Column(
                    children: [
                      _DateTimeTile(
                        label: 'Начало',
                        dateText: _dateOnlyLabel(_start),
                        timeText: _timeOnlyLabel(_start),
                        icon: Icons.schedule_outlined,
                        onTap: _isSaving ? null : _pickStart,
                      ),
                      const Divider(height: 1),
                      _DateTimeTile(
                        label: 'Окончание',
                        dateText: _dateOnlyLabel(_end),
                        timeText: _timeOnlyLabel(_end),
                        icon: Icons.flag_outlined,
                        onTap: _isSaving ? null : _pickEnd,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Card(
                  child: _DateTimeTile(
                    label: 'Дата',
                    dateText: _dateOnlyLabel(_start),
                    timeText: 'Весь день',
                    icon: Icons.calendar_today_outlined,
                    onTap: _isSaving ? null : _pickStart,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Напоминание',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Текущее значение'),
                      subtitle: Text(_reminderLabel(_reminderMinutes)),
                      trailing: const Icon(Icons.notifications_active_outlined),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Нет'),
                                selected: _reminderMinutes == null,
                                onSelected: _isSaving
                                    ? null
                                    : (_) => setState(() {
                                  _reminderMinutes = null;
                                }),
                              ),
                              for (final minutes in allowedPresets)
                                ChoiceChip(
                                  label: Text(_reminderLabel(minutes)),
                                  selected: _reminderMinutes == minutes,
                                  onSelected: _isSaving
                                      ? null
                                      : (_) => setState(() {
                                    _reminderMinutes = minutes;
                                  }),
                                ),
                              ActionChip(
                                label: const Text('Другое…'),
                                onPressed:
                                _isSaving ? null : _onPickCustomReminder,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _untilStartText(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(_isEdit ? 'Сохранить изменения' : 'Сохранить событие'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.dateText,
    required this.timeText,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String dateText;
  final String timeText;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.surfaceSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(label),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                timeText,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}