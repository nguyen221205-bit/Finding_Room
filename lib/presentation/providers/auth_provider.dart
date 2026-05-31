import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/local_auth_repository.dart';
import '../../data/repositories/local_landlord_request_storage.dart';
import '../../core/utils/local_session_service.dart';
import '../../domain/entities/app_enums.dart';
import '../../domain/entities/landlord_request_entity.dart';
import '../../domain/entities/user_entity.dart';

class AuthProvider extends ChangeNotifier {
  final LocalAuthRepository _authRepository;
  final LocalLandlordRequestStorage _requestStorage;
  final LocalSessionService _sessionService;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserEntity? _currentUser;

  AuthProvider({
    LocalAuthRepository? authRepository,
    LocalLandlordRequestStorage? requestStorage,
    LocalSessionService? sessionService,
  }) : _authRepository = authRepository ?? LocalAuthRepository(),
       _requestStorage = requestStorage ?? LocalLandlordRequestStorage(),
       _sessionService = sessionService ?? LocalSessionService();

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserEntity? get currentUser => _currentUser;
  String get userId => _currentUser?.id ?? '';
  String get username => _currentUser?.username ?? 'Guest';
  String get email => _currentUser?.email ?? '';
  List<UserRole> get roles =>
      _normalizeRoles(_currentUser?.roles ?? const <UserRole>[]);

  bool hasRole(UserRole role) => roles.contains(role);

  Future<UserEntity?> getUserById(String userId) async {
    return _authRepository.getUserById(userId);
  }

  Future<bool> isPhoneNumberUnique(
    String phoneNumber,
    String currentUserId,
  ) async {
    return _authRepository.isPhoneNumberUnique(phoneNumber, currentUserId);
  }

  Future<void> restoreSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final String? savedUserId = await _sessionService.loadCurrentUserId();
      if (savedUserId == null || savedUserId.isEmpty) {
        return;
      }

      final UserEntity? savedUser = await _authRepository.getUserById(
        savedUserId,
      );
      if (savedUser == null) {
        await _sessionService.clearSession();
        return;
      }

      _currentUser = await _applyApprovedLandlordRole(savedUser);
      _isAuthenticated = true;
      await _persistCurrentRolesIfNeeded(savedUser);
    } catch (_) {
      _currentUser = null;
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final UserEntity? user = await _authRepository.login(
        email: email,
        password: password,
      );
      if (user == null) {
        return false;
      }

      _currentUser = await _applyApprovedLandlordRole(user);
      _isAuthenticated = true;
      await _sessionService.saveCurrentUserId(_currentUser!.id);
      await _persistCurrentRolesIfNeeded(user);
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final UserEntity? user = await _authRepository.register(
        username: username,
        email: email,
        password: password,
      );
      return user != null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addRole(UserRole role) {
    final UserEntity? user = _currentUser;
    if (user == null || user.roles.contains(role)) return;

    _currentUser = user.copyWith(roles: <UserRole>[...user.roles, role]);
    unawaited(
      _authRepository.updateRoles(userId: _currentUser!.id, roles: roles),
    );
    notifyListeners();
  }

  Future<void> updateActiveRole(UserRole role) async {
    final UserEntity? user = _currentUser;
    if (user == null || user.currentActiveRole == role) return;

    _currentUser = user.copyWith(currentActiveRole: role);
    await _authRepository.updateActiveRole(
      userId: _currentUser!.id,
      role: role,
    );
    notifyListeners();
  }

  Future<void> updateProfile({
    required String username,
    String? avatarPath,
    String? phoneNumber,
    String? zaloNumber,
    String? bio,
  }) async {
    final UserEntity? user = _currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final UserEntity? updatedUser = await _authRepository.updateUserProfile(
        userId: user.id,
        username: username,
        avatarPath: avatarPath,
        phoneNumber: phoneNumber,
        zaloNumber: zaloNumber,
        bio: bio,
      );
      if (updatedUser != null) {
        _currentUser = updatedUser;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _currentUser = null;
    await _sessionService.clearSession();
    notifyListeners();
  }

  Future<UserEntity> _applyApprovedLandlordRole(UserEntity user) async {
    final LandlordRequestEntity? request = await _requestStorage.getByUserId(
      user.id,
    );
    final bool isApproved = request?.status == LandlordRequestStatus.approved;

    if (!isApproved || user.roles.contains(UserRole.landlord)) {
      return user;
    }

    return user.copyWith(roles: <UserRole>[...user.roles, UserRole.landlord]);
  }

  List<UserRole> _normalizeRoles(List<UserRole> roles) {
    if (roles.contains(UserRole.admin)) {
      return const <UserRole>[UserRole.user, UserRole.landlord, UserRole.admin];
    }

    return roles;
  }

  Future<List<UserEntity>> getAllUsers() async {
    return _authRepository.getAllUsers();
  }

  Future<bool> revokeLandlordPrivileges(String landlordId) async {
    try {
      final UserEntity? targetUser = await _authRepository.getUserById(
        landlordId,
      );
      if (targetUser == null) return false;

      final List<UserRole> updatedRoles = targetUser.roles
          .where((UserRole r) => r != UserRole.landlord)
          .toList();

      await _authRepository.updateRoles(
        userId: landlordId,
        roles: updatedRoles,
      );

      if (targetUser.currentActiveRole == UserRole.landlord) {
        await _authRepository.updateActiveRole(
          userId: landlordId,
          role: UserRole.user,
        );
      }

      if (_currentUser != null && _currentUser!.id == landlordId) {
        _currentUser = _currentUser!.copyWith(
          roles: updatedRoles,
          currentActiveRole:
              _currentUser!.currentActiveRole == UserRole.landlord
              ? UserRole.user
              : _currentUser!.currentActiveRole,
        );
      }

      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistCurrentRolesIfNeeded(UserEntity originalUser) async {
    final UserEntity? user = _currentUser;
    if (user == null || listEquals(originalUser.roles, user.roles)) return;

    await _authRepository.updateRoles(userId: user.id, roles: user.roles);
  }
}
