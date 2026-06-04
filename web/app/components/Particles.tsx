"use client";
import React, { useRef, useEffect } from "react";

type Particle = { x: number; y: number; vx: number; vy: number; r: number; hue: number };

export default function Particles() {
  const ref = useRef<HTMLCanvasElement | null>(null);
  const particles = useRef<Particle[]>([]);
  const mouse = useRef({ x: -9999, y: -9999, down: false });

  useEffect(() => {
    const canvas = ref.current!;
    if (!canvas) return;
    const ctx = canvas.getContext("2d")!;
    let w = (canvas.width = window.innerWidth);
    let h = (canvas.height = window.innerHeight);

    const resize = () => { w = canvas.width = window.innerWidth; h = canvas.height = window.innerHeight; };
    window.addEventListener("resize", resize);

    const spawn = (n = 80) => {
      particles.current = [];
      for (let i = 0; i < n; i++) {
        const size = 1 + Math.random() * 4; // roughly matches particles.js size range
        const speed = 1.5; // base speed
        particles.current.push({
          x: Math.random() * w,
          y: Math.random() * h,
          vx: (Math.random() - 0.5) * speed,
          vy: (Math.random() - 0.5) * speed,
          r: size,
          hue: 0,
        });
      }
    };
    spawn(80);

    let raf = 0;
    const dist = (a: Particle, b: Particle) => Math.hypot(a.x - b.x, a.y - b.y);

    const draw = () => {
      ctx.clearRect(0, 0, w, h);
      // lines
      // draw lines between particles (linking)
      for (let i = 0; i < particles.current.length; i++) {
        for (let j = i + 1; j < particles.current.length; j++) {
          const a = particles.current[i];
          const b = particles.current[j];
          const d = dist(a, b);
          if (d < 150) {
            const o = 0.65 * (1 - d / 150);
            ctx.strokeStyle = `rgba(212,175,55,${o})`; // #D4AF37
            ctx.lineWidth = 1 * (1 - d / 150);
            ctx.beginPath(); ctx.moveTo(a.x, a.y); ctx.lineTo(b.x, b.y); ctx.stroke();
          }
        }
      }

      // particles
      particles.current.forEach((p) => {
        // movement
        p.x += p.vx;
        p.y += p.vy;
        // small random jitter to mimic 'random: true'
        p.vx += (Math.random() - 0.5) * 0.02;
        p.vy += (Math.random() - 0.5) * 0.02;
        // slow down slightly
        p.vx *= 0.995; p.vy *= 0.995;
        if (p.x < -50) p.x = w + 50;
        if (p.x > w + 50) p.x = -50;
        if (p.y < -50) p.y = h + 50;
        if (p.y > h + 50) p.y = -50;

        // draw simple circle like particles.js
        ctx.beginPath();
        ctx.fillStyle = `rgba(91,0,0,0.5)`; // #5B0000 with 0.5 opacity
        ctx.arc(p.x, p.y, p.r, 0, Math.PI * 2);
        ctx.fill();
      });
      // draw mouse 'grab' lines
      if (mouse.current.x > -9998) {
        for (let i = 0; i < particles.current.length; i++) {
          const p = particles.current[i];
          const d = Math.hypot(p.x - mouse.current.x, p.y - mouse.current.y);
          if (d < 140) {
            const o = 0.8 * (1 - d / 140);
            ctx.beginPath(); ctx.strokeStyle = `rgba(212,175,55,${o})`; ctx.lineWidth = 1; ctx.moveTo(p.x, p.y); ctx.lineTo(mouse.current.x, mouse.current.y); ctx.stroke();
          }
        }
      }
      raf = requestAnimationFrame(draw);
    };

    draw();

    const onMove = (e: MouseEvent) => { mouse.current.x = e.clientX; mouse.current.y = e.clientY; };
    const onLeave = () => { mouse.current.x = -9999; mouse.current.y = -9999; };
    const onClick = (e: MouseEvent) => {
      // burst
      for (let i = 0; i < 12; i++) {
        particles.current.push({ x: e.clientX, y: e.clientY, vx: (Math.random() - 0.5) * 6, vy: (Math.random() - 0.5) * 6, r: 1 + Math.random() * 3, hue: 30 + Math.random() * 40 });
      }
      // keep count manageable
      if (particles.current.length > 220) particles.current.splice(0, particles.current.length - 220);
    };

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseout", onLeave);
    window.addEventListener("click", onClick);

    return () => {
      cancelAnimationFrame(raf);
      window.removeEventListener("resize", resize);
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseout", onLeave);
      window.removeEventListener("click", onClick);
    };
  }, []);

  return <canvas ref={ref} className="particles-canvas" />;
}
