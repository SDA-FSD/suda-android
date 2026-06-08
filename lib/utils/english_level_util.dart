/// `ENGLISH_LEVEL` 메타·API `languageLevel`의 단일 표현은 CEFR 라벨.
///
/// Pre-A1 / A1 / A2 / B1 / C1
class EnglishLevelUtil {
  EnglishLevelUtil._();

  static const String defaultLevel = 'Pre-A1';

  static const List<String> visibleLevels = [
    'Pre-A1',
    'A1',
    'A2',
    'B1',
  ];

  static const String fadedLevel = 'C1';

  static const Set<String> allLevels = {
    'Pre-A1',
    'A1',
    'A2',
    'B1',
    'C1',
  };

  /// 저장값을 CEFR 라벨로 정규화. 미설정·빈 값 → [defaultLevel].
  static String normalizeToCefr(String? raw) {
    if (raw == null || raw.isEmpty) return defaultLevel;

    final trimmed = raw.trim();
    if (allLevels.contains(trimmed)) return trimmed;

    return trimmed;
  }
}
