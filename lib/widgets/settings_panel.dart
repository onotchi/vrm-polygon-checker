import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import '../localization.dart';
import '../js_interop.dart' as js;
import '../constants.dart';

class SettingsPanel extends StatelessWidget {
  final double ambientIntensity;
  final double directionalIntensity;
  final bool gridVisible;
  final bool shadowVisible;
  final Color backgroundColor;
  final bool antialiasEnabled;
  final double cameraFov;
  final ValueChanged<double> onAmbientChanged;
  final ValueChanged<double> onDirectionalChanged;
  final ValueChanged<double> onCameraFovChanged;
  final ValueChanged<bool> onGridVisibleChanged;
  final ValueChanged<bool> onShadowVisibleChanged;
  final ValueChanged<Color> onBackgroundColorChanged;
  final ValueChanged<bool> onAntialiasChanged;
  final VoidCallback onLanguageChanged;
  final VoidCallback onHidePanels;

  const SettingsPanel({
    super.key,
    required this.ambientIntensity,
    required this.directionalIntensity,
    required this.gridVisible,
    required this.shadowVisible,
    required this.backgroundColor,
    required this.antialiasEnabled,
    required this.cameraFov,
    required this.onAmbientChanged,
    required this.onDirectionalChanged,
    required this.onCameraFovChanged,
    required this.onGridVisibleChanged,
    required this.onShadowVisibleChanged,
    required this.onBackgroundColorChanged,
    required this.onAntialiasChanged,
    required this.onLanguageChanged,
    required this.onHidePanels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.inversePrimary,
            child: Text(
              Localization.get('settings'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          // Controls
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLightingSection(context),
                const SizedBox(height: 16),
                _buildDisplaySection(context),
                const SizedBox(height: 16),
                _buildLanguageSection(context),
              ],
            ),
          ),
          const Spacer(),
          // Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v$appVersion',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: () {
                    web.window.open('https://x.com/onotchi_', '_blank');
                  },
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      'Produced By オノッチ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLightingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localization.get('lighting'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(Localization.get('ambient'), style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: ambientIntensity,
                min: 0,
                max: 2,
                onChanged: (value) {
                  onAmbientChanged(value);
                  js.setLightIntensity(value.toJS, directionalIntensity.toJS);
                },
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                ambientIntensity.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        Text(Localization.get('direct'), style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: directionalIntensity,
                min: 0,
                max: 3,
                onChanged: (value) {
                  onDirectionalChanged(value);
                  js.setLightIntensity(ambientIntensity.toJS, value.toJS);
                },
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                directionalIntensity.toStringAsFixed(1),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDisplaySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localization.get('display'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(Localization.get('fov'), style: const TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: cameraFov,
                min: 10,
                max: 120,
                divisions: 22,
                onChanged: (value) {
                  onCameraFovChanged(value);
                  js.setCameraFov(value.toJS);
                },
              ),
            ),
            SizedBox(
              width: 32,
              child: Text(
                '${cameraFov.round()}°',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Localization.get('grid'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: gridVisible,
              onChanged: (value) {
                onGridVisibleChanged(value);
                js.setGridVisible(value.toJS);
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Localization.get('shadow'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: shadowVisible,
              onChanged: (value) {
                onShadowVisibleChanged(value);
                js.setShadowVisible(value.toJS);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(Localization.get('background'), style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildColorButton(context, const Color(0xFFFFFFFF)),
            _buildColorButton(context, const Color(0xFF000000)),
            _buildColorButton(context, const Color(0xFF87CEEB)),
            _buildColorButton(context, const Color(0xFF90EE90)),
            _buildColorButton(context, const Color(0xFFFFF9C4)),
            _buildColorButton(context, const Color(0xFFFFCDD2)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Localization.get('antialias'), style: const TextStyle(fontSize: 12)),
            Switch(
              value: antialiasEnabled,
              onChanged: (value) {
                onAntialiasChanged(value);
                js.setAntialias(value.toJS);
              },
            ),
          ],
        ),
        const SizedBox(height: 4),
        const _FullscreenButton(),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onHidePanels,
            icon: const Icon(Icons.visibility_off, size: 18),
            label: Text(
              Localization.get('hidePanels'),
              style: const TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localization.get('language'),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildLanguageButton(context, 'JA', AppLanguage.ja),
            const SizedBox(width: 8),
            _buildLanguageButton(context, 'EN', AppLanguage.en),
          ],
        ),
      ],
    );
  }

  Widget _buildColorButton(BuildContext context, Color color) {
    final isSelected = backgroundColor == color;
    return GestureDetector(
      onTap: () {
        onBackgroundColorChanged(color);
        js.setBackgroundColor(
          ((color.r * 255).round()).toJS,
          ((color.g * 255).round()).toJS,
          ((color.b * 255).round()).toJS,
        );
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildLanguageButton(BuildContext context, String label, AppLanguage language) {
    final isSelected = Localization.currentLanguage == language;
    return GestureDetector(
      onTap: () async {
        await Localization.load(language);
        onLanguageChanged();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

/// Fullscreen toggle. Keeps its own state so it stays in sync when the user
/// leaves fullscreen by pressing Esc or the browser's own shortcut.
class _FullscreenButton extends StatefulWidget {
  const _FullscreenButton();

  @override
  State<_FullscreenButton> createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<_FullscreenButton> {
  bool _isFullscreen = false;
  late final JSFunction _changeListener;

  @override
  void initState() {
    super.initState();
    _changeListener = ((web.Event event) => _syncState()).toJS;
    web.document.addEventListener('fullscreenchange', _changeListener);
    web.document.addEventListener('webkitfullscreenchange', _changeListener);
    _syncState();
  }

  @override
  void dispose() {
    web.document.removeEventListener('fullscreenchange', _changeListener);
    web.document.removeEventListener('webkitfullscreenchange', _changeListener);
    super.dispose();
  }

  void _syncState() {
    final result = jsonDecode(js.isFullscreen().toDart) as Map<String, dynamic>;
    final value = result['fullscreen'] == true;
    if (value != _isFullscreen) {
      setState(() => _isFullscreen = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          js.toggleFullscreen();
          _syncState();
        },
        icon: Icon(
          _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
          size: 18,
        ),
        label: Text(
          Localization.get(_isFullscreen ? 'exitFullscreen' : 'fullscreen'),
          style: const TextStyle(fontSize: 12),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}
