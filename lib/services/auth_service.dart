import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Silently authenticates the user upon app launch.
  /// If they already have an account (Anonymous or Google), it does nothing.
  /// If they are a brand new user, it generates a secure Anonymous UID.
  static Future<void> signInAnonymouslySilently() async {
    try {
      if (_auth.currentUser == null) {
        final userCredential = await _auth.signInAnonymously();
        print("DEBUG: New Anonymous User Generated - UID: ${userCredential.user?.uid}");
      } else {
        print("DEBUG: Existing User Found - UID: ${_auth.currentUser?.uid}");
      }
    } catch (e) {
      // If they have no internet on their very first launch, we catch the error
      // so the app still opens successfully in local-only mode.
      print("DEBUG: Failed to sign in silently (Likely offline): $e");
    }
  }

  /// Helper to grab the UID for our database calls later
  static String? get currentUserId => _auth.currentUser?.uid;
}