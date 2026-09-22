#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH

cd /home/habiba/app-deployment
git fetch origin main >/dev/null 2>&1

LOCAL_SHA=$(git rev-parse HEAD)
REMOTE_SHA=$(git rev-parse origin/main)
if [ "$LOCAL_SHA" != "$REMOTE_SHA" ]; then
    echo "[$(date)] 🚀 New Git push detected! Deploying..." >> /home/habiba/app-deployment/cron-deploy.log
    git pull origin main >> /home/habiba/app-deployment/cron-deploy.log 2>&1
    /home/habiba/app-deployment/deploy.sh >> /home/habiba/app-deployment/cron-deploy.log 2>&1
fi
