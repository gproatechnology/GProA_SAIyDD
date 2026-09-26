import { defineConfig } from 'vite';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const rootDir = path.dirname(fileURLToPath(import.meta.url));

function copyExtraStatic() {
  return {
    name: 'copy-extra-static',
    apply: 'build',
    closeBundle() {
      const src = path.join(rootDir, 'src/assets');
      const dest = path.join(rootDir, 'dist/assets');
      if (fs.existsSync(src) && fs.existsSync(dest)) {
        fs.cpSync(src, dest, { recursive: true, force: true });
      }
    }
  };
}

export default defineConfig({
  root: rootDir,
  plugins: [copyExtraStatic()],
  server: {
    port: 5174,
    open: '/index.html'
  }
});