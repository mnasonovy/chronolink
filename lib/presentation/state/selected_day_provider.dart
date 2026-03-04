import 'package:flutter_riverpod/flutter_riverpod.dart';

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

final selectedDayProvider =
NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return dateOnly(DateTime.now());
  }

  void today() => state = dateOnly(DateTime.now());

  void prevDay() => state = state.subtract(const Duration(days: 1));

  void nextDay() => state = state.add(const Duration(days: 1));

  void prevWeek() => state = state.subtract(const Duration(days: 7));

  void nextWeek() => state = state.add(const Duration(days: 7));

  void setDay(DateTime day) => state = dateOnly(day);
}