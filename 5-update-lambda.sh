# the directory of his script file
dir="$(cd "$(dirname "$0")"; pwd)"

cd "$dir"
source settings.sh

cd multipart
npm install

# zip the code of the lambda function
log create zip
rm --force multipart.zip
zip --recurse-paths -9 multipart.zip index.js node_modules

log lambda update-function-code
aws lambda update-function-code \
    --function-name $LAMBDA_NAME \
    --zip-file fileb://multipart.zip \
    --output table