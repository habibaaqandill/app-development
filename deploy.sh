#!/bin/bash
set -e

DOCKER_USER="habibaaqandill"
IMAGE_NAME="app-deployment-nginx"
NAMESPACE="habiba"
DEPLOYMENT="nginx-deployment"
GIT_BRANCH="main"

CURRENT_IMAGE=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
CURRENT_TAG=$(echo "$CURRENT_IMAGE" | awk -F':' '{print $2}')

if [[ "$CURRENT_TAG" =~ ^v([0-9]+) ]]; then
    CURRENT_NUM="${BASH_REMATCH[1]}"
    NEXT_NUM=$((CURRENT_NUM + 1))
    TAG="v${NEXT_NUM}.0"
else
    TAG="v1.0"
fi

echo "--> Target version auto-set to: $TAG"
FULL_IMAGE="${DOCKER_USER}/${IMAGE_NAME}:${TAG}"

#if [ -d .git ]; then
#    git add .
#    git commit -m "UI update version ${TAG}" || true
#    git push origin ${GIT_BRANCH} || true
#fi

echo "--> Building Docker image: $FULL_IMAGE"
docker build -t $FULL_IMAGE ./nginx

echo "--> Pushing image to Docker Hub"
docker push $FULL_IMAGE

#echo "--> Removing ConfigMap volume overrides"
#kubectl patch deployment $DEPLOYMENT -n $NAMESPACE -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","volumeMounts":[]}],"volumes":[]}}}}' 2>/dev/null || true

echo "--> Updating deployment image to $FULL_IMAGE"
kubectl set image deployment/$DEPLOYMENT nginx=$FULL_IMAGE -n $NAMESPACE

kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE

echo "--> Rollout complete! Successfully deployed $TAG."

