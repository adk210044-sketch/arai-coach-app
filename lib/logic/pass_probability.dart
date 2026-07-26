// pass_probability.dart — 合格可能性を推定するロジック(Flutter非依存の純粋Dart)
//
// 衛生管理者試験の合格基準は「各科目 40%以上 かつ 全体 60%以上」であるため、
// 全体正答率を軸に、苦手科目数・残り日数・データ量を加味して補正する。
import 'dart:math' as math;
import '../models/category.dart';

class PassProbabilityResult {
  final int percent; // 0-100
  final String label; // 安全圏 / 合格圏 / もう一歩 / 要注意 / 診断中
  final String comment; // あらいコーチ風コメント
  final bool hasEnoughData;

  const PassProbabilityResult({
    required this.percent,
    required this.label,
    required this.comment,
    required this.hasEnoughData,
  });
}

class PassProbabilityEngine {
  PassProbabilityEngine._();

  /// データが少なすぎる場合に診断中とみなす回答数のしきい値
  static const int _minAnsweredForDiagnosis = 10;

  static PassProbabilityResult calculate({
    required List<CategoryStat> categoryStats,
    required int? daysUntilExam,
  }) {
    final totalAnswered = categoryStats.fold<int>(0, (s, c) => s + c.total);
    final totalCorrect = categoryStats.fold<int>(0, (s, c) => s + c.correct);

    if (totalAnswered < _minAnsweredForDiagnosis) {
      return const PassProbabilityResult(
        percent: 50,
        label: '診断中',
        comment: 'もう少し問題を解くと、僕が合格可能性を診断できるようになるよ。まずは10問チャレンジしてみよう!',
        hasEnoughData: false,
      );
    }

    final accuracy = totalCorrect / totalAnswered;

    // シグモイド関数で「合格基準60%」を中心に確率をマッピング
    // accuracy=0.62 → 約50%、0.8 → 約93%、0.4 → 約8%
    double base = 100 / (1 + math.exp(-11 * (accuracy - 0.62)));

    // 苦手科目(正答率60%未満 かつ 5問以上回答)が多いほどペナルティ
    final weakCount = categoryStats.where((c) => c.weak).length;
    base -= weakCount * 4;

    // 試験までの残り日数による補正
    if (daysUntilExam != null) {
      if (daysUntilExam <= 7 && accuracy < 0.7) {
        base -= 8;
      } else if (daysUntilExam > 60) {
        base += 3;
      }
    }

    final percent = base.clamp(5, 97).round();

    String label;
    String comment;
    if (percent >= 80) {
      label = '安全圏';
      comment = 'すごく良いペースだよ!この調子を維持していこうね。';
    } else if (percent >= 65) {
      label = '合格圏';
      comment = '合格ラインが見えてきたよ。苦手分野をもう少し詰めれば安心だね。';
    } else if (percent >= 45) {
      label = 'もう一歩';
      comment = 'まだ伸ばせる余地があるよ。苦手科目を優先して復習してみよう。';
    } else {
      label = '要注意';
      comment = '焦らなくて大丈夫。今から苦手分野を1つずつ潰していけば、まだ十分間に合うよ。';
    }

    return PassProbabilityResult(
      percent: percent,
      label: label,
      comment: comment,
      hasEnoughData: true,
    );
  }
}
