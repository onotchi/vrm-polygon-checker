import 'package:flutter/material.dart';
import '../localization.dart';
import 'info_panel/animation_controls.dart';
import 'info_panel/expression_controls.dart';
import 'info_panel/mesh_inspector.dart';

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
  final ValueChanged<String?> onExpressionSelected;
  final VoidCallback onExpressionReset;
  final ValueChanged<String> onMeshVisibilityChanged;
  final ValueChanged<String> onMeshFocusChanged;
  final ValueChanged<String> onMeshWireframeChanged;
  final ValueChanged<String> onMeshHighlight;
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
    required this.onExpressionSelected,
    required this.onExpressionReset,
    required this.onMeshVisibilityChanged,
    required this.onMeshFocusChanged,
    required this.onMeshWireframeChanged,
    required this.onMeshHighlight,
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
                        if (animationInfo != null)
                          AnimationControls(
                            animationInfo: animationInfo!,
                            onStop: onStopAnimation,
                          ),
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
          MeshInspector(
            meshDetails: meshDetails,
            hiddenMeshes: hiddenMeshes,
            wireframeMeshes: wireframeMeshes,
            focusedMesh: focusedMesh,
            sortKey: meshSortKey,
            sortAscending: meshSortAscending,
            onSortChanged: onSortChanged,
            onSortReset: onSortReset,
            onVisibilityChanged: onMeshVisibilityChanged,
            onFocusChanged: onMeshFocusChanged,
            onWireframeChanged: onMeshWireframeChanged,
            onHighlight: onMeshHighlight,
            onShowAll: onShowAllMeshes,
            onHideAll: onHideAllMeshes,
            onWireframeAll: onWireframeAllMeshes,
            onClearAllWireframes: onClearAllWireframes,
          ),
        ],
        const Divider(),
        ExpressionControls(
          clips: vrmInfo!['blendShapeClips'] as List<dynamic>?,
          activeExpression: activeExpression,
          onSelected: onExpressionSelected,
          onReset: onExpressionReset,
        ),
      ],
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    // Calculate visible triangles from mesh details
    final meshDetails = vrmInfo!['meshDetails'] as List<dynamic>?;
    int visibleTriangles = 0;
    if (meshDetails != null) {
      for (final mesh in meshDetails) {
        final name = mesh['name'] as String;
        if (!hiddenMeshes.contains(name)) {
          visibleTriangles += mesh['triangles'] as int;
        }
      }
    }
    final totalTriangles = vrmInfo!['triangleCount'] as int;

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
        _infoRow(Localization.get('triangles'), '$totalTriangles'),
        _infoRow(Localization.get('trianglesVisible'), '$visibleTriangles'),
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

}
