import 'package:hive/hive.dart';

part 'hive_event.g.dart';

@HiveType(typeId: 1)
class HiveEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime startDateTime;

  @HiveField(4)
  DateTime endDateTime;

  @HiveField(5)
  bool allDay;

  @HiveField(6)
  int? reminderBeforeMinutes;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  HiveEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDateTime,
    required this.endDateTime,
    required this.allDay,
    required this.reminderBeforeMinutes,
    required this.createdAt,
    required this.updatedAt,
  });
}
