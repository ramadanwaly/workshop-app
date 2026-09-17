import { fileURLToPath } from 'node:url'
import { defineConfig } from 'vitest/config'

const root = fileURLToPath(new URL('.', import.meta.url))

export default defineConfig({
  test: {
    environment: 'node',
    env: {
      // مطلوب لاختبارات المصادقة — يجب أن يطابق القيمة في .env.local
      NEXT_PUBLIC_SITE_URL: 'http://localhost:3000',
    },
  },
  resolve: {
    alias: {
      '@': root,
    },
  },
})