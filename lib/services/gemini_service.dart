// gemini_service.dart — あらいコーチの「本当に質問に答える」会話をGemini APIで実現するサービス。
//
// ・APIキーはローカル(SharedPreferences)に保存し、プロフィール画面から設定する想定。
// ・APIキーが未設定/通信エラーの場合は呼び出し元でルールベース応答にフォールバックする
//   (呼び出し元: AppState._mockCoachReply)。
// ・あらいコーチのペルソナ(〜だよ口調・200字目安・優しいコーチング)をシステム指示として
//   注入し、さらに現在の学習データ(正答率・苦手科目・合格可能性・頻出カテゴリなど)を
//   コンテキストとして渡すことで、「よく出る問題は?」「合格率は?」等の自由質問にも
//   個別最適化した返答ができるようにする。
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  GeminiService._();
  static const String _prefsKey = 'gemini_api_key';

  // 特定バージョン名(例: gemini-2.0-flash)は将来Googleの廃止(EOL)により
  // 404エラーになるリスクがあるため、常に最新の安定版を指す
  // "latest"エイリアスを使用する(Google公式ドキュメント推奨方式)。
  // 参考: https://ai.google.dev/gemini-api/docs/models#model-version-name-patterns
  static const String _model = 'gemini-flash-latest';

  // 2026年9月以降、Google側で「Standard key」(AIzaSy...形式・URLの?key=で渡す方式)が
  // 廃止され、新方式の「Auth key」(AQ....形式)に一本化される。
  // Auth keyはURLクエリパラメータではなく、HTTPヘッダー `x-goog-api-key` で渡す必要がある
  // (Google公式ドキュメントのRESTサンプルコードもこの方式)。
  // 参考: https://ai.google.dev/gemini-api/docs/api-key
  // なお `x-goog-api-key` ヘッダーは旧来のAIzaSy形式キーでも問題なく使えるため、
  // URLクエリパラメータ方式は廃止しヘッダー方式に一本化する。
  static String _endpoint() =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static String? _cachedKey;

  /// モバイルでのコピペ時に紛れ込みやすい、見た目には分からない不正な文字を除去する。
  /// ・前後の空白/改行(trim)
  /// ・文字列内部に混入した改行・タブ
  /// ・全角スペース
  /// ・ゼロ幅スペース等の制御文字(コピー元アプリによって混入することがある)
  static String _sanitizeKey(String raw) {
    return raw
        .trim()
        .replaceAll(RegExp(r'[\r\n\t]'), '')
        .replaceAll('\u3000', '') // 全角スペース
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '') // ゼロ幅系
        .trim();
  }

  /// 保存済みのAPIキーを取得(未設定ならnull)。
  static Future<String?> getApiKey() async {
    if (_cachedKey != null) return _cachedKey;
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_prefsKey);
    final cleaned = key != null ? _sanitizeKey(key) : '';
    _cachedKey = cleaned.isNotEmpty ? cleaned : null;
    return _cachedKey;
  }

  static Future<void> saveApiKey(String key) async {
    final cleaned = _sanitizeKey(key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, cleaned);
    _cachedKey = cleaned.isEmpty ? null : cleaned;
  }

  /// 診断用: 保存されているキーの長さと先頭/末尾の一部だけを安全に表示するための文字列を返す。
  /// (キー全体を画面に晒さず、「本当に正しいキーが送信されているか」を確認できるようにする)
  static String maskForDisplay(String key) {
    if (key.isEmpty) return '(空)';
    if (key.length <= 8) return '${key.length}文字: $key';
    return '${key.length}文字: ${key.substring(0, 6)}...${key.substring(key.length - 4)}';
  }

  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    _cachedKey = null;
  }

  static Future<bool> get isConfigured async => (await getApiKey()) != null;

  /// あらいコーチのシステムプロンプト(ペルソナ + コンテキスト)。
  static String _buildSystemPrompt({required String contextInfo}) {
    return '''
あなたは「あらいコーチ」というアライグマのキャラクターです。
第一種・第二種衛生管理者試験の受験勉強をしているユーザーをサポートするAIコーチとして振る舞ってください。

【口調・人格のルール】
- 必ず「〜だよ」「〜だね」「〜しよう」など、親しみやすいフラットな口調で話す(敬語や堅い言葉は使わない)
- 優しく励ますコーチングトーン。ユーザーを否定せず、焦らせない
- 説明は簡潔に。目安として200文字以内でまとめる(表やリストが必要な場合は少し超えてもよいが、冗長にしない)
- 絵文字は多用しない(使うなら1つまで)
- 自分がAIであることを聞かれたら「あらいコーチだよ」と答え、Geminiという名称やモデル名は出さない

【回答のルール】
- ユーザーの質問には必ず具体的に答える。テンプレート的な相づちだけで終わらせない
- 「よく出る問題」「頻出分野」などを聞かれたら、下記のユーザーの学習データにある苦手・頻出カテゴリ情報を根拠に答える
- 「合格率」「難易度」などを聞かれたら、下記の一般的な統計情報を根拠に答える(最新の公式データは受験者自身に安全衛生技術試験協会のサイトで確認するよう一言添えてもよい)
- 衛生管理者試験に無関係な質問(世間話等)にはコーチらしく軽く応じつつ、学習に話を戻す

【一般的な統計情報(参考値、年度により変動あり)】
- 第一種衛生管理者の合格率はおおむね40〜47%程度
- 第二種衛生管理者の合格率はおおむね48〜55%程度
- 合格基準は「各科目ごとの得点が40%以上」かつ「全科目合計が60%以上」

【現在のユーザーの学習データ】
$contextInfo
''';
  }

  /// Gemini APIにユーザーの質問を送信し、あらいコーチとしての返答テキストを取得する。
  /// 失敗時は例外をthrowするので、呼び出し元でtry/catchしてフォールバックすること。
  static Future<String> sendMessage({
    required String userText,
    required String contextInfo,
    List<({bool isUser, String text})> history = const [],
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null) {
      throw StateError('Gemini APIキーが未設定です');
    }

    final contents = <Map<String, dynamic>>[];
    // 直近の会話履歴を渡す(長すぎると無駄なので直近6件程度に制限する想定は呼び出し元で行う)
    for (final h in history) {
      contents.add({
        'role': h.isUser ? 'user' : 'model',
        'parts': [
          {'text': h.text},
        ],
      });
    }
    contents.add({
      'role': 'user',
      'parts': [
        {'text': userText},
      ],
    });

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _buildSystemPrompt(contextInfo: contextInfo)},
        ],
      },
      'contents': contents,
      'generationConfig': {'temperature': 0.8, 'maxOutputTokens': 500},
    });

    final response = await http
        .post(
          Uri.parse(_endpoint()),
          headers: {
            'Content-Type': 'application/json',
            // Auth key(AQ....形式)・Standard key(AIzaSy...形式)どちらもこのヘッダーで認証できる。
            'x-goog-api-key': apiKey,
          },
          body: body,
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final candidates = decoded['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini APIから応答がありませんでした');
    }
    final parts = candidates[0]['content']?['parts'] as List?;
    if (parts == null || parts.isEmpty) {
      throw Exception('Gemini APIの応答形式が不正です');
    }
    final text = parts.map((p) => (p['text'] as String?) ?? '').join().trim();
    if (text.isEmpty) {
      throw Exception('Gemini APIの応答が空でした');
    }
    return text;
  }
}
