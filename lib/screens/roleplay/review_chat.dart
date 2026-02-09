import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../models/common_models.dart';
import '../../models/roleplay_models.dart';
import '../../widgets/app_scaffold.dart';

/// Chat history entry keys (server chatHistory item key).
const String _kChatKeyUser = 'USER';
const String _kChatKeyAiCharacter = 'AI_CHARACTER';
const String _kChatKeyAiNarrator = 'AI_NARRATOR';
const String _kChatKeySystemMission = 'SYSTEM_MISSION';

/// Review Chat Screen (Sub Screen)
///
/// History Screen에서 진입. RoleplayResultDto(채팅 이력·아바타 경로)로 채팅 내용 열람.
/// Playing 스크린과 동일한 말풍선/나레이션/미션 배치 및 스타일 적용.
class ReviewChatScreen extends StatelessWidget {
  /// History에서 초기화한 롤플레이 결과 (chatHistory, avatarImgPath 포함)
  final RoleplayResultDto result;

  const ReviewChatScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerTitle: 'Chat History',
      showBackButton: true,
      backgroundColor: const Color(0xFF121212),
      usePadding: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bodyWidth = constraints.maxWidth;
          final history = result.chatHistory ?? [];
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No chat history.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < history.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  _buildEntry(context, bodyWidth, history[i]),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEntry(BuildContext context, double bodyWidth, SudaJson item) {
    final value = item.value;
    if (value.isEmpty) return const SizedBox.shrink();

    switch (item.key) {
      case _kChatKeyUser:
        return _buildUserBubble(context, bodyWidth, value);
      case _kChatKeyAiCharacter:
        return _buildAiBubble(context, bodyWidth, value);
      case _kChatKeyAiNarrator:
        return _buildNarrationBubble(context, value, isMission: false);
      case _kChatKeySystemMission:
        return _buildNarrationBubble(context, value, isMission: true);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserBubble(BuildContext context, double bodyWidth, String text) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.black,
        );
    final maxBubbleWidth = bodyWidth * 0.7;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: textStyle),
        ),
      ),
    );
  }

  Widget _buildAiBubble(BuildContext context, double bodyWidth, String text) {
    final bubbleWidth = bodyWidth * 0.7;
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white,
        );
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: bubbleWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(width: 5),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0CABA8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(text, style: textStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final path = result.avatarImgPath;
    if (path == null || path.isEmpty) {
      return Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          shape: BoxShape.circle,
        ),
      );
    }
    final url = '${AppConfig.cdnBaseUrl}$path';
    return ClipOval(
      child: Image(
        image: CachedNetworkImageProvider(url),
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildNarrationBubble(
    BuildContext context,
    String text, {
    required bool isMission,
  }) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontStyle: FontStyle.italic,
        );
    const missionColor = Color(0xFFFF00A6);
    return Center(
      child: isMission
          ? Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: missionColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Mission',
                    style: baseStyle?.copyWith(color: Colors.white),
                  ),
                ),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: baseStyle?.copyWith(color: missionColor),
                ),
              ],
            )
          : Text(
              text,
              textAlign: TextAlign.center,
              style: baseStyle?.copyWith(color: Colors.white),
            ),
    );
  }
}
