class VersionDto {
  final String latestVersion;
  final String forceUpdateYn;
  final String skipOnboardingTutorialYn;
  final String skipRoleplayTutorialYn;

  const VersionDto({
    required this.latestVersion,
    required this.forceUpdateYn,
    this.skipOnboardingTutorialYn = 'N',
    this.skipRoleplayTutorialYn = 'N',
  });

  factory VersionDto.fromJson(Map<String, dynamic> json) {
    String yn(dynamic value) => value == 'Y' ? 'Y' : 'N';

    return VersionDto(
      latestVersion: (json['version'] ?? json['latestVersion']) as String? ?? '',
      forceUpdateYn: json['forceUpdateYn'] as String? ?? 'N',
      skipOnboardingTutorialYn: yn(json['skipOnboardingTutorialYn']),
      skipRoleplayTutorialYn: yn(json['skipRoleplayTutorialYn']),
    );
  }
}
