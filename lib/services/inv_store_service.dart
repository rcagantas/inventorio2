import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:inventorio2/models/inv_auth.dart';
import 'package:inventorio2/models/inv_item.dart';
import 'package:inventorio2/models/inv_meta.dart';
import 'package:inventorio2/models/inv_product.dart';
import 'package:inventorio2/models/inv_user.dart';
import 'package:inventorio2/utils/log/log_printer.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

class InvContainer {
  final InvMeta invMeta;
  final List<InvItem> invList;

  InvContainer({this.invMeta, this.invList});
}

class InvStoreService {
  final logger = Logger(printer: SimpleLogPrinter('InvStoreService'));
  static final Uuid _uuid = Uuid();

  static const String ITEMS = 'inventoryItems';
  static const String PRODUCTS = 'productDictionary';
  static const String IMAGES = 'images';

  Firestore store;
  FirebaseStorage storage;

  CollectionReference get _users => store.collection('users');
  CollectionReference get _inventory => store.collection('inventory');
  CollectionReference get _products => store.collection(PRODUCTS);

  static String generateUuid() => _uuid.v4();

  InvStoreService({
    this.store,
    this.storage
  });

  Stream<InvUser> listenToUser(String uid) {
    return _users.document(uid).snapshots()
        .map((event) {
          return event.exists
              ? InvUser.fromJson(event.data)
              : InvUser.unset(userId: uid);
        });
  }

  Stream<InvMeta> listenToInventoryMeta(String invMetaId) {
    return _inventory.document(invMetaId).snapshots()
        .map((event) {
          return event.exists
              ? InvMeta.fromJson(event.data)
              : InvMeta(uuid: invMetaId);
        });
  }

  Stream<List<InvItem>> listenToInventoryList(String invMetaId) {
    return _inventory.document(invMetaId).collection(ITEMS).snapshots()
        .map((event) => event.documents
          .map((e) => InvItem.fromJson(e.data))
          .map((e) => e.ensureValid(invMetaId))
          .toList());
  }

  Stream<InvProduct> listenToProduct(String code) {
    return _products.document(code).snapshots()
        .map((event) {
          return event.exists
              ? InvProduct.fromJson(event.data)
              : InvProduct.unset(code: code);
        });
  }

  Future<InvProduct> fetchProduct(String code) async {
    return await _products.document(code).get().then((value) {
      return value.exists
          ? InvProduct.fromJson(value.data)
          : InvProduct.unset(code: code);
    });
  }

  Stream<InvProduct> listenToLocalProduct(String invMetaId, String code) {
    return _inventory.document(invMetaId).collection(PRODUCTS)
        .document(code)
        .snapshots()
        .map((event) {
          return event.exists
              ? InvProduct.fromJson(event.data)
              : InvProduct.unset(code: code);
        });
  }

  Future<InvProduct> fetchLocalProduct(String invMetaId, String code) async {
    return _inventory.document(invMetaId).collection(PRODUCTS)
        .document(code)
        .get()
        .then((value) {
          return value.exists
              ? InvProduct.fromJson(value.data)
              : InvProduct.unset(code: code);
        });
  }

  InvMetaBuilder createNewMeta(String createdByUid) {
    return InvMetaBuilder(
      createdBy: createdByUid,
      name: 'Inventory',
      uuid: generateUuid()
    );
  }

  InvUser createNewUser(String uid) {
    InvMetaBuilder metaBuilder = createNewMeta(uid);
    updateMeta(metaBuilder);

    var userBuilder = InvUserBuilder(
        currentInventoryId: metaBuilder.uuid,
        knownInventories: [metaBuilder.uuid],
        userId: uid
    );

    logger.i('Creating new user ${userBuilder.toJson()}');
    updateUser(userBuilder);
    return userBuilder.build();
  }

  Future<InvUser> updateUser(InvUserBuilder userBuilder) async {
    InvUser user = userBuilder.build();
    await _users.document(user.userId).setData(user.toJson());
    return user;
  }

  Future<InvMeta> updateMeta(InvMetaBuilder metaBuilder) async {
    var meta = metaBuilder.build();
    await _inventory.document(meta.uuid).setData(meta.toJson());
    return meta;
  }

  Future migrateUserFromGoogleIdIfPossible(InvAuth invAuth) async {
    String googleSignInId = invAuth.googleSignInId;
    String firebaseUid = invAuth.uid;

    DocumentSnapshot googleSnapshot = await _users.document(googleSignInId).get();
    DocumentSnapshot fireBaseSnapshot = await _users.document(firebaseUid).get();

    if (googleSnapshot.exists && !fireBaseSnapshot.exists) {
      logger.i('Migrating gId $googleSignInId to $firebaseUid');

      InvUser googleInvUser = InvUser.fromJson(googleSnapshot.data);
      await _users.document(firebaseUid).setData(InvUser(
        userId: firebaseUid,
        currentInventoryId: googleInvUser.currentInventoryId,
        knownInventories: googleInvUser.knownInventories
      ).toJson());
    }
  }

  Future<void> deleteItem(InvItem item) async {
    await _inventory.document(item.inventoryId)
        .collection(ITEMS)
        .document(item.uuid)
        .delete();
  }

  Future<void> updateItem(InvItemBuilder itemBuilder) async {
    var item = itemBuilder.build();
    await _inventory.document(item.inventoryId)
        .collection(ITEMS)
        .document(item.uuid)
        .setData(item.toJson());
  }

  Future<void> updateProduct(InvProductBuilder productBuilder, String inventoryId) async {
    var product = productBuilder.build();
    await _inventory.document(inventoryId)
        .collection(PRODUCTS)
        .document(product.code)
        .setData(product.toJson());

    await _products.document(product.code)
        .setData(product.toJson());
  }

  Future<String> uploadProductImage(String code, File image) async {
    var uuid = generateUuid();
    var fileName = '${code}_$uuid.jpg';
    var storageReference = storage.ref().child(IMAGES).child(fileName);
    var uploadTask = storageReference.putData(image.readAsBytesSync());

    await uploadTask.onComplete;
    String url = await storageReference.getDownloadURL();

    logger.i('Uploaded ${image.path} to $url with $uploadTask');
    return url;
  }
}