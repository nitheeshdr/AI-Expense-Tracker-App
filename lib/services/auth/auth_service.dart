import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Optional Google sign-in. The app works fully signed-out; signing in only
/// personalises the Profile header. Nothing in the app requires an account.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// OAuth web client (client_type 3 in google-services.json); Android's
  /// Credential Manager needs it to mint an ID token Firebase accepts.
  static const _webClientId =
      '508419826525-l8pa7c9obkb13jjmuj503h2uv09i7rbe.apps.googleusercontent.com';

  bool _googleInitialized = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get userChanges => FirebaseAuth.instance.userChanges();

  /// Returns null on success, or a short user-facing message on failure.
  /// A cancelled sign-in is not an error and also returns null.
  Future<String?> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
        _googleInitialized = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) return 'Google did not return a sign-in token.';
      await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken));
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      debugPrint('Google sign-in failed: ${e.code} ${e.description}');
      return 'Google sign-in failed. Please try again.';
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      return 'Google sign-in failed. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      if (_googleInitialized) await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('Google sign-out: $e');
    }
    await FirebaseAuth.instance.signOut();
  }
}

final authUserProvider = StreamProvider<User?>((ref) async* {
  final auth = AuthService.instance;
  yield auth.currentUser;
  yield* auth.userChanges;
});
