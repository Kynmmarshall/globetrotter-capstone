import 'package:flutter/material.dart';

import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/themes/trip_colors.dart';
import 'package:trip_io/widgets/glass_panel.dart';

/// Two-step "forgot password" flow, pushed from [AuthScreen]'s login form.
///
/// Uses a manually-entered 6-digit code rather than a clickable email link:
/// this app has no deep-link/URL-scheme handling set up for its Windows,
/// Android, and Web builds, so a code the user types into the app works
/// identically everywhere a link would need per-platform plumbing first.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, required this.session});

  final SessionController session;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  static const double _backgroundBreakpoint = 700;

  final _identifierFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _showNewPassword = false;

  // Once a code has been requested, the identifier itself is locked in as
  // plain text (not editable) for step 2 - "use a different account" backs
  // all the way out to step 1 instead of allowing a mismatched
  // identifier/code pair to be submitted together.
  String? _codeSentFor;
  bool _requesting = false;
  bool _resetting = false;
  String? _error;

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_identifierFormKey.currentState!.validate()) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    final identifier = _identifierController.text.trim();
    try {
      await widget.session.requestPasswordReset(identifier);
      if (!mounted) return;
      setState(() => _codeSentFor = identifier);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    final identifier = _codeSentFor;
    if (identifier == null) return;
    setState(() {
      _resetting = true;
      _error = null;
    });
    try {
      await widget.session.resetPassword(
        identifier,
        _codeController.text.trim(),
        _newPasswordController.text,
      );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.forgotPasswordSuccessMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  void _useDifferentAccount() {
    setState(() {
      _codeSentFor = null;
      _codeController.clear();
      _newPasswordController.clear();
      _error = null;
    });
  }

  Widget _buildIdentifierStep(AppLocalizations l10n) {
    return Form(
      key: _identifierFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.forgotPasswordStep1Subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _identifierController,
            autofillHints: const [AutofillHints.username],
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.forgotPasswordIdentifierLabel,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.forgotPasswordIdentifierRequired
                : null,
            onFieldSubmitted: (_) => _requestCode(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _requesting ? null : _requestCode,
              child: _requesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.forgotPasswordSendCodeButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(AppLocalizations l10n, String identifier) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              l10n.forgotPasswordCodeSentMessage(identifier),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _resetting ? null : _useDifferentAccount,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                l10n.forgotPasswordChangeIdentifierButton,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.forgotPasswordStep2Subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 13.5),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.forgotPasswordCodeLabel,
              hintText: l10n.forgotPasswordCodeHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.forgotPasswordCodeRequired
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _newPasswordController,
            obscureText: !_showNewPassword,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: l10n.forgotPasswordNewPasswordLabel,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _showNewPassword = !_showNewPassword),
                icon: Icon(
                  _showNewPassword ? Icons.visibility_off : Icons.visibility,
                ),
                tooltip: _showNewPassword
                    ? l10n.authHidePassword
                    : l10n.authShowPassword,
              ),
            ),
            validator: (value) => (value == null || value.isEmpty)
                ? l10n.authPasswordRequired
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _resetting ? null : _resetPassword,
              child: _resetting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.forgotPasswordResetButton),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _requesting ? null : _requestCode,
              child: Text(
                l10n.forgotPasswordResendCodeButton,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final identifier = _codeSentFor;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompactBackground =
              constraints.maxWidth < _backgroundBreakpoint;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompactBackground
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(color: context.tripColors.scrim),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                GlassPanel(
                                  borderRadius: BorderRadius.circular(999),
                                  padding: EdgeInsets.zero,
                                  child: IconButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                    tooltip: MaterialLocalizations.of(
                                      context,
                                    ).backButtonTooltip,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            GlassPanel(
                              borderRadius: BorderRadius.circular(22),
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.forgotPasswordTitle,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (identifier == null)
                                    _buildIdentifierStep(l10n)
                                  else
                                    _buildResetStep(l10n, identifier),
                                  if (_error != null) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Colors.red.shade100,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
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
            ],
          );
        },
      ),
    );
  }
}
