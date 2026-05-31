import '../../domain/entities/app_enums.dart';
import '../../domain/entities/user_entity.dart';

class LocalUserModel {
  final String id;
  final String userCode;
  final String username;
  final String email;
  final String password;
  final List<UserRole> roles;
  final String? avatarPath;
  final String? phoneNumber;
  final String? zaloNumber;
  final String? bio;
  final UserRole currentActiveRole;

  const LocalUserModel({
    required this.id,
    this.userCode = '',
    required this.username,
    required this.email,
    required this.password,
    required this.roles,
    this.avatarPath,
    this.phoneNumber,
    this.zaloNumber,
    this.bio,
    this.currentActiveRole = UserRole.user,
  });

  UserEntity toEntity() {
    return UserEntity(
      id: id,
      userCode: userCode,
      username: username,
      email: email,
      roles: roles,
      avatarPath: avatarPath,
      phoneNumber: phoneNumber,
      zaloNumber: zaloNumber,
      bio: bio,
      currentActiveRole: currentActiveRole,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'userCode': userCode,
      'username': username,
      'email': email,
      'password': password,
      'roles': roles.map((UserRole role) => role.name).toList(),
      'avatarPath': avatarPath,
      'phoneNumber': phoneNumber,
      'zaloNumber': zaloNumber,
      'bio': bio,
      'currentActiveRole': currentActiveRole.name,
    };
  }

  static LocalUserModel fromMap(Map<dynamic, dynamic> map) {
    final List<dynamic> roleNames =
        (map['roles'] as List<dynamic>?) ?? <dynamic>[UserRole.user.name];

    return LocalUserModel(
      id: map['id'] as String? ?? '',
      userCode: map['userCode'] as String? ?? '',
      username: map['username'] as String? ?? 'User',
      email: map['email'] as String? ?? '',
      password: map['password'] as String? ?? '',
      roles: roleNames
          .map((dynamic role) => _roleFromName(role.toString()))
          .toList(),
      avatarPath: map['avatarPath'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      zaloNumber: map['zaloNumber'] as String?,
      bio: map['bio'] as String?,
      currentActiveRole: _roleFromName(
        map['currentActiveRole'] as String? ?? 'user',
      ),
    );
  }

  static LocalUserModel fromEntity({
    required UserEntity user,
    required String password,
  }) {
    return LocalUserModel(
      id: user.id,
      userCode: user.userCode,
      username: user.username,
      email: user.email,
      password: password,
      roles: user.roles,
      avatarPath: user.avatarPath,
      phoneNumber: user.phoneNumber,
      zaloNumber: user.zaloNumber,
      bio: user.bio,
      currentActiveRole: user.currentActiveRole,
    );
  }

  static UserRole _roleFromName(String name) {
    return UserRole.values.firstWhere(
      (UserRole role) => role.name == name,
      orElse: () => UserRole.user,
    );
  }
}
