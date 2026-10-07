import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/suda_api_client.dart';
import '../utils/app_language_options.dart';
import '../utils/default_toast.dart';
import '../widgets/app_language_option_list.dart';
import '../widgets/onboarding_step_bar.dart';

/// 약관 동의 뒤, `LANGUAGE_TAG`가 없을 때 한 번 고르는 전체 화면.
class FirstAppLanguageScreen extends StatefulWidget {
  final void Function(UserDto? user) onSaved;
  final bool preview;

  const FirstAppLanguageScreen({
    super.key,
    required this.onSaved,
    this.preview = false,
  });

  @override
  State<FirstAppLanguageScreen> createState() => _FirstAppLanguageScreenState();
}

class _FirstAppLanguageScreenState extends State<FirstAppLanguageScreen> {
  static const _background = Color(0xFF121212);

  late final Locale _device;
  late final List<AppLanguageOption> _options;
  String? _selectedId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _device = WidgetsBinding.instance.platformDispatcher.locale;
    _options = AppLanguageOptions.pinnedForDevice(_device);
    _selectedId = AppLanguageOptions.similarId(_device);
  }

  Future<void> _onContinue() async {
    final selectedId = _selectedId;
    if (selectedId == null || _isSubmitting) return;
    if (widget.preview) {
      widget.onSaved(null);
      return;
    }
    final option = _options.firstWhere((item) => item.id == selectedId);
    final tag = AppLanguageOptions.valueToSave(option, _device);
    setState(() => _isSubmitting = true);
    try {
      final user = await AppLanguageOptions.persist(tag);
      if (!mounted) return;
      widget.onSaved(user);
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
      canPop: false,
      child: Scaffold(
        backgroundColor: _background,
        body: withOnboardingStepBar(
          step: 1,
          body: Column(
            children: [
              Expanded(child: _buildTitle(l10n, theme)),
              Expanded(
                flex: 2,
                child: AppLanguageOptionList(
                  options: _options,
                  selectedId: _selectedId,
                  submitting: _isSubmitting,
                  onSelect: (id) => setState(() => _selectedId = id),
                  onConfirm: canContinue ? _onContinue : null,
                  buttonLabel: l10n.firstAppLanguageContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(AppLocalizations l10n, TextTheme theme) {
    return onboardingTitle(l10n.firstAppLanguageTitle, theme);
  }
}
