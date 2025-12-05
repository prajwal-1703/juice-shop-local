# 1. Installer Stage (Uses Debian Slim for smaller size)
FROM node:20-bullseye-slim as installer

# --- FIX START: Install Git and Build Tools ---
# We need git for dependencies hosted on GitHub
# We need python3 & build-essential for compiling native modules (sqlite3, etc.)
RUN apt-get update && \
    apt-get install -y git build-essential python3 && \
    rm -rf /var/lib/apt/lists/*
# --- FIX END ---

COPY . /juice-shop
WORKDIR /juice-shop

RUN npm i -g typescript ts-node
RUN npm install --omit=dev --unsafe-perm
RUN npm dedupe --omit=dev

# Cleanup to reduce image size
RUN rm -rf frontend/node_modules
RUN rm -rf frontend/.angular
RUN rm -rf frontend/src/assets

# Create logs and set permissions
RUN mkdir logs
RUN chown -R 65532 logs
RUN chgrp -R 0 ftp/ frontend/dist/ logs/ data/ i18n/
RUN chmod -R g=u ftp/ frontend/dist/ logs/ data/ i18n/

# Remove sensitive or unused files
RUN rm data/chatbot/botDefaultTrainingData.json || true
RUN rm ftp/legal.md || true
RUN rm i18n/*.json || true

# Generate SBOM (Software Bill of Materials)
ARG CYCLONEDX_NPM_VERSION=latest
RUN npm install -g @cyclonedx/cyclonedx-npm@$CYCLONEDX_NPM_VERSION
RUN npm run sbom

# 2. Final Runtime Stage (Distroless for Security)
# CHANGED: Using nodejs20 to match the installer stage (prevents ABI mismatch errors)
FROM gcr.io/distroless/nodejs20-debian11

ARG BUILD_DATE
ARG VCS_REF
LABEL maintainer="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.title="OWASP Juice Shop" \
    org.opencontainers.image.description="Probably the most modern and sophisticated insecure web application" \
    org.opencontainers.image.authors="Bjoern Kimminich <bjoern.kimminich@owasp.org>" \
    org.opencontainers.image.vendor="Open Worldwide Application Security Project" \
    org.opencontainers.image.documentation="https://help.owasp-juice.shop" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.version="19.1.1" \
    org.opencontainers.image.url="https://owasp-juice.shop" \
    org.opencontainers.image.source="https://github.com/juice-shop/juice-shop" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

WORKDIR /juice-shop

# Copy the built application from the installer stage
COPY --from=installer --chown=65532:0 /juice-shop .

USER 65532
EXPOSE 3000
CMD ["/juice-shop/build/app.js"]
