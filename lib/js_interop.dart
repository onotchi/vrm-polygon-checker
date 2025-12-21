import 'dart:js_interop';

// File picker
@JS('openFilePicker')
external void openFilePicker();

@JS('openVRMAPicker')
external void openVRMAPicker();

// Animation
@JS('stopAnimation')
external JSString stopAnimation();

// Expression
@JS('setExpression')
external JSString setExpression(JSString expressionName, JSNumber value);

@JS('resetExpressions')
external JSString resetExpressions();

// Pointer events
@JS('onPointerDown')
external void onPointerDown(JSNumber x, JSNumber y, JSNumber button);

@JS('onPointerMove')
external void onPointerMove(JSNumber x, JSNumber y);

@JS('onPointerUp')
external void onPointerUp();

@JS('onWheel')
external void onWheel(JSNumber deltaY);

// Lighting
@JS('setLightIntensity')
external void setLightIntensity(JSNumber ambient, JSNumber directional);

// Mesh
@JS('setMeshVisibility')
external JSString setMeshVisibility(JSString meshName, JSBoolean visible);

@JS('focusMesh')
external JSString focusMesh(JSString meshName);

@JS('showAllMeshes')
external JSString showAllMeshes();

@JS('showWireframe')
external JSString showWireframe(JSString meshName);

@JS('clearWireframe')
external JSString clearWireframe(JSString meshName);

@JS('highlightMesh')
external JSString highlightMesh(JSString meshName);

// Display settings
@JS('setGridVisible')
external JSString setGridVisible(JSBoolean visible);

@JS('setShadowVisible')
external JSString setShadowVisible(JSBoolean visible);

@JS('setBackgroundColor')
external JSString setBackgroundColor(JSNumber r, JSNumber g, JSNumber b);

// Callback setters
@JS('onVRMLoaded')
external set onVRMLoadedCallback(JSFunction? callback);

@JS('onVRMALoaded')
external set onVRMALoadedCallback(JSFunction? callback);

@JS('onVRMLoadCancelled')
external set onVRMLoadCancelledCallback(JSFunction? callback);

@JS('onVRMALoadCancelled')
external set onVRMALoadCancelledCallback(JSFunction? callback);
