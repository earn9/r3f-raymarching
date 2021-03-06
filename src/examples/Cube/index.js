import React, { useRef } from "react";
import { Plane, shaderMaterial, useAspect } from "drei";
import { Canvas, useFrame, extend } from "react-three-fiber";

import frag from './frag.glsl'
import vert from './vert.glsl'

extend({ MyMaterial: shaderMaterial({ time: 0 }, vert, frag) });

function Scene() {
  const mat = useRef();
  useFrame(() => {
    mat.current.uniforms.time.value += 1 / 20;
  });

  const scale = useAspect("cover", window.innerWidth, window.innerHeight, 1);
  const s = Math.min(...scale.slice(0, 2));

  return (
    <Plane scale={[s, s, 1]}>
      <myMaterial ref={mat} />
    </Plane>
  );
}

export default function CubeExample() {
  return (
    <Canvas
      shadowMap
      colorManagement
      camera={{ position: [0, 0, 2], far: 50 }}
      style={{
        background: "#121212",
      }}
      concurrent
    >
      <Scene />
    </Canvas>
  );
}
