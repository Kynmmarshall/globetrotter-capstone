import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Non-web (Android) implementation: a normal button that triggers the
/// native account picker directly.
Widget buildGoogleSignInButton(GoogleSignIn signIn) {
  return OutlinedButton.icon(
    onPressed: () => signIn.signIn(),
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
    icon: const Icon(Icons.g_mobiledata, size: 26),
    label: const Text('Sign in with Google'),
  );
}
