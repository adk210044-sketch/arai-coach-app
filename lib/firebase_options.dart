// File generated manually based on Firebase Console configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAfdJYRAIzeTlERZJkRIH2vpRvT3pJoaUI',
    appId: '1:489856876839:web:9ff4c9761ba03a2d462902',
    messagingSenderId: '489856876839',
    projectId: 'eiseikanri',
    authDomain: 'eiseikanri.firebaseapp.com',
    storageBucket: 'eiseikanri.firebasestorage.app',
    measurementId: 'G-F4TPZ9PTS0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtXA9VyqJlSjyvRLWE06OPIfssUoklif8',
    appId: '1:489856876839:android:dcc7b656a467b92b462902',
    messagingSenderId: '489856876839',
    projectId: 'eiseikanri',
    storageBucket: 'eiseikanri.firebasestorage.app',
  );

  // ⚠️ 暫定値: iOSアプリをまだFirebase Consoleに登録していないため、
  // 正式な appId / apiKey / iosBundleId が発行されていない。
  // Firebase Console → プロジェクト設定 → 「アプリを追加」→ iOS を選択し、
  // Bundle ID に com.hygienecoach.coach を入力してiOSアプリを登録した後、
  // ダウンロードされる GoogleService-Info.plist の値でこのブロックを置き換えること。
  // それまではiOS版のFirestore/Analytics連携は正しく動作しない(初期化は
  // main.dart側でtry/catchしているため、アプリ自体はクラッシュせず動作する)。
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtXA9VyqJlSjyvRLWE06OPIfssUoklif8',
    appId: '1:489856876839:ios:0000000000000000462902',
    messagingSenderId: '489856876839',
    projectId: 'eiseikanri',
    storageBucket: 'eiseikanri.firebasestorage.app',
    iosBundleId: 'com.hygienecoach.coach',
  );
}
