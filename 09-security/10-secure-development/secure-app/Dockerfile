# syntax=docker/dockerfile:1.7
FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
 || npm install --omit=dev --ignore-scripts --no-audit --no-fund

FROM node:20-alpine AS runtime
RUN addgroup -g 10001 -S app && adduser -u 10001 -S app -G app
WORKDIR /app
COPY --from=deps --chown=app:app /app /app
COPY --chown=app:app . .
USER app
ENV NODE_ENV=production
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://127.0.0.1:3000/api/health || exit 1
CMD ["node", "src/index.js"]
