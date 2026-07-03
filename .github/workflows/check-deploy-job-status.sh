#!/bin/bash
set -e

# Use the timestamp from the previous step
GH_TASK_START="${GH_TASK_START}"
echo "Current GitHub task start: $GH_TASK_START"
sleep 30
MAX_WAIT=30

TRIGGER_ID=$(echo -n "${SERVICE_NAME} ${TRIGGER_UUID}" | jq -sRr @uri)

QUERY_URL="${BROKER_URL}/v1/intention/search?where=%7B%22event.trigger.id%22%3A%22${TRIGGER_ID}%22%7D&offset=0&limit=1"
TRIGGER_PHASE_START=$(date +%s)
LAST_HTTP_CODE="n/a"
LAST_CURL_EXIT="0"
TRIGGER_ATTEMPTS=0
COMPLETION_ATTEMPTS=0

# Wait for the Jenkins deployment job to be triggered (max 90s)
for ((i=1; i<=MAX_WAIT; i++)); do
  TRIGGER_ATTEMPTS=$i
  RESPONSE_FILE=$(mktemp)
  set +e
  LAST_HTTP_CODE=$(curl -sS -X 'POST' \
    --output "${RESPONSE_FILE}" \
    --write-out "%{http_code}" \
    --retry 1 \
    --retry-delay 1 \
    --connect-timeout 5 \
    --max-time 15 \
    "$QUERY_URL" \
    -H 'accept: application/json' \
    -H 'Authorization: Bearer '"${BROKER_JWT}"'' \
    -d '')
  LAST_CURL_EXIT=$?
  set -e

  RESPONSE=$(cat "${RESPONSE_FILE}")
  rm -f "${RESPONSE_FILE}"

  if [[ "${LAST_CURL_EXIT}" -ne 0 ]]; then
    echo "Warning: Broker query failed (curl exit ${LAST_CURL_EXIT}) while waiting for trigger."
    if [ $i -eq $MAX_WAIT ]; then
      echo "failure_reason=broker_query_error_trigger" >> $GITHUB_OUTPUT
      echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
      echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
      echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
      exit 1
    fi
    sleep 10
    continue
  fi

  if [[ ! "${LAST_HTTP_CODE}" =~ ^2 ]]; then
    echo "Warning: Broker returned HTTP ${LAST_HTTP_CODE} while waiting for trigger."
    if [ $i -eq $MAX_WAIT ]; then
      echo "failure_reason=broker_http_error_trigger" >> $GITHUB_OUTPUT
      echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
      echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
      echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
      exit 1
    fi
    sleep 10
    continue
  fi

  DATA_LENGTH=$(echo "$RESPONSE" | jq '.data | length')

  if [[ -z "$RESPONSE" || "$RESPONSE" == "null" || "$DATA_LENGTH" -eq 0 ]]; then
    if [ $i -eq $MAX_WAIT ]; then
      echo "Error: Deployment job was not triggered from broker after $((MAX_WAIT*10)) seconds."
      echo "failure_reason=not_triggered_timeout" >> $GITHUB_OUTPUT
      echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
      echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
      echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
      exit 1
    fi
    echo "Waiting for deployment job to be triggered..."
    sleep 10
    continue
  fi
  break
done

TRIGGER_PHASE_END=$(date +%s)
TRIGGER_WAIT_SECONDS=$((TRIGGER_PHASE_END - TRIGGER_PHASE_START))
COMPLETION_PHASE_START=$(date +%s)

