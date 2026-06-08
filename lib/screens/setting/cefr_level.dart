import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../utils/english_level_util.dart';

class CefrLevelScreen extends StatefulWidget {
  final UserDto? user;

  const CefrLevelScreen({super.key, this.user});

  @override
  State<CefrLevelScreen> createState() => _CefrLevelScreenState();
}

class _CefrLevelScreenState extends State<CefrLevelScreen> {
  String _selectedLevel = '';
  bool _isLoading = true;
  String? _updatingLevel;

  String _levelLabel(AppLocalizations l10n, String cefrLevel) {
    switch (cefrLevel) {
      case 'Pre-A1':
        return l10n.cefrLevelAbsoluteBeginner;
      case 'A1':
        return l10n.cefrLevelBeginner;
      case 'A2':
        return l10n.cefrLevelBasic;
      case 'B1':
        return l10n.cefrLevelIntermediate;
      default:
        return cefrLevel;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeLevel();
  }

  void _initializeLevel() {
    if (widget.user != null) {
      final levelMeta = widget.user!.metaInfo?.firstWhere(
        (meta) => meta.key == 'ENGLISH_LEVEL',
        orElse: () => const SudaJson(
          key: 'ENGLISH_LEVEL',
          value: EnglishLevelUtil.defaultLevel,
        ),
      );
      setState(() {
        _selectedLevel = EnglishLevelUtil.normalizeToCefr(levelMeta?.value);
        _isLoading = false;
      });
    } else {
      _fetchUserInfo();
    }
  }

  Future<void> _fetchUserInfo() async {
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        final user = await SudaApiClient.getCurrentUser(accessToken: token);
        final levelMeta = user.metaInfo?.firstWhere(
          (meta) => meta.key == 'ENGLISH_LEVEL',
          orElse: () => const SudaJson(
            key: 'ENGLISH_LEVEL',
            value: EnglishLevelUtil.defaultLevel,
          ),
        );
        setState(() {
          _selectedLevel = EnglishLevelUtil.normalizeToCefr(levelMeta?.value);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onLevelSelected(String cefrLevel) async {
    if (_updatingLevel != null || _selectedLevel == cefrLevel) return;

    setState(() {
      _updatingLevel = cefrLevel;
    });

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateLanguageLevel(
          accessToken: token,
          languageLevel: cefrLevel,
        );

        if (widget.user != null && widget.user!.metaInfo != null) {
          final meta = widget.user!.metaInfo!;
          final index = meta.indexWhere((m) => m.key == 'ENGLISH_LEVEL');

          if (index != -1) {
            meta[index] = SudaJson(key: 'ENGLISH_LEVEL', value: cefrLevel);
          } else {
            meta.add(SudaJson(key: 'ENGLISH_LEVEL', value: cefrLevel));
          }
        }

        setState(() {
          _selectedLevel = cefrLevel;
        });
      }
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Failed to update language level: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _updatingLevel = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;

    return AppScaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 15),
                Text(
                  l10n.cefrLevelTitle,
                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),
                ...EnglishLevelUtil.visibleLevels.map((cefrLevel) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildLevelButton(
                        cefrLevel,
                        _levelLabel(l10n, cefrLevel),
                        theme,
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _buildLevelButton(String cefrLevel, String levelLabel, TextTheme theme) {
    final isActive = _selectedLevel == cefrLevel;
    final isUpdating = _updatingLevel == cefrLevel;
    final isAnyUpdating = _updatingLevel != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isAnyUpdating ? null : () => _onLevelSelected(cefrLevel),
        style: ElevatedButton.styleFrom(
          backgroundColor: isActive ? const Color(0xFF0CABA8) : Colors.white,
          foregroundColor: isActive ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          disabledBackgroundColor: isActive ? const Color(0xFF0CABA8).withOpacity(0.6) : Colors.white.withOpacity(0.6),
        ),
        child: isUpdating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(levelLabel),
      ),
    );
  }
}
