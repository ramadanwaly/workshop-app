# ============================================================================
# Dockerfile — production image for the workshop Next.js app (standalone output)
# Build with output: 'standalone' (see next.config.ts).
# Run as unprivileged node user; copy only the standalone build + static assets.
# ============================================================================
FROM node:26.9.0-alpine3.24 AS base
WORKDIR /app

FROM node:26.9.0-alpine3.24 AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

FROM node:26.9.0-alpine3.24 AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm audit fix --force || true
# متغيرات NEXT_PUBLIC_* تُحقن وقت البناء في حزمة JavaScript الثابتة —
# يجب تمريرها كـ build-args عند البناء.
ARG NEXT_PUBLIC_SUPABASE_URL
ARG NEXT_PUBLIC_SUPABASE_ANON_KEY
ARG NEXT_PUBLIC_SITE_URL
ENV NEXT_PUBLIC_SUPABASE_URL=$NEXT_PUBLIC_SUPABASE_URL \
    NEXT_PUBLIC_SUPABASE_ANON_KEY=$NEXT_PUBLIC_SUPABASE_ANON_KEY \
    NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
RUN npm run build

FROM node:26.9.0-alpine3.24 AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN apk update && apk upgrade --no-cache \
    && addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
