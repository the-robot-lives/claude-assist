ARG NODE_VERSION=22-alpine

FROM node:${NODE_VERSION} AS deps
RUN apk add --no-cache gettext
WORKDIR /app
COPY package.json package-lock.json* .npmrc.template ./
RUN --mount=type=secret,id=npm_token \
    --mount=type=cache,target=/root/.npm \
    NPM_TOKEN=$(cat /run/secrets/npm_token) \
    envsubst < .npmrc.template > .npmrc && \
    npm ci && \
    rm -f .npmrc

FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
# Inlined into Next.js middleware (src/proxy.ts) at build time so the apex
# /app/* -> app-subdomain redirect works; runtime pages use window.__ENV instead.
ARG NEXT_PUBLIC_APP_URL
ENV NEXT_PUBLIC_APP_URL=${NEXT_PUBLIC_APP_URL}

RUN npm run build

FROM node:${NODE_VERSION} AS production
WORKDIR /app

ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=build --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=build --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=build --chown=nextjs:nodejs /app/public ./public
# @noizu/styleguide loadConfig() scans src/config/theme-style-guide from disk at
# SSR time; standalone output omits it, 500ing dynamic routes (ENOENT scandir).
COPY --from=build --chown=nextjs:nodejs /app/src/config ./src/config
COPY --chown=nextjs:nodejs docker-entrypoint.sh ./

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ || exit 1

CMD ["sh", "docker-entrypoint.sh"]
