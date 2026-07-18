import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:trip_io/services/session_controller.dart';
import 'package:trip_io/widgets/feature_pill.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loginMode = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  // Breakpoints: a phone gets the tall portrait background + a bottom
  // sheet-style card; tablets and desktop/web get the wide landscape
  // background. Desktop/web additionally get a two-column layout with
  // room for a tagline next to the card.
  static const double _tabletBreakpoint = 700;
  static const double _desktopBreakpoint = 1080;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_loginMode) {
      await widget.session.login(_usernameController.text.trim(), _passwordController.text);
    } else {
      await widget.session.register(
        _usernameController.text.trim(),
        _passwordController.text,
        email: _emailController.text.trim(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loginMode
              ? 'Log In'
              : 'Register',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          _loginMode
              ? 'Sign in to continue planning and managing your trips.'
              : 'Create your account to save itineraries and get recommendations.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool visible,
    required ValueChanged<bool> onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          onPressed: () => onToggle(!visible),
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          tooltip: visible ? 'Hide password' : 'Show password',
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildFormFields(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_loginMode) ...[
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                helperText: 'We use this for account contact and profile info',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Email is required';
                }
                if (!email.contains('@')) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
          ],
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              helperText: 'This is your account login name',
            ),
            validator: (value) => (value == null || value.trim().isEmpty) ? 'Username is required' : null,
          ),
          const SizedBox(height: 14),
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            visible: _showPassword,
            onToggle: (value) => setState(() => _showPassword = value),
            validator: (value) => (value == null || value.isEmpty) ? 'Password is required' : null,
          ),
          if (!_loginMode) ...[
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                  icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                  tooltip: _showConfirmPassword ? 'Hide password' : 'Show password',
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
          if (_loginMode)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Tip: use the correct username and password you used in your account creation.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
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
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: widget.session.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_loginMode ? 'Login' : 'Create account'),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: widget.session.isLoading ? null : _toggleMode,
            child: Text(_loginMode ? 'No account? Register' : 'Already have an account? Login'),
          ),
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
  Widget _glassCard(BuildContext context, {required Widget child, required BorderRadius borderRadius}) {
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
            child: _buildLogoLockup(iconSize: 40),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                return SingleChildScrollView(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: inner.maxHeight - 16),
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
                Expanded(
                  flex: 6,
                  child: _buildTaglineColumn(context),
                ),
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

  /// The background photos are logo-free, so the trip_io mark is
  /// composited on top here instead.
  Widget _buildLogoLockup({double iconSize = 40}) {
    const navy = Color(0xFF0D2A4A);
    const brandBlue = Color(0xFF1E88E5);
    const shadows = [Shadow(blurRadius: 10, color: Colors.white70, offset: Offset(0, 1))];
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: iconSize * 0.3, vertical: iconSize * 0.18),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/logo.png', height: iconSize),
                const SizedBox(width: 10),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontSize: iconSize * 0.6,
                      fontWeight: FontWeight.w800,
                      shadows: shadows,
                    ),
                    children: const [
                      TextSpan(text: 'trip', style: TextStyle(color: navy)),
                      TextSpan(text: '_io', style: TextStyle(color: brandBlue)),
                    ],
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
    const shadows = [Shadow(blurRadius: 16, color: Colors.black54, offset: Offset(0, 2))];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Plan faster. Travel smarter.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  shadows: shadows,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            'Search destinations, create itineraries, and keep your account synced across mobile, web, and Windows.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, shadows: shadows),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              FeaturePill(icon: Icons.phone_android, label: 'Mobile ready'),
              FeaturePill(icon: Icons.web, label: 'Web ready'),
              FeaturePill(icon: Icons.desktop_windows, label: 'Desktop ready'),
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
                isCompact ? 'assets/backgrounds/mobile.png' : 'assets/backgrounds/pc.png',
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
                      child: _buildLogoLockup(iconSize: 46),
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
