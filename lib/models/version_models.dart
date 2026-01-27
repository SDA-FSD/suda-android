class VersionDto {
  final String latestVersion;
  final String forceUpdateYn;
  final String? androidMarketLink;
  final String? appleMarketLink;

  const VersionDto({
    required this.latestVersion,
    required this.forceUpdateYn,
    this.androidMarketLink,
    this.appleMarketLink,
  });

  factory VersionDto.fromJson(Map<String, dynamic> json) {
    return VersionDto(
      latestVersion: (json['version'] ?? json['latestVersion']) as String? ?? '',
      forceUpdateYn: json['forceUpdateYn'] as String? ?? 'N',
      androidMarketLink: json['androidMarketLink'] as String?,
      appleMarketLink: json['appleMarketLink'] as String?,
    );
  }
}
