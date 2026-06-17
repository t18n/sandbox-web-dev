# web-dev-sandbox

A [Docker sandbox](https://docs.docker.com/ai/sandboxes/) **template** that provides a complete web development environment, paired with **kits** that layer on specific AI coding agents.

Pick a template. Pick a kit. Start coding.

---

## Architecture

```
Template (Dockerfile)                    Kits (kits/<name>/spec.yaml)
┌──────────────────────────┐            ┌─────────────────────────┐
│  shell-docker base       │            │  claude-code            │
│  + system packages       │     ◄──    │  gemini                 │
│  + mise (Node, Python)   │  image     │  codex                  │
│  + TypeScript, Playwright│  reference │  opencode               │
│  + ESLint, Prettier      │            │  cursor-agent           │
│  + database CLIs         │            │  kiro / copilot         │
│  + Docker CE             │            │  droid / amp            │
└──────────────────────────┘            └─────────────────────────┘
```

The **template** is the development environment — runtimes, compilers, linters, formatters, test runners, database CLIs, and Docker. It gets published as a container image.

**Kits** are lightweight YAML specs that reference the template image, install a specific agent at sandbox launch, configure network access and credential injection, and prime the agent with context about the environment.

---

## What's in the template

### Runtimes — managed by [mise](https://mise.jdx.dev)

| Runtime | Default | Switch with            |
| ------- | ------- | ---------------------- |
| Node.js | 24      | `mise use node@22`     |
| Python  | 3.12    | `mise use python@3.11` |
| Bun     | latest  | `mise use bun@1.1`     |

### Package managers

`npm` · `pnpm` · `yarn` · `bun` · `pip`

### TypeScript toolchain

`typescript` (tsc) · `tsx` · `ts-node`

### Linting and formatting

`eslint` · `prettier` · `biome`

### Testing

`playwright` (CLI + Chromium & headless shell) · `puppeteer` (Chrome & headless shell) · `vitest`

### Python tools

`ruff` · `mypy` · `httpie`

### System tools

| Category      | Tools                                            |
| ------------- | ------------------------------------------------ |
| Database CLIs | `psql`, `redis-cli`, `sqlite3`                   |
| Docker        | CE + Compose + Buildx                            |
| Build         | `gcc`, `g++`, `make`, `cmake`, `build-essential` |
| Git           | `git`, `git-lfs`, `gh`                           |
| Shell         | `bat`, `fzf`, `jq`, `yq`, `ripgrep`              |

---

## Available kits

| Kit            | Agent                                                              | Run with                                          |
| -------------- | ------------------------------------------------------------------ | ------------------------------------------------- |
| `claude-code`  | [Claude Code](https://claude.ai/code) (Anthropic)                  | `sbx run --kit ./kits/claude-code/ claude-code`   |
| `gemini`       | [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google) | `sbx run --kit ./kits/gemini/ gemini`             |
| `codex`        | [Codex](https://github.com/openai/codex) (OpenAI)                  | `sbx run --kit ./kits/codex/ codex`               |
| `opencode`     | [OpenCode](https://opencode.ai)                                    | `sbx run --kit ./kits/opencode/ opencode`         |
| `cursor-agent` | [Cursor Agent](https://cursor.com)                                 | `sbx run --kit ./kits/cursor-agent/ cursor-agent` |
| `kiro`         | [Kiro](https://kiro.dev) (AWS)                                     | `sbx run --kit ./kits/kiro/ kiro`                 |
| `copilot`      | [GitHub Copilot](https://docs.github.com/copilot)                  | `sbx run --kit ./kits/copilot/ copilot`           |
| `droid`        | [Droid](https://factory.ai) (Factory AI)                           | `sbx run --kit ./kits/droid/ droid`               |
| `amp`          | [Amp](https://ampcode.com)                                         | `sbx run --kit ./kits/amp/ amp`                   |

---

## Quick start

### Run the base template

```bash
sbx run shell --template sandbox-templates:sandbox-web-dev
```

### Run an agent with a kit

Load a kit straight from this Git repository:

```bash
sbx run claude-code --kit "git+https://github.com/t18n/sandbox-web-dev.git#ref=main&dir=kits/claude-code"
```

or local

- `#ref=<branch|tag|commit>` pins to a specific revision. Defaults to the repository's default branch.
- `#dir=<path>` loads a kit from a subdirectory.
- `git+ssh://` URLs also work, using your local SSH agent, Git credential helpers, and `.netrc`.
- Quote the URL in shells where `&` starts a background job.

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with the `sbx` CLI
- A GitHub account (for GHCR image hosting)

### 1. Build and push the template

```bash
git clone https://github.com/t18n/sandbox-web-dev
cd sandbox-web-dev

DOCKER_REGISTRY=ghcr.io/t18n just push
```

### 2. Update kit image references

Replace `ghcr.io/OWNER/web-dev-sandbox:latest` in each kit's `spec.yaml` with your published image:

```bash
sed -i '' 's|ghcr.io/OWNER/|ghcr.io/t18n/|g' kits/*/spec.yaml
```

### 3. Register API keys

Each kit needs its agent's API key. Use `sbx secret` to register credentials on the host — they never enter the sandbox.

```bash
# Claude Code
sbx secret set-custom -g \
    --host api.anthropic.com \
    --env ANTHROPIC_API_KEY \
    --placeholder "sk-ant-{rand}" \
    --value "$ANTHROPIC_API_KEY"

# Codex / OpenAI
sbx secret set-custom -g \
    --host api.openai.com \
    --env OPENAI_API_KEY \
    --placeholder "sk-{rand}" \
    --value "$OPENAI_API_KEY"

# Gemini
sbx secret set-custom -g \
    --host generativelanguage.googleapis.com \
    --env GEMINI_API_KEY \
    --placeholder "AIza{rand}" \
    --value "$GEMINI_API_KEY"
```

### 4. Launch a sandbox with a kit

```bash
# Claude Code
sbx run --kit ./kits/claude-code/ claude-code

# Gemini
sbx run --kit ./kits/gemini/ gemini

# Amp
sbx run --kit ./kits/amp/ amp

# Or just the template (no agent, drop into shell)
sbx run -t ghcr.io/t18n/web-dev-sandbox shell
```

---

## Development

[`just`](https://github.com/casey/just) is the task runner. Install with `brew install just`.

```bash
just                    # list all recipes
just build              # build template image locally
just push               # build and push to registry
just check-tools        # verify all dev tools are present
just list-kits          # show available kits
just kit claude-code    # launch a sandbox with the Claude Code kit
just validate-kit codex # validate a kit spec
just validate-all-kits  # validate every kit
just inspect            # build and open a shell in the template image
just clean              # remove locally built inspect images
```

Override the registry:

```bash
DOCKER_REGISTRY=ghcr.io/t18n just push
```

---

## CI/CD

The GitHub Actions workflow (`.github/workflows/build.yml`) builds and pushes the template image to `ghcr.io` on every push to `main`, plus a weekly scheduled run.

**Setup:**

1. Fork the repo
2. Ensure **Settings → Actions → General** has "Read and write permissions" for `GITHUB_TOKEN`
3. Push to `main`

The template image publishes to `ghcr.io/t18n/web-dev-sandbox:latest`.

---

## Creating a new kit

1. Create `kits/<name>/spec.yaml` following the [kit spec reference](https://docs.docker.com/ai/sandboxes/kits/)
2. Set `sandbox.image` to your published template image
3. Add install commands, network rules, and agent context
4. Validate: `just validate-kit <name>`
5. Test: `just kit <name>`

See existing kits in `kits/` for examples.

---

## How it's built

```
docker/sandbox-templates:shell-docker   ← sandbox microVM + Docker CE
  └── base        system packages: gh, git-lfs, db CLIs, shell utils, Playwright deps
        └── runtimes    mise + Node 24 + Python 3.12 + Bun + pnpm/yarn
              └── tooling     TypeScript, ESLint, Prettier, Biome, Playwright, Puppeteer, vitest, ruff
                    └── final       published template image
```

All layers are cached between builds. Agents are no longer baked into the image — they're installed at sandbox launch by each kit's `commands.install` block, so they're always on the latest version.

---

## License

MIT
