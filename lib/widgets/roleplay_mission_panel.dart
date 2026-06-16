import 'package:flutter/material.dart';

import '../models/series_models.dart';
import '../utils/suda_json_util.dart';

/// S2 Playing **미션 패널** — 본문 상단 고정 오버레이.
///
/// 접힘: 현재 미션 instruction 1개 + 진행 `completed/total`.
/// 탭 시 아래로만 펼쳐 전체 미션 목록 노출.
/// shine 효과는 [MissionCompleteEffect] 전역 오버레이에서 재생.
class RoleplayMissionPanel extends StatefulWidget {
  static const double collapsedHeight = 54;
  static const double borderRadius = collapsedHeight / 2;
  static const double sideInset = 15;
  static const double rightProgressInset = 20;
  static const double iconSize = 24;
  static const double textSideGap = 8;

  /// 좌·우 슬롯 사이 가용 폭 대비 텍스트 컬럼 비율 (나머지는 양쪽 균등 여백).
  static const double textColumnWidthFactor = 0.9;
  static const Color backgroundColor = Color(0xFF353535);

  static const String missionIconOff =
      'assets/images/icons/rps2_mission_off.png';
  static const String missionIconOn = 'assets/images/icons/rps2_mission_on.png';
  static const Color completedBackgroundColor = Color(0xFF9E0067);

  final List<RpS2CefrMissionDto> missions;
  final int activeMissionIndex;
  final int completedCount;
  final Set<int> completedMissionIndexes;
  final bool keepCompletedBackground;
  final GlobalKey? missionIconAnchorKey;

  const RoleplayMissionPanel({
    super.key,
    required this.missions,
    this.activeMissionIndex = 0,
    this.completedCount = 0,
    this.completedMissionIndexes = const {},
    this.keepCompletedBackground = false,
    this.missionIconAnchorKey,
  });

  @override
  State<RoleplayMissionPanel> createState() => _RoleplayMissionPanelState();
}

class _RoleplayMissionPanelState extends State<RoleplayMissionPanel> {
  bool _expanded = false;

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
  }

  String _instructionAt(int index) {
    if (index < 0 || index >= widget.missions.length) return '';
    return SudaJsonUtil.localizedMapText(widget.missions[index].instruction);
  }

  bool _isMissionCompleted(int index) {
    return widget.completedMissionIndexes.contains(index);
  }

  Widget _missionIcon(int index) {
    return Image.asset(
      _isMissionCompleted(index)
          ? RoleplayMissionPanel.missionIconOn
          : RoleplayMissionPanel.missionIconOff,
      width: RoleplayMissionPanel.iconSize,
      height: RoleplayMissionPanel.iconSize,
    );
  }

  double _measureProgressSlotWidth(TextTheme theme, int total) {
    final style = theme.labelSmall?.copyWith(color: Colors.white);
    final painter = TextPainter(
      text: TextSpan(text: '$total/$total', style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    return RoleplayMissionPanel.textSideGap +
        painter.size.width +
        RoleplayMissionPanel.rightProgressInset;
  }

  double _leftSlotWidth() =>
      RoleplayMissionPanel.sideInset + RoleplayMissionPanel.iconSize;

  Widget _buildInstructionText(TextTheme theme, String instruction) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        instruction,
        style: theme.bodyMedium?.copyWith(color: Colors.white),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildLeftIconSlot({
    required int index,
    Alignment alignment = Alignment.center,
  }) {
    final icon = _missionIcon(index);
    final anchoredIcon =
        index == widget.activeMissionIndex &&
            widget.missionIconAnchorKey != null
        ? KeyedSubtree(key: widget.missionIconAnchorKey!, child: icon)
        : icon;

    return SizedBox(
      width: _leftSlotWidth(),
      child: Align(
        alignment: alignment,
        child: Padding(
          padding: const EdgeInsets.only(left: RoleplayMissionPanel.sideInset),
          child: anchoredIcon,
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(
    TextTheme theme,
    double textColumnWidth,
    double textGutterBefore,
    double textGutterAfter,
    double rightSlotWidth,
  ) {
    final safeIndex = widget.activeMissionIndex.clamp(
      0,
      widget.missions.length - 1,
    );
    final instruction = _instructionAt(safeIndex);
    final total = widget.missions.length;
    final progressIndex = safeIndex + 1;
    final progressStyle = theme.labelSmall?.copyWith(color: Colors.white);

    return SizedBox(
      height: RoleplayMissionPanel.collapsedHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildLeftIconSlot(index: safeIndex),
          SizedBox(width: textGutterBefore),
          SizedBox(
            width: textColumnWidth,
            child: _buildInstructionText(theme, instruction),
          ),
          SizedBox(width: textGutterAfter),
          SizedBox(
            width: rightSlotWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: RoleplayMissionPanel.rightProgressInset,
                ),
                child: Text(
                  '$progressIndex/$total',
                  style: progressStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
    TextTheme theme,
    double textColumnWidth,
    double textGutterBefore,
    double textGutterAfter,
    double rightSlotWidth,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.missions.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftIconSlot(index: i, alignment: Alignment.centerLeft),
                SizedBox(width: textGutterBefore),
                SizedBox(
                  width: textColumnWidth,
                  child: _buildInstructionText(theme, _instructionAt(i)),
                ),
                SizedBox(width: textGutterAfter),
                SizedBox(width: rightSlotWidth),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.missions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth;
        final rightSlotWidth = _measureProgressSlotWidth(
          theme,
          widget.missions.length,
        );
        final leftSlotWidth = _leftSlotWidth();
        final middleRegionWidth = (panelWidth - leftSlotWidth - rightSlotWidth)
            .clamp(0.0, double.infinity);
        final textColumnWidth =
            middleRegionWidth * RoleplayMissionPanel.textColumnWidthFactor;
        final textGutterTotal = middleRegionWidth - textColumnWidth;
        final textGutterBefore = textGutterTotal / 2;
        final textGutterAfter = textGutterTotal / 2;

        final allCompleted =
            widget.missions.isNotEmpty &&
            widget.completedMissionIndexes.length >= widget.missions.length;
        final shouldUseCompletedBackground =
            widget.keepCompletedBackground || allCompleted;

        return GestureDetector(
          onTap: _toggleExpanded,
          behavior: HitTestBehavior.opaque,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.hardEdge,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SizeTransition(
                    sizeFactor: animation,
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: AnimatedContainer(
                key: ValueKey<bool>(_expanded),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                width: double.infinity,
                constraints: const BoxConstraints(
                  minHeight: RoleplayMissionPanel.collapsedHeight,
                ),
                decoration: BoxDecoration(
                  color: shouldUseCompletedBackground
                      ? RoleplayMissionPanel.completedBackgroundColor
                      : RoleplayMissionPanel.backgroundColor,
                  borderRadius: BorderRadius.circular(
                    RoleplayMissionPanel.borderRadius,
                  ),
                ),
                child: Stack(
                  children: [
                    _expanded
                        ? _buildExpandedContent(
                            theme,
                            textColumnWidth,
                            textGutterBefore,
                            textGutterAfter,
                            rightSlotWidth,
                          )
                        : _buildCollapsedContent(
                            theme,
                            textColumnWidth,
                            textGutterBefore,
                            textGutterAfter,
                            rightSlotWidth,
                          ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
