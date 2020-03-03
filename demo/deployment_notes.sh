# Deploy all services
kubectl apply -f /repos/microservices-demo/deploy/kubernetes/complete-demo.yaml
kubectl apply -f /Users/paramsey/Documents/Master Builder/MB3 Artifacts/jumpbox/deploy/jumpbox.yaml
kubectl apply -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl apply -f /repos/octank-promo/deploy/kubernetes/kube-deploy.yaml


# Deploy locally
cd /repos/microservices-demo/deploy/kubernetes/
kubectl apply -f /repos/microservices-demo/deploy/kubernetes/complete-demo.yaml

# Change Image
docker cp logo.png docker-compose_front-end_1:/usr/src/app/public/img/
docker cp logo-small.png docker-compose_front-end_1:/usr/src/app/public/img/

docker cp logo.png sleepy_lamport:/usr/src/app/public/img/
docker cp logo-small.png sleepy_lamport:/usr/src/app/public/img/



# Cleanup
kubectl delete daemonsets,replicasets,services,deployments,pods,rc --all --namespace=sock-shop



# Deploy on AWS

# Set cluster env
export CLUSTER_NAME="octankube" 
echo Cluster name is: $CLUSTER_NAME

# Set region env
export REGION="us-east-2"
echo Region is: $REGION

# Option 1: Create EKS cluster (with MANAGED nodes)
eksctl create cluster \
--name $CLUSTER_NAME \
--version 1.14 \
--managed \
--region $REGION \
--nodes-min 3 \
--nodes-max 10 \
--alb-ingress-access  \
--color true


# Option 2: Create EKS cluster (with nodes)
#eksctl create cluster \
#--name $CLUSTER_NAME \
#--version 1.14 \
#--region $REGION \
#--nodes 2

# Option 3: Create EKS cluster (fargate)
#eksctl create cluster \
#--name BlackBeardv1 \
#--version 1.14 \
#--region $REGION \
#--fargate



# Confirm the current context
kubectl config current-context

# Create sock-shop namespace
kubectl create namespace sock-shop




# Prep cluster for ALB
# Allow IAM Open ID Connect (OIDC) provider
eksctl utils associate-iam-oidc-provider --cluster=$CLUSTER_NAME --approve --region=$REGION

# Deploy RBAC roles and role bindings
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/rbac-role.yaml

# Create IAM Policy to allow ALB ingress controller to make AWS API calls
# Capture Policy.Arn for next step (i.e. arn:aws:iam::<aws_account>:policy/ALBIngressControllerIAMPolicy)
aws iam create-policy \
    --policy-name ALBIngressControllerIAMPolicy \
    --policy-document https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/iam-policy.json

# Get arn of ALBIngressControllerIAMPolicy
export PolicyARN=$(aws iam list-policies --query 'Policies[*].[Arn]' --output text | grep ALBIngressControllerIAMPolicy)
echo Policy arn is: $PolicyARN

# Create Service Account
eksctl create iamserviceaccount \
       --cluster=$CLUSTER_NAME \
       --namespace=kube-system \
       --name=alb-ingress-controller \
       --attach-policy-arn=$PolicyARN \
       --override-existing-serviceaccounts \
       --approve \
       --region=$REGION

# Deploy ALB ingress controller
curl -sS "https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.4/docs/examples/alb-ingress-controller.yaml" \
     | sed "s/# - --cluster-name=devCluster/- --cluster-name=$CLUSTER_NAME/g" \
     | kubectl apply -f -

# verify that the deployment was successful and the controller started
kubectl logs -n kube-system $(kubectl get po -n kube-system | egrep -o alb-ingress[a-zA-Z0-9-]+)

# Deploy the sock-shop stack
cd /repos/microservices-demo/deploy/kubernetes/
kubectl apply -f complete-demo.yaml

# Ensure sock-shop app is running
kubectl get pods -n sock-shop 

# Verify the ingress resource is created and get DNS (Takes a few minutes)
kubectl get ingress/sock-shop-ingress -n sock-shop



