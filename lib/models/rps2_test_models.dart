class RpS2TestTurnDto {
  final String userText;
  final String narration;
  final String answer;
  final String score;
  final int mission;

  const RpS2TestTurnDto({
    required this.userText,
    required this.narration,
    required this.answer,
    required this.score,
    required this.mission,
  });

  factory RpS2TestTurnDto.fromJson(Map<String, dynamic> json) {
    return RpS2TestTurnDto(
      userText: (json['userText'] as String?) ?? '',
      narration: (json['narration'] as String?) ?? '',
      answer: (json['answer'] as String?) ?? '',
      score: (json['score'] as String?) ?? '',
      mission: (json['mission'] as num?)?.toInt() ?? -1,
    );
  }
}
