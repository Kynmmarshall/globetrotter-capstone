import 'package:flutter/material.dart';
import 'package:trip_io/l10n/gen/app_localizations.dart';

/// Floating circular button that hands the current route off to Yango for
/// booking a taxi. Same 42dp circular footprint and elevation as the map's
/// other floating buttons (locate-me, amenities toggle), but shows Yango's
/// own logo mark filling the whole circle rather than a line icon inside a
/// solid-color background - the logo (a solid-red square with a white
/// "YANGO" wordmark, assets/yango.jpg) already reads as a self-contained
/// brand mark, so it's clipped to a circle rather than padded/tinted like
/// a Material icon would be.
class YangoButton extends StatelessWidget {
  const YangoButton({super.key, required this.onTap, this.loading = false});

  final VoidCallback onTap;
  final bool loading;

  static const double _diameter = 42;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.mapYangoButtonTooltip,
      child: Material(
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        child: InkWell(
          onTap: loading ? null : onTap,
          child: SizedBox(
            width: _diameter,
            height: _diameter,
            child: loading
                ? const ColoredBox(
                    color: Color(0xFF0B1A24),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Image.asset('assets/yango.jpg', fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
