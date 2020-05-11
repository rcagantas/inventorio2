import 'package:firebase_auth/firebase_auth.dart';

class InvAuth {
  final String email;
  final String displayName;
  final String photoUrl;
  final String uid;
  final String googleSignInId;

  InvAuth({
    this.email,
    this.displayName,
    this.photoUrl,
    this.uid,
    this.googleSignInId
  });

  static String pullGoogleUserId(FirebaseUser user) {
    for (UserInfo info in user.providerData) {
      if (info.providerId == 'google.com') {
        return info.uid;
      }
    }

    return '';
  }
}