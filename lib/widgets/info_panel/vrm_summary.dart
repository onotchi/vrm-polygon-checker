import 'package:flutter/material.dart';
import '../../localization.dart';

/// File name, VRM version badge and the basic info table for the loaded model.
///
/// [hiddenMeshes] is needed because the table reports the visible triangle
/// count alongside the total.
class VrmSummary extends StatelessWidget {
  const VrmSummary({
    super.key,
    required this.vrmInfo,
    required this.hiddenMeshes,
  });

  final Map<String, dynamic> vrmInfo;
  final Set<String> hiddenMeshes;

  /// One label/value line. [labelKey] doubles as the localization key and as a
  /// stable identity for the row, so tests can address a value without relying
  /// on the surrounding layout.
  Widget _infoRow(String labelKey, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        key: ValueKey('vrm-summary-$labelKey'),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            Localization.get(labelKey),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildBasicInfo(BuildContext context) {
    // Calculate visible triangles from mesh details
    final meshDetails = vrmInfo['meshDetails'] as List<dynamic>?;
    int visibleTriangles = 0;
    if (meshDetails != null) {
      for (final mesh in meshDetails) {
        final name = mesh['name'] as String;
        if (!hiddenMeshes.contains(name)) {
          visibleTriangles += mesh['triangles'] as int;
        }
      }
    }
    final totalTriangles = vrmInfo['triangleCount'] as int;

    return ExpansionTile(
      title: Text(
        Localization.get('basicInfo'),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      initiallyExpanded: true,
      children: [
        _infoRow('name', vrmInfo['name']),
        _infoRow('author', vrmInfo['author']),
        const Divider(),
        _infoRow('vertices', '${vrmInfo['vertexCount']}'),
        _infoRow('triangles', '$totalTriangles'),
        _infoRow('trianglesVisible', '$visibleTriangles'),
        _infoRow('meshes', '${vrmInfo['meshCount']}'),
        const Divider(),
        _infoRow('bones', '${vrmInfo['boneCount']}'),
        _infoRow('materials', '${vrmInfo['materialCount']}'),
        _infoRow('textures', '${vrmInfo['textureCount']}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fileName = vrmInfo['fileName'] as String?;

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
                  'VRM ${vrmInfo['vrmVersion'] ?? '?'}',
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
      ],
    );
  }
}