# Setup monitoring
#curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$CLUSTER_NAME/;s/{{region_name}}/$REGION/" | kubectl apply -f -

# Cleanup monitoring
#curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/$CLUSTER_NAME/;s/{{region_name}}/$REGION/" | kubectl delete -f -

# Create amazon-cloudwatch namespace
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cloudwatch-namespace.yaml

# Create cluster service account
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-serviceaccount.yaml

# Create config map
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-configmap.yaml | sed "s/{{cluster_name}}/$CLUSTER_NAME/;s/{{region_name}}/$REGION/" | kubectl apply -f -

# Get node role name
export ROLE_NAME=$(aws iam list-roles --region=$REGION --query 'Roles[*].[RoleName]' --output text | grep eksctl-$CLUSTER_NAME-nodegroup-ng.*NodeInstanceRole)
echo Role name is: $ROLE_NAME

# Get CloudWatchFullAccess policy ARN
export CW_POLICY_NAME=$(aws iam list-policies --query 'Policies[*].[Arn]' --output text | grep CloudWatchFullAccess) 
echo Cloudwatch Policy Name is: $CW_POLICY_NAME


# Attach CloudWatchFullAccess policy to role eksctl-$CLUSTER_NAME-nodegroup-ng-NodeInstanceRole-*
aws iam attach-role-policy --policy-arn $CW_POLICY_NAME --role-name $ROLE_NAME

# Deploy cloudwatch agent as a DaemonSet
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-daemonset.yaml

# Cleanup DaemonSet
#kubectl delete -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/cwagent-kubernetes-monitoring/cwagent-daemonset.yaml

# Verify cloudwatch agent pod is deployed
kubectl get pods -n amazon-cloudwatch

# Check the events at the bottom of the output.
kubectl describe pod <pod-name> -n amazon-cloudwatch

# Check the logs.
kubectl logs <pod-name>  -n amazon-cloudwatch

# Setup fluentd
kubectl create configmap cluster-info \
--from-literal=cluster.name=$CLUSTER_NAME \
--from-literal=logs.region=$REGION -n amazon-cloudwatch

# Deploy fluentd as a DaemonSet
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/master/k8s-yaml-templates/fluentd/fluentd.yaml

# Ensure fluentd pods are running
kubectl get pods -n amazon-cloudwatch

# Check Pod logs.
kubectl logs <pod-name> -n amazon-cloudwatch

# Check cloudwatch logs (/host /dataplane /performance are CI, /application is fluent)
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logs:prefix=/aws/containerinsights/octankube

# View Container Insights
https://console.aws.amazon.com/cloudwatch/home?region=us-east-2#cw:dashboard=Container



# Setup horizontal autoscaling
# install Helm
curl -sSL https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Add helm stable repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm search repo stable

# Configure helm bash completion
helm completion bash >> ~/.bash_completion
. /etc/profile.d/bash_completion.sh
. ~/.bash_completion
source <(helm completion bash)

# Install the Metrics server
kubectl create namespace metrics

helm install metrics-server \
    stable/metrics-server \
    --version 2.9.0 \
    --namespace metrics

# Configure autoscaling for tax-calc
kubectl autoscale deployment tax-calc -n sock-shop --cpu-percent=50 --min=1 --max=100
# Delete HPA
kubectl delete horizontalpodautoscaler.autoscaling/tax-calc -n sock-shop



# Setup CI/CD
ACCOUNT_ID=<account_id>

# Add role for pipeline to interact with EKS

TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"

echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-role-policy

aws iam create-role --role-name EksWorkshopCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'

aws iam put-role-policy --role-name EksWorkshopCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy


# Add role to the aws-auth ConfigMap
ROLE="    - rolearn: arn:aws:iam::$ACCOUNT_ID:role/EksWorkshopCodeBuildKubectlRole\n      username: build\n      groups:\n        - system:masters"

kubectl get -n kube-system configmap/aws-auth -o yaml | awk "/mapRoles: \|/{print;print \"$ROLE\";next}1" > /tmp/aws-auth-patch.yml

kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"