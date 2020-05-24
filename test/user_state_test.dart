import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:mockito/mockito.dart';

import 'mocks.dart';

void main() {
  group('Login', () {

    UserState userState;
    InvAuthServiceMock invAuthServiceMock;

    setUp(() {
      invAuthServiceMock = InvAuthServiceMock();
      when(invAuthServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.empty());

      GetIt.instance.reset();
      GetIt.instance.registerSingleton<InvAuthService>(invAuthServiceMock);
      userState = UserState();
    });

    test('sign-in with email', () {
      userState.signInWithEmail('email', 'password');

      verify(invAuthServiceMock.signInWithEmailAndPassword(email: 'email', password: 'password')).called(1);
      expect(userState.status, InvStatus.Authenticating);
    });

    test('sign-in with Google', () {
      userState.signInWithGoogle();

      verify(invAuthServiceMock.signInWithGoogle()).called(1);
      expect(userState.status, InvStatus.Authenticating);
    });

    test('sign-in with Apple', () {
      userState.signInWithApple();

      verify(invAuthServiceMock.signInWithApple()).called(1);
      expect(userState.status, InvStatus.Authenticating);
    });

    test('sign-out', () async {
      await userState.signOut();

      verify(invAuthServiceMock.signOut()).called(1);
      expect(userState.status, InvStatus.Unauthenticated);
    });

  });
}