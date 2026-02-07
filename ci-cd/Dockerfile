# HUMMBL Infrastructure - Multi-Stage Dockerfile
# Base120: CO10 (Pipeline Orchestration), SY14 (Resilience)
#
# Stages:
#   1. base - Common dependencies and non-root user
#   2. deps - Install production dependencies only
#   3. builder - Full build with dev dependencies
#   4. runtime - Minimal production image
#
# Build:
#   docker build -t hummbl-infra:latest .
#   docker build --target builder -t hummbl-infra:dev .
#
# Multi-arch:
#   docker buildx build --platform linux/amd64,linux/arm64 -t hummbl-infra:latest .

ARG NODE_VERSION=22
ARG ALPINE_VERSION=3.19

# =============================================================================
# Stage 1: Base - Common setup
# =============================================================================
FROM node:${NODE_VERSION}-alpine${ALPINE_VERSION} AS base

# Install security updates and common dependencies
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache \
      dumb-init \
      ca-certificates \
      curl \
      && rm -rf /var/cache/apk/*

# Create non-root user for security
RUN addgroup -g 1001 hummbl && \
    adduser -u 1001 -G hummbl -s /bin/sh -D hummbl

WORKDIR /app

# =============================================================================
# Stage 2: Dependencies - Production deps only
# =============================================================================
FROM base AS deps

# Copy package files
COPY --chown=hummbl:hummbl package.json pnpm-lock.yaml ./

# Install pnpm and production dependencies
RUN corepack enable pnpm && \
    pnpm install --frozen-lockfile --prod --ignore-scripts

# =============================================================================
# Stage 3: Builder - Full build
# =============================================================================
FROM base AS builder

# Copy package files
COPY --chown=hummbl:hummbl package.json pnpm-lock.yaml ./

# Install pnpm and all dependencies (including dev)
RUN corepack enable pnpm && \
    pnpm install --frozen-lockfile --ignore-scripts

# Copy source code
COPY --chown=hummbl:hummbl . .

# Build application
RUN pnpm build

# Prune dev dependencies after build
RUN pnpm prune --prod

# =============================================================================
# Stage 4: Runtime - Minimal production image
# =============================================================================
FROM base AS runtime

# OCI Labels (required for SLSA compliance)
LABEL org.opencontainers.image.source="https://github.com/hummbl-dev/hummbl-infra"
LABEL org.opencontainers.image.description="HUMMBL Infrastructure Platform"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.vendor="HUMMBL"

# Copy production dependencies from deps stage
COPY --from=deps --chown=hummbl:hummbl /app/node_modules ./node_modules

# Copy built application from builder stage
COPY --from=builder --chown=hummbl:hummbl /app/dist ./dist
COPY --from=builder --chown=hummbl:hummbl /app/package.json ./

# Switch to non-root user
USER hummbl

# Environment
ENV NODE_ENV=production
ENV PORT=3000

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Use dumb-init for proper signal handling
ENTRYPOINT ["/usr/bin/dumb-init", "--"]

# Start application
CMD ["node", "dist/index.js"]
