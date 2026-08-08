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

  // Firebase ConsoleでiOSアプリ(Bundle ID: com.hygienecoach.coach)を
  // 登録した際に発行された、GoogleService-Info.plistの内容に基づく正式値。
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBM4SlMQD8EiQIJoubr5Lrlnvi76G36alg',
    appId: '1:489856876839:ios:5172bda2317d5eee462902',
    messagingSenderId: '489856876839',
    projectId: 'eiseikanri',
    storageBucket: 'eiseikanri.firebasestorage.app',
    iosBundleId: 'com.hygienecoach.coach',
  );
}
