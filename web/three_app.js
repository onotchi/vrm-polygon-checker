import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { VRMLoaderPlugin } from '@pixiv/three-vrm';

// Panel width for Flutter UI
const PANEL_WIDTH = 320;

// Calculate canvas size
function getCanvasSize() {
  return {
    width: window.innerWidth - PANEL_WIDTH,
    height: window.innerHeight
  };
}

// Three.js setup
const canvas = document.getElementById('three-canvas');
const renderer = new THREE.WebGLRenderer({ canvas, alpha: true });
const size = getCanvasSize();
renderer.setSize(size.width, size.height);
renderer.setPixelRatio(window.devicePixelRatio);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(45, size.width / size.height, 0.1, 1000);
camera.position.set(0, 1, 3);

// Orbit controls
const controls = new OrbitControls(camera, renderer.domElement);
controls.target.set(0, 1, 0);
controls.update();

// Lighting
const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
scene.add(ambientLight);

const directionalLight = new THREE.DirectionalLight(0xffffff, 1);
directionalLight.position.set(1, 1, 1);
scene.add(directionalLight);

// Demo cube (will be removed when VRM is loaded)
const geometry = new THREE.BoxGeometry(0.5, 0.5, 0.5);
const material = new THREE.MeshStandardMaterial({ color: 0x6699ff });
const cube = new THREE.Mesh(geometry, material);
cube.position.set(0, 1, 0);
scene.add(cube);

// VRM loader setup
const loader = new GLTFLoader();
loader.register((parser) => new VRMLoaderPlugin(parser));

// Current VRM model
let currentVRM = null;

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

  // Remove demo cube
  scene.remove(cube);

  currentVRM = vrm;
  scene.add(vrm.scene);

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

  return {
    // File info
    fileName: fileName || null,

    // VRM Meta info
    name: meta?.name || 'Unknown',
    author: meta?.authors?.[0] || 'Unknown',
    version: meta?.metaVersion || 'Unknown',

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
  };
}

// Animation loop
function animate() {
  requestAnimationFrame(animate);

  // Rotate demo cube
  cube.rotation.x += 0.01;
  cube.rotation.y += 0.01;

  // Update VRM (for expressions, look-at, etc.)
  if (currentVRM) {
    currentVRM.update(1 / 60);
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

console.log('Three.js app initialized!');
