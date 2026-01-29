import 'suda_api_client.dart';

/// In-memory storage for the current roleplay overview context.
/// Only one roleplay overview can exist at a time.
class RoleplayStateService {
  RoleplayStateService._();

  static final RoleplayStateService instance = RoleplayStateService._();

  RoleplayOverviewDto? _overview;
  int? _roleplayId;
  int? _roleId;
  String? _sessionId;
  String? _isUserTurnYn;
  UserDto? _user;

  RoleplayOverviewDto? get overview => _overview;
  int? get roleplayId => _roleplayId;
  int? get roleId => _roleId;
  String? get sessionId => _sessionId;
  String? get isUserTurnYn => _isUserTurnYn;
  UserDto? get user => _user;

  void setOverview({
    required int roleplayId,
    required RoleplayOverviewDto overview,
  }) {
    _roleplayId = roleplayId;
    _overview = overview;
  }

  void setSelectedRole(int roleId) {
    _roleId = roleId;
  }

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  void setIsUserTurnYn(String isUserTurnYn) {
    _isUserTurnYn = isUserTurnYn;
  }

  void setUser(UserDto? user) {
    _user = user;
  }

  void clear() {
    _roleplayId = null;
    _overview = null;
    _roleId = null;
    _sessionId = null;
    _isUserTurnYn = null;
    _user = null;
  }
}
