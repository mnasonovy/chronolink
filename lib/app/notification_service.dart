import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

enum ReminderScheduleResult {
  scheduled,
  cancelled,
  notScheduledPast,
  permissionDenied,
  error,
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const _channelId = 'chronolink_reminders';
  static const _channelName = 'Chronolink reminders';
  static const _channelDesc = 'Event reminders';

  static bool? _androidPermissionGranted;

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final tzName = info.identifier;
      tz.setLocalLocation(tz.getLocation(tzName));

      if (kDebugMode) {
        // ignore: avoid_print
        print('Local timezone: $tzName');
      }
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Timezone init failed: $e');
      }
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final grantedAndroid = await android?.requestNotificationsPermission();
    _androidPermissionGranted = grantedAndroid;

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final grantedIos = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('Notifications permission: android=$grantedAndroid ios=$grantedIos');
    }
  }

  static int notificationIdFromEventId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  static NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _details(),
    );
  }

  static Future<ReminderScheduleResult> debugScheduleIn20s() async {
    try {
      if (_androidPermissionGranted == false) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Debug schedule blocked: android notifications permission denied');
        }
        return ReminderScheduleResult.permissionDenied;
      }

      final id = DateTime.now().millisecondsSinceEpoch % 100000;

      final scheduledLocal = DateTime.now().add(const Duration(seconds: 20));
      final when = tz.TZDateTime.from(scheduledLocal.toLocal(), tz.local);

      if (kDebugMode) {
        // ignore: avoid_print
        print(
          'Debug schedule in 20s: now=${DateTime.now()} when=$when tz=${tz.local.name}',
        );
      }

      await _plugin.zonedSchedule(
        id: id,
        title: 'Chronolink',
        body: 'Тестовое напоминание • через 20 сек',
        scheduledDate: when,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'debug',
      );

      return ReminderScheduleResult.scheduled;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Debug schedule error: $e');
      }
      return ReminderScheduleResult.error;
    }
  }

  static Future<ReminderScheduleResult> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventStartLocal,
    required int? reminderBeforeMinutes,
  }) async {
    final notifId = notificationIdFromEventId(eventId);

    try {
      // на всякий случай: при редактировании/пересоздании события
      await _plugin.cancel(id: notifId);

      if (reminderBeforeMinutes == null) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Reminder cancelled: eventId=$eventId (reminderBeforeMinutes=null)');
        }
        return ReminderScheduleResult.cancelled;
      }

      if (_androidPermissionGranted == false) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Reminder blocked: android notifications permission denied');
        }
        return ReminderScheduleResult.permissionDenied;
      }

      final scheduledLocal =
      eventStartLocal.subtract(Duration(minutes: reminderBeforeMinutes));

      if (kDebugMode) {
        // ignore: avoid_print
        print('Schedule reminder: eventId=$eventId');
        // ignore: avoid_print
        print('Now: ${DateTime.now()}');
        // ignore: avoid_print
        print('EventStart: $eventStartLocal');
        // ignore: avoid_print
        print('ReminderMin: $reminderBeforeMinutes');
        // ignore: avoid_print
        print('ScheduledLocal: $scheduledLocal');
        // ignore: avoid_print
        print('TZ local: ${tz.local.name}');
      }

      // если уже поздно — не планируем
      if (!scheduledLocal.isAfter(DateTime.now())) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('NOT scheduled: scheduledLocal is not in the future');
        }
        return ReminderScheduleResult.notScheduledPast;
      }

      final when = tz.TZDateTime.from(scheduledLocal.toLocal(), tz.local);

      if (kDebugMode) {
        // ignore: avoid_print
        print('TZ when: $when');
      }

      // 0 минут -> "Сейчас", иначе "через N мин"
      final suffix = reminderBeforeMinutes == 0
          ? 'Сейчас'
          : 'через $reminderBeforeMinutes мин';
      final bodyText = '$title • $suffix';

      await _plugin.zonedSchedule(
        id: notifId,
        title: 'Chronolink',
        body: bodyText,
        scheduledDate: when,
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: eventId,
      );

      return ReminderScheduleResult.scheduled;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('scheduleEventReminder error: $e');
      }
      return ReminderScheduleResult.error;
    }
  }

  static Future<void> cancelEventReminder(String eventId) async {
    final notifId = notificationIdFromEventId(eventId);
    await _plugin.cancel(id: notifId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}