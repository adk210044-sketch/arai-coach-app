// feedback_service.dart — 解説フィードバック(誤り報告・評価)をFirestoreへ送信する
//
// Firestoreコレクション: explanation_feedback
// フィールド:
//   questionId       (String)  対象問題のID
//   type             (String)  'error_report' | 'helpful' | 'difficult' | 'need_alt_explanation'
//   examTypeKey      (String)  'type1' | 'type2'
//   categoryKey      (String)  カテゴリキー
//   createdAt        (Timestamp) 送信日時(サーバー側タイムスタンプ)
//   appVersion       (String)  アプリのバージョン(将来の分析用、固定値でも可)
//
// Firestoreへの送信に失敗しても(オフライン・未設定時など)アプリの動作は
// 継続できるよう、すべての例外を握り呼び出し元には成否のみを返す。
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/question.dart';

enum FeedbackType {
  errorReport,
  helpful,
  difficult,
  needAltExplanation;

  String get value {
    switch (this) {
      case FeedbackType.errorReport:
        return 'error_report';
      case FeedbackType.helpful:
        return 'helpful';
      case FeedbackType.difficult:
        return 'difficult';
      case FeedbackType.needAltExplanation:
        return 'need_alt_explanation';
    }
  }
}

class FeedbackService {
  static const String _collection = 'explanation_feedback';

  /// 解説フィードバック(誤り報告・評価)をFirestoreに送信する。
  /// 送信に失敗した場合(Firebase未初期化・オフライン等)は false を返すのみで、
  /// 例外を投げずアプリの操作は継続できるようにする。
  static Future<bool> sendFeedback({
    required Question question,
    required FeedbackType type,
  }) async {
    try {
      await FirebaseFirestore.instance.collection(_collection).add({
        'questionId': question.id,
        'type': type.value,
        'examTypeKey': question.examTypeKey,
        'categoryKey': question.categoryKey,
        'categoryName': question.categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FeedbackService.sendFeedback failed: $e');
      }
      return false;
    }
  }
}
