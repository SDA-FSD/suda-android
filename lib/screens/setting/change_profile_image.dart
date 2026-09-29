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
    this.characterId,
  });

  factory _ProfileImageChoice.character({
    required String type,
    required String path,
    required int characterId,
  }) {
    return _ProfileImageChoice._(
      type: type,
      value: path,
      cdnPath: path,
      characterId: characterId,
    );
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
  final int? characterId;

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

/// Profile 상단 아바타 또는 Settings > Account 에서 진입하는 프로필 이미지 선택 Sub Screen.
/// 닫기·뒤로가기는 [Navigator.pop]으로 진입한 화면으로 돌아간다.
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

class _CharacterPortraits {
  const _CharacterPortraits({required this.characterId, required this.images});

  final int characterId;
  final List<_ProfileImageChoice> images;

  bool get expandable => images.length > 1;
}

class _ChangeProfileImageScreenState extends State<ChangeProfileImageScreen> {
  static const _gap = 8.0;
  static const _sectionGap = 24.0;
  static const _columns = 5;

  static const _openDuration = Duration(milliseconds: 220);

  List<_CharacterPortraits> _characters = const [];
  List<_ProfileImageChoice> _defaults = const [];
  final Map<int, _ProfileImageChoice> _faces = {};
  _ProfileImageChoice? _selected;
  int? _openCharacterId;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  List<_ProfileImageChoice> get _tiles => [
    for (final group in _characters) _face(group),
    ..._defaults,
  ];

  _ProfileImageChoice _face(_CharacterPortraits group) {
    return _faces[group.characterId] ?? group.images.first;
  }

  _CharacterPortraits? _groupOf(int? characterId) {
    if (characterId == null) return null;
    for (final group in _characters) {
      if (group.characterId == characterId) return group;
    }
    return null;
  }

  List<_ProfileImageChoice> _panelImages(_CharacterPortraits group) {
    final face = _face(group);
    return [
      face,
      for (final image in group.images)
        if (!identical(image, face)) image,
    ];
  }

  Future<void> _load() async {
    List<ClaimedCharacterPortraitDto> portraits = const [];
    List<ClaimedCharacterPortraitDto> neighbors = const [];
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final progress = await SudaApiClient.getProgress(accessToken: token);
        portraits = progress.claimedCharacters;
        neighbors = progress.neighborCharacters;
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Failed to load profile images: $e', isError: true);
      }
    }
    if (!mounted) return;
    final characters = _buildCharacters(portraits, neighbors);
    final defaults = [
      for (var i = 0; i < _ProfileImageChoice.defaults.length; i++)
        _ProfileImageChoice.fallback(i),
    ];
    final selected = _match(widget.imgPath, characters, defaults);
    setState(() {
      _characters = characters;
      _defaults = defaults;
      _faces
        ..clear()
        ..addEntries(
          characters.map(
            (group) => MapEntry(
              group.characterId,
              group.images.contains(selected) ? selected : group.images.first,
            ),
          ),
        );
      _selected = selected;
      _openCharacterId = null;
      _ready = true;
    });
  }

  List<_CharacterPortraits> _buildCharacters(
    List<ClaimedCharacterPortraitDto> portraits,
    List<ClaimedCharacterPortraitDto> neighbors,
  ) {
    final byId = <int, List<ClaimedCharacterPortraitDto>>{};
    final seenOrder = <int>[];
    for (final portrait in portraits) {
      if (portrait.characterId <= 0) continue;
      final path = portrait.characterImgPath.trim();
      if (path.isEmpty) continue;
      final group = byId.putIfAbsent(portrait.characterId, () {
        seenOrder.add(portrait.characterId);
        return [];
      });
      if (group.any((item) => item.characterImgPath.trim() == path)) continue;
      group.add(portrait);
    }

    final order = <int>[];
    final firstPath = <int, String>{};
    for (final neighbor in neighbors) {
      if (neighbor.characterId <= 0 || !byId.containsKey(neighbor.characterId)) {
        continue;
      }
      if (order.contains(neighbor.characterId)) continue;
      order.add(neighbor.characterId);
      final path = neighbor.characterImgPath.trim();
      if (path.isNotEmpty) firstPath[neighbor.characterId] = path;
    }
    for (final id in seenOrder) {
      if (!order.contains(id)) order.add(id);
    }

    return [
      for (final id in order)
        _CharacterPortraits(
          characterId: id,
          images: _orderedImages(byId[id]!, firstPath[id]),
        ),
    ];
  }

  List<_ProfileImageChoice> _orderedImages(
    List<ClaimedCharacterPortraitDto> newestFirst,
    String? firstImagePath,
  ) {
    final ordered = newestFirst.reversed.toList();
    if (firstImagePath != null && firstImagePath.isNotEmpty) {
      final index = ordered.indexWhere(
        (item) => item.characterImgPath.trim() == firstImagePath,
      );
      if (index > 0) {
        final first = ordered.removeAt(index);
        ordered.insert(0, first);
      }
    }
    return [
      for (final portrait in ordered)
        _ProfileImageChoice.character(
          type: CharacterRarityFrame.normalize(portrait.characterRarity),
          path: portrait.characterImgPath.trim(),
          characterId: portrait.characterId,
        ),
    ];
  }

  _ProfileImageChoice _match(
    String? raw,
    List<_CharacterPortraits> characters,
    List<_ProfileImageChoice> defaults,
  ) {
    final parsed = UserImgPath.parse(raw);
    if (parsed.isCharacter) {
      for (final group in characters) {
        for (final item in group.images) {
          if (item.cdnPath == parsed.cdnPath && item.type == parsed.rarity) {
            return item;
          }
        }
      }
    }
    if (parsed.isDefault && parsed.defaultColor != null) {
      for (final item in defaults) {
        if (item.color == parsed.defaultColor) return item;
      }
    }
    return defaults.firstWhere((item) => item.value == '1');
  }

  void _onTileTap(_ProfileImageChoice item) {
    final group = _groupOf(item.characterId);
    setState(() {
      if (group == null || !group.expandable) {
        _selected = item;
        _openCharacterId = null;
        return;
      }
      _selected = _face(group);
      _openCharacterId = _openCharacterId == group.characterId
          ? null
          : group.characterId;
    });
  }

  void _onPanelTap(_ProfileImageChoice item) {
    final id = item.characterId;
    if (id == null) return;
    setState(() {
      _faces[id] = item;
      _selected = item;
      _openCharacterId = null;
    });
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
        final cell = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        final tiles = _tiles;
        final rowCount = tiles.isEmpty
            ? 0
            : (tiles.length + _columns - 1) ~/ _columns;
        return Column(
          children: [
            for (var row = 0; row < rowCount; row++) ...[
              if (row > 0) const SizedBox(height: _gap),
              _tileRow(
                tiles.skip(row * _columns).take(_columns).toList(),
                cell,
                selected,
              ),
              _panelSlot(row, tiles, cell),
            ],
          ],
        );
      },
    );
  }

  Widget _tileRow(
    List<_ProfileImageChoice> tiles,
    double cell,
    _ProfileImageChoice selected,
  ) {
    return Row(
      children: [
        for (var i = 0; i < _columns; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          SizedBox(
            width: cell,
            height: cell,
            child: i < tiles.length
                ? GestureDetector(
                    onTap: () => _onTileTap(tiles[i]),
                    child: _gridFace(
                      tiles[i],
                      cell,
                      selected: identical(tiles[i], selected) &&
                          tiles[i].characterId != _openCharacterId,
                      dimmed: tiles[i].characterId != null &&
                          tiles[i].characterId == _openCharacterId,
                    ),
                  )
                : null,
          ),
        ],
      ],
    );
  }

  Widget _panelSlot(int row, List<_ProfileImageChoice> tiles, double cell) {
    final openId = _openCharacterId;
    final openIndex = openId == null
        ? -1
        : tiles.indexWhere((item) => item.characterId == openId);
    final group = openIndex >= 0 && openIndex ~/ _columns == row
        ? _groupOf(openId)
        : null;
    final images = group == null
        ? const <_ProfileImageChoice>[]
        : _panelImages(group);
    return AnimatedSize(
      duration: _openDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: images.isEmpty
          ? const SizedBox(width: double.infinity, height: 0)
          : Padding(
              padding: const EdgeInsets.only(top: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x14FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x3380D7CF)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: _centeredPortraits(images, cell),
                ),
              ),
            ),
    );
  }

  Widget _centeredPortraits(List<_ProfileImageChoice> images, double cell) {
    return SizedBox(
      height: cell,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < images.length; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: cell,
                      height: cell,
                      child: GestureDetector(
                        onTap: () => _onPanelTap(images[i]),
                        child: _gridFace(
                          images[i],
                          cell,
                          selected: identical(images[i], _selected),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _gridFace(
    _ProfileImageChoice item,
    double size, {
    required bool selected,
    bool dimmed = false,
  }) {
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          foregroundDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
          ),
          child: ClipOval(child: face),
        ),
        if (dimmed)
          const DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0x99000000),
            ),
          ),
      ],
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
