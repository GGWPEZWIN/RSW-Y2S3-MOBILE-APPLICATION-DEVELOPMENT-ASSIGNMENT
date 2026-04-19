import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  static Future<void> initialize() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<User?> signInWithGoogle() async {
    try {
      // v7: singleton pattern, no constructor
      final GoogleSignInAccount googleUser =
      await GoogleSignIn.instance.authenticate();

      // v7: authentication is now synchronous (no await)
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      // v7: idToken still works, accessToken needs scope authorization
      // For Firebase Auth, idToken alone is sufficient
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      return userCredential.user;
    } on GoogleSignInException catch (e) {
      print('Google Sign-In error: ${e.code} - ${e.description}');
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }
}