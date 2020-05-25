import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:dart_extensions_methods/dart_extensions_methods.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:get_it/get_it.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_expiry.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_meta.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/models/inv_user.dart';
import 'package:inventorio2/models/inv_status.dart';
import 'package:inventorio2/services/inv_scheduler_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:inventorio2/utils/log/log_printer.dart';
import 'package:logger/logger.dart';

enum InvSort {
  EXPIRY,
  DATE_ADDED,
  PRODUCT
}

class InvState with ChangeNotifier {
  final logger = Logger(printer: SimpleLogPrinter('InvState'));
  Clock clock = Clock();

  InvStatus currentInvStatus;
  InvUser invUser;
  Map<String, InvMeta> _invMetas = {};
  Map<String, List<InvItem>> _invItemMap = {};
  Map<String, InvProduct> _invProductMap = {};
  Map<String, InvProduct> _invLocalProductMap = {};

  final InvStoreService _invStoreService;
  final InvSchedulerService _invSchedulerService;

  StreamSubscription<InvUser> _userSubscription;
  Map<String, StreamSubscription<InvMeta>> _inventoryMetaSubs = {};
  Map<String, StreamSubscription<List<InvItem>>>_inventorySubs = {};
  Map<String, StreamSubscription<InvProduct>> _productSubs = {};
  Map<String, StreamSubscription<InvProduct>> _localProductSubs = {};

  Map<InvSort, int Function(InvItem item1, InvItem item2)> _sortingFunctionMap;
  InvSort sortingKey = InvSort.EXPIRY;

  List<InvMeta> get invMetas {
    var metaList = invUser.knownInventories
        .where((e) => _invMetas.containsKey(e))
        .map((e) => _invMetas[e]).toList();

    metaList.sort();
    return metaList;
  }

  InvState() :
    _invStoreService = GetIt.instance<InvStoreService>(),
    _invSchedulerService = GetIt.instance<InvSchedulerService>()
  {
    invUser = InvUser.unset(userId: null);
    _invSchedulerService.initialize(
      onSelectNotification: (metaId) async {
        logger.i('Selecting notification with payload $metaId');
        await selectInventory(metaId);
      },
    );

    _sortingFunctionMap = {
      InvSort.EXPIRY: (InvItem item1, InvItem item2) {
        _itemValidationCheck(item1);
        _itemValidationCheck(item2);

        int comparison = item1.expiry.compareTo(item2.expiry);
        return comparison != 0 ? comparison : productSort(item1, item2);
      },

      InvSort.DATE_ADDED: (InvItem item1, InvItem item2) {
        _itemValidationCheck(item1);
        _itemValidationCheck(item2);

        int comparison = item2.dateAdded.compareTo(item1.dateAdded);
        return comparison != 0 ? comparison : productSort(item1, item2);
      },

      InvSort.PRODUCT: productSort
    };

  }

  void userStateChange({InvStatus status, InvAuth auth}) {
    if (currentInvStatus != status) {
      currentInvStatus = status;

      if (currentInvStatus == InvStatus.Unauthenticated) {
        this.clear();
      } else if (currentInvStatus == InvStatus.Authenticated) {
        this.loadUserId(auth);
      }

    }
  }

  Future<void> clear() async {
    _invMetas = {};
    _invItemMap = {};

    invUser = InvUser.unset(userId: null);
    if (_userSubscription != null) {
      await _userSubscription.cancel();
      await _cancelSubscriptions();
      _userSubscription = null;
    }
  }

  Future<void> loadUserId(InvAuth invAuth) async {
    if (invUser.userId == invAuth.uid) {
      return;
    }

    await _invStoreService.migrateUserFromGoogleIdIfPossible(invAuth);
    await _subscribeToUser(invAuth.uid);
  }

