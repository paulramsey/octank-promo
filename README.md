# octank-promo

Bare-bones Spring Boot microservice used for demo purposes. Not supported - no warranty explicit or implied.

## Pre-requisites
- Install Maven and Java 8
- Install and configure AWS CLI 
- Clone repo
- Update `<aws-account-number>` with your real AWS account number in the deploy steps below and in `./deploy/kubernetes/ecr-login.sh`. Change the AWS region throughout if desired.

## Run locally via Maven
- From project root, run: `./mvnw spring-boot:run`
- Navigate to: `http://localhost:8080/promotion/`

## Build Docker container 
- From project root, run: `./mvnw clean package && docker build --tag=promotion .`

## Run locally via Docker with Wildfly
- Run: `docker run -it -p 8080:8080 promotion`  
- Navigate to: `http://localhost:8080/promotion/`

## Deploy to Kubernetes with Wildfly
- Push image to ECR:  
`$(aws ecr get-login --no-include-email --region us-east-2)`  
`docker tag promotion:latest <aws-account-number>.dkr.ecr.us-east-2.amazonaws.com/promotion:latest`  
`docker push <aws-account-number>.dkr.ecr.us-east-2.amazonaws.com/promotion:latest` 
- Deploy to K8s cluster:  
`./deploy/kubernetes/ecr-login.sh`   
`kubectl apply -f deploy/kubernetes/kube-deploy.yaml`
- Navigate to: `http://localhost:30001/promotion/`

## Example POST call:
```bash
curl -i \
-H "Accept: application/json" \
-H "Content-Type:application/json" \
-X POST --data '{"cartId": "1234", "productId": "5678", "quantity": "9", "couponId": "abcd"}' "http://localhost:8080/promotion/"
```

## Generate some load:
- Place the script below in a file called `promotion-generate-load.sh`.
- Call the script with a single argument that defines how many times to call the service: `./promotion-generate-load.sh 1000`

```bash
#!/bin/bash

if [ $# -eq 0 ]
then
   echo "Error: You must provide an interger in position 1 to indicate the number of calls the script should make to the promotion service."
   exit
fi

x=0;
while [ $x -le $1 ];
do
   curl http://promo:8080/promotion/;
   echo " ";
   x=$(( $x + 1 ));
done
```