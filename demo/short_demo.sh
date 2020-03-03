
################# PRE-REQUISITES #################

# Scale down ASG to 3 

# Scale jumpbox to 2
kubectl scale deployment/jumpbox --replicas 2 -n sock-shop

# Delete and redeploy promotion and tax-calc
#kubectl delete horizontalpodautoscaler.autoscaling/promotion -n sock-shop
#kubectl delete -f /repos/octank-promo/deploy/kubernetes/kube-deploy.yaml
#kubectl apply -f /repos/octank-promo/deploy/kubernetes/kube-deploy.yaml
#kubectl autoscale deployment promotion -n sock-shop --cpu-percent=50 --min=1 --max=50
kubectl delete horizontalpodautoscaler.autoscaling/tax-calc -n sock-shop
kubectl delete -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl apply -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl autoscale deployment tax-calc -n sock-shop --cpu-percent=50 --min=1 --max=50
kubectl get pods -n sock-shop

# Open PowerPoint

# Open iTerm windows with 4 panes for autoscaling and availability demos

# Sign in to Isengard 

# Stage commands in iTerm for autoscaling and availability demos

# Load WeaveWorks demo and GitHub pages
open -a "Google Chrome" http://12345a23-sockshop-sockshop-4811-452346809.us-east-2.elb.amazonaws.com https://github.com/paulramsey/octank-tax-calc https://github.com/paulramsey/octank-promo https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details 

# Load Container Insights and X-Ray
open -a "Google Chrome" "https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#cw:dashboard=Container;context=~(clusters~'octankube~dimensions~(~)~performanceType~'Service)" "https://us-east-2.console.aws.amazon.com/xray/home?region=us-east-2#/service-map"

# Maximize windows to prevent distraction


################# INTRO #################

# Go over the AWS architecture

# Show site running
# Highlight that this is built on micro services and accessed through ALB to K8s Ingress to EKS pod
http://12345a23-sockshop-sockshop-4811-452346809.us-east-2.elb.amazonaws.com

<<< WINDOW - TOP LEFT >>>

# Show services running in EKS
kubectl get pods -n sock-shop

# Add item to cart. 
# Show coupon and tax functionality stubbed/not working.


################# TIME TO MARKET #################

You need small services so that you can reduce dependencies on loosely-related functionality and release more frequently.

# Show tax-calc and promotion GitHub - Point out JBoss (Wildfly) and Spring Boot
https://github.com/paulramsey/octank-tax-calc
https://github.com/paulramsey/octank-promo


<<< WINDOW - AD HOC >>>

# Show a sample POST call for both services
jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}' | head -n 1)
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh

curl -w "\n" \
   -H "Accept: application/json" \
   -H "Content-Type:application/json" \
   -X POST \
   --data '{"cartId": "TestUserCart", "productId": "10001", "quantity": "5", "subtotal": "108.11"}' \
   "http://tax:8080/tax-calc/"

curl -w "\n" -i \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST \
--data '{"cartId": "TestCartId", "productId": "20001", "quantity": "1", "couponId": "10001"}' "http://promo:8080/promotion/"




################# SCALABILITY AND INFRASTRUCTURE FLEXIBILITY #################

You need to scale Pods and nodes in response to load. You do this through an ASG. The ASG can run whatever instance type is appropriate for your workload. For the demo, we're using m5.large.

# Show current nodes in ASG
https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details


<<< WINDOW - TOP LEFT >>>

# Show current count of promotion pods in the deployment
kubectl get deployment tax-calc -n sock-shop


<<< WINDOW - TOP RIGHT >>>

# Watch the horizontal pod autoscaler
kubectl get hpa -n sock-shop --watch


<<< WINDOW - BOTTOM RIGHT >>>

# Watch the pods getting created
kubectl get pods -n sock-shop --watch


<<< WINDOW - BOTTOM LEFT >>>

jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}' | head -n 1)
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh


# Run some load
cd scripts/
./tax-calc-load.sh 500

# Show current nodes in ASG has grown
https://us-east-2.console.aws.amazon.com/ec2/autoscaling/home?region=us-east-2#AutoScalingGroups:id=eks-58b8188c-3b3f-43de-52d1-be18da0a6e2a;view=details


<<< WINDOW - TOP LEFT >>>

# Delete and redeploy tax-calc to prevent further scaling
kubectl delete horizontalpodautoscaler.autoscaling/tax-calc -n sock-shop
kubectl delete -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl apply -f /repos/octank-tax-calc/deploy/kubernetes/kube-deploy.yaml
kubectl autoscale deployment tax-calc -n sock-shop --cpu-percent=50 --min=1 --max=50

# Look at Container Insights metrics
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#cw:dashboard=Container;context=~(clusters~(~)~dimensions~(~)~performanceType~'ClusterName)

# Look at X-Ray metrics
https://us-east-2.console.aws.amazon.com/xray/home?region=us-east-2#/service-map




################# AVAILABILITY #################

You need to be sure that your application can sustain failure of the database and caching layers.


<<< WINDOW - TOP LEFT >>>
# Get into jumpbox
jumpbox=$(kubectl get pods -n sock-shop | grep jumpbox | awk '{print $1;}' | tail -n 1)
kubectl exec -it $jumpbox -n sock-shop -- /bin/sh

# If necessary, bring up another jumpbox for the next portion of the demo
kubectl scale deployment jumpbox --replicas 2 -n sock-shop
kubectl get pods -n sock-shop | grep jumpbox
kubectl exec -it <pod> -n sock-shop -- /bin/sh

# Run some load
cd scripts/
./promo-load.sh 5000


<<< WINDOW  - TOP RIGHT >>>

# Loop on database status 
while [ 1 == 1 ]
do
   aws rds describe-db-clusters --db-cluster-identifier octank-database --region us-east-2 --query 'DBClusters[*].DBClusterMembers[*].{ClusterNode:DBInstanceIdentifier, IsPrimary:IsClusterWriter'} --output table
   sleep 0.5
done;
 

<<< WINDOW - BOTTOM RIGHT >>>

#Loop on cache status
while [ 1 == 1 ]
do
   aws elasticache describe-replication-groups --replication-group-id octank-redis --region us-east-2 --query 'ReplicationGroups[*].NodeGroups[*].NodeGroupMembers[*].{ID:CacheClusterId, CurrentRole:CurrentRole}' --output table
   sleep 0.5
done;



<<< NEW WINDOW - BOTTOM LEFT>>> 

# Simulate database and caching failure
aws rds failover-db-cluster --db-cluster-identifier octank-database --region us-east-2 && aws elasticache test-failover --replication-group-id octank-redis --node-group-id 0001 --region us-east-2 




################# MONITORING #################

# Show logs
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#logs:prefix=/aws/containerinsights/octankube

# Show Container Insights
https://us-east-2.console.aws.amazon.com/cloudwatch/home?region=us-east-2#cw:dashboard=Container

# Show X-Ray
https://us-east-2.console.aws.amazon.com/xray/home?region=us-east-2#/service-map




################# COST #################

# Review cost spreadsheet




################# NEXT STEPS #################

# I'll share the GitHub links with you

# Immersion Day for your staff?

# Connect you with a partner?
