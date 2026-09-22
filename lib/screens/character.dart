import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/character_detail.dart';
import '../routes/series_router.dart';
import '../services/main_user_sync.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../widgets/cdn_thumb_image.dart';
import '../utils/default_toast.dart';
import '../utils/full_screen_route.dart';
import '../utils/user_img_path.dart';
import '../widgets/character_rarity_frame.dart';
import '../widgets/default_popup.dart';
import 'home.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key, required this.characterId});

  final int characterId;

  static Future<void> open(BuildContext context, int characterId) {
    if (characterId <= 0) return Future.value();
    return Navigator.of(context).push(
      FullScreenRoute<void>(
        page: CharacterScreen(characterId: characterId),
        transition: FullScreenTransition.bottomUp,
      ),
    );
  }

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  CharacterDetailDto? _detail;
  String? _imgPath;
  bool _savingProfile = false;
  String? _zoomPath;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        if (mounted) Navigator.of(context).maybePop();
        return;
      }
      final results = await Future.wait([
        SudaApiClient.getCharacter(
          accessToken: token,
          characterId: widget.characterId,
        ),
        SudaApiClient.getCurrentUser(accessToken: token),
      ]);
      if (!mounted) return;
      setState(() {
        _detail = results[0] as CharacterDetailDto;
        _imgPath = (results[1] as UserDto).imgPath;
      });
    } catch (e) {
      if (!mounted) return;
      DefaultToast.show(context, 'Failed to load character: $e', isError: true);
      Navigator.of(context).maybePop();
    }
  }

  /// 저장값 `RARE:/path`가 아니라 요청 `{type, value}`의 value.
  String _profileImageValue(String path) {
    final parsed = UserImgPath.parse(path);
    if (parsed.isCharacter && parsed.cdnPath != null && parsed.cdnPath!.isNotEmpty) {
      return parsed.cdnPath!;
    }
    return path.trim();
  }

  bool _imgPathApplied(String? imgPath, {required String type, required String value}) {
    final parsed = UserImgPath.parse(imgPath);
    return parsed.isCharacter &&
        parsed.cdnPath == value &&
        CharacterRarityFrame.normalize(parsed.rarity ?? '') == type;
  }

  bool _isCurrentProfile(String path) {
    final parsed = UserImgPath.parse(_imgPath);
    final rarity = CharacterRarityFrame.normalize(_detail?.rarity ?? '');
    return parsed.isCharacter &&
        parsed.cdnPath == path &&
        CharacterRarityFrame.normalize(parsed.rarity ?? '') == rarity;
  }

  Future<void> _confirmSetProfile(String path) async {
    final detail = _detail;
    if (detail == null || _savingProfile || _isCurrentProfile(path)) return;
    await DefaultPopup.show(
      context,
      titleText: AppLocalizations.of(context)!.characterChangePictureTitle,
      bodyWidget: _ProfilePreview(path: path),
      buttons: [
        DefaultPopupButton(
          type: DefaultPopupButtonType.primary,
          label: AppLocalizations.of(context)!.characterChange,
          onPressed: () => unawaited(_applySetProfile(path)),
        ),
        DefaultPopupButton(
          type: DefaultPopupButtonType.text,
          label: AppLocalizations.of(context)!.characterCancel,
          onPressed: () {},
        ),
      ],
    );
  }

  Future<void> _applySetProfile(String path) async {
    final detail = _detail;
    if (!mounted || detail == null || _savingProfile) return;
    setState(() => _savingProfile = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) return;
      final type = CharacterRarityFrame.normalize(detail.rarity);
      final value = _profileImageValue(path);
      await SudaApiClient.updateProfileImage(
        accessToken: token,
        type: type,
        value: value,
      );
      final user = await SudaApiClient.getCurrentUser(accessToken: token);
      if (!mounted) return;
      if (!_imgPathApplied(user.imgPath, type: type, value: value)) {
        DefaultToast.show(
          context,
          AppLocalizations.of(context)!.characterChangeFailed,
          isError: true,
        );
        return;
      }
      MainUserSync.instance.notifyUserUpdated(user);
      setState(() {
        _imgPath = user.imgPath;
        _zoomPath = null;
      });
    } catch (_) {
      if (!mounted) return;
      DefaultToast.show(
        context,
        AppLocalizations.of(context)!.characterChangeFailed,
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (detail != null)
            DecoratedBox(
              decoration: BoxDecoration(gradient: _background(detail.rarity)),
              child: const SizedBox.expand(),
            ),
          SafeArea(
            child: detail == null
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _body(detail),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
          if (_zoomPath != null) _zoom(_zoomPath!),
        ],
      ),
    );
  }

  Widget _body(CharacterDetailDto detail) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 32),
      children: [
        _header(detail, theme),
        if (detail.personalities.isNotEmpty) ...[
          const SizedBox(height: 24),
          _personalities(detail.personalities, theme),
        ],
        const SizedBox(height: 24),
        _sectionTitle(l10n.characterCollection, theme),
        const SizedBox(height: 12),
        _collection(detail, theme),
        const SizedBox(height: 24),
        _sectionTitle(l10n.characterSecret, theme),
        const SizedBox(height: 12),
        _secret(detail, l10n, theme),
        if (detail.series.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle(l10n.characterSeriesWith(detail.name), theme),
          const SizedBox(height: 12),
          _series(detail),
        ],
      ],
    );
  }

  Widget _header(CharacterDetailDto detail, TextTheme theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth * 0.4;
        final rightWidth = constraints.maxWidth * 0.6;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: leftWidth,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _hero(detail, leftWidth),
                ),
              ),
              SizedBox(
                width: rightWidth,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20),
                  child: _facts(detail, theme),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(CharacterDetailDto detail, double size) {
    final path = detail.rpImgPaths.isEmpty ? '' : detail.rpImgPaths.first.trim();
    final image = path.isEmpty
        ? const ColoredBox(color: Color(0xFF2A2A2A))
        : CachedNetworkImage(
            imageUrl: CdnThumbUrl.original(path),
            fit: BoxFit.cover,
            errorWidget: (_, _, _) => const ColoredBox(color: Color(0xFF2A2A2A)),
          );
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: _downRightCircleShadow(size),
            child: const SizedBox.expand(),
          ),
          CharacterRarityFrame(
            rarity: detail.rarity,
            size: size,
            borderWidth: 5,
            child: image,
          ),
        ],
      ),
    );
  }

  Widget _facts(CharacterDetailDto detail, TextTheme theme) {
    final l10n = AppLocalizations.of(context)!;
    final rarity = _rarityLabel(detail.rarity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: detail.name,
                style: theme.headlineMedium?.copyWith(color: Colors.white),
              ),
              TextSpan(
                text: ' [$rarity]',
                style: theme.bodySmall?.copyWith(color: _rarityColor(detail.rarity)),
              ),
            ],
          ),
        ),
        SizedBox(height: (theme.headlineMedium?.fontSize ?? 24) * (theme.headlineMedium?.height ?? 1.2)),
        if (detail.ageRange != null)
          _fact(l10n.characterAge, detail.ageRange!, theme),
        if (detail.nationality != null)
          _fact(l10n.characterNationality, detail.nationality!, theme),
        if (detail.occupation != null)
          _fact(l10n.characterOccupation, detail.occupation!, theme),
        if (detail.interests.isNotEmpty)
          _fact(l10n.characterInterests, detail.interests.join(', '), theme),
      ],
    );
  }

  Widget _fact(String label, String value, TextTheme theme) {
    final base = theme.bodyMedium?.copyWith(color: Colors.white);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: base?.copyWith(
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
            TextSpan(text: value, style: base),
          ],
        ),
      ),
    );
  }

  Widget _personalities(List<String> items, TextTheme theme) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final item in items)
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF635F5F),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                item,
                style: theme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _collection(CharacterDetailDto detail, TextTheme theme) {
    final count = detail.rpImgPaths.length < 3 ? 3 : detail.rpImgPaths.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 24.0;
        final slot = (constraints.maxWidth - gap * 2) / 3;
        final items = [
          for (var i = 0; i < count; i++)
            SizedBox(
              width: slot,
              child: _collectionSlot(detail, i, slot, theme),
            ),
        ];
        if (count <= 3) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                items[i],
              ],
            ],
          );
        }
        return SizedBox(
          height: slot + 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: gap),
            itemBuilder: (_, index) => items[index],
          ),
        );
      },
    );
  }

  Widget _collectionSlot(
    CharacterDetailDto detail,
    int index,
    double size,
    TextTheme theme,
  ) {
    final path = index < detail.rpImgPaths.length ? detail.rpImgPaths[index].trim() : '';
    final owned = path.isNotEmpty && detail.ownedImgPaths.contains(path);
    final current = owned && _isCurrentProfile(path);
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        GestureDetector(
          onTap: owned ? () => setState(() => _zoomPath = path) : null,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: _downRightCircleShadow(size),
                  child: const SizedBox.expand(),
                ),
                if (owned)
                  ClipOval(
                    child: CdnThumbImage(
                      path: path,
                      slot: CdnThumbSlot.profileAvatar,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xA3570B3C),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/icons/lock.png',
                        width: size * 0.4,
                        height: size * 0.4,
                        color: _lockColor(detail.rarity),
                      ),
                    ),
                  ),
                if (current)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0CABA8),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/icons/check_raw.png',
                        width: 16,
                        height: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (owned && !current)
          GestureDetector(
            onTap: () => unawaited(_confirmSetProfile(path)),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                l10n.characterSetAsProfile,
                textAlign: TextAlign.center,
                style: theme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  Widget _secret(CharacterDetailDto detail, AppLocalizations l10n, TextTheme theme) {
    final unlocked = detail.secretUnlocked;
    final lockSize = ((MediaQuery.sizeOf(context).width - 96) / 3) * 0.4;
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.9,
        child: GestureDetector(
        onTap: unlocked
            ? null
            : () => DefaultToast.show(context, l10n.characterSecretLocked),
        child: Container(
          constraints: BoxConstraints(minHeight: unlocked ? 0 : 130),
          height: unlocked ? null : 130,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xA3570B3C),
            borderRadius: BorderRadius.circular(16),
          ),
          child: unlocked
              ? Text(
                  (detail.secrets ?? const []).join('\n'),
                  textAlign: TextAlign.center,
                  style: theme.bodySmall?.copyWith(color: Colors.white),
                )
              : Image.asset(
                  'assets/images/icons/lock.png',
                  width: lockSize,
                  height: lockSize,
                  color: _lockColor(detail.rarity),
                ),
        ),
      ),
      ),
    );
  }

  Widget _series(CharacterDetailDto detail) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final width = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in detail.series)
              SizedBox(
                width: width,
                child: SeriesThumbnail(
                  item: item,
                  width: width,
                  onTap: () => SeriesRouter.pushOverview(context, item.id),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _zoom(String path) {
    final detail = _detail;
    final current = _isCurrentProfile(path);
    final width = MediaQuery.sizeOf(context).width - 48;
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _zoomPath = null),
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.4),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: CdnThumbUrl.original(path),
                      width: width,
                      height: width,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!current && detail != null) ...[
                    const SizedBox(height: 48),
                    _ZoomSetButton(
                      onTap: _savingProfile
                          ? null
                          : () => unawaited(_confirmSetProfile(path)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text, TextTheme theme) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: theme.headlineSmall?.copyWith(color: Colors.white),
    );
  }
}

