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

  // 解説の誤り報告(questionId -> 報告回数)。即時修正フローの土台として、
  // 「報告済みかどうか」をローカルに記録し、ユーザーに安心感を与える。
  static Future<void> reportExplanationIssue(String questionId) async {
    final box = _progressBox;
    if (box == null) return;
    final raw = box.get('reportedQuestions');
    final Map<String, int> reported = raw == null
        ? {}
        : Map<String, int>.from(raw as Map);
    reported[questionId] = (reported[questionId] ?? 0) + 1;
    await box.put('reportedQuestions', reported);
  }

  static Set<String> loadReportedQuestionIds() {
    final raw = _progressBox?.get('reportedQuestions');
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map).keys.toSet();
  }

  // ─── あらいコーチ(AI相談)の1日あたりの利用回数(フリープランの上限管理用) ──────────────────────
  static ({String date, int count}) loadChatUsage() {
    final raw = _progressBox?.get('chatUsage');
    if (raw == null) return (date: '', count: 0);
    final map = Map<String, dynamic>.from(raw as Map);
    return (
      date: map['date'] as String? ?? '',
      count: map['count'] as int? ?? 0,
    );
  }

  static Future<void> saveChatUsage(String date, int count) async {
    await _progressBox?.put('chatUsage', {'date': date, 'count': count});
  }

  // ─── 実績バッジ(獲得済みIDの永続化。一度獲得したら失わない) ──────────────────────
  static Set<String> loadUnlockedBadgeIds() {
    final raw = _progressBox?.get('unlockedBadgeIds');
    if (raw == null) return {};
    return List<String>.from(raw as List).toSet();
  }

  static Future<void> saveUnlockedBadgeIds(Set<String> ids) async {
    await _progressBox?.put('unlockedBadgeIds', ids.toList());
  }

  // ─── 模擬試験の実施回数(回数バッジ判定用) ──────────────────────
  static int loadMockExamCount() {
    final raw = _progressBox?.get('mockExamCount');
    if (raw == null) return 0;
    return raw as int;
  }

  static Future<void> saveMockExamCount(int count) async {
    await _progressBox?.put('mockExamCount', count);
  }
}
