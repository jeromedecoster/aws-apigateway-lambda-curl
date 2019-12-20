# Project
AWS_ID=
AWS_REGION=eu-west-3
# API Gateway
API_NAME=aws-apigateway-lamdba-curl
API_ID=
# Resources paths
API_PROXY=with-proxy
API_NO_PROXY=no-proxy
# Lambda
LAMBDA_NAME=aws-apigateway-lamdba-curl
LAMBDA_ROLE_NAME=$LAMBDA_NAME-role
LAMBDA_POLICY_ARN=arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

#
# Functions
#

# get the Lambda Role Arn
get_lambda_role_arn () {
    aws iam get-role \
        --role-name $LAMBDA_ROLE_NAME \
        --query 'Role.Arn' \
        --output text
}

# get the Lambda Arn
get_lambda_arn () {
    [[ -z $1 ]] \
        && echo 'get_lambda_arn: $1 is required (LAMBDA_NAME)' >&2 \
        && exit 1
    aws lambda get-function \
        --region $AWS_REGION \
        --function-name $1 \
        --query 'Configuration.FunctionArn' \
        --output text
}

# get the API Gateway id
get_api_gateway_id () {
    [[ -z $1 ]] \
        && echo 'get_api_gateway_id: $1 is required (API_GATEWAY_NAME)' >&2 \
        && exit 1
    aws apigateway get-rest-apis \
        --region $AWS_REGION \
        --query "items[?name=='$1'].[id]" \
        --output text
}

# get the API Gateway Resource id
get_api_gateway_resource_id () {
    [[ -z $1 ]] \
        && echo 'get_api_gateway_resource_id: $1 is required (API_GATEWAY_ID)' >&2 \
        && exit 1
    [[ -z $2 ]] \
        && echo 'get_api_gateway_resource_id: $2 is required (RESOURCE_PATH)' >&2 \
        && exit 1
    local RESOURCE_PATH=$2
    # if first char is not /
    [[ ${RESOURCE_PATH:0:1} != '/' ]] && RESOURCE_PATH="/$2"

    aws apigateway get-resources \
        --region $AWS_REGION \
        --rest-api-id $1 \
        --query "items[?path=='$RESOURCE_PATH'].[id]" \
        --output text
}

# get the API Gateway arn
get_api_gateway_arn () {
    [[ -z $1 ]] \
        && echo 'get_api_gateway_arn: $1 is required (API_GATEWAY_ID)' >&2 \
        && exit 1
    echo -n "arn:aws:execute-api:${AWS_REGION}:${AWS_ID}:$1"
}
