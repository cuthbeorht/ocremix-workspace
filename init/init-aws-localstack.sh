#!/bin/bash
set -x

# Configure AWS CLI
aws configure set default.region us-east-1
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

# List Topics
aws --endpoint-url http://localhost:4566 sns list-topics

# Create SNS Notification for a PUT operation
aws --endpoint-url http://localhost:4566 s3api put-bucket-notification-configuration \
  --bucket ocremix-raw \
  --notification-configuration file:///docker-entrypoint-initaws.d/ocremix-create-file-event-configuration.json

# Create a Queue
aws --endpoint-url http://localhost:4566 sqs create-queue \
    --queue-name ocremix-new-file

# List Queue
aws --endpoint-url http://localhost:4566 sqs list-queues

# Subscribe SQS to SNS
aws --endpoint-url http://localhost:4566 sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:ocremix-create-raw-html-file-events \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/000000000000/ocremix-new-file

# List Subscriptions
aws --endpoint-url http://localhost:4566 sns list-subscriptions

# Create Lambda - To Be Continued
#aws --endpoint-url http://localhost:4566 lambda create-function \
#  --function-name ocremix-parse-html \
#  --runtime python3.8 \
#  --role local

set +x