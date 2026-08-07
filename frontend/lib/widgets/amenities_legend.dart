import 'package:flutter/material.dart';

import 'package:trip_io/l10n/gen/app_localizations.dart';
import 'package:trip_io/widgets/amenity_categories.dart';
import 'package:trip_io/widgets/glass_panel.dart';

/// The floating "layers" button that opens [AmenitiesLegendPanel] - a
/// circular toggle matching the same Material+InkWell+CircleBorder recipe
/// the map's other floating buttons (locate-me, route-planner toggle)
/// already use, so all three read as one consistent control language.
class AmenitiesToggleButton extends StatelessWidget {
  const AmenitiesToggleButton({
    super.key,
    required this.active,
    required this.onTap,
  });

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: active
          ? Theme.of(context).colorScheme.primary
          : const Color(0xFF0B1A24),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            active ? Icons.layers : Icons.layers_outlined,
            color: Colors.white,
            size: 20,
            semanticLabel: l10n.mapAmenitiesToggleTooltip,
          ),
        ),
      ),
    );
  }
}

/// The expandable panel behind [AmenitiesToggleButton] - a master on/off
/// switch plus one row per category, each row doubling as both a legend
/// entry (color + icon + label) and a filter toggle for that category.
class AmenitiesLegendPanel extends StatelessWidget {
  const AmenitiesLegendPanel({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.enabledCategories,
    required this.onCategoryToggle,
    required this.showEmptyHint,
  });

  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final Set<String> enabledCategories;
  final void Function(String category) onCategoryToggle;

  /// True once a fetch has completed while enabled and found nothing
  /// nearby - distinct from "not fetched yet", which shows no hint at all.
  final bool showEmptyHint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GlassPanel(
      style: GlassPanelStyle.solid,
      borderRadius: BorderRadius.circular(18),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.mapAmenitiesLegendTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.mapAmenitiesShowToggle,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeTrackColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 16),
          for (final category in amenityCategories)
            Opacity(
              opacity: enabled ? 1 : 0.4,
              child: InkWell(
                onTap: enabled ? () => onCategoryToggle(category) : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: amenityCategoryColor(category),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        amenityCategoryIcon(category),
                        size: 15,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          amenityCategoryLabel(category, l10n),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: enabledCategories.contains(category),
                        onChanged: enabled
                            ? (_) => onCategoryToggle(category)
                            : null,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        activeColor: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showEmptyHint) ...[
            const SizedBox(height: 4),
            Text(
              l10n.mapAmenitiesEmptyHint,
              style: const TextStyle(color: Colors.white54, fontSize: 11.5),
            ),
          ],
        ],
      ),
    );
  }
}
