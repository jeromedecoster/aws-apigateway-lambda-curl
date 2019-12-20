# the directory of his script file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
[[ -f settings.sh ]] && source settings.sh

# check if a previous `LAMBDA_ROLE_NAME` role exists
previous=$(aws iam list-roles \
    --query "Roles[?RoleName=='$LAMBDA_ROLE_NAME'].RoleName" \
    --output text)

if [[ -n "$previous" ]]; then
    # to delete previous `LAMBDA_ROLE_NAME` role, you must detach policy first
    echo 'iam detach-role-policy'
    aws iam detach-role-policy \
        --role-name $LAMBDA_ROLE_NAME \
        --policy-arn $LAMBDA_POLICY_ARN 2>/dev/null

    # delete previous `LAMBDA_ROLE_NAME` role
    echo 'iam delete-role'
    aws iam delete-role \
        --role-name $LAMBDA_ROLE_NAME
fi

# create the lambda role
echo 'iam create-role'
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document fileb://lambda-role-policy.json \
    --output table

# attach the `AWSLambdaBasicExecutionRole` policy to the lambda role
echo 'iam attach-role-policy'
aws iam attach-role-policy \
    --role-name $LAMBDA_ROLE_NAME \
    --policy-arn $LAMBDA_POLICY_ARN

# need to wait for Arn to become available
echo 'waiting the availability of the iam role... (10 seconds required)'
sleep 10

# zip the code of the lambda function
echo 'create zip...'
rm --force lambda.zip
zip -9 lambda.zip index.js

# delete previous `LAMBDA_NAME` Lambda function
echo 'lambda delete-function'
aws lambda delete-function \
    --region $AWS_REGION \
    --function-name $LAMBDA_NAME \
    2>/dev/null

# get the Lambda Role Arn
LAMBDA_ROLE_ARN=$(get_lambda_role_arn)
echo "LAMBDA_ROLE_ARN: $LAMBDA_ROLE_ARN"

# create the `LAMBDA_NAME` Lambda function
echo 'lambda create-function'
aws lambda create-function \
    --region $AWS_REGION \
    --function-name $LAMBDA_NAME \
    --runtime nodejs12.x \
    --role $LAMBDA_ROLE_ARN \
    --handler index.handler \
    --zip-file fileb://lambda.zip \
    --output table