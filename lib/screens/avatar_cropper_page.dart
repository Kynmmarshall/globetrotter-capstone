import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;

import 'package:trip_io/l10n/gen/app_localizations.dart';

/// Lets someone reposition and zoom a just-picked photo inside a circular
/// frame before it's uploaded as their avatar, rather than uploading
/// whatever [ImagePicker] handed back center-cropped sight unseen. Built by
/// hand on [InteractiveViewer] + [RenderRepaintBoundary] instead of a crop
/// plugin, since the app targets Windows desktop too and the common Flutter
/// cropping packages only support mobile/web.
class AvatarCropperPage extends StatefulWidget {
  const AvatarCropperPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<AvatarCropperPage> createState() => _AvatarCropperPageState();
}

class _AvatarCropperPageState extends State<AvatarCropperPage> {
  static const double _viewportSize = 300;

  final _boundaryKey = GlobalKey();
  final _transformationController = TransformationController();

  double? _imageWidth;
  double? _imageHeight;
  double? _minScale;
  double? _maxScale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _decodeImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    final width = frame.image.width.toDouble();
    final height = frame.image.height.toDouble();
    // The scale at which the image, unscaled by the user, still fully
    // covers the circular viewport - the same job BoxFit.cover does, but
    // computed up front so InteractiveViewer's min/max scale (and the
    // initial centered transform) can be built around it.
    final baseScale = math.max(_viewportSize / width, _viewportSize / height);
    final scaledWidth = width * baseScale;
    final scaledHeight = height * baseScale;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        (_viewportSize - scaledWidth) / 2,
        (_viewportSize - scaledHeight) / 2,
        0,
        1,
      )
      ..scaleByDouble(baseScale, baseScale, baseScale, 1);
    if (!mounted) return;
    setState(() {
      _imageWidth = width;
      _imageHeight = height;
      _minScale = baseScale;
      _maxScale = baseScale * 4;
      _transformationController.value = matrix;
    });
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (!mounted) return;
    Navigator.of(context).pop(byteData?.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ready =
        _imageWidth != null && _imageHeight != null && _minScale != null;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(l10n.avatarCropTitle),
        actions: [
          TextButton(
            onPressed: ready && !_saving ? _confirm : null,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l10n.avatarCropConfirmButton,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
      body: Center(
        child: !ready
            ? const CircularProgressIndicator(color: Colors.white)
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _viewportSize + 6,
                    height: _viewportSize + 6,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipOval(
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: SizedBox(
                          width: _viewportSize,
                          height: _viewportSize,
                          child: InteractiveViewer(
                            transformationController:
                                _transformationController,
                            minScale: _minScale!,
                            maxScale: _maxScale!,
                            boundaryMargin: EdgeInsets.zero,
                            child: SizedBox(
                              width: _imageWidth,
                              height: _imageHeight,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      l10n.avatarCropHint,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
