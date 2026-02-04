#!/bin/bash
set -e

DEPLOY_MODE=${DEPLOY_MODE:-oras}
DEPLOY_DIR="/app"

echo "📋 Deployment mode: $DEPLOY_MODE"

if [ "$DEPLOY_MODE" = "oras" ]; then
    echo "📦 Pulling artifact from GitHub registry..."
    if [ -z "$ARTIFACT_URL" ]; then
        echo "❌ Error: ARTIFACT_URL not set for oras mode"
        exit 1
    fi
    
    oras pull "$ARTIFACT_URL" -o /tmp/app_package
    
    mkdir -p "$DEPLOY_DIR"
    cp -r /tmp/app_package/dist "$DEPLOY_DIR/" 2>/dev/null || echo "⚠️  No dist folder in artifact"
    cp -r /tmp/app_package/node_modules "$DEPLOY_DIR/" 2>/dev/null || echo "⚠️  No node_modules in artifact"
    cp /tmp/app_package/package.json "$DEPLOY_DIR/" 2>/dev/null || true
    
    echo "✓ Artifact pulled and extracted"

elif [ "$DEPLOY_MODE" = "local" ]; then
    echo "📁 Using local source code..."
    
    if [ ! -d "/local_app" ]; then
        echo "❌ Error: /local_app not mounted. Please mount your local source."
        exit 1
    fi
    
    mkdir -p "$DEPLOY_DIR"
    
    # Copy source files
    cp -r /local_app/* "$DEPLOY_DIR/" 2>/dev/null || true
    
    cd "$DEPLOY_DIR"
    
    # Install dependencies if needed
    if [ ! -d "node_modules" ]; then
        echo "📦 Installing dependencies..."
        npm install
    fi
    
    # Build if needed
    if [ ! -d "dist" ]; then
        echo "🔨 Building application..."
        npm run build
    fi
    
    echo "✓ Local deployment ready"
else
    echo "❌ Error: Invalid DEPLOY_MODE '$DEPLOY_MODE'. Use 'local' or 'oras'"
    exit 1
fi

cd "$DEPLOY_DIR"
echo "🚀 Starting Node.js application..."
exec node dist/main.js