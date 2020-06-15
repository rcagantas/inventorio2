import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_meta.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/models/inv_status.dart';
import 'package:inventorio2/models/inv_user.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/services/inv_scheduler_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:mockito/mockito.dart';

import '../mocks.dart';

void main() {
  InvState invState;
  InvStoreServiceMock storeServiceMock;

  setUp(() {
    var frozenDate = DateTime.parse('2020-03-28T15:26:00');
    InvItem.clock = ClockMock();
    when(InvItem.clock.now()).thenReturn(frozenDate);

    GetIt.instance.reset();
    GetIt.instance.registerLazySingleton<InvStoreService>(() => InvStoreServiceMock());
    GetIt.instance.registerLazySingleton<InvSchedulerService>(() => InvSchedulerServiceMock());

    storeServiceMock = GetIt.instance.get<InvStoreService>();
    when(storeServiceMock.listenToUser(any)).thenAnswer((realInvocation) {
      var userId = realInvocation.positionalArguments[0];
      return Stream.value(InvUser(
          userId: userId,
          currentInventoryId: 'inv_id',
          knownInventories: ['inv_id', 'inv_id2']
      ));
    });

    when(storeServiceMock.listenToInventoryList(any)).thenAnswer((realInvocation) {
      var expiry1 = frozenDate.toIso8601String(),
          expiry2 = frozenDate.subtract(Duration(days: 2)).toIso8601String(),
          expiry3 = frozenDate.subtract(Duration(days: 1)).toIso8601String();
      var added1 = frozenDate.toIso8601String(),
          added2 = frozenDate.add(Duration(days: 1)).toIso8601String(),
          added3 = frozenDate.add(Duration(days: 2)).toIso8601String();

      return Stream.value([
        InvItem(uuid: 'item_uid_1', code: '01', inventoryId: 'inv_id', expiry: expiry1, dateAdded: added1),
        InvItem(uuid: 'item_uid_2', code: '02', inventoryId: 'inv_id', expiry: expiry2, dateAdded: added2),
        InvItem(uuid: 'item_uid_3', code: '03', inventoryId: 'inv_id', expiry: expiry3, dateAdded: added3),
      ]);
    });

    when(storeServiceMock.listenToInventoryMeta(any)).thenAnswer((realInvocation) {
      var metaId = realInvocation.positionalArguments[0];
      return Stream.value(InvMeta(uuid: metaId, createdBy: 'user_id', name: 'inventory'));
    });

    when(storeServiceMock.listenToProduct(any)).thenAnswer((realInvocation) {
      var code = realInvocation.positionalArguments[0];
      return Stream.value(InvProduct(code: code, name: 'product_$code', brand: 'brand_$code', variant: 'variant_$code'));
    });

    when(storeServiceMock.listenToLocalProduct(any, any)).thenAnswer((realInvocation) {
      var code = realInvocation.positionalArguments[1];
      return Stream.value(InvProduct(code: code, name: 'product_$code', brand: 'brand_$code', variant: 'variant_$code'));
    });

    when(storeServiceMock.fetchProduct(any)).thenAnswer((realInvocation) {
      var code = realInvocation.positionalArguments[0];
      return Future.value(InvProduct(code: code, name: 'product_$code', brand: 'brand_$code', variant: 'variant_$code'));
    });

    when(storeServiceMock.fetchLocalProduct(any, any)).thenAnswer((realInvocation) {
      var code = realInvocation.positionalArguments[1];
      return Future.value(InvProduct(code: code, name: 'product_$code', brand: 'brand_$code', variant: 'variant_$code'));
    });

    when(storeServiceMock.createNewMeta(any)).thenAnswer((realInvocation) {
      var createdByUid = realInvocation.positionalArguments[0];
      return InvMetaBuilder(
        name: 'new_inventory',
        uuid: 'new_inv_id',
        createdBy: createdByUid,
      );
    });

    when(storeServiceMock.createNewUser(any)).thenAnswer((realInvocation) {
      var userId = realInvocation.positionalArguments[0];
      var meta = storeServiceMock.createNewMeta(userId);
      return InvUser(
        userId: userId,
        knownInventories: [meta.uuid],
        currentInventoryId: meta.uuid,
      );
    });
  });

  tearDown(() {
    InvItem.clock = Clock();
  });

  test('should load user on state change', () async {
    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));

    expect(invState.isLoading(), isTrue);
    await Future.delayed(Duration(milliseconds: 10), () {
      verify(storeServiceMock.listenToUser('user_id')).called(1);
      verify(storeServiceMock.listenToInventoryList('inv_id')).called(1);
      verify(storeServiceMock.listenToInventoryMeta('inv_id')).called(1);
      verify(storeServiceMock.listenToLocalProduct('inv_id', any)).called(3);
      verify(storeServiceMock.listenToProduct(any)).called(3);
      expect(invState.isLoading(), isFalse);
      expect(invState.selectedInvMeta().uuid, 'inv_id');
      expect(invState.invMetas.map((e) => e.uuid), ['inv_id', 'inv_id2']);
      expect(invState.selectedInvList().map((e) => e.uuid), ['item_uid_2', 'item_uid_3', 'item_uid_1']);
      expect(invState.inventoryItemCount('inv_id'), 3);
    });
  });

  test('should persist new user', () async {
    when(storeServiceMock.listenToUser(any)).thenAnswer((realInvocation) {
      var userId = realInvocation.positionalArguments[0];
      return Stream.value(InvUser.unset(
        userId: userId,
      ));
    });

    invState = InvState();

    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    verify(storeServiceMock.migrateUserFromGoogleIdIfPossible(any)).called(1);
    verify(storeServiceMock.createNewUser('user_id')).called(1);
    verify(storeServiceMock.createNewMeta('user_id')).called(1);
  });

  test('should cancel subscriptions on logout', () async {
    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    await invState.clear();
    expect(invState.invUser.unset, isTrue);
  });

  test('should listen to user changes', () async {
    when(storeServiceMock.listenToUser(any)).thenAnswer((realInvocation) {
      var userId = realInvocation.positionalArguments[0];
      return Stream.fromIterable([
        InvUser(
            userId: userId,
            currentInventoryId: 'inv_id',
            knownInventories: ['inv_id', 'inv_id2']
        ),
        InvUser(
            userId: userId,
            currentInventoryId: 'inv_id2',
            knownInventories: ['inv_id', 'inv_id2']
        ),
      ]);

    });

    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    expect(invState.selectedInvMeta().name, 'Inventory');
    await Future.delayed(Duration(milliseconds: 10), () {
      expect(invState.selectedInvMeta().uuid, 'inv_id2');
      expect(invState.invMetas.map((e) => e.uuid), ['inv_id', 'inv_id2']);
    });
  });

  test('should toggle sorting by cycling modes', () async {
    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));

    expect(invState.sortingKey, InvSort.EXPIRY);
    await Future.delayed(Duration(milliseconds: 10), () {
      expect(invState.selectedInvList().map((e) => e.uuid), ['item_uid_2', 'item_uid_3', 'item_uid_1']);
    });

    invState.toggleSort();
    expect(invState.sortingKey, InvSort.DATE_ADDED);
    await Future.delayed(Duration(milliseconds: 10), () {
      expect(invState.selectedInvList().map((e) => e.uuid), ['item_uid_3', 'item_uid_2', 'item_uid_1']);
    });

    invState.toggleSort();
    expect(invState.sortingKey, InvSort.PRODUCT);
    await Future.delayed(Duration(milliseconds: 10), () {
      expect(invState.selectedInvList().map((e) => e.uuid), ['item_uid_1', 'item_uid_2', 'item_uid_3']);
    });

  });

  test('select inventory should update user', () async {
    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    await invState.selectInventory('inv_id2');

    var expected = InvUserBuilder.fromUser(invState.invUser)..currentInventoryId = 'inv_id2';
    var verification = verify(storeServiceMock.updateUser(captureAny))..called(1);
    expect(verification.captured.single.currentInventoryId, expected.currentInventoryId);
  });

  test('selecting inv meta should select inventory', () async {
    invState = InvState();
    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    await invState.selectInvMeta(InvMeta(uuid: 'inv_id2'));

    var expected = InvUserBuilder.fromUser(invState.invUser)..currentInventoryId = 'inv_id2';
    var verification = verify(storeServiceMock.updateUser(captureAny))..called(1);
    expect(verification.captured.single.currentInventoryId, expected.currentInventoryId);
  });

  test('should remove item', () async {
    invState = InvState();
    var item = InvItem(uuid: 'inv_uid_1', code: '01');

    await invState.userStateChange(status: InvStatus.Authenticated, auth: InvAuth(uid: 'user_id'));
    await invState.removeItem(item);
    verify(storeServiceMock.deleteItem(item)).called(1);
  });
}