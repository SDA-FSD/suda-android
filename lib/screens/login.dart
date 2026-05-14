import 'dart:async' show unawaited;
import 'dart:math' show max;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/appsflyer_service.dart';
import '../services/suda_api_client.dart';
import '../services/token_storage.dart';
import '../utils/default_toast.dart';
import '../utils/sub_screen_route.dart';
import 'webview_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(GoogleSignInResult)? onSignIn;
  final String? accessToken;
  final bool showAgreementLayerOnStart;
  final VoidCallback? onAgreementComplete;
  final Future<void> Function()? onAgreementDismissWithoutConsent;

  const LoginScreen({
    super.key,
    this.onSignIn,
    this.accessToken,
    this.showAgreementLayerOnStart = false,
    this.onAgreementComplete,
    this.onAgreementDismissWithoutConsent,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  static const _backgroundColor = Color(0xFF121212);
  static const _accentColor = Color(0xFF0CABA8);
  static const _linkColor = Color(0xFF80D7CF);
  static const _stillWidth = 165.0;
  static const _stillHeight = 36.0;
  static const _logoWidth = 40.0;
  static const _logoHeight = 36.0;
  static const _loginButtonHeight = 50.0;

  static const _posterRows = [
    [
      'assets/images/small_posters/z2szhd.png',
      'assets/images/small_posters/6dqbfi.png',
      'assets/images/small_posters/hvcmkj.png',
      'assets/images/small_posters/h09ze5.png',
      'assets/images/small_posters/ty55ej.png',
      'assets/images/small_posters/ueqp7y.png',
      'assets/images/small_posters/8zhbxy.png',
      'assets/images/small_posters/d0ui5u.png',
      'assets/images/small_posters/k8tqlk.png',
      'assets/images/small_posters/p5ymmx.png',
      'assets/images/small_posters/pnekl5.png',
      'assets/images/small_posters/rua74h.png',
      'assets/images/small_posters/lkwin4.png',
      'assets/images/small_posters/q6s15c.png',
      'assets/images/small_posters/ol69ly.png',
      'assets/images/small_posters/f5t0zm.png',
      'assets/images/small_posters/dwupos.png',
      'assets/images/small_posters/hjyek3.png',
      'assets/images/small_posters/wohldq.png',
    ],
    [
      'assets/images/small_posters/1w70rx.png',
      'assets/images/small_posters/28ogv1.png',
      'assets/images/small_posters/waicvs.png',
      'assets/images/small_posters/7k86a6.png',
      'assets/images/small_posters/1yhwk3.png',
      'assets/images/small_posters/isveap.png',
      'assets/images/small_posters/goa850.png',
      'assets/images/small_posters/s8vcof.png',
      'assets/images/small_posters/ddr94m.png',
      'assets/images/small_posters/5knaof.png',
      'assets/images/small_posters/nz57y3.png',
      'assets/images/small_posters/e8nd41.png',
      'assets/images/small_posters/i3u0gn.png',
      'assets/images/small_posters/mank8r.png',
      'assets/images/small_posters/3m49ay.png',
      'assets/images/small_posters/otvnff.png',
      'assets/images/small_posters/u2l020.png',
      'assets/images/small_posters/fudtov.png',
      'assets/images/small_posters/vqqn7k.png',
    ],
    [
      'assets/images/small_posters/k5h8w5.png',
      'assets/images/small_posters/cxbrij.png',
      'assets/images/small_posters/v140nx.png',
      'assets/images/small_posters/k82wx5.png',
      'assets/images/small_posters/1qx1s1.png',
      'assets/images/small_posters/pa14kh.png',
      'assets/images/small_posters/yoaxlc.png',
      'assets/images/small_posters/u5vmgc.png',
      'assets/images/small_posters/d9rmlu.png',
      'assets/images/small_posters/nioxgr.png',
      'assets/images/small_posters/nj97kv.png',
      'assets/images/small_posters/04ax69.png',
      'assets/images/small_posters/pd0pq9.png',
      'assets/images/small_posters/6zqe7d.png',
      'assets/images/small_posters/a8af4f.png',
      'assets/images/small_posters/9anbul.png',
      'assets/images/small_posters/8rhj8p.png',
      'assets/images/small_posters/ifvm12.png',
      'assets/images/small_posters/6xpk0p.png',
    ],
  ];

  bool _isLoading = false;
  late final AnimationController _stillFadeController;
  late final AnimationController _logoMoveController;
  late final AnimationController _loginContentSlideController;
  late final List<AnimationController> _posterEntranceControllers;
  late final List<AnimationController> _posterMarqueeControllers;
  late final Animation<double> _stillOpacity;

  // Agreement bottom-up layer (AccountScreen 예시와 동일 계열)
  bool _showAgreementLayer = false;
  bool _isAgreementTermsAgreed = false;
  bool _isAgreementPrivacyAgreed = false;
  bool _isAgreementSubmitting = false;
  late final AnimationController _agreementLayerController;
  late final Animation<Offset> _agreementSlideAnimation;
  late final Animation<double> _agreementFadeAnimation;

  static const _animationStartDelay = Duration(milliseconds: 1000);
  static const _entranceCurve = Curves.easeOutCubic;

  @override
  void didUpdateWidget(covariant LoginScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasEligible = oldWidget.showAgreementLayerOnStart &&
        oldWidget.accessToken != null;
    final isEligible =
        widget.showAgreementLayerOnStart && widget.accessToken != null;

    // LoginScreen 위젯이 재사용되면 initState가 다시 호출되지 않으므로,
    // "동의 필요 상태"로 전환되는 순간을 감지해 레이어를 자동으로 띄운다.
    if (!wasEligible && isEligible && !_showAgreementLayer) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAgreementLayer();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _stillFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoMoveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loginContentSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _posterEntranceControllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      ),
    );
    _posterMarqueeControllers = [
      AnimationController(vsync: this, duration: const Duration(seconds: 60)),
      AnimationController(vsync: this, duration: const Duration(seconds: 70)),
      AnimationController(vsync: this, duration: const Duration(seconds: 66)),
    ];
    for (var i = 0; i < 3; i++) {
      final rowIndex = i;
      _posterEntranceControllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _posterMarqueeControllers[rowIndex].repeat();
        }
      });
    }
    _stillOpacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _stillFadeController, curve: Curves.easeOut),
    );

    _agreementLayerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _agreementSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _agreementLayerController, curve: Curves.easeOut),
    );
    _agreementFadeAnimation = CurvedAnimation(
      parent: _agreementLayerController,
      curve: Curves.linear,
    );

    Future.delayed(_animationStartDelay, () {
      if (!mounted) {
        return;
      }
      _stillFadeController.forward();
      _logoMoveController.forward();
      _loginContentSlideController.forward();
      for (final c in _posterEntranceControllers) {
        c.forward();
      }
    });

    if (widget.showAgreementLayerOnStart && widget.accessToken != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openAgreementLayer();
      });
    }
  }

  @override
  void dispose() {
    _stillFadeController.dispose();
    _logoMoveController.dispose();
    _loginContentSlideController.dispose();
    _agreementLayerController.dispose();
    for (final c in _posterEntranceControllers) {
      c.dispose();
    }
    for (final c in _posterMarqueeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _openAgreementLayer() {
    if (_showAgreementLayer) return;
    setState(() => _showAgreementLayer = true);
    _agreementLayerController.forward();
  }

  void _closeAgreementLayer() {
    _agreementLayerController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _showAgreementLayer = false);
      if (widget.showAgreementLayerOnStart &&
          widget.accessToken != null &&
          widget.onAgreementDismissWithoutConsent != null) {
        unawaited(widget.onAgreementDismissWithoutConsent!());
      }
    });
  }

  void _navigateToAgreementWebView(String title, String url) {
    Navigator.push(
      context,
      SubScreenRoute(page: WebViewScreen(title: title, url: url)),
    );
  }

  Future<void> _handleAgreementSubmit() async {
    if (_isAgreementSubmitting) return;
    if (!_isAgreementTermsAgreed || !_isAgreementPrivacyAgreed) return;
    final token = widget.accessToken;
    if (token == null) return;

    setState(() => _isAgreementSubmitting = true);
    try {
      await SudaApiClient.updateAgreement(accessToken: token);
      await AppsflyerService.logEvent('af_complete_registration');
      widget.onAgreementComplete?.call();
    } catch (e) {
      if (mounted) {
        DefaultToast.show(context, 'Error: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isAgreementSubmitting = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.signInWithGoogle();
      if (!mounted) {
        return;
      }
      if (result == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (result.idToken == null) {
        final l10n = AppLocalizations.of(context)!;
        DefaultToast.show(context, l10n.loginErrorIdToken, isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final deviceId = await TokenStorage.getDeviceId();
      final tokens = await SudaApiClient.loginWithGoogle(
        idToken: result.idToken!,
        deviceId: deviceId,
      );

      await TokenStorage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      widget.onSignIn?.call(result);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context)!;
      DefaultToast.show(
        context,
        l10n.loginErrorFailed(error.toString()),
        isError: true,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openTerms() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: 'https://sudatalk.kr/public/app/terms',
          title: l10n.loginTermsTitle,
        ),
      ),
    );
  }

  void _openPrivacy() {
    final l10n = AppLocalizations.of(context)!;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: 'https://sudatalk.kr/public/app/privacy',
          title: l10n.loginPrivacyTitle,
        ),
      ),
    );
  }

  Widget _buildPosterBackground(double width, double height) {
    final posterAreaHeight = height * 0.5;
    final rowHeight = posterAreaHeight / 3;

    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: posterAreaHeight,
      child: Stack(
        children: [
          for (var i = 0; i < _posterRows.length; i++)
            Positioned(
              left: 0,
              top: rowHeight * i,
              width: width,
              height: rowHeight,
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _posterEntranceControllers[i],
                  _posterMarqueeControllers[i],
                ]),
                builder: (context, child) {
                  final entranceT = _entranceCurve.transform(
                    _posterEntranceControllers[i].value,
                  );
                  final fromLeft = i != 1;
                  final dx = fromLeft
                      ? -width * (1 - entranceT)
                      : width * (1 - entranceT);
                  return Transform.translate(
                    offset: Offset(dx, 0),
                    child: child,
                  );
                },
                child: _PosterMarqueeRow(
                  controller: _posterMarqueeControllers[i],
                  posters: _posterRows[i],
                  direction: i == 1
                      ? _PosterMarqueeDirection.left
                      : _PosterMarqueeDirection.right,
                  rowHeight: rowHeight,
                ),
              ),
            ),
          IgnorePointer(
            child: Column(
              children: [
                SizedBox(
                  height: posterAreaHeight / 6,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_backgroundColor, Color(0x00121212)],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: posterAreaHeight / 6,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00121212), _backgroundColor],
                      ),
                    ),
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.loginWelcomeTitle,
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(color: _accentColor),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.loginWelcomeSubtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildLoginButton(double screenWidth) {
    final buttonWidth = screenWidth * 0.4;

    if (_isLoading) {
      return SizedBox(
        width: buttonWidth,
        height: _loginButtonHeight,
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleGoogleSignIn,
      child: SizedBox(
        width: buttonWidth,
        height: _loginButtonHeight,
        child: Image.asset(
          'assets/images/android_dark_rd_SI.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Icon(Icons.login, size: 24, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTermsText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final termsText = l10n.loginTermsTitle;
    final privacyText = l10n.loginPrivacyTitle;
    final template = l10n.loginTermsTemplate(termsText, privacyText);
    final parts = template.split(
      RegExp('${RegExp.escape(termsText)}|${RegExp.escape(privacyText)}'),
    );
    final baseStyle =
        Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white) ??
        const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );
    final linkStyle = baseStyle.copyWith(
      color: _linkColor,
      decoration: TextDecoration.underline,
      decorationColor: _linkColor,
    );

    if (parts.length < 3) {
      return Text(template, textAlign: TextAlign.center, style: baseStyle);
    }

    return RichText(
      textAlign: TextAlign.center,
      softWrap: true,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: parts[0]),
          TextSpan(
            text: termsText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = _openTerms,
          ),
          TextSpan(text: parts[1]),
          TextSpan(
            text: privacyText,
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = _openPrivacy,
          ),
          TextSpan(text: parts[2]),
        ],
      ),
    );
  }

  Widget _buildLoginContent(
    BuildContext context,
    double width,
    double height,
    double logoEndTop,
  ) {
    final contentTop = logoEndTop + _logoHeight;
    final contentHeight = (height - contentTop).clamp(0.0, height);
    final dividerY = contentTop + (contentHeight / 2);
    // Translate down so the topmost 노출(환영 문구) clears the viewport bottom before animation.
    const minContentLeadY = 12.0;
    const slidePastEdge = 40.0;
    final minContentTop = contentTop + minContentLeadY;
    final slideDistance = max(120.0, height - minContentTop + slidePastEdge);

    return AnimatedBuilder(
      animation: _loginContentSlideController,
      builder: (context, child) {
        final t = _entranceCurve.transform(_loginContentSlideController.value);
        return Transform.translate(
          offset: Offset(0, slideDistance * (1 - t)),
          child: child,
        );
      },
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: contentTop + 12,
            child: _buildWelcomeText(context),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: dividerY,
            child: Center(child: _buildLoginButton(width)),
          ),
          Positioned(
            left: width * 0.15,
            right: width * 0.15,
            top: dividerY + _loginButtonHeight,
            height: contentHeight / 3,
            child: Center(child: _buildTermsText(context)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final screenCenter = Offset(width / 2, height / 2);
          final logoStartLeft = screenCenter.dx - (_stillWidth / 2);
          final logoStartTop = screenCenter.dy - (_logoHeight / 2);
          final logoEndLeft = screenCenter.dx - (_logoWidth / 2);
          final logoEndTop = screenCenter.dy - (_logoHeight / 2);

          return Stack(
            children: [
              _buildPosterBackground(width, height),
              _buildLoginContent(context, width, height, logoEndTop),
              Center(
                child: FadeTransition(
                  opacity: _stillOpacity,
                  child: Image.asset(
                    'assets/images/splash_still_260513.png',
                    width: _stillWidth,
                    height: _stillHeight,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _logoMoveController,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(_logoMoveController.value);
                  return Positioned(
                    left: logoStartLeft + (logoEndLeft - logoStartLeft) * t,
                    top: logoStartTop + (logoEndTop - logoStartTop) * t,
                    child: child!,
                  );
                },
                child: Image.asset(
                  'assets/images/splash_still_logo_part.png',
                  width: _logoWidth,
                  height: _logoHeight,
                  fit: BoxFit.contain,
                ),
              ),

              if (_showAgreementLayer) ...[
                Positioned.fill(
                  child: FadeTransition(
                    opacity: _agreementFadeAnimation,
                    child: GestureDetector(
                      onTap: _closeAgreementLayer,
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SlideTransition(
                    position: _agreementSlideAnimation,
                    child: _AgreementBottomSheet(
                      termsAgreed: _isAgreementTermsAgreed,
                      privacyAgreed: _isAgreementPrivacyAgreed,
                      isSubmitting: _isAgreementSubmitting,
                      onTermsChanged: (v) =>
                          setState(() => _isAgreementTermsAgreed = v ?? false),
                      onPrivacyChanged: (v) => setState(
                        () => _isAgreementPrivacyAgreed = v ?? false,
                      ),
                      onOpenTerms: () {
                        final l10n = AppLocalizations.of(context)!;
                        _navigateToAgreementWebView(
                          l10n.agreementTermsTitle,
                          'https://sudatalk.kr/public/app/terms',
                        );
                      },
                      onOpenPrivacy: () {
                        final l10n = AppLocalizations.of(context)!;
                        _navigateToAgreementWebView(
                          l10n.agreementPrivacyTitle,
                          'https://sudatalk.kr/public/app/privacy',
                        );
                      },
                      onSubmit: _handleAgreementSubmit,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AgreementBottomSheet extends StatelessWidget {
  final bool termsAgreed;
  final bool privacyAgreed;
  final bool isSubmitting;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onPrivacyChanged;
  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onSubmit;

  const _AgreementBottomSheet({
    required this.termsAgreed,
    required this.privacyAgreed,
    required this.isSubmitting,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onOpenTerms,
    required this.onOpenPrivacy,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final isAllAgreed = termsAgreed && privacyAgreed;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 60),
              Text(
                l10n.agreementHeading,
                textAlign: TextAlign.center,
                style: theme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 48),
              _AgreementRow(
                label: l10n.agreementTermsLabel,
                linkLabel: l10n.agreementDetailsLink,
                isChecked: termsAgreed,
                onChanged: onTermsChanged,
                onLinkTap: onOpenTerms,
              ),
              const SizedBox(height: 12),
              _AgreementRow(
                label: l10n.agreementPrivacyLabel,
                linkLabel: l10n.agreementDetailsLink,
                isChecked: privacyAgreed,
                onChanged: onPrivacyChanged,
                onLinkTap: onOpenPrivacy,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: isAllAgreed && !isSubmitting ? onSubmit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAllAgreed
                      ? const Color(0xFF0CABA8)
                      : const Color(0xFF353535),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF353535),
                  disabledForegroundColor: Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.agreementButtonConfirm),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  final String label;
  final String linkLabel;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onLinkTap;

  const _AgreementRow({
    required this.label,
    required this.linkLabel,
    required this.isChecked,
    required this.onChanged,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!isChecked),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: isChecked
                  ? SvgPicture.asset(
                      'assets/images/icons/check_mint.svg',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
            ),
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.bodySmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onLinkTap,
                  child: Text(
                    linkLabel,
                    style: theme.bodySmall?.copyWith(
                      color: const Color(0xFF0CABA8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PosterMarqueeDirection { left, right }

class _PosterMarqueeRow extends StatelessWidget {
  final Animation<double> controller;
  final List<String> posters;
  final _PosterMarqueeDirection direction;
  final double rowHeight;

  const _PosterMarqueeRow({
    required this.controller,
    required this.posters,
    required this.direction,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidth = rowHeight * (2 / 3);
    final itemExtent = imageWidth + 8;
    final groupWidth = itemExtent * posters.length;

    return ClipRect(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final progress = controller.value;
          final left = direction == _PosterMarqueeDirection.left
              ? -groupWidth * progress
              : -groupWidth + (groupWidth * progress);

          return Stack(
            children: [
              Positioned(
                left: left,
                top: 0,
                height: rowHeight,
                child: _PosterGroup(
                  posters: posters,
                  imageWidth: imageWidth,
                  rowHeight: rowHeight,
                ),
              ),
              Positioned(
                left: left + groupWidth,
                top: 0,
                height: rowHeight,
                child: _PosterGroup(
                  posters: posters,
                  imageWidth: imageWidth,
                  rowHeight: rowHeight,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PosterGroup extends StatelessWidget {
  final List<String> posters;
  final double imageWidth;
  final double rowHeight;

  const _PosterGroup({
    required this.posters,
    required this.imageWidth,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final poster in posters)
          SizedBox(
            width: imageWidth + 8,
            height: rowHeight,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  poster,
                  width: imageWidth,
                  height: rowHeight - 8,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
