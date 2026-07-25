// local_store.dart — Hive を用いたローカル永続化
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_profile.dart';

class LocalStore {
  LocalStore._();
  static const String userBoxName = 'user_box';
  static const String progressBoxName = 'progress_box';
  static const String logBoxName = 'answer_log_box';

  static Box? _userBox;
  static Box? _progressBox;
  static Box? _logBox;

  static Future<void> init() async {
    await Hive.initFlutter();
    _userBox = await Hive.openBox(userBoxName);
    _progressBox = await Hive.openBox(progressBoxName);
    _logBox = await Hive.openBox(logBoxName);
  }

  static UserProfile loadProfile() {
    final raw = _userBox?.get('profile');
    if (raw == null) return const UserProfile();
    try {
      return UserProfile.fromJson(Map<String, dynamic>.from(raw as Map));
    } catch (_) {
      return const UserProfile();
    }
  }

  static Future<void> saveProfile(UserProfile profile) async {
    await _userBox?.put('profile', profile.toJson());
  }

  static Map<String, int> loadHeatmap() {
    final raw = _progressBox?.get('heatmap');
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  static Future<void> saveHeatmap(Map<String, int> map) async {
    await _progressBox?.put('heatmap', map);
  }

  static Future<void> appendAnswerLog(Map<String, dynamic> entry) async {
    final box = _logBox;
    if (box == null) return;
    final key = DateTime.now().microsecondsSinceEpoch.toString();
    await box.put(key, entry);
  }

  static List<Map<String, dynamic>> allAnswerLogs() {
    final box = _logBox;
    if (box == null) return [];
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // 保存(ブックマーク)した問題ID一覧
  static List<String> loadBookmarks() {
    final raw = _progressBox?.get('bookmarks');
    if (raw == null) return [];
    return List<String>.from(raw as List);
  }

  static Future<void> saveBookmarks(List<String> ids) async {
    await _progressBox?.put('bookmarks', ids);
  }
}
