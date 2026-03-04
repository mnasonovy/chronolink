import 'package:intl/intl.dart';

final _dateTimeFormat = DateFormat('dd MMM, HH:mm');

String formatDateTime(DateTime dt) {
  return _dateTimeFormat.format(dt);
}
