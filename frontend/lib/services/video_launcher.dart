import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/screens/video_player_page.dart';
import 'package:url_launcher/url_launcher.dart';

/// Plays a destination's video. On Android/iOS this pushes an in-app
/// WebView overlay ([VideoPlayerPage]); on every other platform (Windows
/// desktop, Web), Flutter's WebView plugin isn't available, so the link
/// opens externally instead. `kIsWeb` is checked first since `dart:io`'s
/// [Platform] throws on web - same ordering `buildLocationSettings` in
/// trip_map.dart already uses.
Future<void> playDestinationVideo(BuildContext context, String videoUrl) async {
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPlayerPage(videoUrl: videoUrl),
      ),
    );
    return;
  }

  final uri = Uri.parse(videoUrl);
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.videoLaunchFailed)),
    );
  }
}
