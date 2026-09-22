import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/main_user_sync.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/user_img_path.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/cdn_thumb_image.dart';
import '../../widgets/character_rarity_frame.dart';
import '../../widgets/default_profile_avatar.dart';
import '../../widgets/user_profile_avatar.dart';

class _ProfileImageChoice {
  const _ProfileImageChoice._({
    required this.type,
    required this.value,
    this.cdnPath,
    this.color,
  });

  factory _ProfileImageChoice.character({
    required String type,
    required String path,
  }) {
    return _ProfileImageChoice._(type: type, value: path, cdnPath: path);
  }

  factory _ProfileImageChoice.fallback(int index) {
    return _ProfileImageChoice._(
      type: 'DEFAULT',
      value: '${index + 1}',
      color: _ProfileImageChoice.defaults[index],
    );
  }

  static const defaults = <Color>[
    Color(0xFFFFB700),
    Color(0xFFFFAAE1),
    Color(0xFFB286EB),
    Color(0xFF054544),
  ];

  final String type;
  final String value;
  final String? cdnPath;
  final Color? color;

  bool get isDefault => color != null;

  String get stored {
    if (isDefault) {
      final hex = color!.toARGB32().toRadixString(16).padLeft(8, '0');
      return 'DEFAULT:${hex.substring(2).toUpperCase()}';
    }
    return '$type:$value';
  }

  String get previewPath => stored;
}

/// Settings > Account 에서 진입하는 프로필 이미지 선택 Sub Screen.
class ChangeProfileImageScreen extends StatefulWidget {
  const ChangeProfileImageScreen({
    super.key,
    required this.imgPath,
    required this.isPremium,
  });

  final String? imgPath;
  final bool isPremium;

  @override
  State<ChangeProfileImageScreen> createState() =>
      _ChangeProfileImageScreenState();
}

class _ChangeProfileImageScreenState extends State<ChangeProfileImageScreen> {
  static const _gap = 8.0;
  static const _sectionGap = 24.0;

  List<_ProfileImageChoice> _items = const [];
  _ProfileImageChoice? _selected;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    List<ClaimedCharacterPortraitDto> portraits = const [];
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final progress = await SudaApiClient.getProgress(accessToken: token);
        portraits = progress.claimedCharacters;
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Failed to load profile images: $e', isError: true);
      }
    }
    if (!mounted) return;
    final items = _buildItems(portraits);
    setState(() {
      _items = items;
      _selected = _match(widget.imgPath, items);
      _ready = true;
    });
  }

  List<_ProfileImageChoice> _buildItems(
    List<ClaimedCharacterPortraitDto> portraits,
  ) {
    final seen = <String>{};
    final items = <_ProfileImageChoice>[];
    for (final portrait in portraits) {
      final path = portrait.characterImgPath.trim();
      if (path.isEmpty || !seen.add(path)) continue;
      items.add(
        _ProfileImageChoice.character(
          type: CharacterRarityFrame.normalize(portrait.characterRarity),
          path: path,
        ),
      );
    }
    for (var i = 0; i < _ProfileImageChoice.defaults.length; i++) {
      items.add(_ProfileImageChoice.fallback(i));
    }
    return items;
  }

  _ProfileImageChoice _match(String? raw, List<_ProfileImageChoice> items) {
    final parsed = UserImgPath.parse(raw);
    if (parsed.isCharacter) {
      for (final item in items) {
        if (item.cdnPath == parsed.cdnPath && item.type == parsed.rarity) {
          return item;
        }
      }
    }
    if (parsed.isDefault && parsed.defaultColor != null) {
      for (final item in items) {
        if (item.color == parsed.defaultColor) return item;
      }
    }
    return items.firstWhere((item) => item.value == '1' && item.isDefault);
  }

  bool _sameAsCurrent(_ProfileImageChoice selected) {
    final current = (widget.imgPath ?? '').trim().toUpperCase();
    return current.isNotEmpty && current == selected.stored.toUpperCase();
  }

  Future<void> _onDone() async {
    final selected = _selected;
    if (selected == null || _saving) return;
    if (_sameAsCurrent(selected)) {
      Navigator.of(context).pop();
      return;
    }
    final token = await TokenStorage.loadAccessToken();
    if (token == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await SudaApiClient.updateProfileImage(
        accessToken: token,
        type: selected.type,
        value: selected.value,
      );
      final user = await SudaApiClient.getCurrentUser(accessToken: token);
      MainUserSync.instance.notifyUserUpdated(user);
      if (!mounted) return;
      Navigator.of(context).pop(user);
    } catch (e) {
      if (mounted) {
        DefaultToast.show(
          context,
          'Failed to update profile image: $e',
          isError: true,
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final selected = _selected;

    return AppScaffold(
      centerTitle: '',
      body: _ready && selected != null
          ? SingleChildScrollView(
              child: Column(
                children: [
                  Text(
                    l10n.changeProfileImageTitle,
                    textAlign: TextAlign.center,
                    style: theme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: _sectionGap),
                  UserProfileAvatar(
                    imgPath: selected.previewPath,
                    isPremium: widget.isPremium,
                    size: MediaQuery.sizeOf(context).width * 0.5,
                    useOriginal: true,
                  ),
                  const SizedBox(height: _sectionGap),
                  _grid(selected),
                  const SizedBox(height: _sectionGap),
                  _doneButton(theme),
                  const SizedBox(height: _sectionGap),
                ],
              ),
            )
          : const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
    );
  }

  Widget _grid(_ProfileImageChoice selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = (constraints.maxWidth - _gap * 4) / 5;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (var i = 0; i < _items.length; i++)
              SizedBox(
                width: cell,
                height: cell,
                child: GestureDetector(
                  onTap: () => setState(() => _selected = _items[i]),
                  child: _gridFace(_items[i], cell, identical(_items[i], selected)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _gridFace(_ProfileImageChoice item, double size, bool selected) {
    final Widget face;
    final path = item.cdnPath;
    if (path != null) {
      face = CdnThumbImage(
        path: path,
        slot: CdnThumbSlot.characterReward,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: (_, _, _) => DefaultProfileAvatar(
          size: size,
          color: UserImgPath.fallbackColor,
        ),
      );
    } else {
      face = DefaultProfileAvatar(
        size: size,
        color: item.color ?? UserImgPath.fallbackColor,
      );
    }
    return Container(
      foregroundDecoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected ? Border.all(color: Colors.white, width: 2) : null,
      ),
      child: ClipOval(child: face),
    );
  }

  Widget _doneButton(TextTheme theme) {
    final enabled = _selected != null && !_saving;
    return Center(
      child: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.5,
        child: Material(
          color: Colors.white,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: enabled ? () => unawaited(_onDone()) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      'Done',
                      textAlign: TextAlign.center,
                      style: theme.bodyLarge?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                        fontVariations: const [FontVariation('wght', 600)],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
