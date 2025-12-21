import 'package:flutter/material.dart';
import 'dart:js_interop';
import '../localization.dart';
import '../js_interop.dart' as js;

class InfoPanel extends StatelessWidget {
  final double width;
  final Map<String, dynamic>? vrmInfo;
  final Map<String, dynamic>? animationInfo;
  final bool isLoading;
  final bool isLoadingAnimation;
  final String? errorMessage;
  final String? activeExpression;
  final String? focusedMesh;
  final Set<String> wireframeMeshes;
  final Set<String> hiddenMeshes;
  final String meshSortKey;
  final bool meshSortAscending;
  final VoidCallback onOpenFile;
  final VoidCallback onOpenAnimation;
  final VoidCallback onStopAnimation;
  final ValueChanged<String?> onExpressionChanged;
  final ValueChanged<String> onMeshVisibilityChanged;
  final ValueChanged<String> onMeshFocusChanged;
  final ValueChanged<String> onMeshWireframeChanged;
  final VoidCallback onShowAllMeshes;
  final VoidCallback onHideAllMeshes;
  final VoidCallback onWireframeAllMeshes;
  final VoidCallback onClearAllWireframes;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onSortReset;
  final ValueChanged<double> onWidthChanged;

  const InfoPanel({
    super.key,
    required this.width,
    required this.vrmInfo,
    required this.animationInfo,
    required this.isLoading,
    required this.isLoadingAnimation,
    required this.errorMessage,
    required this.activeExpression,
    required this.focusedMesh,
    required this.wireframeMeshes,
    required this.hiddenMeshes,
    required this.meshSortKey,
    required this.meshSortAscending,
    required this.onOpenFile,
    required this.onOpenAnimation,
    required this.onStopAnimation,
    required this.onExpressionChanged,
    required this.onMeshVisibilityChanged,
    required this.onMeshFocusChanged,
    required this.onMeshWireframeChanged,
    required this.onShowAllMeshes,
    required this.onHideAllMeshes,
    required this.onWireframeAllMeshes,
    required this.onClearAllWireframes,
    required this.onSortChanged,
    required this.onSortReset,
    required this.onWidthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Resize handle
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              final newWidth = width - details.delta.dx;
              onWidthChanged(newWidth.clamp(250, 600));
            },
            child: Container(
              width: 4,
              color: Colors.grey.shade300,
            ),
          ),
        ),
        // Panel content
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.inversePrimary,
                  child: const Text(
                    'VRM Polygon Checker',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildButtons(context),
                        if (animationInfo != null) _buildAnimationCard(context),
                        const SizedBox(height: 24),
                        _buildVrmInfoSection(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : onOpenFile,
            icon: const Icon(Icons.folder_open),
            label: Text(Localization.get('openVrmFile')),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isLoadingAnimation ? null : onOpenAnimation,
            icon: const Icon(Icons.animation),
            label: Text(Localization.get('loadAnimation')),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimationCard(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.play_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    animationInfo!['fileName'] ?? 'Animation',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                IconButton(
                  onPressed: onStopAnimation,
                  icon: const Icon(Icons.stop),
                  tooltip: Localization.get('stopAnimation'),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVrmInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localization.get('vrmInfo'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (errorMessage != null)
          Text(errorMessage!, style: const TextStyle(color: Colors.red))
        else if (vrmInfo != null)
          _buildInfoTable(context)
        else
          Text(Localization.get('noVrmLoaded')),
      ],
    );
  }

  Widget _buildInfoTable(BuildContext context) {
    final fileName = vrmInfo!['fileName'] as String?;
    final meshDetails = vrmInfo!['meshDetails'] as List<dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fileName != null) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  fileName,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'VRM ${vrmInfo!['vrmVersion'] ?? '?'}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        _buildBasicInfo(context),
        if (meshDetails != null && meshDetails.isNotEmpty) ...[
          const Divider(),
          _buildMeshDetails(context, meshDetails),
        ],
        const Divider(),
        _buildExpressionButtons(context),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    return ExpansionTile(
      title: Text(Localization.get('basicInfo'), style: const TextStyle(fontWeight: FontWeight.bold)),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      initiallyExpanded: true,
      children: [
        _infoRow(Localization.get('name'), vrmInfo!['name']),
        _infoRow(Localization.get('author'), vrmInfo!['author']),
        const Divider(),
        _infoRow(Localization.get('vertices'), '${vrmInfo!['vertexCount']}'),
        _infoRow(Localization.get('triangles'), '${vrmInfo!['triangleCount']}'),
        _infoRow(Localization.get('meshes'), '${vrmInfo!['meshCount']}'),
        const Divider(),
        _infoRow(Localization.get('bones'), '${vrmInfo!['boneCount']}'),
        _infoRow(Localization.get('materials'), '${vrmInfo!['materialCount']}'),
        _infoRow(Localization.get('textures'), '${vrmInfo!['textureCount']}'),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildExpressionButtons(BuildContext context) {
    final clips = vrmInfo!['blendShapeClips'] as List<dynamic>?;
    if (clips == null || clips.isEmpty) {
      return Text(
        Localization.get('noExpressions'),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    }

    return ExpansionTile(
      title: Text('${Localization.get('expressions')} (${clips.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  js.resetExpressions();
                  onExpressionChanged(null);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  onPressed: () {
                    if (isActive) {
                      js.setExpression(name.toJS, (0.0).toJS);
                      onExpressionChanged(null);
                    } else {
                      if (activeExpression != null) {
                        js.setExpression(activeExpression!.toJS, (0.0).toJS);
                      }
                      js.setExpression(name.toJS, (1.0).toJS);
                      onExpressionChanged(name);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    backgroundColor: isActive
                        ? Theme.of(context).colorScheme.primary
                        : null,
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

  List<Map<String, dynamic>> _getSortedMeshDetails(List<dynamic> meshDetails) {
    final list = meshDetails.cast<Map<String, dynamic>>().toList();
    if (meshSortKey == 'none') return list;

    list.sort((a, b) {
      int result;
      if (meshSortKey == 'name') {
        result = (a['name'] as String).compareTo(b['name'] as String);
      } else {
        result = (a['triangles'] as int).compareTo(b['triangles'] as int);
      }
      return meshSortAscending ? result : -result;
    });
    return list;
  }

  Widget _buildSortButton(BuildContext context, String key) {
    final isActive = meshSortKey == key;
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
                color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade700,
              ),
              if (isActive)
                Icon(
                  meshSortAscending ? Icons.arrow_upward : Icons.arrow_downward,
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

  Widget _buildMeshDetails(BuildContext context, List<dynamic> meshDetails) {
    final sortedDetails = _getSortedMeshDetails(meshDetails);
    final allHidden = hiddenMeshes.length == meshDetails.length;
    final allWireframe = wireframeMeshes.length == meshDetails.length;
    return ExpansionTile(
      title: Row(
        children: [
          Text('${Localization.get('meshDetails')} (${meshDetails.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onTap: allHidden ? onShowAllMeshes : onHideAllMeshes,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        allHidden ? Localization.get('showAll') : Localization.get('hideAll'),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Wireframe toggle all
              GestureDetector(
                onTap: allWireframe ? onClearAllWireframes : onWireframeAllMeshes,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: allWireframe ? Colors.green.shade100 : Colors.grey.shade200,
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
                        allWireframe ? Localization.get('wireframeOff') : Localization.get('wireframeOn'),
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
              onTap: () => js.highlightMesh(name.toJS),
              onLongPress: () => onMeshFocusChanged(name),
              hoverColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: isFocused
                    ? BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      )
                    : null,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    // Visibility toggle
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onMeshVisibilityChanged(name),
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
                      onTap: () => onMeshWireframeChanged(name),
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
      ],
    );
  }
}
