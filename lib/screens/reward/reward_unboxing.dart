import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../services/main_user_sync.dart';
import '../../utils/full_screen_route.dart';
import '../../utils/cdn_thumbnail.dart';
import '../../widgets/character_rarity_frame.dart';
import '../../widgets/procedural_sunburst.dart';

enum _UnboxingStage { idle, tense, confirmed, unlocking, done }

/// 캐릭터 보상 언박싱 Full Screen.
/// Ranking Reward Claim · Profile 업적/레벨업 등에서 공통 사용.
class RewardUnboxing extends StatefulWidget {
  const RewardUnboxing({
    super.key,
    required this.items,
    this.onNavigateToProfile,
  });

  final List<CharacterRewardClaimDto> items;
  final VoidCallback? onNavigateToProfile;

  static const String routeName = '/reward-unboxing';

  static const _selectBox = 'assets/images/achievement/reward_box.png';
  static const _secretUnlocked =
      'assets/images/achievement/secret_unlocked.png';
  static const _closeIcon = 'assets/images/icons/close.svg';

  /// rarity closed 536×592, opened 648×508.
  static const _closedBoxAspect = 592 / 536;
  static const _openedOverClosedWidth = 648 / 536;
  /// opened 박스 에셋 표시 배율(닫힌 박스 대비).
  static const _openedDisplayScale = 1.10;

  static const _textShadow = Shadow(
    offset: Offset(0, 4),
    blurRadius: 4,
    color: Color(0x40000000),
  );

  static Future<T?> push<T>(
    BuildContext context,
    List<CharacterRewardClaimDto> items, {
    VoidCallback? onNavigateToProfile,
  }) {
    return Navigator.of(context).push(
      FullScreenRoute<T>(
        page: RewardUnboxing(
          items: items,
          onNavigateToProfile: onNavigateToProfile,
        ),
        transition: FullScreenTransition.fade,
      ),
    );
  }

