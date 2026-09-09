/// CDN 폰트 팩 카탈로그. 재생 스크립트 `scripts/fonts/packs.json`과 동기화.
class FontPackCatalog {
  static const version = 'v1';
  static const packsPath = '/fonts/packs/$version';

  static const familyHei = 'ChironHeiHK';
  static const familyGo = 'ChironGoRoundTC';
  static const families = [familyHei, familyGo];
  static const bundledPackId = 'latn';

  static const bundledAsset = <String, String>{
    familyHei: 'assets/fonts/packs/ChironHeiHK-latn.ttf',
    familyGo: 'assets/fonts/packs/ChironGoRoundTC-latn.ttf',
  };

  /// CDN에 올린 팩만. 원본에 글리프가 없는 arab/thai/deva·GoRound-grek는 제외.
  static const publishedPacks = <String, Set<String>>{
    familyHei: {'latn', 'hang', 'jpan', 'hani', 'cyrl', 'grek'},
    familyGo: {'latn', 'hang', 'jpan', 'cyrl'},
  };

  /// packs.json `localePacks`와 동일. 미배포 팩은 [packsForFamily]에서 걸러진다.
  static const localePacks = <String, List<String>>{
    'en': ['latn'],
    'ko': ['latn', 'hang'],
    'ja': ['latn', 'jpan', 'hani'],
    'zh': ['latn', 'hani'],
    'zh_Hans': ['latn', 'hani'],
    'zh_Hant': ['latn', 'hani'],
    'pt': ['latn'],
    'es': ['latn'],
    'es_419': ['latn'],
    'fr': ['latn'],
    'de': ['latn'],
    'it': ['latn'],
    'vi': ['latn'],
    'id': ['latn'],
    'ms': ['latn'],
    'fil': ['latn'],
    'tr': ['latn'],
    'pl': ['latn'],
    'nl': ['latn'],
    'ru': ['latn', 'cyrl'],
    'el': ['latn', 'grek'],
    'ar': ['latn', 'arab'],
    'th': ['latn', 'thai'],
    'hi': ['latn', 'deva'],
  };

  static String fileName(String family, String packId) =>
      '$family-$packId.ttf';

  static String cdnPath(String family, String packId) =>
      '$packsPath/${fileName(family, packId)}';

  /// [candidates]는 BCP 47(`zh-Hans`) 또는 `_` 구분. 앞쪽 우선.
  static List<String> packsForLocale(List<String> candidates) {
    for (final raw in candidates) {
      final key = raw.replaceAll('-', '_');
      final direct = localePacks[key];
      if (direct != null) return List<String>.from(direct);
      final parts = key.split('_');
      if (parts.length >= 2) {
        final prefix = '${parts[0]}_${parts[1]}';
        final nested = localePacks[prefix];
        if (nested != null) return List<String>.from(nested);
      }
      final lang = localePacks[parts.first];
      if (lang != null) return List<String>.from(lang);
    }
    return List<String>.from(localePacks['en']!);
  }

  static List<String> packsForFamily(String family, List<String> wanted) {
    final published = publishedPacks[family];
    if (published == null) return const [];
    return wanted.where(published.contains).toList();
  }
}
