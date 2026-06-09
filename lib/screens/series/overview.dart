import 'package:flutter/material.dart';

import '../../models/user_models.dart';
import '../../widgets/app_scaffold.dart';

/// Series Overview Screen (Sub Screen, S2)
///
/// 시리즈 상세·에피소드 목록 화면. 추후 API·UI 지침에 따라 구현 예정.
class SeriesOverviewScreen extends StatelessWidget {
  final int seriesId;
  final UserDto? user;

  const SeriesOverviewScreen({
    super.key,
    required this.seriesId,
    this.user,
  });

  static const String routeName = '/series/overview';

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      body: SizedBox.shrink(),
    );
  }
}
