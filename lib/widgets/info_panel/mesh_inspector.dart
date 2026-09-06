import 'package:flutter/material.dart';
import '../../localization.dart';

/// The mesh list inside the VRM info section: sort controls, bulk visibility
/// and wireframe toggles, and one row per mesh.
///
/// Every action is reported through a callback rather than reaching for the JS
/// side directly, so the whole widget can be built in a test without a viewer
/// behind it.
class MeshInspector extends StatelessWidget {
  const MeshInspector({
    super.key,
    required this.meshDetails,
    required this.hiddenMeshes,
    required this.wireframeMeshes,
    required this.focusedMesh,
    required this.sortKey,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onSortReset,
    required this.onVisibilityChanged,
    required this.onFocusChanged,
    required this.onWireframeChanged,
    required this.onHighlight,
    required this.onShowAll,
    required this.onHideAll,
    required this.onWireframeAll,
    required this.onClearAllWireframes,
  });

  final List<dynamic> meshDetails;
  final Set<String> hiddenMeshes;
  final Set<String> wireframeMeshes;
  final String? focusedMesh;
  final String sortKey;
  final bool sortAscending;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onSortReset;
  final ValueChanged<String> onVisibilityChanged;
  final ValueChanged<String> onFocusChanged;
  final ValueChanged<String> onWireframeChanged;
  final ValueChanged<String> onHighlight;
  final VoidCallback onShowAll;
  final VoidCallback onHideAll;
  final VoidCallback onWireframeAll;
  final VoidCallback onClearAllWireframes;

  List<Map<String, dynamic>> _sortedMeshDetails() {
    final list = meshDetails.cast<Map<String, dynamic>>().toList();
    if (sortKey == 'none') return list;

    list.sort((a, b) {
      int result;
      if (sortKey == 'name') {
        result = (a['name'] as String).compareTo(b['name'] as String);
      } else {
        result = (a['triangles'] as int).compareTo(b['triangles'] as int);
      }
      return sortAscending ? result : -result;
    });
    return list;
  }

  Widget _buildSortButton(BuildContext context, String key) {
    final isActive = sortKey == key;
    final tooltipText = key == 'name'
        ? Localization.get('sortByName')
        : Localization.get('sortByPolygons');
    final icon = key == 'name' ? Icons.abc : Icons.now_widgets_outlined;

    return Tooltip(
      message: tooltipText,
      child: GestureDetector(
        onTap: () => onSortChanged(key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
              ),
              if (isActive)
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortResetButton(BuildContext context) {
    return Tooltip(
      message: Localization.get('sortReset'),
      child: GestureDetector(
        onTap: onSortReset,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.refresh,
            size: 14,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedDetails = _sortedMeshDetails();
    final allHidden = hiddenMeshes.length == meshDetails.length;
    final allWireframe = wireframeMeshes.length == meshDetails.length;
    return ExpansionTile(
      title: Row(
        children: [
          Text('${Localization.get('meshDetails')} (${meshDetails.length})',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildSortButton(context, 'triangles'),
          const SizedBox(width: 4),
          _buildSortButton(context, 'name'),
          const SizedBox(width: 4),
          _buildSortResetButton(context),
        ],
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(left: 8),
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        // Bulk action buttons
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Visibility toggle all
              GestureDetector(
                onTap: allHidden ? onShowAll : onHideAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: allHidden ? Colors.grey.shade300 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        allHidden ? Icons.visibility : Icons.visibility_off,
                        size: 14,
                        color: Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        allHidden
                            ? Localization.get('showAll')
                            : Localization.get('hideAll'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Wireframe toggle all
              GestureDetector(
                onTap: allWireframe ? onClearAllWireframes : onWireframeAll,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        allWireframe ? Colors.green.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.grid_on,
                        size: 14,
                        color: allWireframe ? Colors.green : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        allWireframe
                            ? Localization.get('wireframeOff')
                            : Localization.get('wireframeOn'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Mesh list
        ...List.generate(sortedDetails.length, (index) {
          final m = sortedDetails[index];
          final name = m['name'] as String;
          final tris = m['triangles'] as int;
          final mats = m['materials'] as int;
          final isLast = index == sortedDetails.length - 1;
          final isHidden = hiddenMeshes.contains(name);
          final isFocused = focusedMesh == name;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onHighlight(name),
              onLongPress: () => onFocusChanged(name),
              hoverColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: isFocused
                    ? BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    // Visibility toggle
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onVisibilityChanged(name),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          isHidden ? Icons.visibility_off : Icons.visibility,
                          size: 16,
                          color: isHidden ? Colors.grey : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    // Wireframe toggle
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onWireframeChanged(name),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.grid_on,
                          size: 16,
                          color: wireframeMeshes.contains(name)
                              ? Colors.green
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      isLast ? '└─ ' : '├─ ',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHidden ? Colors.grey : null,
                        ),
                      ),
                    ),
                    Text(
                      '$tris tris, $mats mat${mats > 1 ? 's' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        // Hint for long-press focus mode
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            Localization.get('meshFocusHint'),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }
}
