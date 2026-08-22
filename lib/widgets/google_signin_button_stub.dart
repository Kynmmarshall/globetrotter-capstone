import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';

/// Non-web (Android) implementation: a normal button that triggers the
/// native account picker directly. Wrapped in a [Builder] rather than
/// adding a `BuildContext` parameter - keeps this function's signature
/// identical to the web variant's, since both are swapped in by the same
/// conditional-import dispatcher (google_signin_button.dart).
Widget buildGoogleSignInButton(GoogleSignIn signIn) {
  return Builder(
    builder: (context) => OutlinedButton.icon(
      onPressed: () => signIn.signIn(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.g_mobiledata, size: 26),
      label: Text(AppLocalizations.of(context)!.googleSignInButton),
    ),
  );
}
