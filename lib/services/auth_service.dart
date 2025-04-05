import 'package:beavercash/services/db_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logging/logging.dart';
// Conditionally import dart:html only for web


import 'dart:io';

final log = Logger('authServiceLogs');

class AuthService {
  final FirestoreService firestoreService = FirestoreService();

  // Google sign in
  signInWithGoogle() async {
    log.info("Signing in with Google...");
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    if (gUser == null) {
      log.severe("Google sign in aborted");
      return null; // The user canceled the sign-in
    }

    final GoogleSignInAuthentication? gAuth = await gUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth?.accessToken,
      idToken: gAuth?.idToken,
    );
    final user;
    try {
     user = await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      log.severe("Error signing in with Google: $e");
      return null;
    }
    log.info("Google sign in successful: ${user.user?.uid}");

    // Create user in Firestore using the new method
    log.info("Creating user document in Firestore...");
    bool success = await firestoreService.createUserAfterSignIn(
      uid: user.user!.uid,
      email: user.user!.email!,
      displayName: user.user?.displayName, 
    );
    
    if (success) {
      log.info('User registered and document created successfully');
    } else {
      log.warning('User registered but document creation failed');
      // Still return normally - we have the Firebase Auth user
    }
    return user;
  }

  signInWithApple() async {
    log.info("Signing in with Apple...");

    // Use a function to get the redirect URI based on platform
    Uri getRedirectUri() {
      if (kIsWeb) {
        // For web, use the Firebase auth handler URL
        return Uri.parse('https://beavercash-1b414.firebaseapp.com/__/auth/handler');
      } else if (Platform.isIOS || Platform.isMacOS) {
        // For iOS/macOS, use the Apple Sign In native flow
        // No redirect needed for native flow
        return Uri.parse('https://beavercash-1b414.firebaseapp.com/__/auth/handler');
      } else if (Platform.isAndroid) {
        // For Android, use a custom URL scheme or app link
        return Uri.parse('com.example.beavercash://login-callback');
      } else {
        // Fallback for other platforms
        return Uri.parse('https://beavercash-1b414.firebaseapp.com/__/auth/handler');
      }
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: 'com.example.beavercash',
        redirectUri: getRedirectUri(),
      ),
    );

    return await FirebaseAuth.instance.signInWithCredential(
      OAuthProvider("apple.com").credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      ),
    );
    } catch (e) {
      log.severe("Error signing in with Apple: $e");
      return null;
    }
  }
}