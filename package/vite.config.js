const path = require('path')
import { defineConfig } from 'vite'

export default defineConfig({
  build: {
    lib: {
      entry: path.resolve(__dirname, 'src/index.ts'),
      name: 'media_library'
    },
    rollupOptions: {
      input: 'src/index.ts',
      external: ['stimulus'],
      output: {
        globals: {
          stimulus: 'Stimulus'
        }
      }
    }
  }
})
