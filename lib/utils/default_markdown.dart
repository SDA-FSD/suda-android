import 'package:flutter/material.dart';

/// Default Markdown: 서버에서 내려오는 텍스트 중 `*`(이탤릭), `**`(볼드)만 파싱하여
/// [TextSpan] 리스트로 변환하는 공통 로직.
///
/// - `***텍스트***` → 볼드 + 이탤릭
/// - `**텍스트**` → 볼드
/// - `*텍스트*` → 이탤릭
/// - `***` → `**` → `*` 순서로 처리하며, 중첩(볼드 안 이탤릭 등)은 지원하지 않음.
/// - 줄바꿈은 그대로 유지됨 (호출 측에서 동일한 [Text] 위젯으로 표시).
class DefaultMarkdown {
  DefaultMarkdown._();

  static List<InlineSpan> _buildInlineSpansWithoutTriple(
    String text,
    TextStyle baseStyle,
  ) {
    final segments = <InlineSpan>[];

    // 1) ** 로 분리: 홀수 인덱스가 볼드 구간
    final byBold = text.split('**');
    for (var i = 0; i < byBold.length; i++) {
      if (i % 2 == 1) {
        segments.add(TextSpan(
          text: byBold[i],
          style: baseStyle.copyWith(fontWeight: FontWeight.w700),
        ));
      } else {
        // 2) 볼드가 아닌 구간에서 * 로 분리: 홀수 인덱스가 이탤릭 구간
        final byItalic = byBold[i].split('*');
        for (var j = 0; j < byItalic.length; j++) {
          segments.add(TextSpan(
            text: byItalic[j],
            style: j % 2 == 1
                ? baseStyle.copyWith(fontStyle: FontStyle.italic)
                : baseStyle,
          ));
        }
      }
    }

    return segments;
  }

  /// [text]를 파싱하여 [baseStyle]을 기준으로 [InlineSpan] 리스트를 반환.
  /// [Text.rich(TextSpan(children: DefaultMarkdown.buildSpans(...), style: baseStyle))] 형태로 사용.
  static List<InlineSpan> buildSpans(String? text, TextStyle baseStyle) {
    if (text == null || text.isEmpty) {
      return [TextSpan(text: '', style: baseStyle)];
    }

    // 0) *** 로 분리: 홀수 인덱스가 볼드+이탤릭 구간
    final segments = <InlineSpan>[];
    final byBoldItalic = text.split('***');
    for (var i = 0; i < byBoldItalic.length; i++) {
      if (i % 2 == 1) {
        segments.add(TextSpan(
          text: byBoldItalic[i],
          style: baseStyle.copyWith(
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else {
        segments.addAll(
          _buildInlineSpansWithoutTriple(byBoldItalic[i], baseStyle),
        );
      }
    }

    return segments;
  }
}
