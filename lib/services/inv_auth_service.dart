import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/utils/log/log_printer.dart';
import 'package:logger/logger.dart';

class InvAuthFailure implements Exception {
  String message;
  InvAuthFailure(this.message);
}

class InvAuthService {
  final logger = Logger(printer: SimpleLogPrinter('InvAuthService'));

  FirebaseAuth _auth;
  GoogleSignIn _googleSignIn;
  AppleIdCredential _appleIdCredential;

  Stream<InvAuth> get onAuthStateChanged => _auth.onAuthStateChanged.map((user) {
    return user == null ? null : InvAuth(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
      googleSignInId: _googleSignIn.currentUser?.id
    );
  });

  InvAuthService({
    FirebaseAuth auth,
    GoogleSignIn googleSignIn
  }) {
    this._auth = auth;
    this._googleSignIn = googleSignIn;
  }

  Future<void> signInWithEmailAndPassword({
    @required String email,
    @required String password
  }) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    logger.i('Attempting to silently sign-in with Google...');
    GoogleSignInAccount googleAccount = await _googleSignIn.signInSilently(suppressErrors: true);
    if (googleAccount == null) {
      logger.i('Attempting to sign-in with Google...');
      googleAccount = await _googleSignIn.signIn();
    }

    if (googleAccount == null) {
      throw InvAuthFailure('Failed to sign-in with Google');
    }

    GoogleSignInAuthentication googleCredential = await googleAccount.authentication;
    AuthCredential authCredential = GoogleAuthProvider.getCredential(
        idToken: googleCredential.idToken,
        accessToken: googleCredential.accessToken
    );

    _auth.signInWithCredential(authCredential);
  }

  Future<void> signInWithApple() async {
    logger.i('Attempting to sign-in with Apple...');
    AuthorizationResult result = await AppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    logger.i('Authorization result: ${result.status}');

    switch (result.status) {
      case AuthorizationStatus.cancelled:
      case AuthorizationStatus.error:
        throw new InvAuthFailure('${result.error}');
        break;

      case AuthorizationStatus.authorized:

        _appleIdCredential = result.credential;

        OAuthProvider oAuthProvider = new OAuthProvider(providerId: 'apple.com');
        AuthCredential authCredential = oAuthProvider.getCredential(
            idToken: String.fromCharCodes(_appleIdCredential.identityToken),
            accessToken: String.fromCharCodes(_appleIdCredential.authorizationCode)
        );

        await _auth.signInWithCredential(authCredential);
        break;
    }
  }

  Future<void> signOut() async {
    logger.i('Signing out...');

    await _auth.signOut();
    if (_googleSignIn.currentUser != null) {
      await _googleSignIn.signOut();
    }

    logger.i('Signed out.');
  }

  Future<bool> isAppleSignInAvailable() => AppleSignIn.isAvailable();
}