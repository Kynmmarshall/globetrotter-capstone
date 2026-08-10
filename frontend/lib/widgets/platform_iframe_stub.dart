import 'package:flutter/widgets.dart';

/// Non-web fallback for platform_iframe_web.dart - never actually reached
/// (callers only use this behind a kIsWeb check), just needs to exist so
/// the conditional import compiles on Android/iOS/Windows too.
Widget buildIframe({String? src, String? srcDoc}) => const SizedBox.shrink();
