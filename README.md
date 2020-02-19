# octank-promo

Bare-bones Spring Boot microservice used for demo purposes. Not supported - no warranty explicit or implied.

API checks whether the coupon code applied at checkout is valid and applies to the products in the user's cart.

Example cart data POST input:
```json
{
    "cartId": "208474",
    "productId": "12345",
    "quantity": "9",
    "couponId": "10000"
}
```

Example API response:
```json
{
    "responseObject": {
        "couponValid": "true",
        "productId": "12345",
        "cartId": "1234",
        "productEligible": "true",
        "discountAmount": "0.25",
        "couponId": "10000"
    }
}
```

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
-X POST --data '{"cartId": "208474", "productId": "12345", "quantity": "9", "couponId": "10000"}' "http://localhost:8080/promotion/"
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

# Define coupon and product arrays
couponsArr=(10000 10001 10002 10003 10004 10005 10006 10007 10008 10009);
productsArr=(20000 20001 20002 20003 20004);

# Seed random generator
RANDOM=$$$(date +%s)

# Run API call loop
x=0;
while [ $x -le $1 ];
do
    selectedCoupon=${couponsArr[$RANDOM % ${#couponsArr[@]}]};
    selectedProduct=${productsArr[$RANDOM % ${#productsArr[@]}]};
    curl -w "\n" -H "Accept: application/json" -H "Content-Type:application/json" -X POST --data '{"cartId": "TestUserCart", "productId": "'$selectedProduct'", "quantity": "1", "couponId": "'$selectedCoupon'"}' "http://localhost:8080/promotion/" &
    echo " ";
    x=$(( $x + 1 ));
done
```

## Warm the cache:
```bash
curl -w "\n" "http://localhost:8080/promotion/warmCache/";
```