import 'package:flutter/foundation.dart';

import '../../domain/entities/app_enums.dart';

class RoleProvider extends ChangeNotifier {
  ActiveUserMode _activeMode = ActiveUserMode.renter;
  bool _isAdmin = false;
  bool _isLandlordApproved = false;

  ActiveUserMode get activeMode => _activeMode;
  bool get isAdmin => _isAdmin;
  bool get isLandlordApproved => _isLandlordApproved;

  // Keep existing availableRoles for test and backward compatibility
  List<UserRole> _availableRoles = const <UserRole>[UserRole.user];
  List<UserRole> get availableRoles => List<UserRole>.unmodifiable(_availableRoles);

  // Keep original currentMode / currentRole properties so existing code compiles and passes
  UserRole get currentMode {
    if (_isAdmin && _activeMode == ActiveUserMode.renter && _availableRoles.contains(UserRole.admin) && _currentModeBacking == UserRole.admin) {
      return UserRole.admin;
    }
    return _activeMode == ActiveUserMode.landlord ? UserRole.landlord : UserRole.user;
  }
  
  UserRole get currentRole => currentMode;

  // Private backing field for the backward-compatible switchMode
  UserRole _currentModeBacking = UserRole.user;

  bool canSwitchTo(UserRole role) {
    if (role == UserRole.admin) return _isAdmin;
    if (role == UserRole.landlord) return _isLandlordApproved;
    return true;
  }

  void syncRoles(List<UserRole> roles, [UserRole activeRole = UserRole.user]) {
    final List<UserRole> nextRoles = _normalizeRoles(roles);
    _availableRoles = nextRoles;

    _isAdmin = roles.contains(UserRole.admin);
    _isLandlordApproved = roles.contains(UserRole.landlord) || _isAdmin;

    // Set active mode based on activeRole
    if (activeRole == UserRole.landlord && _isLandlordApproved) {
      _activeMode = ActiveUserMode.landlord;
      _currentModeBacking = UserRole.landlord;
    } else if (activeRole == UserRole.admin && _isAdmin) {
      _activeMode = ActiveUserMode.renter;
      _currentModeBacking = UserRole.admin;
    } else {
      _activeMode = ActiveUserMode.renter;
      _currentModeBacking = UserRole.user;
    }

    notifyListeners();
  }

  void switchMode(UserRole role) {
    if (!canSwitchTo(role)) return;
    
    _currentModeBacking = role;
    if (role == UserRole.landlord) {
      _activeMode = ActiveUserMode.landlord;
    } else {
      // Both UserRole.user and UserRole.admin map to renter viewing mode
      _activeMode = ActiveUserMode.renter;
    }
    notifyListeners();
  }

  void switchActiveMode(ActiveUserMode mode) {
    _activeMode = mode;
    if (mode == ActiveUserMode.landlord) {
      _currentModeBacking = UserRole.landlord;
    } else {
      _currentModeBacking = _isAdmin ? UserRole.admin : UserRole.user;
    }
    notifyListeners();
  }

  void switchRole(UserRole role) => switchMode(role);

  void reset() {
    _activeMode = ActiveUserMode.renter;
    _isAdmin = false;
    _isLandlordApproved = false;
    _availableRoles = const <UserRole>[UserRole.user];
    _currentModeBacking = UserRole.user;
    notifyListeners();
  }

  List<UserRole> _normalizeRoles(List<UserRole> roles) {
    if (roles.contains(UserRole.admin)) {
      return const <UserRole>[UserRole.user, UserRole.landlord, UserRole.admin];
    }

    if (roles.isEmpty) {
      return const <UserRole>[UserRole.user];
    }

    return roles;
  }
}
