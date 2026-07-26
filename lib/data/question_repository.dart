// question_repository.dart — assets/data/exam_questions.json (814問) を読み込み、
// Question モデルへ変換して保持するリポジトリ。
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';
import '../models/category.dart';

class QuestionRepository {
  QuestionRepository._();
  static final QuestionRepository instance = QuestionRepository._();

  List<Question> _all = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<Question> get all => _all;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final raw = await rootBundle.loadString(
        'assets/data/exam_questions.json',
      );
      final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
      _all = data
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      _all = [];
    }
    _loaded = true;
  }

  /// 試験区分でフィルタした問題一覧
  List<Question> byExamType(String examTypeKey) =>
      _all.where((q) => q.examTypeKey == examTypeKey).toList();

  /// 試験区分 + カテゴリキーでフィルタ
  List<Question> byExamTypeAndCategory(
    String examTypeKey,
    String categoryKey,
  ) => _all
      .where(
        (q) => q.examTypeKey == examTypeKey && q.categoryKey == categoryKey,
      )
      .toList();

  /// カテゴリ定義: 試験区分ごとに存在するカテゴリキー一覧(表示順を保証)
  static const Map<String, List<MapEntry<String, String>>> categoryOrder = {
    'type1': [
      MapEntry('law_harm', '関係法令(有害)'),
      MapEntry('law_general', '関係法令(有害以外)'),
      MapEntry('labor_harm', '労働衛生(有害)'),
      MapEntry('labor_general', '労働衛生(有害以外)'),
      MapEntry('physiology', '労働生理'),
    ],
    'type2': [
      MapEntry('law_general', '関係法令'),
      MapEntry('labor_general', '労働衛生'),
      MapEntry('physiology', '労働生理'),
    ],
  };

  // ─── 料金プラン(フリープラン用の問題制限) ──────────────────────
  final Map<String, Set<String>> _freeIdsCache = {};

  /// フリープラン向けの利用可能問題ID一覧(最大50問)。
  /// カテゴリごとに均等に振り分けて選出することで、フリープランでも
  /// 全カテゴリを一通り体験できるようにする。選出は決定的(同じ問題データなら
  /// 常に同じ50問)なので、アプリ再起動でも一覧が変わらない。
  Set<String> freeQuestionIds(String examTypeKey) {
    final cached = _freeIdsCache[examTypeKey];
    if (cached != null) return cached;

    const freeLimit = 50;
    final orders = categoryOrder[examTypeKey] ?? categoryOrder['type1']!;
    if (orders.isEmpty) return {};
    final perCategory = (freeLimit / orders.length).ceil();
    final ids = <String>{};
    for (final entry in orders) {
      final catQuestions = byExamTypeAndCategory(examTypeKey, entry.key);
      for (final q in catQuestions.take(perCategory)) {
        if (ids.length >= freeLimit) break;
        ids.add(q.id);
      }
      if (ids.length >= freeLimit) break;
    }
    _freeIdsCache[examTypeKey] = ids;
    return ids;
  }

  /// 実データ(回答ログ)から算出したカテゴリ別統計を返す。
  /// answered/correct が無いカテゴリは total=出題数, correct=0 として返す。
  List<CategoryStat> buildCategoryStats({
    required String examTypeKey,
    required Map<String, int> answeredByCategory,
    required Map<String, int> correctByCategory,
  }) {
    final orders = categoryOrder[examTypeKey] ?? categoryOrder['type1']!;
    return orders.map((entry) {
      final key = entry.key;
      final name = entry.value;
      final answered = answeredByCategory[key] ?? 0;
      final correct = correctByCategory[key] ?? 0;
      final weak = answered >= 5 && (correct / answered) < 0.6;
      return CategoryStat(
        key: key,
        name: name,
        total: answered,
        correct: correct,
        weak: weak,
      );
    }).toList();
  }
}
