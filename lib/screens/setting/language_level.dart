import 'package:flutter/material.dart';
import '../../widgets/app_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';

class LanguageLevelScreen extends StatefulWidget {
  final UserDto? user;

  const LanguageLevelScreen({super.key, this.user});

  @override
  State<LanguageLevelScreen> createState() => _LanguageLevelScreenState();
}

class _LanguageLevelScreenState extends State<LanguageLevelScreen> {
  String _selectedLevel = ''; // A, B, C, D
  bool _isLoading = true;
  String? _updatingLevel; // 현재 업데이트 중인 레벨 (뱅글뱅글용)

  final Map<String, String> _levelMap = {
    'A': 'Beginner',
    'B': 'Basic',
    'C': 'Intermediate',
    'D': 'Advanced',
  };

  @override
  void initState() {
    super.initState();
    _initializeLevel();
  }

  void _initializeLevel() {
    if (widget.user != null) {
      final levelMeta = widget.user!.metaInfo?.firstWhere(
        (meta) => meta.key == 'ENGLISH_LEVEL',
        orElse: () => const SudaJson(key: 'ENGLISH_LEVEL', value: 'A'),
      );
      setState(() {
        _selectedLevel = levelMeta?.value ?? 'A';
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
          orElse: () => const SudaJson(key: 'ENGLISH_LEVEL', value: 'A'),
        );
        setState(() {
          _selectedLevel = levelMeta?.value ?? 'A';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onLevelSelected(String levelKey) async {
    if (_updatingLevel != null || _selectedLevel == levelKey) return;

    setState(() {
      _updatingLevel = levelKey;
    });

    try {
      final token = await TokenStorage.loadAccessToken();
      if (token != null) {
        await SudaApiClient.updateLanguageLevel(
          accessToken: token,
          languageLevel: levelKey,
        );

        // 앱 내부의 user 객체 업데이트 (기존 메타 정보 유지하며 ENGLISH_LEVEL만 변경)
        if (widget.user != null && widget.user!.metaInfo != null) {
          final meta = widget.user!.metaInfo!;
          final index = meta.indexWhere((m) => m.key == 'ENGLISH_LEVEL');
          
          if (index != -1) {
            // 기존 키가 있으면 값만 교체
            meta[index] = SudaJson(key: 'ENGLISH_LEVEL', value: levelKey);
          } else {
            // 없으면 새로 추가
            meta.add(SudaJson(key: 'ENGLISH_LEVEL', value: levelKey));
          }
        }

        setState(() {
          _selectedLevel = levelKey;
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
                  l10n.languageLevelTitle,
                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),
                Text(
                  l10n.languageLevelDescription,
                  style: theme.bodyLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 45),
                ..._levelMap.entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildLevelButton(entry.key, entry.value, theme),
                    )),
              ],
            ),
    );
  }

  Widget _buildLevelButton(String levelKey, String levelLabel, TextTheme theme) {
    final isActive = _selectedLevel == levelKey;
    final isUpdating = _updatingLevel == levelKey;
    final isAnyUpdating = _updatingLevel != null;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isAnyUpdating ? null : () => _onLevelSelected(levelKey),
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
