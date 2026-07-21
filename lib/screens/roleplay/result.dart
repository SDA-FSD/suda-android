import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';

import '../../api/suda_api_client.dart';
import '../../config/app_config.dart';
import '../../effects/like_progress_effect.dart';
import '../../l10n/app_localizations.dart';
import '../../models/series_models.dart';
import '../../routes/roleplay_router.dart';
import '../../services/main_user_sync.dart';
import '../../services/roleplay_state_service.dart';
import '../../services/series_state_service.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/speech_feedback_premium.dart';
import '../../utils/sub_screen_route.dart';
import '../../utils/suda_json_util.dart';
import 'view_chat.dart';

const Color _exprTextPrimary = Color(0xFF121212);
const Color _exprTextSecondary = Color(0xFF676767);

/// Roleplay Result Screen (Full Screen)
/// 화면 fully shown 이후 1초 뒤 상단 이동 + LikeProgressEffect(레벨·라이크 진행) 후
/// Key Expression / Speech Feedback 본문 레이어를 노출한다.
class RoleplayResultScreen extends StatefulWidget {
  static const String routeName = '/roleplay/result';

  final bool showCloseButton;
  final bool skipEntranceAnimation;
  final bool exitViaPop;
  final bool showReportLink;

  const RoleplayResultScreen({
    super.key,
    this.showCloseButton = true,
    this.skipEntranceAnimation = false,
    this.exitViaPop = false,
    this.showReportLink = true,
  });

  @override
  State<RoleplayResultScreen> createState() => _RoleplayResultScreenState();
}

