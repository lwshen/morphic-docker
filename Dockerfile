# Clone repo
FROM bitnami/git AS source

ARG GIT_TAG=main

WORKDIR /app

RUN git clone --depth=1 --branch ${GIT_TAG} -c advice.detachedHead=false https://github.com/miurla/morphic /app && \
  rm -rf /app/.git


# Build source code
FROM oven/bun:1.2-debian AS builder

WORKDIR /app

COPY --from=source /app/package.json ./
COPY --from=source /app/bun.lock ./

RUN bun install

COPY --from=source /app ./

RUN bun next telemetry disable
COPY next.config.mjs /app/next.config.mjs
RUN bun run build


# Production image, copy all the files and run next
FROM node:22-slim AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Automatically leverage output traces to reduce image size
# https://nextjs.org/docs/advanced-features/output-file-tracing
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT=3000

# server.js is created by next build from the standalone output
# https://nextjs.org/docs/pages/api-reference/config/next-config-js/output
ENV HOSTNAME="0.0.0.0"
CMD ["node", "server.js"]
