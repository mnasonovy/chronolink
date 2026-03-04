import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/event.dart';
import '../../presentation/state/events_controller.dart';

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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late DateTime _start;
  late DateTime _end;
  late bool _allDay;

  int? _reminderMinutes; // null = нет
  bool _isSaving = false;

  bool get isEdit => widget.initialEvent != null;

  static const List<int> _presetReminderMinutes = <int>[0, 5, 10, 15, 30, 60];

  // ---------- time helpers ----------

  DateTime _ceilToNext5Minutes(DateTime dt) {
    final local = dt.toLocal();
    final base = DateTime(local.year, local.month, local.day, local.hour, local.minute);
    final add = (5 - (base.minute % 5)) % 5; // 0..4
    return base.add(Duration(minutes: add));
  }

  /// Минут до старта (округление вверх): 0..∞
  /// Если уже прошло/сейчас — возвращаем 0.
  int _minutesUntilStart() {
    final diff = _start.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 0;
    return (diff.inSeconds / 60).ceil();
  }

  String _untilStartText() {
    final now = DateTime.now();
    if (!_start.isAfter(now)) return 'Время начала уже не в будущем — напоминания не сработают.';
    final m = _minutesUntilStart();
    if (m <= 0) return 'Начало: сейчас';
    if (m == 1) return 'До начала: примерно 1 мин.';
    return 'До начала: примерно $m мин.';
  }

  bool _reminderFits(int minutes) {
    if (minutes < 0) return false;
    final now = DateTime.now();
    if (!_start.isAfter(now)) return minutes == 0; // формально, но мы всё равно не дадим сохранить
    if (minutes == 0) return true;
    final until = _minutesUntilStart();
    return until >= minutes;
  }

  // ---------- init/dispose ----------

  @override
  void initState() {
    super.initState();
    final e = widget.initialEvent;

    _titleController = TextEditingController(text: e?.title ?? '');
    _descController = TextEditingController(text: e?.description ?? '');

    _allDay = e?.allDay ?? false;

    if (e != null) {
      if (_allDay) {
        _start = DateTime(e.startDateTime.year, e.startDateTime.month, e.startDateTime.day);
        _end = _start.add(const Duration(hours: 23, minutes: 59));
      } else {
        _start = e.startDateTime;
        _end = e.endDateTime;
      }
      _reminderMinutes = e.reminderBeforeMinutes;
      return;
    }

    // ✅ fallback: округление до 5 минут вверх, потом +10 минут
    final now = DateTime.now();
    final roundedNow = _ceilToNext5Minutes(now);
    final fallbackStart = roundedNow.add(const Duration(minutes: 10));
    final fallbackEnd = fallbackStart.add(const Duration(minutes: 30));

    _start = widget.initialStart ?? fallbackStart;
    _end = widget.initialEnd ?? fallbackEnd;

    if (_end.isBefore(_start)) {
      _end = _start.add(const Duration(minutes: 30));
    }

    _reminderMinutes = 10;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------

  String _formatDateTime(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mm.$yyyy $hh:$min';
  }

  /// ⚠️ В редакторе 0 минут = "В момент начала" (не "Сейчас")
  String _reminderLabel(int? minutes) {
    if (minutes == null) return 'Нет';
    if (minutes == 0) return 'В момент начала';
    if (minutes == 1) return 'За 1 минуту';
    if (minutes >= 2 && minutes <= 4) return 'За $minutes минуты';
    return 'За $minutes минут';
  }

  List<int> _allowedPresets() {
    // Разрешаем только те варианты, которые "влезают" (и 0 — если событие в будущем)
    final until = _minutesUntilStart();
    final isFuture = _start.isAfter(DateTime.now());
    final allowed = <int>[];

    for (final m in _presetReminderMinutes) {
      if (m == 0) {
        if (isFuture) allowed.add(m);
      } else {
        if (until >= m) allowed.add(m);
      }
    }
    return allowed;
  }

  // ---------- Better custom reminder picker ----------

  Future<int?> _pickCustomReminderMinutes({
    required int minutesUntilStart,
    required bool startIsFuture,
  }) async {
    final theme = Theme.of(context);

    // start value
    int value = _reminderMinutes ?? min(10, minutesUntilStart);

    // clamp to allowed range
    value = value.clamp(0, 180);

    return showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            String helperText() {
              if (!startIsFuture) return 'Сначала выбери будущее время начала.';
              if (value == 0) return 'Сработает в момент начала.';
              if (minutesUntilStart < value) {
                return 'До события менее $value минут — такое напоминание поставить нельзя.';
              }
              return 'Поставим напоминание за $value мин до начала.';
            }

            final canSave = startIsFuture && (value == 0 || minutesUntilStart >= value);

            Widget quick(int m) {
              final selected = value == m;
              return ChoiceChip(
                label: Text(m == 0 ? 'В момент начала' : '$m мин'),
                selected: selected,
                onSelected: (_) => setLocal(() => value = m),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Другое напоминание', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      quick(0),
                      quick(5),
                      quick(10),
                      quick(15),
                      quick(30),
                      quick(60),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Минус 1',
                        onPressed: () => setLocal(() => value = max(0, value - 1)),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Expanded(
                        child: Slider(
                          value: value.toDouble(),
                          min: 0,
                          max: 180,
                          divisions: 180,
                          label: value == 0 ? 'В момент начала' : '$value мин',
                          onChanged: (v) => setLocal(() => value = v.round()),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Плюс 1',
                        onPressed: () => setLocal(() => value = min(180, value + 1)),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),

                  Text(
                    helperText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: canSave ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(null),
                          child: const Text('Отмена'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: canSave ? () => Navigator.of(ctx).pop(value) : null,
                          child: const Text('Сохранить'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------- Date/time picking ----------

  void _toggleAllDay(bool value) {
    setState(() {
      _allDay = value;
      if (value) {
        final date = _start;
        _start = DateTime(date.year, date.month, date.day);
        _end = _start.add(const Duration(hours: 23, minutes: 59));
      }
    });
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _start,
      helpText: 'Выберите дату начала',
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
      helpText: 'Выберите время начала',
    );
    if (time == null) return;

    setState(() {
      _start = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (_end.isBefore(_start)) {
        _end = _start.add(const Duration(minutes: 30));
      }

      // если выбранное напоминание больше чем "до старта" — сбросим на 0
      final until = _minutesUntilStart();
      if (_reminderMinutes != null && _reminderMinutes! > 0 && until < _reminderMinutes!) {
        _reminderMinutes = 0;
      }
    });
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: _end,
      helpText: 'Выберите дату окончания',
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_end),
      helpText: 'Выберите время окончания',
    );
    if (time == null) return;

    final newEnd = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    if (newEnd.isBefore(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Окончание не может быть раньше начала')),
      );
      return;
    }

    setState(() {
      _end = newEnd;
    });
  }

  // ---------- Validation ----------

  Future<bool> _validateReminderFits() async {
    final rem = _reminderMinutes;
    if (rem == null) return true;

    final now = DateTime.now();

    if (!_start.isAfter(now)) {
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

    if (rem == 0) return true;

    final minutesUntilStart = _minutesUntilStart();

    if (minutesUntilStart < rem) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Напоминание не получится'),
          content: Text(
            'До события менее $rem минут.\n'
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

    return true;
  }

  // ---------- Save ----------

  Future<void> _save() async {
    if (_isSaving) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final reminderOk = await _validateReminderFits();
    if (!reminderOk) return;

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(eventsControllerProvider.notifier);

      if (isEdit) {
        final updated = widget.initialEvent!.copyWith(
          title: _titleController.text,
          description: _descController.text,
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
          title: _titleController.text,
          description: _descController.text,
          startDateTime: _start,
          endDateTime: _end,
          allDay: _allDay,
          reminderBeforeMinutes: _reminderMinutes,
        );
        await controller.upsert(created);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final allowed = _allowedPresets();
    final minutesUntilStart = _minutesUntilStart();
    final startIsFuture = _start.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Редактирование' : 'Новое событие'),
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- Заголовок ---
              Text(
                'Событие',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isSaving,
                validator: (v) => v == null || v.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                ),
                enabled: !_isSaving,
                minLines: 2,
                maxLines: 4,
              ),

              const SizedBox(height: 20),

              // --- Время ---
              Text(
                'Время',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _allDay,
                onChanged: _isSaving ? null : _toggleAllDay,
                title: const Text('Весь день'),
                contentPadding: EdgeInsets.zero,
              ),
              if (!_allDay) ...[
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text('Начало'),
                        subtitle: Text(_formatDateTime(_start)),
                        trailing: const Icon(Icons.edit),
                        onTap: _isSaving ? null : _pickStart,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Окончание'),
                        subtitle: Text(_formatDateTime(_end)),
                        trailing: const Icon(Icons.edit),
                        onTap: _isSaving ? null : _pickEnd,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Card(
                  child: ListTile(
                    title: const Text('Дата'),
                    subtitle: Text(_formatDateTime(_start).split(' ').first),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _isSaving ? null : _pickStart,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // --- Напоминание ---
              Text(
                'Напоминание',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

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
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              // "Нет"
                              ChoiceChip(
                                label: const Text('Нет'),
                                selected: _reminderMinutes == null,
                                onSelected: _isSaving ? null : (_) => setState(() => _reminderMinutes = null),
                              ),

                              // пресеты (только разрешённые)
                              for (final m in allowed)
                                ChoiceChip(
                                  label: Text(_reminderLabel(m)),
                                  selected: _reminderMinutes == m,
                                  onSelected: _isSaving ? null : (_) => setState(() => _reminderMinutes = m),
                                ),

                              // Другое...
                              ActionChip(
                                label: const Text('Другое…'),
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                  final picked = await _pickCustomReminderMinutes(
                                    minutesUntilStart: minutesUntilStart,
                                    startIsFuture: startIsFuture,
                                  );
                                  if (!mounted) return;
                                  if (picked == null) return;

                                  // финальная страховка
                                  if (!_reminderFits(picked)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          picked == 0
                                              ? 'Сначала выбери будущее время начала'
                                              : 'До события менее $picked минут — такое напоминание поставить нельзя.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() => _reminderMinutes = picked);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _untilStartText(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Сохранить событие'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}