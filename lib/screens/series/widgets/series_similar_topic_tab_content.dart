import 'dart:async' show unawaited;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/app_config.dart';
import '../../../routes/series_router.dart';
import '../../../services/suda_api_client.dart';
import '../../../services/token_storage.dart';
import '../../../utils/suda_json_util.dart';

/// Series Overview Similar Topic 탭 — 카테고리 시리즈 3열 그리드 + 페이징.
class SeriesSimilarTopicTabContent extends StatefulWidget {
  final String? category;
  final int excludeSeriesId;
  final ScrollController parentScrollController;
  final bool isActive;
  final UserDto? user;

  const SeriesSimilarTopicTabContent({
    super.key,
    required this.category,
    required this.excludeSeriesId,
    required this.parentScrollController,
    required this.isActive,
    this.user,
  });

  @override
  State<SeriesSimilarTopicTabContent> createState() =>
      _SeriesSimilarTopicTabContentState();
}

class _SeriesSimilarTopicTabContentState
    extends State<SeriesSimilarTopicTabContent> {
  static const _thumbGap = 10.0;
  static const _rowGap = 10.0;
  static const _initialPageCount = 3;
  static const _loadMoreThreshold = 200.0;

  final List<HomeSeriesDto> _list = [];
  final Set<int> _seenIds = {};
  int _currentPage = -1;
  bool _isLastPage = false;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _initialLoadStarted = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    widget.parentScrollController.addListener(_onParentScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInitialLoad();
    });
  }

  @override
  void didUpdateWidget(covariant SeriesSimilarTopicTabContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.parentScrollController != widget.parentScrollController) {
      oldWidget.parentScrollController.removeListener(_onParentScroll);
      widget.parentScrollController.addListener(_onParentScroll);
    }
    if (oldWidget.category != widget.category ||
        oldWidget.excludeSeriesId != widget.excludeSeriesId) {
      _resetAndReload();
      return;
    }
    if (widget.isActive && !oldWidget.isActive) {
      _ensureInitialLoad();
      _onParentScroll();
    }
  }

  @override
  void dispose() {
    widget.parentScrollController.removeListener(_onParentScroll);
    super.dispose();
  }

  void _resetAndReload() {
    _list.clear();
    _seenIds.clear();
    _currentPage = -1;
    _isLastPage = false;
    _isInitialLoading = false;
    _isLoadingMore = false;
    _initialLoadStarted = false;
    _errorMessage = null;
    _ensureInitialLoad();
  }

  void _ensureInitialLoad() {
    if (!mounted) return;
    if (_initialLoadStarted) return;
    final category = widget.category?.trim();
    if (category == null || category.isEmpty) return;
    _initialLoadStarted = true;
    unawaited(_loadInitialPages(category));
  }

  void _onParentScroll() {
    if (!widget.isActive) return;
    if (!widget.parentScrollController.hasClients) return;
    if (_isInitialLoading || _isLoadingMore || _isLastPage) return;
    final pos = widget.parentScrollController.position;
    if (pos.pixels < pos.maxScrollExtent - _loadMoreThreshold) return;
    unawaited(_loadMore());
  }

  Future<void> _loadInitialPages(String category) async {
    setState(() {
      _isInitialLoading = true;
      _errorMessage = null;
    });

    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'Authentication required.';
      });
      return;
    }

    try {
      for (var pageNum = 0; pageNum < _initialPageCount; pageNum++) {
        if (_isLastPage) break;
        final page = await SudaApiClient.getSeriesByCategory(
          accessToken: accessToken,
          categoryEnumValue: category,
          pageNum: pageNum,
        );
        if (!mounted) return;
        _appendPage(page);
        if (page.last) break;
      }
      if (mounted) {
        setState(() => _isInitialLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isInitialLoading = false;
        _errorMessage = 'Failed to load series.';
      });
    }
  }

  Future<void> _loadMore() async {
    final category = widget.category?.trim();
    if (category == null || category.isEmpty) return;
    if (_isLoadingMore || _isLastPage || _isInitialLoading) return;

    setState(() => _isLoadingMore = true);
    final accessToken = await TokenStorage.loadAccessToken();
    if (!mounted) return;
    if (accessToken == null) {
      setState(() => _isLoadingMore = false);
      return;
    }

    try {
      final nextPage = _currentPage + 1;
      final page = await SudaApiClient.getSeriesByCategory(
        accessToken: accessToken,
        categoryEnumValue: category,
        pageNum: nextPage,
      );
      if (!mounted) return;
      setState(() {
        _appendPage(page);
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  void _appendPage(SudaAppPage<HomeSeriesDto> page) {
    for (final item in page.content) {
      if (item.id == widget.excludeSeriesId) continue;
      if (!_seenIds.add(item.id)) continue;
      _list.add(item);
    }
    _currentPage = page.number;
    _isLastPage = page.last;
  }

  void _onSeriesTap(HomeSeriesDto item) {
    SeriesRouter.pushOverview(context, item.id, user: widget.user);
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.category?.trim();
    if (category == null || category.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth;
        final itemWidth = (contentWidth - 2 * _thumbGap) / 3;
        final itemHeight = itemWidth * 1.5;

        if (_isInitialLoading && _list.isEmpty) {
          return Column(
            children: [
              _rowOfThree(
                List.generate(
                  3,
                  (_) => _shimmer(itemWidth, itemHeight),
                ),
                itemWidth,
                itemHeight,
              ),
              const SizedBox(height: _rowGap),
              _rowOfThree(
                List.generate(
                  3,
                  (_) => _shimmer(itemWidth, itemHeight),
                ),
                itemWidth,
                itemHeight,
              ),
            ],
          );
        }

        if (_errorMessage != null && _list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (_list.isEmpty) {
          return const SizedBox.shrink();
        }

        final rows = <Widget>[];
        for (var i = 0; i < _list.length; i += 3) {
          final rowItems = <Widget>[];
          for (var j = 0; j < 3; j++) {
            final index = i + j;
            if (index < _list.length) {
              final item = _list[index];
              rowItems.add(
                _SimilarSeriesThumbnail(
                  item: item,
                  width: itemWidth,
                  height: itemHeight,
                  onTap: () => _onSeriesTap(item),
                ),
              );
            }
          }
          rows.add(_rowOfThree(rowItems, itemWidth, itemHeight));
          if (i + 3 < _list.length || _isLoadingMore) {
            rows.add(const SizedBox(height: _rowGap));
          }
        }

        if (_isLoadingMore) {
          rows.add(
            _rowOfThree(
              List.generate(3, (_) => _shimmer(itemWidth, itemHeight)),
              itemWidth,
              itemHeight,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        );
      },
    );
  }

  Widget _rowOfThree(
    List<Widget> children,
    double itemWidth,
    double itemHeight,
  ) {
    final list = <Widget>[];
    for (var i = 0; i < 3; i++) {
      if (i > 0) list.add(const SizedBox(width: _thumbGap));
      list.add(
        i < children.length
            ? children[i]
            : SizedBox(width: itemWidth, height: itemHeight),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: list,
    );
  }

  Widget _shimmer(double width, double height) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3F3F3F),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// Profile 히스토리형 고정 박스(cover) + Home형 하단 제목/Marquee.
class _SimilarSeriesThumbnail extends StatelessWidget {
  final HomeSeriesDto item;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _SimilarSeriesThumbnail({
    required this.item,
    required this.width,
    required this.height,
    this.onTap,
  });

  bool _shouldMarquee({
    required String text,
    required TextStyle? style,
    required double maxWidth,
    required TextDirection textDirection,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: textDirection,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final title = SudaJsonUtil.localizedMapText(item.title);
    final path = item.thumbnailImgPath;
    final imageUrl =
        path != null && path.isNotEmpty ? '${AppConfig.cdnBaseUrl}$path' : null;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontSize: 12,
        );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: width,
                      height: height,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: const Color(0xFF2A2A2A),
                        highlightColor: const Color(0xFF3F3F3F),
                        child: Container(
                          width: width,
                          height: height,
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: width,
                        height: height,
                        color: Colors.grey[900],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      width: width,
                      height: height,
                      color: Colors.grey[900],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    ),
            ),
            if (title.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final shouldMarquee = _shouldMarquee(
                        text: title,
                        style: textStyle,
                        maxWidth: constraints.maxWidth,
                        textDirection: Directionality.of(context),
                      );
                      return SizedBox(
                        height: 18,
                        child: shouldMarquee
                            ? Marquee(
                                text: title,
                                style: textStyle,
                                scrollAxis: Axis.horizontal,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                blankSpace: 20.0,
                                velocity: 30.0,
                                pauseAfterRound: const Duration(seconds: 2),
                                startPadding: 0,
                                accelerationDuration: const Duration(seconds: 1),
                                accelerationCurve: Curves.linear,
                                decelerationDuration:
                                    const Duration(milliseconds: 500),
                                decelerationCurve: Curves.easeOut,
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                  softWrap: false,
                                  textAlign: TextAlign.left,
                                  style: textStyle,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
