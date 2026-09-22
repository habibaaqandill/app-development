#!/bin/bash
set -e

DOCKER_USER="habibaaqandill"
IMAGE_NAME="app-deployment-nginx"
NAMESPACE="habiba"
DEPLOYMENT="nginx-deployment"
GIT_BRANCH="main"

# Grab the currently running tag from K8s
CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
CURRENT_TAG=$(echo "$CURRENT_IMAGE" | awk -F':' '{print $2}')

# Parse version number and increment (e.g., v2.0 -> v3.0)
if [[ "$CURRENT_TAG" =~ ^v([0-9]+) ]]; then
    CURRENT_NUM="${BASH_REMATCH[1]}"
    NEXT_NUM=$((CURRENT_NUM + 1))
    TAG="v${NEXT_NUM}.0"
else
    TAG="v1.0"
fi

echo "--> Target version auto-set to: $TAG"
FULL_IMAGE="${DOCKER_USER}/${IMAGE_NAME}:${TAG}"

# Commit and push if inside a git repo
if [ -d .git ]; then
    git add .
    git commit -m "UI update version ${TAG}" || true
    git push origin ${GIT_BRANCH} || true
fi

# Build image from ./nginx folder
echo "--> Building Docker image: $FULL_IMAGE"
docker build -t $FULL_IMAGE ./nginx

# Push to Docker Hub
echo "--> Pushing image to Docker Hub"
docker push $FULL_IMAGE

# Strip volume mounts so Nginx serves files directly from inside the image
echo "--> Removing ConfigMap volume overrides"
kubectl patch deployment $DEPLOYMENT -n $NAMESPACE -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","volumeMounts":[]}],"volumes":[]}}}}' 2>/dev/null || true

# Apply new image and trigger rolling update
echo "--> Updating deployment image to $FULL_IMAGE"
kubectl set image deployment/$DEPLOYMENT nginx=$FULL_IMAGE -n $NAMESPACE

# Wait for rollout completion
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

echo "--> Rollout complete! Successfully deployed $TAG."
