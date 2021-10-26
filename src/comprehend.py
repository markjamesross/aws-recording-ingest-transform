import boto3
import os
import json

comprehend = boto3.client('comprehend')
s3 = boto3.resource('s3')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_bucket = os.environ['OUTPUT_BUCKET']
    s3_key = event['s3_key']
    extract = event['extract']

    content = f's3://{s3_bucket}/{extract}'
    jobName = f'{s3_key}'
    comprehension = f'{s3_key}/comprehend'
    outputS3 = os.environ['OUTPUT_BUCKET']
    outputS3Uri = f's3://{outputS3}/{comprehension}'

    #Perform comprehension
    response = comprehend.start_key_phrases_detection_job(
      InputDataConfig={
        'S3Uri': content,
        'InputFormat': 'ONE_DOC_PER_FILE',
      },
      OutputDataConfig={
          'S3Uri': outputS3Uri
      },
      DataAccessRoleArn=os.environ['ROLE_ARN'],
      JobName=jobName,
      LanguageCode='en'
    )

    #Pass details to state
    event['comprehend'] = comprehension
    event['comprehendJobId'] = response['JobId']

    return event