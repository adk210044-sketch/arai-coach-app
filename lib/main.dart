import 'dart:io' show Platform;
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AppState;
import 'package:provider/provider.dart';
import 'firebase_options.dart';
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
  // Firebase初期化は QuestionRepository.load() より前に行う
  // (load内部で question_patches の取得に Firestore を使うため)。
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('✅ Firebase initialized successfully');
    }
  } catch (e, st) {
    // Firebaseが初期化できなくてもアプリ自体は起動できるようにする
    // (オフライン利用時やFirebase設定不備時のフォールバック)
    if (kDebugMode) {
      debugPrint('❌ Firebase initialization failed: $e');
      debugPrint(st.toString());
    }
  }
  // 問題データ読み込み(同梱JSON→Firestoreパッチ適用の順で内部処理される)。
  // Firebase初期化が失敗していても、Firestore呼び出しはタイムアウト+例外握り込みで
  // 安全にスキップされ、同梱データのみで問題なく起動を継続する。
  await QuestionRepository.instance.load();
  await NotificationService.init();
  // App Tracking Transparency(ATT)許可リクエスト。
  // iOSでは、広告SDK(AdMob)がトラッキング目的でデータを利用する可能性がある場合、
  // そのデータ収集が始まる前に本許可リクエストを表示する必要がある(Appleガイドライン必須)。
  // AdMobの初期化より必ず先に呼ぶこと。Androidでは何もしない(ATTはiOS専用API)。
  if (!kIsWeb && Platform.isIOS) {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // システムダイアログの表示タイミングが早すぎると表示されないことがあるため、
        // 描画完了を待ってから要求する。
        await Future.delayed(const Duration(milliseconds: 200));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
      if (kDebugMode) {
        final result =
            await AppTrackingTransparency.trackingAuthorizationStatus;
        debugPrint('✅ ATT status: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ATT request failed: $e');
      }
    }
  }
  // AdMob初期化(Web版はサポート対象外なのでスキップし、モックにフォールバック)。
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        debugPrint('✅ MobileAds initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ MobileAds initialization failed: $e');
      }
    }
  }
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
            themeMode: ThemeMode.light,
            // CJK統合漢字(例:「雇」等)が中国語向けの字形で表示されて
            // しまう問題を防ぐため、アプリ全体のロケールを日本語に固定する。
            // ロケール未指定だとプラットフォームのCJKフォントフォールバックが
            // 中国語字形を優先することがあるため明示が必要。
            locale: const Locale('ja', 'JP'),
            supportedLocales: const [Locale('ja', 'JP')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
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
