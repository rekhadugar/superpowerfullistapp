import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NEW: Required for database writes

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static String? get currentUserId => _auth.currentUser?.uid;

  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  static Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final currentUser = _auth.currentUser;
      User? finalUser;

      if (currentUser != null && currentUser.isAnonymous) {
        final userCredential = await currentUser.linkWithCredential(credential);
        finalUser = userCredential.user;
      } else {
        final userCredential = await _auth.signInWithCredential(credential);
        finalUser = userCredential.user;
      }

      // --- NEW: SYNC USER PROFILE TO FIRESTORE ---
      if (finalUser != null && finalUser.email != null) {
        await FirebaseFirestore.instance.collection('users').doc(finalUser.uid).set({
          'email': finalUser.email!.toLowerCase(),
          'displayName': finalUser.displayName ?? 'Listicle User',
          'lastLogin': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // CRITICAL: 'merge: true' ensures we don't accidentally overwrite existing data
      }

      return finalUser;
    } catch (e) {
      print("ERROR: Google Sign-In Failed: $e");
      return null;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}