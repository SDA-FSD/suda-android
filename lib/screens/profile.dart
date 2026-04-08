import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';
import '../services/suda_api_client.dart';
import '../utils/default_toast.dart';
import '../utils/sub_screen_route.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gnb_bar.dart';
import 'roleplay/history.dart';
import 'setting/setting.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToHome;
  final VoidCallback? onNavigateToAlarm;
  final VoidCallback? onSignOut;
  final UserDto? user;
  final ValueChanged<UserDto>? onUserUpdated;
  final bool isActive; // 화면 활성 상태 여부 추가
  /// Profile 탭이 활성인 상태에서 서브 스크린에서 pop으로 복귀할 때마다 증가
  final int? profileReturnCounter;
  final bool showNotiboxUnreadBadge;

  const ProfileScreen({
    super.key,
    this.onNavigateToHome,
    this.onNavigateToAlarm,
    this.onSignOut,
    this.user,
    this.onUserUpdated,
    this.isActive = false,
    this.profileReturnCounter,
    this.showNotiboxUnreadBadge = false,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserDto? _user;
  int? _currentLevel;
  double? _progressPercentage;
  bool _isRefreshing = false;

  // 롤플레이 히스토리 페이징
  final List<RpSimpleResultDto> _historyList = [];
  int _historyNextPageNum = 0;
  bool _isHistoryLastPage = false;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _scrollController.addListener(_onHistoryScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfile();
      _fetchHistoryPage(0);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onHistoryScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onHistoryScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200 &&
        !_isLoadingMoreHistory &&
        !_isHistoryLastPage &&
        _historyList.isNotEmpty) {
      _fetchHistoryPage(_historyNextPageNum);
    }
  }

  static const double _historyRefetchBottomThreshold = 200;

  /// 탭 재진입·복귀 시 히스토리를 0페이지부터 다시 받을지.
  /// 서버에 더 불러올 페이지가 남아 있거나(`!_isHistoryLastPage`), 스크롤이 목록 끝이 아니면
  /// 기존에 불러온 페이지·스크롤 위치를 유지한다.
  /// (마지막 페이지까지 로드한 뒤 하단 근처를 보고 있을 때만 새 항목 반영을 위해 전체 재조회)
  bool _shouldRefetchHistoryFromStart() {
    if (_historyList.isEmpty) return true;
    if (!_isHistoryLastPage) return false;
    if (!_scrollController.hasClients) return false;
    final pos = _scrollController.position;
    return pos.pixels >= pos.maxScrollExtent - _historyRefetchBottomThreshold;
  }

  Future<void> _fetchHistoryPage(int pageNum) async {
    if (pageNum == 0) {
      if (_isLoadingHistory) return;
      setState(() => _isLoadingHistory = true);
    } else {
      if (_isLoadingMoreHistory) return;
      setState(() => _isLoadingMoreHistory = true);
    }
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (mounted) setState(() => _isLoadingHistory = false);
        return;
      }
      final page = await SudaApiClient.getRoleplayResults(
        accessToken: token,
        pageNum: pageNum,
      );
      if (!mounted) return;
      final sameFirstAsCurrent = pageNum == 0 &&
          _historyList.isNotEmpty &&
          page.content.isNotEmpty &&
          _historyList.first.resultId == page.content.first.resultId;
      if (sameFirstAsCurrent) {
        setState(() => _isLoadingHistory = false);
        return;
      }
      setState(() {
        if (pageNum == 0) {
          _historyList.clear();
          _historyList.addAll(page.content);
        } else {
          _historyList.addAll(page.content);
        }
        _historyNextPageNum = page.number + 1;
        _isHistoryLastPage = page.last;
        _isLoadingHistory = false;
        _isLoadingMoreHistory = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
          _isLoadingMoreHistory = false;
        });
      }
    }
  }

  @override
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != null && widget.user != oldWidget.user) {
      setState(() => _user = widget.user);
    }
    // 활성 상태로 전환될 때마다 프로필 갱신. 히스토리는 끝까지 본 경우에만 0페이지 재조회.
    if (!oldWidget.isActive && widget.isActive) {
      _refreshProfile();
      if (_shouldRefetchHistoryFromStart()) {
        _fetchHistoryPage(0);
      }
    }
    // Profile 탭이 활성인 상태에서 서브 스크린 pop으로 복귀할 때도 동일
    if (widget.isActive &&
        widget.profileReturnCounter != null &&
        widget.profileReturnCounter != oldWidget.profileReturnCounter) {
      _refreshProfile();
      if (_shouldRefetchHistoryFromStart()) {
        _fetchHistoryPage(0);
      }
    }
  }

  Future<void> _refreshProfile() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;

      final profile = await SudaApiClient.getUserProfile(accessToken: token);
      if (!mounted) return;

      setState(() {
        _user = profile.userDto;
        _currentLevel = profile.currentLevel;
        _progressPercentage = profile.progressPercentage;
      });
      widget.onUserUpdated?.call(profile.userDto);
    } catch (e) {
      // 프로필 화면은 "자연스럽게 갱신"이 목표라, 실패 시에도 UI는 기존 메모리 값으로 유지
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _handleSignOut() async {
    try {
      final refreshToken = await TokenStorage.loadRefreshToken();
      if (refreshToken != null) {
        try {
          final deviceId = await TokenStorage.getDeviceId();
          await SudaApiClient.logout(
            refreshToken: refreshToken,
            deviceId: deviceId,
          );
        } catch (_) {
          // 서버 로그아웃 실패 시에도 로컬 토큰은 삭제
        }
      }
      await AuthService.signOut();
      await TokenStorage.clearTokens();
      if (mounted) {
        widget.onSignOut?.call();
      }
    } catch (error) {
      if (mounted) {
        DefaultToast.show(context, 'Logout failed: $error', isError: true);
      }
    }
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      SubScreenRoute(
        page: SettingScreen(
          onSignOut: _handleSignOut,
          user: _user ?? widget.user,
          onUserUpdated: widget.onUserUpdated,
          getCurrentUser: () => widget.user,
        ),
      ),
    );
  }

  /// 롤플레이 히스토리: 3열·썸네일 간격 10·행 간격 10·CDN·캐시·shimmer
  static const double _historyThumbGap = 10;
  static const double _historyRowGap = 10;
  static const double _historyHPadding = 24;

  Widget _buildHistorySection(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth - 2 * _historyHPadding - 2 * _historyThumbGap;
    final itemWidth = contentWidth / 3;
    final itemHeight = itemWidth * 1.5;

    Widget rowOfThree(List<Widget> children) {
      assert(children.length <= 3);
      final list = <Widget>[];
      for (var i = 0; i < 3; i++) {
        if (i > 0) list.add(const SizedBox(width: _historyThumbGap));
        list.add(i < children.length
            ? children[i]
            : SizedBox(width: itemWidth, height: itemHeight));
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: list,
      );
    }

    if (_isLoadingHistory && _historyList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: _historyHPadding),
        child: Column(
          children: [
            rowOfThree(
              List.generate(3, (_) => _historyShimmer(itemWidth, itemHeight)),
            ),
            const SizedBox(height: _historyRowGap),
            rowOfThree(
              List.generate(3, (_) => _historyShimmer(itemWidth, itemHeight)),
            ),
          ],
        ),
      );
    }

    if (!_isLoadingHistory && _historyList.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              AppLocalizations.of(context)!.profileHistoryEmpty,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < _historyList.length; i += 3) {
      final rowItems = <Widget>[];
      for (var j = 0; j < 3; j++) {
        final index = i + j;
        if (index < _historyList.length) {
          final item = _historyList[index];
          final resultId = item.resultId;
          rowItems.add(_HistoryThumbnail(
            item: item,
            width: itemWidth,
            height: itemHeight,
            onTap: resultId != null
                ? () {
                    Navigator.push(
                      context,
                      SubScreenRoute(
                        page: HistoryScreen(resultId: resultId),
                      ),
                    );
                  }
                : null,
          ));
        }
      }
      rows.add(rowOfThree(rowItems));
      if (i + 3 < _historyList.length) {
        rows.add(const SizedBox(height: _historyRowGap));
      }
    }

    if (_isLoadingMoreHistory) {
      rows.add(const SizedBox(height: _historyRowGap));
      rows.add(rowOfThree(
        List.generate(3, (_) => _historyShimmer(itemWidth, itemHeight)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _historyHPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }

  Widget _historyShimmer(double width, double height) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3F3F3F),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final user = _user ?? widget.user;
    final name = user?.name ?? '';
    final profileImgUrl = user?.profileImgUrl;
    final roleplayCount = user?.roleplayCount ?? 0;
    final wordsSpokenCount = user?.wordsSpokenCount ?? 0;
    final likePoint = user?.likePoint ?? 0;

    return AppScaffold(
      showBackButton: false,
      actions: [
        GestureDetector(
          onTap: _openSettings,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SvgPicture.asset(
                'assets/images/icons/header_setting.svg',
                width: 24,
                height: 24,
              ),
            ),
          ),
        ),
      ],
      usePadding: false, // 풀-폭 그라데이션을 위해 본문 패딩 제거
      bottomNavigationBar: GnbBar(
        isAlarmActive: false,
        isHomeActive: false,
        isProfileActive: true,
        showNotiboxUnreadBadge: widget.showNotiboxUnreadBadge,
        onAlarmTap: widget.onNavigateToAlarm,
        onHomeTap: widget.onNavigateToHome,
        onProfileTap: () {},
        user: widget.user,
      ),
      body: Stack(
        children: [
          // 1) 프로필 박스 배경 그라데이션 (상단 80 지점부터 시작)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 120,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black,
                      Color(0xFF43716D),
                      Colors.black,
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 2) 실제 콘텐츠
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                const SizedBox(height: 0), // AppScaffold의 top 80 패딩 이후 바로 시작

                // profile box
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        _ProfileAvatar(profileImgUrl: profileImgUrl),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Role Play',
                                        value: roleplayCount.toString(),
                                      ),
                                    ),
                                    const _ProfileStatDivider(),
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Words',
                                        value: wordsSpokenCount.toString(),
                                      ),
                                    ),
                                    const _ProfileStatDivider(),
                                    Expanded(
                                      child: _ProfileStat(
                                        title: 'Like',
                                        value: likePoint.toString(),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // progress box
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Lv. ${_currentLevel ?? 0}',
                        style: theme.labelSmall?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProgressBar(
                          progressPercentage: _progressPercentage ?? 0.0,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // History 라벨 (body-default 흰색·왼쪽 정렬·상단 gap 14·하단 gap 20)
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      AppLocalizations.of(context)!.profileHistory,
                      style: theme.bodyLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 롤플레이 히스토리 (3열·썸네일 간격 10·행 간격 10)
                _buildHistorySection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _ProfileAvatar extends StatelessWidget {
// ... (이후 클래스들 유지)
  final String? profileImgUrl;

  const _ProfileAvatar({required this.profileImgUrl});

  static const String _defaultProfileImage =
      'assets/images/icons/default_profile_image.png';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.all(4), // border thickness = 4
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF80D7CF),
                Color(0xFF43716D),
              ],
            ),
          ),
          child: ClipOval(
            child: (profileImgUrl != null && profileImgUrl!.isNotEmpty)
                ? Image.network(
                    profileImgUrl!,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        _defaultProfileImage,
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    _defaultProfileImage,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.bodySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.bodyMedium?.copyWith(color: const Color(0xFF80D7CF)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStatDivider extends StatelessWidget {
  const _ProfileStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 44,
      color: const Color(0xFF1E1E1E),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progressPercentage;

  const _ProgressBar({required this.progressPercentage});

  @override
  Widget build(BuildContext context) {
    final p = (progressPercentage.clamp(0, 100)) / 100.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: Stack(
          children: [
            // base
            const Positioned.fill(
              child: ColoredBox(color: Color(0xFF635F5F)),
            ),
            // progress
            FractionallySizedBox(
              widthFactor: p,
              heightFactor: 1,
              alignment: Alignment.centerLeft,
              child: const ColoredBox(color: Color(0xFF80D7CF)),
            ),
          ],
        ),
      ),
    );
  }
}

/// 프로필 히스토리 썸네일 (CDN·캐시·shimmer·상단 별·하단 날짜). 탭 시 History 스크린 진입.
class _HistoryThumbnail extends StatelessWidget {
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';

  final RpSimpleResultDto item;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _HistoryThumbnail({
    required this.item,
    required this.width,
    required this.height,
    this.onTap,
  });

  /// createdAt (ISO-8601) → dd/mm
  static String _formatDate(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return '';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final imageUrl = item.imgPath != null && item.imgPath!.isNotEmpty
        ? '${AppConfig.cdnBaseUrl}${item.imgPath}'
        : null;
    final starResult = item.starResult ?? 0;
    final goldCount = starResult.clamp(0, 3);
    final starSize = (width * 0.4) / 3;
    final dateText = _formatDate(item.createdAt);

    final imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: const Color(0xFF2A2A2A),
                highlightColor: const Color(0xFF3F3F3F),
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.white,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: width,
                height: height,
                color: Colors.grey[900],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            )
          : Container(
              width: width,
              height: height,
              color: Colors.grey[900],
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
    );

    final content = SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // 상단 20% 그라데이션 (검정 → 투명): 별 아이콘 가독용
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height * 0.2,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [Colors.black, Color(0x00000000)],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),
          // 상단 별 3개: gap 2, width 40% 오른쪽 정렬, starResult만큼 gold
          Positioned(
            top: 2,
            right: 0,
            child: SizedBox(
              width: width * 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(3, (i) {
                  final isGold = i < goldCount;
                  return Image.asset(
                    isGold ? _starGold : _starSilver,
                    width: starSize,
                    height: starSize,
                    fit: BoxFit.contain,
                  );
                }),
              ),
            ),
          ),
          // 하단 날짜: 텍스트 길이만큼만 차지, 오른쪽 하단에 검정 60%
          if (dateText.isNotEmpty)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Text(
                  dateText,
                  style: theme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }
    return content;
  }
}
