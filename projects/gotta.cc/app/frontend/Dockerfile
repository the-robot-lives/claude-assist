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

# AdSense publisher ID (ca-pub-…). Baked in as a build-time fallback; the
# runtime ADSENSE_CLIENT env var (see docker-entrypoint.sh) takes precedence,
# so changing publishers does not require a rebuild.
ARG NEXT_PUBLIC_ADSENSE_CLIENT
ENV NEXT_PUBLIC_ADSENSE_CLIENT=${NEXT_PUBLIC_ADSENSE_CLIENT}

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
# style-guide config (src/config/theme-style-guide) is read at runtime by
# loadConfig()/loadAllBrandings() during SSR of dynamic routes (e.g. /category/[slug]).
# Next.js standalone file-tracing doesn't see these dynamic fs reads, so copy the
# config dir into the runtime image to avoid ENOENT 500s on dynamic routes.
COPY --from=build --chown=nextjs:nodejs /app/src/config ./src/config
COPY --chown=nextjs:nodejs docker-entrypoint.sh ./

USER nextjs

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/ || exit 1

CMD ["sh", "docker-entrypoint.sh"]
