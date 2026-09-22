import 'package:flutter/material.dart';

/// `user.img_path` / 랭킹 스냅샷 `imgPath` 파서.
/// `DEFAULT:HEX` · `{NORMAL|RARE|EPIC}:{cdnPath}` · 구 스냅샷 http(s) URL.
class UserImgPath {
  static const defaultPrefix = 'DEFAULT:';
  static const nestedRarityBorderWidth = 5.0;
  static const fallbackHex = 'FFB700';
  static const fallbackStored = 'DEFAULT:$fallbackHex';
  static const fallbackColor = Color(0xFFFFB700);

  /// 빈 슬롯이 아닌 실제 유저의 `imgPath`가 비었을 때 1번 노랑으로 표시.
  static String orFallback(String? raw) {
    final value = raw?.trim() ?? '';
    return value.isEmpty ? fallbackStored : value;
  }

  const UserImgPath._({
    this.defaultColor,
    this.rarity,
    this.cdnPath,
    this.httpUrl,
  });

  final Color? defaultColor;
  final String? rarity;
  final String? cdnPath;
  final String? httpUrl;

  bool get isEmpty =>
      defaultColor == null && cdnPath == null && httpUrl == null;
  bool get isDefault => defaultColor != null;
  bool get isCharacter => rarity != null && cdnPath != null && cdnPath!.isNotEmpty;
  bool get isHttpUrl => httpUrl != null && httpUrl!.isNotEmpty;

  static UserImgPath parse(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) {
      return const UserImgPath._();
    }
    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return UserImgPath._(httpUrl: value);
    }
    if (value.startsWith(defaultPrefix)) {
      return UserImgPath._(
        defaultColor: parseHexColor(value.substring(defaultPrefix.length)),
      );
    }
    final colon = value.indexOf(':');
    if (colon > 0) {
      final type = value.substring(0, colon).toUpperCase();
      final path = value.substring(colon + 1).trim();
      if (path.isNotEmpty &&
          (type == 'NORMAL' || type == 'RARE' || type == 'EPIC')) {
        return UserImgPath._(rarity: type, cdnPath: path);
      }
    }
    return UserImgPath._(cdnPath: value);
  }

  static Color? parseHexColor(String hex) {
    final cleaned = hex.trim();
    if (cleaned.length != 6) return null;
    final parsed = int.tryParse(cleaned, radix: 16);
    if (parsed == null) return null;
    return Color(0xFF000000 | parsed);
  }
}
