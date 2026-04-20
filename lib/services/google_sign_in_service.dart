import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added this line

class GoogleSignInService {
  // Initialize once — must be called before any sign-in
  static Future<void> initialize() async {
    await GoogleSignIn.instance.initialize();
  }

  Future<User?> signInWithGoogle() async {
    try {
      // v7: singleton pattern, no constructor
      final GoogleSignInAccount googleUser =
      await GoogleSignIn.instance.authenticate();

      // v7: authentication is now synchronous (no await)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 1. Sign in to Firebase Authentication (The Lobby)
      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final User? user = userCredential.user;

      // 2. THE BRIDGE: Create/Update the Firestore document (The Cabinet)
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? "No Name",
          'email': user.email,
          'photoUrl': user.photoURL ?? "",
          'role': 'jobseeker', // Default role for your assignment
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        // SetOptions(merge: true) is key: it won't delete your Age/Skills later!
      }

      return user;
    } on GoogleSignInException catch (e) {
      print('Google Sign-In error: ${e.code} - ${e.description}');
      return null;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }
}