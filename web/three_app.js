import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { VRMLoaderPlugin } from '@pixiv/three-vrm';
import { VRMAnimationLoaderPlugin, createVRMAnimationClip } from '@pixiv/three-vrm-animation';

// Panel widths for Flutter UI
const LEFT_PANEL_WIDTH = 200;
const RIGHT_PANEL_WIDTH = 320;

// Calculate canvas size
function getCanvasSize() {
  return {
    width: window.innerWidth - LEFT_PANEL_WIDTH - RIGHT_PANEL_WIDTH,
    height: window.innerHeight
  };
}

// Three.js setup
const canvas = document.getElementById('three-canvas');
const renderer = new THREE.WebGLRenderer({ canvas, alpha: false });
const size = getCanvasSize();
renderer.setSize(size.width, size.height);
renderer.setPixelRatio(window.devicePixelRatio);
renderer.setClearColor(0xffffff, 1); // Default white background

const scene = new THREE.Scene();
scene.background = new THREE.Color(0xffffff);
const camera = new THREE.PerspectiveCamera(45, size.width / size.height, 0.1, 1000);
camera.position.set(0, 1, 3);

// Orbit controls
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 1, 0);
controls.update();

// Lighting
const ambientLight = new THREE.AmbientLight(0xffffff, 2.0);
scene.add(ambientLight);

const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
directionalLight.position.set(1, 1, 1);
scene.add(directionalLight);

// Grid helper
const gridHelper = new THREE.GridHelper(10, 20, 0x888888, 0xcccccc);
gridHelper.position.y = 0;
scene.add(gridHelper);

// Circle shadow under avatar (with gradient fade)
const shadowCanvas = document.createElement('canvas');
shadowCanvas.width = 64;
shadowCanvas.height = 64;
const shadowCtx = shadowCanvas.getContext('2d');
const gradient = shadowCtx.createRadialGradient(32, 32, 0, 32, 32, 32);
gradient.addColorStop(0, 'rgba(0, 0, 0, 0.4)');
gradient.addColorStop(0.5, 'rgba(0, 0, 0, 0.2)');
gradient.addColorStop(1, 'rgba(0, 0, 0, 0)');
shadowCtx.fillStyle = gradient;
shadowCtx.fillRect(0, 0, 64, 64);

const shadowTexture = new THREE.CanvasTexture(shadowCanvas);
const shadowGeometry = new THREE.PlaneGeometry(0.8, 0.8);
const shadowMaterial = new THREE.MeshBasicMaterial({
  map: shadowTexture,
  transparent: true,
  depthWrite: false,
});
const shadowMesh = new THREE.Mesh(shadowGeometry, shadowMaterial);
shadowMesh.rotation.x = -Math.PI / 2;
shadowMesh.position.y = 0.001;
shadowMesh.visible = false; // Hidden until VRM is loaded
scene.add(shadowMesh);

// VRM loader setup
const loader = new GLTFLoader();
loader.register((parser) => new VRMLoaderPlugin(parser));

// Current VRM model
let currentVRM = null;

// Animation state
let clock = new THREE.Clock();
let currentMixer = null;
let currentAction = null;

// VRMA loader setup
const vrmaLoader = new GLTFLoader();
vrmaLoader.register((parser) => new VRMAnimationLoaderPlugin(parser));

// Load VRM from URL (will be called from Flutter)
window.loadVRM = async function(url) {
  try {
    const gltf = await loader.loadAsync(url);
    return setupVRM(gltf);
  } catch (e) {
    console.error('VRM load error:', e);
    return JSON.stringify({ error: e.message });
  }
};

// Load VRM from ArrayBuffer (for local files)
window.loadVRMFromBuffer = async function(arrayBuffer, fileName) {
  try {
    const gltf = await new Promise((resolve, reject) => {
      loader.parse(arrayBuffer, '', resolve, reject);
    });
    return setupVRM(gltf, fileName);
  } catch (e) {
    console.error('VRM load error:', e);
    return JSON.stringify({ error: e.message });
  }
};

// Common VRM setup
function setupVRM(gltf, fileName = null) {
  const vrm = gltf.userData.vrm;

  if (currentVRM) {
    scene.remove(currentVRM.scene);
  }

  currentVRM = vrm;
  scene.add(vrm.scene);

  // Show shadow when VRM is loaded
  shadowMesh.visible = true;

  // Rotate VRM to face camera (VRM default is facing -Z, we want +Z)
  vrm.scene.rotation.y = Math.PI;

  // Debug: Log humanoid structure
  console.log('VRM loaded:', vrm);
  console.log('Humanoid:', vrm.humanoid);
  if (vrm.humanoid) {
    console.log('HumanBones:', vrm.humanoid.humanBones);
    console.log('Has getRawBoneNode:', typeof vrm.humanoid.getRawBoneNode);
    console.log('Has getNormalizedBoneNode:', typeof vrm.humanoid.getNormalizedBoneNode);
    // Try to get a bone
    if (vrm.humanoid.humanBones) {
      console.log('Spine bone:', vrm.humanoid.humanBones.spine);
    }
  }

  // Reset camera position
  controls.target.set(0, 1, 0);
  camera.position.set(0, 1, 3);
  controls.update();

  // Get model info
  const info = getVRMInfo(vrm, gltf, fileName);
  return JSON.stringify(info);
}

