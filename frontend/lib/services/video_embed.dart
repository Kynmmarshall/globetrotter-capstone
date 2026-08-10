/// Works out whether a destination's video_url can be shown in an embedded
/// <iframe> on Flutter web - only relevant there, since mobile uses a real
/// WebView (see video_player_page.dart) that isn't subject to iframe
/// framing restrictions at all.
///
/// Two different embedding mechanisms are needed:
/// - [VideoEmbedMode.directSrc]: point the iframe's `src` straight at the
///   platform's own embed page. Confirmed by checking response headers
///   directly: YouTube's /embed/{id} and Facebook's official
///   plugins/video.php video-plugin URL both return no X-Frame-Options and
///   no blocking frame-ancestors CSP directive, so both genuinely embed
///   this way.
/// - [VideoEmbedMode.srcDoc]: TikTok's dedicated /embed/v2/{id} endpoint
///   also doesn't block framing header-wise, but pointing an iframe's `src`
///   directly at it isn't how TikTok expects third-party embeds to arrive -
///   in practice that intermittently trips their own "overload-protect"
///   anti-abuse response. TikTok's actually-documented integration method
///   is a `<blockquote class="tiktok-embed">` plus their own
///   `embed.js`, which then renders the player itself - that's what gets
///   loaded into the iframe via `srcdoc` instead of a bare `src` URL.
///
/// Raw Instagram post URLs are still known to block third-party framing
/// outright, so anything that isn't YouTube/Facebook/TikTok resolves to
/// null and the caller should fall back to opening the link externally.
enum VideoEmbedPlatform { youtube, facebook, tiktok }

enum VideoEmbedMode { directSrc, srcDoc }

class VideoEmbedInfo {
  const VideoEmbedInfo({
    required this.platform,
    required this.mode,
    required this.value,
  });

  final VideoEmbedPlatform platform;
  final VideoEmbedMode mode;
  // The iframe `src` URL when mode is directSrc, or the full HTML document
  // to load via `srcdoc` when mode is srcDoc.
  final String value;
}

VideoEmbedInfo? resolveVideoEmbed(String videoUrl) {
  final uri = Uri.tryParse(videoUrl);
  if (uri == null) return null;
  final host = uri.host.toLowerCase();

  if (_isYoutubeHost(host)) {
    final id = _youtubeVideoId(uri);
    if (id == null || id.isEmpty) return null;
    return VideoEmbedInfo(
      platform: VideoEmbedPlatform.youtube,
      mode: VideoEmbedMode.directSrc,
      value: 'https://www.youtube.com/embed/$id',
    );
  }

  if (_isFacebookHost(host)) {
    return VideoEmbedInfo(
      platform: VideoEmbedPlatform.facebook,
      mode: VideoEmbedMode.directSrc,
      value:
          'https://www.facebook.com/plugins/video.php'
          '?href=${Uri.encodeComponent(videoUrl)}&show_text=false',
    );
  }

  if (_isTiktokHost(host)) {
    final id = _tiktokVideoId(uri);
    if (id == null || id.isEmpty) return null;
    return VideoEmbedInfo(
      platform: VideoEmbedPlatform.tiktok,
      mode: VideoEmbedMode.srcDoc,
      value: _tiktokEmbedHtml(videoUrl: videoUrl, videoId: id),
    );
  }

  return null;
}

bool _isYoutubeHost(String host) =>
    host == 'youtube.com' ||
    host.endsWith('.youtube.com') ||
    host == 'youtu.be' ||
    host.endsWith('.youtu.be');

bool _isFacebookHost(String host) =>
    host == 'facebook.com' ||
    host.endsWith('.facebook.com') ||
    host == 'fb.watch' ||
    host.endsWith('.fb.watch');

bool _isTiktokHost(String host) =>
    host == 'tiktok.com' || host.endsWith('.tiktok.com');

String? _youtubeVideoId(Uri uri) {
  if (uri.host == 'youtu.be' || uri.host.endsWith('.youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  final segments = uri.pathSegments;
  if (segments.isNotEmpty &&
      (segments.first == 'embed' || segments.first == 'shorts') &&
      segments.length > 1) {
    return segments[1];
  }
  return uri.queryParameters['v'];
}

// tiktok.com/@user/video/{id} - the id is whatever follows "video" in the
// path. Short links (vm.tiktok.com/...) aren't handled here since they
// need a redirect resolved first to find the id at all, and every TikTok
// video_url in this catalog is already the full @user/video/{id} form.
String? _tiktokVideoId(Uri uri) {
  final segments = uri.pathSegments;
  final videoIndex = segments.indexOf('video');
  if (videoIndex == -1 || videoIndex + 1 >= segments.length) return null;
  return segments[videoIndex + 1];
}

String _htmlAttrEscape(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

// TikTok's own minimal documented embed markup - a blockquote carrying the
// video's id/url as data attributes, plus their embed.js, which replaces
// the blockquote with the actual player at runtime. This is the sanctioned
// integration path (unlike src-ing /embed/v2/{id} directly), which is what
// avoids the overload-protect response.
String _tiktokEmbedHtml({required String videoUrl, required String videoId}) {
  final citeAttr = _htmlAttrEscape(videoUrl);
  final idAttr = _htmlAttrEscape(videoId);
  return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <style>
    html, body { margin: 0; padding: 0; background: #000; height: 100%; }
    body { display: flex; align-items: center; justify-content: center; }
  </style>
</head>
<body>
  <blockquote class="tiktok-embed" cite="$citeAttr" data-video-id="$idAttr" style="max-width: 605px; min-width: 325px;">
    <section></section>
  </blockquote>
  <script async src="https://www.tiktok.com/embed.js"></script>
</body>
</html>
''';
}