  Future<void> _cancelSubscriptions() async {
    logger.i('Cancelling subscriptions...');
    List<Future> cancellations = [];
    cancellations.addAll(_inventoryMetaSubs.values.map((e) => e.cancel()));
    cancellations.addAll(_inventorySubs.values.map((e) => e.cancel()));
    cancellations.addAll(_localProductSubs.values.map((e) => e.cancel()));
    await Future.wait(cancellations);
    logger.i('Cancelled ${cancellations.length} subscriptions');

    _inventoryMetaSubs.clear();
    _inventorySubs.clear();
    _localProductSubs.clear();

    notifyListeners();
  }

  Future<void> _subscribeToUser(String userId) async {
    if (_userSubscription != null) { await _userSubscription.cancel(); }
    _userSubscription = _invStoreService.listenToUser(userId).listen(_onInvUser);
  }

  Future<void> _onInvUser(InvUser user) async {

    if (user.unset) {
      logger.i('Creating new user ${user.userId}');
      invUser = _invStoreService.createNewUser(user.userId);
    } else {
      logger.i('Loading existing user ${user.userId}');
      invUser = user;
    }

    if (_invItemMap.containsKey(invUser.currentInventoryId)) {
      _invItemMap[invUser.currentInventoryId].sort(getSortingFunction(sortingKey));
    }

    notifyListeners();
    invUser.knownInventories.forEach((invMetaId) {
      _subscribeToInventoryList(invMetaId);
      _subscribeToInventoryMeta(invMetaId);
    });
  }

  void _subscribeToInventoryMeta(String invMetaId) {
    _inventoryMetaSubs.putIfAbsent(invMetaId, () {
      return _invStoreService.listenToInventoryMeta(invMetaId).listen(_onInvMeta);
    });
  }

  void _onInvMeta(InvMeta invMeta) {
    _invMetas[invMeta.uuid] = invMeta;
    notifyListeners();
  }

  void _subscribeToInventoryList(String invMetaId) {
    _inventorySubs.putIfAbsent(invMetaId, () {
      logger.i('Subscribing to list $invMetaId');
      return _invStoreService.listenToInventoryList(invMetaId).listen((event) {
        _onInvList(invMetaId, event);
      });
    });
  }
  
  void _runSchedulerWhenListComplete() async {
    var population = invUser.knownInventories
        .countWhere((element) => _invItemMap.containsKey(element));

    if (population != invUser.knownInventories.length) {
      return;
    }

    var listToSchedule = _invItemMap.values.expand((e) => e).toList();
    var expiryList = <InvExpiry>[];

    for (InvItem item in listToSchedule) {
      var product = await fetchProduct(item.code);
      if (product.unset) {
        logger.i('Product information is not ready. Delaying scheduling.');
        return;
      }

      expiryList.add(InvExpiry(item: item, product: product, daysOffset: item.redOffset));
      expiryList.add(InvExpiry(item: item, product: product, daysOffset: item.yellowOffset));
    }

    var now = clock.now();
    expiryList..removeWhere((element) => element.alertDate.compareTo(now) < 0)..sort();
    expiryList = expiryList.sublist(0, expiryList.length > 64? 64 : expiryList.length);

    await _invSchedulerService.clearScheduledTasks();
    logger.i('Running scheduler for ${expiryList.length} items');

    Future.delayed(Duration(milliseconds: 500), () {
      for (var expiry in expiryList) {
        var delayMs = 50 * expiryList.indexOf(expiry);
        _invSchedulerService.delayedScheduleNotification(expiry, delayMs);
      }
    });
  }

  void _onInvList(String invMetaId, List<InvItem> list) async {
    _invItemMap[invMetaId] = list;

    if (list.isNotNullOrEmpty()) {
      _invItemMap[invMetaId].sort(getSortingFunction(sortingKey));

      for (var invItem in _invItemMap[invMetaId]) {
        _subscribeToProduct(invMetaId, invItem.code);
      }
    }
    
    notifyListeners();

    _runSchedulerWhenListComplete();
  }

  void _subscribeToProduct(String invMetaId, String code) {
    _productSubs.putIfAbsent(code, () {
      return _invStoreService.listenToProduct(code)
          .listen(_onInvProductUpdate);
    });

    _localProductSubs.putIfAbsent('$invMetaId-$code', () {
      return _invStoreService.listenToLocalProduct(invMetaId, code)
          .listen(_onInvLocalProductUpdate);
    });
  }

