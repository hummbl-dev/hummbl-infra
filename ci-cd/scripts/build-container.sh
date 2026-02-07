#!/usr/bin/env bash
# Local Container Build Script
# Base120: CO10 (Pipeline Orchestration)
#
# Usage:
#   ./ci-cd/scripts/build-container.sh              # Build locally
#   ./ci-cd/scripts/build-container.sh --tag v1.0.0 # Custom tag
#   ./ci-cd/scripts/build-container.sh --push       # Push to registry

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Defaults
IMAGE_NAME="hummbl-infra"
TAG="local"
PUSH=false
PLATFORM=""
NO_CACHE=false
DOCKERFILE="$ROOT_DIR/ci-cd/Dockerfile"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Build the HUMMBL Infrastructure container locally.

OPTIONS:
  -t, --tag TAG         Image tag (default: local)
  -n, --name NAME       Image name (default: hummbl-infra)
  -p, --platform PLAT   Target platform (e.g., linux/amd64)
  --push                Push to registry after build
  --no-cache            Build without cache
  -h, --help            Show this help

EXAMPLES:
  $(basename "$0")                    # Build with default tag
  $(basename "$0") --tag v1.0.0       # Build with version tag
  $(basename "$0") --platform linux/arm64  # Build for specific platform
  $(basename "$0") --push             # Build and push to registry
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -t|--tag)
      TAG="$2"
      shift 2
      ;;
    -n|--name)
      IMAGE_NAME="$2"
      shift 2
      ;;
    -p|--platform)
      PLATFORM="$2"
      shift 2
      ;;
    --push)
      PUSH=true
      shift
      ;;
    --no-cache)
      NO_CACHE=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      log_error "Unknown option: $1"
      usage
      ;;
  esac
done

# Check Docker
if ! command -v docker &>/dev/null; then
  log_error "Docker not found. Install Docker or start Colima."
  exit 1
fi

if ! docker info &>/dev/null; then
  log_error "Docker daemon not running."
  exit 1
fi

# Build image
log_info "Building container image..."
echo "  Name: $IMAGE_NAME"
echo "  Tag: $TAG"
echo "  Dockerfile: $DOCKERFILE"

BUILD_ARGS=(
  "--tag" "$IMAGE_NAME:$TAG"
  "--file" "$DOCKERFILE"
)

if [[ -n "$PLATFORM" ]]; then
  BUILD_ARGS+=("--platform" "$PLATFORM")
fi

if [[ "$NO_CACHE" == "true" ]]; then
  BUILD_ARGS+=("--no-cache")
fi

BUILD_ARGS+=("$ROOT_DIR")

docker build "${BUILD_ARGS[@]}"

log_info "Build complete: $IMAGE_NAME:$TAG"

# Push if requested
if [[ "$PUSH" == "true" ]]; then
  log_info "Pushing to registry..."
  docker push "$IMAGE_NAME:$TAG"
  log_info "Push complete"
fi

# Show image info
docker images "$IMAGE_NAME:$TAG" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
