// coach_ai_settings_screen.dart — あらいコーチのAI連携(Gemini APIキー)設定画面。
// ユーザー自身のGoogle AI Studio APIキーを登録すると、あらいコーチが
// テンプレート応答ではなくGeminiによる自由回答で相談に応じられるようになる。
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../services/gemini_service.dart';
import '../state/app_state.dart';
import '../widgets/coach_bubble.dart';

class CoachAiSettingsScreen extends StatefulWidget {
  const CoachAiSettingsScreen({super.key});

  @override
  State<CoachAiSettingsScreen> createState() => _CoachAiSettingsScreenState();
}

class _CoachAiSettingsScreenState extends State<CoachAiSettingsScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _saved = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final key = await GeminiService.getApiKey();
    if (key != null) {
      _controller.text = key;
      _saved = true;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final key = _controller.text.trim();
    if (key.isEmpty) {
      await GeminiService.clearApiKey();
    } else {
      await GeminiService.saveApiKey(key);
    }
    if (!mounted) return;
    setState(() => _saved = key.isNotEmpty);
    if (key.isNotEmpty) {
      // AI連携バッジ(gemini_linked)の獲得判定
      context.read<AppState>().markGeminiLinked();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          key.isEmpty ? 'APIキーを削除したよ' : 'APIキーを保存したよ!これで自由に相談できるようになったよ',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        backgroundColor: AppColors.bgSoft,
        elevation: 0,
        title: const Text(
          'あらいコーチのAI連携',
          style: TextStyle(
            fontSize: AppFontSize.xl,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadow.card,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CoachAvatar(size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _saved
                                      ? '今、僕はGeminiと連携して自由に質問に答えられる状態だよ。'
                                      : 'APIキーを登録すると、僕がもっと自由に、君専用の相談相手になれるよ。',
                                  style: const TextStyle(
                                    fontSize: AppFontSize.base,
                                    color: AppColors.textDim,
                                    height: 1.6,
                                  ),
                                ),
                                if (_saved) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryFaint,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CoachAvatar(size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'バッジ「あらいコーチAI連携」を獲得したよ',
                                          style: TextStyle(
                                            fontSize: AppFontSize.sm,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI連携するとどう良くなるか(メリット)を明示するセクション
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadow.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '連携すると、僕はこう変わるよ',
                            style: TextStyle(
                              fontSize: AppFontSize.base,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._benefitRow(
                            '💬',
                            '自由な質問にも答えられる',
                            '「よく出る問題は?」「暗記のコツは?」のような、決まった選択肢にない質問にもその場で自然に答えられるようになるよ。',
                          ),
                          ..._benefitRow(
                            '📊',
                            '君の学習データを踏まえて回答',
                            '正答率・連続学習日数・合格可能性など、今の学習状況を踏まえたうえで、より的確なアドバイスができるようになるよ。',
                          ),
                          ..._benefitRow(
                            '🗣️',
                            '会話の自然さがアップ',
                            'テンプレートではなく、その時の会話の流れに合わせた返答になるから、雑談っぽい相談にも応じやすくなるよ。',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Gemini APIキー',
                      style: TextStyle(
                        fontSize: AppFontSize.lg,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _controller,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          hintText: 'AIzaSy... を貼り付け',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textMute,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'キーはこの端末内(ローカル)にのみ保存され、外部には送信されないよ(Gemini API呼び出し時のみ利用)。',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMute,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        child: const Text(
                          '保存する',
                          style: TextStyle(
                            fontSize: AppFontSize.xl,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'APIキーの取得方法',
                            style: TextStyle(
                              fontSize: AppFontSize.base,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8),
                          _ApiKeyStep(
                            number: '1',
                            text: 'Google AI Studio\n(aistudio.google.com/apikey)にアクセス',
                          ),
                          SizedBox(height: 6),
                          _ApiKeyStep(number: '2', text: 'Googleアカウントでログイン'),
                          SizedBox(height: 6),
                          _ApiKeyStep(
                            number: '3',
                            text: '「Create API key」をタップして\nキーを発行',
                          ),
                          SizedBox(height: 6),
                          _ApiKeyStep(
                            number: '4',
                            text: '発行されたキーをこの画面に\n貼り付けて保存',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _benefitRow(
    String emoji,
    String title,
    String desc, {
    bool isLast = false,
  }) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppFontSize.md,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: AppFontSize.sm,
                    color: AppColors.textDim,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (!isLast) const SizedBox(height: 12),
    ];
  }
}

/// APIキー取得手順の1ステップ(番号+説明文)。
/// 番号を丸背景で固定表示し、説明文が折り返しても番号位置がずれないようにする。
class _ApiKeyStep extends StatelessWidget {
  final String number;
  final String text;
  const _ApiKeyStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: const EdgeInsets.only(top: 1),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: AppFontSize.sm,
              color: AppColors.textDim,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
