import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      // This is crucial for showing notifications while the app is in foreground
      defaultPresentAlert: true,
      defaultPresentSound: true,
      defaultPresentBadge: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    // Create a high importance channel for Android to ensure heads-up notifications
    final androidPlugin = _notificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'medtrack_alarm_channel', // id
        'Medication Alarms', // title
        description: 'This channel is used for important medication reminders.', // description
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await androidPlugin.createNotificationChannel(channel);
      print('Notification: High importance channel created');
    }

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
          _handleAction(medId, time, 'taken');
        } else if (actionId == 'snooze') {
          final now = DateTime.now();
          final snoozeTime = now.add(const Duration(minutes: 15));
          await scheduleNotification(
            id: medId + 1000, 
            title: 'Snooze: ${parts.length > 2 ? parts[2] : "Medication"}',
            body: 'It\'s time to take your medication (Snoozed)',
            scheduledDate: snoozeTime,
            payload: payload,
          );
        }
      },
    );

    // Request permissions for Android 13+
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
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
      print('Notification: Scheduling for ${scheduledDate.toIso8601String()} with ID $id');
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medtrack_alarm_channel',
            'Medication Alarms',
            channelDescription: 'This channel is used for important medication reminders.',
            importance: Importance.max,
            priority: Priority.max,
            ticker: 'ticker',
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true, // Allow covering screen if locked
            category: AndroidNotificationCategory.alarm,
            audioAttributesUsage: AudioAttributesUsage.alarm,
            visibility: NotificationVisibility.public,
            additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
            actions: <AndroidNotificationAction>[
              const AndroidNotificationAction(
                'mark_taken',
                'Mark as Taken',
                showsUserInterface: true,
              ),
            ],
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e, stackTrace) {
      print('Notification Error scheduling: $e');
      print('Notification StackTrace: $stackTrace');
      // Fallback if exact alarm is not permitted
      final errorStr = e.toString().toLowerCase();
      bool isExactAlarmError = errorStr.contains('exact_alarm_not_permitted') || 
                               errorStr.contains('exact_alarms_not_permitted');
      
      if (isExactAlarmError) {
        print('Notification: Falling back to inexact schedule');
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.UTC),
        NotificationDetails(
            android: AndroidNotificationDetails(
              'medtrack_alarm_channel',
              'Medication Alarms',
              channelDescription: 'This channel is used for important medication reminders. (fallback)',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              visibility: NotificationVisibility.public,
              additionalFlags: Int32List.fromList([4]), // FLAG_INSISTENT
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
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
