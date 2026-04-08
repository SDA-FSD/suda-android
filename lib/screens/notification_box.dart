import 'package:flutter/material.dart';

import '../api/suda_api_client.dart';
import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import '../services/token_storage.dart';
import '../utils/suda_json_util.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gnb_bar.dart';

/// 줄바꿈으로 2줄 이상이면 첫 줄만 남기고 U+2026(…)을 붙인다.
/// 한 줄뿐이면 [text] 그대로(가로 초과는 [TextOverflow.ellipsis]).
String _singleLineForNotification(String text) {
  final lines = text.split(RegExp(r'\r?\n'));
  if (lines.length <= 1) return text;
  return '${lines.first}\u2026';
}

/// 서버 [sendFinishedAt]은 UTC+0 기준 시각. ISO에 `Z`/오프셋이 없으면 UTC로 간주해 `Z`를 붙여 파싱한다
/// (Dart는 타임존 없는 문자열을 로컬로 해석하므로).
/// 이후 디바이스 로컬 날짜로 달력 일 수 차이를 계산한다.
DateTime? _parseSendFinishedAtUtcToLocal(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  final hasZone = t.endsWith('Z') ||
      t.endsWith('z') ||
      RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t) ||
      RegExp(r'[+-]\d{4}$').hasMatch(t);
  final normalized = hasZone ? t : '${t}Z';
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null) return null;
  return parsed.toLocal();
}

/// [sendFinishedAt]을 로컬 날짜 기준으로 오늘과의 일 수 차이로 변환 (파싱 실패·빈 값은 null).
String? _formatSendFinishedRelative(
  AppLocalizations l10n,
  String? sendFinishedAt,
) {
  if (sendFinishedAt == null || sendFinishedAt.isEmpty) return null;
  final sentLocal = _parseSendFinishedAtUtcToLocal(sendFinishedAt);
  if (sentLocal == null) return null;
  final now = DateTime.now();
  final sentDay = DateTime(sentLocal.year, sentLocal.month, sentLocal.day);
  final todayDay = DateTime(now.year, now.month, now.day);
  var days = todayDay.difference(sentDay).inDays;
  if (days < 0) days = 0;
  if (days == 0) return l10n.notificationSendToday;
  if (days == 1) return l10n.notificationSendOneDayAgo;
  return l10n.notificationSendDaysAgo(days);
}

