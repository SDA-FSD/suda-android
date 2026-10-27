import '../l10n/app_localizations.dart';
import '../models/common_models.dart';
import '../models/user_models.dart';

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

  /// 시리즈 플레이에 쓰는 레벨. `C1`은 `B1`, 그 외 미지원 값은 [defaultLevel].
  static String toPlayable(String? raw) {
    final level = normalizeToCefr(raw);
    if (level == fadedLevel) return 'B1';
    if (visibleLevels.contains(level)) return level;
    return defaultLevel;
  }

  static String readLevelFromUser(UserDto? user) {
    final meta = user?.metaInfo;
    if (meta == null) return defaultLevel;
    final levelMeta = meta.firstWhere(
      (m) => m.key == 'ENGLISH_LEVEL',
      orElse: () => const SudaJson(
        key: 'ENGLISH_LEVEL',
        value: defaultLevel,
      ),
    );
    return normalizeToCefr(levelMeta.value);
  }

  static String localizedLabel(AppLocalizations l10n, String? rawLevel) {
    final cefrLevel = normalizeToCefr(rawLevel);
    switch (cefrLevel) {
      case 'Pre-A1':
        return l10n.cefrLevelAbsoluteBeginner;
      case 'A1':
        return l10n.cefrLevelBeginner;
      case 'A2':
        return l10n.cefrLevelBasic;
      case 'B1':
        return l10n.cefrLevelIntermediate;
      default:
        return cefrLevel;
    }
  }
}
