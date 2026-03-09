import 'package:hive/hive.dart';

part 'hive_event.g.dart';

/// Hive-модель события для локального хранения.
@HiveType(typeId: 1)
class HiveEvent {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final DateTime startDateTime;

  @HiveField(4)
  final DateTime endDateTime;

  @HiveField(5)
  final bool allDay;

  @HiveField(6)
  final int? reminderBeforeMinutes;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

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