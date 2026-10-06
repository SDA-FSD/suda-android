import 'dart:convert';
import 'dart:typed_data';

class TtsResultDto {
  final String? text;
  final String? cdnYn;
  final String? cdnPath;
  /// Byte[] 음원. CDN 미사용(cdnYn == 'N')이거나 미제공 시 null.
  final Uint8List? sound;

  const TtsResultDto({
    this.text,
    this.cdnYn,
    this.cdnPath,
    this.sound,
  });

  factory TtsResultDto.fromJson(Map<String, dynamic> json) {
    return TtsResultDto(
      text: json['text'] as String?,
      cdnYn: json['cdnYn'] as String?,
      cdnPath: json['cdnPath'] as String?,
      sound: _parseBytes(json['sound']),
    );
  }
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

Uint8List? _parseBytes(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is List<int>) {
    return Uint8List.fromList(value);
  }
  if (value is List<dynamic>) {
    return Uint8List.fromList(value.map((item) => item as int).toList());
  }
  if (value is String && value.isNotEmpty) {
    return Uint8List.fromList(base64Decode(value));
  }
  return null;
}

class UserExpressionDto {
  final int? id;
  final int? userId;
  final int? roleplayResultId;
  final int? expressionIndex;
  final String? expression;
  final String? meaningUserLanguage;
  final String? rephrasedSentence;
  final String? createdAt;

  const UserExpressionDto({
    this.id,
    this.userId,
    this.roleplayResultId,
    this.expressionIndex,
    this.expression,
    this.meaningUserLanguage,
    this.rephrasedSentence,
    this.createdAt,
  });

  factory UserExpressionDto.fromJson(Map<String, dynamic> json) {
    return UserExpressionDto(
      id: _optionalInt(json['id']),
      userId: _optionalInt(json['userId']),
      roleplayResultId: _optionalInt(json['roleplayResultId']),
      expressionIndex: _optionalInt(json['expressionIndex']),
      expression: json['expression'] as String?,
      meaningUserLanguage: json['meaningUserLanguage'] as String?,
      rephrasedSentence: json['rephrasedSentence'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