// Open file picker dialog
window.openFilePicker = function() {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.vrm';
  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      const arrayBuffer = await file.arrayBuffer();
      const result = await window.loadVRMFromBuffer(arrayBuffer, file.name);
      // Notify Flutter about the loaded file
      if (window.onVRMLoaded) {
        window.onVRMLoaded(result);
      }
    }
  };
  // Handle cancel
  input.oncancel = () => {
    if (window.onVRMLoadCancelled) {
      window.onVRMLoadCancelled();
    }
  };
  input.click();
};

// Get VRM info
function getVRMInfo(vrm, gltf, fileName = null) {
  let totalVertices = 0;
  let totalTriangles = 0;
  const meshDetails = [];

  gltf.scene.traverse((object) => {
    if (object.isMesh) {
      const geometry = object.geometry;
      const vertices = geometry.attributes.position?.count || 0;
      const triangles = geometry.index ? Math.floor(geometry.index.count / 3) : 0;

      // Count materials for this mesh
      let materialCount = 1;
      if (Array.isArray(object.material)) {
        materialCount = object.material.length;
      }

      meshDetails.push({
        name: object.name || `Mesh ${meshDetails.length + 1}`,
        vertices: vertices,
        triangles: triangles,
        materials: materialCount,
      });

      totalVertices += vertices;
      totalTriangles += triangles;
    }
  });

  const meta = vrm.meta;

  // Debug: Log meta structure
  console.log('VRM Meta:', meta);

  // VRM 0.x uses 'title' and 'author', VRM 1.0 uses 'name' and 'authors'
  const name = meta?.name || meta?.title || 'Unknown';
  const author = meta?.authors?.[0] || meta?.author || 'Unknown';

  // Detect VRM version (0.x or 1.0)
  // metaVersion: "0" = VRM 0.x, "1" = VRM 1.0
  let vrmVersion = 'Unknown';
  if (meta?.metaVersion === '0') {
    vrmVersion = '0.x';
  } else if (meta?.metaVersion === '1') {
    vrmVersion = '1.0';
  }

  return {
    // File info
    fileName: fileName || null,
    vrmVersion: vrmVersion,

    // VRM Meta info
    name: name,
    author: author,

    // Mesh info
    meshCount: meshDetails.length,
    vertexCount: totalVertices,
    triangleCount: Math.floor(totalTriangles),
    meshDetails: meshDetails,

    // Bone info
    boneCount: vrm.humanoid?.humanBones ? Object.keys(vrm.humanoid.humanBones).length : 0,

    // Material info
    materialCount: gltf.parser?.json?.materials?.length || 0,

    // Texture info
    textureCount: gltf.parser?.json?.textures?.length || 0,

    // BlendShape/Expression info
    blendShapeClips: getBlendShapeClips(vrm),
  };
}

// Get BlendShape/Expression clips from VRM
function getBlendShapeClips(vrm) {
  // VRM 1.0 uses expressionManager
  if (vrm.expressionManager) {
    const expressions = vrm.expressionManager.expressions || [];
    return expressions.map(expr => expr.expressionName).filter(name => name);
  }
  // VRM 0.x uses blendShapeProxy
  if (vrm.blendShapeProxy) {
    const blendShapeGroups = vrm.blendShapeProxy.blendShapeGroups || [];
    return blendShapeGroups.map(group => group.name).filter(name => name);
  }
  return [];
}

// Set expression value (0.0 - 1.0)
window.setExpression = function(expressionName, value) {
  if (!currentVRM) {
    return JSON.stringify({ error: 'No VRM loaded.' });
  }

  try {
    // VRM 1.0
    if (currentVRM.expressionManager) {
      currentVRM.expressionManager.setValue(expressionName, value);
      return JSON.stringify({ success: true, expression: expressionName, value: value });
    }
    // VRM 0.x
    if (currentVRM.blendShapeProxy) {
      currentVRM.blendShapeProxy.setValue(expressionName, value);
      return JSON.stringify({ success: true, expression: expressionName, value: value });
    }
    return JSON.stringify({ error: 'No expression manager found.' });
  } catch (e) {
    console.error('Expression error:', e);
    return JSON.stringify({ error: e.message });
  }
};

