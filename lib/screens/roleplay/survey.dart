import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/suda_api_client.dart';
import '../../services/token_storage.dart';
import '../../utils/default_toast.dart';
import '../../widgets/roleplay_scaffold.dart';

/// Roleplay Survey Screen (Sub Screen)
///
/// Opening의 -10 분기에서 진입하는 3단계 설문 화면.
class RoleplaySurveyScreen extends StatefulWidget {
  static const String routeName = '/roleplay/survey';

  const RoleplaySurveyScreen({super.key});

  @override
  State<RoleplaySurveyScreen> createState() => _RoleplaySurveyScreenState();
}

class _RoleplaySurveyScreenState extends State<RoleplaySurveyScreen> {
  int _currentStep = 1;
  int? _age;
  int? _gender;
  int? _source;
  bool _isSubmitting = false;

  List<_SurveyOption> _buildOptions(AppLocalizations l10n) {
    switch (_currentStep) {
      case 1:
        return const [
          _SurveyOption(value: 1, label: 'Under 18'),
          _SurveyOption(value: 2, label: '18-24'),
          _SurveyOption(value: 3, label: '25-34'),
          _SurveyOption(value: 4, label: '35-44'),
          _SurveyOption(value: 5, label: '45+'),
        ];
      case 2:
        return [
          _SurveyOption(value: 1, label: l10n.surveyGenderFemale),
          _SurveyOption(value: 2, label: l10n.surveyGenderMale),
          _SurveyOption(value: 3, label: l10n.surveyGenderPreferNotToSay),
        ];
      default:
        return const [
          _SurveyOption(value: 1, label: 'Facebook'),
          _SurveyOption(value: 2, label: 'Instagram'),
          _SurveyOption(value: 3, label: 'TikTok'),
          _SurveyOption(value: 4, label: 'Friends'),
          _SurveyOption(value: 5, label: 'Others'),
        ];
    }
  }

  String _stepTitle(AppLocalizations l10n) {
    switch (_currentStep) {
      case 1:
        return l10n.surveyStep1Title;
      case 2:
        return l10n.surveyStep2Title;
      default:
        return l10n.surveyStep3Title;
    }
  }

  Future<void> _onOptionTap(int value) async {
    if (_isSubmitting) return;
    if (_currentStep == 1) {
      setState(() {
        _age = value;
        _currentStep = 2;
      });
      return;
    }
    if (_currentStep == 2) {
      setState(() {
        _gender = value;
        _currentStep = 3;
      });
      return;
    }
    _source = value;
    await _submitSurvey();
  }

  Future<void> _submitSurvey() async {
    final l10n = AppLocalizations.of(context)!;
    final age = _age;
    final gender = _gender;
    final source = _source;
    if (age == null || gender == null || source == null) {
      DefaultToast.show(context, 'Survey Failed', isError: true);
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final accessToken = await TokenStorage.loadAccessToken();
      if (accessToken == null) {
        DefaultToast.show(context, 'Survey Failed', isError: true);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final result = await SudaApiClient.submitSurvey(
        accessToken: accessToken,
        age: age,
        gender: gender,
        source: source,
      );
      if (!mounted) return;
      if (result == 'Y') {
        DefaultToast.show(context, l10n.surveySuccessToast);
      } else {
        DefaultToast.show(context, 'Survey Failed', isError: true);
      }
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      DefaultToast.show(context, 'Survey Failed', isError: true);
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final options = _buildOptions(l10n);

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {},
      child: RoleplayScaffold(
        showCloseButton: true,
        onClose: () => Navigator.of(context).pop(),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth * 0.32;
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(3, (index) {
                    final isActive = index < _currentStep;
                    return Container(
                      width: segmentWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: isActive ? null : const Color(0xFF353535),
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [Color(0xFF076766), Color(0xFF0CABA8)],
                              )
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 50),
                Text(
                  _stepTitle(l10n),
                  style: theme.headlineMedium?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                ...options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == options.length - 1 ? 0 : 10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => _onOptionTap(option.value),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(
                            color: Color(0xFF635F5F),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          option.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'ChironGoRoundTC',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            fontVariations: [FontVariation('wght', 600)],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
        footer: const SizedBox.shrink(),
      ),
    );
  }
}

class _SurveyOption {
  final int value;
  final String label;

  const _SurveyOption({
    required this.value,
    required this.label,
  });
}
