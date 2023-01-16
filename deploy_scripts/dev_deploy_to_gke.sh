#!/bin/bash

# Delete old 1.0 image from gcr
echo "y" | gcloud container images delete gcr.io/fitcentive-dev/chat:1.0 --force-delete-tags

# Remove existing local docker images
docker image rm gcr.io/fitcentive-dev/chat:1.0
docker image rm gcr.io/fitcentive-dev/chat

# Build and push image to gcr
docker build -t gcr.io/fitcentive-dev/chat:latest -t gcr.io/fitcentive-dev/chat:1.0 ../.
docker push gcr.io/fitcentive-dev/chat:1.0

kubectl apply -f deployment/gke-dev-env/