import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/app_scaffold.dart';

class OpenSourceLicenseScreen extends StatelessWidget {
  const OpenSourceLicenseScreen({super.key});

  static const List<_LicenseSection> _licenseSections = [
    _LicenseSection(
      title: 'BSD 3-Clause License',
      licenseUrl: 'https://opensource.org/license/bsd-3-clause',
      packages: [
        _PackageRef(name: 'connectivity_plus', version: '6.1.5'),
        _PackageRef(name: 'firebase_core', version: '3.15.2'),
        _PackageRef(name: 'firebase_messaging', version: '15.2.10'),
        _PackageRef(name: 'google_sign_in', version: '6.3.0'),
        _PackageRef(name: 'intl', version: '0.20.2'),
        _PackageRef(name: 'just_audio', version: '0.10.5'),
        _PackageRef(name: 'shared_preferences', version: '2.5.3'),
        _PackageRef(name: 'shimmer', version: '3.0.0'),
        _PackageRef(name: 'webview_flutter', version: '4.13.1'),
      ],
    ),
    _LicenseSection(
      title: 'MIT License',
      licenseUrl: 'https://opensource.org/license/mit',
      packages: [
        _PackageRef(name: 'cached_network_image', version: '3.4.1'),
        _PackageRef(name: 'cupertino_icons', version: '1.0.8'),
        _PackageRef(name: 'flutter_native_splash', version: '2.4.7'),
        _PackageRef(name: 'flutter_svg', version: '2.2.3'),
        _PackageRef(name: 'marquee', version: '2.3.0'),
        _PackageRef(name: 'permission_handler', version: '11.4.0'),
        _PackageRef(name: 'record', version: '6.1.2'),
        _PackageRef(name: 'uuid', version: '4.5.2'),
        _PackageRef(name: 'vibration', version: '3.1.5'),
      ],
    ),
    _LicenseSection(
      title: 'Apache License, Version 2.0',
      licenseUrl: 'https://www.apache.org/licenses/LICENSE-2.0',
      packages: [
        _PackageRef(name: 'flutter_secure_storage', version: '10.0.0'),
        _PackageRef(name: 'http', version: '1.6.0'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: l10n.settingsOpenSource,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Open Source Licenses',
              style: (textTheme.headlineLarge ??
                      const TextStyle(fontSize: 32))
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'This page provides information on some of the open-source '
              'libraries and their licenses used in the SUDA app.',
              style: (textTheme.headlineSmall ??
                      const TextStyle(fontSize: 20))
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),
            ..._licenseSections.map(
              (section) => _LicenseSectionView(section: section),
            ),
            const SizedBox(height: 12),
            Text(
              'Some packages may include additional transitive dependencies. '
              'For full license text, please check each package source.',
              style: (textTheme.bodySmall ?? const TextStyle(fontSize: 14))
                  .copyWith(color: const Color(0xFFB0B0B0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseSectionView extends StatelessWidget {
  final _LicenseSection section;

  const _LicenseSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: (textTheme.headlineSmall ?? const TextStyle(fontSize: 20))
                .copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          SelectableText(
            section.licenseUrl,
            style: (textTheme.bodySmall ?? const TextStyle(fontSize: 14))
                .copyWith(color: const Color(0xFF80D7CF)),
          ),
          const SizedBox(height: 14),
          ...section.packages.map(
            (pkg) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${pkg.name} ${pkg.version}',
                style: (textTheme.bodyMedium ?? const TextStyle(fontSize: 16))
                    .copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseSection {
  final String title;
  final String licenseUrl;
  final List<_PackageRef> packages;

  const _LicenseSection({
    required this.title,
    required this.licenseUrl,
    required this.packages,
  });
}

class _PackageRef {
  final String name;
  final String version;

  const _PackageRef({
    required this.name,
    required this.version,
  });
}
