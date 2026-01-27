class SudaAuthTokens {
  final String accessToken;
  final String? refreshToken;

  const SudaAuthTokens({
    required this.accessToken,
    this.refreshToken,
  });

  factory SudaAuthTokens.fromJson(Map<String, dynamic> json) {
    return SudaAuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
  }
}
