// notification_service.dart — あらいコーチからの優しいリマインド通知
// flutter_local_notifications によるローカル通知のスケジューリング。
// 通知の文言はすべて「あらいコーチ」からの優しい一言に統一し、
// 数字や催促っぽい文言は送らない方針(オンボーディング説明文と一致させる)。
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // 毎日のリマインド通知に使う固定ID(1件のみスケジュールする運用)
  static const int dailyReminderId = 1001;

  // あらいコーチからの優しい一言バリエーション(通知本文)。
  // オンボーディングのプレビューと同じトーンに統一。
  static const List<String> _messages = [
    '今日はまだ1問も解いてないみたい。5分だけでも一緒にやろうよ。',
    'コツコツ続けてるね!今日の分もサクッと済ませちゃおう。',
    '試験まであと少し。今日の分を忘れずにやっておこうね。',
    '無理しなくて大丈夫、1問だけでも今日は前進だよ。',
    'あらいコーチだよ。ちょっとだけ復習の時間、取れそう?',
  ];

  static Future<void> init() async {
    if (_initialized) return;
    // Web platformでは通知プラグインが使えないため何もしない
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      tzdata.initializeTimeZones();
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _plugin.initialize(initSettings);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.init failed: $e');
      }
    }
    _initialized = true;
  }

  /// 通知権限をリクエストする(Android13+/iOS)。付与されたかどうかを返す。
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? true;
      } else if (Platform.isIOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.requestPermission failed: $e');
      }
    }
    return true;
  }

  /// 指定した時刻(HH:mm)に毎日繰り返しリマインド通知をスケジュールする。
  static Future<void> scheduleDailyReminder(String reminderTime) async {
    if (kIsWeb) return;
    await init();
    try {
      await cancelDailyReminder();
      final parts = reminderTime.split(':');
      final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 21;
      final minute = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;

      final scheduledDate = _nextInstanceOf(hour, minute);
      final message = _messages[DateTime.now().day % _messages.length];

      const androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'あらいコーチのリマインド',
        channelDescription: 'あらいコーチからの優しい学習リマインド通知だよ',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.zonedSchedule(
        dailyReminderId,
        'あらいコーチより',
        message,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.scheduleDailyReminder failed: $e');
      }
    }
  }

  static Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(dailyReminderId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.cancelDailyReminder failed: $e');
      }
    }
  }

  /// テスト用: 数秒後に即座に通知を送って動作確認できるようにする。
  static Future<void> showTestNotification() async {
    if (kIsWeb) return;
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_reminder_channel',
        'あらいコーチのリマインド',
        channelDescription: 'あらいコーチからの優しい学習リマインド通知だよ',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      final message = _messages[DateTime.now().second % _messages.length];
      await _plugin.show(9999, 'あらいコーチより', message, details);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationService.showTestNotification failed: $e');
      }
    }
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