class _ZoomSetButton extends StatelessWidget {
  const _ZoomSetButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final elevatedBase = Theme.of(context).elevatedButtonTheme.style;
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0CABA8),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        elevation: 0,
      ).merge(elevatedBase),
      child: Text(AppLocalizations.of(context)!.characterSetAsProfile),
    );
  }
}

class _ProfilePreview extends StatelessWidget {
  const _ProfilePreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context).width * 0.8 * 0.3;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: CdnThumbUrl.original(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

BoxDecoration _downRightCircleShadow(double size) {
  return BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: const Color(0x66000000),
        offset: Offset(size * 0.04, size * 0.08),
        blurRadius: size * 0.16,
      ),
    ],
  );
}

LinearGradient _background(String rarity) {
  switch (CharacterRarityFrame.normalize(rarity)) {
    case 'RARE':
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0C0752), Color(0xFF049FFF), Color(0xFF93D6FF)],
        stops: [0.0, 0.29, 1.0],
      );
    case 'EPIC':
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF330371), Color(0xFFDF3FF8)],
      );
    default:
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF03430A), Color(0xE071A431)],
      );
  }
}

String _rarityLabel(String rarity) {
  switch (CharacterRarityFrame.normalize(rarity)) {
    case 'RARE':
      return 'Rare';
    case 'EPIC':
      return 'Epic';
    default:
      return 'Normal';
  }
}

Color _rarityColor(String rarity) {
  switch (CharacterRarityFrame.normalize(rarity)) {
    case 'RARE':
      return const Color(0xFF00D0FF);
    case 'EPIC':
      return const Color(0xFFDF3FF8);
    default:
      return const Color(0xFFC7E23A);
  }
}

Color _lockColor(String rarity) {
  switch (CharacterRarityFrame.normalize(rarity)) {
    case 'RARE':
      return const Color(0xFF09A7C0);
    case 'EPIC':
      return const Color(0xFF853DB5);
    default:
      return const Color(0xFF70A230);
  }
}
