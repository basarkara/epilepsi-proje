import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Firebase options have not been configured for web.',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase options have not been configured for this platform.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAIXeJoTVw2x50lPbR6FN01QysNKDXLxMc',
    appId: '1:186770477228:android:e737e5a47d69cade8d0f09',
    messagingSenderId: '186770477228',
    projectId: 'epilepsi-proje',
    storageBucket: 'epilepsi-proje.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6T1f9cNNThOUTYO8VQaAVbG1XNPjrSPM',
    appId: '1:186770477228:ios:8de3ae25c829db848d0f09',
    messagingSenderId: '186770477228',
    projectId: 'epilepsi-proje',
    storageBucket: 'epilepsi-proje.firebasestorage.app',
    iosBundleId: 'com.example.epilepsiProje',
  );

  static bool get isConfigured => true;
}
