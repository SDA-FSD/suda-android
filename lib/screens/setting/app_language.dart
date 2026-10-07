import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../utils/app_language_options.dart';
import '../../utils/default_toast.dart';
import '../../widgets/app_language_option_list.dart';
import '../../widgets/app_scaffold.dart';

/// Setting에서 여는 앱 언어 하위 화면.
class AppLanguageScreen extends StatefulWidget {
  final String? initialTag;
  final void Function(UserDto user) onSaved;

  const AppLanguageScreen({
    super.key,
    required this.onSaved,
    this.initialTag,
  });

  @override
  State<AppLanguageScreen> createState() => _AppLanguageScreenState();
}

class _AppLanguageScreenState extends State<AppLanguageScreen> {
  static const _background = Color(0xFF121212);

  late final Locale _device;
  String? _selectedId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _device = WidgetsBinding.instance.platformDispatcher.locale;
    _selectedId = AppLanguageOptions.optionIdForTag(widget.initialTag);
  }

  Future<void> _onConfirm() async {
    final selectedId = _selectedId;
    if (selectedId == null || _isSubmitting) return;
    final option = AppLanguageOptions.catalog
        .firstWhere((item) => item.id == selectedId);
    final tag = AppLanguageOptions.valueToSave(option, _device);
    setState(() => _isSubmitting = true);
    try {
      final user = await AppLanguageOptions.persist(tag);
      if (!mounted) return;
      widget.onSaved(user);
      Navigator.of(context).pop();
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
    final canConfirm = _selectedId != null && !_isSubmitting;
    return AppScaffold(
      centerTitle: l10n.settingsAppLanguage,
      backgroundColor: _background,
      usePadding: false,
      body: AppLanguageOptionList(
        options: AppLanguageOptions.catalog,
        selectedId: _selectedId,
        submitting: _isSubmitting,
        onSelect: (id) => setState(() => _selectedId = id),
        onConfirm: canConfirm ? _onConfirm : null,
        buttonLabel: l10n.actionConfirm,
      ),
    );
  }
}
