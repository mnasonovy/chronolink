import 'package:flutter_riverpod/flutter_riverpod.dart';

const int _daysInWeek = 7;

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

DateTime todayDate() => dateOnly(DateTime.now());

final selectedDayProvider =
NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => todayDate();

  void today() => state = todayDate();

  void prevDay() => state = dateOnly(state.subtract(const Duration(days: 1)));

  void nextDay() => state = dateOnly(state.add(const Duration(days: 1)));

  void prevWeek() =>
      state = dateOnly(state.subtract(const Duration(days: _daysInWeek)));

  void nextWeek() =>
      state = dateOnly(state.add(const Duration(days: _daysInWeek)));

  void setDay(DateTime day) => state = dateOnly(day);
}