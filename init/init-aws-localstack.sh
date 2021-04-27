#!/bin/bash
set -x

export API_NAME="OCRemix API"
export REGION="us-east-1"
export LOCALSTACK_HOST="http://localhost:4566"

echo "API Name: ", ${API_NAME}
echo "Region: ", ${REGION}
echo "LOCALSTACK_HOST: ", $LOCALSTACK_HOST

# Configure AWS CLI
aws configure set default.region $REGION
aws configure set aws_access_key_id 'YOUR_ACCESS_KEY'
aws configure set aws_secret_access_key 'YOUR_SECRET_KEY'

# Create S3 bucket
aws --endpoint-url http://localhost:4566 s3api create-bucket \
  --bucket ocremix-raw

# List Buckets
aws --endpoint-url http://localhost:4566 s3api list-buckets

# Create a topic
aws --endpoint-url http://localhost:4566 sns create-topic \
  --name ocremix-create-raw-html-file-events

aws --endpoint-url http://localhost:4566 sns create-topic \
  --name ocremix-parsed-file-info

aws --endpoint-url http://localhost:4566 sns create-topic \
  --name ocremix-parsed-file-info-dlq

# List Topics
aws --endpoint-url http://localhost:4566 sns list-topics

# Create SNS Notification for a PUT operation
aws --endpoint-url http://localhost:4566 s3api put-bucket-notification-configuration \
  --bucket ocremix-raw \
  --notification-configuration file:///docker-entrypoint-initaws.d/ocremix-create-file-event-configuration.json

# List S3 Notifications
aws --endpoint-url http://localstack:4566 s3api get-bucket-notification-configuration \
  --bucket ocremix-raw

# Create a Queue
aws --endpoint-url http://localhost:4566 sqs create-queue \
    --queue-name ocremix-new-file
aws --endpoint-url http://localhost:4566 sqs create-queue \
    --queue-name ocremix-parsed-file-info

# List Queue
aws --endpoint-url http://localhost:4566 sqs list-queues

# Subscribe SQS to SNS
aws --endpoint-url http://localhost:4566 sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:ocremix-create-raw-html-file-events \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/000000000000/ocremix-new-file

aws --endpoint-url http://localhost:4566 sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:ocremix-parsed-file-info \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/000000000000/ocremix-parsed-file-info

# List Subscriptions
aws --endpoint-url http://localhost:4566 sns list-subscriptions

# Create Lambda - To Be Continued
#aws --endpoint-url http://localhost:4566 lambda create-function \
#  --function-name ocremix-parse-html \
#  --runtime python3.8 \
#  --role local

# Create API Gateway

if ! aws --endpoint-url http://localhost:4566 apigateway create-rest-api --name "$API_NAME";
then
  fail 2 "Failed: AWS / apigateway / create-rest-api"
fi

# Get the returned API Id and Parent Resource Id returned from the command
API_ID=$(aws --endpoint-url $LOCALSTACK_HOST apigateway get-rest-apis --query "items[?name==\`${API_NAME}\`].id" --output text --region ${REGION})
PARENT_RESOURCE_ID=$(aws --endpoint-url $LOCALSTACK_HOST apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/`].id' --output text --region ${REGION})

if ! aws apigateway create-resource \
    --endpoint-url ${LOCALSTACK_HOST} \
    --region ${REGION} \
    --rest-api-id ${API_ID} \
    --parent-id ${PARENT_RESOURCE_ID} \
    --path-part "ocremix";
then
  fail 3 "Failed: AWS / apigateway / create-resource"
fi

RESOURCE_ID=$(aws --endpoint-url $LOCALSTACK_HOST apigateway get-resources --rest-api-id ${API_ID} --query 'items[?path==`/ocremix`].id' --output text --region ${REGION})
echo "Resource ID: ", "$RESOURCE_ID"
# Add GET method
aws apigateway put-method \
    --endpoint-url ${LOCALSTACK_HOST} \
    --region ${REGION} \
    --rest-api-id "${API_ID}" \
    --resource-id "${RESOURCE_ID}" \
    --http-method GET \
    --request-parameters "method.request.path.somethingId=true" \
    --authorization-type "NONE"

set +x