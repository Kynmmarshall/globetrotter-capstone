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
          'GlobeTrotter',
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

  Widget _buildAuthForm(BuildContext context, BoxConstraints constraints) {
    final isCompact = constraints.maxWidth < 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Card(
            clipBehavior: Clip.antiAlias,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(0),
              child: isCompact
                  ? _buildCompactContent(context)
                  : Row(
                      children: [
                        Expanded(child: _buildSidePanel(context)),
                        Expanded(child: _buildFormPanel(context)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidePanel(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.travel_explore, size: 52, color: colors.onPrimary),
              const SizedBox(height: 18),
              Text(
                'Plan faster. Travel smarter.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                'Search destinations, create itineraries, and keep your account synced across mobile, web, and Windows.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colors.onPrimary.withValues(alpha: 0.92)),
              ),
            ],
          ),
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

  Widget _buildCompactContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeadline(context),
          const SizedBox(height: 20),
          _buildFormFields(context),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeadline(context),
          const SizedBox(height: 24),
          _buildFormFields(context),
        ],
      ),
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
                'Tip: use the same backend URL on web, Windows, and mobile to keep sessions consistent.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _buildAuthForm(context, constraints);
          },
        ),
      ),
    );
  }
}
