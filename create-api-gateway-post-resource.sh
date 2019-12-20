# the name of this file
file=$(basename "$0")

# the directory of this file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
[[ -f settings.sh ]] && source settings.sh

[[ -z $1 ]] && echo "$file: \$1 is required (API_GATEWAY_NAME)" >&2 && exit 1
[[ -z $2 ]] && echo "$file: \$2 is required (PART_PATH)" >&2 && exit 1
[[ -z $3 ]] && echo "$file: \$3 is required (INTEGRATION_TYPE)" >&2 && exit 1
[[ -z $4 ]] && echo "$file: \$4 is required (LAMBDA_NAME)" >&2 && exit 1
API_GATEWAY_NAME=$1
PART_PATH=$2
INTEGRATION_TYPE=$3 # AWS | AWS_PROXY
LAMBDA_NAME=$4
echo "API_GATEWAY_NAME: $API_GATEWAY_NAME"
echo "PART_PATH: $PART_PATH"
echo "INTEGRATION_TYPE: $INTEGRATION_TYPE"
echo "LAMBDA_NAME: $LAMBDA_NAME"

# get the API Gateway id
API_GATEWAY_ID=$(get_api_gateway_id "$API_GATEWAY_NAME")
echo "API_GATEWAY_ID: $API_GATEWAY_ID"

# get the root path id
API_ROOT_ID=$(get_api_gateway_resource_id "$API_GATEWAY_ID" '/')
echo "API_ROOT_ID: $API_ROOT_ID"

# TODO: delete resource

# get the `RESOURCE_ID` id
RESOURCE_ID=$(get_api_gateway_resource_id "$API_GATEWAY_ID" "$PART_PATH")
echo "RESOURCE_ID: $RESOURCE_ID"

if [[ -n "$RESOURCE_ID" ]]; then
    echo 'apigateway delete-resource'
    aws apigateway delete-resource \
        --region $AWS_REGION \
        --rest-api-id $API_GATEWAY_ID \
        --resource-id $RESOURCE_ID
fi

# create the `API_WITH_PROXY_RESOURCE_NAME` resource
echo 'apigateway create-resource'
aws apigateway create-resource \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --parent-id $API_ROOT_ID \
    --path-part $PART_PATH \
    --output table

# get the `PART_PATH` id
RESOURCE_ID=$(get_api_gateway_resource_id "$API_GATEWAY_ID" "$PART_PATH")
echo "RESOURCE_ID: $RESOURCE_ID"

echo 'apigateway put-method'
aws apigateway put-method \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --authorization-type NONE \
    --output table

LAMBDA_ARN=$(get_lambda_arn "$LAMBDA_NAME")
echo "LAMBDA_ARN: $LAMBDA_ARN"

# setup the POST method integration request
echo 'apigateway put-integration'
aws apigateway put-integration \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --integration-http-method POST \
    --type $INTEGRATION_TYPE \
    --passthrough-behavior WHEN_NO_TEMPLATES \
    --uri "arn:aws:apigateway:$AWS_REGION:lambda:path/2015-03-31/functions/$LAMBDA_ARN/invocations" \
    --output table

# get the API Gateway arn
API_GATEWAY_ARN=$(get_api_gateway_arn "$API_GATEWAY_ID")
echo "API_GATEWAY_ARN: $API_GATEWAY_ARN"

# add lambda permission
STATEMENT_ID=api-lambda-permission-$(cat /dev/urandom | tr -dc 'a-z' | fold -w 10 | head -n 1)
echo "STATEMENT_ID: $STATEMENT_ID"

# optimisation needed (clean previous permissions)
echo 'lambda add-permission silently'
aws lambda add-permission \
    --region $AWS_REGION \
    --function-name $LAMBDA_NAME \
    --source-arn "$API_GATEWAY_ARN/*/POST/$PART_PATH" \
    --principal apigateway.amazonaws.com \
    --statement-id $STATEMENT_ID \
    --action lambda:InvokeFunction \
    &>/dev/null

echo 'apigateway put-method-response'
aws apigateway put-method-response \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --status-code 200 \
    --response-models '{"application/json": "Empty"}' \
    --output table

echo 'apigateway put-integration-response'
aws apigateway put-integration-response \
    --region $AWS_REGION \
    --rest-api-id $API_GATEWAY_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --status-code 200 --selection-pattern '' \
    --output table