class _RoleplayResultScreenState extends State<RoleplayResultScreen>
    with TickerProviderStateMixin {
  static const Color _topBg = Color(0xFF054544);
  static const Color _bottomBg = Color(0xFF0CABA8);
  static const Color _teal = Color(0xFF0CABA8);
  static const Color _mint = Color(0xFF80D7CF);
  static const Color _cardBg = Color(0x8080D7CF);
  static const Color _reportText = Color(0xFF054544);
  static const String _starGold = 'assets/images/star_gold.png';
  static const String _starSilver = 'assets/images/star_silver.png';
  static const String _likeAtResult = 'assets/images/like_at_result.png';
  static const String _rps2MissionOn =
      'assets/images/icons/rps2_mission_on.png';
  static const String _rps2MissionOff =
      'assets/images/icons/rps2_mission_off.png';

  late final AnimationController _panelMoveController;
  late final AnimationController _keyExpressionSectionEntranceController;
  late final AnimationController _footerFadeController;
  final GlobalKey _panelKey = GlobalKey();
  double? _panelMeasuredHeight;
  Animation<double>? _routeAnimation;
  bool _didAttachRouteAnimation = false;
  bool _hasScheduledPostEntrance = false;
  bool _hasStartedEffectSequence = false;
  bool _effectDone = false;
  bool _showFooterActions = false;
  int _revealedGoldStars = 0;
  bool _reportSubmitted = false;
  bool _isLeavingToOverview = false;

  final AudioPlayer _keyExpressionAudioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _keyExpressionAudioSub;
  int _keyExpressionMegaphoneSeq = 0;
  int? _keyExpressionActiveIndex;
  bool _keyExpressionIsPlaying = false;
  final Set<int> _keyExpressionBookmarkedIndexes = <int>{};
  bool _keyExpressionBookmarkInFlight = false;
  int? _speechFeedbackActiveMsgId;
  bool _speechFeedbackIsPlaying = false;

  RpS2UserHistoryDto? get _s2History =>
      SeriesStateService.instance.cachedUserHistory;

  int get _starResult => _s2History?.starScore ?? 0;

  String get _mainTitle => _s2History?.mainTitle ?? '';

  String get _subTitle => _s2History?.subTitle ?? '';

  int get _words => _s2History?.words ?? 0;

  int get _likePoint => _s2History?.likePoint ?? 0;

  static String _httpErrorBrief(Object error) {
    final text = error.toString();
    final match = RegExp(r'HTTP (\d{3})').firstMatch(text);
    if (match != null) {
      final code = int.parse(match.group(1)!);
      final brief = code >= 500 ? 'Server error' : 'Request failed';
      return 'HTTP $code · $brief';
    }
    return 'Request failed';
  }

  @override
  void initState() {
    super.initState();
    _panelMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    _keyExpressionSectionEntranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _footerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    if (widget.skipEntranceAnimation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _bootstrapSkipEntrance();
        }
      });
    } else {
      _scheduleStarSequence();
    }
  }

  void _bootstrapSkipEntrance() {
    _hasScheduledPostEntrance = true;
    _hasStartedEffectSequence = true;
    final targetGoldStars = (_starResult >= 1 && _starResult <= 3)
        ? _starResult
        : 0;
    setState(() {
      _revealedGoldStars = targetGoldStars;
      _panelMoveController.value = 1.0;
      _effectDone = true;
      _showFooterActions = true;
      _keyExpressionSectionEntranceController.value = 1.0;
      _footerFadeController.value = 1.0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.skipEntranceAnimation) {
      _didAttachRouteAnimation = true;
      return;
    }
    if (_didAttachRouteAnimation) {
      return;
    }
    final route = ModalRoute.of(context);
    final animation = route?.animation;
    if (animation == null) {
      _schedulePostEntranceSequence();
      _didAttachRouteAnimation = true;
      return;
    }
    _routeAnimation = animation;
    animation.addStatusListener(_onRouteAnimationStatusChanged);
    if (animation.status == AnimationStatus.completed) {
      _schedulePostEntranceSequence();
    }
    _didAttachRouteAnimation = true;
  }

  void _onRouteAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _schedulePostEntranceSequence();
    }
  }

  Future<void> _schedulePostEntranceSequence() async {
    if (_hasScheduledPostEntrance) {
      return;
    }
    _hasScheduledPostEntrance = true;
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) {
      return;
    }
    _startPanelMoveAndEffect();
  }

  Future<void> _scheduleStarSequence() async {
    final rawStarResult = _starResult;
    final targetGoldStars = (rawStarResult >= 1 && rawStarResult <= 3)
        ? rawStarResult
        : 0;

    for (var i = 1; i <= targetGoldStars; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) {
        return;
      }
      setState(() => _revealedGoldStars = i);
      Vibration.vibrate(duration: 80);
    }
  }

  void _startPanelMoveAndEffect() {
    if (_hasStartedEffectSequence) {
      return;
    }
    _hasStartedEffectSequence = true;
    _panelMoveController.forward();

    final history = _s2History;
    if (history == null) {
      return;
    }
    _playLikeProgressEffect(
      beforeLikePoint: history.beforeLikePoint ?? 0,
      afterLikePoint: history.afterLikePoint ?? 0,
      beforeLevel: history.beforeLevel ?? 0,
      toBeLevel: history.afterLevel ?? 0,
      beforeProgress: history.beforeProgressPercentage ?? 0,
      toBeProgress: history.afterProgressPercentage ?? 0,
      onEffectCompleted: _onS2LikeProgressEffectCompleted,
    );
  }

  void _playLikeProgressEffect({
    required int beforeLikePoint,
    required int afterLikePoint,
    required int beforeLevel,
    required int toBeLevel,
    required int beforeProgress,
    required int toBeProgress,
    VoidCallback? onEffectCompleted,
  }) {
    LikeProgressEffect.play(
      context,
      params: LikeProgressEffectParams(
        asIsLikePoint: beforeLikePoint,
        toBeLikePoint: afterLikePoint,
        asIsLevel: beforeLevel,
        toBeLevel: toBeLevel,
        asIsProgress: beforeProgress,
        toBeProgress: toBeProgress,
      ),
      onCompleted: () {
        if (!mounted) {
          return;
        }
        setState(() {
          _effectDone = true;
          _showFooterActions = false;
        });
        onEffectCompleted?.call();
      },
    );
  }

  void _onS2LikeProgressEffectCompleted() {
    if (mounted) {
      _keyExpressionSectionEntranceController.forward(from: 0);
    }
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) {
        return;
      }
      _footerFadeController.reset();
      setState(() => _showFooterActions = true);
      _footerFadeController.forward();
    });
  }

  void _scheduleMeasurePanel() {
    if (_panelMeasuredHeight != null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _panelMeasuredHeight != null) {
        return;
      }
      final ctx = _panelKey.currentContext;
      if (ctx == null) {
        return;
      }
      final size = ctx.size;
      if (size == null || size.height <= 0) {
        return;
      }
      setState(() => _panelMeasuredHeight = size.height);
    });
  }

  @override
  void dispose() {
    _keyExpressionAudioSub?.cancel();
    _keyExpressionAudioSub = null;
    unawaited(_keyExpressionAudioPlayer.dispose());
    _routeAnimation?.removeStatusListener(_onRouteAnimationStatusChanged);
    _panelMoveController.dispose();
    _keyExpressionSectionEntranceController.dispose();
    _footerFadeController.dispose();
    super.dispose();
  }

  Future<void> _exitResult(BuildContext context) async {
    if (widget.exitViaPop) {
      Navigator.of(context).pop();
      return;
    }
    await _navigateToOverview(context);
  }

  Future<void> _navigateToOverview(BuildContext context) async {
    if (_isLeavingToOverview) return;
    setState(() => _isLeavingToOverview = true);
    final token = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      try {
        final user = await SudaApiClient.getCurrentUser(accessToken: token);
        if (!mounted) return;
        MainUserSync.instance.notifyUserUpdated(user);
        RoleplayStateService.instance.setUser(user);
      } catch (_) {
        // best-effort: ignore
      }
    }
    if (!mounted) return;
    RoleplayRouter.popToOverview(this.context);
  }

  Widget _buildStarsRow() {
    final leftGold = _revealedGoldStars >= 1;
    final centerGold = _revealedGoldStars >= 2;
    final rightGold = _revealedGoldStars >= 3;
    final leftStar = leftGold ? _starGold : _starSilver;
    final centerStar = centerGold ? _starGold : _starSilver;
    final rightStar = rightGold ? _starGold : _starSilver;

    const double star70Offset = 10.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Transform.rotate(
          angle: -10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(
              leftStar,
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Image.asset(centerStar, width: 80, height: 80, fit: BoxFit.contain),
        const SizedBox(width: 10),
        Transform.rotate(
          angle: 10 * math.pi / 180,
          child: Transform.translate(
            offset: const Offset(0, star70Offset),
            child: Image.asset(
              rightStar,
              width: 70,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMissionIcons() {
    final missionIcons = <Widget>[];

    for (final success in _s2History?.missions ?? const <bool>[]) {
      missionIcons.add(
        Image.asset(
          success ? _rps2MissionOn : _rps2MissionOff,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
        ),
      );
    }

    if (missionIcons.isEmpty) {
      return const Text(
        '—',
        style: TextStyle(color: Colors.white),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: missionIcons,
    );
  }

  Widget _buildLikeText(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final likeValue = '$_likePoint'.padLeft(2, '0');

    return Text(
      likeValue,
      style: theme.bodyLarge?.copyWith(color: Colors.white),
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

  Widget _buildPanel(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final wordsDisplay = '$_words'.padLeft(2, '0');

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),
            _buildStarsRow(),
            const SizedBox(height: 5),
            Text(
              _mainTitle,
              style: theme.headlineLarge?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              _subTitle,
              style: const TextStyle(
                fontFamily: 'ChironGoRoundTC',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontVariations: [FontVariation('wght', 600)],
                color: _mint,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCard(
                  context,
                  title: 'Mission',
                  child: _buildMissionIcons(),
                ),
                const SizedBox(width: 10),
                _buildStatCard(
                  context,
                  title: 'Words',
                  child: Text(
                    wordsDisplay,
                    style: theme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
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
                      Flexible(child: _buildLikeText(context)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewChatButton(BuildContext context, {VoidCallback? onTap}) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 80,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'View Chat',
          style: theme.labelSmall?.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSectionTitleRow(
    BuildContext context, {
    required String title,
    Widget? trailing,
  }) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.headlineSmall?.copyWith(color: Colors.white),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildHorizontalSnapCarousel({
    required BuildContext context,
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
    double bottomPadding = 0,
  }) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    final sw = MediaQuery.sizeOf(context).width;
    final itemW = sw * 0.7;
    const between = 16.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding),
      physics: _LeftSnapScrollPhysics(step: itemW + between),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              SizedBox(
                width: itemW,
                child: itemBuilder(context, i),
              ),
              if (i < itemCount - 1) const SizedBox(width: between),
            ],
            SizedBox(width: sw - itemW - 48),
          ],
        ),
      ),
    );
  }

  Future<AudioSource?> _prepareKeyExpressionAudio({
    required String? cdnYn,
    required String? cdnPath,
    required Uint8List? soundBytes,
  }) async {
    await _keyExpressionAudioPlayer.stop();
    if (cdnYn == 'Y' && cdnPath != null && cdnPath.isNotEmpty) {
      final url = '${AppConfig.cdnBaseUrl}$cdnPath';
      final source = AudioSource.uri(Uri.parse(url));
      await _keyExpressionAudioPlayer.setAudioSource(source);
      return source;
    }
    if (soundBytes != null && soundBytes.isNotEmpty) {
      final source = AudioSource.uri(
        Uri.dataFromBytes(soundBytes, mimeType: 'audio/mpeg'),
      );
      await _keyExpressionAudioPlayer.setAudioSource(source);
      return source;
    }
    return null;
  }

  Future<void> _onKeyExpressionCardTap(int expressionIndex) async {
    _keyExpressionMegaphoneSeq++;
    final seq = _keyExpressionMegaphoneSeq;
    _keyExpressionAudioSub?.cancel();
    _keyExpressionAudioSub = null;
    await _keyExpressionAudioPlayer.stop();

    if (!mounted) {
      return;
    }
    setState(() {
      _keyExpressionActiveIndex = expressionIndex;
      _keyExpressionIsPlaying = false;
      _speechFeedbackActiveMsgId = null;
      _speechFeedbackIsPlaying = false;
    });

    final historyId = _s2History?.id;
    final token = await TokenStorage.loadAccessToken();
    if (!mounted || seq != _keyExpressionMegaphoneSeq) {
      return;
    }

    if (token == null || historyId == null) {
      setState(() {
        _keyExpressionActiveIndex = null;
        _keyExpressionIsPlaying = false;
      });
      return;
    }

    try {
      final tts = await SudaApiClient.getRpS2UserHistoryExpressionSound(
        accessToken: token,
        rpUserHistoryId: historyId,
        expressionIndex: expressionIndex,
      );
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }

      final source = await _prepareKeyExpressionAudio(
        cdnYn: tts.cdnYn,
        cdnPath: tts.cdnPath,
        soundBytes: tts.sound,
      );
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }

      if (source == null) {
        setState(() {
          _keyExpressionActiveIndex = null;
          _keyExpressionIsPlaying = false;
        });
        return;
      }

      setState(() => _keyExpressionIsPlaying = true);

      _keyExpressionAudioSub =
          _keyExpressionAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _keyExpressionAudioSub?.cancel();
          _keyExpressionAudioSub = null;
          if (!mounted || seq != _keyExpressionMegaphoneSeq) {
            return;
          }
          setState(() {
            _keyExpressionActiveIndex = null;
            _keyExpressionIsPlaying = false;
          });
        }
      });
      await _keyExpressionAudioPlayer.play();
    } catch (_) {
      _keyExpressionAudioSub?.cancel();
      _keyExpressionAudioSub = null;
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }
      setState(() {
        _keyExpressionActiveIndex = null;
        _keyExpressionIsPlaying = false;
      });
    }
  }

  Future<void> _onSpeechFeedbackAudioTap(int rpMsgId) async {
    _keyExpressionMegaphoneSeq++;
    final seq = _keyExpressionMegaphoneSeq;
    _keyExpressionAudioSub?.cancel();
    _keyExpressionAudioSub = null;
    await _keyExpressionAudioPlayer.stop();

    if (!mounted) {
      return;
    }
    setState(() {
      _keyExpressionActiveIndex = null;
      _keyExpressionIsPlaying = false;
      _speechFeedbackActiveMsgId = rpMsgId;
      _speechFeedbackIsPlaying = false;
    });

    final historyId = _s2History?.id;
    final token = await TokenStorage.loadAccessToken();
    if (!mounted || seq != _keyExpressionMegaphoneSeq) {
      return;
    }

    if (token == null || historyId == null) {
      setState(() {
        _speechFeedbackActiveMsgId = null;
        _speechFeedbackIsPlaying = false;
      });
      return;
    }

    try {
      final tts = await SudaApiClient.getRpS2UserHistoryMessageAudio(
        accessToken: token,
        rpUserHistoryId: historyId,
        rpMsgId: rpMsgId,
      );
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }

      final source = await _prepareKeyExpressionAudio(
        cdnYn: tts.cdnYn,
        cdnPath: tts.cdnPath,
        soundBytes: tts.sound,
      );
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }

      if (source == null) {
        setState(() {
          _speechFeedbackActiveMsgId = null;
          _speechFeedbackIsPlaying = false;
        });
        return;
      }

      setState(() => _speechFeedbackIsPlaying = true);

      _keyExpressionAudioSub =
          _keyExpressionAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _keyExpressionAudioSub?.cancel();
          _keyExpressionAudioSub = null;
          if (!mounted || seq != _keyExpressionMegaphoneSeq) {
            return;
          }
          setState(() {
            _speechFeedbackActiveMsgId = null;
            _speechFeedbackIsPlaying = false;
          });
        }
      });
      await _keyExpressionAudioPlayer.play();
    } catch (_) {
      _keyExpressionAudioSub?.cancel();
      _keyExpressionAudioSub = null;
      if (!mounted || seq != _keyExpressionMegaphoneSeq) {
        return;
      }
      setState(() {
        _speechFeedbackActiveMsgId = null;
        _speechFeedbackIsPlaying = false;
      });
    }
  }

  Future<void> _onKeyExpressionBookmarkTap(int keyExpressionIndex) async {
    if (_keyExpressionBookmarkInFlight) {
      return;
    }
    _keyExpressionBookmarkInFlight = true;
    try {
      final historyId = _s2History?.id;
      final token = await TokenStorage.loadAccessToken();
      if (!mounted) {
        return;
      }
      if (token == null || historyId == null) {
        DefaultToast.show(context, 'HTTP 401 · Request failed', isError: true);
        return;
      }

      final isBookmarked =
          _keyExpressionBookmarkedIndexes.contains(keyExpressionIndex);

      if (isBookmarked) {
        await SudaApiClient.deleteRpS2UserHistoryExpression(
          accessToken: token,
          rpUserHistoryId: historyId,
          expressionIndex: keyExpressionIndex,
        );
        if (!mounted) {
          return;
        }
        setState(
          () => _keyExpressionBookmarkedIndexes.remove(keyExpressionIndex),
        );
      } else {
        await SudaApiClient.saveRpS2UserHistoryExpression(
          accessToken: token,
          rpUserHistoryId: historyId,
          expressionIndex: keyExpressionIndex,
        );
        if (!mounted) {
          return;
        }
        setState(
          () => _keyExpressionBookmarkedIndexes.add(keyExpressionIndex),
        );
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.expressionSavedToProfile);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      DefaultToast.show(context, _httpErrorBrief(e), isError: true);
    } finally {
      _keyExpressionBookmarkInFlight = false;
    }
  }

  // S2 Review Chat API 연동 전 placeholder.
  void _onS2ViewChatTap() {
    final history = _s2History;
    if (history == null) return;
    Navigator.push(
      context,
      SubScreenRoute(page: ViewChatScreen(history: history)),
    );
  }

  Widget _buildKeyExpressionCarousel(BuildContext context) {
    final items = _s2History?.keyExpressions ?? const <RpS2KeyExpressionVo>[];
    return _buildHorizontalSnapCarousel(
      context: context,
      itemCount: items.length,
      bottomPadding: 20,
      itemBuilder: (context, index) {
        final item = items[index];
        return _KeyExpressionCard(
          item: item,
          fetchingActive:
              _keyExpressionActiveIndex == index && !_keyExpressionIsPlaying,
          playingActive:
              _keyExpressionActiveIndex == index && _keyExpressionIsPlaying,
          bookmarked: _keyExpressionBookmarkedIndexes.contains(index),
          onCardTap: () => unawaited(_onKeyExpressionCardTap(index)),
          onBookmarkTap: () => unawaited(_onKeyExpressionBookmarkTap(index)),
        );
      },
    );
  }

  Widget _buildKeyExpressionLayer(BuildContext context) {
    final items = _s2History?.keyExpressions ?? const <RpS2KeyExpressionVo>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final entrance = CurvedAnimation(
      parent: _keyExpressionSectionEntranceController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(entrance),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: Offset.zero,
        ).animate(entrance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitleRow(context, title: 'Key Expression'),
            const SizedBox(height: 16),
            _buildKeyExpressionCarousel(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeechFeedbackLayer(BuildContext context) {
    final items = _buildSpeechFeedbackRows(context);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final entrance = CurvedAnimation(
      parent: _keyExpressionSectionEntranceController,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(entrance),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: Offset.zero,
        ).animate(entrance),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitleRow(
              context,
              title: 'Speech Feedback',
              trailing: _buildViewChatButton(
                context,
                onTap: _onS2ViewChatTap,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    items[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshUserHistoryAfterSpeechFeedbackUnlock() async {
    final historyId = _s2History?.id;
    if (historyId == null) return;
    final token = await TokenStorage.loadAccessToken();
    if (token == null || token.isEmpty) return;
    final history = await SudaApiClient.getRpS2UserHistory(
      accessToken: token,
      rpUserHistoryId: historyId,
    );
    SeriesStateService.instance.setCachedUserHistory(history);
    if (mounted) setState(() {});
  }

  List<Widget> _buildSpeechFeedbackRows(BuildContext context) {
    final history = _s2History;
    if (history == null) return const [];

    final feedbackLocked = history.feedbackLockedYn == 'Y';
    final speechFeedback = history.speechFeedback;

    if (feedbackLocked) {
      final userMessages = history.messages
          .where(
            (m) =>
                m.role == 'USER' &&
                m.id != null &&
                (m.content?.trim().isNotEmpty ?? false),
          )
          .toList()
        ..sort((a, b) => a.id!.compareTo(b.id!));
      if (userMessages.isEmpty) return const [];

      return [
        for (final message in userMessages)
          _SpeechFeedbackRow(
            feedback: null,
            feedbackLockedYn: history.feedbackLockedYn,
            onUnlockedAfterPaywall: _refreshUserHistoryAfterSpeechFeedbackUnlock,
            userSpeech: message.content ?? '',
            audioInputEnabled: message.audioInputYn == 'Y',
            fetchingActive:
                _speechFeedbackActiveMsgId == message.id &&
                !_speechFeedbackIsPlaying,
            playingActive:
                _speechFeedbackActiveMsgId == message.id &&
                _speechFeedbackIsPlaying,
            onAudioTap: () => unawaited(_onSpeechFeedbackAudioTap(message.id!)),
          ),
      ];
    }

    if (speechFeedback == null || speechFeedback.isEmpty) {
      return const [];
    }

    final messageById = <int, RpS2UserHistoryMsgDto>{
      for (final message in history.messages)
        if (message.id != null) message.id!: message,
    };

    final sortedIds = speechFeedback.keys.toList()..sort();
    final rows = <Widget>[];
    for (final messageId in sortedIds) {
      final message = messageById[messageId];
      final feedback = speechFeedback[messageId];
      if (message == null || feedback == null) {
        continue;
      }

      rows.add(
        _SpeechFeedbackRow(
          feedback: feedback,
          feedbackLockedYn: history.feedbackLockedYn,
          onUnlockedAfterPaywall: _refreshUserHistoryAfterSpeechFeedbackUnlock,
          userSpeech: message.content ?? '',
          audioInputEnabled: message.audioInputYn == 'Y',
          fetchingActive:
              _speechFeedbackActiveMsgId == messageId &&
              !_speechFeedbackIsPlaying,
          playingActive:
              _speechFeedbackActiveMsgId == messageId &&
              _speechFeedbackIsPlaying,
          onAudioTap: () => unawaited(_onSpeechFeedbackAudioTap(messageId)),
        ),
      );
    }
    return rows;
  }

  Widget _buildReportLink(BuildContext context) {
    if (!widget.showReportLink) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: _reportSubmitted
          ? IgnorePointer(
              child: Opacity(
                opacity: 0,
                child: Text(
                  l10n.endingReport,
                  style: theme.bodySmall?.copyWith(color: _reportText),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : GestureDetector(
              onTap: () async {
                final result =
                    await RoleplayRouter.pushResultReport<bool>(context);
                if (result == true && mounted) {
                  setState(() => _reportSubmitted = true);
                }
              },
              child: Text(
                l10n.endingReport,
                style: theme.bodySmall?.copyWith(color: _reportText),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }

  Widget _buildS2FooterActions(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _footerFadeController,
        curve: Curves.easeOut,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 28),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLeavingToOverview
                    ? null
                    : () => _exitResult(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _teal,
                  disabledForegroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 18,
                  ),
                  elevation: 0,
                ),
                child: const Text('Got it!'),
              ),
            ),
          ),
          if (widget.showReportLink) ...[
            const SizedBox(height: 35),
            _buildReportLink(context),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildS2PostEffectBody(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(0, 32, 0, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKeyExpressionLayer(context),
          const SizedBox(height: 28),
          _buildSpeechFeedbackLayer(context),
          if (_showFooterActions) _buildS2FooterActions(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurePanel();
    final moveProgress = Curves.easeOutCubic.transform(_panelMoveController.value);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final targetHeight = (_panelMeasuredHeight ?? screenHeight).clamp(0.0, screenHeight);
    final boxHeight = lerpDouble(screenHeight, targetHeight, moveProgress) ?? screenHeight;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _exitResult(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_topBg, _bottomBg],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: boxHeight,
                    width: double.infinity,
                    child: Container(
                      alignment: Alignment.center,
                      child: KeyedSubtree(
                        key: _panelKey,
                        child: _buildPanel(context),
                      ),
                    ),
                  ),
                  if (_effectDone)
                    Expanded(
                      child: _buildS2PostEffectBody(context),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechFeedbackCardShell extends StatelessWidget {
  const _SpeechFeedbackCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SpeechFeedbackGradeStyle {
  static const Color gradeA = Color(0xFF0CABA8);
  static const Color gradeB = Color(0xFF009628);
  static const Color gradeC = Color(0xFFFFB700);
  static const Color gradeD = Color(0xFFB40000);

  static ({String label, Color color})? resolve(String? grade) {
    switch (grade?.toUpperCase()) {
      case 'A':
        return (label: 'PERFECT', color: gradeA);
      case 'B':
        return (label: 'GOOD', color: gradeB);
      case 'C':
        return (label: 'NEEDS IMPROVEMENT', color: gradeC);
      case 'D':
        return (label: 'UNCLEAR', color: gradeD);
      default:
        return null;
    }
  }
}

class _SpeechFeedbackGradeBadge extends StatelessWidget {
  const _SpeechFeedbackGradeBadge({required this.grade});

  final String? grade;

  @override
  Widget build(BuildContext context) {
    final resolved = _SpeechFeedbackGradeStyle.resolve(grade);
    if (resolved == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    return Text(
      resolved.label,
      textAlign: TextAlign.start,
      style: theme.bodySmall?.copyWith(
        color: resolved.color,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _SpeechFeedbackScoreBarTrack extends StatelessWidget {
  const _SpeechFeedbackScoreBarTrack({
    required this.scoreValue,
    required this.barColor,
  });

  final String? scoreValue;
  final Color barColor;

  static const Color _trackColor = Color(0xFFD9D9D9);

  static double _progressFactor(String? value) {
    switch (value?.toUpperCase()) {
      case 'GOOD':
        return 1.0;
      case 'FAIR':
        return 0.6;
      case 'POOR':
        return 0.2;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressFactor(scoreValue).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(1.5),
      child: SizedBox(
        height: 3,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: _trackColor),
            if (progress > 0)
              FractionallySizedBox(
                widthFactor: progress,
                heightFactor: 1,
                alignment: Alignment.centerLeft,
                child: ColoredBox(
                  color: barColor,
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SpeechFeedbackScorePanel extends StatelessWidget {
  const _SpeechFeedbackScorePanel({
    required this.score,
    required this.barColor,
  });

  final RpS2ScoreVo? score;
  final Color barColor;

  static const Color _labelColor = Color(0xFF777373);
  static const double _labelBarGap = 4;
  static const double _rowGap = 8;
  static const double _rowHeight = 14;
  static const double _columnGap = 24;

  static double _labelColumnWidth(
    BuildContext context,
    List<String> labels,
    TextStyle labelStyle,
  ) {
    var maxWidth = 0.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      maxWidth = math.max(maxWidth, painter.width);
    }
    return maxWidth.ceilToDouble();
  }

  Widget _buildScoreRow({
    required String label,
    required String? value,
    required TextStyle labelStyle,
    required double labelWidth,
  }) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: labelStyle),
            ),
          ),
          const SizedBox(width: _labelBarGap),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _SpeechFeedbackScoreBarTrack(
                scoreValue: value,
                barColor: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn({
    required List<({String label, String? value})> rows,
    required TextStyle labelStyle,
    required double labelWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: _rowGap),
          _buildScoreRow(
            label: rows[i].label,
            value: rows[i].value,
            labelStyle: labelStyle,
            labelWidth: labelWidth,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context).textTheme;
    final labelStyle = theme.labelSmall?.copyWith(color: _labelColor);
    final resolvedLabelStyle = labelStyle ?? const TextStyle(fontSize: 12);
    final l10n = AppLocalizations.of(context)!;
    final leftRows = <({String label, String? value})>[
      (label: l10n.roleplayResultScoreMeaning, value: score!.meaning),
      (label: l10n.roleplayResultScoreVocabulary, value: score!.vocabulary),
    ];
    final rightRows = <({String label, String? value})>[
      (label: l10n.roleplayResultScoreRelevance, value: score!.relevance),
      (label: l10n.roleplayResultScoreGrammar, value: score!.grammar),
    ];
    final allLabels = [
      ...leftRows.map((row) => row.label),
      ...rightRows.map((row) => row.label),
    ];
    final labelWidth = _labelColumnWidth(
      context,
      allLabels,
      resolvedLabelStyle,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildScoreColumn(
            rows: leftRows,
            labelStyle: resolvedLabelStyle,
            labelWidth: labelWidth,
          ),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          child: _buildScoreColumn(
            rows: rightRows,
            labelStyle: resolvedLabelStyle,
            labelWidth: labelWidth,
          ),
        ),
      ],
    );
  }
}

class _SpeechFeedbackFeedbackButton extends StatelessWidget {
  const _SpeechFeedbackFeedbackButton({
    required this.onTap,
    required this.expanded,
  });

  final VoidCallback onTap;
  final bool expanded;

  static const String _clickToFoldPng =
      'assets/images/icons/click_to_fold.png';
  static const Color _teal = Color(0xFF0CABA8);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: _teal, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Feedback',
              style: theme.labelSmall?.copyWith(color: _teal),
            ),
            const SizedBox(width: 4),
            Transform.flip(
              flipY: !expanded,
              child: Image.asset(
                _clickToFoldPng,
                width: 12,
                height: 12,
                fit: BoxFit.contain,
                color: _teal,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeechFeedbackRow extends StatefulWidget {
  const _SpeechFeedbackRow({
    required this.feedback,
    required this.feedbackLockedYn,
    required this.onUnlockedAfterPaywall,
    required this.userSpeech,
    required this.audioInputEnabled,
    required this.fetchingActive,
    required this.playingActive,
    required this.onAudioTap,
  });

  final RpS2UserFeedbackVo? feedback;
  final String feedbackLockedYn;
  final Future<void> Function() onUnlockedAfterPaywall;
  final String userSpeech;
  final bool audioInputEnabled;
  final bool fetchingActive;
  final bool playingActive;
  final VoidCallback onAudioTap;

  @override
  State<_SpeechFeedbackRow> createState() => _SpeechFeedbackRowState();
}

class _SpeechFeedbackRowState extends State<_SpeechFeedbackRow> {
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _megaphoneFillPng =
      'assets/images/icons/megaphone_fill.png';
  static const Color _megaphoneTintActive = Color(0xFF0CABA8);
  static const Color _feedbackTextColor = Color(0xFF635F5F);
  static const Color _scoreSpeechDividerColor = Color(0xFFD9D9D9);

  static const Duration _expandDuration = Duration(milliseconds: 300);
  static const Curve _expandCurve = Curves.easeInOutCubic;

  bool _expanded = false;

  Future<void> _onFeedbackTap() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    final allowed = await ensureSpeechFeedbackUnlocked(
      context,
      feedbackLockedYn: widget.feedbackLockedYn,
      onUnlockedAfterPaywall: widget.onUnlockedAfterPaywall,
    );
    if (!mounted || !allowed) return;
    setState(() => _expanded = true);
  }

  Widget _buildMegaphoneAudioIcon({
    required bool isLoading,
    required bool isPlaying,
  }) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _megaphoneTintActive.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return Image.asset(
      isPlaying ? _megaphoneFillPng : _megaphonePng,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      color: _megaphoneTintActive,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  Widget _buildExpandedFeedbackText(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final feedbackText = widget.feedback?.feedback?.trim();
    final hasFeedback =
        feedbackText != null && feedbackText.isNotEmpty;

    if (!_expanded || !hasFeedback) {
      return const SizedBox(width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        feedbackText,
        style: theme.bodySmall?.copyWith(
          color: _feedbackTextColor,
        ),
      ),
    );
  }

  Widget _buildExpandedScorePanel(BuildContext context) {
    final gradeStyle =
        _SpeechFeedbackGradeStyle.resolve(widget.feedback?.grade);
    if (!_expanded || widget.feedback?.score == null) {
      return const SizedBox(width: double.infinity);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: _SpeechFeedbackScorePanel(
        score: widget.feedback!.score,
        barColor: gradeStyle?.color ?? _SpeechFeedbackGradeStyle.gradeA,
      ),
    );
  }

  Widget _buildScoreSpeechDivider() {
    if (!_expanded || widget.feedback?.score == null) {
      return const SizedBox.shrink();
    }

    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: ColoredBox(
        color: _scoreSpeechDividerColor,
        child: SizedBox(width: double.infinity, height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final showScorePanel = _expanded && widget.feedback?.score != null;

    final card = AnimatedSize(
      duration: _expandDuration,
      curve: _expandCurve,
      alignment: Alignment.topCenter,
      clipBehavior: Clip.hardEdge,
      child: _SpeechFeedbackCardShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SpeechFeedbackGradeBadge(grade: widget.feedback?.grade),
            AnimatedSize(
              duration: _expandDuration,
              curve: _expandCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: _buildExpandedScorePanel(context),
            ),
            AnimatedSize(
              duration: _expandDuration,
              curve: _expandCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: _buildScoreSpeechDivider(),
            ),
            if (!showScorePanel) const SizedBox(height: 8),
            Text(
              widget.userSpeech,
              style: theme.bodyLarge?.copyWith(
                color: _exprTextPrimary,
              ),
            ),
            AnimatedSize(
              duration: _expandDuration,
              curve: _expandCurve,
              alignment: Alignment.topCenter,
              clipBehavior: Clip.hardEdge,
              child: _buildExpandedFeedbackText(context),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: widget.audioInputEnabled
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.end,
              children: [
                if (widget.audioInputEnabled)
                  GestureDetector(
                    onTap: widget.onAudioTap,
                    behavior: HitTestBehavior.opaque,
                    child: _buildMegaphoneAudioIcon(
                      isLoading: widget.fetchingActive,
                      isPlaying: widget.playingActive,
                    ),
                  ),
                _SpeechFeedbackFeedbackButton(
                  onTap: () => unawaited(_onFeedbackTap()),
                  expanded: _expanded,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTap: () => unawaited(_onFeedbackTap()),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _KeyExpressionCard extends StatelessWidget {
  const _KeyExpressionCard({
    required this.item,
    required this.fetchingActive,
    required this.playingActive,
    required this.bookmarked,
    required this.onCardTap,
    required this.onBookmarkTap,
  });

  final RpS2KeyExpressionVo item;
  final bool fetchingActive;
  final bool playingActive;
  final bool bookmarked;
  final VoidCallback onCardTap;
  final VoidCallback onBookmarkTap;

  static const String _checkMintSvg = 'assets/images/icons/check_mint.svg';
  static const String _megaphonePng = 'assets/images/icons/megaphone.png';
  static const String _megaphoneFillPng =
      'assets/images/icons/megaphone_fill.png';
  static const String _bookmarkOffPng = 'assets/images/icons/bookmark_off.png';
  static const String _bookmarkOnPng = 'assets/images/icons/bookmark_on.png';
  static const double _bodyLeftIndent = 30;
  static const Color _megaphoneTintActive = Color(0xFF0CABA8);

  Widget _buildMegaphoneAudioIcon({
    required bool isLoading,
    required bool isPlaying,
  }) {
    if (isLoading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _megaphoneTintActive.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }
    return Image.asset(
      isPlaying ? _megaphoneFillPng : _megaphonePng,
      width: 24,
      height: 24,
      fit: BoxFit.contain,
      color: _megaphoneTintActive,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final keyExpressionEn = SudaJsonUtil.localizedMapText(
      item.keyExpression,
      languageCode: 'en',
    );
    final keyExpressionUserLang = SudaJsonUtil.localizedMapText(
      item.keyExpression,
    );
    final sampleAnswerEn = SudaJsonUtil.localizedMapText(
      item.sampleAnswer,
      languageCode: 'en',
    );
    final sampleAnswerUserLang = SudaJsonUtil.localizedMapText(
      item.sampleAnswer,
    );

    return GestureDetector(
      onTap: onCardTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            color: Colors.white,
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
                          keyExpressionEn,
                          style: theme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _exprTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: _bodyLeftIndent),
                    child: Text(
                      keyExpressionUserLang,
                      style: theme.bodySmall?.copyWith(
                        color: _exprTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    sampleAnswerEn,
                    style: theme.bodyMedium?.copyWith(
                      color: _exprTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sampleAnswerUserLang,
                    style: theme.bodySmall?.copyWith(
                      color: _exprTextSecondary,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMegaphoneAudioIcon(
                        isLoading: fetchingActive,
                        isPlaying: playingActive,
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
      ),
    );
  }
}

class _LeftSnapScrollPhysics extends ScrollPhysics {
  const _LeftSnapScrollPhysics({required this.step, super.parent});

  final double step;

  @override
  _LeftSnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LeftSnapScrollPhysics(step: step, parent: buildParent(ancestor));
  }

  double _targetPixels(ScrollMetrics position, Tolerance tolerance, double velocity) {
    double p = position.pixels / step;
    if (velocity < -tolerance.velocity) {
      p = p.floorToDouble();
    } else if (velocity > tolerance.velocity) {
      p = p.ceilToDouble();
    } else {
      p = p.roundToDouble();
    }
    return (p * step).clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if ((target - position.pixels).abs() < 1e-10) {
      return null;
    }
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