// Reset all expressions to 0
window.resetExpressions = function() {
  if (!currentVRM) {
    return JSON.stringify({ error: 'No VRM loaded.' });
  }

  try {
    const clips = getBlendShapeClips(currentVRM);
    clips.forEach(name => {
      if (currentVRM.expressionManager) {
        currentVRM.expressionManager.setValue(name, 0);
      } else if (currentVRM.blendShapeProxy) {
        currentVRM.blendShapeProxy.setValue(name, 0);
      }
    });
    return JSON.stringify({ success: true });
  } catch (e) {
    console.error('Reset expressions error:', e);
    return JSON.stringify({ error: e.message });
  }
};


// Animation loop
function animate() {
  requestAnimationFrame(animate);

  const deltaTime = clock.getDelta();

  // Update VRM
  if (currentVRM) {
    // Update animation mixer
    if (currentMixer) {
      currentMixer.update(deltaTime);
    }

    // Update VRM (SpringBone, etc.)
    currentVRM.update(deltaTime);

    // Update shadow position to follow avatar's hips
    const hips = currentVRM.humanoid?.getRawBoneNode('hips');
    if (hips) {
      const worldPos = new THREE.Vector3();
      hips.getWorldPosition(worldPos);
      shadowMesh.position.x = worldPos.x;
      shadowMesh.position.z = worldPos.z;
    }
  }

  controls.update();
  renderer.render(scene, camera);
}
animate();

// Handle resize
window.addEventListener('resize', () => {
  const size = getCanvasSize();
  camera.aspect = size.width / size.height;
  camera.updateProjectionMatrix();
  renderer.setSize(size.width, size.height);
});

// Pointer event handlers for Flutter
let isPointerDown = false;
let lastPointerX = 0;
let lastPointerY = 0;

window.onPointerDown = function(x, y, buttons) {
  isPointerDown = true;
  lastPointerX = x;
  lastPointerY = y;

  // Simulate pointer event for OrbitControls
  const event = new PointerEvent('pointerdown', {
    clientX: x,
    clientY: y,
    button: (buttons & 1) ? 0 : ((buttons & 2) ? 2 : 1),
    buttons: buttons,
    pointerId: 1,
    pointerType: 'mouse'
  });
  canvas.dispatchEvent(event);
};

window.onPointerMove = function(x, y) {
  lastPointerX = x;
  lastPointerY = y;

  const event = new PointerEvent('pointermove', {
    clientX: x,
    clientY: y,
    buttons: isPointerDown ? 1 : 0,
    pointerId: 1,
    pointerType: 'mouse'
  });
  canvas.dispatchEvent(event);
};

window.onPointerUp = function() {
  isPointerDown = false;

  const event = new PointerEvent('pointerup', {
    clientX: lastPointerX,
    clientY: lastPointerY,
    button: 0,
    buttons: 0,
    pointerId: 1,
    pointerType: 'mouse'
  });
  canvas.dispatchEvent(event);
};

window.onWheel = function(deltaY) {
  const event = new WheelEvent('wheel', {
    clientX: lastPointerX,
    clientY: lastPointerY,
    deltaY: deltaY,
    deltaMode: 0
  });
  canvas.dispatchEvent(event);
};

// Drag and drop support
document.addEventListener('dragover', (e) => {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'copy';
});

document.addEventListener('drop', async (e) => {
  e.preventDefault();
  const file = e.dataTransfer.files[0];
  if (file && file.name.endsWith('.vrm')) {
    const arrayBuffer = await file.arrayBuffer();
    const result = await window.loadVRMFromBuffer(arrayBuffer, file.name);
    if (window.onVRMLoaded) {
      window.onVRMLoaded(result);
    }
  }
});

// Light intensity control
window.setLightIntensity = function(ambient, directional) {
  ambientLight.intensity = ambient;
  directionalLight.intensity = directional;
};

// Load VRMA from ArrayBuffer
window.loadVRMAFromBuffer = async function(arrayBuffer, fileName) {
  if (!currentVRM) {
    return JSON.stringify({ error: 'No VRM loaded. Please load a VRM first.' });
  }

  try {
    const gltf = await new Promise((resolve, reject) => {
      vrmaLoader.parse(arrayBuffer, '', resolve, reject);
    });

    const vrmAnimation = gltf.userData.vrmAnimations?.[0];
    if (!vrmAnimation) {
      return JSON.stringify({ error: 'No VRM animation found in file.' });
    }

    // Stop current animation if any
    if (currentAction) {
      currentAction.stop();
    }

    // Create animation clip for the current VRM
    const clip = createVRMAnimationClip(vrmAnimation, currentVRM);

    // Create mixer and play animation
    currentMixer = new THREE.AnimationMixer(currentVRM.scene);
    currentAction = currentMixer.clipAction(clip);
    currentAction.play();

    console.log('VRMA loaded:', fileName);

    return JSON.stringify({
      success: true,
      fileName: fileName,
      duration: clip.duration,
      trackCount: clip.tracks.length
    });
  } catch (e) {
    console.error('VRMA load error:', e);
    return JSON.stringify({ error: e.message });
  }
};

