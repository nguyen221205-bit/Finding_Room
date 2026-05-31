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
import 'package:room_finder_app/core/utils/business_code_generator.dart';
import 'package:room_finder_app/presentation/providers/auth_provider.dart';
import 'package:room_finder_app/presentation/providers/chat_provider.dart';
import 'package:room_finder_app/presentation/providers/conversation_provider.dart';
import 'package:room_finder_app/presentation/providers/message_provider.dart';
import 'package:room_finder_app/presentation/providers/landlord_request_provider.dart';
import 'package:room_finder_app/presentation/providers/room_provider.dart';
import 'package:room_finder_app/data/repositories/local_notification_storage.dart';
import 'package:room_finder_app/data/repositories/local_appointment_storage.dart';
import 'package:room_finder_app/data/repositories/local_settings_storage.dart';
import 'package:room_finder_app/presentation/providers/notification_provider.dart';
import 'package:room_finder_app/presentation/providers/appointment_provider.dart';
import 'package:room_finder_app/presentation/providers/settings_provider.dart';
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

      final bool approved = await provider.approveRequest('lr1');
      final request = provider.getUserRequest('u_user_1');

      expect(approved, isTrue);
      expect(request?.status, LandlordRequestStatus.approved);
    });

    test('approval and rejection persist after provider reload', () async {
      final LandlordRequestProvider provider = LandlordRequestProvider();
      await provider.loadRequests();

      await provider.approveRequest('lr1');
      await provider.rejectRequest(
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

    test('isPhoneNumberUnique returns true for empty phone', () async {
      final AuthProvider authProvider = AuthProvider();
      final bool result = await authProvider.isPhoneNumberUnique(
        '',
        'u_user_1',
      );
      expect(result, isTrue);
    });

    test(
      'isPhoneNumberUnique rejects duplicate but allows current owner',
      () async {
        final AuthProvider authProvider = AuthProvider();

        // Seed first user with a phone number
        await authProvider.register(
          username: 'User One',
          email: 'user1_phone@example.com',
          password: '123456',
        );
        await authProvider.login(
          email: 'user1_phone@example.com',
          password: '123456',
        );
        final String u1Id = authProvider.userId;

        await authProvider.updateProfile(
          username: 'User One',
          phoneNumber: '0901234567',
        );

        // Register second user
        await authProvider.logout();
        await authProvider.register(
          username: 'User Two',
          email: 'user2_phone@example.com',
          password: '123456',
        );
        await authProvider.login(
          email: 'user2_phone@example.com',
          password: '123456',
        );
        final String u2Id = authProvider.userId;

        // Checking:
        // A. u1's own phone is unique for u1
        final bool ownResult = await authProvider.isPhoneNumberUnique(
          '0901234567',
          u1Id,
        );
        expect(ownResult, isTrue);

        // B. u1's phone is duplicate for u2
        final bool duplicateResult = await authProvider.isPhoneNumberUnique(
          '0901234567',
          u2Id,
        );
        expect(duplicateResult, isFalse);

        // C. Unused phone is unique for u2
        final bool unusedResult = await authProvider.isPhoneNumberUnique(
          '0987654321',
          u2Id,
        );
        expect(unusedResult, isTrue);
      },
    );
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

      await provider.addRoom(
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

      final bool approved = await provider.approveRoom(pendingRoom.id);
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

      await provider.addRoom(
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

      await provider.addRoom(
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
        await provider.approveRoom(roomId);
        await provider.toggleFavorite(roomId);

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

  group('Business Codes', () {
    test(
      'BusinessCodeGenerator generates correct prefix and increments',
      () async {
        final Box<dynamic> testBox = await Hive.openBox<dynamic>(
          'test_code_box',
        );
        await testBox.clear();

        final code1 = BusinessCodeGenerator.generate(
          prefix: 'USR',
          box: testBox,
          codeExtractor: (entry) => entry as String?,
        );
        expect(code1, 'USR00001');

        await testBox.add('USR00001');
        final code2 = BusinessCodeGenerator.generate(
          prefix: 'USR',
          box: testBox,
          codeExtractor: (entry) => entry as String?,
        );
        expect(code2, 'USR00002');

        await testBox.add('USR00099');
        final code3 = BusinessCodeGenerator.generate(
          prefix: 'USR',
          box: testBox,
          codeExtractor: (entry) => entry as String?,
        );
        expect(code3, 'USR00100');

        await testBox.close();
      },
    );

    test('AuthProvider register generates a unique userCode', () async {
      await Hive.box<dynamic>(HiveBoxes.users).clear();
      final AuthProvider authProvider = AuthProvider();

      final bool registered = await authProvider.register(
        username: 'Unique Code User',
        email: 'unique@example.com',
        password: '123456',
      );
      expect(registered, isTrue);

      final bool loggedIn = await authProvider.login(
        email: 'unique@example.com',
        password: '123456',
      );
      expect(loggedIn, isTrue);
      expect(authProvider.currentUser, isNotNull);
      expect(authProvider.currentUser!.userCode, startsWith('USR'));
      expect(authProvider.currentUser!.userCode.length, 8);
    });

    test('RoomProvider addRoom generates unique roomCode', () async {
      await Hive.box<dynamic>(HiveBoxes.rooms).clear();
      final LocalRoomStorage storage = LocalRoomStorage();
      final RoomProvider provider = RoomProvider(storage);
      await provider.loadRooms();

      provider.addRoom(
        ownerId: 'u_landlord_2',
        landlordName: 'landlord',
        landlordPhone: '+84000000000',
        landlordAvatarUrl: 'https://example.com/avatar.jpg',
        title: 'New Room Code Test',
        price: 700,
        address: '123 Test Street',
        area: 30,
        description: 'Testing roomCode generation',
        amenities: const <String>['Wi-Fi'],
        capacity: 2,
        furniture: 'Furnished',
      );

      final RoomProvider reloadedProvider = RoomProvider(storage);
      await reloadedProvider.loadRooms();

      final ownerRooms = reloadedProvider.roomsForOwner('u_landlord_2');
      final room = ownerRooms.firstWhere(
        (r) => r.title == 'New Room Code Test',
      );
      expect(room.roomCode, startsWith('ROOM'));
      expect(room.roomCode.length, 9);
    });
  });

  group('Chat V2', () {
    setUp(() async {
      await Hive.box<dynamic>(HiveBoxes.conversations).clear();
      await Hive.box<dynamic>(HiveBoxes.messages).clear();
    });

    test(
      'creates conversation with CONVxxxxx code and updates correctly',
      () async {
        final ConversationProvider convProv = ConversationProvider();
        await convProv.loadConversations();

        final conv = await convProv.createConversation(
          participantIds: ['u_renter_1', 'u_landlord_1'],
          roomId: 'r1',
        );

        expect(conv.id, isNotEmpty);
        expect(conv.conversationCode, startsWith('CONV'));
        expect(conv.conversationCode.length, 9); // CONV00001
        expect(
          conv.participantIds,
          containsAll(['u_renter_1', 'u_landlord_1']),
        );
        expect(conv.roomId, 'r1');

        // Check duplicate participants yields same conversation
        final conv2 = await convProv.createConversation(
          participantIds: ['u_renter_1', 'u_landlord_1'],
          roomId: 'r1',
        );
        expect(conv2.id, conv.id);
      },
    );

    test('sends messages and generates MSGxxxxx code', () async {
      final ConversationProvider convProv = ConversationProvider();
      final MessageProvider msgProv = MessageProvider();
      await convProv.loadConversations();
      await msgProv.loadMessages();

      final conv = await convProv.createConversation(
        participantIds: ['u_renter_1', 'u_landlord_1'],
        roomId: 'r1',
      );

      final msg1 = await msgProv.sendMessage(
        conversationId: conv.id,
        senderId: 'u_renter_1',
        receiverId: 'u_landlord_1',
        content: 'Hi landlord, is the room available?',
      );

      expect(msg1.messageCode, startsWith('MSG'));
      expect(msg1.messageCode.length, 8); // MSG00001
      expect(msg1.content, 'Hi landlord, is the room available?');

      await convProv.updateLastMessage(
        conversationId: conv.id,
        lastMessage: msg1.content,
        lastMessageSenderId: 'u_renter_1',
        incrementUnread: true,
      );

      final loadedConv = convProv.getConversationById(conv.id);
      expect(loadedConv?.lastMessage, 'Hi landlord, is the room available?');
      expect(loadedConv?.unreadCount, 1);

      // Renter reads it or landlord reads it
      await msgProv.markAsRead(conv.id, 'u_landlord_1');
      await convProv.resetUnreadCount(conv.id);

      final readConv = convProv.getConversationById(conv.id);
      expect(readConv?.unreadCount, 0);
    });

    test('separates conversations by user ID', () async {
      final ConversationProvider convProv = ConversationProvider();
      await convProv.loadConversations();

      // Conv 1: renter1 ↔ landlord1
      await convProv.createConversation(
        participantIds: ['u_renter_1', 'u_landlord_1'],
      );

      // Conv 2: renter2 ↔ landlord1
      await convProv.createConversation(
        participantIds: ['u_renter_2', 'u_landlord_1'],
      );

      // Conv 3: renter1 ↔ landlord2
      await convProv.createConversation(
        participantIds: ['u_renter_1', 'u_landlord_2'],
      );

      final renter1Chats = convProv.getUserConversations('u_renter_1');
      final renter2Chats = convProv.getUserConversations('u_renter_2');
      final landlord1Chats = convProv.getUserConversations('u_landlord_1');

      expect(renter1Chats.length, 2);
      expect(renter2Chats.length, 1);
      expect(landlord1Chats.length, 2);
    });

    group('NotificationProvider Tests', () {
      late LocalNotificationStorage storage;
      late NotificationProvider provider;

      setUp(() async {
        storage = LocalNotificationStorage();
        provider = NotificationProvider(storage: storage);
        final Box<dynamic> box = Hive.box<dynamic>(HiveBoxes.notifications);
        await box.clear();
        await provider.loadNotifications('test_user_1');
      });

      test(
        'Creates notification and generates correct sequential notificationCode',
        () async {
          await provider.createNotification(
            userId: 'test_user_1',
            title: 'Title 1',
            content: 'Content 1',
            type: NotificationType.verificationApproved,
          );

          expect(provider.notifications.length, 1);
          expect(provider.notifications.first.notificationCode, 'NTF00001');
          expect(provider.notifications.first.userId, 'test_user_1');
          expect(provider.notifications.first.isRead, isFalse);

          await provider.createNotification(
            userId: 'test_user_1',
            title: 'Title 2',
            content: 'Content 2',
            type: NotificationType.roomRejected,
          );

          expect(provider.notifications.length, 2);
          expect(provider.notifications.first.notificationCode, 'NTF00002');
        },
      );

      test('unreadCount and markAsRead flows', () async {
        await provider.createNotification(
          userId: 'test_user_1',
          title: 'Title 1',
          content: 'Content 1',
          type: NotificationType.verificationApproved,
        );

        await provider.createNotification(
          userId: 'test_user_1',
          title: 'Title 2',
          content: 'Content 2',
          type: NotificationType.roomRejected,
        );

        expect(provider.unreadCount, 2);

        final String firstId = provider.notifications[1].id;
        await provider.markAsRead(firstId);

        expect(provider.unreadCount, 1);

        await provider.markAllAsRead('test_user_1');
        expect(provider.unreadCount, 0);
      });

      test('archive notification flow', () async {
        await provider.createNotification(
          userId: 'test_user_1',
          title: 'Title 1',
          content: 'Content 1',
          type: NotificationType.verificationApproved,
        );

        final String notifId = provider.notifications.first.id;
        await provider.archiveNotification(notifId);

        expect(provider.notifications.length, 0);

        await provider.loadNotifications('test_user_1');
        expect(provider.notifications.length, 0);
      });
    });

    group('AppointmentProvider', () {
      late AppointmentProvider provider;

      setUp(() async {
        await Hive.box<dynamic>(HiveBoxes.appointments).clear();
        provider = AppointmentProvider(storage: LocalAppointmentStorage());
      });

      test(
        'create appointment generates sequential codes and saves successfully',
        () async {
          final apt1 = await provider.createAppointment(
            roomId: 'room_1',
            landlordId: 'landlord_1',
            tenantId: 'tenant_1',
            tenantName: 'Nguyen Van A',
            tenantPhone: '0901234567',
            numberOfPeople: 2,
            appointmentTime: DateTime.now().add(const Duration(days: 1)),
            note: 'Xem phong buoi chieu',
          );

          expect(apt1, isNotNull);
          expect(apt1!.appointmentCode, 'APT00001');
          expect(apt1.status, AppointmentStatus.pending);

          final apt2 = await provider.createAppointment(
            roomId: 'room_2',
            landlordId: 'landlord_1',
            tenantId: 'tenant_2',
            tenantName: 'Tran Van B',
            tenantPhone: '0907654321',
            numberOfPeople: 1,
            appointmentTime: DateTime.now().add(const Duration(days: 2)),
          );

          expect(apt2, isNotNull);
          expect(apt2!.appointmentCode, 'APT00002');
        },
      );

      test('validate input fields', () async {
        final apt = await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: '', // empty name
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );
        expect(apt, isNull);
        expect(provider.error, 'Họ và tên không được để trống.');

        final aptPhone = await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Nguyen Van A',
          tenantPhone: '', // empty phone
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );
        expect(aptPhone, isNull);
        expect(provider.error, 'Số điện thoại không được để trống.');

        final aptPeople = await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Nguyen Van A',
          tenantPhone: '0901234567',
          numberOfPeople: 0, // invalid people count
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );
        expect(aptPeople, isNull);
        expect(provider.error, 'Số người hẹn phải lớn hơn 0.');
      });

      test('approve and reject appointments updates status', () async {
        final apt = await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Nguyen Van A',
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );

        expect(apt, isNotNull);
        final bool approved = await provider.approveAppointment(apt!.id);
        expect(approved, isTrue);
        expect(provider.appointments.first.status, AppointmentStatus.approved);

        final bool rejected = await provider.rejectAppointment(apt.id);
        expect(rejected, isTrue);
        expect(provider.appointments.first.status, AppointmentStatus.rejected);
      });

      test('loads appointments correctly by landlord and tenant', () async {
        await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Nguyen Van A',
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );

        await provider.createAppointment(
          roomId: 'room_2',
          landlordId: 'landlord_2',
          tenantId: 'tenant_1',
          tenantName: 'Nguyen Van A',
          tenantPhone: '0901234567',
          numberOfPeople: 1,
          appointmentTime: DateTime.now().add(const Duration(days: 2)),
        );

        // Load for landlord_1
        await provider.loadAppointmentsForLandlord('landlord_1');
        expect(provider.appointments.length, 1);
        expect(provider.appointments.first.roomId, 'room_1');

        // Load for tenant_1
        await provider.loadAppointmentsForTenant('tenant_1');
        expect(provider.appointments.length, 2);
      });
    });

    group('SettingsProvider & Notification Filtering', () {
      late SettingsProvider settingsProvider;
      late NotificationProvider notificationProvider;

      setUp(() async {
        await Hive.box<dynamic>(HiveBoxes.settings).clear();
        await Hive.box<dynamic>(HiveBoxes.notifications).clear();
        settingsProvider = SettingsProvider(storage: LocalSettingsStorage());
        notificationProvider = NotificationProvider(
          storage: LocalNotificationStorage(),
          settingsStorage: LocalSettingsStorage(),
        );
      });

      test('Theme toggle and persistence', () async {
        // Default is light (false)
        expect(settingsProvider.isDarkMode, isFalse);

        // Toggle to dark (true)
        await settingsProvider.toggleDarkMode(true);
        expect(settingsProvider.isDarkMode, isTrue);

        // Load new settings provider to check persistence
        final anotherSettings = SettingsProvider(
          storage: LocalSettingsStorage(),
        );
        expect(anotherSettings.isDarkMode, isTrue);
      });

      test('Notification preference toggle and persistence', () async {
        final String userId = 'test_user_settings';
        settingsProvider.loadPreferencesForUser(userId);

        // Default preferences should all be enabled (true)
        expect(
          settingsProvider
              .notificationPreferences
              .verificationNotificationsEnabled,
          isTrue,
        );
        expect(
          settingsProvider
              .notificationPreferences
              .roomApprovalNotificationsEnabled,
          isTrue,
        );
        expect(
          settingsProvider
              .notificationPreferences
              .appointmentNotificationsEnabled,
          isTrue,
        );

        // Disable appointment and verification notifications
        await settingsProvider.toggleAppointmentNotifications(false);
        await settingsProvider.toggleVerificationNotifications(false);

        expect(
          settingsProvider
              .notificationPreferences
              .appointmentNotificationsEnabled,
          isFalse,
        );
        expect(
          settingsProvider
              .notificationPreferences
              .verificationNotificationsEnabled,
          isFalse,
        );
        expect(
          settingsProvider
              .notificationPreferences
              .roomApprovalNotificationsEnabled,
          isTrue,
        );

        // Check persistence by reloading the provider and loading user preferences
        final anotherSettings = SettingsProvider(
          storage: LocalSettingsStorage(),
        );
        anotherSettings.loadPreferencesForUser(userId);
        expect(
          anotherSettings
              .notificationPreferences
              .appointmentNotificationsEnabled,
          isFalse,
        );
        expect(
          anotherSettings
              .notificationPreferences
              .verificationNotificationsEnabled,
          isFalse,
        );
        expect(
          anotherSettings
              .notificationPreferences
              .roomApprovalNotificationsEnabled,
          isTrue,
        );
      });

      test(
        'Enabled notification categories are saved and increment count',
        () async {
          final String userId = 'test_user_settings';
          await notificationProvider.loadNotifications(userId);
          expect(notificationProvider.notifications.length, 0);
          expect(notificationProvider.unreadCount, 0);

          // Create an appointment notification (default enabled)
          await notificationProvider.createNotification(
            userId: userId,
            title: 'Appointment booked',
            content: 'Someone wants to view your room',
            type: NotificationType.appointmentCreated,
          );

          // Reload notifications to verify it was created
          await notificationProvider.loadNotifications(userId);
          expect(notificationProvider.notifications.length, 1);
          expect(notificationProvider.unreadCount, 1);
          expect(
            notificationProvider.notifications.first.title,
            'Appointment booked',
          );
        },
      );

      test(
        'Disabled notification categories are not created and do not increment count',
        () async {
          final String userId = 'test_user_settings';

          // Set preferences to disable appointment notifications
          settingsProvider.loadPreferencesForUser(userId);
          await settingsProvider.toggleAppointmentNotifications(false);

          await notificationProvider.loadNotifications(userId);
          expect(notificationProvider.notifications.length, 0);
          expect(notificationProvider.unreadCount, 0);

          // Attempt to create an appointment notification (should be blocked)
          await notificationProvider.createNotification(
            userId: userId,
            title: 'Appointment booked',
            content: 'Someone wants to view your room',
            type: NotificationType.appointmentCreated,
          );

          // Reload notifications to verify it was NOT created
          await notificationProvider.loadNotifications(userId);
          expect(notificationProvider.notifications.length, 0);
          expect(notificationProvider.unreadCount, 0);

          // Attempt to create a room approval notification (should succeed as it is still enabled)
          await notificationProvider.createNotification(
            userId: userId,
            title: 'Room approved',
            content: 'Your room RM00001 has been approved',
            type: NotificationType.roomApproved,
          );

          await notificationProvider.loadNotifications(userId);
          expect(notificationProvider.notifications.length, 1);
          expect(notificationProvider.unreadCount, 1);
          expect(
            notificationProvider.notifications.first.title,
            'Room approved',
          );
        },
      );
    });

    group('Admin Landlord Management V1', () {
      late AuthProvider authProvider;
      late RoomProvider roomProvider;
      late LandlordRequestProvider requestProvider;
      late NotificationProvider notificationProvider;

      setUp(() async {
        await Hive.box<dynamic>(HiveBoxes.users).clear();
        await Hive.box<dynamic>(HiveBoxes.rooms).clear();
        await Hive.box<dynamic>(HiveBoxes.landlordRequests).clear();
        await Hive.box<dynamic>(HiveBoxes.notifications).clear();

        authProvider = AuthProvider();
        roomProvider = RoomProvider(LocalRoomStorage());
        requestProvider = LandlordRequestProvider();
        notificationProvider = NotificationProvider();
      });

      test(
        'retrieves all users, checks landlord lists, and filters active ownerId',
        () async {
          final users = await authProvider.getAllUsers();
          expect(users, isNotEmpty);

          final landlords = users
              .where((u) => u.roles.contains(UserRole.landlord))
              .toList();
          expect(landlords.any((u) => u.id == 'u_landlord_2'), isTrue);
        },
      );

      test(
        'hides a single room by admin and updates status to hiddenByAdmin with reason, then restores it',
        () async {
          await roomProvider.loadRooms();
          final bool added = await roomProvider.addRoom(
            ownerId: 'u_landlord_2',
            landlordName: 'Landlord User',
            landlordPhone: '0901234567',
            landlordAvatarUrl: '',
            title: 'Room test hide',
            price: 3500000,
            address: '123 Test St',
            area: 25.0,
            description: 'Test description',
            amenities: ['wifi'],
            capacity: 2,
            furniture: 'Bed',
          );
          expect(added, isTrue);

          final String roomId = roomProvider.rooms.first.id;

          final bool hidden = await roomProvider.hideRoomByAdmin(
            roomId: roomId,
            reason: 'Violating room rules',
          );
          expect(hidden, isTrue);

          final updatedRoom = roomProvider.byId(roomId);
          expect(updatedRoom, isNotNull);
          expect(updatedRoom!.status, RoomStatus.hiddenByAdmin);
          expect(updatedRoom.rejectionReason, 'Violating room rules');

          expect(
            roomProvider.approvedFilteredRooms.any((r) => r.id == roomId),
            isFalse,
          );

          // Khôi phục phòng
          final bool restored = await roomProvider.restoreRoomByAdmin(
            roomId: roomId,
          );
          expect(restored, isTrue);

          final restoredRoom = roomProvider.byId(roomId);
          expect(restoredRoom, isNotNull);
          expect(restoredRoom!.status, RoomStatus.approved);
          expect(restoredRoom.rejectionReason, isNull);

          expect(
            roomProvider.approvedFilteredRooms.any((r) => r.id == roomId),
            isTrue,
          );
        },
      );

      test(
        'revokes landlord privileges, shifts active role, hides all landlord rooms, and sends notifications',
        () async {
          final registered = await authProvider.register(
            username: 'new_landlord',
            email: 'new_landlord@test.com',
            password: 'password123',
          );
          expect(registered, isTrue);

          final loggedIn = await authProvider.login(
            email: 'new_landlord@test.com',
            password: 'password123',
          );
          expect(loggedIn, isTrue);
          final String landlordId = authProvider.userId;

          await requestProvider.loadRequests();
          await requestProvider.submitRequest(
            userId: landlordId,
            fullName: 'New Landlord',
            phoneNumber: '0909090909',
            identityNumber: '123456789012',
            currentAddress: 'Test Address',
            identityImageUrl: 'identity.jpg',
            requestMessage: 'Verify me',
          );

          final req = requestProvider.getUserRequest(landlordId);
          expect(req, isNotNull);
          await requestProvider.approveRequest(req!.id);

          authProvider.addRole(UserRole.landlord);
          await authProvider.updateActiveRole(UserRole.landlord);

          expect(
            authProvider.currentUser!.roles.contains(UserRole.landlord),
            isTrue,
          );
          expect(
            authProvider.currentUser!.currentActiveRole,
            UserRole.landlord,
          );

          await roomProvider.loadRooms();
          await roomProvider.addRoom(
            ownerId: landlordId,
            landlordName: 'New Landlord',
            landlordPhone: '0909090909',
            landlordAvatarUrl: '',
            title: 'Landlord Room 1',
            price: 2500000,
            address: 'Test Addr 1',
            area: 20.0,
            description: 'Desc 1',
            amenities: [],
            capacity: 1,
            furniture: 'None',
          );
          await roomProvider.addRoom(
            ownerId: landlordId,
            landlordName: 'New Landlord',
            landlordPhone: '0909090909',
            landlordAvatarUrl: '',
            title: 'Landlord Room 2',
            price: 3000000,
            address: 'Test Addr 2',
            area: 22.0,
            description: 'Desc 2',
            amenities: [],
            capacity: 1,
            furniture: 'None',
          );

          expect(roomProvider.roomsForOwner(landlordId).length, 2);

          await requestProvider.revokeVerificationByUserId(
            userId: landlordId,
            reason: 'Illegal listings',
          );
          expect(
            requestProvider.getUserRequest(landlordId)!.status,
            LandlordRequestStatus.rejected,
          );

          await roomProvider.hideAllRoomsForOwner(
            ownerId: landlordId,
            reason: 'Illegal listings',
          );
          final ownerRooms = roomProvider.roomsForOwner(landlordId);
          for (final r in ownerRooms) {
            expect(r.status, RoomStatus.hiddenByAdmin);
            expect(r.rejectionReason, contains('Illegal listings'));
          }

          final success = await authProvider.revokeLandlordPrivileges(
            landlordId,
          );
          expect(success, isTrue);
          expect(
            authProvider.currentUser!.roles.contains(UserRole.landlord),
            isFalse,
          );
          expect(authProvider.currentUser!.currentActiveRole, UserRole.user);

          await notificationProvider.loadNotifications(landlordId);
          await notificationProvider.createNotification(
            userId: landlordId,
            title: 'Quyền chủ nhà bị thu hồi',
            content: 'Quyền hạn chủ nhà đã bị thu hồi do vi phạm điều khoản.',
            type: NotificationType.landlordPrivilegeRevoked,
          );

          await notificationProvider.loadNotifications(landlordId);
          expect(notificationProvider.notifications.length, 1);
          expect(
            notificationProvider.notifications.first.type,
            NotificationType.landlordPrivilegeRevoked,
          );
        },
      );
    });

    group('Appointment V2 Business Logic & Moderation integration', () {
      late AppointmentProvider provider;

      setUp(() async {
        await Hive.box<dynamic>(HiveBoxes.appointments).clear();
        provider = AppointmentProvider(storage: LocalAppointmentStorage());
      });

      test('Tenant can cancel pending or approved appointments', () async {
        final apt = (await provider.createAppointment(
          roomId: 'room_1',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Tenant A',
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        ))!;

        expect(apt.status, AppointmentStatus.pending);

        // Cancel when pending
        final bool okPending = await provider.cancelAppointmentByTenant(apt.id);
        expect(okPending, isTrue);
        expect(
          provider.appointments.first.status,
          AppointmentStatus.cancelledByTenant,
        );

        // Create approved appointment
        final apt2 = (await provider.createAppointment(
          roomId: 'room_2',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Tenant A',
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 2)),
        ))!;

        await provider.approveAppointment(apt2.id);
        expect(
          provider.appointments.firstWhere((a) => a.id == apt2.id).status,
          AppointmentStatus.approved,
        );

        // Cancel when approved
        final bool okApproved = await provider.cancelAppointmentByTenant(
          apt2.id,
        );
        expect(okApproved, isTrue);
        expect(
          provider.appointments.firstWhere((a) => a.id == apt2.id).status,
          AppointmentStatus.cancelledByTenant,
        );
      });

      test(
        'Landlord can cancel approved appointment and mark as completed',
        () async {
          final apt = (await provider.createAppointment(
            roomId: 'room_1',
            landlordId: 'landlord_1',
            tenantId: 'tenant_1',
            tenantName: 'Tenant A',
            tenantPhone: '0901234567',
            numberOfPeople: 2,
            appointmentTime: DateTime.now().add(const Duration(days: 1)),
          ))!;

          // Cannot cancel when pending
          final bool badCancel = await provider.cancelAppointmentByLandlord(
            apt.id,
          );
          expect(badCancel, isFalse);

          // Approve it first
          await provider.approveAppointment(apt.id);
          expect(
            provider.appointments.first.status,
            AppointmentStatus.approved,
          );

          // Cancel approved
          final bool okCancel = await provider.cancelAppointmentByLandlord(
            apt.id,
          );
          expect(okCancel, isTrue);
          expect(
            provider.appointments.first.status,
            AppointmentStatus.cancelledByLandlord,
          );

          // Complete approved
          final apt2 = (await provider.createAppointment(
            roomId: 'room_2',
            landlordId: 'landlord_1',
            tenantId: 'tenant_1',
            tenantName: 'Tenant A',
            tenantPhone: '0901234567',
            numberOfPeople: 2,
            appointmentTime: DateTime.now().add(const Duration(days: 1)),
          ))!;
          await provider.approveAppointment(apt2.id);

          final bool okComplete = await provider.completeAppointment(apt2.id);
          expect(okComplete, isTrue);
          expect(
            provider.appointments.firstWhere((a) => a.id == apt2.id).status,
            AppointmentStatus.completed,
          );
        },
      );

      test('Admin moderation auto-cancels room appointments', () async {
        // Pending
        await provider.createAppointment(
          roomId: 'bad_room',
          landlordId: 'landlord_1',
          tenantId: 'tenant_1',
          tenantName: 'Tenant A',
          tenantPhone: '0901234567',
          numberOfPeople: 2,
          appointmentTime: DateTime.now().add(const Duration(days: 1)),
        );

        // Approved
        final apt2 = (await provider.createAppointment(
          roomId: 'bad_room',
          landlordId: 'landlord_1',
          tenantId: 'tenant_2',
          tenantName: 'Tenant B',
          tenantPhone: '0907654321',
          numberOfPeople: 1,
          appointmentTime: DateTime.now().add(const Duration(days: 2)),
        ))!;
        await provider.approveAppointment(apt2.id);

        final cancelled = await provider.cancelAppointmentsForRoomByAdmin(
          'bad_room',
        );
        expect(cancelled.length, 2);
        for (final a in cancelled) {
          expect(a.status, AppointmentStatus.cancelledByAdmin);
        }

        // Verify loaded appointments
        await provider.loadAppointmentsForTenant('tenant_1');
        expect(
          provider.appointments
              .firstWhere(
                (a) => a.roomId == 'bad_room' && a.tenantId == 'tenant_1',
              )
              .status,
          AppointmentStatus.cancelledByAdmin,
        );
      });

      test(
        'Admin moderation auto-cancels landlord privileges and appointments',
        () async {
          await provider.createAppointment(
            roomId: 'room_1',
            landlordId: 'bad_landlord',
            tenantId: 'tenant_1',
            tenantName: 'Tenant A',
            tenantPhone: '0901234567',
            numberOfPeople: 2,
            appointmentTime: DateTime.now().add(const Duration(days: 1)),
          );

          final cancelled = await provider.cancelAppointmentsForLandlordByAdmin(
            'bad_landlord',
          );
          expect(cancelled.length, 1);
          expect(cancelled.first.status, AppointmentStatus.cancelledByAdmin);
        },
      );
    });
  });
}
