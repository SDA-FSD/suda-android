import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../routes/roleplay_router.dart';
import '../../services/series_state_service.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/suda_json_util.dart';

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
  late final Animation<double> _scaleAnimation;
  late int _selectedStars;

  String? get _imagePath =>
      SeriesStateService.instance.overview?.endingImgPath;

  bool get _hasImage {
    final path = _imagePath;
    return path != null && path.isNotEmpty;
  }

  String get _imageUrl {
    final path = _imagePath;
    if (path == null || path.isEmpty) return '';
    return '${AppConfig.cdnBaseUrl}$path';
  }

  String get _displayTitle => SudaJsonUtil.localizedMapText(
        SeriesStateService.instance.overview?.endingTitle ?? const {},
      );

  String get _displayContent => SudaJsonUtil.localizedMapText(
        SeriesStateService.instance.overview?.endingContent ?? const {},
      );

  int _resolveInitialStarRating() {
    final rating =
        SeriesStateService.instance.cachedUserHistory?.userStarRating;
    if (rating == null) return 0;
    return rating.clamp(0, 5);
  }

  @override
  void initState() {
    super.initState();
    _selectedStars = _resolveInitialStarRating();
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
    super.dispose();
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
    if (!context.mounted) return;
    RoleplayRouter.replaceWithResult(context);
  }

  void _onStarSelected(int stars) {
    setState(() => _selectedStars = stars);
    final historyId = SeriesStateService.instance.cachedUserHistory?.id;
    if (historyId == null) return;
    TokenStorage.loadAccessToken().then((token) {
      if (token == null) return;
      SudaApiClient.updateRpS2UserStarRating(
        accessToken: token,
        rpUserHistoryId: historyId,
        userStarRating: stars,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final title = _displayTitle;
    final content = _displayContent;
    final contentStyle = theme.bodyMedium?.copyWith(color: Colors.white)
        ?? const TextStyle(color: Colors.white);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomAreaHeight = screenHeight * 0.35;

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
                            Text(
                              content,
                              style: contentStyle,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: bottomAreaHeight,
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: List.generate(5, (i) {
                                        final filled =
                                            (i + 1) <= _selectedStars;
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            right: i < 4 ? 5 : 0,
                                          ),
                                          child: GestureDetector(
                                            onTap: () =>
                                                _onStarSelected(i + 1),
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
                          ),
                          Expanded(
                            child: Center(
                              child: ElevatedButton(
                                onPressed: () => _navigateToResult(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0CABA8),
                                  foregroundColor: Colors.white,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 18,
                                  ),
                                  elevation: 0,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: Size.zero,
                                ),
                                child: Text(l10n.endingNext),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
