import boto3
import os
import json

translate = boto3.client('translate')
s3 = boto3.resource('s3')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_bucket = os.environ['OUTPUT_BUCKET']
    s3_key = event['s3_key']

    content = f's3://{s3_bucket}/{s3_key}/transcript'
    jobName = f'{s3_key}'
    translation = f'{s3_key}/translation'
    outputS3 = os.environ['OUTPUT_BUCKET']
    outputS3Uri = f's3://{outputS3}/{translation}'

    print("Translating " + content)

    #Perform translation 
    response = translate.start_text_translation_job(
      InputDataConfig={
        'S3Uri': content,
        'ContentType': 'text/plain',
      },
      OutputDataConfig={
          'S3Uri': outputS3Uri 
      },
      DataAccessRoleArn=os.environ['ROLE_ARN'],
      JobName=jobName,
      SourceLanguageCode='en',
      TargetLanguageCodes=[
        'pl',
      ],
    )

    #Pass details to state
    event['translate'] = translation
    event['TranslateJobId'] = response['JobId']

    return event