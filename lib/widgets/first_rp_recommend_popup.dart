import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:suda/l10n/app_localizations.dart';

import '../models/home_models.dart';
import '../utils/cdn_thumbnail.dart';
import '../utils/language_util.dart';
import '../utils/suda_json_util.dart';

/// 홈 첫 롤플레이 추천. 딤 탭으로는 닫히지 않는다.
class FirstRpRecommendPopup extends StatelessWidget {
  final HomeFirstRpRecommendDto recommend;
  final VoidCallback onClose;
  final VoidCallback onPlay;

  const FirstRpRecommendPopup({
    super.key,
    required this.recommend,
    required this.onClose,
    required this.onPlay,
  });

  static const _dim = Color(0x66000000);
  static const _bottom = Color(0xFF121212);
  static const _primary = Color(0xFF0CABA8);
  static const _titleShadow = Color(0xE6000000);

  bool get _showLocalizedTitle {
    if (recommend.localizedTitleShowYn != 'Y') return false;
    if (LanguageUtil.getCurrentLanguageCode().toLowerCase() == 'en') {
      return false;
    }
    final title = SudaJsonUtil.localizedMapTextOrNull(recommend.title);
    return title != null && title.isNotEmpty;
  }

  String? get _categoryLabel {
    final name = recommend.category?.name;
    final text = SudaJsonUtil.localizedMapTextOrNull(name);
    if (text == null || text.isEmpty) return null;
    return text;
  }

  String? get _difficultyLabel {
    switch (recommend.synopsisComplexityLevel?.toUpperCase()) {
      case 'EASY':
        return 'Easy';
      case 'NORMAL':
        return 'Normal';
      case 'HARD':
        return 'Hard';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    const closeSize = 40.0;
    const closeGap = 8.0;
    var cardWidth = size.width * 0.78;
    var cardHeight = cardWidth * 1.5;
    final maxHeight = size.height * 0.78 - closeSize - closeGap;
    if (cardHeight > maxHeight) {
      cardHeight = maxHeight;
      cardWidth = cardHeight * 2 / 3;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: const ColoredBox(color: _dim),
          ),
        ),
        Center(
          child: SizedBox(
            width: cardWidth,
            height: cardHeight + closeSize + closeGap,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: closeSize,
                      height: closeSize,
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/images/icons/close.svg',
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: closeSize + closeGap,
                  left: 0,
                  right: 0,
                  height: cardHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _thumbnail(),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00121212),
                                Color(0x00121212),
                                _bottom,
                                _bottom,
                              ],
                              stops: [0, 0.6, 0.9, 1],
                            ),
                          ),
                        ),
                        if (_showLocalizedTitle) _title(context),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _badge(context, l10n.firstRpRecommendBadge),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 16,
                          child: _bottomChrome(context, l10n.firstRpRecommendPlay),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _thumbnail() {
    final path = recommend.thumbnailImgPath;
    if (path == null || path.isEmpty) {
      return const ColoredBox(color: _bottom);
    }
    return CachedNetworkImage(
      imageUrl: CdnThumbUrl.original(path),
      fit: BoxFit.cover,
      placeholder: (context, url) => const ColoredBox(color: _bottom),
      errorWidget: (context, url, error) => const ColoredBox(color: _bottom),
    );
  }

  Widget _title(BuildContext context) {
    final title = SudaJsonUtil.localizedMapTextOrNull(recommend.title) ?? '';
    final style = Theme.of(context).textTheme.headlineSmall?.copyWith(
      color: Colors.white,
      shadows: const [
        Shadow(
          offset: Offset(0, 4),
          blurRadius: 6,
          color: _titleShadow,
        ),
      ],
    );
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                left: constraints.maxWidth * recommend.titleBoxLeft,
                top: constraints.maxHeight * recommend.titleBoxTop,
                width: constraints.maxWidth * recommend.titleBoxWidth,
                child: Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.left,
                  style: style,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _bottomChrome(BuildContext context, String playLabel) {
    final category = _categoryLabel;
    final difficulty = _difficultyLabel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (category != null || difficulty != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (category != null) _glassPill(context, category),
                if (category != null && difficulty != null)
                  const SizedBox(width: 8),
                if (difficulty != null) _glassPill(context, difficulty),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: onPlay,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              playLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _glassPill(BuildContext context, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          color: Colors.white.withValues(alpha: 0.22),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
