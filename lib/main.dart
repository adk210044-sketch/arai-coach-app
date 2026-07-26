import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/app_state.dart';
import 'models/user_profile.dart';
import 'data/local_store.dart';
import 'data/question_repository.dart';
import 'services/notification_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_tab_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStore.init();
  await QuestionRepository.instance.load();
  await NotificationService.init();
  runApp(const HygieneCoachApp());
}

class HygieneCoachApp extends StatelessWidget {
  const HygieneCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Builder(
        builder: (context) {
          final scale = context
              .watch<AppState>()
              .profile
              .textSizeOption
              .scaleFactor;
          return MaterialApp(
            title: 'Hygiene Coach',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              );
            },
            home: const _RootRouter(),
          );
        },
      ),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.profile.onboardingDone) {
      return const MainTabScaffold();
    }
    return const OnboardingScreen();
  }
}
