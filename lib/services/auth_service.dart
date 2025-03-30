import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';

final log = Logger('authServiceLogs');

class AuthService {

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

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}