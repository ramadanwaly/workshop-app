import { z } from 'zod'

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  NEXT_PUBLIC_SUPABASE_URL: z.string().url({ message: 'Must be a valid URL' }),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1, { message: 'Must not be empty' }),
  SUPABASE_SERVICE_ROLE_KEY: z.string().optional(),
  NEXT_PUBLIC_SITE_URL: z.string().url({ message: 'Must be a valid URL' }),
})

function getEnv() {
  const isTest = process.env.NODE_ENV === 'test' || Boolean(process.env.VITEST)
  return envSchema.parse({
    NODE_ENV: process.env.NODE_ENV ?? 'development',
    NEXT_PUBLIC_SUPABASE_URL:
      process.env.NEXT_PUBLIC_SUPABASE_URL ?? (isTest ? 'http://127.0.0.1:54321' : undefined),
    NEXT_PUBLIC_SUPABASE_ANON_KEY:
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY ?? (isTest ? 'anon-test-key' : undefined),
    SUPABASE_SERVICE_ROLE_KEY: process.env.SUPABASE_SERVICE_ROLE_KEY,
    NEXT_PUBLIC_SITE_URL:
      process.env.NEXT_PUBLIC_SITE_URL ?? (isTest ? 'http://localhost:3000' : undefined),
  })
}

export const env = getEnv()
