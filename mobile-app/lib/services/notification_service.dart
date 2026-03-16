import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final actionId = response.actionId;
        final payload = response.payload;
        if (payload == null) return;
        
        final parts = payload.split('|');
        if (parts.length < 2) return;
        
        final medId = int.tryParse(parts[0]);
        final time = parts[1];
        if (medId == null) return;

        if (actionId == 'mark_taken') {
          // We'll need a way to reach the repository. 
          // Since this is a service, we'll use a callback or global provider.
          // For now, let's assume we'll trigger a refresh or handle it via a singleton/registry.
          _handleAction(medId, time, 'taken');
        } else if (actionId == 'snooze') {
          final now = DateTime.now();
          final snoozeTime = now.add(const Duration(minutes: 15));
          await scheduleNotification(
            id: medId + 1000, // Unique ID for snooze
            title: 'Snooze: ${parts[2]}',
            body: 'It\'s time to take your medication (Snoozed)',
            scheduledDate: snoozeTime,
            payload: payload,
          );
        }
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medtrack_channel',
            'Medication Reminders',
            channelDescription: 'Notifications for medication schedule',
            importance: Importance.max,
            priority: Priority.high,
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'mark_taken',
                'Mark as Taken',
                showsUserInterface: true,
              ),
              const AndroidNotificationAction(
                'snooze',
                'Snooze (15m)',
                showsUserInterface: false,
              ),
            ],
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      // Fallback if exact alarm is not permitted
      final errorStr = e.toString().toLowerCase();
      bool isExactAlarmError = errorStr.contains('exact_alarm_not_permitted') || 
                               errorStr.contains('exact_alarms_not_permitted');
      
      if (isExactAlarmError) {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'medtrack_channel',
              'Medication Reminders',
              channelDescription: 'Notifications for medication schedule (fallback)',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        rethrow;
      }
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Function(int, String, String)? _onActionCallback;
  static Function(int, String, String, String)? _onForegroundNotification;

  static void setActionCallback(Function(int, String, String) callback) {
    _onActionCallback = callback;
  }

  static void setForegroundNotificationCallback(Function(int, String, String, String) callback) {
    _onForegroundNotification = callback;
  }

  void _handleAction(int medId, String time, String status) {
    if (_onActionCallback != null) {
      _onActionCallback!(medId, time, status);
    }
  }

  void _triggerForegroundNotification(int medId, String title, String body, String time) {
    if (_onForegroundNotification != null) {
      _onForegroundNotification!(medId, title, body, time);
    }
  }
}
