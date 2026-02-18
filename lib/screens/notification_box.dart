import 'package:flutter/material.dart';

import '../api/suda_api_client.dart';
import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import '../services/token_storage.dart';
import '../utils/suda_json_util.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gnb_bar.dart';

/// Notification Box Screen (기존 AlarmMessageScreen)
class NotificationBoxScreen extends StatefulWidget {
  const NotificationBoxScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToProfile,
    this.onNavigateToAlarm,
    this.isActive = false,
    this.user,
  });

  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToAlarm;
  final bool isActive;
  final UserDto? user;

  static const String routeName = '/notification_box';

  @override
  State<NotificationBoxScreen> createState() => _NotificationBoxScreenState();
}

class _NotificationBoxScreenState extends State<NotificationBoxScreen> {
  final List<NotificationDto> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchPage(0);
  }

  @override
  void didUpdateWidget(NotificationBoxScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 알림 탭이 다시 활성화될 때 첫 페이지를 새로 조회
    if (!oldWidget.isActive && widget.isActive) {
      _refresh();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLastPage &&
        _notifications.isNotEmpty) {
      _fetchPage(_currentPage + 1);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notifications.clear();
      _isLastPage = false;
      _currentPage = 0;
    });
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int page) async {
    if (page == 0) {
      if (_isLoading) return;
      setState(() {
        _isLoading = true;
      });
    } else {
      if (_isLoadingMore || _isLastPage) return;
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isLoadingMore = false;
            _isLastPage = true;
          });
        }
        return;
      }

      final list = await SudaApiClient.getNotifications(
        accessToken: accessToken,
        page: page,
      );

      if (!mounted) return;

      setState(() {
        if (page == 0) {
          _notifications
            ..clear()
            ..addAll(list);
        } else {
          _notifications.addAll(list);
        }

        _currentPage = page;
        _isLastPage = list.isEmpty;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      showBackButton: false,
      centerTitle: l10n.notificationsTitle,
      bottomNavigationBar: GnbBar(
        isAlarmActive: true,
        isHomeActive: false,
        isProfileActive: false,
        onAlarmTap: widget.onNavigateToAlarm,
        onHomeTap: widget.onNavigateToHome,
        onProfileTap: widget.onNavigateToProfile,
        user: widget.user,
      ),
      body: _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_isLoading && _notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          l10n.notificationsEmpty,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _notifications.length) {
          // 하단 로딩 인디케이터
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          );
        }

        final item = _notifications[index];
        final titleText = SudaJsonUtil.localizedText(item.title);
        final contentText = SudaJsonUtil.localizedText(item.content);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titleText.isNotEmpty)
                  Text(
                    titleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                if (titleText.isNotEmpty && contentText.isNotEmpty)
                  const SizedBox(height: 4),
                if (contentText.isNotEmpty)
                  Text(
                    contentText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

