import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/onboarding_step_bar.dart';

/// 약관 동의 뒤, `LANGUAGE_TAG`가 없을 때 한 번 고르는 앱 언어 화면.
class FirstAppLanguageScreen extends StatefulWidget {
  final void Function(UserDto? user) onSaved;
  final bool preview;
  final bool showStepBar;
  final String? initialTag;

  const FirstAppLanguageScreen({
    super.key,
    required this.onSaved,
    this.preview = false,
    this.showStepBar = true,
    this.initialTag,
  });

  @override
  State<FirstAppLanguageScreen> createState() => _FirstAppLanguageScreenState();
}

class _LangOption {
  final String id;
  final String label;
  /// 지역·스크립트가 고정이면 기기 태그를 붙이지 않는다.
  final bool fixed;
  final String code;

  const _LangOption(this.id, this.label, this.code, this.fixed);
}

class _FirstAppLanguageScreenState extends State<FirstAppLanguageScreen> {
  static const _background = Color(0xFF121212);
  static const _selected = Color(0xFF0CABA8);
  static const _optionTextStyle = TextStyle(
    fontFamily: 'ChironGoRoundTC',
    fontFamilyFallback: ['ChironHeiHK'],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    color: Colors.white,
  );

  static const _catalog = <_LangOption>[
    _LangOption('en', 'English', 'en', false),
    _LangOption('ko', '한국어', 'ko', false),
    _LangOption('pt-BR', 'Português (Brasil)', 'pt-BR', true),
    _LangOption('es-419', 'Español (Latinoamérica)', 'es-419', true),
    _LangOption('ja', '日本語', 'ja', false),
    _LangOption('zh-Hans', '简体中文', 'zh-Hans', true),
    _LangOption('zh-Hant', '繁體中文', 'zh-Hant', true),
    _LangOption('fr', 'Français', 'fr', false),
    _LangOption('de', 'Deutsch', 'de', false),
    _LangOption('it', 'Italiano', 'it', false),
    _LangOption('vi', 'Tiếng Việt', 'vi', false),
    _LangOption('th', 'ไทย', 'th', false),
    _LangOption('id', 'Bahasa Indonesia', 'id', false),
    _LangOption('ms', 'Bahasa Melayu', 'ms', false),
    _LangOption('fil', 'Filipino', 'fil', false),
    _LangOption('hi', 'हिन्दी', 'hi', false),
    _LangOption('ar', 'العربية', 'ar', false),
    _LangOption('tr', 'Türkçe', 'tr', false),
    _LangOption('ru', 'Русский', 'ru', false),
    _LangOption('pl', 'Polski', 'pl', false),
    _LangOption('nl', 'Nederlands', 'nl', false),
  ];

  static final _tagPattern = RegExp(r'^[A-Za-z0-9-]{1,12}$');

  late final Locale _device;
  late final List<_LangOption> _options;
  String? _selectedId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _device = WidgetsBinding.instance.platformDispatcher.locale;
    if (!widget.showStepBar) {
      _options = List.of(_catalog);
      _selectedId = _optionIdForTag(widget.initialTag);
      return;
    }
    final similar = _similarId(_device);
    if (similar == null) {
      _options = List.of(_catalog);
      _selectedId = null;
    } else {
      final picked = _catalog.where((option) => option.id == similar).toList();
      final rest = _catalog.where((option) => option.id != similar);
      _options = [...picked, ...rest];
      _selectedId = similar;
    }
  }

  static String? _optionIdForTag(String? tag) {
    if (tag == null || tag.trim().isEmpty) return null;
    final lower = tag.trim().toLowerCase();
    for (final option in _catalog) {
      if (option.code.toLowerCase() == lower) return option.id;
    }
    if (lower.startsWith('zh')) {
      final region = lower.split('-').last;
      if (lower.contains('hant') ||
          region == 'tw' ||
          region == 'hk' ||
          region == 'mo') {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    if (lower.startsWith('pt')) return 'pt-BR';
    if (lower.startsWith('es')) return 'es-419';
    if (lower.startsWith('fil') || lower.startsWith('tl')) return 'fil';
    final primary = lower.split('-').first;
    for (final option in _catalog) {
      if (!option.fixed && option.code == primary) return option.id;
    }
    return null;
  }

  static String? _similarId(Locale device) {
    final lang = device.languageCode.toLowerCase();
    final script = device.scriptCode?.toLowerCase();
    final country = device.countryCode?.toUpperCase();
    if (lang == 'zh') {
      if (script == 'hant' ||
          country == 'TW' ||
          country == 'HK' ||
          country == 'MO') {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    if (lang == 'pt') return 'pt-BR';
    if (lang == 'es') return 'es-419';
    if (lang == 'fil' || lang == 'tl') return 'fil';
    for (final option in _catalog) {
      if (!option.fixed && option.code == lang) return option.id;
    }
    return null;
  }

  String _valueToSave(_LangOption option) {
    if (option.fixed) return option.code;
    if (_device.languageCode.toLowerCase() != option.code) return option.code;
    final tag = _device.toLanguageTag();
    if (_tagPattern.hasMatch(tag)) return tag;
    return option.code;
  }

  Future<void> _onContinue() async {
    final selectedId = _selectedId;
    if (selectedId == null || _isSubmitting) return;
    final option = _options.firstWhere((item) => item.id == selectedId);
    final tag = _valueToSave(option);
    if (widget.preview) {
      widget.onSaved(null);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await TokenStorage.loadAccessToken();
      if (token == null) {
        throw Exception('missing token');
      }
      await SudaApiClient.updateLanguageTag(
        accessToken: token,
        languageTag: tag,
      );
      final fresh = await SudaApiClient.getCurrentUser(accessToken: token);
      final user = fresh.upsertMetaInfo(key: 'LANGUAGE_TAG', value: tag);
      if (!mounted) return;
      widget.onSaved(user);
      if (!widget.showStepBar && mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      DefaultToast.show(
        context,
        AppLocalizations.of(context)!.requestFailed,
        isError: true,
      );
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final canContinue = _selectedId != null && !_isSubmitting;

    return PopScope(
      canPop: !widget.showStepBar,
      child: Scaffold(
        backgroundColor: _background,
        body: widget.showStepBar
            ? withOnboardingStepBar(step: 1, body: _buildBody(l10n, theme, canContinue))
            : Stack(
                children: [
                  _buildBody(l10n, theme, canContinue),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16, left: 16),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: AppScaffold.backButton(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, TextTheme theme, bool canContinue) {
    return Column(
      children: [
        Expanded(child: _buildTitle(l10n, theme)),
        Expanded(
          flex: 2,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fadeHeight = constraints.maxHeight / 3;
              return Stack(
                children: [
                  ListView.separated(
                    padding: EdgeInsets.fromLTRB(24, 8, 24, fadeHeight),
                    itemCount: _options.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final option = _options[index];
                      final selected = option.id == _selectedId;
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
                              onTap: _isSubmitting
                                  ? null
                                  : () => setState(() => _selectedId = option.id),
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
                          onPressed: canContinue ? _onContinue : null,
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
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : Text(
                                  widget.showStepBar
                                      ? l10n.firstAppLanguageContinue
                                      : l10n.actionConfirm,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTitle(AppLocalizations l10n, TextTheme theme) {
    return Column(
      children: [
            Expanded(
              flex: 5,
              child: const SizedBox.shrink(),
            ),
            Expanded(
              flex: 5,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.8,
                  child: Text(
                    l10n.firstAppLanguageTitle,
                    style: theme.headlineLarge?.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
            const Expanded(flex: 2, child: SizedBox.shrink()),
      ],
    );
  }
}
