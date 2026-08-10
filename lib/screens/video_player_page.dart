import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/services/video_embed.dart';
import 'package:trip_io/widgets/platform_iframe_stub.dart'
    if (dart.library.html) 'package:trip_io/widgets/platform_iframe_web.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Fullscreen dialog that plays a destination's video.
///
/// - Android/iOS: an embedded WebView loads the raw video_url directly -
///   native WebViews aren't subject to browser iframe restrictions, so no
///   platform-specific "embed" URL is needed there.
/// - Web: embeds [webEmbed] (see video_embed.dart) as a real <iframe> -
///   only reachable this way for YouTube/Facebook/TikTok, the platforms
///   confirmed to actually allow third-party framing. [playDestinationVideo]
///   in video_launcher.dart only pushes this page on web when that resolved
///   to something non-null; anything else opens externally instead.
class VideoPlayerPage extends StatefulWidget {
  const VideoPlayerPage({super.key, required this.videoUrl, this.webEmbed});

  final String videoUrl;
  final VideoEmbedInfo? webEmbed;

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  WebViewController? _controller;
  bool _hasError = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _loading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.videoUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.videoCloseTooltip,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // A wide/landscape-ish box (whether the full screen, a forced 16:9
      // ratio, or even a generously-capped-but-still-wide box - all tried
      // before this) only has room for a portrait phone-shot clip (the
      // overwhelming majority of what's in this catalog - TikTok/Facebook
      // clips) at a small fraction of its actual height, so a chunk of the
      // video reads as "cut off". TikTok's own web player deliberately
      // uses a narrow, tall column instead for exactly this reason - a
      // portrait video gets its full height, and a landscape video just
      // pillarboxes narrower than it would on a wide screen (still whole,
      // never cropped). Matching that shape here, rather than the ordinary
      // "wide video player" default, is what actually fixes this.
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight * 0.92;
            final maxWidth = (maxHeight * 9 / 16).clamp(280.0, 480.0);
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                maxHeight: maxHeight,
              ),
              child: kIsWeb ? _buildWebEmbed(l10n) : _buildMobileWebView(l10n),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebEmbed(AppLocalizations l10n) {
    final embed = widget.webEmbed;
    if (embed == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.videoLoadError,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    // The iframe shows the embedded player's own loading/error UI directly -
    // there's no cross-origin way to hook page-load/error events on it the
    // way the mobile WebView's NavigationDelegate does.
    return embed.mode == VideoEmbedMode.srcDoc
        ? buildIframe(srcDoc: embed.value)
        : buildIframe(src: embed.value);
  }

  Widget _buildMobileWebView(AppLocalizations l10n) {
    return Stack(
      children: [
        if (!_hasError) WebViewWidget(controller: _controller!),
        if (_hasError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                l10n.videoLoadError,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_loading && !_hasError)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      ],
    );
  }
}
