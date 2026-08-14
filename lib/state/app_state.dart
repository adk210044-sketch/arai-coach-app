// app_state.dart — Provider によるグローバル状態管理
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../models/plan.dart';
import '../models/badge.dart';
import '../models/mock_session.dart';
import '../data/sample_data.dart';
import '../data/local_store.dart';
import '../data/question_repository.dart';
import '../logic/pass_probability.dart';
import '../logic/daily_plan.dart';
import '../logic/weak_point_insight.dart';
import '../logic/badge_engine.dart';
import '../services/gemini_service.dart';
import '../services/notification_service.dart';
import '../services/purchase_service.dart';

class AppState extends ChangeNotifier {
  UserProfile profile = LocalStore.loadProfile();

  // 解説の誤り報告済み問題ID一覧(誤り報告→確認・修正フローの土台)
  Set<String> reportedQuestionIds = LocalStore.loadReportedQuestionIds();

  // 演習セッション
  List<Question> questionQueue = [];
  int currentIndex = 0;
  int? selectedAnswer;
  bool answered = false;
  int sessionCorrectCount = 0;
  int sessionAnsweredCount = 0;
  DateTime? questionStartedAt;

  // 今日の進捗 (ホーム画面用、日次リセット)
  int todayAnswered = 0;

  /// 今日の目標問題数。学習計画エンジン(dailyPlan)から自動算出する。
  int get dailyGoal => dailyPlan.targetCount;

  // heatmap: date(yyyy-MM-dd) -> count
  Map<String, int> heatmap = LocalStore.loadHeatmap();

  // チャット
  List<ChatMessage> chatMessages = buildInitialChatMessages();
  bool isCoachReplying = false;

  // 保存した問題(ブックマーク)
  Set<String> bookmarkedIds = LocalStore.loadBookmarks().toSet();

  // ─── 実績バッジ ──────────────────────
  final Set<String> _unlockedBadgeIds = LocalStore.loadUnlockedBadgeIds();

  /// 新規獲得したバッジのキュー(お祝いダイアログ表示用)。
  /// 同時に複数獲得した場合も1つずつ表示できるよう、キュー形式で保持する。
  /// 表示後は [popNewlyUnlockedBadge] で先頭を取り出して消費する。
  final List<AppBadge> newlyUnlockedBadges = [];

  /// 全バッジの現在の状態(獲得済み/未獲得)を、表示順のまま返す。
  List<AppBadge> get badges => BadgeEngine.all
      .map(
        (c) => AppBadge(
          id: c.id,
          icon: c.icon,
          name: c.name,
          description: c.description,
          category: c.category,
          unlocked: _unlockedBadgeIds.contains(c.id),
          tier: c.tier,
        ),
      )
      .toList();

  /// カテゴリ別にグルーピングしたバッジ一覧(プロフィール/カレンダー画面のカテゴリ表示用)。
  Map<BadgeCategory, List<AppBadge>> get badgesByCategory {
    final all = badges;
    return {
      for (final cat in BadgeCategory.values)
        cat: all.where((b) => b.category == cat).toList(),
    };
  }

  int get unlockedBadgeCount => _unlockedBadgeIds.length;
  int get totalBadgeCount => BadgeEngine.all.length;

  /// お祝いダイアログ表示用に、キューの先頭のバッジを取り出して消費する。
  /// なければnullを返す。
  AppBadge? popNewlyUnlockedBadge() {
    if (newlyUnlockedBadges.isEmpty) return null;
    final b = newlyUnlockedBadges.removeAt(0);
    notifyListeners();
    return b;
  }

  /// 指定IDのバッジをまだ獲得していなければ新規獲得として記録する(獲得済みなら何もしない)。
  /// 一度獲得したバッジは失わない設計。
  void _unlockBadge(String id) {
    if (_unlockedBadgeIds.contains(id)) return;
    _unlockedBadgeIds.add(id);
    LocalStore.saveUnlockedBadgeIds(_unlockedBadgeIds);
    final c = BadgeEngine.byId(id);
    newlyUnlockedBadges.add(
      AppBadge(
        id: c.id,
        icon: c.icon,
        name: c.name,
        description: c.description,
        category: c.category,
        unlocked: true,
        tier: c.tier,
      ),
    );
    notifyListeners();
  }

  void _unlockBadges(Iterable<String> ids) {
    for (final id in ids) {
      _unlockBadge(id);
    }
  }

  /// 連続学習日数から、達成済みのストリークバッジをすべて解除(獲得)する。
  void _checkStreakBadges(int days) {
    _unlockBadges(BadgeEngine.streakBadgeIdsForDays(days));
  }

  /// 合格可能性診断の値から、達成済みの合格力バッジをすべて解除(獲得)する。
  /// データ不足(簡易値)の場合は判定しない。
  void checkPassRateBadges() {
    final result = passProbability;
    if (!result.hasEnoughData) return;
    _unlockBadges(BadgeEngine.passRateBadgeIdsForPercent(result.percent));
  }

  /// Gemini API連携が完了した時点で呼ぶ(coach_ai_settings_screen.dartから)。
  void markGeminiLinked() {
    _unlockBadge('gemini_linked');
  }

  // 模擬試験の実施回数(回数バッジ判定用)。
  int _mockExamCount = LocalStore.loadMockExamCount();
  int get mockExamCount => _mockExamCount;

  /// 模擬試験が終了した時点で呼ぶ(mock_exam_session_screen.dartから)。
  /// 実施回数をカウントアップし、デビュー・回数マイルストーンのバッジを判定した上で、
  /// 受験履歴(日付・点数・判定)を保存する。
  void markMockExamCompleted({
    required int score,
    required int total,
    required int passingScore,
    required bool isMini,
  }) {
    _unlockBadge('first_mock_exam');
    _mockExamCount++;
    LocalStore.saveMockExamCount(_mockExamCount);
    _unlockBadges(BadgeEngine.mockExamBadgeIdsForCount(_mockExamCount));
    checkPassRateBadges();

    final result = MockSessionResult(
      score: score,
      total: total,
      passingScore: passingScore,
      passed: score >= passingScore,
      date: DateTime.now(),
      examTypeKey: examTypeKey,
      isMini: isMini,
    );
    LocalStore.appendMockExamHistory(result.toJson());
    notifyListeners();
  }

