import 'package:flutter/material.dart';

import '../../widgets/app_scaffold.dart';

/// History V2 Screen (Sub Screen)
///
/// Result V2에 대응하는 신규 히스토리 화면의 진입 껍데기만 먼저 준비한다.
/// 실제 UI/동작은 후속 지침에서 구현한다.
class HistoryScreenV2 extends StatelessWidget {
  static const String routeName = '/profile/history_v2';

  final int resultId;

  const HistoryScreenV2({
    super.key,
    required this.resultId,
  });

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      centerTitle: 'History',
      body: Center(
        child: Text(
          'History V2 is under construction.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
