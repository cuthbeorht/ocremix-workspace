#!/bin/bash
set -x

# Configure AWS CLI
aws configure set default.region us-east-1
aws configure set aws_access_key_id 'YOUR_ACCESS_KEY'
aws configure set aws_secret_access_key 'YOUR_SECRET_KEY'

# List Topics
aws --endpoint-url http://localhost:4566 sns list-topics

# Create a topic
aws --endpoint-url http://localhost:4566 sns create-topic \
    --name ocremix-raw-html

# Create a Queue
aws --endpoint-url http://localhost:4566 sqs create-queue \
    --queue-name ocremix-raw-html

# List Queueu
aws --endpoint-url http://localhost:4566 sqs list-queues

# Subscribe SQS to SNS
aws --endpoint-url http://localhost:4566 sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:ocremix-raw-html \
    --protocol sqs \
    --notification-endpoint http://localhost:4566/000000000000/ocremix-raw-html

# List Subscriptions
aws --endpoint-url http://localhost:4566 sns list-subscriptions

set +x