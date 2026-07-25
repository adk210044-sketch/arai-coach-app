// app_state.dart — Provider によるグローバル状態管理
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/question.dart';
import '../models/category.dart';
import '../models/chat_message.dart';
import '../data/sample_data.dart';
import '../data/local_store.dart';
import '../data/question_repository.dart';

class AppState extends ChangeNotifier {
  UserProfile profile = LocalStore.loadProfile();

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
  final int dailyGoal = 20;

  // heatmap: date(yyyy-MM-dd) -> count
  Map<String, int> heatmap = LocalStore.loadHeatmap();

  // チャット
  List<ChatMessage> chatMessages = buildInitialChatMessages();

  // 保存した問題(ブックマーク)
  Set<String> bookmarkedIds = LocalStore.loadBookmarks().toSet();

  String get examTypeKey =>
      profile.examType == ExamType.type2 ? 'type2' : 'type1';

  /// 現在の受験区分に対応する問題プール(814問データ)。
  /// 読み込みに失敗している場合はハードコードのサンプル20問にフォールバックする。
  List<Question> get questionPool {
    final repo = QuestionRepository.instance;
    if (repo.isLoaded && repo.all.isNotEmpty) {
      final pool = repo.byExamType(examTypeKey);
      if (pool.isNotEmpty) return pool;
    }
    return kQuestionPool;
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

  // ─── 演習フロー ──────────────────────
  void startSession({String? categoryKey, int count = 10}) {
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
    }
    LocalStore.saveBookmarks(bookmarkedIds.toList());
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

  void retryCurrentQuestion() {
    selectedAnswer = null;
    answered = false;
    questionStartedAt = DateTime.now();
    notifyListeners();
  }

  // ─── チャット ──────────────────────
  void sendUserMessage(String text) {
    if (text.trim().isEmpty) return;
    chatMessages.add(ChatMessage(role: ChatRole.user, text: text.trim()));
    notifyListeners();
    // モック応答(実運用ではSSEでバックエンドに接続)
    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = _mockCoachReply(text);
      chatMessages.add(
        ChatMessage(
          role: ChatRole.ai,
          text: reply.text,
          action: reply.action,
        ),
      );
      notifyListeners();
    });
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
      return (text: template.replaceAll('{weak}', weakNote), action: ChatAction.none);
    }
    // 合格した先輩の話
    if (userText.contains('先輩') ||
        userText.contains('合格') ||
        userText.contains('体験談') ||
        userText.contains('経験')) {
      final template =
          _seniorStoryTemplates[_chatRandom.nextInt(_seniorStoryTemplates.length)];
      return (text: template, action: ChatAction.openWeakReview);
    }
    return (
      text: 'いい質問だね。その調子で続けていこう!わからない問題があれば、いつでも聞いてね。',
      action: ChatAction.none,
    );
  }
}
