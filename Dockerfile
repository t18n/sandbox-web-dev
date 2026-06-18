# syntax=docker/dockerfile:1.4
#
# Web Development Sandbox Template
# ─────────────────────────────────
# A full development environment image for Docker sandboxes.
# This is the template layer — agent-specific configuration lives in kits.
#
# Base: docker/sandbox-templates:shell
# Tooling: Node.js 24, TypeScript, Playwright, Puppeteer, ESLint, Prettier,
#          Biome, database CLIs, build tools, shell utilities
#
# Usage with kits:
#   sbx run --kit ./kits/claude-code/ claude
#   sbx run --kit ./kits/gemini/ gemini

FROM docker/sandbox-templates:shell

USER root

# GitHub CLI repository
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
       "$(dpkg --print-architecture)" \
       > /etc/apt/sources.list.d/github-cli.list

# Node.js 24 from NodeSource
RUN mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key \
        | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" \
        > /etc/apt/sources.list.d/nodesource.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Node.js
    nodejs \
    # GitHub CLI
    gh \
    # Version control
    git-lfs \
    # Build toolchain (native addons, C/C++ compilation)
    build-essential \
    cmake \
    # Python
    python3 \
    python3-pip \
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

USER agent

# agent-local npm "global" installs
RUN mkdir -p "$HOME/.npm-global" \
    && npm config set prefix "$HOME/.npm-global" \
    && printf '\n# npm user-global prefix\nexport PATH="$HOME/.npm-global/bin:$PATH"\n' >> ~/.bashrc

# Package managers
RUN npm install -g pnpm yarn

# TypeScript toolchain
RUN npm install -g typescript tsx ts-node

# Linting and formatting
RUN npm install -g eslint prettier @biomejs/biome

# Testing — skip browser downloads at build time; sandbox has network access at runtime
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_CACHE_DIR=/home/agent/.cache/puppeteer
RUN npm install -g --ignore-scripts playwright @playwright/test puppeteer vitest

# Python dev tools
RUN pip3 install --user --break-system-packages ruff mypy httpie

# Keep the container alive so sbx can exec into it; kits override with their own entrypoint
CMD ["sleep", "infinity"]
