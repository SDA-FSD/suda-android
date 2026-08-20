class VersionDto {
  final String latestVersion;
  final String forceUpdateYn;
  final String? aosMarketLink;
  final String? iosMarketLink;

  const VersionDto({
    required this.latestVersion,
    required this.forceUpdateYn,
    this.aosMarketLink,
    this.iosMarketLink,
  });

  factory VersionDto.fromJson(Map<String, dynamic> json) {
    return VersionDto(
      latestVersion: (json['version'] ?? json['latestVersion']) as String? ?? '',
      forceUpdateYn: json['forceUpdateYn'] as String? ?? 'N',
      aosMarketLink: _parseMarketLink(json, 'aosMarketLink', 'androidMarketLink'),
      iosMarketLink: _parseMarketLink(json, 'iosMarketLink', 'appleMarketLink'),
    );
  }

  static String? _parseMarketLink(
    Map<String, dynamic> json,
    String primaryKey,
    String legacyKey,
  ) {
    final raw = (json[primaryKey] ?? json[legacyKey]) as String?;
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
