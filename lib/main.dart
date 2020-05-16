import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:inventorio2/providers/inv_state.dart';
import 'package:inventorio2/providers/user_state.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:inventorio2/services/inv_scheduler_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:inventorio2/widgets/auth/auth_page.dart';
import 'package:inventorio2/widgets/expiry/expiry_page.dart';
import 'package:inventorio2/widgets/inventory_edit/inventory_edit_page.dart';
import 'package:inventorio2/widgets/product_edit/product_edit_page.dart';
import 'package:inventorio2/widgets/scan/scan_page.dart';
import 'package:inventorio2/widgets/settings/settings_page.dart';
import 'package:provider/provider.dart';

void register() {
  GetIt locator = GetIt.instance;
  locator.registerSingleton<InvSchedulerService>(InvSchedulerService(
    notificationsPlugin: FlutterLocalNotificationsPlugin()
  ));
  locator.registerLazySingleton<InvAuthService>(() => InvAuthService(
    auth: FirebaseAuth.instance,
    googleSignIn: GoogleSignIn(),
  ));
  locator.registerLazySingleton(() => InvStoreService(
    store: Firestore.instance,
    storage: FirebaseStorage.instance,
  ));
  locator.registerLazySingleton(() => UserState());
  locator.registerLazySingleton(() => InvState());
}

void main() {
  register();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final GetIt locator = GetIt.instance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ListenableProvider<UserState>.value(value: locator<UserState>()),
        ListenableProvider<InvState>.value(value: locator<InvState>()),
      ],
      child: MaterialApp(
        initialRoute: '/auth',
        routes: {
          AuthPage.ROUTE: (context) => AuthPage(),
          SettingsPage.ROUTE: (context) => SettingsPage(),
          ExpiryPage.ROUTE: (context) => ExpiryPage(),
          ScanPage.ROUTE: (context) => ScanPage(),
          ProductEditPage.ROUTE: (context) => ProductEditPage(),
          InventoryEditPage.ROUTE: (context) => InventoryEditPage(),
        },
        title: 'Inventorio 2',
        theme: ThemeData(
          brightness: Brightness.light,
          fontFamily: 'Montserrat',
          primaryColor: Colors.blue.shade700,
          accentColor: Colors.blue.shade600,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'Montserrat',
          accentColor: Colors.blue.shade500,
        ),
      ),
    );
  }
}