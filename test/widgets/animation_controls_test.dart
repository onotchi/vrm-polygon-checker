import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrm_polygon_checker/bridge/animation_bridge.dart';
import 'package:vrm_polygon_checker/widgets/info_panel/animation_controls.dart';

/// Stands in for the viewer: answers with whatever the test sets up, and
/// records what was asked of it.
class FakeAnimationBridge implements AnimationBridge {
  FakeAnimationBridge({this.duration = 10, this.paused = false});

  double duration;
  double currentTime = 0;
  bool paused;

  final List<String> calls = [];
  final List<double> seeks = [];

  @override
  double getDuration() => duration;

  @override
  double getCurrentTime() => currentTime;

  @override
  bool isPaused() => paused;

  @override
  void seek(double seconds) {
    calls.add('seek');
    seeks.add(seconds);
    currentTime = seconds;
  }

  @override
  void pause() {
    calls.add('pause');
    paused = true;
  }

  @override
  void resume() {
    calls.add('resume');
    paused = false;
  }

  // The viewer moves the playhead one frame and pauses, so the fake does too:
  // a step that only recorded the call would let a test pass that the real
  // bridge would fail.
  static const _frame = 1 / 60;

  @override
  void stepForward() {
    calls.add('stepForward');
    currentTime = (currentTime + _frame).clamp(0, duration);
    paused = true;
  }

  @override
  void stepBackward() {
    calls.add('stepBackward');
    currentTime = (currentTime - _frame).clamp(0, duration);
    paused = true;
  }

  @override
  void stop() {
    calls.add('stop');
    duration = 0;
    currentTime = 0;
    paused = false;
  }
}

Widget _wrap(
  FakeAnimationBridge bridge, {
  VoidCallback? onStop,
  Map<String, dynamic>? animationInfo,
}) {
  return MaterialApp(
    home: Scaffold(
      body: AnimationControls(
        animationInfo: animationInfo ?? const {'fileName': 'walk.vrma'},
        onStop: onStop ?? () {},
        bridge: bridge,
      ),
    ),
  );
}

void main() {
  group('AnimationControls', () {
    testWidgets('shows the loaded file name', (tester) async {
      await tester.pumpWidget(_wrap(FakeAnimationBridge()));

      expect(find.text('walk.vrma'), findsOneWidget);
    });

    testWidgets('reports the stop button', (tester) async {
      var stops = 0;
      await tester.pumpWidget(
        _wrap(FakeAnimationBridge(), onStop: () => stops++),
      );

      await tester.tap(find.byIcon(Icons.stop));
      expect(stops, 1);
    });

    testWidgets('hides the seek bar when nothing is playing', (tester) async {
      await tester.pumpWidget(_wrap(FakeAnimationBridge(duration: 0)));

      expect(find.byType(Slider), findsNothing);
    });

    testWidgets('shows the seek bar once a clip is loaded', (tester) async {
      await tester.pumpWidget(_wrap(FakeAnimationBridge(duration: 12)));

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.max, 12);
    });

    testWidgets('takes the clip length from the bridge on the first build', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(FakeAnimationBridge(duration: 90)));

      // 90 seconds formatted as minutes:seconds
      expect(find.text('1:30.0'), findsOneWidget);
    });

    testWidgets('pauses a playing clip and resumes a paused one', (
      tester,
    ) async {
      final bridge = FakeAnimationBridge(paused: false);
      await tester.pumpWidget(_wrap(bridge));

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(bridge.calls, ['pause']);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(bridge.calls, ['pause', 'resume']);
    });

    testWidgets('starts on the paused icon when the clip is already paused', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(FakeAnimationBridge(paused: true)));

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('steps forward and back a frame', (tester) async {
      final bridge = FakeAnimationBridge();
      await tester.pumpWidget(_wrap(bridge));

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.tap(find.byIcon(Icons.skip_previous));

      expect(bridge.calls, ['stepForward', 'stepBackward']);
    });

    testWidgets('pauses when stepping, so the clip does not run away', (
      tester,
    ) async {
      final bridge = FakeAnimationBridge(paused: false);
      await tester.pumpWidget(_wrap(bridge));
      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump();

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('seeks to the dragged position', (tester) async {
      final bridge = FakeAnimationBridge(duration: 10);
      await tester.pumpWidget(_wrap(bridge));

      // Drag the thumb from the start towards the middle of the track.
      await tester.drag(find.byType(Slider), const Offset(200, 0));
      await tester.pump();

      expect(bridge.seeks, hasLength(1));
      expect(bridge.seeks.single, greaterThan(0));
    });

    testWidgets('moves the playhead one frame when stepping', (tester) async {
      final bridge = FakeAnimationBridge(duration: 10);
      await tester.pumpWidget(_wrap(bridge));

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump(const Duration(milliseconds: 60));

      expect(bridge.currentTime, closeTo(1 / 60, 1e-9));
      expect(find.text('0:00.0'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('does not step back past the start', (tester) async {
      final bridge = FakeAnimationBridge(duration: 10);
      await tester.pumpWidget(_wrap(bridge));

      await tester.tap(find.byIcon(Icons.skip_previous));
      await tester.pump();

      expect(bridge.currentTime, 0);
    });

    testWidgets('starts a new session over when a new clip map arrives', (
      tester,
    ) async {
      // This is what a VRM swap looks like from here: the JS side rebuilds the
      // animation and starts it playing, and main.dart hands over a fresh map
      // so this widget re-reads the state instead of keeping the old one.
      final bridge = FakeAnimationBridge(duration: 10, paused: true);
      await tester.pumpWidget(
        _wrap(bridge, animationInfo: {'fileName': 'walk.vrma'}),
      );
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      bridge.paused = false;
      await tester.pumpWidget(
        _wrap(bridge, animationInfo: {'fileName': 'walk.vrma'}),
      );

      expect(find.byIcon(Icons.pause), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('follows the playhead while the clip runs', (tester) async {
      final bridge = FakeAnimationBridge(duration: 10);
      await tester.pumpWidget(_wrap(bridge));
      expect(find.text('0:00.0'), findsOneWidget);

      bridge.currentTime = 3.5;
      // The seek bar polls every 50ms.
      await tester.pump(const Duration(milliseconds: 60));

      expect(find.text('0:03.5'), findsOneWidget);

      // Leave no timer running when the test ends.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
