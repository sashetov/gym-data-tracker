#!/bin/bash
. .env
set -xv
APP_NS=gym-data-tracker
CLUSTER_NAME=eks-cluster
eksctl create cluster --name $CLUSTER_NAME --region us-west-2 --nodegroup-name nodesgroup --node-type t3.medium --nodes 3
eksctl utils associate-iam-oidc-provider --cluster $CLUSTER_NAME --approve
eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster $CLUSTER_NAME \
    --role-name AmazonEKS_EBS_CSI_DriverRole \
    --role-only \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve
eksctl create addon --name aws-ebs-csi-driver --cluster $CLUSTER_NAME --service-account-role-arn arn:aws:iam::927315517716:role/AmazonEKS_EBS_CSI_DriverRole --force
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
kubectl create secret generic mysql-root-pass --from-literal=password=$MYSQL_ROOT_PASS

#MAKE DB + MONITOR
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=master"
until [[ $(kubectl get pods -n kube-system | grep ebs-csi | grep -vc Running) -eq 0 ]]; do echo "Waiting for ebs-csi pods to be running..."; sleep 5; done
VOLUME_ID=$(aws ec2 create-volume --size 10 --region us-west-2 --availability-zone us-west-2a --volume-type gp2 --query "VolumeId" --output text)
cp k8s/pv-template.yaml k8s/mysql-pv.yaml
sed -i "s/YOUR_VOLUME_ID_PLACEHOLDER/$VOLUME_ID/g" k8s/mysql-pv.yaml
kubectl apply -f k8s/mysql-pv.yaml
rm -f k8s/mysql-pv.yaml
kubectl apply -f k8s/mysql-pvc.yaml
cat <<EOF > k8s/.my.cnf
[client]
user=root
password=$MYSQL_ROOT_PASS
EOF
kubectl create configmap mysqld-exporter-config --from-file=k8s/.my.cnf -n default
rm -f k8s/.my.cnf
kubectl apply -f k8s/mysql-deployment.yaml \
    -f k8s/mysql-service.yaml \
    -f k8s/mysql-service-monitor.yaml 
timeout 60 bash -c 'while true; do if kubectl get pods --no-headers | grep "^mysql" | awk '"'"'{print $2}'"'"' | grep -vq "2/2"; then sleep 3; else exit 0; fi; done' || {
    echo "mysql pod not available, debug why"
    exit 1;
} # wait for mysql pod to become available
MY_POD=$(kubectl get pods --no-headers | grep "^mysql" | awk '{print $1}' | head -n 1)
kubectl exec -it $MY_POD -c mysql -- /usr/bin/mysql -u root -p"${MYSQL_ROOT_PASS}" -e "CREATE DATABASE IF NOT EXISTS gymdata;" # make the database

# make webapp + monitors
kubectl apply -f k8s/webapp-deployment.yaml \
              -f k8s/webapp-service.yaml \
              -f k8s/webapp-service-monitor.yaml \
              -f k8s/webapp-pod-monitor.yaml

# set up monitoring dashboards
sleep 120 # wait/sleep for DNS records to be set and propagate
curl -X POST -H "Content-Type: application/json" -d @grafana/app-containers-dashboard.json "http://admin:${GRAFANA_PASS}@$(kubectl get svc gym-data-tracker-grafana -o=jsonpath='{.status.loadBalancer.ingress[0].hostname}')/api/dashboards/db"
