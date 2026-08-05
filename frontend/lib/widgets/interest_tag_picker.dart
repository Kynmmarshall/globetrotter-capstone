import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';

import 'package:trip_io/models/interest_tags.dart';

/// A single-row, horizontally-scrollable set of [interestTags] filter
/// chips, each with its own icon (see [interestTagIcon]) - shared by every
/// place the app lets someone pick from this fixed vocabulary (browsing
/// filters, registration, the profile page, and destination submission),
/// so all of them look and behave the same. Deliberately a scrolling row
/// rather than a wrapping grid: with 18 tags, wrapping would stack several
/// rows tall and push the rest of the screen down, especially on mobile.
class InterestTagPicker extends StatefulWidget {
  const InterestTagPicker({
    super.key,
    required this.selectedTags,
    required this.onToggle,
  });

  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onToggle;

  @override
  State<InterestTagPicker> createState() => _InterestTagPickerState();
}

class _InterestTagPickerState extends State<InterestTagPicker> {
  final _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  static const double _scrollStep = 220;

  // Mouse/trackpad platforms get click-to-scroll arrows instead of relying
  // on drag or the wheel: a horizontal-only scroll view only responds to
  // click-and-drag by default, which isn't how anyone expects to scroll a
  // row with a mouse, and redirecting the wheel's vertical delta onto it
  // instead turned out to feel unpredictable rather than helpful. Touch
  // platforms keep plain swipe-to-scroll, which already works fine there,
  // so no arrows clutter the row on phones.
  bool get _showArrows =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  void initState() {
    super.initState();
    if (_showArrows) {
      _scrollController.addListener(_updateArrowState);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateArrowState());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateArrowState() {
    if (!mounted || !_scrollController.hasClients) return;
    final position = _scrollController.position;
    final canLeft = position.pixels > position.minScrollExtent + 1;
    final canRight = position.pixels < position.maxScrollExtent - 1;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollBy(double delta) {
    if (!_scrollController.hasClients) return;
    final target = (_scrollController.offset + delta).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Widget _arrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: enabled ? 0.14 : 0.05),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? Colors.white : Colors.white24,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final row = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: interestTags.map((tag) {
          final selected = widget.selectedTags.contains(tag);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                _capitalize(tag),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF1A2530),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: selected,
              showCheckmark: false,
              avatar: Icon(
                interestTagIcon(tag),
                size: 16,
                color: selected ? Colors.white : const Color(0xFF1A2530),
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.88),
              selectedColor: colors.primary.withValues(alpha: 0.85),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              onSelected: (value) => widget.onToggle(tag, value),
            ),
          );
        }).toList(),
      ),
    );

    if (!_showArrows) return row;

    return Row(
      children: [
        _arrowButton(
          icon: Icons.chevron_left,
          enabled: _canScrollLeft,
          onTap: () => _scrollBy(-_scrollStep),
        ),
        const SizedBox(width: 4),
        Expanded(child: row),
        const SizedBox(width: 4),
        _arrowButton(
          icon: Icons.chevron_right,
          enabled: _canScrollRight,
          onTap: () => _scrollBy(_scrollStep),
        ),
      ],
    );
  }
}
