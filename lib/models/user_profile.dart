import 'package:flutter/material.dart';
import 'plan.dart';

enum ExamType { type1, type2 }

/// 文字サイズ設定(2段階)。「文字が小さい」という声への対応。
enum TextSizeOption { standard, large }

extension TextSizeOptionX on TextSizeOption {
  String get label => this == TextSizeOption.large ? '大きい' : '標準';

  /// アプリ全体のテキストスケール倍率。
  double get scaleFactor => this == TextSizeOption.large ? 1.18 : 1.0;
}

/// ダークモード設定(自動/オン/オフの3段階)。
enum DarkModeOption { auto, on, off }

extension DarkModeOptionX on DarkModeOption {
  String get label {
    switch (this) {
      case DarkModeOption.auto:
        return '自動';
      case DarkModeOption.on:
        return 'オン';
      case DarkModeOption.off:
        return 'オフ';
    }
  }

  /// MaterialAppに渡す実際のThemeMode。
  ThemeMode get themeMode {
    switch (this) {
      case DarkModeOption.auto:
        return ThemeMode.system;
      case DarkModeOption.on:
        return ThemeMode.dark;
      case DarkModeOption.off:
        return ThemeMode.light;
    }
  }
}

class UserProfile {
  final String displayName;
  final ExamType examType;
  final DateTime? examDate;
  final int dailyGoalMinutes;
  final int dailyGoalQuestions;
  final int streakDays;
  final int longestStreak;
  final int totalAnswered;
  final int totalCorrect;
  final bool onboardingDone;
  final bool notificationsEnabled;
  final String reminderTime; // "HH:mm"
  final TextSizeOption textSizeOption;
  final DarkModeOption darkModeOption;
  final bool onboardingDemoDone; // オンボーディング内デモ問題を体験済みか

  // ─── 料金プラン(価格モデル) ──────────────────────
  final PlanTier planTier;
  final DateTime? planExpiresAt; // premium/intensivePack の有効期限(nullなら無期限/未設定)
  final bool trialUsed; // 3か月集中パックの無料トライアルを使用済みか
  final bool planIsTrial; // 現在の有効プランが無料トライアル中かどうか

  const UserProfile({
    this.displayName = '康一',
    this.examType = ExamType.type1,
    this.examDate,
    this.dailyGoalMinutes = 20,
    this.dailyGoalQuestions = 20,
    this.streakDays = 0,
    this.longestStreak = 0,
    this.totalAnswered = 0,
    this.totalCorrect = 0,
    this.onboardingDone = false,
    this.notificationsEnabled = true,
    this.reminderTime = '21:00',
    this.textSizeOption = TextSizeOption.standard,
    this.darkModeOption = DarkModeOption.auto,
    this.onboardingDemoDone = false,
    this.planTier = PlanTier.free,
    this.planExpiresAt,
    this.trialUsed = false,
    this.planIsTrial = false,
  });

