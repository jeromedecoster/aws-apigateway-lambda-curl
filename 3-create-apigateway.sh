# the directory of his script file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
source settings.sh

./create-api-gateway.sh "$API_NAME"

./create-api-gateway-post-resource.sh "$API_NAME" "$API_PROXY" AWS_PROXY "$LAMBDA_NAME"

./create-api-gateway-post-resource.sh "$API_NAME" "$API_NO_PROXY" AWS "$LAMBDA_NAME"

# get the API Gateway id
API_ID=$(get_api_gateway_id "$API_NAME")
echo "API_ID: $API_ID"

# write `API_ID` into settings.sh
sed -i "s/API_ID=.*$/API_ID=$API_ID/" settings.sh