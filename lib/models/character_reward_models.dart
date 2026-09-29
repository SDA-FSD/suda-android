import 'common_models.dart';

/// `POST /v1/rank/character-rewards/claim` 수령 항목.
/// Reward Unboxing · Profile 업적/레벨업 보상과 동일 형태.
class CharacterRewardClaimDto {
  final int userCharacterRewardId;
  final int characterId;
  final String characterRarity; // NORMAL | RARE | EPIC
  final String characterName;
  final String characterImgPath;
  final int totalImgCount;
  final int currentImgProgress;
  final String newCharacterYn;
  final List<String> rpImgPaths;
  final List<String> ownedImgPaths;

  const CharacterRewardClaimDto({
    required this.userCharacterRewardId,
    required this.characterId,
    required this.characterRarity,
    this.characterName = '',
    required this.characterImgPath,
    this.totalImgCount = 0,
    this.currentImgProgress = 0,
    this.newCharacterYn = 'N',
    this.rpImgPaths = const [],
    this.ownedImgPaths = const [],
  });

  bool get isNewCharacter => newCharacterYn == 'Y';

  factory CharacterRewardClaimDto.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return CharacterRewardClaimDto(
      userCharacterRewardId: asInt(json['userCharacterRewardId']),
      characterId: asInt(json['characterId']),
      characterRarity: json['characterRarity'] as String? ?? '',
      characterName: json['characterName'] as String? ?? '',
      characterImgPath: json['characterImgPath'] as String? ?? '',
      totalImgCount: asInt(json['totalImgCount']),
      currentImgProgress: asInt(json['currentImgProgress']),
      newCharacterYn: sudaYnFromJson(json['newCharacterYn']),
      rpImgPaths: _stringList(json['rpImgPaths']),
      ownedImgPaths: _stringList(json['ownedImgPaths']),
    );
  }

  static const _labPortrait = '/rps2/characters/u8vgiy.png';

  /// Lab Reward Unboxing 3건 연속 미리보기.
  static List<CharacterRewardClaimDto> labUnboxingPreviewItems() {
    return const [
      CharacterRewardClaimDto(
        userCharacterRewardId: 2,
        characterId: 1,
        characterName: 'Endalf',
        characterRarity: 'NORMAL',
        characterImgPath: _labPortrait,
        totalImgCount: 3,
        currentImgProgress: 2,
        newCharacterYn: 'N',
        rpImgPaths: [_labPortrait, _labPortrait, _labPortrait],
        ownedImgPaths: [_labPortrait],
      ),
      CharacterRewardClaimDto(
        userCharacterRewardId: 3,
        characterId: 2,
        characterName: 'Prista',
        characterRarity: 'RARE',
        characterImgPath: _labPortrait,
        totalImgCount: 1,
        currentImgProgress: 1,
        newCharacterYn: 'Y',
        rpImgPaths: [_labPortrait],
        ownedImgPaths: [],
      ),
      CharacterRewardClaimDto(
        userCharacterRewardId: 4,
        characterId: 3,
        characterName: 'Ninel',
        characterRarity: 'EPIC',
        characterImgPath: _labPortrait,
        totalImgCount: 3,
        currentImgProgress: 3,
        newCharacterYn: 'N',
        rpImgPaths: [_labPortrait, _labPortrait, _labPortrait],
        ownedImgPaths: [_labPortrait, _labPortrait],
      ),
    ];
  }

  /// Lab Claim Preview용. 샘플 초상화를 칸마다 재사용.
  static CharacterRewardClaimDto labMock() {
    return const CharacterRewardClaimDto(
      userCharacterRewardId: 0,
      characterId: 12,
      characterName: 'Luna',
      characterRarity: 'RARE',
      characterImgPath: _labPortrait,
      totalImgCount: 3,
      currentImgProgress: 1,
      newCharacterYn: 'Y',
      rpImgPaths: [_labPortrait, _labPortrait, _labPortrait],
      ownedImgPaths: [],
    );
  }
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return [
    for (final item in raw)
      if (item != null) item.toString(),
  ];
}
