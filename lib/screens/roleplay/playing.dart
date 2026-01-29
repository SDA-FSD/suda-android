import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/roleplay_scaffold.dart';
import '../../routes/roleplay_router.dart';
import '../../services/roleplay_state_service.dart';
import '../../utils/suda_json_util.dart';

/// Roleplay Playing Screen (Full Screen)
/// 
/// Roleplay 진행 중 화면
class RoleplayPlayingScreen extends StatefulWidget {
  final bool showCloseButton;

  const RoleplayPlayingScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  State<RoleplayPlayingScreen> createState() => _RoleplayPlayingScreenState();
}

class _RoleplayPlayingScreenState extends State<RoleplayPlayingScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _remainingSeconds = 0;
  int _totalSteps = 0;
  int _currentStep = 0;
  final Map<int, _MissionStatus> _missionStatuses = {};
  final Map<int, _MissionStatus> _animatingSteps = {};
  Timer? _hoverTimer;
  int _cycleToken = 0;
  double _dragOffsetX = 0;
  bool _isCancelHovered = false;
  bool _isPointerDown = false;
  _MicButtonState _micState = _MicButtonState.defaultState;
  _InputMode _inputMode = _InputMode.recording;
  final TextEditingController _typingController = TextEditingController();
  int _typingToken = 0;
  bool _isTypingEnabled = true;
  late final AnimationController _loadingRotationController;
  late final AnimationController _arrowPulseController;

  @override
  void initState() {
    super.initState();
    _initializeCountdown();
    _initializeProgressState();
    _loadingRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _arrowPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _hoverTimer?.cancel();
    _typingController.dispose();
    _loadingRotationController.dispose();
    _arrowPulseController.dispose();
    super.dispose();
  }

  void _initializeCountdown() {
    final roleplay = RoleplayStateService.instance.overview?.roleplay;
    _remainingSeconds = _parseDurationSeconds(roleplay?.duration);
    if (_remainingSeconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        _timer?.cancel();
        _timer = null;
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _timer?.cancel();
          _timer = null;
        }
      });
    });
  }

  void _initializeProgressState() {
    final overview = RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    final roleId = RoleplayStateService.instance.roleId;
    final selectedRole = roleplay?.roleList?.firstWhere(
      (r) => r.id == roleId,
      orElse: () => roleplay.roleList!.first,
    );

    _totalSteps = selectedRole?.scenarioFlow?.length ?? 0;
    _currentStep = 0;
    _missionStatuses.clear();

    for (final mission in selectedRole?.missionList ?? const []) {
      final index = mission.scenarioFlowIndex;
      if (index != null) {
        _missionStatuses[index] = _MissionStatus.ready;
      }
    }
  }


  int _parseDurationSeconds(String? raw) {
    if (raw == null || raw.isEmpty) return 0;
    final parts = raw.split(':');
    if (parts.length < 3) return 0;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    final seconds = int.tryParse(parts[2]) ?? 0;
    return (hours * 3600) + (minutes * 60) + seconds;
  }

  String _formatRemaining() {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  int get _maxStepIndex => _totalSteps <= 0 ? 0 : _totalSteps - 1;

  void _setProgressToStep(int stepIndex) {
    if (!mounted) return;
    final clamped = stepIndex.clamp(0, _maxStepIndex);
    setState(() {
      _currentStep = clamped;
    });
  }

  void _setMissionSuccess(int stepIndex) {
    if (!_missionStatuses.containsKey(stepIndex)) return;
    final previous = _missionStatuses[stepIndex];
    setState(() {
      _missionStatuses[stepIndex] = _MissionStatus.success;
      if (previous != _MissionStatus.success) {
        _animatingSteps[stepIndex] = _MissionStatus.success;
      }
    });
  }

  void _setMissionFailed(int stepIndex) {
    if (!_missionStatuses.containsKey(stepIndex)) return;
    final previous = _missionStatuses[stepIndex];
    setState(() {
      _missionStatuses[stepIndex] = _MissionStatus.failed;
      if (previous != _MissionStatus.failed) {
        _animatingSteps[stepIndex] = _MissionStatus.failed;
      }
    });
  }

  bool get _isMicInteractive =>
      _micState == _MicButtonState.defaultState ||
      _micState == _MicButtonState.hover ||
      _micState == _MicButtonState.pressed;

  void _setMicState(_MicButtonState next, {bool resetDrag = false}) {
    if (_micState == next) return;
    setState(() {
      _micState = next;
      if (resetDrag) {
        _dragOffsetX = 0;
        _isCancelHovered = false;
      }
    });
    _syncLoadingAnimation();
  }

  void _syncLoadingAnimation() {
    if (_micState == _MicButtonState.loading) {
      if (!_loadingRotationController.isAnimating) {
        _loadingRotationController.repeat();
      }
    } else {
      if (_loadingRotationController.isAnimating) {
        _loadingRotationController.stop();
      }
      _loadingRotationController.reset();
    }
  }

  void _handleMicTapDown(TapDownDetails details) {
    if (_micState != _MicButtonState.defaultState) return;
    _cycleToken += 1;
    _isPointerDown = true;
    _hoverTimer?.cancel();
    _setMicState(_MicButtonState.hover, resetDrag: true);
    _hoverTimer = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      if (_isPointerDown && _micState == _MicButtonState.hover) {
        _setMicState(_MicButtonState.pressed);
      }
    });
  }

  void _handleMicPanStart(DragStartDetails details) {
    if (_micState == _MicButtonState.loading ||
        _micState == _MicButtonState.disabled) {
      return;
    }
    _isPointerDown = true;
    _hoverTimer?.cancel();
    if (_micState == _MicButtonState.hover ||
        _micState == _MicButtonState.defaultState) {
      _setMicState(_MicButtonState.pressed, resetDrag: true);
    }
  }

  void _handleMicPanUpdate({
    required double deltaX,
    required double maxLeftOffset,
    required double cancelRightX,
    required double cancelCenterX,
    required double centerX,
  }) {
    if (_micState != _MicButtonState.pressed) return;
    final nextOffset = (_dragOffsetX + deltaX).clamp(maxLeftOffset, 0.0);
    final buttonLeft = centerX + nextOffset - (_micPressedSize / 2);
    final cancelHovered = buttonLeft <= cancelCenterX;
    setState(() {
      _dragOffsetX = nextOffset;
      _isCancelHovered = cancelHovered;
    });
  }

  void _handleMicTapCancel() {
    _isPointerDown = false;
    _hoverTimer?.cancel();
    if (_micState == _MicButtonState.hover ||
        _micState == _MicButtonState.pressed) {
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
    }
  }

  void _handleMicTapUp() {
    _isPointerDown = false;
    _hoverTimer?.cancel();
    if (_micState == _MicButtonState.hover) {
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      return;
    }
    if (_micState != _MicButtonState.pressed) return;
    if (_isCancelHovered) {
      _cancelRecording();
      _setMicState(_MicButtonState.defaultState, resetDrag: true);
      return;
    }
    _startLoadingCycle();
  }

  void _startLoadingCycle() async {
    final token = ++_cycleToken;
    _setMicState(_MicButtonState.loading, resetDrag: true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || token != _cycleToken) return;
    _setMicState(_MicButtonState.disabled, resetDrag: true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted || token != _cycleToken) return;
    _setMicState(_MicButtonState.defaultState, resetDrag: true);
  }

  void _handleSend() {
    if (!_isTypingEnabled) return;
    setState(() {
      _isTypingEnabled = false;
      _typingController.clear();
    });
    final token = ++_typingToken;
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || token != _typingToken) return;
      setState(() {
        _isTypingEnabled = true;
      });
    });
  }

  void _cancelRecording() {
    // placeholder for cancel flow; keep state reset in caller
  }

  TextStyle _cancelTextStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    return (baseStyle ?? const TextStyle()).copyWith(
      color: const Color(0xFF0CABA8),
    );
  }

  double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return painter.size.width;
  }

  String _micAssetForState(_MicButtonState state, bool cancelHover) {
    if (state == _MicButtonState.pressed && cancelHover) {
      return 'assets/images/buttons/mic_btn_default.png';
    }
    return switch (state) {
      _MicButtonState.defaultState => 'assets/images/buttons/mic_btn_default.png',
      _MicButtonState.hover => 'assets/images/buttons/mic_btn_hover.png',
      _MicButtonState.pressed => 'assets/images/buttons/mic_btn_pressed.png',
      _MicButtonState.loading => 'assets/images/buttons/mic_btn_loading.png',
      _MicButtonState.disabled => 'assets/images/buttons/mic_btn_disabled.png',
    };
  }

  double _micSizeForState(_MicButtonState state, bool cancelHover) {
    if (state == _MicButtonState.pressed && cancelHover) {
      return _micDefaultSize;
    }
    return switch (state) {
      _MicButtonState.defaultState => _micDefaultSize,
      _MicButtonState.hover => _micHoverSize,
      _MicButtonState.pressed => _micPressedSize,
      _MicButtonState.loading => _micDefaultSize,
      _MicButtonState.disabled => _micDefaultSize,
    };
  }

  Widget _buildMicButton() {
    final cancelHover = _micState == _MicButtonState.pressed && _isCancelHovered;
    final size = _micSizeForState(_micState, cancelHover);
    final asset = _micAssetForState(_micState, cancelHover);
    final image = Image.asset(
      asset,
      width: size,
      height: size,
    );
    final content = _micState == _MicButtonState.loading
        ? RotationTransition(
            turns: _loadingRotationController,
            child: image,
          )
        : image;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: content,
    );
  }

  Widget _buildDragArrows({
    required double cancelRightX,
    required double areaHeight,
    required double anchorLeftX,
  }) {
    const iconSize = 16.0;
    const gap = 5.0;
    const count = 3;
    final groupWidth = (iconSize * count) + (gap * (count - 1));
    final availableWidth = anchorLeftX - cancelRightX;
    if (availableWidth <= groupWidth) {
      return const SizedBox.shrink();
    }
    final groupLeft =
        cancelRightX + ((availableWidth - groupWidth) / 2);

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _arrowPulseController,
        builder: (context, child) {
          final shift = _arrowPulseController.value;
          return Stack(
            children: [
              Positioned(
                left: groupLeft,
                top: (areaHeight - iconSize) / 2,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white,
                        Colors.white.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                      transform: _SlidingGradientTransform(-shift),
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.modulate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(count, (index) {
                      if (index > 0) {
                        return Padding(
                          padding: const EdgeInsets.only(left: gap),
                          child: SvgPicture.asset(
                            'assets/images/icons/header_arrow_back.svg',
                            width: iconSize,
                            height: iconSize,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                        );
                      }
                      return SvgPicture.asset(
                        'assets/images/icons/header_arrow_back.svg',
                        width: iconSize,
                        height: iconSize,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
    return SizedBox(
      height: 18,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const iconSize = 18.0;
          final barWidth = (width - iconSize).clamp(0.0, width);
          final barLeft = (width - barWidth) / 2;
          final maxIndex = _maxStepIndex;
          final progressRatio =
              maxIndex <= 0 ? 0.0 : (_currentStep / maxIndex).clamp(0.0, 1.0);
          final progressWidth = barWidth * progressRatio;
          const barHeight = 3.0;
          final barTop = (18 - barHeight) / 2;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: barTop,
                left: barLeft,
                width: barWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: barHeight,
                    color: const Color(0xFF635F5F),
                  ),
                ),
              ),
              Positioned(
                top: barTop,
                left: barLeft,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedContainer(
                    height: barHeight,
                    width: progressWidth,
                    color: const Color(0xFFFFAAE1),
                    duration: const Duration(milliseconds: 500),
                  ),
                ),
              ),
              for (final entry in _missionStatuses.entries)
                _buildMissionIcon(
                  barLeft: barLeft,
                  barWidth: barWidth,
                  maxIndex: maxIndex,
                  stepIndex: entry.key,
                  status: entry.value,
                  iconSize: iconSize,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMissionIcon({
    required double barLeft,
    required double barWidth,
    required int maxIndex,
    required int stepIndex,
    required _MissionStatus status,
    required double iconSize,
  }) {
    final ratio = maxIndex <= 0 ? 0.0 : (stepIndex / maxIndex).clamp(0.0, 1.0);
    final left = barLeft + (barWidth * ratio) - (iconSize / 2);
    final asset = switch (status) {
      _MissionStatus.ready => 'assets/images/icons/mission_ready.png',
      _MissionStatus.success => 'assets/images/icons/mission_succeeded.png',
      _MissionStatus.failed => 'assets/images/icons/mission_failed.png',
    };
    final shouldAnimate = _animatingSteps.containsKey(stepIndex) &&
        _animatingSteps[stepIndex] == status;

    return Positioned(
      left: left,
      top: 0,
      child: _MissionIconScale(
        asset: asset,
        size: iconSize,
        animate: shouldAnimate,
        onCompleted: () {
          if (!mounted) return;
          setState(() {
            _animatingSteps.remove(stepIndex);
          });
        },
      ),
    );
  }

  void _navigateToEnding(BuildContext context) {
    // playing screen 삭제하고 ending으로 전환
    RoleplayRouter.replaceWithEnding(context);
  }

  void _navigateToFailed(BuildContext context) {
    // playing screen 삭제하고 failed로 전환
    RoleplayRouter.replaceWithFailed(context);
  }

  Future<bool> _handleBackButton(BuildContext context) async {
    // 뒤로가기 시 얼럿 표시
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification'),
        content: const Text('Exit from page'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (shouldPop == true && context.mounted) {
      // playing screen 삭제하고 overview로 돌아감
      // overview는 Sub Screen이므로 Navigator.popUntil으로 overview까지 pop
      RoleplayRouter.popToOverview(context);
    }

    return false; // PopScope가 자동으로 pop하지 않도록
  }

  @override
  Widget build(BuildContext context) {
    final overview = RoleplayStateService.instance.overview;
    final roleplay = overview?.roleplay;
    if (_totalSteps == 0 && roleplay != null) {
      _initializeProgressState();
    }

    // Opening과 동일한 헤더 표기 규칙
    final titleEn = SudaJsonUtil.englishText(roleplay?.title);

    final durationFormatted = _formatRemaining();
    final durationColor = _remainingSeconds <= 10 ? Colors.red : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _handleBackButton(context);
        }
      },
      child: RoleplayScaffold(
        showCloseButton: widget.showCloseButton,
        onClose: () => _handleBackButton(context),
        title: titleEn,
        duration: durationFormatted,
        durationColor: durationColor,
        headerExtra: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 14),
            _buildProgressHeader(),
            const SizedBox(height: 14),
          ],
        ),
        headerTopSpacing: 108,
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              'Temp Controls',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Set Progress Step',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i <= _maxStepIndex; i++)
                  TextButton(
                    onPressed: () => _setProgressToStep(i),
                    child: Text('Go $i'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Set Mission Result',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              children: _missionStatuses.keys.map((index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mission $index',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _setMissionSuccess(index),
                        child: const Text('Success'),
                      ),
                      TextButton(
                        onPressed: () => _setMissionFailed(index),
                        child: const Text('Failed'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        footer: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 24,
                child: Center(
                  child: Text(
                    'service message area',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              if (_inputMode == _InputMode.recording)
                SizedBox(
                  height: 120,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final areaWidth = constraints.maxWidth;
                      final centerX = areaWidth / 2;
                      final cancelStyle = _cancelTextStyle(context);
                      final cancelWidth =
                          _measureTextWidth('Cancel', cancelStyle);
                      final cancelRight = cancelWidth;
                      final cancelCenter = cancelWidth / 2;
                      final maxLeftOffset = (_micPressedSize / 2) - centerX;
                      final effectiveOffset = _micState == _MicButtonState.pressed
                          ? _dragOffsetX
                          : 0.0;
                      final showArrows = _micState == _MicButtonState.pressed;
                      final shouldShowCancel = _micState == _MicButtonState.pressed;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: shouldShowCancel ? 1 : 0,
                              child: Text(
                                'Cancel',
                                style: cancelStyle,
                              ),
                            ),
                          ),
                          if (showArrows)
                            _buildDragArrows(
                              cancelRightX: cancelRight,
                              areaHeight: 120,
                              anchorLeftX: centerX - (_micPressedSize / 2),
                            ),
                          Center(
                            child: Transform.translate(
                              offset: Offset(effectiveOffset, 0),
                              child: IgnorePointer(
                                ignoring: !_isMicInteractive,
                                child: GestureDetector(
                                  onTapDown: _handleMicTapDown,
                                  onTapUp: (_) => _handleMicTapUp(),
                                  onTapCancel: _handleMicTapCancel,
                                  onPanStart: _handleMicPanStart,
                                  onPanUpdate: (details) => _handleMicPanUpdate(
                                    deltaX: details.delta.dx,
                                    maxLeftOffset: maxLeftOffset,
                                    cancelRightX: cancelRight,
                                    cancelCenterX: cancelCenter,
                                    centerX: centerX,
                                  ),
                                  onPanEnd: (_) => _handleMicTapUp(),
                                  child: _buildMicButton(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF353535),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: _typingController,
                                enabled: _isTypingEnabled,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _handleSend(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.white),
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: _isTypingEnabled
                                      ? 'Type your message ...'
                                      : 'Wait for your turn ...',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: const Color(0xFF9B9B9B)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: _isTypingEnabled ? _handleSend : null,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFF353535),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/icons/send.png',
                                  width: 24,
                                  height: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _inputMode = _inputMode == _InputMode.typing
                                ? _InputMode.recording
                                : _InputMode.typing;
                          });
                        },
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Image.asset(
                              _inputMode == _InputMode.typing
                                  ? 'assets/images/icons/mic.png'
                                  : 'assets/images/icons/keyboard.png',
                              height: 30,
                              width: 30,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: Image.asset(
                            'assets/images/icons/lightball.png',
                            height: 24,
                            width: 24,
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
    );
  }
}

enum _MissionStatus {
  ready,
  success,
  failed,
}

enum _InputMode {
  recording,
  typing,
}

enum _MicButtonState {
  defaultState,
  hover,
  pressed,
  loading,
  disabled,
}

const double _micDefaultSize = 100;
const double _micHoverSize = 110;
const double _micPressedSize = 115;

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _MissionIconScale extends StatefulWidget {
  final String asset;
  final double size;
  final bool animate;
  final VoidCallback onCompleted;

  const _MissionIconScale({
    required this.asset,
    required this.size,
    required this.animate,
    required this.onCompleted,
  });

  @override
  State<_MissionIconScale> createState() => _MissionIconScaleState();
}

class _MissionIconScaleState extends State<_MissionIconScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    if (widget.animate) {
      _startAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant _MissionIconScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !oldWidget.animate) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller
      ..reset()
      ..forward().whenComplete(widget.onCompleted);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
      );
    }

    return ScaleTransition(
      scale: _scale,
      child: Image.asset(
        widget.asset,
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
