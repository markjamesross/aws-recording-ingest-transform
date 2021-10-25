import boto3
import os
import json

polly = boto3.client('polly')
s3 = boto3.resource('s3')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_bucket = event['s3_bucket']
    s3_key = event['s3_key']
    translate_job_id = event['TranslateJobId']
    outputS3 = os.environ['OUTPUT_BUCKET']
    accountId = os.environ['ACCOUNT_ID']

    #Extract text from the translated file
    content_object = s3.Object(f'{outputS3}', f'{s3_key}/translation/{accountId}-TranslateText-{translate_job_id}/pl.transcript.txt')
    file_content = content_object.get()['Body'].read().decode('utf-8')
    print("The translated text is: -")
    print(file_content)

    speech = f'{s3_key}/polly/polly.mp3'

    #Perform Text to Speech
    response = polly.start_speech_synthesis_task(
      OutputFormat='mp3',
      Text=file_content,
      VoiceId='Amy',
      OutputS3BucketName=outputS3,
      OutputS3KeyPrefix=speech,
    )

    #Pass details to state
    event['polly'] = speech
    event['PollyOutputUri'] = response['SynthesisTask']['OutputUri']

    return event