## Sharp dependencies, copy all the files for production
FROM node:22-slim AS sharp

ENV PNPM_HOME "/pnpm"
ENV PATH "$PNPM_HOME:$PATH"
RUN npm install -g pnpm

WORKDIR /app

RUN pnpm add sharp


FROM bitnami/git AS source

ARG GIT_TAG=main

WORKDIR /app

RUN git clone --depth=1 --branch ${GIT_TAG} -c advice.detachedHead=false https://github.com/miurla/morphic /app && \
  rm -rf /app/.git


FROM oven/bun:1.2-debian AS builder
# FROM node:22 AS builder

WORKDIR /app

COPY --from=source /app /app

RUN cd /app && \
  bun install && \
  bun next telemetry disable
COPY next.config.mjs /app/next.config.mjs
COPY .env.local /app/.env.local
RUN bun run build

# RUN git clone --depth=1 --branch ${GIT_TAG} -c advice.detachedHead=false https://github.com/miurla/morphic /app && \
#   rm -rf /app/.git && \
#   cd /app && \
#   npm install && \
#   npx next telemetry disable
# COPY next.config.mjs /app/next.config.mjs
# COPY .env.local /app/.env.local
# RUN npm run build


# Production image, copy all the files and run next
FROM node:22-slim AS runner
WORKDIR /app

ENV NODE_ENV production

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=sharp /app/node_modules/.pnpm ./node_modules/.pnpm

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
