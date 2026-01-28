#!/bin/bash
set -e

echo "usage: ./deploy-run.sh [docker|podman] PROJECT_NAME SERVICE_NAME"

ENGINE_INPUT=$1

if [ "$ENGINE_INPUT" == "podman" ]; then
    ENGINE="podman"
    COMPOSE="podman-compose"
    shift # Remove engine from argument list so $1 becomes PROJECT_NAME
elif [ "$ENGINE_INPUT" == "docker" ]; then
    ENGINE="docker"
    COMPOSE="docker-compose"
    shift
else
    # Auto-detect logic as fallback
    if command -v podman &> /dev/null; then
        ENGINE="podman"; COMPOSE="podman-compose"
    else
        ENGINE="docker"; COMPOSE="docker-compose"
    fi
fi

echo "Using Engine: $ENGINE"
# 'source' ensures the exports stay in the current process
source .setenv.sh "$1" "$2"

echo "Building with Node: $NODE_VERSION and Tomcat: $TOMCAT_VERSION"

# Pass secrets into the Docker Build
#$ENGINE build \
#  --build-arg NODE_VERSION=$NODE_VERSION \
#  --build-arg TOMCAT_VERSION=$TOMCAT_VERSION \
#  -t my-app-builder .

echo "--- Cleaning up old containers ---"
$COMPOSE -f docker-compose.yaml down --remove-orphans

echo "--- 5. Standing up Local Tomcat ---"
$COMPOSE -f docker-compose.yaml up -d  \
  --build-arg NODE_VERSION=$NODE_VERSION \
  --build-arg TOMCAT_VERSION=$TOMCAT_VERSION \
  --build

echo "--------------------------------------------------------"
echo "Success! Web app: http://localhost:8080/app-context"
echo "Config Path: /app/config/application.properties"
echo "--------------------------------------------------------"
#$COMPOSE logs -f
#$COMPOSE -f docker-compose.yaml logs -f