import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../data/sample_data.dart';
import '../services/gemini_service.dart';
import '../widgets/coach_bubble.dart';
import '../widgets/quiz_resume_dialog.dart';
import 'study_screen.dart';
import 'paywall_screen.dart';
import 'coach_ai_settings_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Gemini連携済みかどうか(null=判定中, true=連携済み, false=未連携)
  bool? _geminiLinked;

  @override
  void initState() {
    super.initState();
    _checkGeminiLinked();
  }

  Future<void> _checkGeminiLinked() async {
    final apiKey = await GeminiService.getApiKey();
    if (!mounted) return;
    setState(() {
      _geminiLinked = apiKey != null;
    });
  }

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    final appState = context.read<AppState>();
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    appState.sendUserMessage(text).then((_) {
      Future.delayed(const Duration(milliseconds: 150), _scrollToBottom);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _runAction(ChatAction action) {
    final appState = context.read<AppState>();
    switch (action) {
      case ChatAction.startQuiz3:
        final weakest = appState.categoryStats.isEmpty
            ? null
            : appState.categoryStats.reduce(
                (a, b) => a.accuracy <= b.accuracy ? a : b,
              );
        startQuizSession(
          context,
          onStartNew: () => appState.startSession(
            categoryKey: weakest?.key,
            count: 3,
          ),
        );
        break;
      case ChatAction.openWeakReview:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StudyScreen()));
        break;
      case ChatAction.openPaywall:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                const PaywallScreen(trigger: PaywallTrigger.general),
          ),
        );
        break;
      case ChatAction.none:
        break;
    }
  }

  Widget? _actionButton(ChatAction action) {
    String label;
    switch (action) {
      case ChatAction.startQuiz3:
        label = '▶ 3問はじめる';
        break;
      case ChatAction.openWeakReview:
        label = '▶ 苦手分野を見る';
        break;
      case ChatAction.openPaywall:
        label = '💎 プランを見る';
        break;
      case ChatAction.none:
        return null;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => _runAction(action),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final messages = appState.chatMessages;
    final isPremium = appState.isPremium;
    final remaining = appState.remainingChatToday;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                const CoachAvatar(size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'あらいコーチ',
                        style: TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.ok,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'いつでも聞いてね(AI相談対応)',
                            style: TextStyle(
                              fontSize: AppFontSize.sm,
                              color: AppColors.ok,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isPremium)
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PaywallScreen(
                          trigger: PaywallTrigger.general,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryFaint,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '今日 ${remaining ?? 0}/${AppState.freeChatDisplayLimit}回',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7DC),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: const Text(
                      '👑 相談し放題',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA16207),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Gemini未連携の場合のみ表示する注記バナー(連携完了後は非表示)
          if (_geminiLinked == false)
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const CoachAiSettingsScreen(),
                    ),
                  )
                  .then((_) => _checkGeminiLinked()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                color: const Color(0xFFFFF4E5),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFA16207),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '※自由な質問に答えるにはユーザー側でGemini連携が必須だよ。未連携時は決まった質問のみ対応',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFA16207),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      size: 16,
                      color: Color(0xFFA16207),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
              itemCount:
                  messages.length + 1 + (appState.isCoachReplying ? 1 : 0),
              itemBuilder: (context, index) {
                if (appState.isCoachReplying && index == messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: CoachAvatar(size: 40),
                        ),
                        _TypingBubble(),
                      ],
                    ),
                  );
                }
                final quickReplyIndex =
                    messages.length + (appState.isCoachReplying ? 1 : 0);
                if (index == quickReplyIndex) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 36, top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: kQuickReplies.map((q) {
                        return GestureDetector(
                          onTap: () => _send(q),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              q,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: AppFontSize.base,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
                final m = messages[index];
                final isUser = m.role == ChatRole.user;
                final actionBtn = isUser ? null : _actionButton(m.action);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: isUser
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: CoachAvatar(size: 40),
                        ),
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isUser ? 18 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 18),
                          ),
                          boxShadow: isUser ? null : AppShadow.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              m.text,
                              style: TextStyle(
                                color: isUser ? Colors.white : AppColors.text,
                                fontSize: AppFontSize.md,
                                height: 1.7,
                              ),
                            ),
                            if (actionBtn != null) actionBtn,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // input
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderSoft)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSoft,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'コーチに質問…',
                        hintStyle: TextStyle(
                          color: AppColors.textMute,
                          fontSize: AppFontSize.md,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// あらいコーチが「考え中…」であることを示すシンプルなタイピングインジケータ。
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: AppShadow.card,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (_controller.value + i * 0.2) % 1.0;
              final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0, 1);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