  /// 受験履歴一覧(新しい順・フル模擬試験のみ)。
  List<MockSessionResult> get mockExamHistory {
    return LocalStore.loadMockExamHistory()
        .map((e) => MockSessionResult.fromJson(e))
        .where((r) => !r.isMini)
        .toList();
  }

  /// 受験履歴一覧(新しい順・ミニ模試のみ)。
  List<MockSessionResult> get miniMockExamHistory {
    return LocalStore.loadMockExamHistory()
        .map((e) => MockSessionResult.fromJson(e))
        .where((r) => r.isMini)
        .toList();
  }

  String get examTypeKey =>
      profile.examType == ExamType.type2 ? 'type2' : 'type1';

  // ─── 模擬試験の一時保存(中断・再開) ──────────────────────
  // 現在の受験区分(examTypeKey)に対応する保存済み進行状況(なければnull)。
  Map<String, dynamic>? get savedMockExamProgress {
    final data = LocalStore.loadMockExamProgress();
    if (data == null) return null;
    if (data['examTypeKey'] != examTypeKey) return null;
    return data;
  }

  bool get hasSavedMockExam => savedMockExamProgress != null;

  /// 模擬試験の進行状況を保存する(回答ごと・明示的な一時保存ボタン両方から呼ばれる)。
  Future<void> saveMockExamProgress({
    required List<String> questionIds,
    required List<int?> answers,
    required int currentIndex,
    required int remainingSec,
    required int questionCount,
    required int durationSec,
    required bool isMini,
  }) async {
    await LocalStore.saveMockExamProgress({
      'examTypeKey': examTypeKey,
      'questionIds': questionIds,
      'answers': answers,
      'currentIndex': currentIndex,
      'remainingSec': remainingSec,
      'questionCount': questionCount,
      'durationSec': durationSec,
      'isMini': isMini,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 模擬試験を提出(完了)または新規に開始する際、古い一時保存データを削除する。
  Future<void> clearMockExamProgress() async {
    await LocalStore.clearMockExamProgress();
    notifyListeners();
  }

  // ─── 料金プラン(価格モデル) ──────────────────────
  bool get isPremium => profile.isPremium;

  /// フリープランで利用可能な問題数(上限)。
  static const int freeQuestionLimit = 50;

  /// 現在の受験区分に対応する問題プール(800問以上のデータ)。
  /// 読み込みに失敗している場合はハードコードのサンプル20問にフォールバックする。
  /// フリープランの場合は、カテゴリ均等に選出した50問に絞る。
  List<Question> get questionPool {
    final repo = QuestionRepository.instance;
    List<Question> pool;
    if (repo.isLoaded && repo.all.isNotEmpty) {
      final full = repo.byExamType(examTypeKey);
      pool = full.isNotEmpty ? full : kQuestionPool;
    } else {
      pool = kQuestionPool;
    }
    if (!isPremium && repo.isLoaded && repo.all.isNotEmpty) {
      final freeIds = repo.freeQuestionIds(examTypeKey);
      final limited = pool.where((q) => freeIds.contains(q.id)).toList();
      if (limited.isNotEmpty) return limited;
    }
    return pool;
  }

  /// 模擬試験(フル・ミニ)はプレミアム限定機能。
  bool get canUseMockExam => isPremium;

  /// 現在の受験区分(第一種/第二種)の過去問総数。
  /// プラン比較表で「令和元年以降すべて」の実数を表示するために使用する。
  int get totalQuestionCountForCurrentExamType {
    final repo = QuestionRepository.instance;
    if (repo.isLoaded && repo.all.isNotEmpty) {
      final n = repo.byExamType(examTypeKey).length;
      if (n > 0) return n;
    }
    return kQuestionPool.length;
  }

  /// 「苦手復習」で優先的に取り組むべきカテゴリキー。
  /// プレミアム: AIが優先復習ランキング(正答率が最も低いカテゴリ)から自動選定。
  /// フリー: シンプル版として先頭カテゴリ固定(AIランキングなしの簡易挙動)。
  String? get weakReviewCategoryKey {
    if (isPremium) {
      final insights = weakPointInsights;
      if (insights.isNotEmpty) return insights.first.categoryKey;
      return null;
    }
    final orders =
        QuestionRepository.categoryOrder[examTypeKey] ??
        QuestionRepository.categoryOrder['type1']!;
    return orders.isNotEmpty ? orders.first.key : null;
  }

  /// 「苦手復習」の見出し表示名(カテゴリ名)。データが無ければnull。
  String? get weakReviewCategoryName {
    final key = weakReviewCategoryKey;
    if (key == null) return null;
    final orders =
        QuestionRepository.categoryOrder[examTypeKey] ??
        QuestionRepository.categoryOrder['type1']!;
    for (final entry in orders) {
      if (entry.key == key) return entry.value;
    }
    return null;
  }

  /// 苦手復習セッションを開始する。プレミアムはAI優先復習ランキングの1位カテゴリ、
  /// フリープランはシンプル版(先頭カテゴリ固定)から出題する。
  void startWeakReviewSession({int count = 10}) {
    startSession(categoryKey: weakReviewCategoryKey, count: count);
    _unlockBadge('first_weak_review');
  }

  /// あらいコーチ(AI相談)のフリープラン1日あたりの表示上の利用上限(「◯/3回」表記用)。
  static const int freeChatDisplayLimit = 3;

  /// あらいコーチ(AI相談)のフリープラン1日あたりの実際の送信可能回数。
  /// 表示ラベル([freeChatDisplayLimit]「3回」)と実際に送信できる回数を
  /// 一致させ、ちょうど3回分だけ送信できるようにする。
  static const int freeChatDailyLimit = freeChatDisplayLimit;

  /// 今日すでに使ったコーチ相談回数(フリープランのみ意味を持つ)。
  int get todayChatCount {
    final usage = LocalStore.loadChatUsage();
    return usage.date == _todayKey() ? usage.count : 0;
  }

  /// 今日、あらいコーチにあと何回相談できるか(プレミアムはnull=無制限)。
  /// 表示は常に「◯/3回」に収まるよう [freeChatDisplayLimit] を基準に計算する。
  int? get remainingChatToday => isPremium
      ? null
      : (freeChatDisplayLimit - todayChatCount).clamp(0, freeChatDisplayLimit);

  bool get canSendChatMessage =>
      isPremium || todayChatCount < freeChatDailyLimit;

  void _incrementChatUsage() {
    if (isPremium) return;
    final today = _todayKey();
    final usage = LocalStore.loadChatUsage();
    final nextCount = usage.date == today ? usage.count + 1 : 1;
    LocalStore.saveChatUsage(today, nextCount);
  }

  /// プラン変更(モック決済)。
  /// ストア課金(Google Play Billing)が利用できない環境(Web版プレビュー等)向けの
  /// フォールバック実装。UI上でプランを選んだ時点でローカル状態を切り替えるだけ。
  /// 実機Android版では [startStorePurchase] を優先し、購入完了イベント経由で
  /// [_handlePurchaseCompleted] からプランが反映される。
  void selectPlan(PlanTier tier, {bool startTrial = false}) {
    DateTime? expiresAt;
    final now = DateTime.now();
    switch (tier) {
      case PlanTier.free:
        expiresAt = null;
        break;
      case PlanTier.premium:
        expiresAt = startTrial
            ? now.add(const Duration(days: 7))
            : DateTime(now.year, now.month + 1, now.day);
        break;
      case PlanTier.intensivePack:
        expiresAt = startTrial
            ? now.add(const Duration(days: 7))
            : DateTime(now.year, now.month + 3, now.day);
        break;
    }
    profile = profile.copyWith(
      planTier: tier,
      planExpiresAt: expiresAt,
      clearPlanExpiresAt: tier == PlanTier.free,
      trialUsed: startTrial ? true : profile.trialUsed,
      planIsTrial: startTrial,
    );
    _persistProfile();
    notifyListeners();
  }

  /// フリープランに戻す(プラン解約)。
  /// 実際のサブスク解約はGoogle Play側(アプリ内からはPlayストアの定期購入管理画面へ
  /// 誘導する形)で行う必要があるが、アプリ内の表示上はローカル状態をフリーに戻す。
  void cancelPlan() {
    profile = profile.copyWith(
      planTier: PlanTier.free,
      clearPlanExpiresAt: true,
      planIsTrial: false,
    );
    _persistProfile();
    notifyListeners();
  }

  // ─── ストア課金(Google Play Billing) ──────────────────────
  final PurchaseService _purchaseService = PurchaseService.instance;
  bool _purchaseInitStarted = false;

  /// ストア課金(in_app_purchase)がこの環境で利用可能かどうか。
  /// Web版プレビューでは常にfalse(呼び出し元は[selectPlan]にフォールバックすること)。
  bool get purchaseServiceAvailable => _purchaseService.isAvailable;

  /// 購入処理が進行中(Google Play購入UIの応答待ち等)かどうか。
  bool purchaseInProgress = false;

  /// 購入完了時にユーザーへ1回だけ表示すべき成功メッセージ。
  /// 表示後は呼び出し元が[clearPurchaseMessages]で消費すること。
  String? purchaseSuccessMessage;

  /// 購入エラー時にユーザーへ1回だけ表示すべきエラーメッセージ。
  String? purchaseErrorMessage;

  /// ペイウォール画面表示時に呼ぶ。何度呼んでも初期化は1回だけ実行される。
  Future<void> ensurePurchaseServiceInitialized() async {
    if (_purchaseInitStarted) return;
    _purchaseInitStarted = true;
    _purchaseService.onPurchaseCompleted = _handlePurchaseCompleted;
    _purchaseService.onPurchaseError = (message) {
      purchaseErrorMessage = message;
      purchaseInProgress = false;
      notifyListeners();
    };
    _purchaseService.onPendingChanged = (pending) {
      purchaseInProgress = pending;
      notifyListeners();
    };
    await _purchaseService.init();
    notifyListeners();
  }

  /// 指定プランのストア購入(Google Play Billing)を開始する。
  /// [withTrial]がtrueの場合、Google Play側に無料トライアルオファーが
  /// 設定されていればそれを使用し、無ければ通常課金に自動フォールバックする。
  /// ストアが利用できない環境ではfalseを返すので、呼び出し元は[selectPlan]で
  /// モック挙動にフォールバックすること。
  Future<bool> startStorePurchase(
    PlanTier tier, {
    bool withTrial = false,
  }) async {
    final product = tier.purchasableProduct;
    if (product == null || !_purchaseService.isAvailable) return false;
    await _purchaseService.buy(product, withTrial: withTrial);
    return true;
  }

  /// 購入履歴の復元(機種変更・再インストール時など)。
  Future<void> restoreStorePurchases() async {
    await _purchaseService.restorePurchases();
  }

  /// ストア購入完了(新規購入/更新/復元)イベントを受けてプロフィールを更新する。
  /// 注: 現時点ではクライアント側のみで完結する簡易実装(サーバーサイドでの
  /// レシート検証は行っていない)。
  void _handlePurchaseCompleted(PurchaseResultEvent event) {
    purchaseInProgress = false;
    final tier = event.product.planTier;
    final now = DateTime.now();
    final DateTime expiresAt = event.isTrial
        ? now.add(const Duration(days: 7))
        : (tier == PlanTier.premium
              ? DateTime(now.year, now.month + 1, now.day)
              : DateTime(now.year, now.month + 3, now.day));
    profile = profile.copyWith(
      planTier: tier,
      planExpiresAt: expiresAt,
      trialUsed: event.isTrial ? true : profile.trialUsed,
      planIsTrial: event.isTrial,
    );
    _persistProfile();
    final info = kPlanCatalog[tier]!;
    purchaseSuccessMessage = event.isRestore
        ? '購入内容を復元したよ。${info.label}が利用できるようになったよ。'
        : (event.isTrial
              ? '${info.trialDays}日間の無料トライアルを開始したよ!'
              : '${info.label}に加入したよ。ありがとう!');
    notifyListeners();
  }

  /// 購入成功/エラーメッセージを表示し終えたら呼ぶ(再表示ループ防止)。
  void clearPurchaseMessages() {
    purchaseSuccessMessage = null;
    purchaseErrorMessage = null;
  }

  /// 回答ログ(questionId -> isCorrect)から、現在の受験区分のカテゴリ別正答率統計を算出する。
  List<CategoryStat> get categoryStats {
    final repo = QuestionRepository.instance;
    if (!repo.isLoaded || repo.all.isEmpty) {
      return kCategories;
    }
    final questionsById = {for (final q in repo.all) q.id: q};
    final answeredByCategory = <String, int>{};
    final correctByCategory = <String, int>{};
    for (final log in LocalStore.allAnswerLogs()) {
      final qid = log['questionId'] as String?;
      final q = qid != null ? questionsById[qid] : null;
      if (q == null || q.examTypeKey != examTypeKey) continue;
      answeredByCategory[q.categoryKey] =
          (answeredByCategory[q.categoryKey] ?? 0) + 1;
      if (log['isCorrect'] == true) {
        correctByCategory[q.categoryKey] =
            (correctByCategory[q.categoryKey] ?? 0) + 1;
      }
    }
    return repo.buildCategoryStats(
      examTypeKey: examTypeKey,
      answeredByCategory: answeredByCategory,
      correctByCategory: correctByCategory,
    );
  }

  void _persistProfile() {
    LocalStore.saveProfile(profile);
  }

  // ─── 合格可能性 診断 ──────────────────────
  PassProbabilityResult get passProbability => PassProbabilityEngine.calculate(
    categoryStats: categoryStats,
    daysUntilExam: profile.daysUntilExam,
  );

  /// 直近4週間の「その時点までの累計データ」で合格可能性を再計算し、週次トレンドを算出する。
  /// プレミアム限定の分析強化機能(AIによる継続診断)として利用する。
  /// 各要素は合格可能性(%)。データ不足で診断できない週は null(未診断)を返す。
  List<int?> get passProbabilityWeeklyTrend {
    final repo = QuestionRepository.instance;
    if (!repo.isLoaded || repo.all.isEmpty) return [];
    final questionsById = {for (final q in repo.all) q.id: q};
    final logs = LocalStore.allAnswerLogs()
      ..sort((a, b) {
        final da =
            DateTime.tryParse(a['answeredAt'] as String? ?? '') ??
            DateTime(2000);
        final db =
            DateTime.tryParse(b['answeredAt'] as String? ?? '') ??
            DateTime(2000);
        return da.compareTo(db);
      });
    if (logs.isEmpty) return [];

    final now = DateTime.now();
    final trend = <int?>[];
    for (var weeksAgo = 3; weeksAgo >= 0; weeksAgo--) {
      final cutoff = now.subtract(Duration(days: weeksAgo * 7));
      final answeredByCategory = <String, int>{};
      final correctByCategory = <String, int>{};
      for (final log in logs) {
        final answeredAt = DateTime.tryParse(
          log['answeredAt'] as String? ?? '',
        );
        if (answeredAt == null || answeredAt.isAfter(cutoff)) continue;
        final qid = log['questionId'] as String?;
        final q = qid != null ? questionsById[qid] : null;
        if (q == null || q.examTypeKey != examTypeKey) continue;
        answeredByCategory[q.categoryKey] =
            (answeredByCategory[q.categoryKey] ?? 0) + 1;
        if (log['isCorrect'] == true) {
          correctByCategory[q.categoryKey] =
              (correctByCategory[q.categoryKey] ?? 0) + 1;
        }
      }
      final stats = repo.buildCategoryStats(
        examTypeKey: examTypeKey,
        answeredByCategory: answeredByCategory,
        correctByCategory: correctByCategory,
      );
      final result = PassProbabilityEngine.calculate(
        categoryStats: stats,
        daysUntilExam: profile.daysUntilExam,
      );
      trend.add(result.hasEnoughData ? result.percent : null);
    }
    return trend;
  }

  /// 苦手ヒートマップ用: 直近4週間、各週「その週だけ」の科目別正答率マトリクス。
  /// (「科目別の正答率」セクションは全期間の累計スナップショットを表示するのに対し、
  /// ここでは週ごとに区切って集計するため、直近の伸び・落ち込みが科目別に見える)
  /// 戻り値は週ごとのリスト(古い週→新しい週の順、要素数4)。各要素は科目順に
  /// [CategoryWeekCell] を並べたリスト。
  List<List<CategoryWeekCell>> get categoryWeeklyHeatmap {
    final repo = QuestionRepository.instance;
    final orders =
        QuestionRepository.categoryOrder[examTypeKey] ??
        QuestionRepository.categoryOrder['type1']!;
    if (!repo.isLoaded || repo.all.isEmpty) {
      return List.generate(
        4,
        (_) => orders
            .map(
              (e) => CategoryWeekCell(
                categoryKey: e.key,
                categoryName: e.value,
                total: 0,
                correct: 0,
              ),
            )
            .toList(),
      );
    }
    final questionsById = {for (final q in repo.all) q.id: q};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final weeks = <List<CategoryWeekCell>>[];
    for (var weeksAgo = 3; weeksAgo >= 0; weeksAgo--) {
      final weekEnd = today.subtract(Duration(days: weeksAgo * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      final answered = <String, int>{};
      final correct = <String, int>{};
      for (final log in LocalStore.allAnswerLogs()) {
        final answeredAt = DateTime.tryParse(
          log['answeredAt'] as String? ?? '',
        );
        if (answeredAt == null) continue;
        final day = DateTime(answeredAt.year, answeredAt.month, answeredAt.day);
        if (day.isBefore(weekStart) ||
            day.isAfter(weekEnd.add(const Duration(days: 1)))) {
          continue;
        }
        final qid = log['questionId'] as String?;
        final q = qid != null ? questionsById[qid] : null;
        if (q == null || q.examTypeKey != examTypeKey) continue;
        answered[q.categoryKey] = (answered[q.categoryKey] ?? 0) + 1;
        if (log['isCorrect'] == true) {
          correct[q.categoryKey] = (correct[q.categoryKey] ?? 0) + 1;
        }
      }
      weeks.add(
        orders
            .map(
              (e) => CategoryWeekCell(
                categoryKey: e.key,
                categoryName: e.value,
                total: answered[e.key] ?? 0,
                correct: correct[e.key] ?? 0,
              ),
            )
            .toList(),
      );
    }
    return weeks;
  }

  // ─── AI弱点分析(プレミアム限定の強化機能) ──────────────────────
  /// 優先復習ランキング(正答率が低い科目から並べたAI分析結果)。
  List<WeakPointInsight> get weakPointInsights =>
      WeakPointEngine.analyze(categoryStats);

  // ─── 今日の学習プラン(自動作成) ──────────────────────
  DailyPlanResult get dailyPlan => DailyPlanEngine.computeToday(
    totalQuestionsInPool: questionPool.length,
    totalAnsweredOverall: profile.totalAnswered,
    daysUntilExam: profile.daysUntilExam,
    categoryStats: categoryStats,
  );

  // ─── 解説の誤り報告(確認・修正フローの入口) ──────────────────────
  bool isExplanationReported(String questionId) =>
      reportedQuestionIds.contains(questionId);

  void reportExplanationIssue(String questionId) {
    reportedQuestionIds.add(questionId);
    LocalStore.reportExplanationIssue(questionId);
    notifyListeners();
  }

  void completeOnboarding({
    required ExamType examType,
    required DateTime examDate,
    required int dailyGoalMinutes,
  }) {
    profile = profile.copyWith(
      examType: examType,
      examDate: examDate,
      dailyGoalMinutes: dailyGoalMinutes,
      onboardingDone: true,
    );
    _persistProfile();
    notifyListeners();
  }

  void updateProfile(UserProfile Function(UserProfile) updater) {
    profile = updater(profile);
    _persistProfile();
    notifyListeners();
  }

  // ─── 通知(あらいコーチからの優しいリマインド) ──────────────────────
  /// 通知ON/OFFとリマインド時刻を反映し、実際のローカル通知スケジュールも更新する。
  Future<void> setNotificationSettings({
    required bool enabled,
    String? reminderTime,
  }) async {
    profile = profile.copyWith(
      notificationsEnabled: enabled,
      reminderTime: reminderTime ?? profile.reminderTime,
    );
    _persistProfile();
    notifyListeners();
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (granted) {
        await NotificationService.scheduleDailyReminder(profile.reminderTime);
      }
    } else {
      await NotificationService.cancelDailyReminder();
    }
  }

  // ─── 文字サイズ(2段階) ──────────────────────
  void setTextSizeOption(TextSizeOption option) {
    profile = profile.copyWith(textSizeOption: option);
    _persistProfile();
    notifyListeners();
  }

  // ─── 学習ゴール(1日の目標問題数) ──────────────────────
  void setDailyGoalQuestions(int count) {
    profile = profile.copyWith(dailyGoalQuestions: count);
    _persistProfile();
    notifyListeners();
  }

  // ─── 試験日 ──────────────────────
  void setExamDate(DateTime date) {
    profile = profile.copyWith(examDate: date);
    _persistProfile();
    notifyListeners();
  }

  // ─── オンボーディング内1問デモ ──────────────────────
  void markOnboardingDemoDone() {
    profile = profile.copyWith(onboardingDemoDone: true);
    _persistProfile();
    notifyListeners();
  }

  String _todayKey([DateTime? d]) {
    final date = d ?? DateTime.now();
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _recordActivity() {
    final key = _todayKey();
    heatmap[key] = (heatmap[key] ?? 0) + 1;
    LocalStore.saveHeatmap(heatmap);

    // streak計算(簡易): 今日の記録があれば連続日数+1(初回のみ更新)
    final yesterday = _todayKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if ((heatmap[key] ?? 0) == 1) {
      final hadYesterday = (heatmap[yesterday] ?? 0) > 0;
      final newStreak = hadYesterday ? profile.streakDays + 1 : 1;
      final newLongest = max(profile.longestStreak, newStreak);
      profile = profile.copyWith(
        streakDays: newStreak,
        longestStreak: newLongest,
      );
      _persistProfile();
    }
  }

  // ─── 通常演習の一時保存(中断・再開) ──────────────────────
  // 演習中に×ボタンで中断した場合、次回同じ入り口(今日のタスク/カテゴリ別/
  // ランダム等)から始めようとしたときに「続きから」を選べるようにする。
  // 現在の受験区分(examTypeKey)に対応する保存済み進行状況(なければnull)。
  Map<String, dynamic>? get savedQuizProgress {
    final data = LocalStore.loadQuizSessionProgress();
    if (data == null) return null;
    if (data['examTypeKey'] != examTypeKey) return null;
    return data;
  }

  bool get hasSavedQuizProgress => savedQuizProgress != null;

  /// 現在の演習セッションの状態を保存する(×ボタンで中断する際に呼ぶ)。
  ///
  /// 【重要】結果画面(正解/不正解表示中)で×を押した場合、その時点では
  /// 現在の問題は既に回答済み(answered=true)になっている。この状態のまま
  /// 保存すると、再開時に「回答済みの問題」が選択肢ロック状態(タップ不可・
  /// 回答するボタンも押せない)で復元されてしまい、操作不能になるバグが
  /// あったため、回答済みの問題は「次の問題に進んだ状態」として保存する。
  /// 最後の問題まで回答済みだった場合は、セッション自体を完了扱いとし、
  /// 保存済み進行状況をクリアする(「続きから」自体を出さない)。
  Future<void> saveQuizProgress() async {
    if (questionQueue.isEmpty) return;

    if (answered) {
      if (hasNextQuestion) {
        await LocalStore.saveQuizSessionProgress({
          'examTypeKey': examTypeKey,
          'questionIds': questionQueue.map((q) => q.id).toList(),
          'currentIndex': currentIndex + 1,
          'selectedAnswer': null,
          'answered': false,
          'sessionCorrectCount': sessionCorrectCount,
          'sessionAnsweredCount': sessionAnsweredCount,
          'savedAt': DateTime.now().toIso8601String(),
        });
      } else {
        // 最後の問題まで回答済み = セッション完了。中断保存は不要。
        await LocalStore.clearQuizSessionProgress();
      }
      return;
    }

    await LocalStore.saveQuizSessionProgress({
      'examTypeKey': examTypeKey,
      'questionIds': questionQueue.map((q) => q.id).toList(),
      'currentIndex': currentIndex,
      'selectedAnswer': selectedAnswer,
      'answered': answered,
      'sessionCorrectCount': sessionCorrectCount,
      'sessionAnsweredCount': sessionAnsweredCount,
      'savedAt': DateTime.now().toIso8601String(),
    });
  }

  /// 保存された演習セッションを復元する。復元に成功したらtrueを返す。
  /// (問題データの更新等でIDが見つからない場合はfalseを返し、呼び出し側で
  /// 新規セッション開始にフォールバックできるようにする)
  bool resumeQuizProgress() {
    final data = savedQuizProgress;
    if (data == null) return false;
    final ids = List<String>.from(data['questionIds'] as List? ?? []);
    final repo = QuestionRepository.instance;
    final byId = {for (final q in repo.all) q.id: q};
    final restored = <Question>[];
    for (final id in ids) {
      final q = byId[id];
      if (q != null) restored.add(q);
    }
    if (restored.isEmpty) return false;

    questionQueue = restored;
    currentIndex = (data['currentIndex'] as int? ?? 0).clamp(
      0,
      restored.length - 1,
    );
    selectedAnswer = data['selectedAnswer'] as int?;
    answered = data['answered'] as bool? ?? false;
    sessionCorrectCount = data['sessionCorrectCount'] as int? ?? 0;
    sessionAnsweredCount = data['sessionAnsweredCount'] as int? ?? 0;

    // 【安全策】旧バージョンで保存された不整合データ(結果画面で×を押した際に
    // answered=trueのまま保存されてしまったもの)が万一残っていた場合、
    // そのまま復元すると選択肢・回答ボタンが一切操作できない不具合になる。
    // ここで検知し、未回答の次の問題に進めるか、最後の問題なら新規開始に
    // フォールバックすることで、操作不能状態を防ぐ。
    if (answered) {
      if (currentIndex < questionQueue.length - 1) {
        currentIndex++;
      } else {
        questionStartedAt = DateTime.now();
        notifyListeners();
        return false;
      }
      selectedAnswer = null;
      answered = false;
    }

    questionStartedAt = DateTime.now();
    notifyListeners();
    return true;
  }

  /// セッション完了(全問終了)または「最初から」選択時に、古い一時保存を削除する。
  Future<void> clearQuizProgress() async {
    await LocalStore.clearQuizSessionProgress();
  }

  // ─── 演習フロー ──────────────────────
  /// [isGapStudy] は「スキマ学習」からの開始かどうか(初操作バッジ判定用)。
  void startSession({
    String? categoryKey,
    int count = 10,
    bool isGapStudy = false,
  }) {
    final basePool = questionPool;
    final pool = categoryKey == null
        ? List<Question>.from(basePool)
        : basePool.where((q) => q.categoryKey == categoryKey).toList();
    pool.shuffle(Random());
    questionQueue = pool.take(count).toList();
    if (questionQueue.isEmpty) {
      questionQueue = List<Question>.from(basePool)..shuffle();
    }
    currentIndex = 0;
    selectedAnswer = null;
    answered = false;
    sessionCorrectCount = 0;
    sessionAnsweredCount = 0;
    questionStartedAt = DateTime.now();
    if (isGapStudy) {
      _unlockBadge('first_gap_study');
    }
    notifyListeners();
  }

  /// 「今日のタスク」専用のセッション開始。
  /// [distribution] はカテゴリキー → 出題数のマップ(DailyPlanResult.categoryDistribution)。
  /// 全カテゴリから指定数ずつランダムに問題を抽出し、最後に全体をシャッフルして出題順をばらけさせる。
  void startDailyTaskSession(Map<String, int> distribution) {
    final basePool = questionPool;
    final byCategory = <String, List<Question>>{};
    for (final q in basePool) {
      (byCategory[q.categoryKey] ??= []).add(q);
    }

    final selected = <Question>[];
    distribution.forEach((categoryKey, count) {
      if (count <= 0) return;
      final candidates = List<Question>.from(byCategory[categoryKey] ?? [])
        ..shuffle(Random());
      selected.addAll(candidates.take(count));
    });

    selected.shuffle(Random());
    questionQueue = selected;
    if (questionQueue.isEmpty) {
      questionQueue = List<Question>.from(basePool)..shuffle();
    }
    currentIndex = 0;
    selectedAnswer = null;
    answered = false;
    sessionCorrectCount = 0;
    sessionAnsweredCount = 0;
    questionStartedAt = DateTime.now();
    notifyListeners();
  }

  Question get currentQuestion => questionQueue[currentIndex];

  bool get hasNextQuestion => currentIndex < questionQueue.length - 1;

  void selectAnswer(int index) {
    if (answered) return;
    selectedAnswer = index;
    notifyListeners();
  }

  void submitAnswer() {
    if (selectedAnswer == null || answered) return;
    answered = true;
    final correct = selectedAnswer == currentQuestion.correctIndex;
    if (correct) sessionCorrectCount++;
    sessionAnsweredCount++;
    todayAnswered++;
    profile = profile.copyWith(
      totalAnswered: profile.totalAnswered + 1,
      totalCorrect: profile.totalCorrect + (correct ? 1 : 0),
    );
    _persistProfile();
    _recordActivity();
    LocalStore.appendAnswerLog({
      'questionId': currentQuestion.id,
      'userAnswer': selectedAnswer,
      'isCorrect': correct,
      'answeredAt': DateTime.now().toIso8601String(),
      'timeSpentMs': questionStartedAt != null
          ? DateTime.now().difference(questionStartedAt!).inMilliseconds
          : 0,
    });
    _unlockBadge('first_answer');
    _checkStreakBadges(profile.streakDays);
    checkPassRateBadges();
    notifyListeners();
  }

  bool get lastAnswerCorrect =>
      selectedAnswer != null && selectedAnswer == currentQuestion.correctIndex;

  // 正解時・不正解時のコーチコメントのバリエーション。
  // 問題IDのハッシュを使って決定的に選ぶことで、同じ問題では同じ文言になり
  // 前後の画面遷移でチラつかない一方、問題ごとには変化が出るようにする。
  static const List<String> _correctComments = [
    '+10 XP ゲット',
    'いいペースだね!',
    'その調子!完璧だよ',
    'ナイス、しっかり定着してるね',
    '+10 XP。この調子で行こう',
  ];
  static const List<String> _incorrectComments = [
    '次はきっといける',
    '惜しい、もう一歩だよ',
    'ここは要チェックだね',
    'ここで気づけたのはラッキーだよ',
    '出るとこだから覚えておこう',
    'よくある間違いポイントだよ',
  ];

  String get resultComment {
    final list = lastAnswerCorrect ? _correctComments : _incorrectComments;
    final h = currentQuestion.id.hashCode.abs();
    return list[h % list.length];
  }

  // ─── ブックマーク ──────────────────────
  bool isBookmarked(String questionId) => bookmarkedIds.contains(questionId);

  void toggleBookmark(String questionId) {
    if (bookmarkedIds.contains(questionId)) {
      bookmarkedIds.remove(questionId);
    } else {
      bookmarkedIds.add(questionId);
      _unlockBadge('first_bookmark');
    }
    LocalStore.saveBookmarks(bookmarkedIds.toList());
    notifyListeners();
  }

  /// 保存(ブックマーク)した問題を実際の [Question] オブジェクトとして返す。
  /// 現在選択中の受験区分(第一種/第二種)に関わらず、保存した問題は
  /// すべて表示する(区分を後で変更しても保存リストが消えないようにする)。
  List<Question> get bookmarkedQuestions {
    final repo = QuestionRepository.instance;
    final byId = {for (final q in repo.all) q.id: q};
    final result = <Question>[];
    for (final id in bookmarkedIds) {
      final q = byId[id];
      if (q != null) result.add(q);
    }
    return result;
  }

  /// 保存した問題一覧から1問だけを演習キューにセットし、
  /// 問題画面(QuestionScreen)でその場で解けるようにする。
  void startSingleQuestionSession(Question question) {
    questionQueue = [question];
    currentIndex = 0;
    selectedAnswer = null;
    answered = false;
    sessionCorrectCount = 0;
    sessionAnsweredCount = 0;
    questionStartedAt = DateTime.now();
    notifyListeners();
  }

  void nextQuestion() {
    if (hasNextQuestion) {
      currentIndex++;
      selectedAnswer = null;
      answered = false;
      questionStartedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// 1問前の問題に戻る(誤操作でのスキップ・誤タップからのやり直し用)。
  /// 選択状態・回答済み状態はリセットし、その問題を解き直せるようにする。
  void previousQuestion() {
    if (currentIndex > 0) {
      currentIndex--;
      selectedAnswer = null;
      answered = false;
      questionStartedAt = DateTime.now();
      notifyListeners();
    }
  }

  void retryCurrentQuestion() {
    selectedAnswer = null;
    answered = false;
    questionStartedAt = DateTime.now();
    notifyListeners();
  }

  // ─── チャット ──────────────────────

  /// あらいコーチに渡す「今のユーザーの学習状況」コンテキスト。
  /// Gemini連携時にこれをシステムプロンプトへ差し込むことで、
  /// 「よく出る問題は?」「合格率は?」のような自由質問にも
  /// 実データに基づいた回答ができるようにする。
  String _buildCoachContext() {
    final stats = categoryStats;
    final weakOnes = stats.where((c) => c.weak).toList();
    final sortedByAccuracy = [...stats]
      ..sort((a, b) => a.accuracy.compareTo(b.accuracy));
    final prob = passProbability;
    final buf = StringBuffer();
    buf.writeln('- 受験区分: ${profile.examTypeLabel}衛生管理者');
    if (profile.examDate != null) {
      buf.writeln(
        '- 試験日: ${profile.examDate!.year}/${profile.examDate!.month}/${profile.examDate!.day}'
        '(残り${profile.daysUntilExam ?? '?'}日)',
      );
    }
    buf.writeln(
      '- 累計回答数: ${profile.totalAnswered}問 / 累計正答数: ${profile.totalCorrect}問',
    );
    buf.writeln(
      '- 連続学習日数: ${profile.streakDays}日(最長${profile.longestStreak}日)',
    );
    buf.writeln(
      '- 合格可能性診断: ${prob.percent}%(${prob.label})${prob.hasEnoughData ? '' : ' ※データ不足のため簡易値'}',
    );
    if (sortedByAccuracy.isNotEmpty) {
      buf.writeln('- 科目別正答率(低い順):');
      for (final c in sortedByAccuracy) {
        if (c.total == 0) continue;
        buf.writeln(
          '  ・${c.name}: ${c.accuracyPercent}%(${c.total}問中${c.correct}問正解)',
        );
      }
    }
    if (weakOnes.isNotEmpty) {
      buf.writeln('- 現在の要復習(苦手)科目: ${weakOnes.map((c) => c.name).join('、')}');
    }
    buf.writeln(
      '- プラン: ${isPremium ? kPlanCatalog[profile.planTier]!.label : 'フリープラン'}',
    );
    return buf.toString();
  }

  /// ユーザーの発言を送信し、あらいコーチの返信を追加する。
  /// Gemini APIキーが設定されていればAI応答、未設定/失敗時はルールベース応答にフォールバックする。
  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (!canSendChatMessage) {
      chatMessages.add(ChatMessage(role: ChatRole.user, text: text.trim()));
      chatMessages.add(
        ChatMessage(
          role: ChatRole.ai,
          text:
              'ごめんね、フリープランは1日3回まで相談できるんだ。\nプレミアムなら無制限で相談できて、パーソナルな学習プランも作れるようになるよ。',
          action: ChatAction.openPaywall,
        ),
      );
      notifyListeners();
      return;
    }

    chatMessages.add(ChatMessage(role: ChatRole.user, text: text.trim()));
    _unlockBadge('first_coach_chat');
    isCoachReplying = true;
    notifyListeners();

    String replyText;
    ChatAction replyAction = ChatAction.none;

    final apiKey = await GeminiService.getApiKey();
    if (apiKey != null) {
      try {
        final history = chatMessages
            .sublist(0, chatMessages.length - 1)
            .reversed
            .take(8)
            .toList()
            .reversed
            .map((m) => (isUser: m.role == ChatRole.user, text: m.text))
            .toList();
        replyText = await GeminiService.sendMessage(
          userText: text.trim(),
          contextInfo: _buildCoachContext(),
          history: history,
        );
        // Gemini応答時も、演習開始の意図が明確な場合はアクションボタンを付ける
        if (text.contains('3問') || text.contains('三問') || text.contains('出題')) {
          replyAction = ChatAction.startQuiz3;
        } else if (text.contains('苦手') || text.contains('復習')) {
          replyAction = ChatAction.openWeakReview;
        }
      } catch (e) {
        // Gemini呼び出し失敗時はルールベース応答にフォールバックする。
        // 原因調査用に、デバッグビルドでのみエラー内容をログ出力する
        // (「AI連携」画面の接続テストでも同様のエラーを確認できる)。
        if (kDebugMode) {
          debugPrint('Gemini sendMessage failed, falling back: $e');
        }
        final reply = _mockCoachReply(text);
        replyText = reply.text;
        replyAction = reply.action;
      }
    } else {
      // APIキー未設定時は少し待ってルールベース応答(演出上の「考え中」感を出す)
      await Future.delayed(const Duration(milliseconds: 500));
      final reply = _mockCoachReply(text);
      replyText = reply.text;
      replyAction = reply.action;
    }

    _incrementChatUsage();
    isCoachReplying = false;
    chatMessages.add(
      ChatMessage(role: ChatRole.ai, text: replyText, action: replyAction),
    );
    notifyListeners();
  }

  static final Random _chatRandom = Random();

  // 「3問だけ出す」の返答バリエーション(苦手分野名は動的に埋め込む)
  static const List<String> _quiz3Templates = [
    '了解だよ!{weak}から3問出すね。下のボタンから始めよう。',
    'いいね、その気になったときが伸びるタイミングだよ。{weak}を中心に3問用意したよ。',
    'よし、3問だけサクッといこう。{weak}をピックアップしてみたよ。',
    '無理せず3問からでOKだよ。{weak}を選んでおいたから、下のボタンから試してみてね。',
  ];

  // 「暗記のコツ」の返答バリエーション
  static const List<String> _memoTipTemplates = [
    '暗記のコツは「数字」と「主語」をセットで覚えることだよ。\n\n例えば「50人以上→衛生管理者」「6か月以内ごと→特定化学物質健診」のように、数字と結論をワンフレーズで語呂合わせにすると忘れにくいんだ。\n\n{weak}',
    'コツを1つだけ挙げるなら「間違えた問題だけを見返す」ことだよ。\n\n1問1問を丁寧に覚えるより、間違えた箇所を繰り返し見る方が定着が早いんだ。人間は忘れる生き物だから、それでいいんだよ。\n\n{weak}',
    '暗記は「イメージ化」すると強いよ。\n\n例えば「有機溶剤作業主任者」は「シンナー臭い現場に責任者がいる」って絵を想像すると、法令の細かい条文より先に思い出せるようになるんだ。\n\n{weak}',
    '個人的には「声に出す」のがおすすめだよ。\n\n目で読むだけより、口に出すと記憶に残りやすいという研究もあるんだ。通勤中にブツブツ言うのも意外と効果あるよ。\n\n{weak}',
    '実は「覚える範囲を絞る」のもコツの一つだよ。\n\n毎回全部を覚えようとせず、今日は法令だけ、と範囲を決めて集中する方が結果的に速く覚えられるんだ。\n\n{weak}',
  ];

  // 「合格した先輩の話」の返答バリエーション
  static const List<String> _seniorStoryTemplates = [
    '実際に合格した人の多くは「毎日ちょっとずつ」がキーワードだよ。\n\n1日20問を60日続けた人が多くて、直前1週間は苦手カテゴリだけを回す「仕上げ期間」を作ってたのが共通点。\n\n康一さんも今のペースを崩さなければ十分狙えるよ。',
    'ある先輩は最初、労働衛生(有害)がずっと苦手だったんだけど、「間違えた問題だけをまとめたノート」を作って、通勤中に見返すようにしたら1か月で正答率が急に上がったって話してたよ。\n\nいきなり満点を目指さなくて大丈夫、まず穴を塞ぐのが近道だね。',
    '別の先輩は仕事が忙しくて勉強時間が全然取れなかったタイプだったけど、「スキマ時間に3問だけ」というルールにしたら継続できたそうだよ。\n\n毎日少しでも触れることが、実は最短ルートだったりするんだ。',
    '合格者に共通していたのは「模試で悪い点を取っても凹まない」姿勢だったよ。\n\n模試はあくまで穴を見つけるための道具、と割り切っていた人ほど最終的に伸びていたのが印象的だね。',
    'ある先輩は語呂合わせノートを自作していて、「試験前日はそのノートだけ見返した」と話してたよ。\n\n新しい知識を入れるより、覚えたことの再確認に時間を使う方が本番では効くみたいだね。',
  ];

  ({String text, ChatAction action}) _mockCoachReply(String userText) {
    final weakest = categoryStats.isEmpty
        ? null
        : categoryStats.reduce((a, b) => a.accuracy <= b.accuracy ? a : b);

    // 「3問だけ出す」「問題出して」など演習開始の意図
    if (userText.contains('3問') ||
        userText.contains('三問') ||
        (userText.contains('問題') && userText.contains('出')) ||
        userText.contains('出題')) {
      final target = weakest?.name ?? '苦手分野';
      final template =
          _quiz3Templates[_chatRandom.nextInt(_quiz3Templates.length)];
      return (
        text: template.replaceAll('{weak}', target),
        action: ChatAction.startQuiz3,
      );
    }
    // 暗記のコツ
    if (userText.contains('コツ') ||
        userText.contains('覚え方') ||
        userText.contains('暗記')) {
      final weakNote = weakest != null
          ? '${weakest.name}が今ちょっと苦手気味だから、そこから固めてみるのもいいかもね。'
          : '';
      final template =
          _memoTipTemplates[_chatRandom.nextInt(_memoTipTemplates.length)];
      return (
        text: template.replaceAll('{weak}', weakNote),
        action: ChatAction.none,
      );
    }
    // 合格した先輩の話
    if (userText.contains('先輩') ||
        userText.contains('体験談') ||
        userText.contains('経験')) {
      final template =
          _seniorStoryTemplates[_chatRandom.nextInt(
            _seniorStoryTemplates.length,
          )];
      return (text: template, action: ChatAction.openWeakReview);
    }
    // 合格率・難易度に関する質問
    if (userText.contains('合格率') ||
        userText.contains('合格率') ||
        (userText.contains('難易度') || userText.contains('難し'))) {
      return (
        text:
            '第一種はだいたい40〜47%、第二種は48〜55%くらいが目安だよ。\n\n国家資格の中では高めだけど、「各科目40%以上・全体60%以上」の基準があるから、苦手科目を作らないことが合格の近道だよ。',
        action: ChatAction.none,
      );
    }
    // よく出る問題・頻出分野に関する質問
    if (userText.contains('よく出る') ||
        userText.contains('頻出') ||
        userText.contains('出やすい')) {
      final target = weakest?.name;
      final text = target != null
          ? '君の場合は「$target」の正答率がまだ低めだから、そこが頻出かつ要注意ゾーンだよ。\n\n「苦手復習」から優先的に解いてみると効率よく点数が伸びるよ。'
          : '関係法令と労働衛生は毎回まんべんなく出る印象だよ。\n\nまずは何問か解いてみると、僕が君専用の頻出・苦手分野を分析できるようになるよ。';
      return (text: text, action: ChatAction.openWeakReview);
    }
    return (
      text: 'いい質問だね。その調子で続けていこう!わからない問題があれば、いつでも聞いてね。',
      action: ChatAction.none,
    );
  }
}
