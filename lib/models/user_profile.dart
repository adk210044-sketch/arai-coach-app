enum ExamType { type1, type2 }

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
  });

  int? get daysUntilExam {
    if (examDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(examDate!.year, examDate!.month, examDate!.day);
    return target.difference(today).inDays;
  }

  String get examTypeLabel => examType == ExamType.type1 ? '第一種' : '第二種';

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
    );
  }
}
