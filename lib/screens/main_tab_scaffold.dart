import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/tokens.dart';
import '../state/app_state.dart';
import '../widgets/badge_detail_dialog.dart';
import 'home_screen.dart';
import 'study_screen.dart';
import 'analysis_screen.dart';
import 'coach_screen.dart';
import 'profile_screen.dart';

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _index = 0;
  bool _badgeDialogShowing = false;

  void _maybeShowBadgeCelebration(AppState appState) {
    if (_badgeDialogShowing) return;
    if (appState.newlyUnlockedBadges.isEmpty) return;
    _badgeDialogShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final badge = appState.popNewlyUnlockedBadge();
      if (badge != null && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => BadgeDetailDialog(badge: badge, isCelebration: true),
        );
      }
      _badgeDialogShowing = false;
      // キューにまだ残っていれば、続けて次のバッジも表示する
      if (mounted && appState.newlyUnlockedBadges.isNotEmpty) {
        _maybeShowBadgeCelebration(appState);
      }
    });
  }

  static const _screens = [
    HomeScreen(),
    StudyScreen(),
    AnalysisScreen(),
    CoachScreen(),
    ProfileScreen(),
  ];

  static const _items = [
    (Icons.home_outlined, Icons.home, 'ホーム'),
    (Icons.menu_book_outlined, Icons.menu_book, '演習'),
    (Icons.bar_chart_outlined, Icons.bar_chart, '分析'),
    (Icons.chat_bubble_outline, Icons.chat_bubble, 'コーチ'),
    (Icons.person_outline, Icons.person, 'マイ'),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    _maybeShowBadgeCelebration(appState);
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        padding: const EdgeInsets.only(top: 10, bottom: 22),
        child: Row(
          children: List.generate(_items.length, (i) {
            final (outlineIcon, filledIcon, label) = _items[i];
            final active = i == _index;
            final color = active ? AppColors.primary : const Color(0xFFB0B8C4);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _index = i),
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                  button: true,
                  label: label,
                  selected: active,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        active ? filledIcon : outlineIcon,
                        color: color,
                        size: 24,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
