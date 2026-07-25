enum QuestionFormat { ox, choice5 }

/// 出題される試験区分(第一種/第二種)。Question.examTypeKey は 'type1' / 'type2'。
class Question {
  final String id;
  final String examTypeKey; // 'type1' | 'type2'
  final String year;
  final String categoryKey;
  final String categoryName;
  final String subCategory;
  final QuestionFormat format;
  final String number;
  final String text;
  final List<String> items; // choice5専用 A~D
  final List<String> choices; // ox: ['正しい','誤り'] / choice5: (1)~(5)
  final int correctIndex;
  final String aiExplanation;
  final String officialExplanation;

  const Question({
    required this.id,
    this.examTypeKey = 'type1',
    required this.year,
    required this.categoryKey,
    required this.categoryName,
    required this.subCategory,
    required this.format,
    required this.number,
    required this.text,
    this.items = const [],
    required this.choices,
    required this.correctIndex,
    required this.aiExplanation,
    this.officialExplanation = '',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      examTypeKey: json['examType'] as String? ?? 'type1',
      year: json['year'] as String? ?? '',
      categoryKey: json['categoryKey'] as String? ?? 'physiology',
      categoryName: json['categoryName'] as String? ?? '',
      subCategory: json['subCategory'] as String? ?? '',
      format: (json['format'] as String?) == 'ox'
          ? QuestionFormat.ox
          : QuestionFormat.choice5,
      number: json['number'] as String? ?? '',
      text: json['text'] as String? ?? '',
      items: (json['items'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      choices: (json['choices'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      aiExplanation: json['aiExplanation'] as String? ?? '',
      officialExplanation: json['officialExplanation'] as String? ?? '',
    );
  }
}