  Future<InvProduct> fetchProduct(String code) async {
    code = sanitizeCode(code);

    if (getProduct(code).unset) {
      _subscribeToProduct(invUser.currentInventoryId, code);
      String invMetaId = invUser.currentInventoryId;

      var product = await _invStoreService.fetchProduct(code);
      var localProduct = await _invStoreService.fetchLocalProduct(invMetaId, code);

      if (product.unset && localProduct.unset) {
        logger.i('Unknown product: $code');
      }

      _onInvProductUpdate(product);
      _onInvLocalProductUpdate(localProduct);
    }

    return getProduct(code);
  }

  void _onInvProductUpdate(InvProduct invProduct) {
    if (invProduct.unset) {
      return;
    }

    String code = invProduct.code;

    if (!_invProductMap.containsKey(code) || _invProductMap[code] != invProduct) {
      _invProductMap[code] = invProduct;
      logger.i('Product ${invProduct.toJson()}');
      notifyListeners();
    }
  }

  void _onInvLocalProductUpdate(InvProduct invProduct) {
    if (invProduct.unset) {
      return;
    }

    String code = invProduct.code;
    if (!_invLocalProductMap.containsKey(code) || _invLocalProductMap[code] != invProduct) {
      _invLocalProductMap[code] = invProduct;
      logger.i('Local Product ${invProduct.toJson()}');
      notifyListeners();
    }
  }

  InvMeta selectedInvMeta() {
    return _invMetas.containsKey(invUser.currentInventoryId)
        ? _invMetas[invUser.currentInventoryId]
        : InvMeta(name: 'Inventory');
  }

  List<InvItem> selectedInvList() {
    return _invItemMap[invUser.currentInventoryId] ?? [];
  }

  bool isLoading() {
    return _invItemMap[invUser.currentInventoryId] == null;
  }

  static String sanitizeCode(String code) {
    return code.replaceAll('/', '#');
  }


  InvProduct getProduct(String code) {
    code = sanitizeCode(code);
    InvProduct defaultProduct = InvProduct.unset(code: code);
    InvProduct master = _invProductMap.containsKey(code) ? _invProductMap[code] : defaultProduct;
    InvProduct local = _invLocalProductMap.containsKey(code) ? _invLocalProductMap[code] : defaultProduct;

    return !local.unset ? local : master;
  }

  void _itemValidationCheck(InvItem item) {
    String msg;
    if (item.expiry == null)  msg = 'Expiry date is unset for ${item.toJson()}';
    if (item.dateAdded == null) msg = 'Date added is unset for ${item.toJson()}';
    if (msg != null) throw Exception(msg);
  }

  int productSort(InvItem item1, InvItem item2) {
    return getProduct(item1.code).compareTo(getProduct(item2.code));
  }

  int Function(InvItem item1, InvItem item2) getSortingFunction(InvSort sortingKey) {
    return _sortingFunctionMap[sortingKey];
  }

  void toggleSort() {
    var index = InvSort.values.indexOf(sortingKey);
    sortingKey = InvSort.values[(index + 1) % InvSort.values.length];

    var invMetaId = selectedInvMeta().uuid;
    _invItemMap[invMetaId].sort(getSortingFunction(sortingKey));
    notifyListeners();
  }

  Future<void> selectInventory(String metaId) async {
    if (!invUser.unset && invUser.knownInventories.contains(metaId)) {
      logger.i('Selecting inventory $metaId');
      var userBuilder = InvUserBuilder.fromUser(invUser)
        ..currentInventoryId = metaId;
      await _invStoreService.updateUser(userBuilder);
    }
  }

  int inventoryItemCount(String metaId) {
    return _invItemMap[metaId]?.length ?? 0;
  }

  Future<void> selectInvMeta(InvMeta invMeta) async {
    await selectInventory(invMeta.uuid);
  }

  Future<void> removeItem(InvItem item) async {
    logger.i('Deleting item [${getProduct(item.code).name}] ${item.toJson()}');
    await _invStoreService.deleteItem(item);
  }

