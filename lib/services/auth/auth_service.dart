import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google sign-in. The app is offered sign-in automatically on launch, but it
/// is never a gate: it works fully signed-out, and signing in only
/// personalises the Profile header.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// OAuth web client (client_type 3 in google-services.json); Android's
  /// Credential Manager needs it to mint an ID token Firebase accepts.
  static const _webClientId =
      '508419826525-l8pa7c9obkb13jjmuj503h2uv09i7rbe.apps.googleusercontent.com';

  static const _kDeclinedAt = 'auth_auto_prompt_declined_at';
  static const _kSignedOutByUser = 'auth_signed_out_by_user';

  /// After the user dismisses the launch prompt we stay quiet this long
  /// rather than nagging on every cold start.
  static const _declineCooldown = Duration(days: 7);

  bool _googleInitialized = false;
  bool _autoRunning = false;

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get userChanges => FirebaseAuth.instance.userChanges();

  Future<void> _ensureInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
    _googleInitialized = true;
  }

  /// Exchanges a Google account for a Firebase session. Firebase persists
  /// that session (and refreshes its tokens) across launches on its own.
  Future<void> _signInToFirebase(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw StateError('Google did not return a sign-in token.');
    }
    await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken));
  }

  /// Launch-time sign-in. Already signed in → nothing to do (no popup).
  /// Otherwise: first try Google's silent restore for an account this app was
  /// previously authorised with, and only if that yields nothing show the
  /// account chooser. Never throws and never blocks the app; a dismissed
  /// prompt is not repeated for [_declineCooldown], and an explicit sign-out
  /// disables it until the user signs in again.
  Future<void> autoSignIn() async {
    if (_autoRunning || currentUser != null) return;
    _autoRunning = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kSignedOutByUser) ?? false) return;
      final declinedAt = prefs.getInt(_kDeclinedAt);
      if (declinedAt != null &&
          DateTime.now().difference(
                  DateTime.fromMillisecondsSinceEpoch(declinedAt)) <
              _declineCooldown) {
        return;
      }

      await _ensureInitialized();
      final silent = GoogleSignIn.instance.attemptLightweightAuthentication();
      var account = silent == null ? null : await silent;
      if (account == null && GoogleSignIn.instance.supportsAuthenticate()) {
        try {
          account = await GoogleSignIn.instance.authenticate();
        } on GoogleSignInException catch (e) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            await prefs.setInt(
                _kDeclinedAt, DateTime.now().millisecondsSinceEpoch);
            return;
          }
          rethrow;
        }
      }
      if (account == null) return;
      await _signInToFirebase(account);
    } catch (e) {
      // Offline, no Google account on device, Play services missing, etc.
      debugPrint('Auto sign-in skipped: $e');
    } finally {
      _autoRunning = false;
    }
  }

  /// Returns null on success, or a short user-facing message on failure.
  /// A cancelled sign-in is not an error and also returns null.
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      await _signInToFirebase(account);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kSignedOutByUser);
      await prefs.remove(_kDeclinedAt);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSignedOutByUser, true);
    } catch (_) {}
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
