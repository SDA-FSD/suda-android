/// 서버 Y/N 플래그 (`readYn`, `notiboxUnreadYn` 등). 문자열·bool·숫자 혼용 대비.
String sudaYnFromJson(dynamic v) {
  if (v == null) return 'N';
  if (v is bool) return v ? 'Y' : 'N';
  if (v is num) {
    // 관례: 1=읽음(Y), 그 외=미읽음(N)
    if (v == 1 || v == 1.0) return 'Y';
    return 'N';
  }
  if (v is String) {
    final t = v.trim().replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '').toUpperCase();
    switch (t) {
      case 'Y':
      case 'TRUE':
      case '1':
        return 'Y';
      default:
        return 'N';
    }
  }
  return 'N';
}

class SudaJson {
  final String key;
  final String value;

  const SudaJson({
    required this.key,
    required this.value,
  });

  factory SudaJson.fromJson(Map<String, dynamic> json) {
    return SudaJson(
      key: json['key'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}
