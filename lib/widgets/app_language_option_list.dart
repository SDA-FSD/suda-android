import 'package:flutter/material.dart';

import '../utils/app_language_options.dart';

class AppLanguageOptionList extends StatelessWidget {
  final List<AppLanguageOption> options;
  final String? selectedId;
  final bool submitting;
  final ValueChanged<String> onSelect;
  final VoidCallback? onConfirm;
  final String buttonLabel;

  const AppLanguageOptionList({
    super.key,
    required this.options,
    required this.selectedId,
    required this.submitting,
    required this.onSelect,
    required this.onConfirm,
    required this.buttonLabel,
  });

  static const _selected = Color(0xFF0CABA8);
  static const _optionTextStyle = TextStyle(
    fontFamily: 'ChironGoRoundTC',
    fontFamilyFallback: ['ChironHeiHK'],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    color: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fadeHeight = constraints.maxHeight / 3;
        return Stack(
          children: [
            ListView.separated(
              padding: EdgeInsets.fromLTRB(24, 8, 24, fadeHeight),
              itemCount: options.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = option.id == selectedId;
                return Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: 0.8,
                    child: Material(
                      color: selected ? _selected : Colors.transparent,
                      shape: StadiumBorder(
                        side: selected
                            ? BorderSide.none
                            : const BorderSide(
                                color: Color(0xFF635F5F),
                                width: 1,
                              ),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: submitting ? null : () => onSelect(option.id),
                        child: SizedBox(
                          height: 52,
                          child: Center(
                            child: Text(
                              option.label,
                              style: _optionTextStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: fadeHeight,
              child: const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xFF000000),
                        Color(0xFF000000),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: fadeHeight,
              child: Center(
                child: SizedBox(
                  height: 60,
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withOpacity(0.6),
                      disabledForegroundColor: Colors.black.withOpacity(0.6),
                      elevation: 0,
                      shape: const StadiumBorder(),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                    ),
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : Text(buttonLabel),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
