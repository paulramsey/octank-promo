
################# INTRO #################

# BRIEFLY go over the architecture

# We're running in us-east-2 (Ohio), same state as their current hot datacenter

# Show site running
# Highlight that this is built on micro services and accessed through ALB to K8s Ingress to EKS pod
http://12345a23-sockshop-sockshop-4811-452346809.us-east-2.elb.amazonaws.com

# Sock Shop Architecture diagram in case they're interested
https://github.com/microservices-demo/microservices-demo/blob/master/internal-docs/design.md

# Show services running in EKS
kubectl get pods -n sock-shop

# Show ingress address that maps to ALB
kubectl get ingress -n sock-shop

# Add item to cart. 
# Show coupon and tax functionality stubbed/not working.

# Show tax-calc GitHub - Point out JBoss (Wildfly) and Spring Boot
https://github.com/paulramsey/octank-tax-calc


################# HORIZONTAL SCALING #################

# Deploy tax-calc service - Show that we're pulling images from ECR
kubectl apply -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl get -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl describe deployment tax-calc -n sock-shop

# Show a sample POST call
jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}')
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh

curl -w "\n" \
   -H "Accept: application/json" \
   -H "Content-Type:application/json" \
   -X POST \
   --data '{"cartId": "TestUserCart", "productId": "10001", "quantity": "5", "subtotal": "108.11"}' \
   "http://tax:8080/tax-calc/"

# Show current count of tax-calc pods in the deployment
kubectl get deployment tax-calc -n sock-shop

# Add HPA (already installed metrics server, 
kubectl autoscale deployment tax-calc -n sock-shop --cpu-percent=50 --min=1 --max=100
kubectl describe horizontalpodautoscaler.autoscaling/tax-calc -n sock-shop

# Show current nodes in ASG
https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details

# Run load to stress system
jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}')
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh

# Test one call to make sure it works
cd scripts/
./tax-calc-load.sh 0

# Run load
./tax-calc-load.sh 20000

# Spin up new window to watch the scaling
kubectl get hpa -n sock-shop --watch

# Spin up another new window to watch the pods
kubectl get pods -n sock-shop --watch

# Look at X-Ray metrics
https://us-east-2.console.aws.amazon.com/xray/home?region=us-east-2#/service-map

# Look at Container Insights metrics
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#cw:dashboard=Container


################# VERTICAL SCALING #################

# Show pending replicas preventing us from full scale-out
kubectl get pods -n sock-shop | grep Pending
pendingpod=$(kubectl get pods -n sock-shop | grep Pending | awk '{print $1;}')
kubectl describe pod $pendingpod -n sock-shop 

# Enable cluster autoscaling (This manifest, the metrics server, and an ASG inline policy are required for this to work)
#kubectl apply -f /Users/paramsey/Documents/Master\ Builder/MB3\ Artifacts/jumpbox/cluster-autoscaler.yaml 

# Look at autoscaling group to show increase in nodes
https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details

# If it is failing, try reinstalling the metrics server:
helm repo update
helm upgrade --install metrics-server \
    stable/metrics-server \
    --version 2.9.0 \
    --namespace metrics
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml



################# AVAILABILITY #################

# Delete deployment tax-calc if necessary
kubectl delete deployment tax-calc -n sock-shop

# Add HPA
kubectl autoscale deployment promotion -n sock-shop --cpu-percent=50 --min=1 --max=100
kubectl describe horizontalpodautoscaler.autoscaling/promotion -n sock-shop

# Show current nodes in ASG
https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details

# Show current count of tax-calc pods in the deployment
kubectl get deployment tax-calc -n sock-shop

# Spin up new window to watch the scaling
kubectl get hpa -n sock-shop --watch

# Spin up another new window to watch the pods
kubectl get pods -n sock-shop --watch


# Show the promotion service GitHub
https://github.com/paulramsey/octank-promo

# Deploy the promotion service
cd /repos/octank-promo
deploy/deploy.sh 

# Bring up another jumpbox for the next portion of the demo
kubectl scale deployment jumpbox --replicas 2 -n sock-shop
kubectl get pods -n sock-shop | grep jumpbox
kubectl exec -it <pod> -n sock-shop -- /bin/sh

# Run a sample call
curl -w "\n" -i \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST \
--data '{"cartId": "TestCartId", "productId": "20001", "quantity": "1", "couponId": "10001"}' "http://promo:8080/promotion/"

# Run some load
cd scripts/
./promo-load.sh 20000

# Loop on status 
while [ 1 == 1 ]
do
   aws rds describe-db-clusters --db-cluster-identifier octank-database-1 --region us-east-2 --query 'DBClusters[*].DBClusterMembers[*].{ClusterNode:DBInstanceIdentifier, IsPrimary:IsClusterWriter'} --output table
   sleep 0.5
done; 

# Simulate database failure
aws rds failover-db-cluster --db-cluster-identifier octank-database-1 --region us-east-2

# Show snapshot in another region

# Enable the cache for the next portion of the demo by updating the code

# Show code pipeline running

################# VISIBILITY #################

# Show logs
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logs:prefix=/aws/containerinsights/octankube


################# AVAILABILITY PART 2 #################

# Show code pipeline complete

# Show tag matches GitHub commit sha
kubectl describe deployment promotion -n sock-shop

# Run some load
cd scripts/
./promo-load.sh 300

# Simulate caching layer failure
# In another window, Loop on status
while [ 1 == 1 ]
do
   aws elasticache describe-replication-groups --replication-group-id octank-redis --region us-east-2 --query 'ReplicationGroups[*].NodeGroups[*].NodeGroupMembers[*].{ID:CacheClusterId, CurrentRole:CurrentRole}' --output table
   sleep 0.5
done;

# In another window, execute failover
aws elasticache test-failover --replication-group-id octank-redis --node-group-id 0001 --region us-east-2 



################# PERFORMANCE #################

# Get into jump box
jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}')
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh

# Flush the cache
redis-cli -h octank-redis.fecgtm.ng.0001.use2.cache.amazonaws.com -p 6379
FLUSHALL

# Run some load
cd scripts/
./promo-load.sh 100

# Flush the cache again
redis-cli -h octank-redis.fecgtm.ng.0001.use2.cache.amazonaws.com -p 6379
FLUSHALL

# Warm the cache
curl -w "\n" "http://promo:8080/promotion/warmCache/";

# Warm the cache again
curl -w "\n" "http://promo:8080/promotion/warmCache/";

# View the difference in performance with cache warmed vs without
https://us-east-2.console.aws.amazon.com/xray/home?region=us-east-2#/service-map


################# SECURITY #################

# IAM is locking down permissions for what the EKS nodes can do

# Kubernetes RBAC is being used to control access to the k8s cluster via roles and role bindings

# Services are deployed in namespaces, which can act as logical security boundaries around which you can create roles and role bindings


################# DISASTER RECOVERY #################

# Copy snapshot to another region

# Create CFN scripts for resources





# Cleanup
kubectl delete horizontalpodautoscaler.autoscaling/tax-calc -n sock-shop
kubectl delete -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl delete -f /Users/paramsey/Documents/Master\ Builder/MB3\ Artifacts/jumpbox/cluster-autoscaler.yaml 
kubectl scale deployment jumpbox --replicas 1 -n sock-shop
kubectl delete -f /repos/octank-promo/deploy/kubernetes/kube-deploy.yaml

# Scale down jumpbox and scale back up to apply new image
kubectl scale deployment/jumpbox --replicas 0 -n sock-shop
kubectl scale deployment/jumpbox --replicas 1 -n sock-shop