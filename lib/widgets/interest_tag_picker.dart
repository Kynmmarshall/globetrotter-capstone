import 'package:flutter/material.dart';

import 'package:trip_io/models/interest_tags.dart';

/// A single-row, horizontally-scrollable set of [interestTags] filter
/// chips, each with its own icon (see [interestTagIcon]) - shared by every
/// place the app lets someone pick from this fixed vocabulary (browsing
/// filters, registration, the profile page, and destination submission),
/// so all of them look and behave the same. Deliberately a scrolling row
/// rather than a wrapping grid: with 18 tags, wrapping would stack several
/// rows tall and push the rest of the screen down, especially on mobile.
class InterestTagPicker extends StatelessWidget {
  const InterestTagPicker({
    super.key,
    required this.selectedTags,
    required this.onToggle,
  });

  final Set<String> selectedTags;
  final void Function(String tag, bool selected) onToggle;

  static String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: interestTags.map((tag) {
          final selected = selectedTags.contains(tag);
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
              onSelected: (value) => onToggle(tag, value),
            ),
          );
        }).toList(),
      ),
    );
  }
}
