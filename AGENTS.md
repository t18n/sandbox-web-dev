# Agent Rules

## Project

This repo produces two things:

1. A **Docker sandbox template** (`Dockerfile`) — a dev environment image with runtimes, compilers, linters, and test tooling. No agents baked in.
2. **Kits** (`kits/<name>/spec.yaml`) — lightweight YAML specs that layer a specific AI agent on top of the template at sandbox launch.

Published image: `ghcr.io/t18n/web-dev-sandbox:latest`

## Dockerfile

- Base image is `docker/sandbox-templates:shell-docker`. Do not switch to `shell` unless Docker-in-sandbox support is being removed.
- Multi-stage build: `base` → `runtimes` → `tooling` → `final`. Keep this order. Each stage is a cache boundary.
- System packages go in `base`. Language runtimes (via mise) go in `runtimes`. npm/pip dev tools go in `tooling`.
- Never install AI agents in the Dockerfile. Agents belong in kits.
- The `agent` user (UID 1000) owns everything under `/home/agent/`. Run installs as this user unless root is required for system packages.

## Kits

- One directory per agent under `kits/`. Each contains a single `spec.yaml`.
- All kits must set `sandbox.image` to `ghcr.io/t18n/web-dev-sandbox:latest`.
- Install commands run as user `1000` (agent), not root.
- Keep `allowedDomains` minimal — only the hosts the agent actually needs. Do not use broad wildcards on domains that serve auth traffic.
- Keep `serviceDomains` narrow to avoid TLS interception on CDN/install hosts.
- `agentContext` should be short and describe available tooling, not repeat the kit spec.

## General

- Task runner is `just` (see `Justfile`). Validate kits with `just validate-kit <name>`.
- CI builds and pushes the template image only. Kits are not built — they're consumed by `sbx run --kit` at launch time.
- Do not add files to the repo root unless necessary. Keep the structure flat.
- When adding a new agent kit, also add it to the "Available kits" table in `README.md`.
