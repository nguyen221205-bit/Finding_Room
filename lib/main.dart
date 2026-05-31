import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/hive_storage_service.dart';
import 'core/utils/local_session_service.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/local_auth_repository.dart';
import 'data/repositories/local_chat_storage.dart';
import 'data/repositories/local_landlord_request_storage.dart';
import 'data/repositories/local_room_storage.dart';
import 'data/repositories/room_repository.dart';
import 'domain/entities/app_enums.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/favorite_provider.dart';
import 'presentation/providers/landlord_request_provider.dart';
import 'presentation/providers/role_provider.dart';
import 'presentation/providers/room_provider.dart';
import 'presentation/providers/conversation_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'data/repositories/local_notification_storage.dart';
import 'data/repositories/local_appointment_storage.dart';
import 'data/repositories/local_settings_storage.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/appointment_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorageService.initialize();
  await LocalLandlordRequestStorage().seedIfNeeded();
  await LocalAuthRepository().ensureDefaultUsers();
  runApp(const RoomFinderApp());
}

class RoomFinderApp extends StatelessWidget {
  const RoomFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<RoomRepository>(create: (_) => LocalRoomStorage()),
        Provider<ChatRepository>(create: (_) => LocalChatStorage()),
        Provider<LocalSessionService>(create: (_) => LocalSessionService()),
        Provider<LocalLandlordRequestStorage>(
          create: (_) => LocalLandlordRequestStorage(),
        ),
        Provider<LocalAuthRepository>(create: (_) => LocalAuthRepository()),
        Provider<LocalNotificationStorage>(
          create: (_) => LocalNotificationStorage(),
        ),
        Provider<LocalAppointmentStorage>(
          create: (_) => LocalAppointmentStorage(),
        ),
        Provider<LocalSettingsStorage>(create: (_) => LocalSettingsStorage()),
        ChangeNotifierProvider<NotificationProvider>(
          create: (BuildContext ctx) => NotificationProvider(
            storage: ctx.read<LocalNotificationStorage>(),
            settingsStorage: ctx.read<LocalSettingsStorage>(),
          ),
        ),
        ChangeNotifierProvider<AppointmentProvider>(
          create: (BuildContext ctx) =>
              AppointmentProvider(storage: ctx.read<LocalAppointmentStorage>()),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (BuildContext ctx) => AuthProvider(
            authRepository: ctx.read<LocalAuthRepository>(),
            requestStorage: ctx.read<LocalLandlordRequestStorage>(),
            sessionService: ctx.read<LocalSessionService>(),
          )..restoreSession(),
        ),
        ChangeNotifierProvider<LandlordRequestProvider>(
          create: (BuildContext ctx) => LandlordRequestProvider(
            storage: ctx.read<LocalLandlordRequestStorage>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (BuildContext ctx) =>
              SettingsProvider(storage: ctx.read<LocalSettingsStorage>()),
          update:
              (
                BuildContext ctx,
                AuthProvider auth,
                SettingsProvider? settings,
              ) {
                final SettingsProvider provider =
                    settings ??
                    SettingsProvider(storage: ctx.read<LocalSettingsStorage>());
                if (auth.isAuthenticated && auth.currentUser != null) {
                  provider.loadPreferencesForUser(auth.currentUser!.id);
                } else {
                  provider.loadPreferencesForUser('');
                }
                return provider;
              },
        ),
        ChangeNotifierProxyProvider<AuthProvider, RoleProvider>(
          create: (_) => RoleProvider(),
          update: (_, AuthProvider auth, RoleProvider? roleProvider) {
            final RoleProvider provider = roleProvider ?? RoleProvider();
            if (auth.isAuthenticated) {
              provider.syncRoles(
                auth.roles,
                auth.currentUser?.currentActiveRole ?? UserRole.user,
              );
            } else {
              provider.reset();
            }
            return provider;
          },
        ),
        ChangeNotifierProvider<RoomProvider>(
          create: (BuildContext ctx) =>
              RoomProvider(ctx.read<RoomRepository>()),
        ),
        ChangeNotifierProxyProvider<RoomProvider, FavoriteProvider>(
          create: (_) => FavoriteProvider(),
          update: (BuildContext ctx, RoomProvider room, FavoriteProvider? fav) {
            final FavoriteProvider provider = fav ?? FavoriteProvider();
            provider.attach(room);
            return provider;
          },
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (BuildContext ctx) =>
              ChatProvider(ctx.read<ChatRepository>()),
        ),
        ChangeNotifierProvider<ConversationProvider>(
          create: (_) => ConversationProvider()..loadConversations(),
        ),
        ChangeNotifierProvider<MessageProvider>(
          create: (_) => MessageProvider()..loadMessages(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (BuildContext context, SettingsProvider settings, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Room Rental Finder',
            theme: settings.isDarkMode ? AppTheme.dark() : AppTheme.light(),
            home: const _AuthGate(),
          );
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider auth, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: auth.isAuthenticated
              ? const MainShellScreen()
              : const LoginScreen(),
        );
      },
    );
  }
}
