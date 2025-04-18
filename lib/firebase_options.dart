// File generated by FlutterFire CLI.
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDZJkiGeyX13McXggJqfn7tqPKxNOFbuec',
    appId: '1:422244124062:web:f79a685344ce9c8dc8028f',
    messagingSenderId: '422244124062',
    projectId: 'beavercash-1b414',
    authDomain: 'beavercash-1b414.firebaseapp.com',
    storageBucket: 'beavercash-1b414.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmPOEJWm5MuXZYPARCGTAZsQiy840YmVQ',
    appId: '1:422244124062:android:1af30b133965bafbc8028f',
    messagingSenderId: '422244124062',
    projectId: 'beavercash-1b414',
    storageBucket: 'beavercash-1b414.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCnTHOm9w7AtbwdgQKlzOZO1tYsp_okV0Q',
    appId: '1:422244124062:ios:6cb79fadce76b59ec8028f',
    messagingSenderId: '422244124062',
    projectId: 'beavercash-1b414',
    storageBucket: 'beavercash-1b414.firebasestorage.app',
    androidClientId: '422244124062-3lc8u00ht8ss5uvsuk43efa8ue98t67i.apps.googleusercontent.com',
    iosClientId: '422244124062-m6dt24i1m6d82mph9jr51vjmdbjg9tid.apps.googleusercontent.com',
    iosBundleId: 'com.soylentcola.beavercash',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCnTHOm9w7AtbwdgQKlzOZO1tYsp_okV0Q',
    appId: '1:422244124062:ios:6cb79fadce76b59ec8028f',
    messagingSenderId: '422244124062',
    projectId: 'beavercash-1b414',
    storageBucket: 'beavercash-1b414.firebasestorage.app',
    androidClientId: '422244124062-3lc8u00ht8ss5uvsuk43efa8ue98t67i.apps.googleusercontent.com',
    iosClientId: '422244124062-m6dt24i1m6d82mph9jr51vjmdbjg9tid.apps.googleusercontent.com',
    iosBundleId: 'com.soylentcola.beavercash',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDZJkiGeyX13McXggJqfn7tqPKxNOFbuec',
    appId: '1:422244124062:web:746ae424d919a3a9c8028f',
    messagingSenderId: '422244124062',
    projectId: 'beavercash-1b414',
    authDomain: 'beavercash-1b414.firebaseapp.com',
    storageBucket: 'beavercash-1b414.firebasestorage.app',
  );

}