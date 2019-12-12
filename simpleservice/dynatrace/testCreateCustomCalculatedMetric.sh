#!/bin/bash

# Usage:
# ./testCreateCustomCalculatedMetrics.sh CONTEXTLESS keptn-project simpleproject

if [[ -z "$DT_TENANT" ]]; then
  DT_TENANT=$(cat ~/dynatrace-service/deploy/scripts/creds_dt.json | jq -r '.dynatraceTenant')
fi
if [[ -z "$DT_API_TOKEN" ]]; then
  DT_API_TOKEN=$(cat ~/dynatrace-service/deploy/scripts/creds_dt.json | jq -r '.dynatraceApiToken')
fi
if [[ -z "$DT_TENANT" || -z "$DT_API_TOKEN" ]]; then
  echo "DT_TENANT & DT_API_TOKEN MUST BE SET!!"
  exit 1
fi
CONDITION_CONTEXT=$1
CONDITION_KEY=$2
CONDITION_VALUE=$3

if [[ -z "$CONDITION_KEY" && -z "$CONDITION_VALUE" ]]; then
  echo "You have to at least specify a Tag Key or Value as a filter:"
  echo "Usage: ./testCreateCustomCalculatedMetrics.sh CONTEXTLESS keptn_project simpleproject"
  exit 1
fi

echo "============================================================="
echo "About to create one test sample metric [$1]$2:$3 on Dynatrace Tenant: $DT_TENANT!"
echo "============================================================="
echo "Usage: ./testCreateCustomCalculatedMetrics.sh CONTEXT KEY VALUE"
read -rsp $'Press ctrl-c to abort. Press any key to continue...\n' -n1 key

####################################################################################################################
## createCalculatedMetric(METRICKEY, METRICNAME, BASEMETRIC, UNIT, CONTEXT, KEY, VALUE, DIMENSIONNAME, DIMENSIONDEF DIMENSIONAGGR)
####################################################################################################################
# Example: createCalculatedMetric("calc:service.topurlresponsetime", "Top URL Response Time", "RESPONSE_TIME", "CONTEXTLESS", "keptn_project", "simpleproject", "URL", "{URL}" "COUNT")
# Full List of possible BASEMETRICS: CPU_TIME, DATABASE_CHILD_CALL_COUNT, DATABASE_CHILD_CALL_TIME, EXCEPTION_COUNT, FAILED_REQUEST_COUNT, FAILED_REQUEST_COUNT_CLIENT, FAILURE_RATE, FAILURE_RATE_CLIENT, HTTP_4XX_ERROR_COUNT, HTTP_4XX_ERROR_COUNT_CLIENT, HTTP_5XX_ERROR_COUNT, HTTP_5XX_ERROR_COUNT_CLIENT, IO_TIME, LOCK_TIME, NON_DATABASE_CHILD_CALL_COUNT, NON_DATABASE_CHILD_CALL_TIME, REQUEST_ATTRIBUTE, REQUEST_COUNT, RESPONSE_TIME, RESPONSE_TIME_CLIENT, SUCCESSFUL_REQUEST_COUNT, SUCCESSFUL_REQUEST_COUNT_CLIENT, TOTAL_PROCESSING_TIME, WAIT_TIME
function createCalculatedMetric() {
    METRICKEY=$1
    METRICNAME=$2
    BASEMETRIC=$3
    METRICUNIT=$4
    CONDITION_CONTEXT=$5
    CONDITION_KEY=$6
    CONDITION_VALUE=$7
    DIMENSION_NAME=$8
    DIMENSION_DEFINTION=$9
    DIMENSION_AGGREGATE=${10}

    PAYLOAD='{
            "tsmMetricKey": "'$METRICKEY'",
            "name": "'$METRICNAME'",
            "enabled": true,
            "metricDefinition": {
                "metric": "'$BASEMETRIC'",
                "requestAttribute": null
            },
            "unit": "'$METRICUNIT'",
            "unitDisplayName": "",
            "conditions": [
                {
                "attribute": "SERVICE_TAG",
                "comparisonInfo": {
                    "type": "TAG",
                    "comparison": "TAG_KEY_EQUALS",
                    "value": {
                        "context": "'$CONDITION_CONTEXT'",
                        "key": "'$CONDITION_KEY'",
                        "value": "'$CONDITION_VALUE'"
                    },
                    "negate": false
                }
                }
            ],
            "dimensionDefinition": {
                "name": "'$DIMENSION_NAME'",
                "dimension": "'$DIMENSION_DEFINTION'",
                "placeholders": [],
                "topX": 10,
                "topXDirection": "DESCENDING",
                "topXAggregation": "'$DIMENSION_AGGREGATE'"
            }
        }'

    echo "Creating Metric $METRICNAME($METRICKEY)"
    echo "PUT https://$DT_TENANT/api/config/v1/calculatedMetrics/service/$METRICKEY"
    echo "$PAYLOAD"
    curl -X PUT \
        "https://$DT_TENANT/api/config/v1/calculatedMetrics/service/$METRICKEY" \
        -H 'accept: application/json; charset=utf-8' \
        -H "Authorization: Api-Token $DT_API_TOKEN" \
        -H 'Content-Type: application/json; charset=utf-8' \
        -d "$PAYLOAD" \
        -o curloutput.txt

    cat curloutput.txt
}

## Creates a Test Calculated Service Metrics "Test RT Metric by URL"
createCalculatedMetric "calc:service.test" "Test RT Metric by URL" "RESPONSE_TIME" "MICRO_SECOND" "$CONDITION_CONTEXT" "$CONDITION_KEY" "$CONDITION_VALUE" "URL" "{URL:Path}" "SUM"