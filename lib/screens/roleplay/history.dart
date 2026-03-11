import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../config/app_config.dart';
import '../../models/roleplay_models.dart';
import '../../services/token_storage.dart';
import '../../services/suda_api_client.dart';
import '../../utils/sub_screen_route.dart';
import '../../widgets/app_scaffold.dart';
import 'review_chat.dart';
import 'review_ending.dart';

/// History Screen (Sub Screen)
///
/// Profile에서 진입. 롤플레이 결과 요약. Result Screen과 동일 구조, 초기 애니메이션 없음.
/// resultId로 RoleplayResultDto를 조회해 스크린 상태로 보관 (RoleplayStateService와 혼용하지 않음).
/// History ↔ ReviewChat/ReviewEnding 왔다 갔다 하는 동안 동일 result 정보 유지. 나갈 때·새로 진입할 때 갱신.
class HistoryScreen extends StatefulWidget {
  /// 해당 롤플레이 결과 ID (GET /v1/roleplays/results 응답의 resultId)
  final int resultId;

  const HistoryScreen({
    super.key,
    required this.resultId,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  RoleplayResultDto? _resultDto;
  bool _loading = true;
  String? _error;
  bool _endingLoading = false;
  bool _reloadInProgress = false;

  static const double _finalBoxHeight = 210;
  static const Color _teal = Color(0xFF0CABA8);
  static const Color _defaultBg = Color(0xFF121212);
  static const Color _mint = Color(0xFF80D7CF);
  static const Color _mintLight = Color(0xFFCFFFFB);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _missionSucceeded = 'assets/images/icons/mission_succeeded.png';
  static const String _missionFailed = 'assets/images/icons/mission_failed.png';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// resultId로 RoleplayResultDto 조회 후 상태 보관. 롤플레이 진행용 상태(RoleplayStateService)와 혼용하지 않음.
  Future<void> _loadData() async {
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await SudaApiClient.getRoleplayResult(
        accessToken: token,
        resultId: widget.resultId,
      );
      if (!mounted) return;
      setState(() {
        _resultDto = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  /// GET /v1/roleplays/results-reload/{resultId}. 2xx only → update _resultDto. No UI feedback; blocks duplicate taps while in progress.
  Future<void> _fetchReload() async {
    if (_reloadInProgress) return;
    final token = await TokenStorage.loadAccessToken();
    if (token == null || !mounted) return;
    setState(() => _reloadInProgress = true);
    try {
      final dto = await SudaApiClient.getRoleplayResultReload(
        accessToken: token,
        resultId: widget.resultId,
      );
      if (!mounted) return;
      if (dto != null) setState(() => _resultDto = dto);
    } finally {
      if (mounted) setState(() => _reloadInProgress = false);
    }
  }

  Widget _buildBoxLayerContent(BuildContext context) {
    final dto = _resultDto;
    final starResult = dto?.starResult ?? 0;
    final theme = Theme.of(context).textTheme;

    const double star70Offset = 10.0;
    // 기본 silver, 왼쪽부터 starResult개만 gold (1번째: starResult>=1, 2번째: starResult>=2, 3번째: starResult>=3)
    Widget starWidget(int index, double size) {
      final isGold = starResult >= index + 1;
      final asset = isGold ? _starGold : _starSilver;
      return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    }

    final starsRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: starWidget(0, 70),
          ),
        ),
        const SizedBox(width: 10),
        starWidget(1, 80),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: starWidget(2, 70),
          ),
        ),
      ],
    );

