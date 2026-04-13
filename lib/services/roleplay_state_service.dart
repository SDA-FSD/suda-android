import 'package:flutter/foundation.dart';

import '../models/roleplay_models.dart';
import '../models/user_models.dart';

/// In-memory storage for the current roleplay overview context.
/// Only one roleplay overview can exist at a time.
class RoleplayStateService {
  RoleplayStateService._();

  static final RoleplayStateService instance = RoleplayStateService._();

  RoleplayOverviewDto? _overview;
  int? _roleplayId;
  int? _roleId;
  String? _sessionId;
  RoleplaySessionDto? _session;
  String? _isUserTurnYn;
  UserDto? _user;
  RoleplayResultDto? _cachedResult;
  final ValueNotifier<int> _overviewUpdateTick = ValueNotifier<int>(0);

  RoleplayOverviewDto? get overview => _overview;
  int? get roleplayId => _roleplayId;
  int? get roleId => _roleId;
  String? get sessionId => _sessionId;
  RoleplaySessionDto? get session => _session;
  String? get isUserTurnYn => _isUserTurnYn;
  UserDto? get user => _user;
  RoleplayResultDto? get cachedResult => _cachedResult;
  ValueListenable<int> get overviewUpdateTick => _overviewUpdateTick;

  void setOverview({
    required int roleplayId,
    required RoleplayOverviewDto overview,
  }) {
    _roleplayId = roleplayId;
    _overview = overview;
    _overviewUpdateTick.value++;
  }

  void setSelectedRole(int roleId) {
    _roleId = roleId;
  }

  void setSessionId(String sessionId) {
    _sessionId = sessionId;
  }

  void setSession(RoleplaySessionDto session) {
    _session = session;
  }

  void setIsUserTurnYn(String isUserTurnYn) {
    _isUserTurnYn = isUserTurnYn;
  }

  void setUser(UserDto? user) {
    _user = user;
  }

  void setCachedResult(RoleplayResultDto? result) {
    _cachedResult = result;
  }

  void clear() {
    _roleplayId = null;
    _overview = null;
    _roleId = null;
    _sessionId = null;
    _session = null;
    _isUserTurnYn = null;
    _user = null;
    _cachedResult = null;
    _overviewUpdateTick.value++;
  }
}
