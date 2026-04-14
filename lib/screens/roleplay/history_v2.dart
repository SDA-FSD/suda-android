import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../api/suda_api_client.dart';
import '../../config/app_config.dart';
import '../../l10n/app_localizations.dart';
import '../../models/roleplay_models.dart';
import '../../utils/default_toast.dart';
import '../../utils/sub_screen_route.dart';
import '../roleplay/review_chat.dart';
import '../roleplay/review_ending.dart';
import '../../services/token_storage.dart';

/// History V2 Screen (Sub Screen)
///
/// Profile에서 진입. Result V2를 기준으로 결과를 재조회해 최종 상태로만 노출한다(애니메이션 없음).
/// 하단 View Chat/View Ending 버튼 동작은 HistoryScreen과 동일하게 유지한다.
class HistoryScreenV2 extends StatefulWidget {
  static const String routeName = '/profile/history_v2';

  final int resultId;

  const HistoryScreenV2({
    super.key,
    required this.resultId,
  });

  @override
  State<HistoryScreenV2> createState() => _HistoryScreenV2State();
}

class _HistoryScreenV2State extends State<HistoryScreenV2> {
  RoleplayResultDto? _dto;
  bool _loading = true;
  String? _error;
  bool _endingLoading = false;
  bool _reloadInProgress = false;

  final AudioPlayer _expressionAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _expressionAudioSub;
  int _expressionMegaphoneSeq = 0;
  int? _expressionHighlightedIndex;
  int? _expressionPlaybackIndex;
  late final Set<int> _bookmarkedExpressionIndexes = <int>{};

