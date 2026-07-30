import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Web implementation: Google's SDK requires its own rendered button to
/// reliably hand back an idToken - see google_signin_button.dart. The
/// result of a click surfaces via `signIn.onCurrentUserChanged`, same as
/// the mobile path.
Widget buildGoogleSignInButton(GoogleSignIn signIn) {
  return SizedBox(height: 44, child: web.renderButton());
}
