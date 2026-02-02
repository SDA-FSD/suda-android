import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/app_config.dart';
import '../../models/user_models.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/app_toast.dart';
import '../../utils/language_util.dart';
import '../../utils/suda_json_util.dart';
import '../../widgets/app_scaffold.dart';
import '../../routes/roleplay_router.dart';

/// Roleplay Overview Screen (Sub Screen)
///
/// Roleplay 목록 및 개요를 표시하는 화면
class RoleplayOverviewScreen extends StatefulWidget {
  final int roleplayId;
  final UserDto? user;

  const RoleplayOverviewScreen({
    super.key,
    required this.roleplayId,
    this.user,
  });

  static const String routeName = '/roleplay/overview';

  @override
  State<RoleplayOverviewScreen> createState() => _RoleplayOverviewScreenState();
}

class _RoleplayOverviewScreenState extends State<RoleplayOverviewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  RoleplayOverviewDto? _overview;
  late int _currentRoleplayId;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _titleKey = GlobalKey();
  bool _isBackButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _currentRoleplayId = widget.roleplayId;
    _loadOverview(_currentRoleplayId);
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    RoleplayStateService.instance.clear();
    _overview = null;
    _errorMessage = null;
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadOverview(int roleplayId) async {
    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Authentication required.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _overview = null;
      });
      RoleplayStateService.instance.clear();
      if (widget.user != null) {
        RoleplayStateService.instance.setUser(widget.user);
      }
      final overview = await SudaApiClient.getRoleplayOverview(
        accessToken: accessToken,
        roleplayId: roleplayId,
      );
      if (!mounted) return;
      RoleplayStateService.instance.setOverview(
        roleplayId: roleplayId,
        overview: overview,
      );
      setState(() {
        _overview = overview;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load roleplay overview.';
      });
    }
  }

  void _navigateToOpening(BuildContext context) {
    RoleplayRouter.pushOpening(context);
  }

  String _getLocalizedText(List<SudaJson>? values) {
    return SudaJsonUtil.localizedText(values);
  }

  String _getChooseRoleText() {
    final langCode = LanguageUtil.getCurrentLanguageCode();
    if (langCode == 'ko') return '역할을 선택하세요';
    if (langCode == 'pt') return 'Escolha seu papel';
    return 'Choose your role';
  }

  String _getSimilarRoleplaysText() {
    final langCode = LanguageUtil.getCurrentLanguageCode();
    if (langCode == 'ko') return '비슷한 롤플레이';
    if (langCode == 'pt') return 'Roleplays Similares';
    return 'Similar Roleplays';
  }

  String _getRoleLockedMessage({required bool isAvailableToUsers}) {
    final langCode = LanguageUtil.getCurrentLanguageCode();
    if (!isAvailableToUsers) {
      if (langCode == 'ko') return '이 롤플레이는 준비 중입니다.';
      if (langCode == 'pt') return 'Este roleplay está sendo preparado.';
      return 'This roleplay is being prepared.';
    }
    if (langCode == 'ko') {
      return '이 역할을 잠금 해제하려면 이전 역할의 모든 엔딩을 완료하세요.';
    }
    if (langCode == 'pt') {
      return 'Complete todos os finais do papel anterior para desbloquear este papel.';
    }
    return 'Complete all endings of the previous role to unlock this role.';
  }

  Widget _buildStars(int activeCount) {
    final count = activeCount.clamp(0, 3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final isActive = index < count;
        return Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : 2),
          child: Image.asset(
            isActive
                ? 'assets/images/icons/star_on.png'
                : 'assets/images/icons/star_off.png',
            width: 16,
            height: 16,
          ),
        );
      }),
    );
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

  Widget _buildRoleButton({
    required RoleplayRoleDto role,
    required bool isEnabled,
    required int starCount,
  }) {
    final name = _getLocalizedText(role.name);
    final availableToUsersYn = role.availableToUsersYn ?? 'N';
    final backgroundColor = isEnabled ? const Color(0xFF0CABA8) : const Color(0xFF353535);
    final foregroundColor = isEnabled ? Colors.white : const Color(0xFF8C8C8C);
    final leadingIcon = isEnabled
        ? 'assets/images/icons/play_white.svg'
        : 'assets/images/icons/lock.svg';
    final stars = _buildStars(starCount);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (!isEnabled) {
            final message = _getRoleLockedMessage(
              isAvailableToUsers: availableToUsersYn == 'Y',
            );
            AppToast.show(context, message);
          } else {
            // 활성화된 경우 roleId 저장 후 오프닝으로 이동
            final overview = RoleplayStateService.instance.overview;
            final starterKey = overview?.roleplay?.starter?.key;
            final starterRoleId = int.tryParse(starterKey ?? '');
            final isUserStarter =
                starterRoleId != null && starterRoleId == role.id;
            RoleplayStateService.instance.setSelectedRole(role.id);
            RoleplayStateService.instance
                .setIsUserTurnYn(isUserStarter ? 'Y' : 'N');
            _navigateToOpening(context);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
          elevation: 0,
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              leadingIcon,
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            stars,
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarRoleplayItem(RoleplayDto roleplay, double width) {
    final imageUrl = roleplay.thumbnailImgPath == null || roleplay.thumbnailImgPath!.isEmpty
        ? null
        : '${AppConfig.cdnBaseUrl}${roleplay.thumbnailImgPath}';
    final title = _getLocalizedText(roleplay.title);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 12,
        );

    return GestureDetector(
      onTap: () => _refreshOverview(roleplay.id),
      child: SizedBox(
        width: width,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl == null
                  ? Container(
                      width: width,
                      height: width * 1.5,
                      color: const Color(0xFF2A2A2A),
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      imageBuilder: (context, imageProvider) {
                        return Image(
                          image: imageProvider,
                          width: width,
                          fit: BoxFit.fitWidth,
                        );
                      },
                      placeholder: (context, url) => Container(
                        width: width,
                        height: width * 1.5,
                        color: const Color(0xFF2A2A2A),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: width,
                        height: width * 1.5,
                        color: Colors.grey[900],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
            ),
            if (title.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
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
    );
  }

  void _refreshOverview(int roleplayId) {
    if (_currentRoleplayId == roleplayId) return;
    if (!_isBackButtonVisible) {
      setState(() {
        _isBackButtonVisible = true;
      });
    }
    _currentRoleplayId = roleplayId;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
    _loadOverview(roleplayId);
  }

  Widget _buildBackgroundShimmer(double size) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3F3F3F),
      child: Container(
        width: double.infinity,
        height: size,
        color: Colors.white,
      ),
    );
  }

  void _handleScroll() {
    final context = _titleKey.currentContext;
    if (context == null) return;
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    final position = box.localToGlobal(Offset.zero);
    final topInset = MediaQuery.of(context).padding.top;
    final shouldHide = position.dy <= (topInset + 48);
    if (shouldHide == _isBackButtonVisible) {
      setState(() {
        _isBackButtonVisible = !shouldHide;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _overview ?? RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    final theme = Theme.of(context).textTheme;
    final scaffoldBackground = Theme.of(context).scaffoldBackgroundColor;
    final backgroundSize = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: roleplay?.overviewImgPath == null || roleplay!.overviewImgPath!.isEmpty
                ? Container(
                    height: backgroundSize,
                    color: scaffoldBackground,
                  )
                : CachedNetworkImage(
                    imageUrl: '${AppConfig.cdnBaseUrl}${roleplay.overviewImgPath}',
                    width: double.infinity,
                    height: backgroundSize,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    placeholder: (context, url) => _buildBackgroundShimmer(backgroundSize),
                    errorWidget: (context, url, error) => Container(
                      height: backgroundSize,
                      color: scaffoldBackground,
                    ),
                  ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: backgroundSize,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          scaffoldBackground,
                        ],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    color: scaffoldBackground,
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getLocalizedText(roleplay?.title),
                          key: _titleKey,
                          style: theme.headlineLarge?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getLocalizedText(roleplay?.synopsis),
                          style: theme.bodySmall?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _getChooseRoleText(),
                          style: theme.headlineSmall?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 40),
                        if (roleplay?.roleList != null)
                          ...roleplay!.roleList!.map((role) {
                            final availableRoleIds =
                                overview?.availableRoleIds ?? const <int>[];
                            final isAvailable = availableRoleIds.contains(role.id);
                            final isEnabled = isAvailable && role.availableToUsersYn == 'Y';
                            final starCount = overview?.starResultMap?[role.id] ?? 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRoleButton(
                                role: role,
                                isEnabled: isEnabled,
                                starCount: starCount,
                              ),
                            );
                          }),
                        const SizedBox(height: 20),
                        Text(
                          _getSimilarRoleplaysText(),
                          style: theme.headlineSmall?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 2,
                          color: const Color(0xFF353535),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final spacing = 12.0;
                            final itemWidth =
                                (constraints.maxWidth - (spacing * 2)) / 3;
                            final items =
                                overview?.similarRoleplayList ?? const <RoleplayDto>[];
                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: items
                                  .map((item) => _buildSimilarRoleplayItem(item, itemWidth))
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: AnimatedOpacity(
              opacity: _isBackButtonVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_isBackButtonVisible,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16),
                    child: AppScaffold.backButton(context),
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          if (!_isLoading && _errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
