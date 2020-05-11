import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:inventorio2/models/inv_expiry.dart';

class InvSchedulerService {
  final FlutterLocalNotificationsPlugin notificationsPlugin;
  AndroidNotificationDetails androidNotificationDetails;
  IOSNotificationDetails iosNotificationDetails;
  NotificationDetails notificationDetails;

  InvSchedulerService({
    this.notificationsPlugin
  });

  void initialize({
    dynamic Function(int id, String title, String body, String payload) onDidReceiveLocalNotification,
    dynamic Function(String payload) onSelectNotification,
  }) {

    onDidReceiveLocalNotification = onDidReceiveLocalNotification == null
        ? (id, title, body, payload) {}
        : onDidReceiveLocalNotification;

    onSelectNotification = onSelectNotification == null
        ? (payload) {}
        : onSelectNotification;

    this.notificationsPlugin.initialize(
      InitializationSettings(
        AndroidInitializationSettings('ic_alert'),
        IOSInitializationSettings(onDidReceiveLocalNotification: onDidReceiveLocalNotification)
      ), onSelectNotification: onSelectNotification
    );

    this.androidNotificationDetails = AndroidNotificationDetails(
      'com.rcagantas.inventorio.scheduled.notifications',
      'Inventorio Expiration Notification',
      'Notification 7 and 30 days before expiry',
    );

    this.iosNotificationDetails = IOSNotificationDetails();
    this.notificationDetails = NotificationDetails(
      androidNotificationDetails,
      iosNotificationDetails
    );

  }

  Future<void> clearScheduleTasks() async {
    await notificationsPlugin.cancelAll();
  }

  Future<void> scheduleNotification(InvExpiry expiry) async {
    await notificationsPlugin.schedule(
      expiry.scheduleId,
      expiry.title,
      expiry.body,
      expiry.alertDate,
      notificationDetails
    );
  }


}