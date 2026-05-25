import 'app_enums.dart';

class UserEntity {
  final String id;
  final String username;
  final String email;
  final List<UserRole> roles;
  final String? avatarPath;
  final String? phoneNumber;
  final String? zaloNumber;
  final String? bio;
  final UserRole currentActiveRole;

  const UserEntity({
    required this.id,
    required this.username,
    required this.email,
    required this.roles,
    this.avatarPath,
    this.phoneNumber,
    this.zaloNumber,
    this.bio,
    this.currentActiveRole = UserRole.user,
  });

  bool hasRole(UserRole role) => roles.contains(role);

  UserEntity copyWith({
    String? id,
    String? username,
    String? email,
    List<UserRole>? roles,
    String? avatarPath,
    String? phoneNumber,
    String? zaloNumber,
    String? bio,
    UserRole? currentActiveRole,
  }) {
    return UserEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      avatarPath: avatarPath ?? this.avatarPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      zaloNumber: zaloNumber ?? this.zaloNumber,
      bio: bio ?? this.bio,
      currentActiveRole: currentActiveRole ?? this.currentActiveRole,
    );
  }
}
