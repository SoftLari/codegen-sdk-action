#!/bin/bash

# Function to set GitHub Actions output
set_output() {
  local name=$1
  local value=$2
  if [[ -n "$GITHUB_OUTPUT" ]]; then
    echo "$name=$value" >> $GITHUB_OUTPUT
  fi
}

# Get inputs from environment variables
ORG_ID="${INPUT_ORG_ID}"
TOKEN="${INPUT_TOKEN}"
PROMPT="${INPUT_PROMPT}"
BASE_URL="${INPUT_BASE_URL:-https://api.codegen.com}"
WAIT_FOR_COMPLETION="${INPUT_WAIT_FOR_COMPLETION:-true}"
TIMEOUT_SECONDS="${INPUT_TIMEOUT_SECONDS:-300}"

# Validate required inputs
if [ -z "$ORG_ID" ]; then
  echo "Error: Organization ID is required"
  exit 1
fi

if [ -z "$TOKEN" ]; then
  echo "Error: API token is required"
  exit 1
fi

if [ -z "$PROMPT" ]; then
  echo "Error: Prompt is required"
  exit 1
fi

# Ensure BASE_URL doesn't end with a slash
BASE_URL="${BASE_URL%/}"

# Create the API endpoint URL
API_URL="${BASE_URL}/v1/organizations/${ORG_ID}/agent/run"

echo "Running Codegen agent with prompt: $PROMPT"

# Make the API call using curl
RESPONSE=$(curl --silent --request POST \
  --url "$API_URL" \
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/json" \
  --data "{\"prompt\": \"$PROMPT\"}")

# Check if curl command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to make API request"
  exit 1
fi

# Extract task ID and status from response
TASK_ID=$(echo $RESPONSE | jq -r '.id // empty')
STATUS=$(echo $RESPONSE | jq -r '.status // empty')

# Check if we got a valid task ID
if [ -z "$TASK_ID" ]; then
  echo "Error: Failed to get task ID from response"
  echo "Response: $RESPONSE"
  exit 1
fi

# Set outputs
set_output "task_id" "$TASK_ID"
set_output "status" "$STATUS"

echo "Task created with ID: $TASK_ID"
echo "Initial status: $STATUS"

# Wait for completion if requested
if [ "$WAIT_FOR_COMPLETION" = "true" ]; then
  START_TIME=$(date +%s)
  END_TIME=$((START_TIME + TIMEOUT_SECONDS))
  
  while [ "$(date +%s)" -lt "$END_TIME" ]; do
    if [ "$STATUS" = "completed" ] || [ "$STATUS" = "failed" ] || [ "$STATUS" = "error" ]; then
      break
    fi
    
    echo "Waiting for task completion... Current status: $STATUS"
    sleep 10
    
    # Poll for task status
    TASK_RESPONSE=$(curl --silent --request GET \
      --url "${BASE_URL}/v1/organizations/${ORG_ID}/agent/tasks/${TASK_ID}" \
      --header "Authorization: Bearer $TOKEN")
    
    STATUS=$(echo $TASK_RESPONSE | jq -r '.status // empty')
  done
  
  # Final status after waiting
  echo "Final status: $STATUS"
  set_output "status" "$STATUS"
  
  # If completed, set the result
  if [ "$STATUS" = "completed" ]; then
    RESULT=$(echo $TASK_RESPONSE | jq -r '.result // empty')
    echo "Task completed with result: $RESULT"
    set_output "result" "$RESULT"
  elif [ "$STATUS" = "failed" ] || [ "$STATUS" = "error" ]; then
    echo "Task failed or errored"
    exit 1
  else
    echo "Task did not complete within the timeout period"
    exit 1
  fi
fi

