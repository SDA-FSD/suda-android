import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';
import '../../models/rank_models.dart';
import '../../utils/default_toast.dart';
import '../../utils/user_img_path.dart';
import '../../widgets/gnb_bar.dart';
import '../../widgets/procedural_sunburst.dart';
import 'rank_crown_avatar.dart';

/// 1~3등 Ranking Reward Claim 전면 패널.
/// 배경·sunburst는 화면 하단(GNB 뒤)까지. 콘텐츠는 GNB 위 inset.
class RankingRewardClaimPanel extends StatelessWidget {
  const RankingRewardClaimPanel({
    super.key,
    required this.entry,
    required this.place,
    required this.onClaim,
    this.paintBackground = true,
    this.submitting = false,
  });

  final RankEntryDto entry;
  final int place; // 1|2|3
  final VoidCallback? onClaim;
  final bool submitting;

  /// false면 그라데이션 없이 콘텐츠만 (AppScaffold.background에 그라데이션을 둔 경우).
  final bool paintBackground;

  static const _defaultProfile =
      'assets/images/icons/default_profile_image.png';
  static const _crown1 = 'assets/images/icons/ranking_1st_crown.png';
  static const _crown2 = 'assets/images/icons/ranking_2st_crown.png';
  static const _crown3 = 'assets/images/icons/ranking_3st_crown.png';
  static const _figmaW = 440.0;
  /// 콘텐츠 블록 전체 Y 하향만 (내부 간격·크기 불변). Figma 440 기준 × s.
  static const _contentOffsetY = 40.0;

  /// Lab 목데이터.
  static RankEntryDto labMock({
    int rank = 1,
    String? imgPath,
    int weeklyLike = 3456,
    String subscribedYn = 'N',
  }) {
    return RankEntryDto(
      rank: rank,
      name: 'You',
      imgPath: imgPath,
      weeklyLike: weeklyLike,
      subscribedYn: subscribedYn,
      level: 1,
      isMe: true,
    );
  }

  /// Lab 1등 목데이터.
  static RankEntryDto labMockFirst({
    String? imgPath,
    int weeklyLike = 3456,
    String subscribedYn = 'N',
  }) {
    return labMock(
      rank: 1,
      imgPath: imgPath,
      weeklyLike: weeklyLike,
      subscribedYn: subscribedYn,
    );
  }

  static const _place3Bg = Color(0xFF0CABA8);

