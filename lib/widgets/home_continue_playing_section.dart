import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/home_models.dart';
import '../utils/suda_json_util.dart';
import 'cdn_thumb_image.dart';
import 'suda_tap.dart';

/// 홈 Continue Playing. 목록이 비면 [SizedBox.shrink].
class HomeContinuePlayingSection extends StatelessWidget {
  static const _borderStart = Color(0xFF0CABA8);
  static const _borderEnd = Color(0xFF054544);
  static const _buttonColor = Color(0xFF0CABA8);
  static const _episodeTitleColor = Color(0xFF8C8C8C);
  static const _cardBg = Color(0xFF1A2222);
  static const _contentBgStart = Color(0xFF182D2E);
  static const _contentBgEnd = Color(0xFF131C1B);
  static const _trackColor = Color(0xFF3A3A3A);
  static const _panelRadius = 24.0;
  static const _cardListHeight = 172.0;
  static const _cardWidth = 320.0;
  /// 피그마 ~40% 폭 세로 스트립.
  static const _thumbWidth = 128.0;
  static const _cardGap = 12.0;

  final List<HomeContinuePlayingDto> items;
  final ValueChanged<HomeContinuePlayingDto> onContinue;

  const HomeContinuePlayingSection({
    super.key,
    required this.items,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    // 타이틀+카드 패널: 좌측만 round, 우측 직각.
    // 정사각 원형 방사형을 패널 비율로 stretch → 타원형 그라데이션.
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_panelRadius),
        bottomLeft: Radius.circular(_panelRadius),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _borderEnd)),
          const Positioned.fill(
            child: FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                width: 100,
                height: 100,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [_borderStart, _borderEnd],
                      stops: [0.0, 0.65],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Text(
                  l10n.homeContinuePlayingSection,
                  style: theme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: _cardListHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  physics: const _ContinuePlayingSnapPhysics(
                    step: _cardWidth + _cardGap,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: _cardGap),
                  itemBuilder: (context, index) {
                    return _ContinuePlayingCard(
                      item: items[index],
                      buttonLabel: l10n.homeContinuePlayingButton,
                      onContinue: () => onContinue(items[index]),
                    );
                  },
                ),
              ),
              // 카드 ↔ 방사형 패널 하단 여백
              const SizedBox(height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

/// 카드 폭+간격 단위로 왼쪽 정렬 스냅 (Result 가로 캐러셀과 동일 패턴).
class _ContinuePlayingSnapPhysics extends ScrollPhysics {
  const _ContinuePlayingSnapPhysics({required this.step, super.parent});

  final double step;

  @override
  _ContinuePlayingSnapPhysics applyTo(ScrollPhysics? ancestor) {
    return _ContinuePlayingSnapPhysics(
      step: step,
      parent: buildParent(ancestor),
    );
  }

  double _targetPixels(
    ScrollMetrics position,
    Tolerance tolerance,
    double velocity,
  ) {
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
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
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

class _ContinuePlayingCard extends StatelessWidget {
  final HomeContinuePlayingDto item;
  final String buttonLabel;
  final VoidCallback onContinue;

  const _ContinuePlayingCard({
    required this.item,
    required this.buttonLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final seriesTitle = SudaJsonUtil.localizedMapText(item.title);
    final episodeTitle = SudaJsonUtil.localizedMapText(item.episodeTitle);
    final epLabel = item.episodeOrder > 0
        ? 'Ep.${item.episodeOrder} $episodeTitle'
        : episodeTitle;
    final progress = (item.progressPercent.clamp(0, 100)) / 100.0;
    final thumbPath = item.thumbnailImgPath;

    // 썸네일: 카드 좌측 full-bleed. 카드 간격(12)은 유지, 안쪽 상하 패딩만 축소.
    return SizedBox(
      width: HomeContinuePlayingSection._cardWidth,
      height: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              HomeContinuePlayingSection._borderStart,
              HomeContinuePlayingSection._borderEnd,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ColoredBox(
              color: HomeContinuePlayingSection._cardBg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: HomeContinuePlayingSection._thumbWidth,
                    child: thumbPath == null || thumbPath.isEmpty
                        ? const ColoredBox(color: Color(0xFF2A2A2A))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return CdnThumbImage(
                                path: thumbPath,
                                slot: CdnThumbSlot.seriesRow,
                                width: constraints.maxWidth,
                                height: constraints.maxHeight,
                                fit: BoxFit.cover,
                                alignment: Alignment.topLeft,
                                placeholder: (_, _) => const ColoredBox(
                                  color: Color(0xFF2A2A2A),
                                ),
                                errorWidget: (_, _, _) => const ColoredBox(
                                  color: Color(0xFF2A2A2A),
                                ),
                              );
                            },
                          ),
                  ),
                  Expanded(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            HomeContinuePlayingSection._contentBgStart,
                            HomeContinuePlayingSection._contentBgEnd,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  seriesTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.labelLarge?.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  epLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.bodySmall?.copyWith(
                                    color: HomeContinuePlayingSection
                                        ._episodeTitleColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.italic,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                            // 프로그레스는 이어하기 바로 위 고정. 버튼 키운 만큼 중간 공백 감소.
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          minHeight: 4,
                                          backgroundColor:
                                              HomeContinuePlayingSection
                                                  ._trackColor,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.progressPercent.clamp(0, 100)}%',
                                      style: theme.labelSmall?.copyWith(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SudaTap(
                                  onTap: onContinue,
                                  child: Container(
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: HomeContinuePlayingSection
                                          ._buttonColor,
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Text(
                                      buttonLabel,
                                      style: theme.labelLarge?.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
