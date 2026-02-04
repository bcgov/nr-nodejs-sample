
#!/bin/bash

ENGINE=${1:-podman}
IMAGE_NAME="nodejs-tomcat-local"
CONTAINER_NAME="nodejs-tomcat-app"

GH_REGISTRY="ghcr.io"
TAG="63-merge"
DEFAULT_ARTIFACT="ghcr.io/bcgov/nr-nodejs-sample/nodejs-sample:$TAG"

# Deployment mode: "local" or "oras" (default: oras)
DEPLOY_MODE=${DEPLOY_MODE:-oras}
DEPLOY_MODE="local"
ARTIFACT_URL=${ARTIFACT_URL:-$DEFAULT_ARTIFACT}

if [ -f "./.setenv.sh" ]; then
    source ./.setenv.sh
else
    echo "Error: setenv.sh not found. Cannot retrieve secrets."
    exit 1
fi

echo "📋 Deployment mode: $DEPLOY_MODE"

echo "🧹 Cleaning up old containers and images..."
$ENGINE stop $CONTAINER_NAME 2>/dev/null || true
$ENGINE rm $CONTAINER_NAME 2>/dev/null || true
$ENGINE rmi $IMAGE_NAME 2>/dev/null || true


echo "🚀 Starting $ENGINE container..."

# Check if we need GitHub registry login for oras mode
if [ "$DEPLOY_MODE" = "oras" ]; then
    if ! $ENGINE login --check $GH_REGISTRY >/dev/null 2>&1; then
        if [ ! -f "${XDG_RUNTIME_DIR}/containers/auth.json" ]; then
            echo "❌ Not logged into $GH_REGISTRY. Please run: $ENGINE login $GH_REGISTRY"
            exit 1
        fi
    fi
fi

echo "📦 Building container image..."

if ! $ENGINE build -f Dockerfile.oras -t $IMAGE_NAME  .; then
    echo "Error: Failed to build container image"
    exit 1
fi
echo "✓ Image built successfully"

# Prepare volume mounts based on deployment mode
VOLUME_MOUNTS=""
if [ "$DEPLOY_MODE" = "oras" ]; then
    # Mount Docker config for oras pull authentication
    VOLUME_MOUNTS="-v ${XDG_RUNTIME_DIR}/containers/auth.json:/root/.docker/config.json:Z"
elif [ "$DEPLOY_MODE" = "local" ]; then
    # Mount local source code
    LOCAL_SRC_PATH=${LOCAL_SRC_PATH:-$(pwd)}
    VOLUME_MOUNTS="-v $LOCAL_SRC_PATH:/local_app:Z"
    echo "📁 Mounting local path: $LOCAL_SRC_PATH"
fi

$ENGINE run -d \
    --name $CONTAINER_NAME \
    $VOLUME_MOUNTS \
    -e DEPLOY_MODE="$DEPLOY_MODE" \
    -e ARTIFACT_URL="$ARTIFACT_URL" \
    -p 3000:3000 \
    --env-file <(env) \
    $IMAGE_NAME
    
echo ""
echo "✓ Container started successfully"
echo "✅ Done! Nodejs Application will be available at http://localhost:3000"
echo "Log check: $ENGINE logs -f $CONTAINER_NAME"