# Wait for the deployment job to be closed (completed)
for ((i=1; i<=MAX_WAIT; i++)); do
  COMPLETION_ATTEMPTS=$i
  RESPONSE_FILE=$(mktemp)
  set +e
  LAST_HTTP_CODE=$(curl -sS -X 'POST' \
    --output "${RESPONSE_FILE}" \
    --write-out "%{http_code}" \
    --retry 1 \
    --retry-delay 1 \
    --connect-timeout 5 \
    --max-time 15 \
    "$QUERY_URL" \
    -H 'accept: application/json' \
    -H 'Authorization: Bearer '"${BROKER_JWT}"'' \
    -d '')
  LAST_CURL_EXIT=$?
  set -e

  RESPONSE=$(cat "${RESPONSE_FILE}")
  rm -f "${RESPONSE_FILE}"

  if [[ "${LAST_CURL_EXIT}" -ne 0 ]]; then
    echo "Warning: Broker query failed (curl exit ${LAST_CURL_EXIT}) while waiting for completion."
    if [ $i -eq $MAX_WAIT ]; then
      echo "failure_reason=broker_query_error_completion" >> $GITHUB_OUTPUT
      echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
      echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
      echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "trigger_wait_seconds=${TRIGGER_WAIT_SECONDS}" >> $GITHUB_OUTPUT
      exit 1
    fi
    sleep 10
    continue
  fi

  if [[ ! "${LAST_HTTP_CODE}" =~ ^2 ]]; then
    echo "Warning: Broker returned HTTP ${LAST_HTTP_CODE} while waiting for completion."
    if [ $i -eq $MAX_WAIT ]; then
      echo "failure_reason=broker_http_error_completion" >> $GITHUB_OUTPUT
      echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
      echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
      echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
      echo "trigger_wait_seconds=${TRIGGER_WAIT_SECONDS}" >> $GITHUB_OUTPUT
      exit 1
    fi
    sleep 10
    continue
  fi

  CLOSED=$(echo "$RESPONSE" | jq -r '.data[0].closed // false')
  if [[ "$CLOSED" == "true" ]]; then
    echo "Deployment job is closed."
    break
  fi
  if [ $i -eq $MAX_WAIT ]; then
    echo "Error: Deployment job could not complete within $((MAX_WAIT*10)) seconds."
    echo "failure_reason=not_completed_timeout" >> $GITHUB_OUTPUT
    echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
    echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
    echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
    echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
    echo "trigger_wait_seconds=${TRIGGER_WAIT_SECONDS}" >> $GITHUB_OUTPUT
    exit 1
  fi
  echo "Deployment job still running... waiting 10s"
  sleep 10
done

COMPLETION_PHASE_END=$(date +%s)
COMPLETION_WAIT_SECONDS=$((COMPLETION_PHASE_END - COMPLETION_PHASE_START))

echo "last_http_code=${LAST_HTTP_CODE}" >> $GITHUB_OUTPUT
echo "last_curl_exit=${LAST_CURL_EXIT}" >> $GITHUB_OUTPUT
echo "trigger_attempts=${TRIGGER_ATTEMPTS}" >> $GITHUB_OUTPUT
echo "completion_attempts=${COMPLETION_ATTEMPTS}" >> $GITHUB_OUTPUT
echo "trigger_wait_seconds=${TRIGGER_WAIT_SECONDS}" >> $GITHUB_OUTPUT
echo "completion_wait_seconds=${COMPLETION_WAIT_SECONDS}" >> $GITHUB_OUTPUT

# Extract and display the event URL
EVENT_URL=$(echo "$RESPONSE" | jq -r '.data[0].event.url // empty')
if [[ -n "$EVENT_URL" ]]; then
  echo "Event URL: $EVENT_URL"
  echo "event_url=$EVENT_URL" >> $GITHUB_OUTPUT
else
  echo "Event URL not found in response."
fi

# Check the outcome
STATUS=$(echo "$RESPONSE" | jq -r '.data[0].transaction.outcome // empty')
echo "status=$STATUS" >> $GITHUB_OUTPUT
if [[ "$STATUS" != "success" ]]; then
  echo "failure_reason=deployment_outcome_not_success" >> $GITHUB_OUTPUT
  echo "Deployment outcome is not success: $STATUS"
  exit 1
fi
