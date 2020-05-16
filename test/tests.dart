import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import 'package:inventorio2/main.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_expiry.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/models/inv_user.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:mockito/mockito.dart';

class InvAuthServiceMock extends Mock implements InvAuthService {}
class InvStoreServiceMock extends Mock implements InvStoreService {}

void main() {

  group('Hashing', () {

    test('items should have predictable hash', () {
      var date = '2020-04-14T19:00:00Z';
      var item1 = InvItem(uuid: 'uid', code: '01', expiry: date, dateAdded: date, inventoryId: 'inv id');
      var item2 = InvItem(uuid: 'uid', code: '01', expiry: date, dateAdded: date, inventoryId: 'inv id');
      expect(item1.hashCode, item2.hashCode);
    });

    test('products should have predictable hash', () {
      var product1 = InvProduct(code: '01', imageUrl: 'http://x', brand: 'brand', name: 'name', variant: '1');
      var product2 = InvProduct(code: '01', imageUrl: 'http://x', brand: 'brand', name: 'name', variant: '1');
      expect(product1.hashCode, product2.hashCode);
    });

    test('inv expiry should have predictable schedule Id', () {
      var date1 = '2020-04-14T19:00:00Z';
      var date2 = '2020-04-15T19:00:00Z';

      var item1 = InvItem(uuid: 'uid', code: '01', expiry: date1, dateAdded: date1, inventoryId: 'inv id');
      var item2 = InvItem(uuid: 'uid', code: '01', expiry: date2, dateAdded: date1, inventoryId: 'inv id');

      var expiry1Red = InvExpiry(item: item1, daysOffset: item1.redOffset);
      var expiry2Red = InvExpiry(item: item2, daysOffset: item2.redOffset);

      expect(expiry1Red.scheduleId, expiry2Red.scheduleId);
    });
  });

//  group('Inventory Repo', () {
//    InvState invState;
//    InvStoreServiceMock invStoreServiceMock;
//
//    setUp(() {
//      invStoreServiceMock = InvStoreServiceMock();
//      when(invStoreServiceMock.listenToUser(any)).thenAnswer((realInvocation) => Stream.fromIterable([]));
//      when(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(any)).thenAnswer((realInvocation) => Future.value());
//
//      GetIt.instance.reset();
//      GetIt.instance.registerLazySingleton<InvStoreService>(() => invStoreServiceMock);
//
//      invState = InvState();
//    });
//
//
//    test('should create a new inventory and user on first log in', () async {
//      // given
//      String givenId = 'UID';
//      InvAuth invAuth = InvAuth(uid: givenId);
//
//      // when
//      when(invStoreServiceMock.listenToUser(any))
//          .thenAnswer((realInvocation) => Stream.fromIterable([
//            InvUser(
//              userId: 'user_id',
//              currentInventoryId: 'inv_id',
//              knownInventories: ['inv_id'],
//            )
//          ]));
//      await invState.loadUserId(invAuth);
//
//      // then
//      verify(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(invAuth)).called(1);
//      verify(invStoreServiceMock.listenToUser(givenId)).called(1);
//      await untilCalled(invStoreServiceMock.createNewUser(givenId));
//    });
//
//    test('should load existing inventory when user has logged in', () async {
//      // given
//      String givenId = 'UID';
//      InvAuth invAuth = InvAuth(uid: givenId);
//
//      // when
//      when(invStoreServiceMock.listenToUser(any))
//          .thenAnswer((realInvocation) => Stream.fromIterable([
//            InvUser(
//              userId: givenId,
//              currentInventoryId: 'inv_id',
//              knownInventories: ['inv_id']
//            )
//          ]));
//      await invState.loadUserId(invAuth);
//
//      // then
//      verify(invStoreServiceMock.migrateUserFromGoogleIdIfPossible(invAuth)).called(1);
//      verify(invStoreServiceMock.listenToUser(givenId)).called(1);
//      verifyNever(invStoreServiceMock.createNewUser(givenId));
//    });
//  });
//
//  group('Splash Screen', () {
//    InvAuthServiceMock invAuthServiceMock;
//
//    setUp(() async {
//      invAuthServiceMock = InvAuthServiceMock();
//      when(invAuthServiceMock.onAuthStateChanged).thenAnswer((realInvocation) => Stream.fromIterable([]));
//
//      GetIt.instance.reset();
//      GetIt.instance.registerLazySingleton<InvAuthService>(() => invAuthServiceMock);
//      GetIt.instance.registerLazySingleton(() => UserState());
//      GetIt.instance.registerLazySingleton(() => InvState());
//    });
//
//    testWidgets('Show splash screen on entry', (tester) async {
//      await tester.pumpWidget(MyApp());
//
//      expect(find.byKey(ObjectKey('icon_transparent')), findsOneWidget);
//      await tester.pump(Duration(milliseconds: 100));
//    });
//
//    testWidgets('Show login screen when current login is unset', (tester) async {
//      await tester.pumpWidget(MyApp());
//
//      await tester.pump(Duration(milliseconds: 100));
//      expect(find.byKey(ObjectKey('google_sign_in')), findsOneWidget);
//      expect(find.byKey(ObjectKey('apple_sign_in')), findsOneWidget);
//    });
//  });
}
