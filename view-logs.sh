#!/bin/bash

# Get the latest log stream
LATEST_STREAM=$(aws logs describe-log-streams \
  --log-group-name "/aws/lambda/lambda-api-function" \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)

echo "Viewing logs from: $LATEST_STREAM"
echo "------------------------------"

# Check if --full flag is provided
if [[ "$1" == "--full" ]]; then
  # Full logs but simplified
  aws logs get-log-events \
    --log-group-name "/aws/lambda/lambda-api-function" \
    --log-stream-name "$LATEST_STREAM" \
    --output text \
    --query 'events[*].message' | \
    grep -v "START\|END\|REPORT" | \
    grep -v "multiValue\|isBase64Encoded\|requestContext\|identity" | \
    sed 's/.*INFO[[:space:]]\+//'
else
  # Super simple logs - just the essentials
  echo "API REQUESTS:"
  aws logs get-log-events \
    --log-group-name "/aws/lambda/lambda-api-function" \
    --log-stream-name "$LATEST_STREAM" \
    --output text \
    --query 'events[*].message' | \
    grep "HTTP method\|Path:" | \
    sed 's/.*INFO[[:space:]]\+//'

  echo -e "\nERRORS (if any):"
  aws logs get-log-events \
    --log-group-name "/aws/lambda/lambda-api-function" \
    --log-stream-name "$LATEST_STREAM" \
    --output text \
    --query 'events[*].message' | \
    grep -i "error" | \
    sed 's/.*INFO[[:space:]]\+//'
fi

echo -e "\n------------------------------"
echo "For more details: ./view-logs.sh --full" 