  /// 등수별 배경 — **불투명** (뒤 랭킹 비침 방지).
  static Widget placeBackground({required int place}) {
    if (place == 3) {
      return const ColoredBox(
        color: _place3Bg,
        child: SizedBox.expand(),
      );
    }
    if (place == 2) {
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF00A6),
              Color(0xFF8A38F5),
            ],
          ),
        ),
        child: SizedBox.expand(),
      );
    }
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF00A6), // opaque (피그마 80%는 뒤 비침 생겨 100%로)
            Color(0xFF8A38F5),
            Color(0xFF80D7CF),
          ],
          stops: [0.0, 0.35, 1.0],
        ),
      ),
      child: SizedBox.expand(),
    );
  }

  static const _rewardsBg = Color(0xA3570B3C); // #570B3C @ 64%
  static const _likePillBg = Color(0xE6043B3A); // #043B3A @ 90%
  // Figma 10.47° — 왼쪽→오른쪽 상승 = Flutter 반시계(음수). 양수면 하강(현재 버그).
  static const _likePillRadians = -10.47 * 3.141592653589793 / 180.0;

  String _watermark(int place) => switch (place) {
        2 => '2nd',
        3 => '3rd',
        _ => '1st',
      };

  @override
  Widget build(BuildContext context) {
    assert(place >= 1 && place <= 3);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final topInset = paintBackground ? MediaQuery.paddingOf(context).top : 0.0;

    Widget content(BoxConstraints constraints) {
      final w = constraints.maxWidth;
      final s = (w / _figmaW).clamp(0.75, 1.35);
      final bottomInset = paintBackground
          ? GnbBar.contentHeight + MediaQuery.paddingOf(context).bottom
          : 0.0;
      final avatarScale = s * 1.85;
      final rewardLikes = switch (place) {
        2 => l10n.rankTop3Likes60,
        3 => l10n.rankTop3Likes50,
        _ => l10n.rankTop3Likes100,
      };
      final rewardBadge = switch (place) {
        2 => l10n.rankTop3Badge2,
        3 => l10n.rankTop3Badge3,
        _ => l10n.rankTop3Badge1,
      };
      final rewardBox = switch (place) {
        2 => l10n.rankTop3Box2,
        3 => l10n.rankTop3Box1,
        _ => l10n.rankTop3Box3,
      };
      final medalAsset = switch (place) {
        2 => 'assets/images/achievement/medal_2st.png',
        3 => 'assets/images/achievement/medal_3st.png',
        _ => 'assets/images/achievement/medal_1st.png',
      };

      return Padding(
        padding: EdgeInsets.only(top: topInset),
        child: ScrollConfiguration(
          // iOS AlwaysScrollable 바운스(콘텐츠가 짧아도 드래그) 제거.
          // 오버플로 시에만 Clamping으로 스크롤.
          behavior: ScrollConfiguration.of(context).copyWith(
            physics: const ClampingScrollPhysics(),
            overscroll: false,
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              24 * s,
              (20 + _contentOffsetY) * s,
              24 * s,
              24 * s + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.translate(
                  offset: Offset(0, -20 * s),
                  child: Text(
                    l10n.rankingRewardClaimCongratulations,
                    textAlign: TextAlign.center,
                    style: theme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                ),
                SizedBox(height: 8 * s),
                Text(
                  l10n.rankingRewardClaimFinishedPlace(place),
                  textAlign: TextAlign.center,
                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                ),
                // 순위 안내 아래 블록 전체 Y만 하향 (내부 속성 불변)
                SizedBox(height: (28 + 40) * s),
                _ProfileHero(
                  entry: entry,
                  place: place,
                  avatarScale: avatarScale,
                  watermark: _watermark(place),
                ),
                SizedBox(height: 22 * s),
                Align(
                  child: FractionallySizedBox(
                    widthFactor: 0.75,
                    child: _YourRewardsCard(
                      scale: s,
                      overlayBlend: place == 3,
                      title: l10n.rankingRewardClaimYourRewards,
                      rows: [
                        (medalAsset, rewardBadge),
                        ('assets/images/like_at_result.png', rewardLikes),
                        ('assets/images/achievement/reward_box.png', rewardBox),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 28 * s),
                _RankingRewardClaimButton(
                  label: l10n.rankingRewardClaim,
                  onPressed: submitting ? null : onClaim,
                  submitting: submitting,
                ),
                SizedBox(height: 12 * s),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final child = content(constraints);
          if (!paintBackground) return child;
          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              placeBackground(place: place),
              const ProceduralSunburstOverlay(
                focal: SunburstFocal.bottomCenter,
              ),
              child,
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.entry,
    required this.place,
    required this.avatarScale,
    required this.watermark,
  });

  final RankEntryDto entry;
  final int place;
  final double avatarScale;
  final String watermark;

  @override
  Widget build(BuildContext context) {
    final s = avatarScale;
    final avatarOuter = RankCrownAvatar.avatarOuter * s;
    final stageW = avatarOuter * 1.55;
    final stageH = RankCrownAvatar.boxH * s + 24 * s;

    return SizedBox(
      width: stageW,
      height: stageH,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            // st 오른쪽 = 아바타 왼쪽 보더와 겹침
            right: (stageW + avatarOuter) / 2 -
                RankCrownAvatar.borderW * s -
                14 * s,
            top: (-RankCrownAvatar.crownTopOnAvatar * 0.15) * s - 8 * s,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  watermark.substring(0, 1),
                  style: TextStyle(
                    fontFamily: 'ChironHeiHK',
                    color: Colors.white.withValues(alpha: 0.22),
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 80,
                    height: 1.0,
                  ),
                ),
                Text(
                  watermark.substring(1),
                  style: TextStyle(
                    fontFamily: 'ChironHeiHK',
                    color: Colors.white.withValues(alpha: 0.22),
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                    fontSize: 50,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: (-RankCrownAvatar.crownTopOnAvatar * 0.15) * s + 12 * s,
            left: (stageW - avatarOuter) / 2,
            child: RankCrownAvatar(
              scale: s,
              imgPath: UserImgPath.orFallback(entry.imgPath),
              frameStyle: place == 1
                  ? RankProfileFrameStyle.winner
                  : RankProfileFrameStyle.rankingRewardClaimRunnerUp,
              defaultAsset: RankingRewardClaimPanel._defaultProfile,
              crownAsset: switch (place) {
                2 => RankingRewardClaimPanel._crown2,
                3 => RankingRewardClaimPanel._crown3,
                _ => RankingRewardClaimPanel._crown1,
              },
              showCrown: true,
              showLevelBadge: false,
              outerShadowScale: s,
            ),
          ),
          Positioned(
            // 아이콘 축 고정 — 자릿수는 오른쪽으로만 늘어남 (right 앵커면 아이콘이 밀림)
            left: stageW * 0.60,
            // bottom↑ = 알약만 위로
            bottom: stageH * 0.08 + 4 * s,
            child: Transform.rotate(
              angle: RankingRewardClaimPanel._likePillRadians,
              alignment: Alignment.topLeft,
              origin: Offset(14 * s, 11 * s), // 아이콘 중심: 좌 6+8, 상 3+8 (s=avatarScale)
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: RankingRewardClaimPanel._likePillBg,
                  borderRadius: BorderRadius.circular(20 * s),
                  boxShadow: [
                    // RankProfileFrame outer shadow와 동일 (#000@30%, offset/blur 20×scale)
                    BoxShadow(
                      color: Color(0x4D000000),
                      offset: Offset(20 * s, 20 * s),
                      blurRadius: 20 * s,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(6 * s, 3 * s, 10 * s, 3 * s),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/like_at_result.png',
                        width: 16 * s,
                        height: 16 * s,
                      ),
                      SizedBox(width: 4 * s),
                      Text(
                        '${entry.weeklyLike}',
                        style: TextStyle(
                          fontFamily: 'ChironHeiHK',
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                          fontSize: 22,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YourRewardsCard extends StatelessWidget {
  const _YourRewardsCard({
    required this.scale,
    required this.title,
    required this.rows,
    this.overlayBlend = false,
  });

  final double scale;
  final String title;
  final List<(String, String)> rows;
  /// 3등: 카드 fill만 overlay. 텍스트·아이콘은 일반 합성.
  final bool overlayBlend;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final theme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            offset: Offset(20, 20),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 11.2, sigmaY: 11.2),
          child: Stack(
            children: [
              Positioned.fill(
                child: overlayBlend
                    ? const Stack(
                        fit: StackFit.expand,
                        children: [
                          // 스크롤 레이어 분리 시 페이지 배경이 안 보여
                          // 단색 3등 배경을 카드 안에서 다시 깔고 overlay.
                          ColoredBox(color: RankingRewardClaimPanel._place3Bg),
                          _OverlayBlend(
                            child: ColoredBox(
                              color: RankingRewardClaimPanel._rewardsBg,
                            ),
                          ),
                        ],
                      )
                    : const ColoredBox(color: RankingRewardClaimPanel._rewardsBg),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20 * s, 16 * s, 20 * s, 16 * s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    SizedBox(height: 12 * s),
                    for (var i = 0; i < rows.length; i++) ...[
                      if (i > 0) SizedBox(height: 10 * s),
                      Row(
                        children: [
                          SizedBox(width: 12 * s),
                          Image.asset(
                            rows[i].$1,
                            width: 28 * s,
                            height: 28 * s,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Text(
                              rows[i].$2,
                              style: theme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingRewardClaimButton extends StatelessWidget {
  const _RankingRewardClaimButton({
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

/// CSS `mix-blend-mode: overlay` 대응. fill 전용(텍스트는 부모 Stack에서 srcOver).
class _OverlayBlend extends SingleChildRenderObjectWidget {
  const _OverlayBlend({required Widget child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderOverlayBlend();
  }
}

class _RenderOverlayBlend extends RenderProxyBox {
  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    context.canvas.saveLayer(
      offset & size,
      Paint()..blendMode = BlendMode.overlay,
    );
    context.paintChild(child!, offset);
    context.canvas.restore();
  }
}

void showRankingRewardClaimErrorToast(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  DefaultToast.show(context, l10n.rankingRewardClaimError, isError: true);
}
