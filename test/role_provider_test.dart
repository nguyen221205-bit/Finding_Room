import 'package:flutter_test/flutter_test.dart';
import 'package:room_finder_app/domain/entities/app_enums.dart';
import 'package:room_finder_app/presentation/providers/role_provider.dart';

void main() {
  group('RoleProvider', () {
    test('defaults to user mode', () {
      final RoleProvider provider = RoleProvider();

      expect(provider.currentMode, UserRole.user);
      expect(provider.availableRoles, const <UserRole>[UserRole.user]);
    });

    test('syncRoles updates available roles and keeps valid current role', () {
      final RoleProvider provider = RoleProvider();

      provider.syncRoles(const <UserRole>[UserRole.user, UserRole.landlord]);

      expect(provider.availableRoles, const <UserRole>[
        UserRole.user,
        UserRole.landlord,
      ]);
      expect(provider.currentMode, UserRole.user);
    });

    test('admin role can switch between user, landlord, and admin modes', () {
      final RoleProvider provider = RoleProvider()
        ..syncRoles(const <UserRole>[UserRole.user, UserRole.admin]);

      expect(provider.availableRoles, const <UserRole>[
        UserRole.user,
        UserRole.landlord,
        UserRole.admin,
      ]);

      provider.switchMode(UserRole.admin);
      expect(provider.currentMode, UserRole.admin);

      provider.switchMode(UserRole.landlord);
      expect(provider.currentMode, UserRole.landlord);

      provider.switchMode(UserRole.user);
      expect(provider.currentMode, UserRole.user);
    });

    test('syncRoles resets current mode when it becomes unavailable', () {
      final RoleProvider provider = RoleProvider()
        ..syncRoles(const <UserRole>[UserRole.user, UserRole.admin])
        ..switchMode(UserRole.admin);

      provider.syncRoles(const <UserRole>[UserRole.user]);

      expect(provider.currentMode, UserRole.user);
      expect(provider.availableRoles, const <UserRole>[UserRole.user]);
    });
  });
}
