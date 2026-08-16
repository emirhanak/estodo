import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/app_constants.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {}

class NotificationAction {
  const NotificationAction({required this.taskId, required this.actionId});

  final String taskId;
  final String actionId;
}

class NotificationService {
  NotificationService({
    FlutterLocalNotificationsPlugin? localNotifications,
    FirebaseMessaging? messaging,
  })  : _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin(),
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications;
  final FirebaseMessaging _messaging;
  var _initialized = false;
  var _permissionsGranted = false;

  final _tapController = StreamController<String>.broadcast();
  final _actionController = StreamController<NotificationAction>.broadcast();

  /// Emits a taskId whenever the user taps a notification for a task.
  Stream<String> get onNotificationTap => _tapController.stream;

  Stream<NotificationAction> get onNotificationAction =>
      _actionController.stream;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          'task_reminder',
          actions: [
            DarwinNotificationAction.plain('complete', 'Tamamla'),
            DarwinNotificationAction.plain('snooze_10m', '10 dk ertele'),
          ],
        ),
      ],
    );

    await _localNotifications.initialize(
      settings: InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final taskId = response.payload;
        if (taskId != null && taskId.isNotEmpty) {
          if (response.actionId == null || response.actionId!.isEmpty) {
            _tapController.add(taskId);
          } else {
            _actionController.add(NotificationAction(
              taskId: taskId,
              actionId: response.actionId!,
            ));
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _createAndroidChannel();

    FirebaseMessaging.onMessage.listen(_showForegroundPush);

    // App opened from a background FCM push
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final taskId = message.data['taskId'] as String?;
      if (taskId != null && taskId.isNotEmpty) {
        _tapController.add(taskId);
      }
    });

    // App launched from a terminated state via FCM push
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      final taskId = initial.data['taskId'] as String?;
      if (taskId != null && taskId.isNotEmpty) {
        _tapController.add(taskId);
      }
    }

    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        AppConstants.remindersChannelId,
        AppConstants.remindersChannelName,
        description: AppConstants.remindersChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    if (_permissionsGranted) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isAndroid) {
      final android = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission() ?? false;
      await android?.requestExactAlarmsPermission();
      _permissionsGranted = granted;
    } else if (Platform.isIOS) {
      final ios = _localNotifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      _permissionsGranted = await ios?.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    } else {
      _permissionsGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
    }
  }

  Future<String?> getFcmToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String? body,
    required DateTime reminderAt,
  }) async {
    await initialize();
    await _requestPermissions();

    if (!_permissionsGranted) return;

    if (reminderAt.isBefore(DateTime.now())) {
      await cancelTaskReminder(taskId);
      return;
    }

    await _localNotifications.zonedSchedule(
      id: taskId.hashCode,
      title: title,
      body: body?.isNotEmpty == true ? body : 'Task reminder',
      scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.remindersChannelId,
          AppConstants.remindersChannelName,
          channelDescription: AppConstants.remindersChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          actions: [
            AndroidNotificationAction('complete', 'Complete'),
            AndroidNotificationAction('snooze_10m', 'Snooze 10m'),
          ],
        ),
        iOS: DarwinNotificationDetails(categoryIdentifier: 'task_reminder'),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: taskId,
    );
  }

  Future<void> cancelTaskReminder(String taskId) {
    return _localNotifications.cancel(id: taskId.hashCode);
  }

  Future<void> cancelAllNotifications() {
    return _localNotifications.cancelAll();
  }

  Future<void> _showForegroundPush(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.remindersChannelId,
          AppConstants.remindersChannelName,
          channelDescription: AppConstants.remindersChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['taskId'] as String?,
    );
  }
}
