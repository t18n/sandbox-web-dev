image := "web-dev-sandbox"
registry := env("DOCKER_REGISTRY", "ghcr.io/t18n")
tag := env("IMAGE_TAG", "latest")
full_image := registry + "/" + image + ":" + tag

# List available recipes
default:
    @just --list

# Build the template image locally (no push)
build:
    docker buildx build --load -t {{full_image}} .

# Build and push the template image to registry
push:
    docker buildx build --push -t {{full_image}} .

# Build a specific stage and drop into a shell to inspect it
inspect stage="final":
    docker buildx build --load --target {{stage}} -t {{image}}-inspect:{{stage}} . \
        && docker run --rm -it {{image}}-inspect:{{stage}}

# Run the template image directly (drops into a shell)
run:
    docker run --rm -it \
        -v "$(pwd)":/home/agent/workspace \
        -w /home/agent/workspace \
        {{full_image}}

# Launch a sandbox with a specific kit (e.g., just kit claude-code)
kit name:
    sbx run --kit ./kits/{{name}}/ {{name}}

# Validate a kit spec (e.g., just validate-kit claude-code)
validate-kit name:
    sbx kit validate ./kits/{{name}}/

# Validate all kit specs
validate-all-kits:
    @for dir in kits/*/; do \
        name=$(basename "$$dir"); \
        echo "Validating $$name..."; \
        sbx kit validate "$$dir" && echo "  ✓ $$name" || echo "  ✗ $$name"; \
    done

# List all available kits
list-kits:
    @echo "Available kits:"
    @for dir in kits/*/; do \
        name=$(basename "$$dir"); \
        desc=$$(grep '^description:' "$$dir/spec.yaml" | sed 's/^description: *//'); \
        printf "  %-16s %s\n" "$$name" "$$desc"; \
    done

# Show what dev tools are available in the template image
check-tools:
    @echo "Checking tools in {{full_image}}..."
    docker run --rm --entrypoint="" {{full_image}} \
        bash -c ' \
            echo "=== Language runtimes (mise) ==="; \
            /home/agent/.local/bin/mise list 2>/dev/null | sed "s/^/  /"; \
            echo ""; \
            echo "=== Node.js global packages ==="; \
            for bin in tsc tsx ts-node eslint prettier biome playwright vitest pnpm yarn; do \
                path=$(command -v "$bin" 2>/dev/null); \
                if [ -n "$path" ]; then echo "  ✓  $bin → $path"; \
                else echo "  ✗  $bin (not found)"; fi; \
            done; \
            echo ""; \
            echo "=== Python tools ==="; \
            for bin in ruff mypy http; do \
                path=$(command -v "$bin" 2>/dev/null); \
                if [ -n "$path" ]; then echo "  ✓  $bin → $path"; \
                else echo "  ✗  $bin (not found)"; fi; \
            done; \
            echo ""; \
            echo "=== System tools ==="; \
            for bin in docker gh git-lfs bat fzf jq yq rg psql redis-cli sqlite3 cmake; do \
                path=$(command -v "$bin" 2>/dev/null); \
                if [ -n "$path" ]; then echo "  ✓  $bin → $path"; \
                else echo "  ✗  $bin (not found)"; fi; \
            done'

# Remove locally built inspect images
clean:
    docker images --format '{{{{.Repository}}}}:{{{{.Tag}}}}' \
        | grep '^{{image}}-inspect:' \
        | xargs -r docker rmi
