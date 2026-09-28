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
      external: ['stimulus', '@hotwired/stimulus', '@hotwired/turbo'],
      output: {
        globals: {
          stimulus: 'Stimulus',
          '@hotwired/stimulus': 'Stimulus',
          '@hotwired/turbo': 'Turbo'
        }
      }
    }
  }
})
