import { defineConfig } from 'vitest/config';

// Game content (problems, countermeasures, missions, concepts) lives in ../data
// and is shared with the legacy Python build, so Vite must be allowed to read it.
export default defineConfig({
  base: './',
  server: { fs: { allow: ['..'] } },
  build: { chunkSizeWarningLimit: 2000 },
  test: { environment: 'node' },
});
