/// EventProvider — управление списком событий
/// Здесь хранится список всех событий и методы для добавления/удаления/изменения
///
/// Почему нужен Provider?
/// Вместо передачи данных через конструкторы, мы просто "слушаем"
/// изменения в EventProvider и обновляем интерфейс автоматически

import 'package:flutter/material.dart';
import '../models/event.dart';

class EventProvider extends ChangeNotifier {
  /// Список всех событий в приложении
  /// Изначально пуст (не подключена БД)
  List<Event> _events = [];

  /// Getter для получения списка событий
  List<Event> get events => _events;

  /// Добавить новое событие в список
  void addEvent(Event event) {
    _events.add(event);

    // notifyListeners() — говорит приложению "данные изменились, обновите интерфейс!"
    notifyListeners();
  }

  /// Удалить событие из списка по ID
  void deleteEvent(String eventId) {
    _events.removeWhere((event) => event.id == eventId);
    notifyListeners();
  }

  /// Получить одно событие по ID
  Event? getEventById(String eventId) {
    try {
      return _events.firstWhere((event) => event.id == eventId);
    } catch (e) {
      return null;
    }
  }

  /// Обновить событие (заменить старое новым)
  void updateEvent(String eventId, Event newEvent) {
    final index = _events.indexWhere((event) => event.id == eventId);
    if (index != -1) {
      _events[index] = newEvent;
      notifyListeners();
    }
  }

  /// Получить события на определённый день
  List<Event> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.startTime.year == day.year &&
          event.startTime.month == day.month &&
          event.startTime.day == day.day;
    }).toList();
  }

  /// Получить события на определённый месяц
  List<Event> getEventsForMonth(int year, int month) {
    return _events.where((event) {
      return event.startTime.year == year &&
          event.startTime.month == month;
    }).toList();
  }

  /// Получить все события, отсортированные по дате (новые первыми)
  List<Event> getUpcomingEvents() {
    final sorted = List<Event>.from(_events);
    sorted.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted;
  }

  /// Добавить несколько тестовых событий (для тестирования приложения)
  void addSampleEvents() {
    final now = DateTime.now();

    _events = [
      Event(
        id: '1',
        title: 'Математика',
        description: 'Кабинет 304',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 10, 30),
        reminderBefore: 15,
        isAllDay: false,
      ),
      Event(
        id: '2',
        title: 'Обеденный перерыв',
        description: 'Столовая',
        startTime: DateTime(now.year, now.month, now.day, 12, 0),
        endTime: DateTime(now.year, now.month, now.day, 13, 0),
        reminderBefore: 0,
        isAllDay: false,
      ),
      Event(
        id: '3',
        title: 'Английский',
        description: 'Кабинет 102',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        reminderBefore: 10,
        isAllDay: false,
      ),
    ];

    notifyListeners();
  }
}
