import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_status.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';

void main() {
  UserState userState;
  InvAuthServiceMock invAuthServiceMock;

  setUp(() {
    GetIt.instance.reset();
    GetIt.instance.registerLazySingleton<InvAuthService>(() => InvAuthServiceMock());

    invAuthServiceMock = GetIt.instance.get<InvAuthService>();
    when(invAuthServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.empty());

    userState = UserState();
  });

  test('sign-in with email', () {
    userState.signInWithEmail('email', 'password');

    verify(invAuthServiceMock.signInWithEmailAndPassword(email: 'email', password: 'password')).called(1);
    expect(userState.status, InvStatus.Authenticating);
  });

  test('sign-in with email failure', () {
    when(invAuthServiceMock.signInWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
        .thenThrow(Exception('failure'));

    userState.signInWithEmail('email', 'password');
    expect(userState.status, InvStatus.Unauthenticated);
  });

  test('sign-in with Google', () {
    userState.signInWithGoogle();

    verify(invAuthServiceMock.signInWithGoogle()).called(1);
    expect(userState.status, InvStatus.Authenticating);
  });

  test('sign-in with Google failure', () async {
    when(invAuthServiceMock.signInWithGoogle()).thenThrow(Exception('failure'));

    await userState.signInWithGoogle();
    expect(userState.status, InvStatus.Unauthenticated);
  });

  test('sign-in with Apple', () {
    userState.signInWithApple();

    verify(invAuthServiceMock.signInWithApple()).called(1);
    expect(userState.status, InvStatus.Authenticating);
  });

  test('sign-in with Apple failure', () async {
    when(invAuthServiceMock.signInWithApple()).thenThrow(Exception('failure'));

    await userState.signInWithApple();
    expect(userState.status, InvStatus.Unauthenticated);
  });

  test('sign-out', () async {
    await userState.signOut();

    verify(invAuthServiceMock.signOut()).called(1);
    expect(userState.status, InvStatus.Unauthenticated);
  });

  test('auth state change to null', () async {
    when(invAuthServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.value(null));

    userState = UserState();

    await Future.delayed(Duration(milliseconds: 30), () {
      expect(userState.status, InvStatus.Unauthenticated);
    });
  });

  test('new auth', () async {
    when(invAuthServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.value(InvAuth(uid: 'uid')));

    userState = UserState();

    await Future.delayed(Duration(milliseconds: 30), () {
      expect(userState.status, InvStatus.Authenticated);
    });
  });
}