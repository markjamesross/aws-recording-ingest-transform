import boto3
import json

translate = boto3.client('translate')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    jobName = event['translateJobId']

    response = translate.describe_text_translation_job(
      JobId=jobName
    )

    event['translateJobStatus'] = response['TextTranslationJobProperties']['JobStatus']

    return event