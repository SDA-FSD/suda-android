import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Play Billing `obfuscatedAccountId`용 해시.
///
/// 규칙(서버와 동일): `SHA-256(UTF-8("{userId}"))` → 소문자 hex 64자.
/// salt 없음. verify body에는 넣지 않음.
String iapObfuscatedAccountIdFromUserId(int userId) {
  final digest = sha256.convert(utf8.encode('$userId'));
  return digest.toString();
}
