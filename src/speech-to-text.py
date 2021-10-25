import boto3
import os
import json

transcribe = boto3.client('transcribe')
s3 = boto3.resource('s3')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_bucket = event['s3_bucket']
    s3_key = event['s3_key']
    outputS3 = os.environ['OUTPUT_BUCKET']

    content = f's3://{s3_bucket}/{s3_key}'
    jobName = f'{s3_key}'
    transcript = f'{s3_key}/transcript_raw/transcript.json'

    #Perform transcription
    response = transcribe.start_transcription_job(
        TranscriptionJobName=jobName,
        IdentifyLanguage=True,
        Media={'MediaFileUri': content},
        OutputBucketName=outputS3,
        OutputKey=transcript
    )

    #Pass details to state
    event['transcript'] = transcript

    return event