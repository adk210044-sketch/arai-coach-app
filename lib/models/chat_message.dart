enum ChatRole { ai, user }

/// AIの返信に付随する実アクション。
/// coach_screen側でこれを見てボタン表示・実処理(演習開始など)に紐付ける。
enum ChatAction { none, startQuiz3, openWeakReview }

class ChatMessage {
  final ChatRole role;
  final String text;
  final DateTime timestamp;
  final ChatAction action;

  ChatMessage({
    required this.role,
    required this.text,
    DateTime? timestamp,
    this.action = ChatAction.none,
  }) : timestamp = timestamp ?? DateTime.now();
}
