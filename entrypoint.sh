#!/bin/bash
# Default entrypoint for the web-dev sandbox template.
# Kits override this with their own entrypoint; this is the fallback
# when the template is used directly without a kit.
set -e
exec "$@"
