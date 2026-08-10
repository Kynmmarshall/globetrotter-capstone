import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/screens/video_player_page.dart';
import 'package:trip_io/services/video_embed.dart';
import 'package:url_launcher/url_launcher.dart';

/// Plays a destination's video.
///
/// - Android/iOS: pushes an in-app WebView overlay ([VideoPlayerPage])
///   loading the raw video_url - Flutter's WebView plugin supports both.
/// - Web: pushes the same overlay, but as a real embedded <iframe> - only
///   for YouTube/Facebook/TikTok links, the platforms confirmed to actually
///   allow third-party framing (see video_embed.dart). Anything else on
///   web, and everything on Windows desktop (no embedded-browser option
///   there at all), opens externally instead.
///
/// `kIsWeb` is checked first since `dart:io`'s [Platform] throws on web -
/// same ordering `buildLocationSettings` in trip_map.dart already uses.
Future<void> playDestinationVideo(BuildContext context, String videoUrl) async {
  final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  final webEmbed = kIsWeb ? resolveVideoEmbed(videoUrl) : null;

  if (isMobile || webEmbed != null) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => VideoPlayerPage(videoUrl: videoUrl, webEmbed: webEmbed),
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
