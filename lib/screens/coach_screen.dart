import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../models/chat_message.dart';
import '../data/sample_data.dart';
import '../widgets/coach_bubble.dart';
import 'question_screen.dart';
import 'study_screen.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _send([String? preset]) {
    final text = preset ?? _controller.text;
    if (text.trim().isEmpty) return;
    context.read<AppState>().sendUserMessage(text);
    _controller.clear();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    Future.delayed(const Duration(milliseconds: 700), _scrollToBottom);
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
        appState.startSession(categoryKey: weakest?.key, count: 3);
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QuestionScreen()),
        );
        break;
      case ChatAction.openWeakReview:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StudyScreen()),
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
                const CoachAvatar(size: 42),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'あらいコーチ',
                        style: TextStyle(
                          fontSize: AppFontSize.xl,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: AppColors.ok,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'いつでも聞いてね',
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
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 18),
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == messages.length) {
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
                          child: CoachAvatar(size: 28),
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
                                color: isUser
                                    ? Colors.white
                                    : AppColors.text,
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