  int? get daysUntilExam {
    if (examDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
    return target.difference(today).inDays;
  }

  String get examTypeLabel => examType == ExamType.type1 ? '第一種' : '第二種';

  /// 有料プラン(プレミアム/集中パック)が有効かどうか。
  /// 期限切れの場合はfree相当として扱う。
  bool get isPremium {
    if (planTier == PlanTier.free) return false;
    if (planExpiresAt == null) return true;
    return DateTime.now().isBefore(planExpiresAt!);
  }

  int? get planDaysRemaining {
    if (planExpiresAt == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(
      planExpiresAt!.year,
      planExpiresAt!.month,
      planExpiresAt!.day,
    );
    final diff = target.difference(today).inDays;
    return diff < 0 ? 0 : diff;
  }

  UserProfile copyWith({
    String? displayName,
    ExamType? examType,
    DateTime? examDate,
    int? dailyGoalMinutes,
    int? dailyGoalQuestions,
    int? streakDays,
    int? longestStreak,
    int? totalAnswered,
    int? totalCorrect,
    bool? onboardingDone,
    bool? notificationsEnabled,
    String? reminderTime,
    TextSizeOption? textSizeOption,
    DarkModeOption? darkModeOption,
    bool? onboardingDemoDone,
    PlanTier? planTier,
    DateTime? planExpiresAt,
    bool clearPlanExpiresAt = false,
    bool? trialUsed,
    bool? planIsTrial,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      examType: examType ?? this.examType,
      examDate: examDate ?? this.examDate,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      dailyGoalQuestions: dailyGoalQuestions ?? this.dailyGoalQuestions,
      streakDays: streakDays ?? this.streakDays,
      longestStreak: longestStreak ?? this.longestStreak,
      totalAnswered: totalAnswered ?? this.totalAnswered,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      textSizeOption: textSizeOption ?? this.textSizeOption,
      darkModeOption: darkModeOption ?? this.darkModeOption,
      onboardingDemoDone: onboardingDemoDone ?? this.onboardingDemoDone,
      planTier: planTier ?? this.planTier,
      planExpiresAt: clearPlanExpiresAt
          ? null
          : (planExpiresAt ?? this.planExpiresAt),
      trialUsed: trialUsed ?? this.trialUsed,
      planIsTrial: planIsTrial ?? this.planIsTrial,
    );
  }

  Map<String, dynamic> toJson() => {
    'displayName': displayName,
    'examType': examType.name,
    'examDate': examDate?.toIso8601String(),
    'dailyGoalMinutes': dailyGoalMinutes,
    'dailyGoalQuestions': dailyGoalQuestions,
    'streakDays': streakDays,
    'longestStreak': longestStreak,
    'totalAnswered': totalAnswered,
    'totalCorrect': totalCorrect,
    'onboardingDone': onboardingDone,
    'notificationsEnabled': notificationsEnabled,
    'reminderTime': reminderTime,
    'textSizeOption': textSizeOption.name,
    'darkModeOption': darkModeOption.name,
    'onboardingDemoDone': onboardingDemoDone,
    'planTier': planTier.name,
    'planExpiresAt': planExpiresAt?.toIso8601String(),
    'trialUsed': trialUsed,
    'planIsTrial': planIsTrial,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String? ?? '康一',
      examType: (json['examType'] as String?) == 'type2'
          ? ExamType.type2
          : ExamType.type1,
      examDate: json['examDate'] != null
          ? DateTime.tryParse(json['examDate'] as String)
          : null,
      dailyGoalMinutes: json['dailyGoalMinutes'] as int? ?? 20,
      dailyGoalQuestions: json['dailyGoalQuestions'] as int? ?? 20,
      streakDays: json['streakDays'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      totalAnswered: json['totalAnswered'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      onboardingDone: json['onboardingDone'] as bool? ?? false,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      reminderTime: json['reminderTime'] as String? ?? '21:00',
      textSizeOption: (json['textSizeOption'] as String?) == 'large'
          ? TextSizeOption.large
          : TextSizeOption.standard,
      darkModeOption: _darkModeOptionFromName(
        json['darkModeOption'] as String?,
      ),
      onboardingDemoDone: json['onboardingDemoDone'] as bool? ?? false,
      planTier: _planTierFromName(json['planTier'] as String?),
      planExpiresAt: json['planExpiresAt'] != null
          ? DateTime.tryParse(json['planExpiresAt'] as String)
          : null,
      trialUsed: json['trialUsed'] as bool? ?? false,
      planIsTrial: json['planIsTrial'] as bool? ?? false,
    );
  }

  static DarkModeOption _darkModeOptionFromName(String? name) {
    switch (name) {
      case 'on':
        return DarkModeOption.on;
      case 'off':
        return DarkModeOption.off;
      default:
        return DarkModeOption.auto;
    }
  }

  static PlanTier _planTierFromName(String? name) {
    switch (name) {
      case 'premium':
        return PlanTier.premium;
      case 'intensivePack':
        return PlanTier.intensivePack;
      default:
        return PlanTier.free;
    }
  }
}
