import boto3
import os
import json

transcribe = boto3.client('transcribe')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    s3_bucket = event['s3_bucket']
    s3_key = event['s3_key']

    content = f's3://{s3_bucket}/{s3_key}'
    jobName = f'{s3_key}'
    transcript = f'transcripts/{s3_key}/{s3_key}-transcript.json'

    #Perform transcription
    response = transcribe.start_transcription_job(
        TranscriptionJobName=jobName,
        IdentifyLanguage=True,
        Media={'MediaFileUri': content},
        OutputBucketName=os.environ['OUTPUT_BUCKET'],
        OutputKey=transcript
    )

    #Pass details to state
    event['transcript'] = transcript
    event['TranscriptionJobName'] = response['TranscriptionJob']['TranscriptionJobName']

    return event