import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/bridge/fullscreen_bridge.dart';
import 'package:vrm_polygon_checker/localization.dart';
import 'package:vrm_polygon_checker/widgets/settings_panel/fullscreen_button.dart';

/// Stands in for the browser. [fullscreen] can be flipped from the test to act
/// out a change the app did not initiate, such as the user pressing Esc.
class FakeFullscreenBridge implements FullscreenBridge {
  FakeFullscreenBridge({this.fullscreen = false});

  bool fullscreen;
  int toggleCount = 0;
  int listenerCount = 0;

  final List<VoidCallback> _listeners = [];

  @override
  bool isFullscreen() => fullscreen;

  @override
  void toggle() {
    toggleCount++;
    fullscreen = !fullscreen;
  }

  @override
  VoidCallback onChange(VoidCallback listener) {
    listenerCount++;
    _listeners.add(listener);
    return () {
      listenerCount--;
      _listeners.remove(listener);
    };
  }

  /// Acts out Esc / F11: change the state behind the app's back and notify.
  void changeExternally({required bool toFullscreen}) {
    fullscreen = toFullscreen;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

Widget _wrap(FakeFullscreenBridge bridge) =>
    MaterialApp(home: Scaffold(body: FullscreenButton(bridge: bridge)));

void main() {
  // Localization.load() reads the language files through rootBundle.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FullscreenButton', () {
    testWidgets('starts from the browser state', (tester) async {
      await tester.pumpWidget(_wrap(FakeFullscreenBridge(fullscreen: true)));

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(find.byIcon(Icons.fullscreen), findsNothing);
    });

    testWidgets('toggles and reflects the new state', (tester) async {
      final bridge = FakeFullscreenBridge();
      await tester.pumpWidget(_wrap(bridge));
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();

      expect(bridge.toggleCount, 1);
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
    });

    testWidgets('follows a change it did not initiate', (tester) async {
      final bridge = FakeFullscreenBridge();
      await tester.pumpWidget(_wrap(bridge));
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);

      // As if the user pressed F11.
      bridge.changeExternally(toFullscreen: true);
      await tester.pump();

      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      expect(bridge.toggleCount, 0);
    });

    testWidgets('stops listening once it leaves the tree', (tester) async {
      final bridge = FakeFullscreenBridge();
      await tester.pumpWidget(_wrap(bridge));
      expect(bridge.listenerCount, 1);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(bridge.listenerCount, 0);
    });

    testWidgets('relabels itself when the language changes', (tester) async {
      // Regression test: the button used to be built as a const widget, so
      // Flutter skipped rebuilding it and the label kept the wording of
      // whichever language happened to load first.
      final bridge = FakeFullscreenBridge();

      await Localization.load(AppLanguage.ja);
      await tester.pumpWidget(_wrap(bridge));
      expect(find.text('最大化'), findsOneWidget);

      await Localization.load(AppLanguage.en);
      await tester.pumpWidget(_wrap(bridge));

      expect(find.text('Fullscreen'), findsOneWidget);
      expect(find.text('最大化'), findsNothing);
    });

    testWidgets('uses the exit wording while fullscreen', (tester) async {
      await Localization.load(AppLanguage.en);

      await tester.pumpWidget(_wrap(FakeFullscreenBridge(fullscreen: true)));

      expect(find.text('Exit Fullscreen'), findsOneWidget);
    });
  });
}
