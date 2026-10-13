class VersionDto {
  final String latestVersion;
  final String forceUpdateYn;

  const VersionDto({
    required this.latestVersion,
    required this.forceUpdateYn,
  });

  factory VersionDto.fromJson(Map<String, dynamic> json) {
    return VersionDto(
      latestVersion: (json['version'] ?? json['latestVersion']) as String? ?? '',
      forceUpdateYn: json['forceUpdateYn'] as String? ?? 'N',
    );
  }
}
