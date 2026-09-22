import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/user_models.dart';
import '../utils/user_img_path.dart';
import 'cdn_thumb_image.dart';
import 'character_rarity_frame.dart';

class SudaNeighborsRow extends StatelessWidget {
  const SudaNeighborsRow({super.key, required this.portraits, this.emptyText});

  static const _size = 70.0;
  static const _gap = 15.0;
  static const _gradientWidth = 30.0;
  static const _hPad = 24.0;

  final List<ClaimedCharacterPortraitDto> portraits;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: _size,
      width: double.infinity,
      child: portraits.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: _hPad),
              child: Center(
                child: Text(
                  emptyText ?? l10n.profileSudaNeighborsEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white),
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final count = portraits.length;
                final contentWidth = count * _size + (count - 1) * _gap;
                final overflow =
                    contentWidth > constraints.maxWidth - _hPad * 2;
                final list = ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: overflow
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: _hPad),
                  itemCount: count,
                  separatorBuilder: (_, _) => const SizedBox(width: _gap),
                  itemBuilder: (context, index) {
                    final item = portraits[index];
                    return CharacterRarityFrame(
                      key: ValueKey(
                        '${item.characterId}:${item.characterImgPath}',
                      ),
                      rarity: item.characterRarity,
                      size: _size,
                      borderWidth: UserImgPath.nestedRarityBorderWidth,
                      child: CdnThumbImage(
                        path: item.characterImgPath,
                        slot: CdnThumbSlot.characterReward,
                        width: _size,
                        height: _size,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                );
                if (!overflow) return list;
                return Stack(
                  children: [
                    list,
                    const Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0x00121212), Color(0xFF121212)],
                            ),
                          ),
                          child: SizedBox(width: _gradientWidth),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
