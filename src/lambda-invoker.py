import json
import urllib.parse
import boto3
import os

print('Loading function')

stepfunctions = boto3.client('stepfunctions')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    # Get the object from the event and show its content type
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')

    s3_info = {
        "s3_bucket": bucket,
        "s3_key": key
    }

    try:
        response = stepfunctions.start_execution(
            stateMachineArn=os.environ['STEP_FUNCTION_ARN'],
            input=json.dumps(s3_info)
        )
        return json.dumps(response, default=str)
    except Exception as e:
        print(e)
        raise e
