import 'package:flutter/foundation.dart';

import '../models/roleplay_models.dart';
import '../models/user_models.dart';

/// In-memory storage for roleplay overview context (deeplink·legacy overview screen).
class RoleplayStateService {
  RoleplayStateService._();

  static final RoleplayStateService instance = RoleplayStateService._();

  RoleplayOverviewDto? _overview;
  int? _roleplayId;
  UserDto? _user;
  final ValueNotifier<int> _overviewUpdateTick = ValueNotifier<int>(0);

  RoleplayOverviewDto? get overview => _overview;
  int? get roleplayId => _roleplayId;
  UserDto? get user => _user;
  ValueListenable<int> get overviewUpdateTick => _overviewUpdateTick;

  void setOverview({
    required int roleplayId,
    required RoleplayOverviewDto overview,
  }) {
    _roleplayId = roleplayId;
    _overview = overview;
    _overviewUpdateTick.value++;
  }

  void setUser(UserDto? user) {
    _user = user;
  }

  void clear() {
    _roleplayId = null;
    _overview = null;
    _user = null;
    _overviewUpdateTick.value++;
  }
}
