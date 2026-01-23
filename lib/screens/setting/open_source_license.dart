import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';

class OpenSourceLicenseScreen extends StatelessWidget {
  const OpenSourceLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      centerTitle: 'Open source license',
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // heading1
            Text(
              'Heading 1 - 32 / w700',
              style: (textTheme.headlineLarge ??
                      const TextStyle(fontSize: 32))
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // heading2
            Text(
              'Heading 2 - 24 / w600',
              style: (textTheme.headlineMedium ??
                      const TextStyle(fontSize: 24))
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 12),

            // heading3
            Text(
              'Heading 3 - 20 / w700',
              style: (textTheme.headlineSmall ??
                      const TextStyle(fontSize: 20))
                  .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 24),

            // body-default
            Text(
              'Body default - 18 / w400',
              style:
                  (textTheme.bodyLarge ?? const TextStyle(fontSize: 18))
                      .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),

            // body-secondary
            Text(
              'Body secondary - 16 / w400',
              style:
                  (textTheme.bodyMedium ??
                          const TextStyle(fontSize: 16))
                      .copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),

            // body-caption
            Text(
              'Body caption - 14 / w400',
              style:
                  (textTheme.bodySmall ?? const TextStyle(fontSize: 14))
                      .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
