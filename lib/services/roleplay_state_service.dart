import '../models/user_models.dart';

/// Tutorial·Result가 공유하는 사용자 스냅샷.
class RoleplayStateService {
  RoleplayStateService._();

  static final RoleplayStateService instance = RoleplayStateService._();

  UserDto? _user;

  UserDto? get user => _user;

  void setUser(UserDto? user) {
    _user = user;
  }
}
