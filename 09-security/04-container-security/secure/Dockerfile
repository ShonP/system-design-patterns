# syntax=docker/dockerfile:1.7
# Stage 1 — install deps in a fat image
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --no-audit --no-fund

# Stage 2 — copy app source
FROM node:20-alpine AS build
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Stage 3 — minimal runtime
FROM node:20-alpine AS runtime
RUN addgroup -g 10001 -S app && adduser -u 10001 -S app -G app
WORKDIR /app
COPY --from=build --chown=app:app /app /app

USER app
ENV NODE_ENV=production
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/health || exit 1

CMD ["node", "server.js"]
