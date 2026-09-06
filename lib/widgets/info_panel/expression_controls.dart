import 'package:flutter/material.dart';
import '../../localization.dart';

/// Blend shape / expression buttons.
///
/// One expression is applied at a time: tapping the active one clears it, and
/// reset clears everything. Which JS calls that takes is the parent's business;
/// this widget only reports what was picked.
class ExpressionControls extends StatelessWidget {
  const ExpressionControls({
    super.key,
    required this.clips,
    required this.activeExpression,
    required this.onSelected,
    required this.onReset,
  });

  /// Expression names from the VRM, or null/empty when it has none.
  final List<dynamic>? clips;
  final String? activeExpression;

  /// Called with the picked name, or null when the active one is tapped again.
  final ValueChanged<String?> onSelected;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final clips = this.clips;
    if (clips == null || clips.isEmpty) {
      return Text(
        Localization.get('noExpressions'),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return ExpansionTile(
      title: Text('${Localization.get('expressions')} (${clips.length})',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: onReset,
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  Localization.get('reset'),
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              ...clips.map((clip) {
                final name = clip as String;
                final isActive = activeExpression == name;
                return ElevatedButton(
                  onPressed: () => onSelected(isActive ? null : name),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    backgroundColor:
                        isActive ? Theme.of(context).colorScheme.primary : null,
                    foregroundColor: isActive
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                  child: Text(name, style: const TextStyle(fontSize: 11)),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