// Stop current animation
window.stopAnimation = function() {
  if (currentAction) {
    currentAction.stop();
    currentAction = null;
  }
  if (currentMixer) {
    currentMixer = null;
  }
  return JSON.stringify({ success: true });
};

// Open VRMA file picker
window.openVRMAPicker = function() {
  const input = document.createElement('input');
  input.type = 'file';
  input.accept = '.vrma';
  input.onchange = async (e) => {
    const file = e.target.files[0];
    if (file) {
      const arrayBuffer = await file.arrayBuffer();
      const result = await window.loadVRMAFromBuffer(arrayBuffer, file.name);
      if (window.onVRMALoaded) {
        window.onVRMALoaded(result);
      }
    }
  };
  // Handle cancel
  input.oncancel = () => {
    if (window.onVRMALoadCancelled) {
      window.onVRMALoadCancelled();
    }
  };
  input.click();
};

window.getLightIntensity = function() {
  return JSON.stringify({
    ambient: ambientLight.intensity,
    directional: directionalLight.intensity
  });
};

// Grid and shadow visibility controls
window.setGridVisible = function(visible) {
  gridHelper.visible = visible;
  return JSON.stringify({ success: true, visible: visible });
};

window.setShadowVisible = function(visible) {
  shadowMesh.visible = visible && currentVRM !== null;
  return JSON.stringify({ success: true, visible: visible });
};

// Background color control
window.setBackgroundColor = function(r, g, b) {
  const color = new THREE.Color(r / 255, g / 255, b / 255);
  scene.background = color;
  renderer.setClearColor(color, 1);
  return JSON.stringify({ success: true, r: r, g: g, b: b });
};

// Mesh highlight state
let highlightedMesh = null;
let originalMaterials = new Map();

// Highlight a specific mesh by name
window.highlightMesh = function(meshName) {
  // Clear previous highlight
  window.clearMeshHighlight();

  if (!currentVRM) {
    return JSON.stringify({ error: 'No VRM loaded.' });
  }

  // Find the mesh
  currentVRM.scene.traverse((object) => {
    if (object.isMesh && object.name === meshName) {
      highlightedMesh = object;

      // Store original materials and apply highlight
      if (Array.isArray(object.material)) {
        originalMaterials.set(object, object.material.map(m => m.clone()));
        object.material.forEach(m => {
          m.emissive = new THREE.Color(0x4488ff);
          m.emissiveIntensity = 0.3;
        });
      } else {
        originalMaterials.set(object, object.material.clone());
        object.material.emissive = new THREE.Color(0x4488ff);
        object.material.emissiveIntensity = 0.3;
      }
    }
  });

  if (highlightedMesh) {
    return JSON.stringify({ success: true, mesh: meshName });
  }
  return JSON.stringify({ error: 'Mesh not found: ' + meshName });
};

// Clear mesh highlight
window.clearMeshHighlight = function() {
  if (highlightedMesh && originalMaterials.has(highlightedMesh)) {
    const original = originalMaterials.get(highlightedMesh);
    if (Array.isArray(highlightedMesh.material)) {
      highlightedMesh.material.forEach((m, i) => {
        m.emissive = original[i].emissive;
        m.emissiveIntensity = original[i].emissiveIntensity;
      });
    } else {
      highlightedMesh.material.emissive = original.emissive;
      highlightedMesh.material.emissiveIntensity = original.emissiveIntensity;
    }
    originalMaterials.delete(highlightedMesh);
    highlightedMesh = null;
  }
  return JSON.stringify({ success: true });
};

// Set mesh visibility
window.setMeshVisibility = function(meshName, visible) {
  if (!currentVRM) {
    return JSON.stringify({ error: 'No VRM loaded.' });
  }

  let found = false;
  currentVRM.scene.traverse((object) => {
    if (object.isMesh && object.name === meshName) {
      object.visible = visible;
      found = true;
    }
  });

  if (found) {
    return JSON.stringify({ success: true, mesh: meshName, visible: visible });
  }
  return JSON.stringify({ error: 'Mesh not found: ' + meshName });
};

console.log('Three.js app initialized!');