  /// `characterImgPath` CDN 원본 프리로드. 실패는 무시.
  static Future<void> preload(
    BuildContext context,
    List<CharacterRewardClaimDto> items,
  ) async {
    final futures = <Future<void>>[];
    for (final item in items) {
      final path = item.characterImgPath.trim();
      if (path.isEmpty) continue;
      final url = CdnThumbUrl.original(path);
      futures.add(() async {
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (_) {}
      }());
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  static String _closedBoxAsset(String rarity) {
    switch (CharacterRarityFrame.normalize(rarity)) {
      case 'RARE':
        return 'assets/images/achievement/reward_box_rare.png';
      case 'EPIC':
        return 'assets/images/achievement/reward_box_epic.png';
      default:
        return 'assets/images/achievement/reward_box_normal.png';
    }
  }

  static String _openedBoxAsset(String rarity) {
    switch (CharacterRarityFrame.normalize(rarity)) {
      case 'RARE':
        return 'assets/images/achievement/reward_box_rare_opened.png';
      case 'EPIC':
        return 'assets/images/achievement/reward_box_epic_opened.png';
      default:
        return 'assets/images/achievement/reward_box_normal_opened.png';
    }
  }

  @override
  State<RewardUnboxing> createState() => _RewardUnboxingState();
}

class _RewardUnboxingState extends State<RewardUnboxing>
    with TickerProviderStateMixin {
  int _index = 0;
  _UnboxingStage _stage = _UnboxingStage.idle;
  bool _settingProfile = false;
  int _wobbleSign = 1;

  late final AnimationController _wobbleController;
  late final AnimationController _tenseWobbleController;
  late final AnimationController _maskController;
  late final AnimationController _confirmController;
  late final AnimationController _uiController;
  late final AnimationController _revealController;
  late final AnimationController _secretController;

  late final Animation<double> _wobble;

  Timer? _tenseTimer;
  Timer? _tenseVibeTimer;
  Timer? _uiTimer;
  Timer? _unlockTimer;
  Timer? _wobbleVibeTimer;

  CharacterRewardClaimDto? get _item {
    if (widget.items.isEmpty) return null;
    if (_index < 0 || _index >= widget.items.length) return null;
    return widget.items[_index];
  }

  bool get _isLast =>
      widget.items.isNotEmpty && _index >= widget.items.length - 1;

  bool get _canClose => _isLast && _stage == _UnboxingStage.done;

  int get _displayTotal {
    final total = _item?.totalImgCount ?? 0;
    return total <= 3 ? 3 : total;
  }

  /// 확정 후 캐릭터 reveal 최종 위치·opened 박스 기하 (상단 카피·secret과 공유).
  _CharacterRevealLayout _characterRevealLayout(Size size) {
    final endSize = size.width * 0.50;
    final boxW = size.width * 0.55;
    final boxH = boxW * RewardUnboxing._closedBoxAspect;
    final boxTop = (size.height - boxH) / 2;
    final openedW =
        boxW *
        RewardUnboxing._openedOverClosedWidth *
        RewardUnboxing._openedDisplayScale;
    final openedH = openedW * (508 / 648);
    final openedTop = boxTop + (boxH - openedH) / 2;
    // opened 상단이 캐릭터 원형 영역 상단에서 ~15% 아래(뚜껑을 약간 덮음).
    const lidOverlapFraction = 0.15;
    final lidBasedY = openedTop + endSize * (0.5 - lidOverlapFraction);
    final legacyY = size.height * 0.25;
    final endY = (legacyY + lidBasedY) / 2;
    return _CharacterRevealLayout(
      endSize: endSize,
      endCenter: Offset(size.width / 2, endY),
      openedTop: openedTop,
    );
  }

  @override
  void initState() {
    super.initState();
    _wobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _wobble =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.12), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.12), weight: 12),
          TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.10), weight: 10),
          TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.06), weight: 10),
          TweenSequenceItem(tween: Tween(begin: -0.06, end: 0.0), weight: 10),
          TweenSequenceItem(tween: ConstantTween(0.0), weight: 48),
        ]).animate(
          CurvedAnimation(parent: _wobbleController, curve: Curves.easeInOut),
        );
    _wobbleController.addStatusListener(_onWobbleStatus);
    _tenseWobbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _maskController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _confirmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _uiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _secretController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _startIdleWobble();
  }

  @override
  void dispose() {
    _cancelTimers();
    _wobbleController.removeStatusListener(_onWobbleStatus);
    _wobbleController.dispose();
    _tenseWobbleController.dispose();
    _maskController.dispose();
    _confirmController.dispose();
    _uiController.dispose();
    _revealController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  void _onWobbleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_stage != _UnboxingStage.idle) return;
    _wobbleSign = -_wobbleSign;
    _wobbleController.forward(from: 0);
  }

  void _startIdleWobble() {
    _wobbleVibeTimer?.cancel();
    _wobbleController
      ..stop()
      ..value = 0;
    _wobbleController.forward();
    _vibeWeak();
    _wobbleVibeTimer = Timer.periodic(const Duration(milliseconds: 280), (t) {
      if (!mounted || _stage != _UnboxingStage.idle) {
        t.cancel();
        return;
      }
      if (_wobbleController.value < 0.48) _vibeWeak();
    });
  }

  void _cancelTimers() {
    _tenseTimer?.cancel();
    _tenseVibeTimer?.cancel();
    _uiTimer?.cancel();
    _unlockTimer?.cancel();
    _wobbleVibeTimer?.cancel();
  }

  Future<void> _vibeWeak() async {
    try {
      await Vibration.vibrate(duration: 35, amplitude: 64);
    } catch (_) {}
  }

  Future<void> _vibeStrong() async {
    try {
      await Vibration.vibrate(duration: 90, amplitude: 255);
    } catch (_) {}
  }

  Future<void> _vibeStrongTwice() async {
    await _vibeStrong();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await _vibeStrong();
  }

  void _onBoxTap() {
    if (_stage != _UnboxingStage.idle) return;
    _wobbleVibeTimer?.cancel();
    _wobbleController.stop();
    setState(() => _stage = _UnboxingStage.tense);
    _maskController.forward(from: 0);
    _tenseWobbleController.repeat(reverse: true);
    _tenseVibeTimer?.cancel();
    _tenseVibeTimer = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (!mounted || _stage != _UnboxingStage.tense) return;
      _vibeWeak();
    });
    _tenseTimer?.cancel();
    _tenseTimer = Timer(const Duration(milliseconds: 1500), _onConfirm);
  }

  void _onConfirm() {
    if (!mounted || _stage != _UnboxingStage.tense) return;
    _tenseVibeTimer?.cancel();
    _tenseWobbleController
      ..stop()
      ..value = 0.5;
    setState(() => _stage = _UnboxingStage.confirmed);
    _confirmController.forward(from: 0);
    _vibeStrong();
    _uiTimer?.cancel();
    _uiTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _uiController.forward(from: 0);
    });
    _unlockTimer?.cancel();
    _unlockTimer = Timer(const Duration(milliseconds: 1000), _onUnlock);
  }

  void _onUnlock() {
    if (!mounted) return;
    if (_stage != _UnboxingStage.confirmed) return;
    setState(() => _stage = _UnboxingStage.unlocking);
    unawaited(_vibeStrongTwice());
    _revealController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _stage = _UnboxingStage.done);
      if (_item?.currentImgProgress == _displayTotal) {
        _secretController.forward(from: 0);
      }
    });
  }

  void _onOpenNext() {
    if (_isLast || _stage != _UnboxingStage.done) return;
    _cancelTimers();
    _maskController.value = 0;
    _confirmController.value = 0;
    _uiController.value = 0;
    _revealController.value = 0;
    _secretController.value = 0;
    _tenseWobbleController.value = 0;
    setState(() {
      _index += 1;
      _stage = _UnboxingStage.idle;
      _wobbleSign = 1;
    });
    _startIdleWobble();
  }

  Future<void> _onSetAsProfile() async {
    if (_settingProfile || !_isLast) return;
    setState(() => _settingProfile = true);
    final path = _item?.characterImgPath.trim() ?? '';
    final rarity = (_item?.characterRarity ?? '').trim().toUpperCase();
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null && token.isNotEmpty) {
        if (path.isNotEmpty &&
            (rarity == 'NORMAL' || rarity == 'RARE' || rarity == 'EPIC')) {
          await SudaApiClient.updateProfileImage(
            accessToken: token,
            type: rarity,
            value: path,
          );
        }
        final updated = await SudaApiClient.getCurrentUser(accessToken: token);
        MainUserSync.instance.notifyUserUpdated(updated);
      }
    } catch (err) {
      debugPrint('[DEBUG] reward unboxing set profile failed: $err');
    }
    if (!mounted) return;
    widget.onNavigateToProfile?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _close() {
    if (!_canClose) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canClose,
      child: Scaffold(
        backgroundColor: const Color(0xFF80D7CF),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(child: _buildBackground()),
                const Positioned.fill(
                  child: ProceduralSunburstOverlay(
                    focal: SunburstFocal.center,
                  ),
                ),
                Positioned.fill(child: _buildHint()),
                _buildBox(size),
                _buildCharacter(size),
                _buildTopCopy(size),
                _buildSecret(size),
                _buildBottomUi(size),
                _buildCloseButton(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return AnimatedBuilder(
      animation: _confirmController,
      builder: (context, _) {
        return Stack(
          fit: StackFit.expand,
          children: [
            const _UnboxingGradient(spec: _BgSpec.select),
            Opacity(
              opacity: _confirmController.value,
              child: _UnboxingGradient(
                spec: _BgSpec.forRarity(_item?.characterRarity),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHint() {
    final l10n = AppLocalizations.of(context)!;
    final visible = _stage == _UnboxingStage.idle;
    return IgnorePointer(
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1 : 0,
        child: Align(
          alignment: const Alignment(0, 0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              l10n.rewardUnboxingTapToOpen,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBox(Size size) {
    final boxW = size.width * 0.55;
    final boxH = boxW * RewardUnboxing._closedBoxAspect;
    final boxLeft = (size.width - boxW) / 2;
    final boxTop = (size.height - boxH) / 2;
    final openedW =
        boxW *
        RewardUnboxing._openedOverClosedWidth *
        RewardUnboxing._openedDisplayScale;
    final openedH = openedW * (508 / 648);
    final openedTop = boxTop + (boxH - openedH) / 2;
    final openedLeft = boxLeft + (boxW - openedW) / 2;
    final rarity = _item?.characterRarity ?? 'NORMAL';
    final tappable = _stage == _UnboxingStage.idle;

    Widget wobble(Widget child) {
      final tense = _stage == _UnboxingStage.tense;
      return AnimatedBuilder(
        animation: tense ? _tenseWobbleController : _wobble,
        builder: (context, _) {
          final angle = tense
              ? (_tenseWobbleController.value * 2 - 1) * 0.14
              : _wobble.value * _wobbleSign;
          return Transform.rotate(angle: angle, child: child);
        },
      );
    }

    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: boxLeft,
            top: boxTop,
            width: boxW,
            height: boxH,
            child: IgnorePointer(
              ignoring: !tappable,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onBoxTap,
                child: wobble(
                  _MaskedBox(
                    asset: RewardUnboxing._selectBox,
                    mask: _maskController,
                    hidden: _confirmController,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: boxLeft,
            top: boxTop,
            width: boxW,
            height: boxH,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _confirmController,
                  _revealController,
                ]),
                builder: (context, child) {
                  final opacity =
                      _confirmController.value * (1 - _revealController.value);
                  return Opacity(opacity: opacity, child: child);
                },
                child: Image.asset(
                  RewardUnboxing._closedBoxAsset(rarity),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          Positioned(
            left: openedLeft,
            top: openedTop,
            width: openedW,
            height: openedH,
            child: IgnorePointer(
              child: FadeTransition(
                opacity: _revealController,
                child: Image.asset(
                  RewardUnboxing._openedBoxAsset(rarity),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacter(Size size) {
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    final layout = _characterRevealLayout(size);
    final boxW = size.width * 0.55;
    final startSize = boxW * 0.38;
    final endSize = layout.endSize;
    final start = Offset(size.width / 2, size.height / 2);
    final end = layout.endCenter;
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _revealController,
        builder: (context, _) {
          if (_revealController.value == 0 &&
              _stage != _UnboxingStage.unlocking &&
              _stage != _UnboxingStage.done) {
            return const SizedBox.shrink();
          }
          final t = Curves.easeOutCubic.transform(_revealController.value);
          final pos = Offset.lerp(start, end, t)!;
          final charSize = startSize + (endSize - startSize) * t;
          final path = item.characterImgPath.trim();
          final inner = (charSize - 20).clamp(1.0, charSize);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: pos.dx - charSize / 2,
                top: pos.dy - charSize / 2,
                width: charSize,
                height: charSize,
                child: IgnorePointer(
                  child: CharacterRarityFrame(
                    rarity: item.characterRarity,
                    size: charSize,
                    child: path.isEmpty
                        ? const ColoredBox(color: Color(0x33FFFFFF))
                        : CachedNetworkImage(
                            imageUrl: CdnThumbUrl.original(path),
                            width: inner,
                            height: inner,
                            fit: BoxFit.cover,
                            fadeInDuration: Duration.zero,
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopCopy(Size size) {
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final layout = _characterRevealLayout(size);
    final endSize = layout.endSize;
    final characterTop = layout.endCenter.dy - endSize / 2;
    final topPad = MediaQuery.paddingOf(context).top;
    final shadowStyle = const TextStyle(
      color: Colors.white,
      shadows: [RewardUnboxing._textShadow],
    );
    return Positioned(
      left: 24,
      right: 24,
      top: topPad,
      height: math.max(0, characterTop - topPad),
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _uiController,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isNewCharacter)
                  Text(
                    l10n.rewardUnboxingNewCharacter,
                    textAlign: TextAlign.center,
                    style: theme.bodySmall?.merge(shadowStyle),
                  ),
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.rewardUnboxingYouGot(
                          item.characterName.trim().isEmpty
                              ? '—'
                              : item.characterName,
                        ),
                        textAlign: TextAlign.center,
                        style: theme.headlineLarge?.merge(shadowStyle),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          CharacterRarityFrame.englishLabel(
                            item.characterRarity,
                          ),
                          style: theme.bodySmall?.merge(shadowStyle),
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecret(Size size) {
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    if (item.currentImgProgress != _displayTotal) {
      return const SizedBox.shrink();
    }
    final layout = _characterRevealLayout(size);
    final characterBottom = layout.endCenter.dy + layout.endSize / 2;
    final baseMidY = (characterBottom + layout.openedTop) / 2;
    // 변경 전(base) ↔ 중앙 쪽(0.35) 보간의 중간(0.175).
    final midY =
        baseMidY + (layout.endCenter.dy - baseMidY) * 0.175;
    final secretW = size.width * 0.40;
    final secretH = secretW * (315 / 436);
    // 변경 전(right=width/2 → left=width/2−W) ↔ left=width/2−0.52W 의 중간(0.76W).
    final secretLeft = size.width * 0.5 - secretW * 0.76;
    return Positioned(
      left: secretLeft,
      top: midY - secretH / 2,
      width: secretW,
      height: secretH,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _secretController,
          child: Image.asset(
            RewardUnboxing._secretUnlocked,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomUi(Size size) {
    final item = _item;
    if (item == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final boxW = size.width * 0.55;
    final boxH = boxW * RewardUnboxing._closedBoxAspect;
    final openedW =
        boxW *
        RewardUnboxing._openedOverClosedWidth *
        RewardUnboxing._openedDisplayScale;
    final openedH = openedW * (508 / 648);
    final boxTop = (size.height - boxH) / 2;
    final openedTop = boxTop + (boxH - openedH) / 2;
    final openedBottom = openedTop + openedH;
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 24,
      right: 24,
      top: openedBottom,
      bottom: bottomPad,
      child: AnimatedBuilder(
        animation: _uiController,
        builder: (context, child) {
          return IgnorePointer(
            ignoring: _uiController.value == 0,
            child: child,
          );
        },
        child: FadeTransition(
          opacity: _uiController,
          child: Column(
            children: [
              const Spacer(),
              Text(
                '${item.currentImgProgress} / $_displayTotal',
                textAlign: TextAlign.center,
                style: theme.headlineMedium?.copyWith(
                  color: Colors.white,
                  shadows: const [RewardUnboxing._textShadow],
                ),
              ),
              const SizedBox(height: 20),
              if (!_isLast)
                _UnboxingCtaButton(
                  label: 'Open Next Box',
                  onPressed: _stage == _UnboxingStage.done ? _onOpenNext : null,
                )
              else ...[
                _UnboxingCtaButton(
                  label: l10n.rewardUnboxingSetAsProfile,
                  onPressed: _stage == _UnboxingStage.done
                      ? _onSetAsProfile
                      : null,
                  submitting: _settingProfile,
                ),
                const SizedBox(height: 12),
                _UnboxingCtaButton(
                  label: l10n.rewardUnboxingViewCharacter,
                  onPressed: _stage == _UnboxingStage.done ? () {} : null,
                ),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton() {
    if (!_canClose) return const SizedBox.shrink();
    final top = MediaQuery.paddingOf(context).top;
    return PositionedDirectional(
      top: top + 16,
      start: 16,
      child: GestureDetector(
        onTap: _close,
        child: Container(
          width: 40,
          height: 40,
          color: Colors.transparent,
          child: Center(
            child: SvgPicture.asset(
              RewardUnboxing._closeIcon,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _BgSpec {
  const _BgSpec({required this.colors, required this.stops});

  final List<Color> colors;
  final List<double> stops;

  static const select = _BgSpec(
    colors: [Color(0xFFFF00A6), Color(0xFF8A38F5), Color(0xFFFF00A6)],
    stops: [0.0, 0.5, 1.0],
  );

  static const normal = _BgSpec(
    colors: [Color(0xFF80D7CF), Color(0xFF80D7CF)],
    stops: [0.0, 1.0],
  );

  static const rare = _BgSpec(
    colors: [Color(0xCC9A30EA), Color(0xFF80D7CF), Color(0xFF8A38F5)],
    stops: [0.0, 0.5, 1.0],
  );

  static const epic = _BgSpec(
    colors: [
      Color(0x33FF00A6),
      Color(0xDE9A30EA),
      Color(0xFF80D7CF),
      Color(0xFF8A38F5),
      Color(0x33FF00A6),
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  static _BgSpec forRarity(String? rarity) {
    switch (CharacterRarityFrame.normalize(rarity ?? '')) {
      case 'RARE':
        return rare;
      case 'EPIC':
        return epic;
      default:
        return normal;
    }
  }
}

class _CharacterRevealLayout {
  const _CharacterRevealLayout({
    required this.endSize,
    required this.endCenter,
    required this.openedTop,
  });

  final double endSize;
  final Offset endCenter;
  final double openedTop;
}

class _UnboxingGradient extends StatelessWidget {
  const _UnboxingGradient({required this.spec});

  final _BgSpec spec;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: spec.colors,
          stops: spec.stops,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MaskedBox extends StatelessWidget {
  const _MaskedBox({
    required this.asset,
    required this.mask,
    required this.hidden,
  });

  final String asset;
  final Animation<double> mask;
  final Animation<double> hidden;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([mask, hidden]),
      builder: (context, _) {
        final img = Image.asset(
          asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        );
        return Opacity(
          opacity: 1 - hidden.value,
          child: Stack(
            fit: StackFit.expand,
            children: [
              img,
              Opacity(
                opacity: mask.value,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.black,
                    BlendMode.srcATop,
                  ),
                  child: img,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UnboxingCtaButton extends StatelessWidget {
  const _UnboxingCtaButton({
    required this.label,
    this.onPressed,
    this.submitting = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final elevated = Theme.of(context).elevatedButtonTheme.style;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(198, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ).merge(elevated),
        child: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.black,
                ),
              )
            : Text(label),
      ),
    );
  }
}
