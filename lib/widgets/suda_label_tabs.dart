import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// 탭 레이블: [SudaTabLabel.fixed]는 고정 문자열, [SudaTabLabel.l10n]은 locale별 l10n.
class SudaTabLabel {
  final String Function(BuildContext context) _resolve;

  const SudaTabLabel._(this._resolve);

  factory SudaTabLabel.fixed(String text) {
    return SudaTabLabel._((_) => text);
  }

  factory SudaTabLabel.l10n(String Function(AppLocalizations l10n) resolver) {
    return SudaTabLabel._(
      (context) => resolver(AppLocalizations.of(context)!),
    );
  }

  String resolve(BuildContext context) => _resolve(context);
}

class SudaLabelTab {
  final SudaTabLabel label;
  final Widget child;

  const SudaLabelTab({
    required this.label,
    required this.child,
  });
}

/// 좌측 정렬 레이블 탭 + 선택 시 하단 콘텐츠 전환.
///
/// - 선택: bodySmall bold 흰색 + 하단 2px 흰색 밑줄
/// - 미선택: bodySmall bold #635F5F, 밑줄 없음
/// - 탭 영역 배경·구분선 없음
class SudaLabelTabs extends StatefulWidget {
  final List<SudaLabelTab> tabs;
  final int initialIndex;
  final int? selectedIndex;
  final ValueChanged<int>? onTabChanged;
  final double tabSpacing;
  final double contentGap;
  final EdgeInsetsGeometry labelPadding;

  /// true면 비선택 탭 child도 [IndexedStack]으로 유지(상태·초기 로드 보존).
  final bool maintainState;

  const SudaLabelTabs({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.selectedIndex,
    this.onTabChanged,
    this.tabSpacing = 24,
    this.contentGap = 20,
    this.labelPadding = EdgeInsets.zero,
    this.maintainState = false,
  }) : assert(tabs.length >= 2, 'SudaLabelTabs requires at least 2 tabs');

  @override
  State<SudaLabelTabs> createState() => _SudaLabelTabsState();
}

class _SudaLabelTabsState extends State<SudaLabelTabs> {
  static const _inactiveColor = Color(0xFF635F5F);
  static const _underlineThickness = 2.0;
  static const _labelUnderlineGap = 4.0;

  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex ?? widget.initialIndex;
  }

  @override
  void didUpdateWidget(SudaLabelTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null &&
        widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex!;
    }
  }

  int get _effectiveIndex => widget.selectedIndex ?? _selectedIndex;

  void _selectTab(int index) {
    if (index == _effectiveIndex) return;
    if (widget.selectedIndex == null) {
      setState(() => _selectedIndex = index);
    }
    widget.onTabChanged?.call(index);
  }

  TextStyle _labelStyle(TextTheme theme, bool selected) {
    return theme.bodySmall!.copyWith(
      color: selected ? Colors.white : _inactiveColor,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );
  }

  Widget _buildTabLabel(
    BuildContext context,
    TextTheme theme,
    int index,
  ) {
    final selected = index == _effectiveIndex;
    final label = widget.tabs[index].label.resolve(context);

    return GestureDetector(
      onTap: () => _selectTab(index),
      behavior: HitTestBehavior.opaque,
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: _labelStyle(theme, selected),
            ),
            const SizedBox(height: _labelUnderlineGap),
            ColoredBox(
              color: selected ? Colors.white : Colors.transparent,
              child: const SizedBox(
                height: _underlineThickness,
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: widget.labelPadding,
          child: Wrap(
            spacing: widget.tabSpacing,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (int i = 0; i < widget.tabs.length; i++)
                _buildTabLabel(context, theme, i),
            ],
          ),
        ),
        SizedBox(height: widget.contentGap),
        if (widget.maintainState)
          // Offstage: 비선택 탭은 레이아웃 높이 0, 상태는 유지
          Stack(
            alignment: Alignment.topCenter,
            children: [
              for (var i = 0; i < widget.tabs.length; i++)
                Offstage(
                  offstage: i != _effectiveIndex,
                  child: TickerMode(
                    enabled: i == _effectiveIndex,
                    child: widget.tabs[i].child,
                  ),
                ),
            ],
          )
        else
          widget.tabs[_effectiveIndex].child,
      ],
    );
  }
}
