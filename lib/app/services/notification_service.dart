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

  static const String _channelId = 'chronolink_reminders';
  static const String _channelName = 'Chronolink reminders';
  static const String _channelDescription = 'Event reminders';

  static bool? _androidPermissionGranted;

  static Future<void> init() async {
    await _initTimezone();
    await _initPlugin();
    await _requestPermissions();
  }

  static Future<void> _initTimezone() async {
    tz.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final timezoneName = info.identifier;
      tz.setLocalLocation(tz.getLocation(timezoneName));

      _log('Local timezone: $timezoneName');
    } catch (e, st) {
      _logError('Timezone init failed', e, st);
    }
  }

  static Future<void> _initPlugin() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings: settings);
  }

  static Future<void> _requestPermissions() async {
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

    _log('Notifications permission: android=$grantedAndroid ios=$grantedIos');
  }

  static NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  static int notificationIdFromEventId(String eventId) {
    return eventId.hashCode & 0x7fffffff;
  }

  static bool get _isAndroidPermissionDenied => _androidPermissionGranted == false;

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails(),
    );
  }

  static Future<ReminderScheduleResult> debugScheduleIn20s() async {
    try {
      if (_isAndroidPermissionDenied) {
        _log('Debug schedule blocked: android notifications permission denied');
        return ReminderScheduleResult.permissionDenied;
      }

      final id = DateTime.now().millisecondsSinceEpoch % 100000;
      final scheduledLocal = DateTime.now().add(const Duration(seconds: 20));
      final when = tz.TZDateTime.from(scheduledLocal.toLocal(), tz.local);

      _log(
        'Debug schedule in 20s: now=${DateTime.now()} when=$when tz=${tz.local.name}',
      );

      await _plugin.zonedSchedule(
        id: id,
        title: 'Chronolink',
        body: 'Тестовое напоминание • через 20 сек',
        scheduledDate: when,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'debug',
      );

      return ReminderScheduleResult.scheduled;
    } catch (e, st) {
      _logError('Debug schedule error', e, st);
      return ReminderScheduleResult.error;
    }
  }

  static Future<ReminderScheduleResult> scheduleEventReminder({
    required String eventId,
    required String title,
    required DateTime eventStartLocal,
    required int? reminderBeforeMinutes,
  }) async {
    final notificationId = notificationIdFromEventId(eventId);

    try {
      await _plugin.cancel(id: notificationId);

      if (reminderBeforeMinutes == null) {
        _log('Reminder cancelled: eventId=$eventId (reminderBeforeMinutes=null)');
        return ReminderScheduleResult.cancelled;
      }

      if (_isAndroidPermissionDenied) {
        _log('Reminder blocked: android notifications permission denied');
        return ReminderScheduleResult.permissionDenied;
      }

      final scheduledLocal =
      eventStartLocal.subtract(Duration(minutes: reminderBeforeMinutes));

      _log('Schedule reminder: eventId=$eventId');
      _log('Now: ${DateTime.now()}');
      _log('EventStart: $eventStartLocal');
      _log('ReminderMin: $reminderBeforeMinutes');
      _log('ScheduledLocal: $scheduledLocal');
      _log('TZ local: ${tz.local.name}');

      if (!scheduledLocal.isAfter(DateTime.now())) {
        _log('NOT scheduled: scheduledLocal is not in the future');
        return ReminderScheduleResult.notScheduledPast;
      }

      final when = tz.TZDateTime.from(scheduledLocal.toLocal(), tz.local);
      final bodyText = _buildReminderBody(
        title: title,
        reminderBeforeMinutes: reminderBeforeMinutes,
      );

      _log('TZ when: $when');

      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Chronolink',
        body: bodyText,
        scheduledDate: when,
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: eventId,
      );

      return ReminderScheduleResult.scheduled;
    } catch (e, st) {
      _logError('scheduleEventReminder error', e, st);
      return ReminderScheduleResult.error;
    }
  }

  static String _buildReminderBody({
    required String title,
    required int reminderBeforeMinutes,
  }) {
    final suffix = reminderBeforeMinutes == 0
        ? 'Сейчас'
        : 'через $reminderBeforeMinutes мин';

    return '$title • $suffix';
  }

  static Future<void> cancelEventReminder(String eventId) async {
    final notificationId = notificationIdFromEventId(eventId);
    await _plugin.cancel(id: notificationId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static void _log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  static void _logError(String prefix, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('$prefix: $error');
      // ignore: avoid_print
      print(stackTrace);
    }
  }
}