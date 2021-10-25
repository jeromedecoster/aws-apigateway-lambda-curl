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
    log iam detach-role-policy
    aws iam detach-role-policy \
        --role-name $LAMBDA_ROLE_NAME \
        --policy-arn $LAMBDA_POLICY_ARN 2>/dev/null

    # delete previous `LAMBDA_ROLE_NAME` role
    log iam delete-role
    aws iam delete-role \
        --role-name $LAMBDA_ROLE_NAME
fi

# create the lambda role
log iam create-role
aws iam create-role \
    --role-name $LAMBDA_ROLE_NAME \
    --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": {
        "Effect": "Allow",
        "Principal": {"Service": "lambda.amazonaws.com"},
        "Action": "sts:AssumeRole"
        }
    }' \
    --output table

# attach the `AWSLambdaBasicExecutionRole` policy to the lambda role
log iam attach-role-policy
aws iam attach-role-policy \
    --role-name $LAMBDA_ROLE_NAME \
    --policy-arn $LAMBDA_POLICY_ARN

# need to wait for Arn to become available
info waiting 'the availability of the iam role... (10 seconds required)'
sleep 10

# zip the code of the lambda function
log create zip
rm --force lambda.zip
zip -9 lambda.zip index.js

# delete previous `LAMBDA_NAME` Lambda function
log lambda delete-function
aws lambda delete-function \
    --region $AWS_REGION \
    --function-name $LAMBDA_NAME \
    2>/dev/null

# get the Lambda Role Arn
LAMBDA_ROLE_ARN=$(get_lambda_role_arn)
log LAMBDA_ROLE_ARN $LAMBDA_ROLE_ARN

# create the `LAMBDA_NAME` Lambda function
log lambda create-function
aws lambda create-function \
    --region $AWS_REGION \
    --function-name $LAMBDA_NAME \
    --runtime nodejs14.x \
    --role $LAMBDA_ROLE_ARN \
    --handler index.handler \
    --zip-file fileb://lambda.zip \
    --output table