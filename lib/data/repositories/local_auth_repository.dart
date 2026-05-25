import 'package:hive/hive.dart';

import '../../core/constants/storage_keys.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/user_entity.dart';
import '../models/local_user_model.dart';

class LocalAuthRepository {
  Box<dynamic> get _usersBox => Hive.box<dynamic>(HiveBoxes.users);

  Future<void> ensureDefaultUsers() async {
    await _seedUser(
      const LocalUserModel(
        id: 'u_admin_1',
        username: 'admin',
        email: 'admin@roomfinder.app',
        password: 'admin123',
        roles: <UserRole>[UserRole.user, UserRole.landlord, UserRole.admin],
        currentActiveRole: UserRole.admin,
      ),
    );
    await _seedUser(
      const LocalUserModel(
        id: 'u_landlord_2',
        username: 'landlord',
        email: 'landlord@roomfinder.app',
        password: '123456',
        roles: <UserRole>[UserRole.user, UserRole.landlord],
        currentActiveRole: UserRole.landlord,
      ),
    );
    await _seedUser(
      const LocalUserModel(
        id: 'u_user_1',
        username: 'user1',
        email: 'user1@roomfinder.app',
        password: '123456',
        roles: <UserRole>[UserRole.user],
        currentActiveRole: UserRole.user,
      ),
    );
    await _seedUser(
      const LocalUserModel(
        id: 'u_user_3',
        username: 'user3',
        email: 'user3@roomfinder.app',
        password: '123456',
        roles: <UserRole>[UserRole.user],
        currentActiveRole: UserRole.user,
      ),
    );
  }

  Future<bool> emailExists(String email) async {
    await ensureDefaultUsers();
    return _findByEmail(email) != null;
  }

  Future<UserEntity?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    await ensureDefaultUsers();

    final String normalizedEmail = email.trim().toLowerCase();
    if (_findByEmail(normalizedEmail) != null) {
      return null;
    }

    final String id = _createUserId(normalizedEmail);
    final LocalUserModel user = LocalUserModel(
      id: id,
      username: username.trim().isEmpty ? 'User' : username.trim(),
      email: normalizedEmail,
      password: password,
      roles: const <UserRole>[UserRole.user],
      currentActiveRole: UserRole.user,
    );

    await _usersBox.put(user.id, user.toMap());
    return user.toEntity();
  }

  Future<UserEntity?> login({
    required String email,
    required String password,
  }) async {
    await ensureDefaultUsers();

    final LocalUserModel? user = _findByEmail(email.trim().toLowerCase());
    if (user == null || user.password != password) {
      return null;
    }

    return user.toEntity();
  }

  Future<UserEntity?> getUserById(String userId) async {
    await ensureDefaultUsers();

    final dynamic value = _usersBox.get(userId);
    if (value is Map<dynamic, dynamic>) {
      return LocalUserModel.fromMap(value).toEntity();
    }

    return null;
  }

  Future<void> updateRoles({
    required String userId,
    required List<UserRole> roles,
  }) async {
    final dynamic value = _usersBox.get(userId);
    if (value is! Map<dynamic, dynamic>) return;

    final LocalUserModel user = LocalUserModel.fromMap(value);
    await _usersBox.put(
      userId,
      LocalUserModel(
        id: user.id,
        username: user.username,
        email: user.email,
        password: user.password,
        roles: roles,
        avatarPath: user.avatarPath,
        phoneNumber: user.phoneNumber,
        zaloNumber: user.zaloNumber,
        bio: user.bio,
        currentActiveRole: user.currentActiveRole,
      ).toMap(),
    );
  }

  Future<UserEntity?> updateUserProfile({
    required String userId,
    required String username,
    String? avatarPath,
    String? phoneNumber,
    String? zaloNumber,
    String? bio,
  }) async {
    final dynamic value = _usersBox.get(userId);
    if (value is! Map<dynamic, dynamic>) return null;

    final LocalUserModel user = LocalUserModel.fromMap(value);
    final LocalUserModel updatedUser = LocalUserModel(
      id: user.id,
      username: username,
      email: user.email,
      password: user.password,
      roles: user.roles,
      avatarPath: avatarPath ?? user.avatarPath,
      phoneNumber: phoneNumber ?? user.phoneNumber,
      zaloNumber: zaloNumber ?? user.zaloNumber,
      bio: bio ?? user.bio,
      currentActiveRole: user.currentActiveRole,
    );

    await _usersBox.put(userId, updatedUser.toMap());
    return updatedUser.toEntity();
  }

  Future<void> updateActiveRole({
    required String userId,
    required UserRole role,
  }) async {
    final dynamic value = _usersBox.get(userId);
    if (value is! Map<dynamic, dynamic>) return;

    final LocalUserModel user = LocalUserModel.fromMap(value);
    await _usersBox.put(
      userId,
      LocalUserModel(
        id: user.id,
        username: user.username,
        email: user.email,
        password: user.password,
        roles: user.roles,
        avatarPath: user.avatarPath,
        phoneNumber: user.phoneNumber,
        zaloNumber: user.zaloNumber,
        bio: user.bio,
        currentActiveRole: role,
      ).toMap(),
    );
  }

  LocalUserModel? _findByEmail(String email) {
    final String normalizedEmail = email.trim().toLowerCase();

    for (final dynamic value in _usersBox.values) {
      if (value is! Map<dynamic, dynamic>) continue;

      final LocalUserModel user = LocalUserModel.fromMap(value);
      if (user.email.toLowerCase() == normalizedEmail) {
        return user;
      }
    }

    return null;
  }

  Future<void> _seedUser(LocalUserModel user) async {
    if (_findByEmail(user.email) != null) return;
    await _usersBox.put(user.id, user.toMap());
  }

  String _createUserId(String email) {
    final String prefix = email
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
        .toLowerCase();
    return 'u_${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }
}
