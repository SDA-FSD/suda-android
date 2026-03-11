import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/roleplay_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/suda_json_util.dart';
import '../../utils/default_markdown.dart';

/// Roleplay Ending Screen (Full Screen)
///
/// Roleplay 성공 종료 화면. 닫기 버튼 없음.
/// 엔딩 이미지(있을 경우) → 1.5x→1x 축소 애니메이션 → 80% 검정 레이어 fade-in → 콘텐츠 fade-in.
/// 이미지 없을 경우 바로 레이어·콘텐츠 노출.
class RoleplayEndingScreen extends StatefulWidget {
  const RoleplayEndingScreen({super.key});

  @override
  State<RoleplayEndingScreen> createState() => _RoleplayEndingScreenState();
}

class _RoleplayEndingScreenState extends State<RoleplayEndingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _overlayController;
  late final AnimationController _contentController;
  late final AnimationController _buttonFadeController;
  late final AnimationController _balloonController;
  late final Animation<double> _scaleAnimation;
  int _selectedStars = 0;
  bool _isTransitioning = false;
  Offset? _buttonCenter;
  Size? _buttonSize;
  final GlobalKey _nextButtonKey = GlobalKey();

  RoleplayEndingDto? get _ending {
    final overview = RoleplayStateService.instance.overview;
    final roleId = RoleplayStateService.instance.roleId;
    if (overview == null || roleId == null) return null;
    final roleList = overview.roleplay?.roleList;
    if (roleList == null) return null;
    for (final r in roleList) {
      if (r.id == roleId) {
        final list = r.endingList;
        return list != null && list.isNotEmpty ? list.first : null;
      }
    }
    return null;
  }

  bool get _hasImage {
    final path = _ending?.imgPath;
    return path != null && path.isNotEmpty;
  }

  String get _imageUrl {
    final path = _ending?.imgPath;
    if (path == null || path.isEmpty) return '';
    return '${AppConfig.cdnBaseUrl}$path';
  }

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _overlayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
    _buttonFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _balloonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_hasImage) {
        _scaleController.forward().then((_) {
          if (!mounted) return;
          _overlayController.forward().then((_) {
            if (mounted) _contentController.forward();
          });
        });
      } else {
        _overlayController.forward().then((_) {
          if (mounted) _contentController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _overlayController.dispose();
    _contentController.dispose();
    _buttonFadeController.dispose();
    _balloonController.dispose();
    super.dispose();
  }

  void _startTransitionToResult(BuildContext context) {
    final box = _nextButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !mounted) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    setState(() {
      _buttonCenter = pos + Offset(size.width / 2, size.height / 2);
      _buttonSize = size;
    });
    _buttonFadeController.forward();
    _balloonController.forward().then((_) {
      if (mounted) {
        RoleplayRouter.replaceWithResult(context);
      }
    });
  }

  Future<void> _handleBackButton(BuildContext context) async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Exit from ending screen'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (shouldPop == true && context.mounted) {
      RoleplayRouter.popToOverview(context);
    }
  }

  void _navigateToResult(BuildContext context) {
    final resultId = RoleplayStateService.instance.cachedResult?.id;
    TokenStorage.loadAccessToken().then((token) {
      if (resultId != null && token != null) {
        SudaApiClient.updateRoleplayResultStar(
          accessToken: token,
          resultId: resultId,
          star: _selectedStars,
        );
      }
    });
    if (!context.mounted) return;
    setState(() => _isTransitioning = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startTransitionToResult(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final ending = _ending;
    final title = ending != null
        ? SudaJsonUtil.localizedText(ending.title)
        : '';
    final content = ending != null
        ? SudaJsonUtil.localizedText(ending.content)
        : '';
    final contentStyle = theme.bodyMedium?.copyWith(color: Colors.white)
        ?? TextStyle(color: Colors.white);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) await _handleBackButton(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_hasImage)
              AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: SizedBox(
                  height: screenHeight,
                  width: double.infinity,
                  child: Image(
                    image: CachedNetworkImageProvider(_imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _overlayController,
                curve: Curves.easeOut,
              ),
              child: Container(color: const Color(0xCC000000)),
            ),
            FadeTransition(
              opacity: CurvedAnimation(
                parent: _contentController,
                curve: Curves.easeOut,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            Text(
                              title,
                              style: theme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                            Text.rich(
                              TextSpan(
                                style: contentStyle,
                                children: DefaultMarkdown.buildSpans(
                                  content,
                                  contentStyle,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                            Text(
                              l10n.endingHowWas,
                              style: theme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (i) {
                                final filled = (i + 1) <= _selectedStars;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: i < 4 ? 5 : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => setState(
                                      () => _selectedStars = i + 1,
                                    ),
                                    child: Image.asset(
                                      filled
                                          ? 'assets/images/icons/star_filled.png'
                                          : 'assets/images/icons/star_empty.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Stack(
                          key: _nextButtonKey,
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: MediaQuery.sizeOf(context).width * 0.4,
                              height: 54,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0CABA8),
                                  borderRadius: BorderRadius.circular(27),
                                ),
                              ),
                            ),
                            FadeTransition(
                              opacity: Tween<double>(begin: 1, end: 0)
                                  .animate(_buttonFadeController),
                              child: SizedBox(
                                width: MediaQuery.sizeOf(context).width * 0.4,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isTransitioning
                                      ? null
                                      : () => _navigateToResult(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0CABA8),
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 18,
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(l10n.endingNext),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isTransitioning && _buttonCenter != null && _buttonSize != null)
              _buildShadowExpandOverlay(context),
          ],
        ),
      ),
    );
  }

  /// 그림자 객체: 버튼 위치·크기에서 확대, 중심은 디스플레이 중심으로, 좌우 반원(pill) 유지.
  /// 최종 크기: 가로 w*1.5, 세로 h*1.1. 가속 곡선(easeInQuint) 적용.
  Widget _buildShadowExpandOverlay(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final center = _buttonCenter!;
    final btnSize = _buttonSize!;
    final bw = btnSize.width;
    final bh = btnSize.height;
    final targetW = w * 1.5;
    final targetH = h * 1.1;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _balloonController,
        builder: (context, child) {
          // 가속 곡선: 더 급하게 — 천천히 시작 → 최종 구간에서 더 빠르게
          final t = Curves.easeInQuint.transform(_balloonController.value);
          // 보간: 버튼 위치·크기 → 디스플레이 중심, (targetW, targetH). pill 유지 = radius = min(w,h)/2
          final left = (center.dx - bw / 2) * (1 - t) + (w / 2 - targetW / 2) * t;
          final top = (center.dy - bh / 2) * (1 - t) + (h / 2 - targetH / 2) * t;
          final width = bw + (targetW - bw) * t;
          final height = bh + (targetH - bh) * t;
          final radius = (width < height ? width : height) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: left,
                top: top,
                width: width,
                height: height,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0CABA8),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
