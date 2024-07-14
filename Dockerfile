## Sharp dependencies, copy all the files for production
FROM node:20-slim AS sharp

ENV PNPM_HOME="/pnpm"
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable

WORKDIR /app

RUN pnpm add sharp


# FROM oven/bun:1.1.3-debian AS builder
FROM node:20 AS builder

ARG GIT_TAG=main

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends --reinstall git ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# RUN git clone --depth=1 --branch ${GIT_TAG} https://github.com/miurla/morphic /app && \
#   rm -rf /app/.git && \
#   cd /app && \
#   bun install && \
#   bun next telemetry disable
# COPY morphic/next.config.mjs /app/next.config.mjs
# RUN bun run build

RUN git clone --depth=1 --branch ${GIT_TAG} -c advice.detachedHead=false https://github.com/miurla/morphic /app && \
  rm -rf /app/.git && \
  cd /app && \
  npm install && \
  npx next telemetry disable
COPY next.config.mjs /app/next.config.mjs
COPY .env.local /app/.env.local
RUN npm run build


# Production image, copy all the files and run next
FROM node:20-slim AS runner
WORKDIR /app

ENV NODE_ENV production

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=sharp /app/node_modules/.pnpm ./node_modules/.pnpm

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
