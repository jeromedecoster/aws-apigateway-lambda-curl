# the directory of his script file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
source settings.sh

TEMPLATE=$(cat <<EOF
'{
    "type":"form-urlencoded",
    "body": \$input.body,
    "params" : {
    #foreach(\$param in \$input.params().querystring.keySet())
        "\$param": "\$util.escapeJavaScript(\$input.params().querystring.get(\$param))"
        #if (\$foreach.hasNext), #end
    #end
    }
}'
EOF
)

# get the API_NO_PROXY id
RESOURCE_ID=$(get_api_gateway_resource_id "$API_ID" "$API_NO_PROXY")

echo 'apigateway update-integration'
aws apigateway update-integration \
    --rest-api-id $API_ID \
    --resource-id $RESOURCE_ID \
    --http-method POST \
    --patch-operations op='add',path='/requestTemplates/application~1x-www-form-urlencoded',value="$TEMPLATE" \
    --output table

# publish the API, create the `dev` stage
echo 'apigateway create-deployment'
aws apigateway create-deployment \
    --region $AWS_REGION \
    --rest-api-id $API_ID \
    --stage-name dev \
    --output table

echo 'creating a API Gateway deployment... (5 seconds required)'
sleep 5