import 'package:flutter/material.dart';
import 'package:trip_io/services/session_controller.dart';

/// A tappable favorite/unfavorite star, meant to sit on top of a
/// destination card or in a detail page header. Reads its favorited state
/// straight from [session] each build - the app rebuilds on every
/// [SessionController] change (see app.dart's AnimatedBuilder), so this
/// stays in sync without any local state of its own beyond an in-flight
/// guard against double-taps.
class FavoriteToggleButton extends StatefulWidget {
  const FavoriteToggleButton({
    super.key,
    required this.session,
    required this.destinationId,
    this.size = 20,
  });

  final SessionController session;
  final String destinationId;
  final double size;

  @override
  State<FavoriteToggleButton> createState() => _FavoriteToggleButtonState();
}

class _FavoriteToggleButtonState extends State<FavoriteToggleButton> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.session.toggleFavorite(widget.destinationId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.session.isFavorite(widget.destinationId);
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: _busy
            ? SizedBox(
                width: widget.size,
                height: widget.size,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? const Color(0xFFFF6B81) : Colors.white,
                size: widget.size,
              ),
      ),
    );
  }
}
