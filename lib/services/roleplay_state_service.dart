import 'suda_api_client.dart';

/// In-memory storage for the current roleplay overview context.
/// Only one roleplay overview can exist at a time.
class RoleplayStateService {
  RoleplayStateService._();

  static final RoleplayStateService instance = RoleplayStateService._();

  RoleplayOverviewDto? _overview;
  int? _roleplayId;
  int? _roleId;

  RoleplayOverviewDto? get overview => _overview;
  int? get roleplayId => _roleplayId;
  int? get roleId => _roleId;

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

  void clear() {
    _roleplayId = null;
    _overview = null;
    _roleId = null;
  }
}
