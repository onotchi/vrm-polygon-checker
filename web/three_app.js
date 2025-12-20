import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { VRMLoaderPlugin } from '@pixiv/three-vrm';

// Three.js setup
const canvas = document.getElementById('three-canvas');
const renderer = new THREE.WebGLRenderer({ canvas, alpha: true });
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.setPixelRatio(window.devicePixelRatio);

const scene = new THREE.Scene();
const camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 1000);
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

// Load VRM function (will be called from Flutter)
window.loadVRM = async function(url) {
  try {
    const gltf = await loader.loadAsync(url);
    const vrm = gltf.userData.vrm;

    if (currentVRM) {
      scene.remove(currentVRM.scene);
    }

    // Remove demo cube
    scene.remove(cube);

    currentVRM = vrm;
    scene.add(vrm.scene);

    // Get model info
    const info = getVRMInfo(vrm, gltf);
    return JSON.stringify(info);
  } catch (e) {
    console.error('VRM load error:', e);
    return JSON.stringify({ error: e.message });
  }
};

// Get VRM info
function getVRMInfo(vrm, gltf) {
  let totalVertices = 0;
  let totalTriangles = 0;
  let meshCount = 0;

  gltf.scene.traverse((object) => {
    if (object.isMesh) {
      meshCount++;
      const geometry = object.geometry;
      if (geometry.attributes.position) {
        totalVertices += geometry.attributes.position.count;
      }
      if (geometry.index) {
        totalTriangles += geometry.index.count / 3;
      }
    }
  });

  const meta = vrm.meta;

  return {
    // VRM Meta info
    name: meta?.name || 'Unknown',
    author: meta?.authors?.[0] || 'Unknown',
    version: meta?.metaVersion || 'Unknown',

    // Mesh info
    meshCount: meshCount,
    vertexCount: totalVertices,
    triangleCount: Math.floor(totalTriangles),

    // Bone info
    boneCount: vrm.humanoid?.humanBones ? Object.keys(vrm.humanoid.humanBones).length : 0,

    // Material info
    materialCount: gltf.parser?.json?.materials?.length || 0,

    // Texture info
    textureCount: gltf.parser?.json?.textures?.length || 0,
  };
}

// Expose canvas control for Flutter
window.setThreeCanvasPointerEvents = function(enabled) {
  canvas.style.pointerEvents = enabled ? 'auto' : 'none';
};

// Enable pointer events by default for OrbitControls
canvas.style.pointerEvents = 'auto';

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
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
});

console.log('Three.js app initialized!');
