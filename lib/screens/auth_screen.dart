import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/screens/forgot_password_page.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/brand_logo_lockup.dart';
import 'package:trip_io/widgets/feature_pill.dart';
import 'package:trip_io/widgets/google_signin_button.dart';
import 'package:trip_io/widgets/interest_tag_picker.dart';

// Set at build time with:
//   --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id.apps.googleusercontent.com
// The same client ID is used for both web (as `clientId`) and Android (as
// `serverClientId`) so every platform's idToken shares one `aud`, matching
// the single GOOGLE_OAUTH_CLIENT_ID the backend validates against.
const _googleClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.session,
    this.initialLoginMode = true,
  });

  final SessionController session;

  /// False starts the form on the register tab instead of login - used
  /// when arriving via a shared-itinerary claim link, where whoever opened
  /// it most likely doesn't have an account yet.
  final bool initialLoginMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  late bool _loginMode = widget.initialLoginMode;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  final Set<String> _selectedInterests = {};

  GoogleSignIn? _googleSignIn;
  StreamSubscription<GoogleSignInAccount?>? _googleSub;
  bool _googleBusy = false;
  String? _googleError;

  // Breakpoints: a phone gets the tall portrait background + a bottom
  // sheet-style card; tablets and desktop/web get the wide landscape
  // background. Desktop/web additionally get a two-column layout with
  // room for a tagline next to the card.
  static const double _tabletBreakpoint = 700;
  static const double _desktopBreakpoint = 1080;

  // google_sign_in has no Windows implementation - same constraint as
  // google_maps_flutter. Windows keeps username/password only. Also
  // requires a client ID to be configured at build time; without one,
  // there's nothing to sign in against, so the button stays hidden.
  bool get _supportsGoogleSignIn =>
      _googleClientId.isNotEmpty &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.android);

  @override
  void initState() {
    super.initState();
    if (_supportsGoogleSignIn) {
      final signIn = GoogleSignIn(
        scopes: const ['email'],
        clientId: kIsWeb ? _googleClientId : null,
        serverClientId: kIsWeb ? null : _googleClientId,
      );
      _googleSignIn = signIn;
      _googleSub = signIn.onCurrentUserChanged.listen(_onGoogleAccount);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _googleSub?.cancel();
    super.dispose();
  }

  Future<void> _onGoogleAccount(GoogleSignInAccount? account) async {
    if (account == null || _googleBusy) return;
    setState(() {
      _googleBusy = true;
      _googleError = null;
    });
    try {
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw Exception('Google did not return an ID token.');
      }
      await widget.session.loginWithGoogle(idToken);
    } catch (e) {
      if (mounted) {
        setState(
          () => _googleError = e.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_loginMode) {
      await widget.session.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
    } else {
      await widget.session.register(
        _usernameController.text.trim(),
        _passwordController.text,
        email: _emailController.text.trim(),
        interests: _selectedInterests.toList(),
      );
    }
  }

  void _toggleMode() {
    setState(() {
      _loginMode = !_loginMode;
      if (_loginMode) {
        _confirmPasswordController.clear();
      }
    });
    widget.session.clearError();
  }

  Widget _buildHeadline(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loginMode ? l10n.authLoginTitle : l10n.authRegisterTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _loginMode ? l10n.authLoginSubtitle : l10n.authRegisterSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInterestsPicker(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.interestsLabel,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.interestsHelper,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 10),
        InterestTagPicker(
          selectedTags: _selectedInterests,
          onToggle: (tag, value) {
            setState(() {
              if (value) {
                _selectedInterests.add(tag);
              } else {
                _selectedInterests.remove(tag);
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required bool visible,
    required ValueChanged<bool> onToggle,
    required String? Function(String?) validator,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () => onToggle(!visible),
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          tooltip: visible ? l10n.authHidePassword : l10n.authShowPassword,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFormFields(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loginMode) ...[
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.authEmailLabel,
                helperText: l10n.authEmailHelper,
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return l10n.authEmailRequired;
                }
                if (!email.contains('@')) {
                  return l10n.authEmailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: l10n.authUsernameLabel,
              helperText: l10n.authUsernameHelper,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.authUsernameRequired
                : null,
          ),
          const SizedBox(height: 14),
          _buildPasswordField(
            context: context,
            controller: _passwordController,
            label: l10n.authPasswordLabel,
            visible: _showPassword,
            onToggle: (value) => setState(() => _showPassword = value),
            validator: (value) => (value == null || value.isEmpty)
                ? l10n.authPasswordRequired
                : null,
          ),
          if (!_loginMode) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: l10n.authConfirmPasswordLabel,
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  tooltip: _showConfirmPassword
                      ? l10n.authHidePassword
                      : l10n.authShowPassword,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.authConfirmPasswordRequired;
                }
                if (value != _passwordController.text) {
                  return l10n.authPasswordsMismatch;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildInterestsPicker(context, l10n, colorScheme),
          ],
          if (_loginMode) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.authLoginTip,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ForgotPasswordPage(session: widget.session),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.forgotPasswordLink),
              ),
            ),
          ],
          if (widget.session.error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.session.error!,
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: widget.session.isLoading ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: widget.session.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _loginMode
                        ? l10n.authLoginButton
                        : l10n.authCreateAccountButton,
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.session.isLoading ? null : _toggleMode,
            child: Text(
              _loginMode ? l10n.authToggleToRegister : l10n.authToggleToLogin,
            ),
          ),
          if (_supportsGoogleSignIn) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.authOrDivider,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: colorScheme.outlineVariant)),
              ],
            ),
            const SizedBox(height: 14),
            if (_googleError != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _googleError!,
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
              const SizedBox(height: 10),
            ],
            if (_googleBusy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (_googleSignIn != null)
              buildGoogleSignInButton(_googleSignIn!),
          ],
        ],
      ),
    );
  }

  Widget _buildCardContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeadline(context),
        const SizedBox(height: 20),
        _buildFormFields(context),
      ],
    );
  }

  /// Frosted glass card so the branded background photo stays visible
  /// around its edges instead of being hidden behind a solid panel.
  Widget _glassCard(
    BuildContext context, {
    required Widget child,
    required BorderRadius borderRadius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.52),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  /// Phone layout: the logo sits in a fixed (non-scrolling) header so it
  /// can never be covered, and the form docks to the bottom of the space
  /// below it as a sheet-style card that scrolls when content grows.
  Widget _buildMobileLayout(BuildContext context, BoxConstraints constraints) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: BrandLogoLockup(iconSize: 40),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                return SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: inner.maxHeight - 16,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _glassCard(
                          context,
                          borderRadius: BorderRadius.circular(24),
                          child: _buildCardContent(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet layout: landscape background, single centered card - there
  /// isn't quite enough width here for a second column of copy.
  Widget _buildTabletLayout(BuildContext context, BoxConstraints constraints) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _glassCard(
              context,
              borderRadius: BorderRadius.circular(28),
              child: _buildCardContent(context),
            ),
          ),
        ),
      ),
    );
  }

  /// Desktop/web layout: wide landscape background with room for a
  /// tagline + feature pills beside the card, like a marketing split view.
  Widget _buildDesktopLayout(BuildContext context, BoxConstraints constraints) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1160),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: _buildTaglineColumn(context)),
                const SizedBox(width: 48),
                Expanded(
                  flex: 5,
                  child: _glassCard(
                    context,
                    borderRadius: BorderRadius.circular(28),
                    child: _buildCardContent(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaglineColumn(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const shadows = [
      Shadow(blurRadius: 16, color: Colors.black54, offset: Offset(0, 2)),
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.authTaglineTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              shadows: shadows,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.authTaglineSubtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              shadows: shadows,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FeaturePill(
                icon: Icons.phone_android,
                label: l10n.authFeatureMobile,
              ),
              FeaturePill(icon: Icons.web, label: l10n.authFeatureWeb),
              FeaturePill(
                icon: Icons.desktop_windows,
                label: l10n.authFeatureDesktop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _tabletBreakpoint;
          final isDesktop = constraints.maxWidth >= _desktopBreakpoint;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                isCompact
                    ? 'assets/backgrounds/mobile.png'
                    : 'assets/backgrounds/pc.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.18),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0.2, 0.7, 1.0],
                  ),
                ),
              ),
              // Soft, edge-free shade behind the tagline copy (desktop
              // only) so it stays legible over busy parts of the photo
              // without reading as a hard card/box.
              if (isDesktop)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.35, 0.05),
                      radius: 0.85,
                      colors: [Color(0x66000000), Colors.transparent],
                    ),
                  ),
                ),
              if (isCompact)
                _buildMobileLayout(context, constraints)
              else if (isDesktop)
                _buildDesktopLayout(context, constraints)
              else
                _buildTabletLayout(context, constraints),
              // On phones the logo lives inside _buildMobileLayout's fixed
              // header instead, so it scrolls in-flow and can never end up
              // underneath the card.
              if (!isCompact)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: BrandLogoLockup(iconSize: 46),
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
