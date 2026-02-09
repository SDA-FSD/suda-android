import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/roleplay_models.dart';
import '../../utils/suda_json_util.dart';
import '../../widgets/app_scaffold.dart';

/// Review Ending Screen (Sub Screen)
///
/// History에서 진입. RoleplayEndingDto로 엔딩 이미지·타이틀·콘텐츠 열람.
/// 헤더 아래 영역에 이미지(비율 유지·세로 100%), 2.5s 후 레이어·콘텐츠 페이드인. 버튼 없음.
class ReviewEndingScreen extends StatefulWidget {
  final RoleplayEndingDto ending;

  const ReviewEndingScreen({
    super.key,
    required this.ending,
  });

  @override
  State<ReviewEndingScreen> createState() => _ReviewEndingScreenState();
}

class _ReviewEndingScreenState extends State<ReviewEndingScreen> {
  bool _showOverlayAndContent = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) setState(() => _showOverlayAndContent = true);
    });
  }

  bool get _hasImage {
    final path = widget.ending.imgPath;
    return path != null && path.isNotEmpty;
  }

  String get _imageUrl {
    final path = widget.ending.imgPath;
    if (path == null || path.isEmpty) return '';
    return '${AppConfig.cdnBaseUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final title = SudaJsonUtil.localizedText(widget.ending.title);
    final content = SudaJsonUtil.localizedText(widget.ending.content);

    return AppScaffold(
      centerTitle: 'View Ending',
      showBackButton: true,
      backgroundColor: const Color(0xFF121212),
      usePadding: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bodyHeight = constraints.maxHeight;
          final bodyWidth = constraints.maxWidth;
          return Stack(
            fit: StackFit.expand,
            children: [
              if (_hasImage)
                Positioned(
                  left: 0,
                  top: 0,
                  width: bodyWidth,
                  height: bodyHeight,
                  child: Image(
                    image: CachedNetworkImageProvider(_imageUrl),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                )
              else
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF121212)),
                ),
              AnimatedOpacity(
                opacity: _showOverlayAndContent ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Container(color: const Color(0xCC000000)),
              ),
              AnimatedOpacity(
                opacity: _showOverlayAndContent ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Text(
                              title,
                              style: theme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                            ),
                            child: Text(
                              content,
                              style: theme.bodyMedium?.copyWith(
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
