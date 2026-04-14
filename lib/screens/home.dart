import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:marquee/marquee.dart';
import '../services/rest_status_service.dart';
import '../services/token_storage.dart';
import '../services/suda_api_client.dart';
import '../config/app_config.dart';
import '../routes/roleplay_router.dart';
import '../utils/language_util.dart';
import '../utils/suda_json_util.dart';
import '../widgets/daily_ticket_popup.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/gnb_bar.dart';
import '../services/effect_anchor_registry.dart';
class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAlarm;
  final VoidCallback? onNavigateToProfile;
  final UserDto? user;
  /// 홈 탭이 선택될 때마다 증가. didUpdateWidget에서 변경 시 티켓 갱신.
  final int? homeTabSelectedCounter;
  final ValueChanged<HomeDto>? onHomeContentsLoaded;
  final bool showNotiboxUnreadBadge;

  const HomeScreen({
    super.key,
    this.onNavigateToAlarm,
    this.onNavigateToProfile,
    this.user,
    this.homeTabSelectedCounter,
    this.onHomeContentsLoaded,
    this.showNotiboxUnreadBadge = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isInitialized = false; // 초기화 작업 한 번만 실행 플래그
  bool _dailyTicketPopupShown = false; // 세션 당 1회만 팝업 노출
  List<MainHomeBannerDto>? _banners;
  bool _isLoadingBanners = true;
  List<AppHomeRoleplayGroupDto>? _roleplayGroups;
  bool _isLoadingGroups = true;
  String? _accessToken;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _bannerTimer;
  bool _bannerTimerStarted = false; // 타이머 시작 여부 플래그
  int _visibleCategoryCount = 0; // 현재 렌더링 허용된 카테고리 개수
  int _displayTicketCount = 0;
  final GlobalKey _ticketBadgeKey = GlobalKey();

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.homeTabSelectedCounter != null &&
        widget.homeTabSelectedCounter != oldWidget.homeTabSelectedCounter) {
      _fetchTicket();
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    EffectAnchorRegistry.instance.registerKey(
      EffectAnchorId.ticketBadge,
      _ticketBadgeKey,
    );
    // 초기화 작업 (한 번만 실행)
    _performInitialization();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _pageController.dispose();
    EffectAnchorRegistry.instance.unregister(
      EffectAnchorId.ticketBadge,
      _ticketBadgeKey,
    );
    super.dispose();
  }

  /// 초기화 작업 수행 (확장 가능한 형태)
  Future<void> _performInitialization() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // 1. 토큰 로드
    _accessToken = await TokenStorage.loadAccessToken();

    // 2. 푸시 토큰 등록
    await _registerPushToken();

    // 3. 홈 콘텐츠 조회 (배너 + 롤플레이 통합 API)
    await _fetchHomeContents();
    // 4. 티켓 개수 조회
    await _fetchTicket();
  }

  Future<void> _fetchTicket() async {
    if (_accessToken == null) return;
    try {
      final dto = await SudaApiClient.getUserTicket(accessToken: _accessToken!);
      if (!mounted) return;
      setState(() => _displayTicketCount = dto.finalTicketCount);
      if (dto.dailyTicketGrantYn == 'Y') {
        await _showDailyTicketPopup();
      }
    } catch (_) {
      // 실패 시 표시값 유지
    }
  }

  Future<void> _showDailyTicketPopup() async {
    if (_dailyTicketPopupShown) return;
    _dailyTicketPopupShown = true;
    if (!mounted) return;
    final token = _accessToken;
    if (token == null) return;
    await showDailyTicketDefaultPopup(
      context,
      token,
      onClaimSuccess: () async {
        if (!mounted) return;
        await _fetchTicket();
      },
    );
  }

  /// 홈 콘텐츠 조회 (배너 + 롤플레이 통합 API)
  Future<void> _fetchHomeContents() async {
    if (_accessToken == null) {
      setState(() {
        _isLoadingBanners = false;
        _isLoadingGroups = false;
      });
      return;
    }

    try {
      final home = await SudaApiClient.getHomeContents(accessToken: _accessToken!);
      if (!mounted) return;

      RestStatusService.instance.update(
        restYn: home.restYn,
        restStartsAt: home.restStartsAt,
        restEndsAt: home.restEndsAt,
        notiboxUnreadYn: home.notiboxUnreadYn,
      );

      widget.onHomeContentsLoaded?.call(home);

      final banners = home.banners;
      final groups = home.roleplays;

      setState(() {
        _banners = banners;
        _roleplayGroups = groups;
        _isLoadingBanners = false;
        _isLoadingGroups = false;
        if (banners.isNotEmpty) {
          final int initialPage = banners.length * 500;
          _pageController = PageController(initialPage: initialPage);
          _currentPage = initialPage % banners.length;
        }
        if (groups.isNotEmpty) {
          _visibleCategoryCount = 1;
        }
      });

      if (banners.isNotEmpty) {
        _preloadAllBanners(banners);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBanners = false;
          _isLoadingGroups = false;
        });
      }
    }
  }

  /// 모든 배너 이미지를 미리 로드
  Future<void> _preloadAllBanners(List<MainHomeBannerDto> banners) async {
    if (!mounted) return;

    try {
      // 모든 배너 이미지에 대해 precacheImage 수행
      final List<Future<void>> futures = banners.map((banner) {
        return precacheImage(
          CachedNetworkImageProvider('${AppConfig.cdnBaseUrl}${banner.imgPath}'),
          context,
        );
      }).toList();

      // 모든 이미지가 로드될 때까지 대기
      await Future.wait(futures);

      // 로드 완료 후 자동 롤링 타이머 시작
      if (mounted) {
        _startBannerTimer();
      }
    } catch (e) {
      // 에러 발생 시에도 무한 대기를 방지하기 위해 일단 타이머 시작
      if (mounted) {
        _startBannerTimer();
      }
    }
  }

  /// 푸시 토큰 등록
  Future<void> _registerPushToken() async {
    if (_accessToken == null) return;
    try {
      // Firebase Messaging 토큰 획득
      final messaging = FirebaseMessaging.instance;
      final pushToken = await messaging.getToken();
      if (pushToken == null) return;
      final languageCode = LanguageUtil.getCurrentLanguageCode();

      // 서버에 푸시 토큰 전송 (응답 처리하지 않음)
      await SudaApiClient.registerPushToken(
        accessToken: _accessToken!,
        pushToken: pushToken,
        languageCode: languageCode,
      );
    } catch (_) {
      // 에러 발생 시에도 무시 (응답 처리하지 않음)
    }
  }

  /// 배너 자동 슬라이드 타이머 시작
  void _startBannerTimer() {
    if (_bannerTimerStarted) return; // 이미 시작되었다면 무시
    
    final bannerCount = _banners?.length ?? 0;
    if (bannerCount < 2) return; // 배너가 2개 미만이면 타이머 불필요

    _bannerTimerStarted = true;
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _navigateToRoleplayOverview(int roleplayId) {
    RoleplayRouter.pushOverview(context, roleplayId, user: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBackButton: false,
      title: 'Hi, ${widget.user?.name ?? 'User'}!',
      titleStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
      usePadding: false, // 배너 풀-폭 유지를 위해 본문 패딩 제거
      actions: [
        KeyedSubtree(
          key: _ticketBadgeKey,
          child: _buildTicketBadge(context),
        ),
      ],
      bottomNavigationBar: GnbBar(
        isAlarmActive: false,
        isHomeActive: true,
        isProfileActive: false,
        showNotiboxUnreadBadge: widget.showNotiboxUnreadBadge,
        onAlarmTap: widget.onNavigateToAlarm,
        onHomeTap: () {},
        onProfileTap: widget.onNavigateToProfile,
        user: widget.user,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildBannerSection(),
            const SizedBox(height: 10), // 배너 하단 gap 10 추가
            const SizedBox(height: 32), // 배너와 첫 카테고리 사이 간격 (표준화)
            _buildRoleplayGroupsSection(),
            const SizedBox(height: 40), // 하단 여백
          ],
        ),
      ),
    );
  }

  /// 배너 섹션 위젯
  Widget _buildBannerSection() {
    if (_isLoadingBanners) {
      return _buildBannerShimmer();
    }

    if (_banners == null || _banners!.isEmpty) {
      return const SizedBox.shrink();
    }

    final bannerCount = _banners!.length;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % bannerCount;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners![index % bannerCount];
              final imageUrl = '${AppConfig.cdnBaseUrl}${banner.imgPath}';
              
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) {
                        return Image(
                          image: imageProvider,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFF2A2A2A),
                        highlightColor: const Color(0xFF3F3F3F),
                        child: Container(
                          color: Colors.white,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[900],
                        width: double.infinity,
                        height: double.infinity,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    // 오버레이 텍스트
                    Positioned(
                      bottom: 50,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: Text(
                          _getOverlayText(banner),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            shadows: [
                              const Shadow(
                                blurRadius: 4.0,
                                color: Colors.black54,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 인디케이터 (배너가 2개 이상일 때)
          if (bannerCount > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(bannerCount, (index) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  /// 롤플레이 그룹 섹션
  Widget _buildRoleplayGroupsSection() {
    if (_isLoadingGroups) {
      return _buildGroupsShimmer();
    }

    if (_roleplayGroups == null || _roleplayGroups!.isEmpty) {
      return const SizedBox.shrink();
    }

    // 허용된 개수만큼만 리스트 생성
    final List<Widget> categories = [];
    for (int i = 0; i < _roleplayGroups!.length; i++) {
      if (i < _visibleCategoryCount) {
        categories.add(
          CategoryRoleplayRow(
            key: ValueKey('category_${_roleplayGroups![i].roleplayCategoryDto.id}'),
            group: _roleplayGroups![i],
            accessToken: _accessToken!,
            onRoleplayTap: (item) => _navigateToRoleplayOverview(item.id),
            onRendered: () {
              // 현재 카테고리가 렌더링되면 다음 카테고리 허용
              if (_visibleCategoryCount <= i + 1) {
                setState(() {
                  _visibleCategoryCount = i + 2;
                });
              }
            },
          ),
        );
      }
    }

    return Column(children: categories);
  }

  /// 배너 로딩 셔머 효과 (shimmer 패키지 사용)
  Widget _buildBannerShimmer() {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Shimmer.fromColors(
        baseColor: const Color(0xFF2A2A2A),
        highlightColor: const Color(0xFF3F3F3F),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// 그룹 전체 로딩 셔머 효과
  Widget _buildGroupsShimmer() {
    return Column(
      children: List.generate(2, (index) => _buildSingleGroupShimmer()),
    );
  }

  Widget _buildSingleGroupShimmer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbWidth = screenWidth * 0.3;
    // Shimmer는 대략적인 가이드라인이 필요하므로 1.5 비율 유지
    final shimmerHeight = thumbWidth * 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Shimmer.fromColors(
            baseColor: const Color(0xFF2A2A2A),
            highlightColor: const Color(0xFF3F3F3F),
            child: Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
        SizedBox(
          height: shimmerHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) => Shimmer.fromColors(
              baseColor: const Color(0xFF2A2A2A),
              highlightColor: const Color(0xFF3F3F3F),
              child: Container(
                width: thumbWidth,
                height: shimmerHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 언어 설정에 맞는 오버레이 텍스트 반환
  String _getOverlayText(MainHomeBannerDto banner) {
    return SudaJsonUtil.localizedText(banner.overlayText);
  }

  /// 상단 우측 티켓 아이콘 + 개수 (38x20, body-caption 흰색)
  Widget _buildTicketBadge(BuildContext context) {
    return SizedBox(
      width: 38,
      height: 20,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/icons/ticket.png',
            width: 38,
            height: 20,
            fit: BoxFit.cover,
          ),
          Center(
            child: Text(
              '$_displayTicketCount',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 개별 롤플레이 썸네일 위젯
class RoleplayThumbnail extends StatelessWidget {
  final AppHomeRoleplayDto item;
  final double width;
  final VoidCallback? onRendered;
  final VoidCallback? onTap;

  const RoleplayThumbnail({
    super.key,
    required this.item,
    required this.width,
    this.onRendered,
    this.onTap,
  });

  String _getTitle() {
    return SudaJsonUtil.localizedText(item.title);
  }

  bool _shouldMarquee({
    required String text,
    required TextStyle? style,
    required double maxWidth,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final title = _getTitle();
    final imageUrl = '${AppConfig.cdnBaseUrl}${item.thumbnailImgPath}';
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 12,
        );

    return Align(
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Stack(
            children: [
              // 1. 이미지 영역 (상하좌우 radius 10 보장)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  imageBuilder: (context, imageProvider) {
                    if (onRendered != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => onRendered!());
                    }
                    return Image(
                      image: imageProvider,
                      width: width,
                      fit: BoxFit.fitWidth, // 너비 고정, 높이는 원본 비율에 따라 자동 결정
                    );
                  },
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: const Color(0xFF2A2A2A),
                    highlightColor: const Color(0xFF3F3F3F),
                    child: Container(
                      width: width,
                      height: width * 1.5, // 로딩 중 최소 높이 가이드
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    if (onRendered != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => onRendered!());
                    }
                    return Container(
                      width: width,
                      height: width * 1.5,
                      color: Colors.grey[900],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              // 2. 오버레이 박스 (이미지 하단에 겹쳐서 노출)
              if (title.isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(5), // 텍스트 상하좌우 마진 5
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10), // 상하좌우 모두 radius 10
                    ),
                    alignment: Alignment.center,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final shouldMarquee = _shouldMarquee(
                          text: title,
                          style: textStyle,
                          maxWidth: constraints.maxWidth,
                          textDirection: Directionality.of(context),
                        );
                        return SizedBox(
                          height: 18,
                          child: shouldMarquee
                              ? Marquee(
                                  text: title,
                                  style: textStyle,
                                  scrollAxis: Axis.horizontal,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  blankSpace: 20.0,
                                  velocity: 30.0,
                                  pauseAfterRound: const Duration(seconds: 2),
                                  startPadding: 0,
                                  accelerationDuration: const Duration(seconds: 1),
                                  accelerationCurve: Curves.linear,
                                  decelerationDuration: const Duration(milliseconds: 500),
                                  decelerationCurve: Curves.easeOut,
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.clip,
                                    softWrap: false,
                                    textAlign: TextAlign.left,
                                    style: textStyle,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카테고리별 롤플레이 가로 행 (페이징 관리)
class CategoryRoleplayRow extends StatefulWidget {
  final AppHomeRoleplayGroupDto group;
  final String accessToken;
  final VoidCallback? onRendered;
  final void Function(AppHomeRoleplayDto item) onRoleplayTap;

  const CategoryRoleplayRow({
    super.key,
    required this.group,
    required this.accessToken,
    required this.onRoleplayTap,
    this.onRendered,
  });

  @override
  State<CategoryRoleplayRow> createState() => _CategoryRoleplayRowState();
}

class _CategoryRoleplayRowState extends State<CategoryRoleplayRow> {
  late List<AppHomeRoleplayDto> _list;
  int _currentPage = 0;
  bool _isLastPage = false;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.group.list);
    // 첫 호출 데이터가 4개 미만이면 이미 마지막 페이지일 수 있음 (가정)
    if (_list.length < 4) _isLastPage = true; 
    _scrollController.addListener(_onScroll);

    // 데이터가 아예 없는 카테고리라면 즉시 완료 보고하여 다음 카테고리 진행
    if (_list.isEmpty && widget.onRendered != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onRendered!());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_isLastPage) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPnum = _currentPage + 1;
      final page = await SudaApiClient.getRoleplaysByCategory(
        accessToken: widget.accessToken,
        categoryId: widget.group.roleplayCategoryDto.id,
        pageNum: nextPnum,
      );
      if (mounted) {
        setState(() {
          _list.addAll(page.content);
          _currentPage = page.number;
          _isLastPage = page.last;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  String _getCategoryTitle() {
    return SudaJsonUtil.localizedText(widget.group.roleplayCategoryDto.name);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbWidth = screenWidth * 0.3;
    // 여유롭게 1.6배 비율 적용
    final rowHeight = thumbWidth * 1.6; 
    final categoryTitle = _getCategoryTitle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8), // 상단 패딩 제거 (SizedBox로 제어)
          child: Text(
            categoryTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
        ),
        SizedBox(
          height: rowHeight,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _list.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              if (index < _list.length) {
                return RoleplayThumbnail(
                  item: _list[index],
                  width: thumbWidth,
                  onTap: () => widget.onRoleplayTap(_list[index]),
                  onRendered: index == 0 ? widget.onRendered : null,
                );
              } else {
                return _buildMoreLoadingShimmer(thumbWidth, rowHeight);
              }
            },
          ),
        ),
        const SizedBox(height: 32), // 카테고리 사이 간격 (표준화)
      ],
    );
  }

  Widget _buildMoreLoadingShimmer(double width, double height) {
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
}