    final starsTappable = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _fetchReload,
      child: starsRow,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        starsTappable,
        const SizedBox(height: 5),
        Text(
          dto?.mainTitle ?? '',
          style: theme.headlineLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          dto?.subTitle ?? '',
          style: theme.headlineSmall?.copyWith(color: Colors.black),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildContentLayer(BuildContext context) {
    final dto = _resultDto;
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final likePointValue = dto?.likePoint != null ? '${dto!.likePoint}' : '00';
    final likePointText = ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_mint, _mintLight],
      ).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          likePointValue,
          style: theme.headlineLarge?.copyWith(color: Colors.white),
        ),
      ),
    );

    final missionResultStr = dto?.missionResult ?? '';
    final missionIcons = <Widget>[];
    if (missionResultStr.isEmpty) {
      final missionCount = dto?.completedMissionIds?.length ?? 0;
      for (var i = 0; i < missionCount; i++) {
        missionIcons.add(Image.asset(_missionFailed, height: 20, width: 20, fit: BoxFit.contain));
      }
    } else {
      for (var i = 0; i < missionResultStr.length; i++) {
        final isSuccess = missionResultStr[i].toUpperCase() == 'Y';
        missionIcons.add(Image.asset(
          isSuccess ? _missionSucceeded : _missionFailed,
          height: 20,
          width: 20,
          fit: BoxFit.contain,
        ));
      }
    }

    final wordsValue = dto?.words != null ? '${dto!.words}' : '00';

    final bodyDefaultMint = theme.bodyLarge?.copyWith(
      fontWeight: FontWeight.w600,
      fontFamily: 'ChironGoRoundTC',
      color: _mint,
    );
    final h3Mint = theme.headlineSmall?.copyWith(
      fontFamily: 'ChironGoRoundTC',
      color: _mint,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 35),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(_likeAtResult, width: 75, height: 75, fit: BoxFit.contain),
              const SizedBox(width: 5),
              Transform.translate(
                offset: const Offset(0, 10),
                child: likePointText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 35),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Mission', style: bodyDefaultMint),
                    const SizedBox(height: 4),
                    if (missionIcons.isEmpty)
                      Text('—', style: theme.bodyMedium?.copyWith(color: Colors.white))
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: missionIcons,
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Words', style: bodyDefaultMint),
                    const SizedBox(height: 4),
                    Text(wordsValue, style: theme.bodyLarge?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        Text('Good Points', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.goodFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        Text('To Improve', style: h3Mint, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        Text(
          dto?.improvementFeedback ?? '',
          style: theme.bodySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 25),
        Center(
          child: _resultDto?.endingId != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _viewButton(
                      context,
                      'View Chat',
                      _resultDto != null
                          ? () {
                              Navigator.push(
                                context,
                                SubScreenRoute(
                                  page: ReviewChatScreen(result: _resultDto!),
                                ),
                              );
                            }
                          : null,
                    ),
                    const SizedBox(width: 15),
                    _viewButton(
                      context,
                      'View Ending',
                      _resultDto != null &&
                              _resultDto!.roleplayId != null &&
                              _resultDto!.roleplayRoleId != null &&
                              _resultDto!.endingId != null
                          ? () => _openReviewEnding(context)
                          : null,
                    ),
                  ],
                )
              : _viewButton(
                  context,
                  'View Chat',
                  _resultDto != null
                      ? () {
                          Navigator.push(
                            context,
                            SubScreenRoute(
                              page: ReviewChatScreen(result: _resultDto!),
                            ),
                          );
                        }
                      : null,
                ),
        ),
        const SizedBox(height: 35),
      ],
    );
  }

  Future<void> _openReviewEnding(BuildContext context) async {
    final dto = _resultDto;
    if (dto == null ||
        dto.roleplayId == null ||
        dto.roleplayRoleId == null ||
        dto.endingId == null) return;
    final token = await TokenStorage.loadAccessToken();
    if (token == null) return;
    if (!mounted) return;
    setState(() => _endingLoading = true);
    try {
      final ending = await SudaApiClient.getRoleplayEnding(
        accessToken: token,
        rpId: dto.roleplayId!,
        rpRoleId: dto.roleplayRoleId!,
        endingId: dto.endingId!,
      );
      if (!mounted) return;
      final path = ending.imgPath;
      if (path != null && path.isNotEmpty && context.mounted) {
        final url = '${AppConfig.cdnBaseUrl}$path';
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      }
      if (!mounted) return;
      setState(() => _endingLoading = false);
      if (!context.mounted) return;
      Navigator.push(
        context,
        SubScreenRoute(page: ReviewEndingScreen(ending: ending)),
      );
    } catch (_) {
      if (mounted) setState(() => _endingLoading = false);
    }
  }

  Widget _viewButton(
    BuildContext context,
    String label,
    VoidCallback? onPressed,
  ) {
    final isEndingLoading = label == 'View Ending' && _endingLoading;
    return ElevatedButton(
      onPressed: isEndingLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _teal,
        disabledForegroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
        elevation: 0,
      ),
      child: isEndingLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        showBackButton: false,
        backgroundColor: _defaultBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return AppScaffold(
        showBackButton: false,
        backgroundColor: _defaultBg,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _teal,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: Container(color: _teal)),
            Column(
              children: [
                SizedBox(
                  height: _finalBoxHeight,
                  width: double.infinity,
                  child: Container(
                    color: _teal,
                    alignment: Alignment.center,
                    child: _buildBoxLayerContent(context),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _defaultBg,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildContentLayer(context),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 16,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/icons/header_arrow_back.svg',
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
