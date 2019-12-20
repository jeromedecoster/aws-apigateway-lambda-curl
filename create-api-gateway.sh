# the name of this file
file=$(basename "$0")

# the directory of this file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
source settings.sh

[[ -z $1 ]] && echo "$file: \$1 is required (API_GATEWAY_NAME)" && exit
API_GATEWAY_NAME=$1

# delete previous `NAME` API gateways
aws apigateway get-rest-apis \
    --region $AWS_REGION \
    --query "items[?name=='$API_GATEWAY_NAME'].[id]" \
    --output text | while read id; do \
        echo "apigateway delete-rest-api"
        aws apigateway delete-rest-api \
            --region $AWS_REGION \
            --rest-api-id "$id"
        echo 'deleting an API Gateway... (5 seconds required)'
        sleep 5
    done

# create the API Gateway
echo 'apigateway create-rest-api'
aws apigateway create-rest-api \
    --region $AWS_REGION \
    --name $API_GATEWAY_NAME \
    --endpoint-configuration types=REGIONAL \
    --description 'A test API' \
    --output table
