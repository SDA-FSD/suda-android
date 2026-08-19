import 'dart:async' show unawaited;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../utils/default_toast.dart';

/// iOS App Store 심사용 hidden login. LoginScreen 중앙 로고 5연타로만 노출.
class ReviewLoginDialog extends StatefulWidget {
  final Future<void> Function(String id, String password) onSubmit;

  const ReviewLoginDialog({
    super.key,
    required this.onSubmit,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function(String id, String password) onSubmit,
  }) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (ctx) => ReviewLoginDialog(onSubmit: onSubmit),
    );
  }

  @override
  State<ReviewLoginDialog> createState() => _ReviewLoginDialogState();
}

class _ReviewLoginDialogState extends State<ReviewLoginDialog> {
  static const _focusBorderColor = Color(0xFF80D7CF);
  static const _cardBorderRadius = 16.0;

  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _idFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _idFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _close() {
    if (_isSubmitting) return;
    Navigator.of(context).pop();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final id = _idController.text.trim();
    final password = _passwordController.text;
    if (id.isEmpty || password.isEmpty) {
      DefaultToast.show(context, 'Enter your email and password.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(id, password);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      DefaultToast.show(
        context,
        'Sign-in failed. Check your credentials and try again.',
        isError: true,
      );
      setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    final theme = Theme.of(context).textTheme;
    return InputDecoration(
      labelText: label,
      labelStyle: theme.bodySmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.55),
      ),
      floatingLabelStyle: theme.bodySmall?.copyWith(
        color: _focusBorderColor.withValues(alpha: 0.9),
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _focusBorderColor, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: !_isSubmitting,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withValues(alpha: 0.42)),
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: screenWidth * 0.82),
              child: Material(
                color: Colors.transparent,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_cardBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_cardBorderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(_cardBorderRadius),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.32),
                            width: 1,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 12, 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: _close,
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white.withValues(alpha: 0.72),
                                    size: 22,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  right: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _idController,
                                      focusNode: _idFocusNode,
                                      enabled: !_isSubmitting,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      style: theme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                      decoration: _fieldDecoration('Email'),
                                      onSubmitted: (_) =>
                                          _passwordFocusNode.requestFocus(),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _passwordController,
                                      focusNode: _passwordFocusNode,
                                      enabled: !_isSubmitting,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.done,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      style: theme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                      decoration: _fieldDecoration('Password')
                                          .copyWith(
                                        suffixIcon: IconButton(
                                          onPressed: _isSubmitting
                                              ? null
                                              : () => setState(
                                                    () => _obscurePassword =
                                                        !_obscurePassword,
                                                  ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_outlined
                                                : Icons.visibility_off_outlined,
                                            color: Colors.white
                                                .withValues(alpha: 0.45),
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      onSubmitted: (_) => unawaited(_submit()),
                                    ),
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isSubmitting ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.white
                                              .withValues(alpha: 0.55),
                                          foregroundColor: const Color(0xFF121212),
                                          disabledForegroundColor: const Color(
                                            0xFF121212,
                                          ).withValues(alpha: 0.45),
                                          elevation: 0,
                                          shape: const StadiumBorder(),
                                        ),
                                        child: _isSubmitting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Color(0xFF121212),
                                                  ),
                                                ),
                                              )
                                            : Text(
                                                'Log in',
                                                style: theme.bodyLarge
                                                    ?.copyWith(
                                                  color: const Color(0xFF121212),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
