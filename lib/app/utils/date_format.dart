import 'package:intl/intl.dart';

final _dateFormat = DateFormat('dd.MM.yyyy');
final _timeFormat = DateFormat('HH:mm');
final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

String formatDate(DateTime dt) {
  return _dateFormat.format(dt);
}

String formatTime(DateTime dt) {
  return _timeFormat.format(dt);
}

String formatDateTime(DateTime dt) {
  return _dateTimeFormat.format(dt);
}