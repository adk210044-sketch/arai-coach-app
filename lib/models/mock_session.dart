class MockAnswer {
  final String questionId;
  final int answer;
  final bool isCorrect;

  const MockAnswer({
    required this.questionId,
    required this.answer,
    required this.isCorrect,
  });
}

/// 受験履歴1件分(模擬試験の提出結果)。
/// 「模擬試験 > 受験履歴」に一覧表示するために保存する。
///
/// 判定(grade)の境界値は、模擬試験の合格ライン(70%、
/// mock_exam_session_screen.dartのpassingScore算出と同じ基準)を
/// Bランクの下限にそのまま採用し、結果画面の「合格ライン達成」表示と
/// 矛盾しないようにしている。
/// A: 85%以上(安全圏) / B: 70%以上(合格ライン達成) /
/// C: 55%以上(もう一歩) / D: 55%未満(要注意)
class MockSessionResult {
  final int score;
  final int total;
  final int passingScore;
  final bool passed;
  final DateTime date;
  final String examTypeKey; // 'type1' / 'type2'(受験区分)

  const MockSessionResult({
    required this.score,
    required this.total,
    required this.passingScore,
    required this.passed,
    required this.date,
    required this.examTypeKey,
  });

  int get percentage => total == 0 ? 0 : (score / total * 100).round();

  /// A〜Dの4段階判定。境界値はmock_exam_result_screen/合格可能性カード等、
  /// 他の評価表示と矛盾しないよう統一している(クラスコメント参照)。
  String get grade {
    final pct = percentage;
    if (pct >= 85) return 'A';
    if (pct >= 70) return 'B';
    if (pct >= 55) return 'C';
    return 'D';
  }

  /// 判定に応じたひとことコメント(あらいコーチ風)。
  String get comment {
    switch (grade) {
      case 'A':
        return '安全圏の実力!この調子で本番も乗り切れるね';
      case 'B':
        return '合格ラインを達成したよ!この調子をキープしよう';
      case 'C':
        return '合格圏まであと少し!苦手分野を詰めていこう';
      default:
        return '焦らなくて大丈夫。1つずつ苦手を潰していこう';
    }
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'total': total,
    'passingScore': passingScore,
    'passed': passed,
    'date': date.toIso8601String(),
    'examTypeKey': examTypeKey,
  };

  factory MockSessionResult.fromJson(Map<String, dynamic> json) {
    return MockSessionResult(
      score: json['score'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      passingScore: json['passingScore'] as int? ?? 0,
      passed: json['passed'] as bool? ?? false,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      examTypeKey: json['examTypeKey'] as String? ?? 'type1',
    );
  }
}
