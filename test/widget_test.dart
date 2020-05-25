import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:inventorio2/main.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_user.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:inventorio2/services/inv_scheduler_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:mockito/mockito.dart';

import 'mocks.dart';


void main() {

  group('Inventory Repo', () {
    InvState invState;
    InvStoreServiceMock invStoreServiceMock;

    setUp(() {
      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<InvAuthService>(() => InvAuthServiceMock());
      GetIt.instance.registerLazySingleton<InvSchedulerService>(() => InvSchedulerServiceMock());
      GetIt.instance.registerLazySingleton<InvStoreService>(() => InvStoreServiceMock());
      GetIt.instance.registerLazySingleton(() => UserState());
      GetIt.instance.registerLazySingleton(() => InvState());


      invStoreServiceMock = GetIt.instance.get<InvStoreService>();
      when(invStoreServiceMock.listenToUser(any)).thenAnswer((realInvocation) => Stream.empty());
      when(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(any)).thenAnswer((realInvocation) => Future.value());
      when(invStoreServiceMock.listenToInventoryList(any)).thenAnswer((realInvocation) => Stream.fromIterable([<InvItem>[]]));
      when(invStoreServiceMock.listenToInventoryMeta(any)).thenAnswer((realInvocation) => Stream.empty());


      invState = GetIt.instance.get<InvState>();
    });


    test('should create a new inventory and user on first log in', () async {
      // given
      String givenId = 'user_id';
      InvAuth invAuth = InvAuth(uid: givenId);

      // when
      when(invStoreServiceMock.listenToUser(any))
          .thenAnswer((realInvocation) => Stream.fromIterable([InvUser.unset(userId: 'user_id'),]));
      when(invStoreServiceMock.createNewUser(any))
          .thenReturn(InvUser(userId: givenId, currentInventoryId: 'inv_id', knownInventories: ['inv_id']));

      await invState.loadUserId(invAuth);

      // then
      verify(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(invAuth)).called(1);
      verify(invStoreServiceMock.listenToUser(givenId)).called(1);
      verify(invStoreServiceMock.createNewUser(givenId)).called(1);
    });

    test('should load existing inventory when user has logged in', () async {
      // given
      String givenId = 'user_id';
      InvAuth invAuth = InvAuth(uid: givenId);

      // when
      when(invStoreServiceMock.listenToUser(any))
          .thenAnswer((realInvocation) => Stream.fromIterable([
            InvUser(
              userId: givenId,
              currentInventoryId: 'inv_id',
              knownInventories: ['inv_id']
            )
          ]));
      await invState.loadUserId(invAuth);

      // then
      verify(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(invAuth)).called(1);
      verify(invStoreServiceMock.listenToUser(givenId)).called(1);
      verifyNever(invStoreServiceMock.createNewUser(givenId));
    });
  });

  group('Splash Screen', () {
    InvAuthServiceMock authServiceMock;

    setUp(() async {
      GetIt.instance.reset();
      GetIt.instance.registerLazySingleton<InvAuthService>(() => InvAuthServiceMock());
      GetIt.instance.registerLazySingleton<InvSchedulerService>(() => InvSchedulerServiceMock());
      GetIt.instance.registerLazySingleton<InvStoreService>(() => InvStoreServiceMock());
      GetIt.instance.registerLazySingleton(() => UserState());
      GetIt.instance.registerLazySingleton(() => InvState());

      authServiceMock = GetIt.instance.get<InvAuthService>();
      when(authServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.fromIterable([]));
    });

    testWidgets('Show splash screen on entry', (tester) async {
      await tester.pumpWidget(MyApp());

      expect(find.byKey(ObjectKey('icon_small')), findsOneWidget);
    });

    testWidgets('Show login screen when current login is unset', (tester) async {
      when(authServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.fromIterable([null]));

      await tester.pumpWidget(MyApp());
      await tester.pump(Duration(milliseconds: 100));
      expect(find.byKey(ObjectKey('google_sign_in')), findsOneWidget);
      expect(find.byKey(ObjectKey('apple_sign_in')), findsOneWidget);
    });
  });
}