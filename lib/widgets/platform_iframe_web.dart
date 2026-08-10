import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Embeds either a URL (`src`) or a full HTML document (`srcDoc`) as a real
/// browser <iframe> inside the Flutter web page, via
/// HtmlElementView.fromTagName - which handles the platform-view
/// registration for us, onElementCreated just configures the resulting DOM
/// element. Exactly one of [src]/[srcDoc] should be given. Only ever built
/// behind a kIsWeb check - see video_embed.dart for which URLs use which
/// mode and why.
Widget buildIframe({String? src, String? srcDoc}) {
  assert(
    (src == null) != (srcDoc == null),
    'buildIframe needs exactly one of src or srcDoc',
  );
  return HtmlElementView.fromTagName(
    tagName: 'iframe',
    onElementCreated: (Object element) {
      final iframe = element as web.HTMLIFrameElement;
      if (srcDoc != null) {
        iframe.srcdoc = srcDoc.toJS;
      } else {
        iframe.src = src!;
      }
      iframe.style.border = 'none';
      iframe.allow =
          'accelerometer; autoplay; clipboard-write; encrypted-media; '
          'gyroscope; picture-in-picture; web-share';
      iframe.allowFullscreen = true;
    },
  );
}
