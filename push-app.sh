#!/bin/bash
set -x
source .env
docker build -t "sashetov/gym-data-tracker-app:v$VERSION" .
docker tag "sashetov/gym-data-tracker-app:v${VERSION}" "927315517716.dkr.ecr.us-west-2.amazonaws.com/seshsrepo:gym-data-tracker-app-v${VERSION}"
docker push  927315517716.dkr.ecr.us-west-2.amazonaws.com/seshsrepo:gym-data-tracker-app-v$VERSION
envsubst < k8s/webapp-deployment.yaml | kubectl apply -f -
