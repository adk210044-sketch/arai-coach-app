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

class MockSessionResult {
  final int score;
  final int total;
  final int passingScore;
  final bool passed;
  final DateTime date;

  const MockSessionResult({
    required this.score,
    required this.total,
    required this.passingScore,
    required this.passed,
    required this.date,
  });

  int get percentage => total == 0 ? 0 : (score / total * 100).round();
}
