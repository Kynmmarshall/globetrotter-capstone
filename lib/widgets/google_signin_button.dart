import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_signin_button_stub.dart'
    if (dart.library.html) 'google_signin_button_web.dart'
    as impl;

/// Platform-specific Google sign-in trigger. On mobile this is a normal
/// button that calls `signIn.signIn()` directly. On web, Google's SDK
/// refuses to reliably return an idToken from a programmatic `signIn()`
/// call - it requires its own rendered button - so the web implementation
/// swaps in `google_sign_in_web`'s `renderButton()` instead. Either way,
/// the result surfaces through `signIn.onCurrentUserChanged`.
Widget buildGoogleSignInButton(GoogleSignIn signIn) {
  return impl.buildGoogleSignInButton(signIn);
}
