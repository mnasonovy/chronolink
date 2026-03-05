import 'package:flutter_riverpod/flutter_riverpod.dart';

DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

final selectedDayProvider =
NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => dateOnly(DateTime.now());

  void today() => state = dateOnly(DateTime.now());

  void prevDay() => state = dateOnly(state.subtract(const Duration(days: 1)));

  void nextDay() => state = dateOnly(state.add(const Duration(days: 1)));

  void prevWeek() => state = dateOnly(state.subtract(const Duration(days: 7)));

  void nextWeek() => state = dateOnly(state.add(const Duration(days: 7)));

  void setDay(DateTime day) => state = dateOnly(day);
}