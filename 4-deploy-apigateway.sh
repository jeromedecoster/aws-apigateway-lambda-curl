# the directory of his script file
dir="$(cd "$(dirname "$0")"; pwd)"

# the current working directory
cwd=$(pwd)

cd "$dir"
source settings.sh

# publish the API, create the `dev` stage
log apigateway create-deployment
aws apigateway create-deployment \
    --region $AWS_REGION \
    --rest-api-id $API_ID \
    --stage-name dev \
    --output table

info creating 'a API Gateway deployment... (5 seconds required)'
sleep 5