import 'home_models.dart';

class CharacterDetailDto {
  final int id;
  final String name;
  final String rarity;
  final String? ageRange;
  final String? nationality;
  final String? occupation;
  final List<String> interests;
  final List<String> personalities;
  final List<String> rpImgPaths;
  final List<HomeSeriesDto> series;
  final List<String> ownedImgPaths;
  final List<String>? secrets;

  const CharacterDetailDto({
    required this.id,
    required this.name,
    required this.rarity,
    this.ageRange,
    this.nationality,
    this.occupation,
    this.interests = const [],
    this.personalities = const [],
    this.rpImgPaths = const [],
    this.series = const [],
    this.ownedImgPaths = const [],
    this.secrets,
  });

  bool get secretUnlocked => secrets != null;

  factory CharacterDetailDto.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((item) => item?.toString() ?? '').where((item) => item.isNotEmpty).toList();
    }

    final seriesRaw = json['series'];
    return CharacterDetailDto(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: json['name'] as String? ?? '',
      rarity: json['rarity'] as String? ?? '',
      ageRange: _blankToNull(json['ageRange']),
      nationality: _blankToNull(json['nationality']),
      occupation: _blankToNull(json['occupation']),
      interests: strings(json['interests']),
      personalities: strings(json['personalities']),
      rpImgPaths: json['rpImgPaths'] is List
          ? (json['rpImgPaths'] as List).map((item) => item?.toString() ?? '').toList()
          : const [],
      series: seriesRaw is List
          ? seriesRaw
              .whereType<Map>()
              .map((item) => HomeSeriesDto.fromJson(Map<String, dynamic>.from(item)))
              .where((item) => item.id > 0)
              .toList()
          : const [],
      ownedImgPaths: strings(json['ownedImgPaths']),
      secrets: json.containsKey('secrets') ? strings(json['secrets']) : null,
    );
  }
}

String? _blankToNull(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
