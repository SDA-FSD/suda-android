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