  Future<void> updateItem(InvItemBuilder itemBuilder) async {
    var product = await fetchProduct(itemBuilder.code);
    if (product.unset) {
      logger.i('Product is unset. Aborting add of item ${itemBuilder.toJson()}');
      return;
    }

    logger.i('Adding item [${product.name}] ${itemBuilder.toJson()}');
    await _invStoreService.updateItem(itemBuilder);
  }

  Future<void> updateProduct(InvProductBuilder productBuilder) async {
    if (invUser.currentInventoryId.isNullOrEmpty()) {
      logger.e('User is unset or currentInventoryId is unset');
      return;
    }

    if (productBuilder.build() == getProduct(productBuilder.code)) {
      logger.i('Product [${productBuilder.name}]: Information did not change. Ignoring.');
      return;
    }

    logger.i('Adding product [${productBuilder.name}] ${productBuilder.toString()}');

    // we need to update the cache immediately so that we can add the item.
    _onInvLocalProductUpdate(productBuilder.build());

    await _invStoreService.updateProduct(productBuilder, invUser.currentInventoryId);
    await _updateProductWithImage(productBuilder);
  }

  Future<File> _compressImage(InvProductBuilder productBuilder) async {
    Stopwatch stopwatch = Stopwatch()..start();

    File resized = await FlutterNativeImage.compressImage(productBuilder.imageFile.path, percentage: 16);
    ImageProperties properties = await FlutterNativeImage.getImageProperties(resized.path);
    logger.i('Resized ${resized.path} to ${properties.height}:${properties.width} [${stopwatch.elapsedMilliseconds}] ms');

    stopwatch.stop();
    return resized;
  }

  Future<void> _updateProductWithImage(InvProductBuilder productBuilder) async {

    if (productBuilder.imageFile == null) {
      return;
    }

    File resized = await _compressImage(productBuilder);
    String imageUrl = await _invStoreService.uploadProductImage(productBuilder.code, resized);
    productBuilder.imageUrl = imageUrl;

    logger.i('Re-uploading with ${productBuilder.imageUrl}');
    await _invStoreService.updateProduct(productBuilder, invUser.currentInventoryId);

    await productBuilder.imageFile.delete();
    await resized.delete();
  }

  Future<void> updateInvMeta(InvMetaBuilder invMetaBuilder) async {
    if (invMetaBuilder.createdBy == null) {
      invMetaBuilder.createdBy = invUser.userId;
    }

    await _invStoreService.updateMeta(invMetaBuilder);

    if (!invUser.knownInventories.contains(invMetaBuilder.uuid)) {
      logger.i('Adding inventory ${invMetaBuilder.uuid}');
      var userBuilder = InvUserBuilder.fromUser(invUser)
        ..knownInventories.add(invMetaBuilder.uuid);
      await _invStoreService.updateUser(userBuilder);
    }
  }

  Future<void> unsubscribeFromInventory(String uuid) async {
    if (invUser.knownInventories.contains(uuid)
        && invUser.knownInventories.length > 1
    ) {
      logger.i('Removing inventory $uuid');
      var userBuilder = InvUserBuilder.fromUser(invUser)
        ..knownInventories.remove(uuid);

      if (userBuilder.currentInventoryId == uuid) {
        userBuilder.currentInventoryId = userBuilder.knownInventories[0];
      }

      await _invStoreService.updateUser(userBuilder);
    }
  }

  Future<InvMeta> addInventory(String uuid) async {
    var meta = await _invStoreService.fetchInvMeta(uuid);

    if (!invUser.knownInventories.contains(uuid) && !meta.unset) {
      var userBuilder = InvUserBuilder.fromUser(invUser)
        ..currentInventoryId = uuid
        ..knownInventories.add(uuid);
      await _invStoreService.updateUser(userBuilder);

    } else if (invUser.knownInventories.contains(uuid)) {
      await this.selectInventory(uuid);
    }
    return meta;
  }

  InvMetaBuilder createNewInventory() {
    return _invStoreService.createNewMeta(invUser.userId);
  }
}