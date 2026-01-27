class SudaAppPage<T> {
  final List<T> content;
  final int number;
  final int size;
  final bool last;
  final bool first;

  const SudaAppPage({
    required this.content,
    required this.number,
    required this.size,
    required this.last,
    required this.first,
  });

  factory SudaAppPage.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJsonT) {
    return SudaAppPage<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      number: json['number'] as int,
      size: json['size'] as int,
      last: json['last'] as bool,
      first: json['first'] as bool,
    );
  }
}
