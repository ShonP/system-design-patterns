# syntax=docker/dockerfile:1.7
# Stage 1 — install deps in a fat image
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
# `npm ci` is the correct command: it installs exactly the lock file, or fails.
# This lab does not commit a lock file (it would be 10k lines of noise), so there is a
# fallback. In a real repo, commit package-lock.json and delete the fallback -- a build
# that can silently resolve fresh versions is not a reproducible build.
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --no-audit --no-fund \
 || npm install --omit=dev --no-audit --no-fund

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
