import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Build to ./build with relative asset paths so FiveM's NUI can load it.
export default defineConfig({
  plugins: [react()],
  base: './',
  build: {
    outDir: 'build',
    target: 'esnext',
    assetsInlineLimit: 100000000, // inline everything -> single-file friendly HUD
    chunkSizeWarningLimit: 4096,
  },
});
