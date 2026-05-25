import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:room_finder_app/core/constants/storage_keys.dart';
import 'package:room_finder_app/core/utils/hive_storage_service.dart';
import 'package:room_finder_app/core/utils/local_session_service.dart';
import 'package:room_finder_app/data/repositories/local_auth_repository.dart';
import 'package:room_finder_app/data/repositories/local_chat_storage.dart';
import 'package:room_finder_app/data/repositories/local_landlord_request_storage.dart';
import 'package:room_finder_app/data/repositories/local_room_storage.dart';
import 'package:room_finder_app/data/repositories/mock_room_repository.dart';
import 'package:room_finder_app/domain/entities/app_enums.dart';
import 'package:room_finder_app/presentation/providers/auth_provider.dart';
import 'package:room_finder_app/presentation/providers/chat_provider.dart';
import 'package:room_finder_app/presentation/providers/landlord_request_provider.dart';
import 'package:room_finder_app/presentation/providers/room_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('room_finder_hive_test');
    Hive.init(tempDir.path);
    await HiveStorageService.openBoxes();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LandlordRequestProvider', () {
    setUp(() async {
      await Hive.box<dynamic>(HiveBoxes.landlordRequests).clear();
    });

    test('loads mock requests and can find request by user id', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();

      await provider.loadRequests();

      expect(provider.requests, isNotEmpty);
      expect(
        provider.getUserRequest('u_user_1')?.status,
        LandlordRequestStatus.pending,
      );
    });

    test('resubmits rejected request as pending and clears reason', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();
      await provider.loadRequests();

      final bool submitted = await provider.submitRequest(
        userId: 'u_user_3',
        fullName: 'Pham Minh Hai',
        phoneNumber: '+84909990011',
        identityNumber: '001199002233',
        currentAddress: '5 Pham Van Dong, Thu Duc',
        identityImageUrl: 'https://example.com/identity.jpg',
        requestMessage: 'Please verify my landlord account again.',
      );
      final request = provider.getUserRequest('u_user_3');

      expect(submitted, isTrue);
      expect(request, isNotNull);
      expect(request!.status, LandlordRequestStatus.pending);
      expect(request.rejectionReason, isNull);
    });

    test('approves pending request', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();
      await provider.loadRequests();

      final bool approved = provider.approveRequest('lr1');
      final request = provider.getUserRequest('u_user_1');

      expect(approved, isTrue);
      expect(request?.status, LandlordRequestStatus.approved);
    });

    test('approval and rejection persist after provider reload', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();
      await provider.loadRequests();

      provider.approveRequest('lr1');
      provider.rejectRequest(
        requestId: 'lr3',
        reason: 'Identity photo is too blurry.',
      );

      final LandlordRequestProvider reloadedProvider =
          LandlordRequestProvider();
      await reloadedProvider.loadRequests();

      expect(
        reloadedProvider.getUserRequest('u_user_1')?.status,
        LandlordRequestStatus.approved,
      );
      expect(
        reloadedProvider.getUserRequest('u_user_3')?.status,
        LandlordRequestStatus.rejected,
      );
      expect(
        reloadedProvider.getUserRequest('u_user_3')?.rejectionReason,
        'Identity photo is too blurry.',
      );
    });

    test('blocks duplicate pending request', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();
      await provider.loadRequests();

      final bool submitted = await provider.submitRequest(
        userId: 'u_user_1',
        fullName: 'Nguyen Van An',
        phoneNumber: '+84901234567',
        identityNumber: '079203004512',
        currentAddress: '24 Nguyen Trai, District 1',
        identityImageUrl: 'https://example.com/identity.jpg',
        requestMessage: 'Please review my duplicate request.',
      );

      expect(submitted, isFalse);
      expect(provider.error, 'You already have a pending landlord request.');
    });
  });

  group('AuthProvider', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await Hive.box<dynamic>(HiveBoxes.users).clear();
      await Hive.box<dynamic>(HiveBoxes.landlordRequests).clear();
    });

    test('approved request grants landlord role on login', () async {
      final LandlordRequestProvider requestProvider = LandlordRequestProvider();
      await requestProvider.loadRequests();
      requestProvider.approveRequest('lr1');

      final AuthProvider authProvider = AuthProvider();
      await authProvider.login(
        email: 'user1@roomfinder.app',
        password: '123456',
      );

      expect(authProvider.hasRole(UserRole.landlord), isTrue);
    });

    test('approved landlord role persists after login', () async {
      final LocalAuthRepository authRepository = LocalAuthRepository();
      final LocalLandlordRequestStorage requestStorage =
          LocalLandlordRequestStorage();
      final LandlordRequestProvider requestProvider = LandlordRequestProvider(
        storage: requestStorage,
      );
      await requestProvider.loadRequests();
      requestProvider.approveRequest('lr1');

      final AuthProvider authProvider = AuthProvider(
        authRepository: authRepository,
        requestStorage: requestStorage,
      );
      await authProvider.login(
        email: 'user1@roomfinder.app',
        password: '123456',
      );

      final AuthProvider reloadedAuthProvider = AuthProvider(
        authRepository: authRepository,
        requestStorage: requestStorage,
      );
      await reloadedAuthProvider.login(
        email: 'user1@roomfinder.app',
        password: '123456',
      );

      expect(reloadedAuthProvider.hasRole(UserRole.landlord), isTrue);
    });

    test('register stores a local user that can login later', () async {
      final AuthProvider authProvider = AuthProvider();

      final bool registered = await authProvider.register(
        username: 'Local User',
        email: 'local@example.com',
        password: '123456',
      );
      final bool loggedIn = await authProvider.login(
        email: 'local@example.com',
        password: '123456',
      );

      expect(registered, isTrue);
      expect(loggedIn, isTrue);
      expect(authProvider.email, 'local@example.com');
      expect(authProvider.roles, const <UserRole>[UserRole.user]);
    });

    test('register rejects duplicate email', () async {
      final AuthProvider authProvider = AuthProvider();

      final bool first = await authProvider.register(
        username: 'Local User',
        email: 'duplicate@example.com',
        password: '123456',
      );
      final bool second = await authProvider.register(
        username: 'Another User',
        email: 'duplicate@example.com',
        password: '123456',
      );

      expect(first, isTrue);
      expect(second, isFalse);
    });

    test('default admin account has all modes', () async {
      final AuthProvider authProvider = AuthProvider();

      final bool loggedIn = await authProvider.login(
        email: 'admin@roomfinder.app',
        password: 'admin123',
      );

      expect(loggedIn, isTrue);
      expect(authProvider.roles, const <UserRole>[
        UserRole.user,
        UserRole.landlord,
        UserRole.admin,
      ]);
    });

    test('restoreSession loads saved user from SharedPreferences', () async {
      final LocalAuthRepository authRepository = LocalAuthRepository();
      final LocalSessionService sessionService = LocalSessionService();
      final AuthProvider authProvider = AuthProvider(
        authRepository: authRepository,
        sessionService: sessionService,
      );

      await authProvider.register(
        username: 'Remember Me',
        email: 'remember@example.com',
        password: '123456',
      );
      await authProvider.login(
        email: 'remember@example.com',
        password: '123456',
      );

      final AuthProvider restoredProvider = AuthProvider(
        authRepository: authRepository,
        sessionService: sessionService,
      );
      await restoredProvider.restoreSession();

      expect(restoredProvider.isAuthenticated, isTrue);
      expect(restoredProvider.email, 'remember@example.com');
    });
  });

  group('RoomProvider', () {
    setUp(() async {
      await Hive.box<dynamic>(HiveBoxes.rooms).clear();
    });

    test('approvedFilteredRooms only contains approved rooms', () async {
      final RoomProvider provider = RoomProvider(MockRoomRepository());

      await provider.loadRooms();

      expect(provider.filteredRooms, isNotEmpty);
      expect(provider.approvedFilteredRooms, isNotEmpty);
      expect(
        provider.approvedFilteredRooms.every(
          (room) => room.status == RoomStatus.approved,
        ),
        isTrue,
      );
    });

    test('addRoom creates a pending room for the owner', () async {
      final RoomProvider provider = RoomProvider(MockRoomRepository());
      await provider.loadRooms();

      provider.addRoom(
        ownerId: 'u_landlord_2',
        landlordName: 'landlord',
        landlordPhone: '+84000000000',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        title: 'Test Pending Room',
        price: 700,
        address: '123 Test Street',
        area: 30,
        description: 'Pending room for approval',
        amenities: const <String>['Wi-Fi'],
        capacity: 2,
        furniture: 'Furnished',
      );

      final ownerRooms = provider.roomsForOwner('u_landlord_2');
      final room = ownerRooms.firstWhere(
        (room) => room.title == 'Test Pending Room',
      );

      expect(room.status, RoomStatus.pending);
    });

    test('approveRoom updates room status to approved', () async {
      final RoomProvider provider = RoomProvider(MockRoomRepository());
      await provider.loadRooms();

      final pendingRoom = provider.rooms.firstWhere(
        (room) => room.status == RoomStatus.pending,
      );

      final bool approved = provider.approveRoom(pendingRoom.id);
      final updatedRoom = provider.byId(pendingRoom.id);

      expect(approved, isTrue);
      expect(updatedRoom?.status, RoomStatus.approved);
    });

    test('local storage seeds mock rooms only when box is empty', () async {
      final LocalRoomStorage storage = LocalRoomStorage();

      final List firstLoad = await storage.fetchRooms();
      final int seededCount = firstLoad.length;
      final List secondLoad = await storage.fetchRooms();

      expect(seededCount, greaterThan(0));
      expect(secondLoad.length, seededCount);
    });

    test('added room persists after provider reload', () async {
      final LocalRoomStorage storage = LocalRoomStorage();
      final RoomProvider provider = RoomProvider(storage);
      await provider.loadRooms();

      provider.addRoom(
        ownerId: 'u_landlord_2',
        landlordName: 'landlord',
        landlordPhone: '+84000000000',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        title: 'Persisted Pending Room',
        price: 750,
        address: '456 Local Street',
        area: 28,
        description: 'Room persisted with Hive',
        amenities: const <String>['Wi-Fi'],
        capacity: 2,
        furniture: 'Furnished',
      );

      final RoomProvider reloadedProvider = RoomProvider(storage);
      await reloadedProvider.loadRooms();

      expect(
        reloadedProvider.rooms.any(
          (room) =>
              room.title == 'Persisted Pending Room' &&
              room.status == RoomStatus.pending,
        ),
        isTrue,
      );
    });

    test('local room image path persists after provider reload', () async {
      final LocalRoomStorage storage = LocalRoomStorage();
      final RoomProvider provider = RoomProvider(storage);
      await provider.loadRooms();

      provider.addRoom(
        ownerId: 'u_landlord_2',
        landlordName: 'landlord',
        landlordPhone: '+84000000000',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        title: 'Local Image Room',
        price: 800,
        address: '789 Image Street',
        area: 32,
        description: 'Room with a local image path',
        amenities: const <String>['Wi-Fi'],
        capacity: 2,
        furniture: 'Furnished',
        imageUrls: const <String>['D:/local/room.jpg'],
      );

      final RoomProvider reloadedProvider = RoomProvider(storage);
      await reloadedProvider.loadRooms();
      final room = reloadedProvider.rooms.firstWhere(
        (room) => room.title == 'Local Image Room',
      );

      expect(room.primaryImageUrl, 'D:/local/room.jpg');
    });

    test(
      'approval status and favorite persist after provider reload',
      () async {
        final LocalRoomStorage storage = LocalRoomStorage();
        final RoomProvider provider = RoomProvider(storage);
        await provider.loadRooms();

        final String roomId = provider.rooms.first.id;
        provider.approveRoom(roomId);
        provider.toggleFavorite(roomId);

        final RoomProvider reloadedProvider = RoomProvider(storage);
        await reloadedProvider.loadRooms();
        final room = reloadedProvider.byId(roomId);

        expect(room?.status, RoomStatus.approved);
        expect(room?.isFavorite, isTrue);
      },
    );
  });

  group('ChatProvider', () {
    setUp(() async {
      await Hive.box<dynamic>(HiveBoxes.conversations).clear();
      await Hive.box<dynamic>(HiveBoxes.messages).clear();
    });

    test(
      'creates one conversation for same room, user, and landlord',
      () async {
        final ChatProvider provider = ChatProvider(LocalChatStorage());

        final String firstId = provider.ensureThreadForLandlord(
          roomId: 'r1',
          userId: 'u_user_1',
          landlordId: 'u_landlord_1',
          landlordName: 'Minh Tran',
          landlordAvatarUrl: 'https://example.com/avatar.jpg',
          landlordPhone: '+84901234567',
        );
        final String secondId = provider.ensureThreadForLandlord(
          roomId: 'r1',
          userId: 'u_user_1',
          landlordId: 'u_landlord_1',
          landlordName: 'Minh Tran',
          landlordAvatarUrl: 'https://example.com/avatar.jpg',
          landlordPhone: '+84901234567',
        );

        expect(firstId, secondId);
        expect(provider.threads.length, 1);
      },
    );

    test('sent message persists after provider reload', () async {
      final LocalChatStorage storage = LocalChatStorage();
      final ChatProvider provider = ChatProvider(storage);

      final String threadId = provider.ensureThreadForLandlord(
        roomId: 'r1',
        userId: 'u_user_1',
        landlordId: 'u_landlord_1',
        landlordName: 'Minh Tran',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        landlordPhone: '+84901234567',
      );
      provider.sendMessage(threadId: threadId, text: 'Hello landlord');

      final ChatProvider reloadedProvider = ChatProvider(storage);
      await reloadedProvider.loadThreads();

      expect(reloadedProvider.messages(threadId).length, 1);
      expect(reloadedProvider.messages(threadId).first.text, 'Hello landlord');
    });

    test('conversation list sorts newest message first', () async {
      final LocalChatStorage storage = LocalChatStorage();
      final ChatProvider provider = ChatProvider(storage);

      final String olderThreadId = provider.ensureThreadForLandlord(
        roomId: 'r1',
        userId: 'u_user_1',
        landlordId: 'u_landlord_1',
        landlordName: 'Minh Tran',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        landlordPhone: '+84901234567',
      );
      provider.sendMessage(threadId: olderThreadId, text: 'Older');

      await Future<void>.delayed(const Duration(milliseconds: 2));

      final String newerThreadId = provider.ensureThreadForLandlord(
        roomId: 'r2',
        userId: 'u_user_1',
        landlordId: 'u_landlord_2',
        landlordName: 'Linh Nguyen',
        landlordAvatarUrl: 'https://example.com/avatar2.jpg',
        landlordPhone: '+84908886655',
      );
      provider.sendMessage(threadId: newerThreadId, text: 'Newer');

      final ChatProvider reloadedProvider = ChatProvider(storage);
      await reloadedProvider.loadThreads();

      expect(reloadedProvider.threads.first.id, newerThreadId);
    });

    test('markThreadRead clears unread messages', () async {
      final LocalChatStorage storage = LocalChatStorage();
      final String threadId = storage.ensureConversation(
        roomId: 'r1',
        userId: 'u_user_1',
        landlordId: 'u_landlord_1',
        landlordName: 'Minh Tran',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
      );
      storage.sendMessage(
        conversationId: threadId,
        senderId: 'u_landlord_1',
        message: 'Please read this',
      );

      final ChatProvider provider = ChatProvider(storage);
      await provider.loadThreads();
      expect(provider.threadById(threadId)?.unreadCount, 1);

      provider.markThreadRead(threadId);

      final ChatProvider reloadedProvider = ChatProvider(storage);
      await reloadedProvider.loadThreads();
      expect(reloadedProvider.threadById(threadId)?.unreadCount, 0);
    });
  });
}
