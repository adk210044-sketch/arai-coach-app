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
      items:
          (json['items'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      choices:
          (json['choices'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      correctIndex: json['correctIndex'] as int? ?? 0,
      aiExplanation: json['aiExplanation'] as String? ?? '',
      officialExplanation: json['officialExplanation'] as String? ?? '',
    );
  }

  /// 問題文中の空欄 `[ Ａ ]` `[ Ｂ ]` ... から、出現順のラベル一覧を抽出する。
  /// ラベルが2つ未満(=穴埋め問題ではない)の場合は空リストを返す。
  List<String> get _blankLabels {
    final matches = RegExp(r'\[\s*([Ａ-Ｚ])\s*\]').allMatches(text);
    final seen = <String>{};
    final labels = <String>[];
    for (final m in matches) {
      final ch = m.group(1)!;
      if (seen.add(ch)) labels.add(ch);
    }
    return labels.length >= 2 ? labels : const [];
  }

  /// 選択肢の表示用リスト。
  /// 問題文が「[ Ａ ][ Ｂ ]...」形式の穴埋めで、かつ各選択肢が
  /// ラベル数と同じ個数の語句をスペース区切りで並べたものになっている場合のみ、
  /// 各語句の前に対応するラベル(Ａ: など)を自動で付与して分かりやすくする。
  /// 条件に合致しない場合(通常の記述文選択肢など)は元の choices をそのまま返す
  /// (誤ったラベル付けを避けるための安全なフォールバック)。
  List<String> get displayChoices {
    final labels = _blankLabels;
    if (labels.isEmpty) return choices;
    if (choices.any((c) => c.trimRight().endsWith('。'))) return choices;
    if (choices.any((c) => RegExp(r'[ＡＢＣＤＥ]').hasMatch(c))) {
      return choices;
    }

    final prefixPattern = RegExp(r'^(\([0-9]+\)\s*)');
    final result = <String>[];
    for (final c in choices) {
      final prefixMatch = prefixPattern.firstMatch(c);
      final prefix = prefixMatch?.group(1) ?? '';
      final body = c.substring(prefix.length);
      final tokens = body
          .split(RegExp(r'[\s\u3000]+'))
          .where((t) => t.isNotEmpty)
          .toList();
      if (tokens.length != labels.length) {
        return choices; // 想定外の形式なら安全に元の表示へフォールバック
      }
      final labeled = List.generate(
        tokens.length,
        (i) => '${labels[i]}: ${tokens[i]}',
      ).join('  ');
      result.add('$prefix$labeled');
    }
    return result;
  }
}
