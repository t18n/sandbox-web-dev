# syntax=docker/dockerfile:1.4
#
# Web Development Sandbox Template
# ─────────────────────────────────
# A full development environment image for Docker sandboxes.
# This is the template layer — agent-specific configuration lives in kits.
#
# Base: docker/sandbox-templates:shell-docker (includes Docker CE)
# Tooling: mise (Node 24, Python 3.12, Bun), TypeScript, Playwright,
#          Puppeteer, headless Chromium, ESLint, Prettier, database CLIs,
#          build tools, shell utilities
#
# Usage with kits:
#   sbx run --kit ./kits/claude-code/ claude
#   sbx run --kit ./kits/gemini/ gemini

##############################################################################
# base — system packages on top of the Docker-enabled sandbox shell
##############################################################################
FROM docker/sandbox-templates:shell-docker AS base

USER root

# GitHub CLI repository
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
       "$(dpkg --print-architecture)" \
       > /etc/apt/sources.list.d/github-cli.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    # GitHub CLI
    gh \
    # Version control
    git-lfs \
    # Build toolchain (native addons, C/C++ compilation)
    build-essential \
    cmake \
    # Database CLIs
    postgresql-client \
    redis-tools \
    sqlite3 \
    # Shell utilities
    bat \
    fzf \
    jq \
    ripgrep \
    # Network utilities
    dnsutils \
    # Playwright browser dependencies (Chromium)
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 \
    libpango-1.0-0 libcairo2 libasound2t64 libatspi2.0-0 \
    # Misc
    xdg-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# yq — YAML/JSON/TOML processor (not in Ubuntu repos)
RUN YQ_VER=$(curl -fsSL https://api.github.com/repos/mikefarah/yq/releases/latest \
      | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/') \
    && curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VER}/yq_linux_amd64" \
       -o /usr/local/bin/yq \
    && chmod +x /usr/local/bin/yq

# Ensure npm-global dir is writable by agent
RUN mkdir -p /usr/local/share/npm-global/bin \
    && chown -R agent:agent /usr/local/share/npm-global

# npm globals always land at this prefix
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global

##############################################################################
# runtimes — mise + managed language versions
##############################################################################
FROM base AS runtimes

USER agent

# Install mise binary (via GitHub releases — arch-aware)
RUN set -eux; \
    MISE_VER=$(curl -fsSL https://api.github.com/repos/jdx/mise/releases/latest \
        | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/'); \
    ARCH=$(uname -m | sed 's/x86_64/x64/;s/aarch64/arm64/'); \
    mkdir -p /home/agent/.local/bin \
    && curl -fsSL "https://github.com/jdx/mise/releases/download/v${MISE_VER}/mise-v${MISE_VER}-linux-${ARCH}" \
       -o /home/agent/.local/bin/mise \
    && chmod +x /home/agent/.local/bin/mise

# Extend PATH: mise shims first so managed tools shadow system versions
ENV PATH=/home/agent/.local/share/mise/shims:/home/agent/.local/bin:/usr/local/share/npm-global/bin:$PATH

# Persist PATH into sandbox runtime
RUN printf 'export PATH="/home/agent/.local/share/mise/shims:/home/agent/.local/bin:/usr/local/share/npm-global/bin:$PATH"\n' \
    >> /etc/sandbox-persistent.sh

# Language runtimes
RUN mise use --global node@24 python@3.12 bun@latest \
    && mise install

# Global package managers
RUN npm install -g pnpm yarn

##############################################################################
# tooling — development tools baked into the template
##############################################################################
FROM runtimes AS tooling

USER agent

# TypeScript toolchain
RUN npm install -g typescript tsx ts-node

# Linting and formatting
RUN npm install -g eslint prettier @biomejs/biome

# Testing — Playwright (bundles the playwright CLI), Puppeteer, Vitest
# Skip browser downloads at build time; sandbox has network access at runtime
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_CACHE_DIR=/home/agent/.cache/puppeteer
RUN npm install -g playwright @playwright/test puppeteer vitest

# Python dev tools
RUN pip install --user ruff mypy httpie

##############################################################################
# final — the published template image
##############################################################################
FROM tooling AS final

USER agent

# Keep the container alive so sbx can exec into it; kits override with their own entrypoint
CMD ["sleep", "infinity"]
