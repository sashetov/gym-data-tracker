#!/bin/bash
. .env
set -xv
APP_NS=gym-data-tracker
eksctl create cluster --name eks-cluster --region us-west-2 --nodegroup-name nodesgroup --node-type t3.medium --nodes 3
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install $APP_NS prometheus-community/kube-prometheus-stack
kubectl patch secret "$APP_NS-grafana" -n default --type='json' -p='[{"op": "replace", "path": "/data/admin-password", "value":"'$(printf $GRAFANA_PASS | base64)'"}]'
kubectl delete pods -l 'app.kubernetes.io/name=grafana' # delete it to restart and pick up new secret
kubectl patch svc gym-data-tracker-grafana -p '{"spec": {"type": "LoadBalancer"}}'
kubectl patch svc gym-data-tracker-kube-prom-prometheus -p '{"spec": {"type": "LoadBalancer"}}'
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 927315517716.dkr.ecr.us-west-2.amazonaws.com
docker build -t sashetov/gym-data-tracker-app:v1 .
docker tag sashetov/gym-data-tracker-app:v1 927315517716.dkr.ecr.us-west-2.amazonaws.com/seshsrepo:gym-data-tracker-app-v1
docker push  927315517716.dkr.ecr.us-west-2.amazonaws.com/seshsrepo:gym-data-tracker-app-v1
kubectl apply -f k8s/webapp-deployment.yaml \
              -f k8s/webapp-service.yaml \
              -f k8s/webapp-service-monitor.yaml \
              -f k8s/webapp-pod-monitor.yaml
sleep 120 # sleep for DNS
curl -X POST -H "Content-Type: application/json" -d @grafana/app-containers-dashboard.json "http://admin:${GRAFANA_PASS}@$(kubectl get svc gym-data-tracker-grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/api/dashboards/db"
