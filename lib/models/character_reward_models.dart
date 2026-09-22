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

  const CharacterRewardClaimDto({
    required this.userCharacterRewardId,
    required this.characterId,
    required this.characterRarity,
    this.characterName = '',
    required this.characterImgPath,
    this.totalImgCount = 0,
    this.currentImgProgress = 0,
    this.newCharacterYn = 'N',
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
    );
  }

  /// Lab Reward Unboxing 3건 연속 미리보기.
  static List<CharacterRewardClaimDto> labUnboxingPreviewItems() {
    return const [
      CharacterRewardClaimDto(
        userCharacterRewardId: 2,
        characterId: 1,
        characterName: 'Endalf',
        characterRarity: 'NORMAL',
        characterImgPath: '/rps2/characters/u8vgiy.png',
        totalImgCount: 3,
        currentImgProgress: 2,
        newCharacterYn: 'N',
      ),
      CharacterRewardClaimDto(
        userCharacterRewardId: 3,
        characterId: 2,
        characterName: 'Prista',
        characterRarity: 'RARE',
        characterImgPath: '/rps2/characters/u8vgiy.png',
        totalImgCount: 1,
        currentImgProgress: 1,
        newCharacterYn: 'Y',
      ),
      CharacterRewardClaimDto(
        userCharacterRewardId: 4,
        characterId: 3,
        characterName: 'Ninel',
        characterRarity: 'EPIC',
        characterImgPath: '/rps2/characters/u8vgiy.png',
        totalImgCount: 3,
        currentImgProgress: 3,
        newCharacterYn: 'N',
      ),
    ];
  }

  /// Lab Claim Preview용. 이미지 없음.
  static CharacterRewardClaimDto labMock() {
    return const CharacterRewardClaimDto(
      userCharacterRewardId: 0,
      characterId: 12,
      characterName: 'Luna',
      characterRarity: 'RARE',
      characterImgPath: '',
      totalImgCount: 3,
      currentImgProgress: 1,
      newCharacterYn: 'Y',
    );
  }
}
