import 'package:flutter/material.dart';

import '../../api/suda_api_client.dart';
import '../../services/series_state_service.dart';
import '../../services/token_storage.dart';
import '../../widgets/app_scaffold.dart';
import 'result.dart';

/// History Screen (Sub Screen)
///
/// Profile에서 진입. `GET /rps2/user-histories/{rpUserHistoryId}`로 Result와 동일
/// 데이터를 조회한 뒤, 초기 애니메이션 없이 Result 본문을 노출한다.
class HistoryScreen extends StatefulWidget {
  static const String routeName = '/profile/history';

  final int rpUserHistoryId;

  const HistoryScreen({
    super.key,
    required this.rpUserHistoryId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    SeriesStateService.instance.setCachedUserHistory(null);
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Not signed in';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final history = await SudaApiClient.getRpS2UserHistory(
        accessToken: token,
        rpUserHistoryId: widget.rpUserHistoryId,
      );
      SeriesStateService.instance.setCachedUserHistory(history);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0CABA8)),
        ),
      );
    }

    if (_error != null || !_ready) {
      return AppScaffold(
        showBackButton: true,
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _error ?? 'Failed to load history',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return const RoleplayResultScreen(
      skipEntranceAnimation: true,
      exitViaPop: true,
      showCloseButton: false,
      showReportLink: false,
    );
  }
}
