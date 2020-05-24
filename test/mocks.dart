import 'package:clock/clock.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:inventorio2/services/inv_auth_service.dart';
import 'package:inventorio2/services/inv_scheduler_service.dart';
import 'package:inventorio2/services/inv_store_service.dart';
import 'package:mockito/mockito.dart';

class InvAuthServiceMock extends Mock implements InvAuthService {}
class InvStoreServiceMock extends Mock implements InvStoreService {}
class InvSchedulerServiceMock extends Mock implements InvSchedulerService {}
class FirebaseUserMock extends Mock implements FirebaseUser {}
class FirebaseUserInfoMock extends Mock implements UserInfo {}
class ClockMock extends Mock implements Clock {}