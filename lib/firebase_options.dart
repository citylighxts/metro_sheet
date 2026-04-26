import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDO7LXkp4nhfuaEg_se2bbESx7pwUnOr9g',
    appId: '1:386356118961:web:2c399f32666c0576ade990',
    messagingSenderId: '386356118961',
    projectId: 'metro-sheet',
    authDomain: 'metro-sheet.firebaseapp.com',
    storageBucket: 'metro-sheet.firebasestorage.app',
    measurementId: 'G-0W90GWQEXN',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAtZlQ3hZMXdlndqxsrgip0vGIBuyl09I0',
    appId: '1:386356118961:ios:787b029c730ea1b0ade990',
    messagingSenderId: '386356118961',
    projectId: 'metro-sheet',
    storageBucket: 'metro-sheet.firebasestorage.app',
    iosBundleId: 'com.hanaazizah.metrosheet',
  );
}
