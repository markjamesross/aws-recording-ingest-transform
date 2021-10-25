import boto3
import json

transcribe = boto3.client('transcribe')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))
    textractJobName = event['textractJobName']

    response = transcribe.get_transcription_job(
        TranscriptionJobName=textractJobName
    )

    event['textractJobStatus'] = response['TranscriptionJob']['TranscriptionJobStatus']

    return event