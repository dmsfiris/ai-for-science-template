# ---------- Builder ----------
# (Only ARG is allowed before the first FROM)
ARG BASE_PATH
ARG NEXT_PUBLIC_API_URL

FROM node:20-bullseye AS builder

# Make build args available in this stage
ARG BASE_PATH
ARG NEXT_PUBLIC_API_URL

WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
# Expose base path + API URL to Next at build time (for client bundle)
ENV NEXT_PUBLIC_BASE_PATH=${BASE_PATH}
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}

# OS deps commonly needed by Next (sharp/SWC fallbacks, etc.)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates python3 make g++ \
 && rm -rf /var/lib/apt/lists/*

# Install deps (dev deps included for build)
COPY package.json package-lock.json* pnpm-lock.yaml* yarn.lock* ./
RUN if [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then npm install -g pnpm && pnpm i --frozen-lockfile; \
    elif [ -f yarn.lock ]; then corepack enable && yarn install --immutable; \
    else npm install; fi

# App source
COPY . .
# Ensure a public dir exists so the copy in runner never fails
RUN mkdir -p public

# Build Next.js
RUN npm run build

# ---------- Runtime ----------
FROM node:20-bullseye AS runner

WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

# Copy runtime artifacts
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/next.config.* ./
COPY --from=builder /app/tsconfig.json ./

EXPOSE 3000
CMD ["npm", "start"]

