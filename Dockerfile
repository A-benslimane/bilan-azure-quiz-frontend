# syntax=docker/dockerfile:1
# ──────────────────────────────────────────────────────────────────────────────
# Multi-stage build for the AKS track (piste "AKS", see helm/ and
# .github/workflows/aks-deploy.yml). swa-deploy.yml (Static Web Apps track)
# never uses this image.
#
# API_BASE_URL/API_KEY are baked in at build time via the same sed-into-
# environment.ts substitution swa-deploy.yml already does ("Inject prod
# environment values" step) -- Angular bundles environment.ts into the JS at
# build time either way, so there's no "runtime env var" option here without
# a bigger restructure (e.g. a config.json fetched at startup). Consequence:
# a URL/key change means a rebuild + redeploy, not just a new `helm upgrade
# --set`, same constraint that already exists for the Static Web App track.
# ──────────────────────────────────────────────────────────────────────────────

# ── Build stage ─────────────────────────────────────────────────────────────
FROM node:24-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

ARG API_BASE_URL
ARG API_KEY
RUN test -n "$API_BASE_URL" && test -n "$API_KEY" || (echo "API_BASE_URL and API_KEY build args are required" && exit 1)
RUN sed -i "s#https://REPLACE_WITH_PROD_API_URL/api#${API_BASE_URL}#" src/environments/environment.ts \
 && sed -i "s/__BACKEND_API_KEY__/${API_KEY}/" src/environments/environment.ts

RUN npm run build:prod

# ── Runtime stage ────────────────────────────────────────────────────────────
# Keep the runtime image current to pick up Alpine/OpenSSL security fixes.
FROM nginx:1.31.6-alpine3.24

RUN apk upgrade --no-cache

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist/azure-quiz-frontend/browser /usr/share/nginx/html

# Trivy DS-0002: run the runtime container as the unprivileged nginx user.
# nginx.conf listens on 8080, so no privileged (<1024) port is required.
RUN chown -R nginx:nginx /var/cache/nginx /var/run /usr/share/nginx/html
USER nginx

EXPOSE 8080