  static const Color _teal = Color(0xFF0CABA8);
  static const Color _topBg = Color(0xFF054544);
  static const Color _bottomBg = Color(0xFF0CABA8);
  static const Color _feedbackBoxFill = Color(0xFF80D7CF);
  static const Color _cardBg = Color(0x8080D7CF);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const double _boxHeight = 340;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _expressionAudioSub?.cancel();
    _expressionAudioSub = null;
    unawaited(_expressionAudioPlayer.dispose());
    super.dispose();
  }

  Future<void> _loadData() async {
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
      final result = await SudaApiClient.getRoleplayResult(
        accessToken: token,
        resultId: widget.resultId,
      );
      if (!mounted) return;
      setState(() {
        _dto = result;
        _loading = false;
        _error = null;
        _bookmarkedExpressionIndexes
          ..clear()
          ..addAll(result.savedExpressionIndexes ?? const <int>[]);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// GET /v1/roleplays/results-reload/{resultId}. 2xx only → update _dto. No UI feedback.
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
      if (dto != null) {
        setState(() {
          _dto = dto;
          _bookmarkedExpressionIndexes
            ..clear()
            ..addAll(dto.savedExpressionIndexes ?? const <int>[]);
        });
      }
    } finally {
      if (mounted) setState(() => _reloadInProgress = false);
    }
  }

  Future<AudioSource?> _prepareExpressionAudio({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    await _expressionAudioPlayer.stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _expressionAudioPlayer.setAudioSource(source);
      return source;
    }
    if (soundBytes != null && soundBytes.isNotEmpty) {
      final source = AudioSource.uri(
        Uri.dataFromBytes(soundBytes, mimeType: 'audio/mpeg'),
      );
      await _expressionAudioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<void> _onExpressionCardTap(int expressionIndex) async {
    _expressionMegaphoneSeq++;
    final seq = _expressionMegaphoneSeq;
    _expressionAudioSub?.cancel();
    _expressionAudioSub = null;
    await _expressionAudioPlayer.stop();

    if (!mounted) return;
    setState(() {
      _expressionHighlightedIndex = expressionIndex;
      _expressionPlaybackIndex = expressionIndex;
    });

    final token = await TokenStorage.loadAccessToken();
    if (!mounted || seq != _expressionMegaphoneSeq) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _expressionHighlightedIndex = null;
        _expressionPlaybackIndex = null;
      });
      return;
    }

    try {
      final tts = await SudaApiClient.getRoleplayResultExpressionSound(
        accessToken: token,
        resultId: widget.resultId,
        expressionIndex: expressionIndex,
      );
      if (!mounted || seq != _expressionMegaphoneSeq) return;

      final source = await _prepareExpressionAudio(
        cdnYn: tts.cdnYn,
        cdnPath: tts.cdnPath,
        soundBytes: tts.sound,
      );
      if (!mounted || seq != _expressionMegaphoneSeq) return;

      if (source == null) {
        setState(() => _expressionPlaybackIndex = null);
        return;
      }

      _expressionAudioSub =
          _expressionAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _expressionAudioSub?.cancel();
          _expressionAudioSub = null;
          if (!mounted || seq != _expressionMegaphoneSeq) return;
          setState(() => _expressionPlaybackIndex = null);
        }
      });
      await _expressionAudioPlayer.play();
    } catch (_) {
      _expressionAudioSub?.cancel();
      _expressionAudioSub = null;
      if (!mounted || seq != _expressionMegaphoneSeq) return;
      setState(() => _expressionPlaybackIndex = null);
    }
  }

  Future<void> _onExpressionBookmarkTap(int expressionIndex) async {
    final isBookmarked = _bookmarkedExpressionIndexes.contains(expressionIndex);
    final token = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      DefaultToast.show(context, 'HTTP 401 · Request failed', isError: true);
      return;
    }

    try {
      if (isBookmarked) {
        await SudaApiClient.deleteUserExpression(
          accessToken: token,
          rpResultId: widget.resultId,
          expressionIndex: expressionIndex,
        );
        if (!mounted) return;
        setState(() => _bookmarkedExpressionIndexes.remove(expressionIndex));
      } else {
        await SudaApiClient.saveUserExpression(
          accessToken: token,
          roleplayResultId: widget.resultId,
          expressionIndex: expressionIndex,
        );
        if (!mounted) return;
        setState(() => _bookmarkedExpressionIndexes.add(expressionIndex));
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.expressionSavedToProfile);
      }
    } catch (e) {
      if (!mounted) return;
      DefaultToast.show(context, e.toString(), isError: true);
    }
  }

  Widget _buildStarsRow(RoleplayResultDto dto) {
    final starResult = dto.starResult ?? 0;
    const double star70Offset = 10.0;
    Widget starWidget(int index, double size) {
      final isGold = starResult >= index + 1;
      final asset = isGold ? _starGold : _starSilver;
      return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _fetchReload,
      child: Row(
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
      ),
    );
  }

  Widget _buildBoxLayer(RoleplayResultDto dto) {
    final theme = Theme.of(context).textTheme;
    final wordsDisplay = '${dto.words ?? 0}'.padLeft(2, '0');
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 35),
        _buildStarsRow(dto),
        const SizedBox(height: 5),
        Text(
          dto.mainTitle ?? '',
          style: theme.headlineLarge?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 5),
        Text(
          dto.subTitle ?? '',
          style: theme.headlineSmall?.copyWith(color: const Color(0xFF80D7CF)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 24),
            _buildStatCard(
              context,
              title: 'Mission',
              child: _buildMissionIcons(dto),
            ),
            const SizedBox(width: 20),
            _buildStatCard(
              context,
              title: 'Words',
              child: Text(
                wordsDisplay,
                style: theme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(width: 20),
            _buildStatCard(
              context,
              title: 'Like',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    _likeAtResult,
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 2),
                  Flexible(child: _buildLikeText(theme, dto)),
                ],
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final theme = Theme.of(context).textTheme;
    final labelPrimary = theme.bodyLarge?.copyWith(
          fontFamily: 'ChironGoRoundTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontVariations: const [FontVariation('wght', 600)],
          letterSpacing: -0.4,
          height: 1.2,
          color: Colors.white,
        ) ??
        const TextStyle(
          fontFamily: 'ChironGoRoundTC',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontVariations: [FontVariation('wght', 600)],
          letterSpacing: -0.4,
          height: 1.2,
          color: Colors.white,
        );

    return Expanded(
      child: Container(
        height: 75,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: labelPrimary,
              textAlign: TextAlign.center,
            ),
            Expanded(
              child: Center(child: child),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionIcons(RoleplayResultDto dto) {
    final missionResultStr = dto.missionResult ?? '';
    final missionLen = missionResultStr.isEmpty
        ? (dto.completedMissionIds?.length ?? 0)
        : missionResultStr.length;
    final missionIcons = <Widget>[];

    if (missionResultStr.isEmpty) {
      for (var i = 0; i < missionLen; i++) {
        missionIcons.add(
          Image.asset(
            'assets/images/icons/mission_failed.png',
            height: 20,
            width: 15,
            fit: BoxFit.contain,
          ),
        );
      }
    } else {
      for (var i = 0; i < missionResultStr.length; i++) {
        final isSuccess = missionResultStr[i].toUpperCase() == 'Y';
        missionIcons.add(
          Image.asset(
            isSuccess
                ? 'assets/images/icons/mission_succeeded.png'
                : 'assets/images/icons/mission_failed.png',
            height: 20,
            width: 15,
            fit: BoxFit.contain,
          ),
        );
      }
    }

    if (missionIcons.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: Colors.white),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 0,
      runSpacing: 2,
      children: missionIcons,
    );
  }

  Widget _buildLikeText(TextTheme theme, RoleplayResultDto dto) {
    final likeValue = '${dto.likePoint ?? 0}'.padLeft(2, '0');
    return Text(
      likeValue,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
    );
  }

  Widget _buildFeedback(RoleplayResultDto dto) {
    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final raw = dto.overallFeedback;
    final feedback = (raw == null || raw.trim().isEmpty)
        ? l10n.roleplayResultFeedbackInsufficientWords
        : raw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'Feedback',
            style: theme.headlineSmall?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _feedbackBoxFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                feedback,
                style: theme.bodyMedium?.copyWith(color: Colors.black),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpressionLayer(RoleplayResultDto dto) {
    final items = dto.expressionUpgrades ?? const <ExpressionUpgradeDto>[];
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context).textTheme;
    final sw = MediaQuery.sizeOf(context).width;
    final itemW = sw * 0.7;
    const between = 16.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            'Expression Upgrade',
            style: theme.headlineSmall?.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 24, right: 24),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  SizedBox(
                    width: itemW,
                    child: _ExpressionUpgradeCard(
                      item: items[i],
                      highlighted: _expressionHighlightedIndex == i,
                      playbackActive: _expressionPlaybackIndex == i,
                      bookmarked: _bookmarkedExpressionIndexes.contains(i),
                      onCardTap: () => _onExpressionCardTap(i),
                      onBookmarkTap: () => _onExpressionBookmarkTap(i),
                    ),
                  ),
                  if (i < items.length - 1) const SizedBox(width: between),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openReviewEnding() async {
    final dto = _dto;
    if (dto == null ||
        dto.roleplayId == null ||
        dto.roleplayRoleId == null ||
        dto.endingId == null) {
      return;
    }
    final token = await TokenStorage.loadAccessToken();
    if (token == null) {
      return;
    }
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
        await precacheImage(CachedNetworkImageProvider(url), context);
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

  Widget _viewButton(String label, VoidCallback? onPressed) {
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
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_topBg, _bottomBg],
            ),
          ),
          child: const SafeArea(
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_topBg, _bottomBg],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 40,
                      height: 40,
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
        ),
      );
    }

    final dto = _dto!;
    final hasUpgrades = dto.expressionUpgrades?.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_topBg, _bottomBg],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: _boxHeight,
                    width: double.infinity,
                    child: Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: _buildBoxLayer(dto),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(0, 32, 0, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildFeedback(dto),
                          if (hasUpgrades) ...[
                            const SizedBox(height: 28),
                            _buildExpressionLayer(dto),
                          ],
                          const SizedBox(height: 28),
                          Center(
                            child: dto.endingId != null
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _viewButton(
                                        'View Chat',
                                        () {
                                          final r = _dto;
                                          if (r == null) return;
                                          Navigator.push(
                                            context,
                                            SubScreenRoute(
                                              page: ReviewChatScreen(result: r),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 15),
                                      _viewButton(
                                        'View Ending',
                                        (dto.roleplayId != null &&
                                                dto.roleplayRoleId != null &&
                                                dto.endingId != null)
                                            ? _openReviewEnding
                                            : null,
                                      ),
                                    ],
                                  )
                                : _viewButton(
                                    'View Chat',
                                    () {
                                      final r = _dto;
                                      if (r == null) return;
                                      Navigator.push(
                                        context,
                                        SubScreenRoute(
                                          page: ReviewChatScreen(result: r),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
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
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 40,
                    height: 40,
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
      ),
    );
  }
}

class _ExpressionUpgradeCard extends StatelessWidget {
  const _ExpressionUpgradeCard({
    required this.item,
    required this.highlighted,
    required this.playbackActive,
    required this.bookmarked,
    required this.onCardTap,
    required this.onBookmarkTap,
  });

  final ExpressionUpgradeDto item;
  final bool highlighted;
  final bool playbackActive;
  final bool bookmarked;
  final VoidCallback onCardTap;
  final VoidCallback onBookmarkTap;

  static const String _checkMintSvg = 'assets/images/icons/check_mint.svg';
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _bookmarkOffPng = 'assets/images/icons/bookmark_off.png';
  static const String _bookmarkOnPng = 'assets/images/icons/bookmark_on.png';
  static const double _bodyLeftIndent = 30;
  static const Color _exprTextPrimary = Color(0xFF121212);
  static const Color _exprTextSecondary = Color(0xFF676767);
  static const Color _expressionUpgradeCardBg = Color(0xFF80D7CF);
  static const Color _megaphoneTintActive = Color(0xFF0CABA8);
  static const Color _megaphoneTintLoading = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final expression = item.expression ?? '';
    final meaning = item.meaningUserLanguage ?? '';
    final rephrased = item.rephrasedSentence ?? '';

    return GestureDetector(
      onTap: onCardTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          color: highlighted ? Colors.white : _expressionUpgradeCardBg,
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      _checkMintSvg,
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expression,
                        style: theme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _exprTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.only(left: _bodyLeftIndent),
                  child: Text(
                    rephrased,
                    style: theme.bodyMedium?.copyWith(
                      color: _exprTextPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: _bodyLeftIndent),
                  child: Text(
                    meaning,
                    style: theme.bodySmall?.copyWith(
                      color: _exprTextSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset(
                      _megaphonePng,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      color: playbackActive
                          ? _megaphoneTintLoading
                          : _megaphoneTintActive,
                      colorBlendMode: BlendMode.srcIn,
                    ),
                    GestureDetector(
                      onTap: onBookmarkTap,
                      behavior: HitTestBehavior.opaque,
                      child: Image.asset(
                        bookmarked ? _bookmarkOnPng : _bookmarkOffPng,
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
