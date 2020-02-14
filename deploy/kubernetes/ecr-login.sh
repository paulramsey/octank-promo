# source: https://medium.com/@damitj07/how-to-configure-and-use-aws-ecr-with-kubernetes-rancher2-0-6144c626d42c
ACCOUNT=<aws-account-number>
REGION=us-east-2
SECRET_NAME=${REGION}-ecr-registry
EMAIL=dummy.email@email.com
TOKEN=`aws ecr get-login --region ${REGION} --registry-ids ${ACCOUNT} | cut -d' ' -f6`
NAMESPACE=sock-shop
echo "ENV variables setup done."
kubectl delete secret --ignore-not-found $SECRET_NAME -n $NAMESPACE
kubectl create secret docker-registry $SECRET_NAME -n $NAMESPACE \
--docker-server=https://${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com \
--docker-username=AWS \
--docker-password="${TOKEN}" \
--docker-email="${EMAIL}"
echo "Secret created by name. $SECRET_NAME"
kubectl patch serviceaccount default -p '{"imagePullSecrets":[{"name":"'$SECRET_NAME'"}]}' -n $NAMESPACE
echo "All done."