/// Notification Box Screen (기존 AlarmMessageScreen)
class NotificationBoxScreen extends StatefulWidget {
  const NotificationBoxScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToProfile,
    this.onNavigateToAlarm,
    this.isActive = false,
    this.user,
    this.showNotiboxUnreadBadge = false,
    this.onFirstPageUnreadDetected,
  });

  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToProfile;
  final VoidCallback? onNavigateToAlarm;
  final bool isActive;
  final UserDto? user;
  final bool showNotiboxUnreadBadge;
  /// 첫 페이지(0) 조회 직후·펼침 읽음 처리 직후 등, 목록 기준 미읽음 존재 여부.
  final ValueChanged<bool>? onFirstPageUnreadDetected;

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
  /// 다음 스크롤 시 요청할 pageNum(0부터). 첫 요청 성공 후 1, 2, …
  int _nextPageNum = 0;
  /// 펼침 상태인 알림 id (접힘이 기본)
  final Set<int> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _nextPageNum = 0;
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
      _fetchPage(_nextPageNum);
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _notifications.clear();
      _expandedIds.clear();
      _isLastPage = false;
      _nextPageNum = 0;
    });
    await _fetchPage(0);
  }

  Future<void> _fetchPage(int pageNum) async {
    if (pageNum == 0) {
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
        pageNum: pageNum,
      );

      if (!mounted) return;

      setState(() {
        if (pageNum == 0) {
          _notifications
            ..clear()
            ..addAll(list);
          _expandedIds.clear();
        } else {
          _notifications.addAll(list);
        }

        _nextPageNum = pageNum + 1;
        _isLastPage = list.isEmpty;
        _isLoading = false;
        _isLoadingMore = false;
      });
      if (pageNum == 0) {
        final hasUnread = list.any((n) => n.readYn != 'Y');
        widget.onFirstPageUnreadDetected?.call(hasUnread);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markReadOnServer(int notificationId) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (accessToken == null) return;
    try {
      await SudaApiClient.markNotificationRead(
        accessToken: accessToken,
        notificationId: notificationId,
      );
      if (!mounted) return;
      final hasUnread = _notifications.any((n) => n.readYn != 'Y');
      widget.onFirstPageUnreadDetected?.call(hasUnread);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final i = _notifications.indexWhere((e) => e.id == notificationId);
        if (i >= 0) {
          _notifications[i] = _notifications[i].copyWith(readYn: 'N');
        }
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
        showNotiboxUnreadBadge: widget.showNotiboxUnreadBadge,
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

    final bottomInset =
        MediaQuery.paddingOf(context).bottom + GnbBar.contentHeight;

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(bottom: bottomInset),
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
        return _buildNotificationCard(context, l10n, item);
      },
    );
  }

  static const Duration _expandAnimDuration = Duration(milliseconds: 300);
  static const Duration _textFadeDuration = Duration(milliseconds: 150);

  static const String _assetClickToExpand =
      'assets/images/icons/click_to_expand.png';
  static const String _assetClickToFold =
      'assets/images/icons/click_to_fold.png';

  /// 접기/펼치기 시각 힌트(카드 전체가 탭 영역 — 스크린리더 제외).
  Widget _expandCollapseIcon(bool expanded) {
    return ExcludeSemantics(
      child: Image.asset(
        expanded ? _assetClickToFold : _assetClickToExpand,
        width: 24,
        height: 24,
        filterQuality: FilterQuality.medium,
      ),
    );
  }

  Widget _fadeTextSwitch({
    required int itemId,
    required bool expanded,
    required String collapsedText,
    required String expandedText,
    required TextStyle? style,
    required String keyPrefix,
  }) {
    return AnimatedSwitcher(
      duration: _textFadeDuration,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      // 기본 layoutBuilder는 Stack center라 텍스트가 중앙으로 보일 수 있음 → 좌상단 정렬
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topLeft,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Align(
        key: ValueKey<String>('$itemId-$keyPrefix-$expanded'),
        alignment: Alignment.topLeft,
        widthFactor: 1.0,
        child: Text(
          expanded ? expandedText : collapsedText,
          textAlign: TextAlign.start,
          maxLines: expanded ? null : 1,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: style,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    AppLocalizations l10n,
    NotificationDto item,
  ) {
    final titleText = SudaJsonUtil.localizedText(item.title);
    final contentText = SudaJsonUtil.localizedText(item.content);
    final titleLine = _singleLineForNotification(titleText);
    final contentLine = _singleLineForNotification(contentText);
    final relativeSendLabel =
        _formatSendFinishedRelative(l10n, item.sendFinishedAt);
    final hasTextBlock = titleText.isNotEmpty || contentText.isNotEmpty;
    final isExpanded = _expandedIds.contains(item.id);

    final theme = Theme.of(context);
    final isUnread = item.readYn != 'Y';
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
    );
    final contentStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.white,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final wasExpanded = _expandedIds.contains(item.id);
          if (wasExpanded) {
            setState(() {
              _expandedIds.remove(item.id);
            });
            return;
          }
          final stillUnread = item.readYn != 'Y';
          setState(() {
            _expandedIds.add(item.id);
            if (stillUnread) {
              final i = _notifications.indexWhere((e) => e.id == item.id);
              if (i >= 0) {
                _notifications[i] = _notifications[i].copyWith(readYn: 'Y');
              }
            }
          });
          if (stillUnread) {
            _markReadOnServer(item.id);
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isUnread
                ? const Color(0xFF1A2423)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFF4A6B66)
                  : const Color(0xFF353535),
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: AnimatedSize(
            duration: _expandAnimDuration,
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titleText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUnread)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 10),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5252),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66FF5252),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Expanded(
                          child: _fadeTextSwitch(
                            itemId: item.id,
                            expanded: isExpanded,
                            collapsedText: titleLine,
                            expandedText: titleText,
                            style: titleStyle,
                            keyPrefix: 'title',
                          ),
                        ),
                        const SizedBox(width: 8),
                        _expandCollapseIcon(isExpanded),
                      ],
                    ),
                  ),
                if (titleText.isNotEmpty && contentText.isNotEmpty)
                  const SizedBox(height: 4),
                if (contentText.isNotEmpty)
                  titleText.isNotEmpty
                      ? _fadeTextSwitch(
                          itemId: item.id,
                          expanded: isExpanded,
                          collapsedText: contentLine,
                          expandedText: contentText,
                          style: contentStyle,
                          keyPrefix: 'body',
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isUnread)
                              Padding(
                                padding: const EdgeInsets.only(top: 5, right: 10),
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF5252),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x66FF5252),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Expanded(
                              child: _fadeTextSwitch(
                                itemId: item.id,
                                expanded: isExpanded,
                                collapsedText: contentLine,
                                expandedText: contentText,
                                style: contentStyle,
                                keyPrefix: 'body',
                              ),
                            ),
                            const SizedBox(width: 8),
                            _expandCollapseIcon(isExpanded),
                          ],
                        ),
                if (relativeSendLabel != null) ...[
                  if (hasTextBlock) const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      relativeSendLabel,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF635F5F),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

